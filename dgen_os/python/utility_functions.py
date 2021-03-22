import json
import getopt
import sys
import colorama
import logging
import colorlog
import pandas as pd
import datetime
import select
import psycopg2 as pg
import psycopg2.extras as pgx
import time
import subprocess
import os
from sqlalchemy import create_engine
from sqlalchemy.pool import  NullPool
#==============================================================================
#       Logging Functions
#==============================================================================


def get_logger(log_file_path=None):
    """
    Takes depreciation schedule and sorts table fields by depreciation year
    
    Parameters
    ----------
    log_file_path : 'str' 
        The log_file_path. 
    
    Returns
    -------
    logger : 'loggin.logger'
        logger object for logging
    """

    colorama.init()
    formatter = colorlog.ColoredFormatter("{log_color}{levelname:8}:{reset} {white}{message}",
                                          datefmt=None,
                                          reset=True, style = '{'
                                          )
    if log_file_path is not None:
        logging.basicConfig(filename=log_file_path, filemode='w',
                            format='{levelname}-8:{message}', level=logging.DEBUG, style = '{')
        
    logger = logging.getLogger(__name__)

    if len(logger.handlers) == 0:
        logger = logging.getLogger(__name__)
        console = logging.StreamHandler()
        console.setLevel(logging.DEBUG)
        console.setFormatter(formatter)
        logger.addHandler(console)

    return logger


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


def make_con(connection_string, role, async_=False):

    '''
    Returns the psql connection and cursor objects to be used with functions that query from the database.
        
    Parameters
    ----------    
    connection_string : 'SQL connection'
        Connection string. e.g. "postgresql+psycopg2://postgres:postgres@127.0.0.1:5432/dgen_db".       
    role : 'str'
        Database role. 'postgres' should be the default role name for the open source codebase. 

    Returns
    -------
    con : 'SQL connection'
        Postgres Database Connection.
    cur : 'SQL cursor'
        Postgres Database Cursor.
    '''

    con = pg.connect(connection_string, async_=async_)
    if async_:
        wait(con)
    # create cursor object
    cur = con.cursor(cursor_factory=pgx.RealDictCursor)
    # set role (this should avoid permissions issues)
    cur.execute('SET ROLE "{}";'.format(role))
    if async_:
        wait(con)
    else:
        con.commit()

    return con, cur

def make_engine(pg_engine_con):

    return create_engine(pg_engine_con, poolclass=NullPool)


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
