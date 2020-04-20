# -*- coding: utf-8 -*-
"""
Created on Mon Mar 03 09:53:27 2014

@author: mgleason
"""

import h5py
import psycopg2 as pg
from psycopg2 import extras as pgx
import numpy as np
# import pgdbUtil
# import hdfaccess
import glob
import os
import pandas as pd
from cStringIO import StringIO

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

# connect to pg
# conn, cur = pgdbUtil.pgdbConnect(True)

pg_params = {'host'     : 'localhost',
             'dbname'   : 'dav-gis',
             'user'     : 'mgleason',
             'password' : 'mgleason',
             'role'     : 'diffusion-writers',
             'port'     : 5432
             }

pg_conn_string = 'host=%(host)s dbname=%(dbname)s user=%(user)s password=%(password)s port=%(port)s' % pg_params
conn = pg.connect(pg_conn_string)
cur = conn.cursor(cursor_factory=pgx.RealDictCursor)

if 'role' in pg_params.keys():
    sql = "SET ROLE '%(role)s';" % pg_params
    cur.execute(sql)
    conn.commit()

schema = 'diffusion_resource_wind'
in_path = '/srv2/mgleason_backups/dwind_powercurves_update_2016_04_25'

hdfs = glob.glob1(in_path, '*.hdf5')
for hdf in hdfs:
    # split the turbine name
    filename_parts = hdf.split('_')
    turbine_i = 4
    turbine_id = int(filename_parts[turbine_i])

    # create the output table
    out_table = '%s.wind_resource_annual_turbine_%s' % (schema, turbine_id)
    print out_table
    
    # NOTE: Be sure to archive the table before dropping and replacing

    # create the table
    sql = 'DROP TABLE IF EXISTS %s;' % out_table
    cur.execute(sql)
    conn.commit()
    
    sql = """CREATE TABLE %s 
            (
                    i integer,
                    j integer,
                    cf_bin integer,
                    height integer,
                    aep numeric,
                    cf_avg numeric,
                    turbine_id integer
            );""" % out_table
    cur.execute(sql)
    conn.commit()
    
    print 'Loading %s to %s' % (hdf, out_table)

    # open hdf
    hf = h5py.File(os.path.join(in_path, hdf),'r')

    # get cf_bins
    cf_bins = [k for k in hf.keys() if 'cfbin' in k]

    # get ijs
    ijs = np.array(hf['meta'])

    for cf_bin in cf_bins:
        print 'Working on cf_bin = %s' % cf_bin
        heights = hf[cf_bin].keys()
        for height in heights:
            print '\tWorking on height = %s' % height
            # get aep data
            aep_path = '%s/%s/%s' % (cf_bin,height,'aep')
            aep = getFilteredData(hf,aep_path)
            # get avg cf data
            cf_avg_path = '%s/%s/%s' % (cf_bin,height,'cf_avg')
            cf_avg = getFilteredData(hf,cf_avg_path)
            # mask ijs data
            ijs_data = ijs[np.invert(aep.mask)]
            # combine into a dataframe
            df = pd.DataFrame(
                    data={
                        'i': ijs_data['i'],
                        'j': ijs_data['j'],
                        'cf_bin': int(cf_bin.split('_')[0])/10,
                        'height': height,
                        'aep': aep.data[np.invert(aep.mask)],
                        'cf_avg': cf_avg.data[np.invert(cf_avg.mask)],
                        'turbine_id': turbine_id                     
                   },
                   index = np.arange(0, np.shape(ijs_data)[0]))
            # dump to an in memory csv   
            print 'Writing to postgres'
            # open an in memory stringIO file (like an in memory csv)
            s = StringIO()
            # write the data to the stringIO
            columns = ['i', 'j', 'cf_bin', 'height', 'aep', 'cf_avg', 'turbine_id']
            df[columns].to_csv(s, index = False, header = False)
            # seek back to the beginning of the stringIO file
            s.seek(0)
            # copy the data from the stringio file to the postgres table
            cur.copy_expert('COPY %s FROM STDOUT WITH CSV' % out_table, s)
            # commit the additions and close the stringio file (clears memory)
            conn.commit()    
            s.close()   
    hf.close()

        