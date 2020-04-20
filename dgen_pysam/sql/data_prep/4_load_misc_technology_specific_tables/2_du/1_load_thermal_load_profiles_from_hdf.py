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
pg_params = {'host'     : 'localhost',
             'dbname'   : 'dav-gis',
             'user'     : 'mgleason',
             'password' : 'mgleason',
             'role'     : 'diffusion-writers'
             }
hf_dir = '/home/shared/data/building_load/all_attributes/'
    
    
water_heating_attributes = ['gas_water_heating_kw']
space_heating_attributes = ['elec_heating_kw', 'gas_heating_kw']
space_cooling_attributes = ['elec_cooling_kw']

outputs = {
            'water_and_space_heating' : space_heating_attributes + water_heating_attributes,
            'water_heating' : water_heating_attributes,
            'space_heating' : space_heating_attributes,
            'space_cooling' : space_cooling_attributes
            }

 
          
# CONNECT TO POSTGRES
con, cur = pg_connect(pg_params)
scale_offset = 1e8
hf_files = ['res.h5','com.h5']
for hf_file in hf_files:
    # get the sector type
    sector = hf_file.split('.')[0]
    print sector
    
    # open the source hdf file
    hf = h5py.File(os.path.join(hf_dir, hf_file), 'r')
    
    for output_name, output_attributes in outputs.iteritems():
        print '\t%s' % output_name
        
        out_table = 'diffusion_load_profiles.energy_plus_normalized_%s_%s' % (output_name, sector)
        sql_params = {'out_table' : out_table}
        # create the output table in postgres    
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
        
        # define the building types based on the hdf keys
        bldg_types = [k for k in hf.keys() if k <> 'meta']    
        for bldg_type in bldg_types:
            print '\t\t%s' % bldg_type
            arrays = []
            masks = []
            for attribute in output_attributes:
                # point to the correct dataset based on the bldg type and attributes
                dataset_path = os.path.join(bldg_type, attribute)
                dataset = hf[dataset_path]
                # get the datasets
                fillvalue = dataset.fillvalue
                # extract the masked data
                kwh = np.ma.masked_equal(dataset, fillvalue)
                arrays.append(kwh)
                masks.append(kwh.mask)
            # sum the data across all arrays
            combined_mask = np.stack(masks).sum(axis = 0) > 0
            combined_kwh = np.stack(arrays).data.sum(axis = 0)
            combined_kwh_masked = np.ma.masked_array(combined_kwh, combined_mask)
            # find the annual sum in each column
            sum_year = np.ma.sum(combined_kwh_masked, 0)
            # normalize the max hours to the sums
            nkwh_masked = combined_kwh_masked/sum_year
            # where sum_year = 0, values will be nan -- so repalce with zeros
            nkwh_masked[:, sum_year == 0] = 0
            # also fix the mask
            nkwh_masked.mask = combined_mask
            # build a reverse mask to use in extracting the data
            unmasked = np.invert(nkwh_masked.mask[0,:])
            # extract the data that is unmasked
            nkwh = np.round(nkwh_masked.data[:, unmasked].T * scale_offset, 0).astype(int)
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
            # append to the stringio object
            df.to_csv(f, index = False, header = False, mode = 'a')
        # reset to the beginning of the stringio file
        f.seek(0)
        # copy the data from the stringio file to the postgres table
        cur.copy_expert("COPY %(out_table)s FROM STDOUT WITH CSV;" % sql_params, f)
        # commit the additions
        con.commit()    
        # close the stringio file (clears memory)
        f.close()       
    
    # close the hdf
    hf.close()

        


