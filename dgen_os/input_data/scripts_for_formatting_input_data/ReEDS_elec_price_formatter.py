# -*- coding: utf-8 -*-
"""
Created on Sun Mar 26 17:59:55 2017

@author: pgagnon
"""

import pandas as pd
import numpy as np
import os
os.chdir('/Users/kmccabe/Projects/diffusion/input_data/scripts_for_formatting_input_data')


# specify file name for price inputs
file_name = '../unformatted_input_data/2018_Standard_Scenarios_dGen_Price_Inputs.csv'

# read in scenario matrix
scen_definition = pd.read_csv('SS18_definition.csv')

# read in region mapping files
region_map = pd.read_csv('ReEDS_census_division_map.csv')
cen_div_to_state = pd.read_csv('state_to_census_regions_divs_lkup.csv')

# read in price inputs
elec_price_df = pd.read_csv(file_name)
# cleanup - rename columns, fix census division abbr for Pacific (pa -> pac), capitalize census division abbrs
elec_price_df.rename(columns={'censusregions':'census_division_abbr','Price (2015$/MWh)':'value'}, inplace=True)
elec_price_df['census_division_abbr'] = np.where(elec_price_df['census_division_abbr'].str.lower() == 'pa', 'pac', elec_price_df['census_division_abbr'])
elec_price_df['census_division_abbr'] = elec_price_df['census_division_abbr'].str.upper()

# reformat table to wide format
elec_price_df = elec_price_df.pivot_table(index=['scenario', 'census_division_abbr', 'type'], columns='year', values='value').reset_index(drop = False)

# add missing year data by interpolating between neighboring years
missing_years = np.arange(2015, 2050, 2)
for year in missing_years:
    elec_price_df[year] = (elec_price_df[(year-1)] + elec_price_df[(year+1)]) / 2

# reformat table to tidy format
elec_price_df = pd.melt(elec_price_df, id_vars = ['scenario', 'census_division_abbr', 'type'], var_name = 'year')

# use full list of scenario names from scenario matrix
scen_names = list(pd.unique(scen_definition['reeds_scen_name']))
price_types = ['Competitive', 'Regulated']

# loop through all scenarios and all price types (retail and wholesale)
for scen in scen_names:
    for price_type in price_types:
        scen_df = elec_price_df[elec_price_df.type == price_type]
        
        # if no data exists from ReEDS for specific scenario, use mid case data
        if scen not in list(pd.unique(elec_price_df['scenario'])):
            print scen
            scen_df = scen_df[scen_df.scenario == 'Mid_Case_final']
        else:
            scen_df = scen_df[scen_df.scenario == scen]
        
        # process retail rates and write to csv
        if price_type == 'Regulated':
            scen_df['value'] = scen_df.value * (1 - 0.0012) / 1000 # convert to 2014$ and from $/MWh to $/kWh
            scen_df.rename(columns={'value':'elec_price_res'}, inplace=True)
            scen_df['elec_price_com'] = scen_df.elec_price_res
            scen_df['elec_price_ind'] = scen_df.elec_price_res
            if '_final' in scen: 
                scen_file_name = scen[:-6]
            else:
                scen_file_name = scen
            scen_df.drop(['type', 'scenario'], axis=1).to_csv('../elec_prices/ATB18_%s_retail.csv' % scen_file_name, index=False)
        # process wholesale rates and write to csv
        else:
            scen_df['value'] = scen_df.value * (1 - 0.0012) / 1000 # convert to 2014$ and from $/MWh to $/kWh
            scen_df = scen_df.merge(cen_div_to_state[['state_abbr', 'census_division_abbr']], on='census_division_abbr')
            scen_df = scen_df.pivot_table(index=['state_abbr', 'census_division_abbr', 'scenario'], columns='year', values='value').reset_index(drop = False)
            if '_final' in scen: 
                scen_file_name = scen[:-6]
            else:
                scen_file_name = scen                
            scen_df.drop(['census_division_abbr', 'scenario'], axis=1).to_csv('../wholesale_electricity_prices/ATB18_%s_wholesale.csv' % scen_file_name, index=False)
    



##### DEPRECATED #####
#for file_name in file_names:
#    print file_name
#    
#    # Import the ReEDS file
#    elec_price_df = pd.read_csv(file_name)
#    
#    # Merge on census divisions and drop unnecessary columns
#    elec_price_df = pd.merge(elec_price_df, region_map[['census_division_abbr', 'id']], on=['id'])
#    elec_price_df.drop(['type', 'id'], axis=1, inplace=True)
#    
#    # Fill in the odd years with linear interpolation of even years
#    missing_years = np.arange(2011, 2050, 2)
#    for year in missing_years:
#        elec_price_df[str(year)] = (elec_price_df[str(year-1)] + elec_price_df[str(year+1)]) / 2
#        
#    # Formatting for melt
#    elec_price_df.set_index('census_division_abbr', inplace=True)
#    elec_price_df = elec_price_df.transpose()
#    elec_price_df.reset_index(inplace=True)
#    elec_price_df.rename(columns={'index':'year'}, inplace=True)
#    
#    # Melt
#    elec_price_df_melted = pd.melt(elec_price_df, id_vars='year', value_name='elec_price_res')
#    
#    # Change from $/MWh to $/kWh
#    elec_price_df_melted['elec_price_res'] = elec_price_df_melted['elec_price_res'] / 1000.0
#    
#    # All sectors are the same, since ReEDS does not differentiate
#    elec_price_df_melted['elec_price_com'] = elec_price_df_melted['elec_price_res']
#    elec_price_df_melted['elec_price_ind'] = elec_price_df_melted['elec_price_res']
#    
#    # Write formatted results
#    elec_price_df_melted.to_csv(output_dir + file_name, index=False)