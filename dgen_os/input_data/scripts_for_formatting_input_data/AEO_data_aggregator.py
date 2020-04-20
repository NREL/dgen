# -*- coding: utf-8 -*-
"""
Created on Fri Mar 10 15:20:21 2017

@author: pgagnon
"""

import pandas as pd

input_dir = 'workspace_for_data_aggregation'

divisions = ['New_England', 'Middle_Atlantic', 'East_North_Central', 'West_North_Central', 'South_Atlantic',
           'East_South_Central', 'West_South_Central', 'Mountain', 'Pacific']
           
division_map = {'New_England':'NE', 
              'Middle_Atlantic':'MA', 
              'East_North_Central':'ENC', 
              'West_North_Central':'WNC', 
              'South_Atlantic':'SA',
              'East_South_Central':'ESC', 
              'West_South_Central':'WSC', 
              'Mountain':'MTN', 
              'Pacific':'PAC'}
               
conversion_2016_to_2014 = 0.98637
MMBtu_to_kWh = 0.003412

all_regions_df = pd.DataFrame()
           
for region in divisions:
    region_file_path = input_dir + '/Energy_Prices_(Case_Reference_case_Region_%s).csv' % region
    region_df = pd.read_csv(region_file_path, header=4)
    region_df['census_division_abbr'] = division_map[region]
    
    region_df.rename(columns={'Residential: Electricity 2016 $/MMBtu':'elec_price_res',
                              'Commercial: Electricity 2016 $/MMBtu':'elec_price_com',
                              'Industrial: Electricity 2016 $/MMBtu':'elec_price_ind',
                              'Year':'year'}, inplace=True)

    # Convert to the correct dollar year, and then correct units                              
    region_df[['elec_price_res', 'elec_price_com', 'elec_price_ind']] = conversion_2016_to_2014 * region_df[['elec_price_res', 'elec_price_com', 'elec_price_ind']]
    region_df[['elec_price_res', 'elec_price_com', 'elec_price_ind']] = MMBtu_to_kWh * region_df[['elec_price_res', 'elec_price_com', 'elec_price_ind']]
    
    all_regions_df = pd.concat([all_regions_df, region_df], ignore_index=True)
    
all_regions_df.to_csv(input_dir + '/AEO2016_Reference_case.csv')
