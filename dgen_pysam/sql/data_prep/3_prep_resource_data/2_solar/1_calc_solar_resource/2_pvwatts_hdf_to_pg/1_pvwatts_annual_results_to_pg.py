# -*- coding: utf-8 -*-
"""
Created on Mon Mar 03 09:53:27 2014

@author: mgleason
"""

import h5py
import psycopg2 as pg
import numpy as np
import psycopg2.extras as pgx
import sys
import glob
import pandas as pd
from cStringIO import StringIO
import os


# define a dictionary for converting azimuth to a nominal direction
orientations = {180: 'S',
                135: 'SE',
                225: 'SW',
                90: 'E',
                270: 'W'
                }

# connect to pg
print 'Connecting to postgres'
pgConnString = "dbname=dav-gis user=mgleason password=mgleason host=gispgdb"
con = pg.connect(pgConnString)
cur = con.cursor(cursor_factory=pgx.DictCursor)
sql = "SET ROLE 'diffusion-writers';"
cur.execute(sql)
con.commit()


# create the output table
print 'Creating output tables'
out_table_template = 'diffusion_solar.solar_resource_annual_%s'

for azimuth in orientations.values():
    out_table = out_table_template % azimuth.lower()
    
    # create the table
    sql = 'DROP TABLE IF EXISTS %s;' % out_table
    cur.execute(sql)
    con.commit()
    
    sql = '''CREATE TABLE %s 
            (
                solar_re_9809_gid INTEGER,
                tilt NUMERIC,
                azimuth CHARACTER VARYING(2),
                naep NUMERIC,
                cf_avg NUMERIC
            );''' % out_table
    cur.execute(sql)
    con.commit()

# get the hdfs
print 'Finding hdf files'
#hdf_path = '/Users/mgleason/gispgdb/data/dg_solar/cf'
hdf_path = '/home/mgleason/data/dg_solar/cf'

hdfs = [os.path.join(hdf_path,f) for f in glob.glob1(hdf_path,'*.h5')]

for hdf in hdfs:
    print 'Loading %s' % hdf
    # open the h5 file
    hf = h5py.File(hdf, mode = 'r')
    
    # get the gids
    gids_all = np.array(hf['index'])
    # find gid for solar_re_9809_gid = 3101 (no data due to bad/missing tmy file)
    subset = np.where(gids_all <> 3101)[0]
    gids = gids_all[subset]
    del gids_all
    
    # calculate the total normalized aep
    naep = np.sum(np.array(hf['cf'][:,subset], dtype = np.float),0)
    cf_avg = np.mean(np.array(hf['cf'][:,subset], dtype = np.float),0)
    
    # get the tilt (making sure it's not tilted at latitude)
    tilt = hf['cf'].attrs['tilt']
    if tilt == -1:
        print 'Warning: Tilt was set to tilt at latitude'
#        sys.exit(-1)
    
    # get the azimuth
    azimuth = orientations[hf['cf'].attrs['azimuth']]
    # set the correct output table
    out_table = out_table_template % azimuth.lower()
    
    # combine into pandas dataframe
    df = pd.DataFrame(data={'solar_re_9809_gid' : gids,
                       'tilt' : tilt,
                       'azimuth' : azimuth,
                       'naep' : naep,
                       'cf_avg' : cf_avg
                       },
                       index = np.arange(0,np.shape(gids)[0]))
    
    # dump to an in memory csv   
    # open an in memory stringIO file (like an in memory csv)
    print 'Writing to postgres'
    s = StringIO()
    # write the data to the stringIO
    columns = ['solar_re_9809_gid','tilt','azimuth','naep','cf_avg']
    df[columns].to_csv(s, index = False, header = False)
    # seek back to the beginning of the stringIO file
    s.seek(0)
    # copy the data from the stringio file to the postgres table
    cur.copy_expert('COPY %s FROM STDOUT WITH CSV' % out_table, s)
    # commit the additions and close the stringio file (clears memory)
    con.commit()    
    s.close()    
    
    # close the hdf file
    hf.close()
        