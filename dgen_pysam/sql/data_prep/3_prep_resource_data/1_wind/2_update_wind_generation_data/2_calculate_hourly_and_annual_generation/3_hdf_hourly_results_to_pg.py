# -*- coding: utf-8 -*-
"""
Created on Mon Mar 03 09:53:27 2014

@author: mgleason
"""

import h5py
import psycopg2 as pg
import psycopg2.extras as pgx
import numpy as np
# import pgdbUtil
# import hdfaccess
import glob
import os
import pandas as pd
from cStringIO import StringIO
import multiprocessing

 
def getFilteredData(hfile,path,indices = [], mask = None):
    '''
    Return the filtered data, scale factor, fill value mask, and optionally list of indexes. If indices is not specified, data for all locations will be returned

    hfile = an HDF file object
    path = string giving the path to the dataset of interest in the hfile
    indices = optional list of indices for which to get data (indicating different cell locations)
    '''

    # find the scale factor (if it exists)
    if 'scale_factor' in hfile[path].attrs.keys():
        scale_factor =  hfile[path].attrs['scale_factor']
    else:
        scale_factor = 1 # this will have no effect when multiplied against the array

    # find the fill_value (if it exists)
    if 'fill_value' in hfile[path].attrs.keys():
        fill_value =  hfile[path].attrs['fill_value']
    elif hfile[path].fillvalue <> 0: # this is the default if a fill value isn't set
        fill_value = hfile[path].fillvalue
    else:
        fill_value = None # this will have no effect on np.ma.masked_equal()

    # get data, masking fill_value and applying scale factor
    extract = np.ma.masked_equal(hfile[path], fill_value) * scale_factor
    if indices <> []:
        # Extract the subset
        data = extract[indices]
    else:
        data = extract

    if mask is not None:
        result = np.ma.masked_array(data,mask)
    else:
        result = data

    return result

def pg_connect(pg_params):
    pg_conn_string = 'host=%(host)s dbname=%(dbname)s user=%(user)s password=%(password)s port=%(port)s' % pg_params
    con = pg.connect(pg_conn_string)
    cur = con.cursor(cursor_factory=pgx.RealDictCursor)
    
    if 'role' in pg_params.keys():
        sql = "SET ROLE '%(role)s';" % pg_params
        cur.execute(sql)
        con.commit()
    
    return con, cur


def hdf2pg(hdf, hdf_path, pg_params, schema, scale_offset):
    
    pg_conn_string = 'host=%(host)s dbname=%(dbname)s user=%(user)s password=%(password)s port=%(port)s' % pg_params
    con = pg.connect(pg_conn_string)
    cur = con.cursor(cursor_factory=pgx.RealDictCursor)

    if 'role' in pg_params.keys():
        sql = "SET ROLE '%(role)s';" % pg_params
        cur.execute(sql)
        con.commit()

    # split the turbine name
    filename_parts = hdf.split('_')
    turbine_i = 4
    turbine_id = int(filename_parts[turbine_i])
    
    # create the output table
    out_table = '%s.wind_resource_hourly_turbine_%s' % (schema, turbine_id)
    
    # create the table
    sql = 'DROP TABLE IF EXISTS %s;' % out_table
    cur.execute(sql)
    con.commit()
    
    sql = """CREATE TABLE %s (
                cf SMALLINT[],
                i integer,
                j integer,
                cf_bin integer,
                height integer,
                turbine_id integer
            );""" % out_table
    cur.execute(sql)
    con.commit()
    
    sql = """COMMENT ON COLUMN %s.cf IS 'scale_offset = %s';""" % (out_table, scale_offset)
    cur.execute(sql)
    con.commit()

    hf = h5py.File(os.path.join(hdf_path, hdf),'r')
    
    cf_bins = [k for k in hf.keys() if 'cfbin' in k]
    
    ijs = np.array(hf['meta'])

    for cf_bin in cf_bins:
        print 'Working on cf_bin = %s' % cf_bin
        heights = hf[cf_bin].keys()
        for height in heights:
            print '\tWorking on height = %s' % height
            cf_path = '%s/%s/%s' % (cf_bin,height,'cf_hourly')
            cf = getFilteredData(hf, cf_path)
            unmasked = np.invert(cf.mask)[:,0]
            cf_list = np.trunc(cf[unmasked,:]*scale_offset).astype(int).tolist()
            ijs_data = ijs[unmasked]

            df = pd.DataFrame()
            df['cf'] = pd.Series(cf_list).apply(lambda l: '{%s}' % str(l)[1:-1])
            df['i'] = ijs_data['i']
            df['j'] = ijs_data['j']
            df['cf_bin'] = int(cf_bin.split('_')[0])/10
            df['height'] = int(height)
            df['turbine_id'] = turbine_id
            
            # dump to a csv (can't use in memory because it is too large)
#            print 'Writing to postgres'
#            for i in range(0,df.shape[0]):
#                sql = 'INSERT INTO %s VALUES %s;' % (out_table, tuple(df.ix[i].values))
#                cur.execute(sql)
#                con.commit()

            
            nrows = df.shape[0]
            block_size = np.min([10000, nrows])
            nblocks = np.ceil(nrows/block_size)
            blocks = np.array_split(df.index, nblocks)
            print 'Writing to postgres'
            for block in blocks:
                s = StringIO()         
                df.ix[block].to_csv(s, index = False, header = False)
                # seek back to the beginning of the stringIO file
                s.seek(0)
                # copy the data from the stringio file to the postgres table
                cur.copy_expert('COPY %s FROM STDOUT WITH CSV' % out_table, s)
                # commit the additions and close the stringio file (clears memory)
                con.commit()    
                s.close()

    hf.close()    

    return hdf
    
# INPUTS
pg_params = {'host'     : 'localhost',
             'dbname'   : 'dav-gis',
             'user'     : 'mgleason',
             'password' : 'mgleason',
             'role'     : 'diffusion-writers',
             'port'     : 5432
             }
schema = 'diffusion_resource_wind'
scale_offset = 1e3
in_path = '/srv2/mgleason_backups/dwind_powercurves_update_2016_04_25'

# MAIN
# set up pool of workers

# initialize results object
result_list = []
# get list of hdf files
hdfs = glob.glob1(in_path, '*.hdf5')
pool = multiprocessing.Pool(processes = 2)
# kick off loading process 
for hdf in hdfs:
    res = pool.apply_async(hdf2pg, (hdf, in_path, pg_params, schema, scale_offset))
    result_list.append(res)  

for result in result_list:
    msg = result.get()
    print 'Finished %s' % msg