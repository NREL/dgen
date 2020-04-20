# -*- coding: utf-8 -*-
"""
Created on Mon Jan 11 11:16:53 2016

@author: bsigrin
"""

import urllib2
import pandas as pd
import json
import itertools


sectors = ['RES','IDAL','COMM']
regions = ['NEENGL','MDATL','ENC','WNC','SOATL','ESC','WSC','MTN','PCF']
scenarios = ['REF2015','HIGHMACRO','LOWMACRO','LOWPRICE','HIGHRESOURCE','HIGHPRICE']
energy = ['ELC', 'DFO', 'NG', 'PROP']


params_list = [dict(zip(['sector', 'region', 'scenario', 'energy'], t)) for t in itertools.product(sectors, regions, scenarios, energy)]

# Iterate over sector, region, and scenario to pull the table via the API
df1 = pd.DataFrame()
for params in params_list:
     
            url = 'http://api.eia.gov/series/?api_key=7D4BEDC1881B2AAC518E832AC04FF8AA&series_id=AEO.2015.%(scenario)s.PRCE_REAL_%(sector)s_NA_%(energy)s_NA_%(region)s_Y13DLRPMMBTU.A' % params
            
            raw = urllib2.urlopen(url).read()
            jso = json.loads(raw)
            data_series = jso['series'][0]['data']            
            temp_df = pd.DataFrame(data_series)
            temp_df.columns = ['year','dlrs_per_mmbtu']
            for k, v in params.iteritems():
                temp_df[k] = v
                
            df1 = df1.append(temp_df, ignore_index = True)
                   
# The 2015 AEO doesn't have a low resource scenario, so pull that one in a separate call
df2 = pd.DataFrame()
sectors = ['RES','IDAL','CMM']
scenarios = ['LOWRESOURCE']
params_list = [dict(zip(['sector', 'region', 'scenario', 'energy'], t)) for t in itertools.product(sectors, regions, scenarios, energy)]

for params in params_list:
    url = 'http://api.eia.gov/series/?api_key=7D4BEDC1881B2AAC518E832AC04FF8AA&series_id=AEO.2014.%(scenario)s.PRCE_ENE_%(sector)s_NA_%(energy)s_NA_%(region)s_Y12DLRPMMBTU.A' % params
    
    raw = urllib2.urlopen(url).read()
    jso = json.loads(raw)
    data_series = jso['series'][0]['data']            
    temp_df = pd.DataFrame(data_series)
    temp_df.columns = ['year','dlrs_per_mmbtu']
    for k, v in params.iteritems():
        temp_df[k] = v
        
    df2 = df2.append(temp_df, ignore_index = True)

df = df1.append(df2, ignore_index = True)            

#Replace strings with codes we use
df['scenario'] = df['scenario'].replace({'REF2015': 'AEO2015 Reference'}, regex=True)
df['scenario'] = df['scenario'].replace({'HIGHMACRO': 'AEO2015 High Growth'}, regex=True)
df['scenario'] = df['scenario'].replace({'LOWMACRO': 'AEO2015 Low Growth'}, regex=True)
df['scenario'] = df['scenario'].replace({'LOWPRICE': 'AEO2015 Low Prices'}, regex=True)
df['scenario'] = df['scenario'].replace({'HIGHRESOURCE': 'AEO2015 High Resource'}, regex=True)
df['scenario'] = df['scenario'].replace({'HIGHPRICE': 'AEO2015 High Prices'}, regex=True)
df['scenario'] = df['scenario'].replace({'LOWRESOURCE': 'AEO2015 Low Resource'}, regex=True)
          
df['sector'] = df['sector'].replace({'RES': 'res'}, regex=True)
df['sector'] = df['sector'].replace({'IDAL': 'ind'}, regex=True)
df['sector'] = df['sector'].replace({'COMM': 'com'}, regex=True)
df['sector'] = df['sector'].replace({'CMM': 'com'}, regex=True)

df['region'] = df['region'].replace({'NEENGL': 'NE'}, regex=True)
df['region'] = df['region'].replace({'MDATL': 'MA'}, regex=True)
df['region'] = df['region'].replace({'SOATL': 'SA'}, regex=True)
df['region'] = df['region'].replace({'PCF': 'PAC'}, regex=True)

df['energy'] = df['energy'].replace({'ELC': 'electricity'}, regex=True)
df['energy'] = df['energy'].replace({'DFO': 'distallate fuel oil'}, regex=True)
df['energy'] = df['energy'].replace({'NG': 'natural gas'}, regex=True)
df['energy'] = df['energy'].replace({'PROP': 'propane'}, regex=True)



#Two more transformations: Normalize to the 2014 value and extend forecast to 2080 (keep price constant in real terms based on 2040 values)

df['year'] = df['year'].astype(int)
df_2040 = df[df['year'] == 2040]

final_df = df.copy()
for year in range(2041, 2081):
    new_rows = df_2040.copy()
    new_rows['year'] = year
    
    final_df = final_df.append(new_rows, ignore_index = False)
    
final_df.to_csv('/Volumes/Staff/mgleason/dGeo/Data/Source_Data/EIA_AEO_2015_Energy_Prices/aeo_2015_energy_price_projections.csv', index = False)
