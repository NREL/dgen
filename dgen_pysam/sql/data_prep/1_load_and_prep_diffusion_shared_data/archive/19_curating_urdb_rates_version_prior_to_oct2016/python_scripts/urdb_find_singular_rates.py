# -*- coding: utf-8 -*-
"""
Created on Thu Dec  4 14:57:57 2014

@author: mgleason
"""

import urdb_to_sam as u2s
import pandas as pd
import numpy as np
from batch_load_urdb_to_postgres import pg_connect, pg_params
from cStringIO import StringIO



def find_utilities_with_one_rate(rates_df):
    
    # find how many rates there are for each utility
    rate_count_by_utility = rates_df.groupby(['utility_name'], as_index = True).count()
    rate_count_by_utility.reset_index(level = 0, inplace = True)
    rate_count_by_utility.columns = ['utility_name','count']
    # limit to just the unique ones
    simple_utilities = rate_count_by_utility[rate_count_by_utility['count'] == 1]
    
    return simple_utilities

def get_verified_rates(res_com, con):
    
    if res_com.upper() not in ['R','C']:
        raise ValueError("res_com must be one of ['r','c']")
    
    # get rates
    sql = """SELECT urdb_rate_id as rate_key
            FROM urdb_rates.urdb3_verified_rates_lookup_20141202
            WHERE res_com = '%s';""" % res_com.upper()
    verified_rates = pd.read_sql(sql, con)
    verified_rate_keys = verified_rates['rate_key'].tolist()    
    
    return verified_rate_keys


def create_output_table(sql_params, cur, con):
    
    # add this info to postgres
    sql = """DROP TABLE IF EXISTS %(output_table)s ;
            CREATE TABLE %(output_table)s 
            (
                utility_name TEXT,
                urdb_rate_id TEXT,
                res_com CHARACTER VARYING(1),
                verified BOOLEAN,
                CONSTRAINT singular_rates_pkey PRIMARY KEY (urdb_rate_id, res_com),
                CONSTRAINT singular_rates_res_com_check CHECK (res_com::text = ANY (ARRAY['R'::character varying, 'C'::character varying]::text[]))
            );""" % sql_params
    cur.execute(sql)
    con.commit()


def main():
    

    # create connection and cursor object
    con, cur = pg_connect(pg_params)


    # create output table
    output_table = 'urdb_rates.urdb3_singular_rates_lookup_20141202'    
    sql_params = {'output_table': output_table}    
    create_output_table(sql_params, cur, con)    
    

    # open an in-memory stringio file
    f = StringIO()

    # get the rates that are lone rates (only rate in the utility district) for each sector
    sectors = ['residential', 'commercial']
    for sector in sectors:
        # set the res_com variable to the first letter of the sector
        res_com = sector[0]    
        
        # get all of the 'approved' rates from URDB for the sector
        rates_df = u2s.get_urdb_rate_keys_by_sector(sector)
        
        # isolate the utilities that only have one rate
        simple_utilities = find_utilities_with_one_rate(rates_df)
        print 'There are %s utilties with a single %s rate' % (simple_utilities.shape[0], sector)
        
        # extract the rate keys associated with the simple utilities
        lone_rates = pd.merge(simple_utilities, rates_df, how = 'inner', on = ['utility_name'])
        lone_rate_keys = lone_rates['rate_key'].tolist()
        
        # get the rate_keys for the "verified" rates
        verified_rate_keys = get_verified_rates(res_com, con)
        print "There are a total of %s 'verified' utility rates for %s in the database already" % (len(verified_rate_keys), sector)
           
        # how many new ones do we have that are lone rates
        new_rates = [r for r in lone_rate_keys if r not in verified_rate_keys]
        print "We will have an additional %s rates now" %  len(new_rates)
    
        # format the data for dumping to pg
        out_df = lone_rates[['utility_name','rate_key']]
        out_df.columns = ['utility_name','urdb_rate_id']
        # add additional fields
        out_df['res_com'] = res_com.upper()
        out_df['verified'] = out_df['urdb_rate_id'].isin(verified_rate_keys)
    
        out_df.to_csv(f, index = False, header = False)
    
    # seek to the beginning of the csv
    f.seek(0)    
    # copy the data from the stringio file to the postgres table
    cur.copy_expert("COPY %(output_table)s FROM STDOUT WITH CSV;" % sql_params, f)
    # commit the additions
    con.commit()    
    # close the stringio file (clears memory)
    f.close()



if __name__ == '__main__':
    main()