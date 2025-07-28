import json
import getopt
from google.cloud.sql.connector import Connector
import sys
import colorama
import logging
import colorlog
import pandas as pd
import datetime
import select
import pg8000.native
import psycopg2 as pg
from psycopg2.extras import RealDictCursor
import time
import subprocess
import os
from sqlalchemy import create_engine
from sqlalchemy.pool import  NullPool
#==============================================================================
#       Logging Functions
#==============================================================================


class StatefulAdapter(logging.LoggerAdapter):
    """
    A LoggerAdapter that prefixes every message with [<state>] [Task <idx>].
    """
    def __init__(self, logger, state):
        super().__init__(logger, {})
        self.state      = state

    def process(self, msg, kwargs):
        prefix = f"[{self.state}]"
        return f"{prefix} {msg}", kwargs

def get_logger(log_file_path=None):
    """
    Returns a LoggerAdapter which automatically prefixes each message
    with the BATCH_STATE and BATCH_TASK_INDEX, writes INFO+ to stdout,
    and optionally logs to a file.
    """
    colorama.init()

    # — prepare your colored console formatter (only needs to format {message}) —
    console_fmt = (
        "{log_color}{levelname:8}{reset} {message}"
    )
    console_formatter = colorlog.ColoredFormatter(
        console_fmt,
        reset=True,
        style="{"
    )

    # — create the base logger —
    base = logging.getLogger("dgen_model")
    base.setLevel(logging.DEBUG)
    base.handlers.clear()

    # 1) File handler (if requested)
    if log_file_path:
        fh = logging.FileHandler(log_file_path, mode="w")
        fh.setLevel(logging.DEBUG)
        # simple %-style formatter, but it will see the prefixed message
        fh.setFormatter(logging.Formatter(
            "%(levelname)-8s %(message)s"
        ))
        base.addHandler(fh)

    # 2) Console handler → stdout
    ch = logging.StreamHandler(stream=sys.stdout)
    ch.setLevel(logging.DEBUG)
    ch.setFormatter(console_formatter)
    base.addHandler(ch)

    # — wrap it in our adapter so every .info/.error call is auto-prefixed —
    state = os.getenv("BATCH_STATE", "??")
    return StatefulAdapter(base, state)


def shutdown_log(logger):
    logging.shutdown()
    for handler in logger.handlers:
        handler.flush()
        if handler.close and isinstance(handler, logging.StreamHandler):
            handler.close()
        logger.removeHandler(handler)


def code_profiler(out_dir):
    lines = [line for line in open(
        out_dir + '/dg_model.log') if 'took:' in line]

    process = [line.split('took:')[-2] for line in lines]
    process = [line.split(':')[-1] for line in process]

    time = [line.split('took:')[-1] for line in lines]
    time = [line.split('s')[0] for line in time]
    time = [float(x) for x in time]

    profile = pd.DataFrame({'process': process, 'time': time})
    profile = profile.sort_values('time', ascending=False)
    profile.to_csv(out_dir + '/code_profiler.csv')


def current_datetime(format='%Y_%m_%d_%Hh%Mm%Ss'):

    dt = datetime.datetime.strftime(datetime.datetime.now(), format)

    return dt


class Timer:
    # adapted from
    # http://preshing.com/20110924/timing-your-code-using-pythons-with-statement/

    def __enter__(self):
        self.start = time.time()
        return self

    def __exit__(self, *args):
        self.end = time.time()
        self.interval = self.end - self.start

#==============================================================================
#       Postgres Functions
#==============================================================================


def wait(conn):
    while 1:
        state = conn.poll()
        if state == pg.extensions.POLL_OK:
            break
        elif state == pg.extensions.POLL_WRITE:
            select.select([], [conn.fileno()], [])
        elif state == pg.extensions.POLL_READ:
            select.select([conn.fileno()], [], [])
        else:
            raise pg.OperationalError("poll() returned {}".format(state))


def pylist_2_pglist(l):
    return str(l)[1:-1]


# One Connector instance for the lifetime of the process
_connector = Connector()

def make_con(connection_string, role, async_=False):
    """
    Returns a DB connection+cursor.
      - In GCP (PG_CONN_STRING set): use Connector + pg8000
      - Locally: psycopg2.connect(connection_string)
    """
    dsn = os.environ.get("PG_CONN_STRING")
    if dsn:
        # ── Cloud mode: Connector + pg8000
        inst     = os.environ["INSTANCE_CONNECTION_NAME"]
        user     = os.environ["DB_USER"]
        password = os.environ["DB_PASS"]
        dbname   = os.environ.get("DB_NAME", None)

        conn: pg8000.native.Connection = _connector.connect(
            inst,
            "pg8000",
            user=user,
            password=password,
            db=dbname,
        )
        cur = conn.cursor()
        # SET ROLE still works
        cur.execute(f'SET ROLE "{role}";')
        conn.commit()

    else:
        # ── Local mode: psycopg2 + cloud-sql-proxy or local Postgres
        conn = pg.connect(connection_string, async_=async_)
        if async_:
            wait(conn)
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute(f'SET ROLE "{role}";')
        if async_:
            wait(conn)
        else:
            conn.commit()

    return conn, cur

def make_engine(pg_engine_con):
    """
    SQLAlchemy engine factory:
     - GCP: use Connector+pg8000 via creator() to open the Cloud SQL socket
     - Local: create_engine(pg_engine_con) as before
    """
    if os.environ.get("PG_CONN_STRING"):
        # Cloud mode: all engine connections go via the Connector
        def getconn():
            inst     = os.environ["INSTANCE_CONNECTION_NAME"]
            user     = os.environ["DB_USER"]
            password = os.environ["DB_PASS"]
            dbname   = os.environ.get("DB_NAME", None)
            return _connector.connect(
                inst,
                "pg8000",
                user=user,
                password=password,
                db=dbname,
            )

        print(f"[make_engine] Using Cloud SQL Connector for engine", flush=True)
        return create_engine(
            "postgresql+pg8000://",
            creator=getconn,
            poolclass=NullPool
        )

    # Local mode
    url = pg_engine_con.strip()
    print(f"[make_engine] Using URL: {url}", flush=True)
    return create_engine(url, poolclass=NullPool)


def get_pg_params(json_file):

    """
    Takes the path to the json file specifying database connection information and returns formatted information.
    
    Parameters
    ----------
    json_file : 'str' 
        The path to the json file specifying database connection information. 
    
    Returns
    -------
    pg_params : 'json'
        'postgres database connection parameters'
    pg_conn_str : 'str'
        Formatted connection string
    """

    pg_params_json = open(json_file, 'r')
    pg_params = json.load(pg_params_json)
    pg_params_json.close()

    pg_conn_string = 'host={host} dbname={dbname} user={user} password={password} port={port}'.format(**pg_params)

    return pg_params, pg_conn_string

def get_pg_engine_params(json_file):

    pg_params_json = open(json_file, 'r')
    pg_params = json.load(pg_params_json)
    pg_params_json.close()

    pg_conn_string = 'postgresql://{user}:{password}@{host}:{port}/{dbname}'.format(**pg_params)

    return pg_params, pg_conn_string


#==============================================================================
#       Miscellaneous Functions
#==============================================================================
def parse_command_args(argv):

    """
    Function to parse the command line arguments.
    
    Parameters
    ----------
    argv : 'str' 
        -h : help 'dg_model.py -i <Initiate Model?> -y <year>'
        -i : Initiate model for 2010 and quit
        -y: or year= : Resume model solve in passed year 
    
    Returns
    -------
    init_model - 'bool'
        Initialize the model
    resume_year : 'float'
        The year the model should resume.

    """

    resume_year = None
    init_model = False

    try:
        opts, args = getopt.getopt(argv, "hiy:", ["year="])
    except getopt.GetoptError:
        print('Command line argument not recognized, please use: dg_model.py -i -y <year>')
        sys.exit(2)
    for opt, arg in opts:
        if opt == '-h':
            print('dg_model.py -i <Initiate Model?> -y <year>')
            sys.exit()
        elif opt in ("-i"):
            init_model = True
        elif opt in ("-y", "year="):
            resume_year = arg
    return init_model, resume_year


def get_epoch_time():

    epoch_time = time.time()

    return epoch_time


def get_formatted_time():

    formatted_time = time.strftime('%Y%m%d_%H%M%S')

    return formatted_time
