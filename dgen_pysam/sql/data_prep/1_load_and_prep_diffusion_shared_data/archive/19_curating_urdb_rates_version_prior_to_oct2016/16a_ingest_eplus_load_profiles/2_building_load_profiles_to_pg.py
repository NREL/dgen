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
hf_dir = '/home/shared/data/building_load/all_attributes/'
    
             
             
# CONNECT TO POSTGRES
con, cur = pg_connect(pg_params)
scale_offset = 1e8
hf_files = ['res.h5','com.h5']
for hf_file in hf_files:
    # get the sector type
    sector = hf_file.split('.')[0]
    print '\nWorking on %s' % sector
    out_table = 'diffusion_shared.energy_plus_normalized_load_%s' % sector 
    sql_params = {'out_table' : out_table}
    # create the output table in postgres    
    # create table
    sql = """DROP TABLE IF EXISTS %(out_table)s;
             CREATE TABLE %(out_table)s 
             (
                 hdf_index integer,
                 crb_model text,
                 nkwh integer[]
             );""" % sql_params
    cur.execute(sql)
    con.commit()
    
    sql = """COMMENT ON COLUMN %s.nkwh IS 'scale_offset = %s';""" % (out_table, scale_offset)
    cur.execute(sql)
    con.commit()    
    
    # open a string io file object to hold the data that will be copied to postgres
    f = StringIO()
    hf = h5py.File(os.path.join(hf_dir, hf_file), 'r')
    bldg_types = [k for k in hf.keys() if k <> 'meta']    
    for bldg_type in bldg_types:
        print 'Working on %s' % bldg_type
        fillvalue = hf[bldg_type].fillvalue
        # extract the masked data
        kwh = np.ma.masked_equal(hf[bldg_type], fillvalue)
        # find the annual sum in each column
        sum_year = np.ma.sum(kwh, 0)
        # normalize the max hours to the sums
        nkwh_masked = kwh/sum_year
        # build a reverse mask to use in extracting the data
        unmasked = np.invert(nkwh_masked.mask[0,:])
        # extract the data that is unmasked
        nkwh = np.round(nkwh_masked.data[:,unmasked].T*scale_offset,0).astype(int)
        nkwh_list = nkwh.tolist()
        # extract the indices that these correspond to
        hdf_index = np.arange(0, nkwh_masked.shape[0])[unmasked]
        # manually fix supermarket name formating
        if bldg_type == 'super_market':
            bldg_type = 'supermarket'        
        # combine this info into a pandas data frame
        df = pd.DataFrame()
        df['hdf_index'] = hdf_index
        df['crb_model'] = bldg_type
        df['nkwh'] = pd.Series(nkwh_list).apply(lambda l: '{%s}' % str(l)[1:-1])            
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
        


