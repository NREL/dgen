# -*- coding: utf-8 -*-
"""
Created on Fri Jan  8 15:21:15 2016

@author: mgleason
"""

import pandas as pd
import numpy as np
import cPickle
import config as cfg
import utility_functions as utilfunc
import psycopg2 as pg
from cStringIO import StringIO
import time
import pickle
from scipy import sparse
import pywt
import numba 


class SparseArray(object):
    
    def __init__(self, a, dtype, fill_value = 0, wavelets = False):
        
        a = np.array(a, dtype = dtype)
        
        non_fill_indices = np.where(a <> fill_value)[0]
        fill_indices = np.where(a == fill_value)[0]
        non_fill_data = a[non_fill_indices]
        
        self.wavelets = wavelets        
        if self.wavelets == True:
            coefs = pywt.wavedec(non_fill_data, 'db1')
            data = [x.tolist() for x in coefs]
        else:
            data = non_fill_data.tolist()
            
        self.data = data
        self.fvalue = fill_value
        self.shape = a.shape
        self.dtype = a.dtype
        
        if len(fill_indices) < len(non_fill_indices):
            self.slice = fill_indices.tolist()
            self.fill = True
        else:
            self.slice = non_fill_indices.tolist()
            self.fill = False
    
    def to_dense(self):
        
        a = np.ones(self.shape, self.dtype) * self.fvalue
        if self.wavelets == True:  
            coefs = [np.array(x) for x in self.data]
            data = pywt.waverec(coefs, 'db1')
        else:
            data = self.data
            
        if self.fill == False:
            a[self.slice] = np.array(data, self.dtype)
        else:
            mask = np.ones(a.shape, dtype = bool)
            mask[self.slice] = False
            a[mask] = np.array(data, self.dtype)
        
        return a

def list_to_sparse_components(row, col, data_col, index_col, fill_col, fill_value_col, fill_value = 0, dtype = 'int64'):
    
    sparse_data = SparseArray(row[col], fill_value = fill_value, dtype = dtype)
    row[data_col] = sparse_data.data
    row[index_col] = sparse_data.slice
    row[fill_col] = sparse_data.fill
    row[fill_value_col] = sparse_data.fvalue
    
    return row

def list_to_sparse(row, col, new_col, fill_value = 0, dtype = 'int64', flavor = 'custom', wavelets = False):
    
    if flavor == 'custom':
        sparse_data = SparseArray(row[col], fill_value = fill_value, dtype = dtype, wavelets = wavelets)
    elif flavor == 'pandas':
        sparse_data = pd.SparseArray(row[col], fill_value = fill_value, dtype = dtype)
    else:
        raise TypeError()
        
    row[new_col] = sparse_data
    
    return row
    
def apply_cpickle(row, col, new_col, pg_binary = True, protocol = 2):
    
    pkl = cPickle.dumps(row[col], protocol = protocol)
    if pg_binary == True:
        bts = pg.Binary(pkl)
    else:
        bts = pkl
        
    row[new_col] = bts
    
    return row

def bytea_to_list(row, col, new_col):
    
    l = cPickle.loads(str(row[col])).to_dense()
    row[new_col] = l
    
    return row

def to_pg_array(a):
    
    pg_a = "'{%s}'" % str(a)[1:-1]

    return pg_a
    
con, cur = utilfunc.make_con(cfg.pg_conn_string)
sql = "SET ROLE mgleason;"
cur.execute(sql)
con.commit()

def load_data(row_count, offset):
    sql = """SELECT cf
           FROM diffusion_wind.wind_resource_hourly
           OFFSET %s
           LIMIT %s""" % (offset, row_count)
    df = pd.read_sql(sql, con)
    
    df = df.apply(list_to_sparse, axis = 1, args = ('cf', 'cf_pds', 0, 'int16', 'pandas'))
    df = df.apply(apply_cpickle, axis = 1, args = ('cf_pds', 'cf_pdb'))
    
    df = df.apply(list_to_sparse, axis = 1, args = ('cf', 'cf_cs', 0, 'int16', 'custom'))
    df = df.apply(apply_cpickle, axis = 1, args = ('cf_cs', 'cf_cb'))
    
    df = df.apply(list_to_sparse, axis = 1, args = ('cf', 'cf_cw', 0, 'int16', 'custom', True))
    df = df.apply(apply_cpickle, axis = 1, args = ('cf_cw', 'cf_cwb'))
    
#    df2 = df.apply(list_to_sparse_components, axis = 1, args = ('cf', 'data', 'slice', 'fill', 'fill_value', 0, 'int16'))
    
    
#    sql = """DROP TABLE IF EXISTS mgleason.sparse_components;
#            CREATE TABLE mgleason.sparse_components
#            (
#                	data smallint[],
#                  slice smallint[],
#                  fill boolean,
#                  fill_value smallint
#            );
#            
#            """
#    cur.execute(sql)
#    con.commit()
#    
#    for row in df2.iterrows():
#        sql = "INSERT INTO mgleason.sparse_components VALUES (%s, %s, %s, %s)" % (to_pg_array(row[1]['data']), to_pg_array(row[1]['slice']), row[1]['fill'], row[1]['fill_value']) 
#        cur.execute(sql)
#        con.commit()    
        
        
    
    sql = """DROP TABLE IF EXISTS mgleason.sparse_data_pandas;
            CREATE TABLE mgleason.sparse_data_pandas
            (
                	cf bytea
            );
            
            """
    cur.execute(sql)
    con.commit()
    
    for row in df.iterrows():
        sql = "INSERT INTO mgleason.sparse_data_pandas VALUES (%s)" % row[1]['cf_pdb']
        cur.execute(sql)
        con.commit()
    
    
    
    sql = """DROP TABLE IF EXISTS mgleason.sparse_data_custom;
            CREATE TABLE mgleason.sparse_data_custom
            (
                	cf bytea
            );
            
            """
    cur.execute(sql)
    con.commit()
    
    for row in df.iterrows():
        sql = "INSERT INTO mgleason.sparse_data_custom VALUES (%s)" % row[1]['cf_cb']
        cur.execute(sql)
        con.commit()
    # doesnt work because of the extra text added by pg.Binary()
    #s = StringIO()
    ## write the data to the stringIO
    #df['cfb'].to_csv(s, index = False, header = False)
    ## seek back to the beginning of the stringIO file
    #s.seek(0)
    ## copy the data from the stringio file to the postgres table
    #cur.copy_expert('COPY mgleason.sparse_data FROM STDOUT WITH CSV', s)
    ## commit the additions and close the stringio file (clears memory)
    #con.commit()    
    #s.close()

#    sql = """DROP TABLE IF EXISTS mgleason.sparse_data_custom_wavelets;
#            CREATE TABLE mgleason.sparse_data_custom_wavelets
#            (
#                	cf bytea
#            );
#            
#            """
#    cur.execute(sql)
#    con.commit()
#    
#    for row in df.iterrows():
#        sql = "INSERT INTO mgleason.sparse_data_custom_wavelets VALUES (%s)" % row[1]['cf_cwb']
#        cur.execute(sql)
#        con.commit()


    sql = """DROP TABLE IF EXISTS mgleason.regular_data;
            CREATE TABLE mgleason.regular_data AS
            SELECT cf::INTEGER[8760]
            FROM diffusion_wind.wind_resource_hourly
            OFFSET %s
            LIMIT %s;""" % (offset, row_count)
    cur.execute(sql)
    con.commit()


    sql = """DROP TABLE IF EXISTS mgleason.smallint_data;
            CREATE TABLE mgleason.smallint_data AS
            SELECT cf::SMALLINT[8760]
            FROM diffusion_wind.wind_resource_hourly
            OFFSET %s
            LIMIT %s;""" % (offset, row_count)
    cur.execute(sql)
    con.commit()

t0 = time.time()
load_data(100, 80000)
print 'Load Time: %s' % (time.time()-t0, )

t0 = time.time()
sql = """SELECT cf as cf_bytes
         FROM mgleason.sparse_data_pandas;"""
df_pd = pd.read_sql(sql, con)
df_pd = df_pd.apply(bytea_to_list, axis = 1, args = ('cf_bytes', 'cf'))
print 'Pandas Sparse Data: %s' % (time.time()-t0, )


t0 = time.time()
sql = """SELECT cf as cf_bytes
         FROM mgleason.sparse_data_custom;"""
df_custom = pd.read_sql(sql, con)
df_custom = df_custom.apply(bytea_to_list, axis = 1, args = ('cf_bytes', 'cf'))
print 'Custom Sparse Data: %s' % (time.time()-t0, )
   
   
#t0 = time.time()
#sql = """SELECT cf as cf_bytes
#         FROM mgleason.sparse_data_custom_wavelets;"""
#df_custom_waves = pd.read_sql(sql, con)
#df_custom_waves = df_custom_waves.apply(bytea_to_list, axis = 1, args = ('cf_bytes', 'cf'))
#print 'Custom Sparse Wavelets Data: %s' % (time.time()-t0, )   
   
   
   
t0 = time.time()
sql = """SELECT cf
         FROM mgleason.regular_data;"""
df_regular = pd.read_sql(sql, con)
print 'Regular Data: %s' % (time.time()-t0, )



t0 = time.time()
sql = """SELECT cf
         FROM mgleason.smallint_data;"""
df_smallint = pd.read_sql(sql, con)
print 'SMALLINT Data: %s' % (time.time()-t0, )



#t0 = time.time()
#sql = """SELECT *
#         FROM mgleason.sparse_components;"""
#df_components = pd.read_sql(sql, con)
#print 'Sparse Components Data: %s' % (time.time()-t0, )


a_pd = np.array(df_pd['cf'].tolist())
a_custom = np.array(df_custom['cf'].tolist())
#a_custom_waves = np.array(df_custom_waves['cf'].tolist())
a_regular = np.array(df_regular['cf'].tolist())
print np.all(a_pd == a_custom)
#print np.all(a_pd == a_custom_waves)#
print np.all(a_pd == a_regular)
# test taht all data match


#a = dfs['cf'][20].astype('int')
#
#
#pref = pickle.dumps(pd.SparseArray(a, fill_value = 0), protocol = 2)
#
#s = SparseArray(a, dtype = 'int')        
#p = pickle.dumps(s, protocol = 2)
#len(pickle.dumps(a, protocol = 2))
#len(pref)
#len(p)
#
#np.all(s.to_dense() == a)

#pickle.dumps(z)

