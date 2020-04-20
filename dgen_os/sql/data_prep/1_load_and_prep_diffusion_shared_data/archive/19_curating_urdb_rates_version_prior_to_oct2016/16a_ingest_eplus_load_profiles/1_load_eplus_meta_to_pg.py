# -*- coding: utf-8 -*-
"""
Created on Thu Dec 11 14:55:35 2014

@author: mgleason
"""


import psycopg2 as pg
import psycopg2.extras as pgx
import pandas as pd
from cStringIO import StringIO
import datetime
import json
import h5py

def pg_connect(pg_params):
    pg_conn_string = 'host=%(host)s dbname=%(dbname)s user=%(user)s password=%(password)s' % pg_params
    con = pg.connect(pg_conn_string)
    cur = con.cursor(cursor_factory=pgx.RealDictCursor)
    
    if 'role' in pg_params.keys():
        sql = "SET ROLE '%(role)s';" % pg_params
        cur.execute(sql)
        con.commit()
    
    return con, cur
    


# get the meta data out of the hdf and into a df
hfpath = '/Users/mgleason/gispgdb_home/shared/data/building_load/res.h5'
hf = h5py.File(hfpath, 'r')
columns = hf['meta'].dtype.names
meta = pd.DataFrame.from_records(hf['meta'], columns = columns)
hf.close()

# copy the df to postgres
pg_params = {'host'     : 'gispgdb',
             'dbname'   : 'dav-gis',
             'user'     : 'mgleason',
             'password' : 'mgleason',
             'role'     : 'diffusion-writers'
             }
             
# CONNECT TO POSTGRES
con, cur = pg_connect(pg_params)

# create table
sql = """DROP TABLE IF EXISTS diffusion_shared.energy_plus_load_meta;
         CREATE TABLE diffusion_shared.energy_plus_load_meta 
         (
             hdf_index integer,
             source_hdf_file_num integer,
             usaf integer,
             class integer,
             solar integer,
             station text,
             st text,
             nsrdb_lat numeric,
             nsrdb_lon numeric,
             nsrdb_elev numeric,
             timezone integer,
             ish_lat numeric,
             ish_lon numeric,
             ish_elev numeric,
             wban text,
             tmy3 integer,
             tmy2 integer,
             res1 text,
             res2 text,
             res3 text,
             com text,
             missing_data text         
         );"""
cur.execute(sql)
con.commit()
f = StringIO()
meta.to_csv(f, index = False)
f.seek(0)
# copy the data from the stringio file to the postgres table
cur.copy_expert("COPY diffusion_shared.energy_plus_load_meta FROM STDOUT WITH CSV HEADER;", f)
# commit the additions
con.commit()    
# close the stringio file (clears memory)
f.close()