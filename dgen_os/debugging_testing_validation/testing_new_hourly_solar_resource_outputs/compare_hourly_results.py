# -*- coding: utf-8 -*-
"""
Created on Mon Jul  6 11:35:20 2015

@author: mgleason
"""

# -*- coding: utf-8 -*-
"""
Created on Mon Jul  6 11:14:48 2015

@author: mgleason
"""
import pandas as pd
import psycopg2 as pg
from psycopg2 import extras as pgx

pgConnString = "dbname=dav-gis user=mgleason password=mgleason host=gispgdb"
con = pg.connect(pgConnString)
cur = con.cursor(cursor_factory=pgx.DictCursor)

sql = '''select a.cf as new, b.cf as old
FROM diffusion_solar.solar_resource_hourly_new a
left join diffusion_solar.solar_resource_hourly b
ON a.tilt = b.tilt
and a.azimuth = b.azimuth
and a.solar_re_9809_gid = b.solar_re_9809_gid
limit 10'''
df = pd.read_sql(sql, con)



def f(row):
    
    row['diff'] = np.max(np.array(row['new'])/1000000.0 - np.array(row['old'])/1000000.0)
    
    return row

df['diff'] = df['new'] - df['old']

x = df.apply(f, axis = 1)

for i in range(0, df.shape[0]):
    old = pd.Series(df['old'][i][0:1000])
    new = pd.Series(df['new'][i][0:1000])
    ax = old.plot()
    ax = new.plot()
    fig = ax.get_figure()
    fig.savefig('/Users/mgleason/Desktop/untitled folder/%s.png' % i)
    fig.clear()
