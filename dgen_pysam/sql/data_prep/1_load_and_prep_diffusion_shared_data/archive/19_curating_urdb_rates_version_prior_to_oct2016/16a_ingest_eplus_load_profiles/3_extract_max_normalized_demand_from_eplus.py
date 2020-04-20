# -*- coding: utf-8 -*-
"""
Created on Thu Dec 11 14:55:35 2014

@author: mgleason
"""


import psycopg2 as pg
import psycopg2.extras as pgx
import pandas as pd
from cStringIO import StringIO
import h5py
import os
import numpy as np

def pg_connect(pg_params):
    pg_conn_string = 'host=%(host)s dbname=%(dbname)s user=%(user)s password=%(password)s' % pg_params
    con = pg.connect(pg_conn_string)
    cur = con.cursor(cursor_factory=pgx.RealDictCursor)
    
    if 'role' in pg_params.keys():
        sql = "SET ROLE '%(role)s';" % pg_params
        cur.execute(sql)
        con.commit()
    
    return con, cur
    
# copy the df to postgres
pg_params = {'host'     : 'gispgdb',
             'dbname'   : 'dav-gis',
             'user'     : 'mgleason',
             'password' : 'mgleason',
             'role'     : 'diffusion-writers'
             }
             
# CONNECT TO POSTGRES
con, cur = pg_connect(pg_params)

hf_dir = '/Users/mgleason/gispgdb_home/shared/data/building_load/'
hf_dir = '/home/shared/data/building_load/'
hf_files = ['res.h5','com.h5']
for hf_file in hf_files:
    # get the sector type
    sector = hf_file.split('.')[0]
    print '\nWorking on %s' % sector
    out_table = 'diffusion_shared.energy_plus_max_normalized_demand_%s' % sector 
    sql_params = {'out_table' : out_table}
    # create the output table in postgres    
    # create table
    sql = """DROP TABLE IF EXISTS %(out_table)s;
             CREATE TABLE %(out_table)s 
             (
                 hdf_index integer,
                 crb_model text,
                 normalized_max_demand_kw_per_kw numeric,
                 annual_sum_Kwh numeric
             );""" % sql_params
    cur.execute(sql)
    con.commit()
    # open a string io file object to hold the data that will be copied to postgres
    f = StringIO()
    hf = h5py.File(os.path.join(hf_dir, hf_file), 'r')
    bldg_types = [k for k in hf.keys() if k <> 'meta']    
    for bldg_type in bldg_types:
        print 'WOrking on %s' % bldg_type
        fillvalue = hf[bldg_type].fillvalue
        # extract the masked data
        hourly_load = np.ma.masked_equal(hf[bldg_type], fillvalue)
        # find the max in each column
        max_hours = np.ma.max(hourly_load, 0)
        # find the annual sum in each column
        sum_year = np.ma.sum(hourly_load, 0)
        # normalize the max hours to the sums
        normalized_max_hours_masked = max_hours/sum_year
        # build a reverse mask to use in extracting the data
        unmasked = np.invert(normalized_max_hours_masked.mask)
        # extract the data that is unmasked
        normalized_max_hours = normalized_max_hours_masked.data[unmasked]
        # extract the indices that these correspond to
        hdf_index = np.arange(0,normalized_max_hours_masked.shape[0])[unmasked]
        # combine this info into a pandas data frame
        df = pd.DataFrame()
        df['hdf_index'] = hdf_index
        df['crb_model'] = bldg_type
        df['normalized_max_demand_kw_per_kw'] = normalized_max_hours
        df['annual_sum_kwh'] = sum_year.data[unmasked]
        # dump the data to the stringio file
        df.to_csv(f, index = False, header = False, mode = 'a')
    # close the hdf
    hf.close()
    # reset to the beginning of the stringio file
    f.seek(0)
    # copy the data from the stringio file to the postgres table
    cur.copy_expert("COPY %(out_table)s FROM STDOUT WITH CSV;" % sql_params, f)
    # commit the additions
    con.commit()    
    # close the stringio file (clears memory)
    f.close()       
        


