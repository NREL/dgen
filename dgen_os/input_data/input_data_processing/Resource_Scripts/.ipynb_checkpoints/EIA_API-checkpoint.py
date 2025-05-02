import requests
import time
import pandas as pd
import numpy as np

# API Key from EIA
api_key = '75Fb2LqLyK0yIDO2LNW5Zh9rqgvcQuUeeb08SfKE'

# FOr each region (number 1-25), pull data and append to empty df 
final_data = []
for i in range(0,25):
    val = i+1
    
    url = 'https://api.eia.gov/v2/aeo/2023/data/?frequency=annual&data[0]=value&facets[regionId][]=5-' + str(val) +'&facets[scenario][]=aeo2022ref&facets[scenario][]=highmacro&facets[scenario][]=highprice&facets[scenario][]=highupIRA&facets[scenario][]=lowmacro&facets[scenario][]=lowprice&facets[scenario][]=lowupIRA&facets[scenario][]=noIRA&facets[scenario][]=ref2023&facets[seriesId][]=prce_NA_comm_NA_elc_NA_flrc_ncntpkwh&facets[seriesId][]=prce_NA_comm_NA_elc_NA_mcc_ncntpkwh&facets[seriesId][]=prce_NA_comm_NA_elc_NA_mce_ncntpkwh&facets[seriesId][]=prce_NA_comm_NA_elc_NA_mcs_ncntpkwh&facets[seriesId][]=prce_NA_comm_NA_elc_NA_mcw_ncntpkwh&facets[seriesId][]=prce_NA_comm_NA_elc_NA_nenycli_ncntpkwh&facets[seriesId][]=prce_NA_comm_NA_elc_NA_npccne_ncntpkwh&facets[seriesId][]=prce_NA_comm_NA_elc_NA_npccupny_ncntpkwh&facets[seriesId][]=prce_NA_comm_NA_elc_NA_pjmce_ncntpkwh&facets[seriesId][]=prce_NA_comm_NA_elc_NA_pjmd_ncntpkwh&facets[seriesId][]=prce_NA_comm_NA_elc_NA_pjme_ncntpkwh&facets[seriesId][]=prce_NA_comm_NA_elc_NA_pjmw_ncntpkwh&facets[seriesId][]=prce_NA_comm_NA_elc_NA_serccnt_ncntpkwh&facets[seriesId][]=prce_NA_comm_NA_elc_NA_serce_ncntpkwh&facets[seriesId][]=prce_NA_comm_NA_elc_NA_sercsoes_ncntpkwh&facets[seriesId][]=prce_NA_comm_NA_elc_NA_swppc_ncntpkwh&facets[seriesId][]=prce_NA_comm_NA_elc_NA_swppno_ncntpkwh&facets[seriesId][]=prce_NA_comm_NA_elc_NA_swppso_ncntpkwh&facets[seriesId][]=prce_NA_comm_NA_elc_NA_tre_ncntpkwh&facets[seriesId][]=prce_NA_comm_NA_elc_NA_weccb_ncntpkwh&facets[seriesId][]=prce_NA_comm_NA_elc_NA_wecccan_ncntpkwh&facets[seriesId][]=prce_NA_comm_NA_elc_NA_wecccas_ncntpkwh&facets[seriesId][]=prce_NA_comm_NA_elc_NA_weccrks_ncntpkwh&facets[seriesId][]=prce_NA_comm_NA_elc_NA_weccsw_ncntpkwh&facets[seriesId][]=prce_NA_comm_NA_elc_NA_wenwpp_ncntpkwh&facets[seriesId][]=prce_NA_idal_NA_elc_NA_flrc_ncntpkwh&facets[seriesId][]=prce_NA_idal_NA_elc_NA_mcc_ncntpkwh&facets[seriesId][]=prce_NA_idal_NA_elc_NA_mce_ncntpkwh&facets[seriesId][]=prce_NA_idal_NA_elc_NA_mcs_ncntpkwh&facets[seriesId][]=prce_NA_idal_NA_elc_NA_mcw_ncntpkwh&facets[seriesId][]=prce_NA_idal_NA_elc_NA_nenycli_ncntpkwh&facets[seriesId][]=prce_NA_idal_NA_elc_NA_npccne_ncntpkwh&facets[seriesId][]=prce_NA_idal_NA_elc_NA_npccupny_ncntpkwh&facets[seriesId][]=prce_NA_idal_NA_elc_NA_pjmce_ncntpkwh&facets[seriesId][]=prce_NA_idal_NA_elc_NA_pjmd_ncntpkwh&facets[seriesId][]=prce_NA_idal_NA_elc_NA_pjme_ncntpkwh&facets[seriesId][]=prce_NA_idal_NA_elc_NA_pjmw_ncntpkwh&facets[seriesId][]=prce_NA_idal_NA_elc_NA_serccnt_ncntpkwh&facets[seriesId][]=prce_NA_idal_NA_elc_NA_serce_ncntpkwh&facets[seriesId][]=prce_NA_idal_NA_elc_NA_sercsoes_ncntpkwh&facets[seriesId][]=prce_NA_idal_NA_elc_NA_swppc_ncntpkwh&facets[seriesId][]=prce_NA_idal_NA_elc_NA_swppno_ncntpkwh&facets[seriesId][]=prce_NA_idal_NA_elc_NA_swppso_ncntpkwh&facets[seriesId][]=prce_NA_idal_NA_elc_NA_tre_ncntpkwh&facets[seriesId][]=prce_NA_idal_NA_elc_NA_weccb_ncntpkwh&facets[seriesId][]=prce_NA_idal_NA_elc_NA_wecccan_ncntpkwh&facets[seriesId][]=prce_NA_idal_NA_elc_NA_wecccas_ncntpkwh&facets[seriesId][]=prce_NA_idal_NA_elc_NA_weccrks_ncntpkwh&facets[seriesId][]=prce_NA_idal_NA_elc_NA_weccsw_ncntpkwh&facets[seriesId][]=prce_NA_idal_NA_elc_NA_wenwpp_ncntpkwh&facets[seriesId][]=prce_NA_resd_NA_elc_NA_flrc_ncntpkwh&facets[seriesId][]=prce_NA_resd_NA_elc_NA_mcc_ncntpkwh&facets[seriesId][]=prce_NA_resd_NA_elc_NA_mce_ncntpkwh&facets[seriesId][]=prce_NA_resd_NA_elc_NA_mcs_ncntpkwh&facets[seriesId][]=prce_NA_resd_NA_elc_NA_mcw_ncntpkwh&facets[seriesId][]=prce_NA_resd_NA_elc_NA_nenycli_ncntpkwh&facets[seriesId][]=prce_NA_resd_NA_elc_NA_npccne_ncntpkwh&facets[seriesId][]=prce_NA_resd_NA_elc_NA_npccupny_ncntpkwh&facets[seriesId][]=prce_NA_resd_NA_elc_NA_pjmce_ncntpkwh&facets[seriesId][]=prce_NA_resd_NA_elc_NA_pjmd_ncntpkwh&facets[seriesId][]=prce_NA_resd_NA_elc_NA_pjme_ncntpkwh&facets[seriesId][]=prce_NA_resd_NA_elc_NA_pjmw_ncntpkwh&facets[seriesId][]=prce_NA_resd_NA_elc_NA_serccnt_ncntpkwh&facets[seriesId][]=prce_NA_resd_NA_elc_NA_serce_ncntpkwh&facets[seriesId][]=prce_NA_resd_NA_elc_NA_sercsoes_ncntpkwh&facets[seriesId][]=prce_NA_resd_NA_elc_NA_swppc_ncntpkwh&facets[seriesId][]=prce_NA_resd_NA_elc_NA_swppno_ncntpkwh&facets[seriesId][]=prce_NA_resd_NA_elc_NA_swppso_ncntpkwh&facets[seriesId][]=prce_NA_resd_NA_elc_NA_tre_ncntpkwh&facets[seriesId][]=prce_NA_resd_NA_elc_NA_weccb_ncntpkwh&facets[seriesId][]=prce_NA_resd_NA_elc_NA_wecccan_ncntpkwh&facets[seriesId][]=prce_NA_resd_NA_elc_NA_wecccas_ncntpkwh&facets[seriesId][]=prce_NA_resd_NA_elc_NA_weccrks_ncntpkwh&facets[seriesId][]=prce_NA_resd_NA_elc_NA_weccsw_ncntpkwh&facets[seriesId][]=prce_NA_resd_NA_elc_NA_wenwpp_ncntpkwh&facets[tableId][]=62&start=2022&end=2050&sort[0][column]=period&sort[0][direction]=desc&offset=0&length=5000&api_key=' + api_key
    r = requests.get(url)
    time.sleep(7) # pause 7 seconds between each call to not get 429
    json_data = r.json()

    if r.status_code == 200:
        print('Success!')
    else:
        print('Error')
    rep = json_data['response']
    df = pd.DataFrame(rep['data'])
    final_data.append(df)

# Merge all data into one dataframe 
df = pd.concat(final_data, ignore_index=True)
# df.to_csv("name_of_csv.csv")

print(df)

############################################################################
# Code for reformatting new csv files
# unchanged = '/Users/msizemor/Desktop/STND_scen/1_aeo_load_projections_nerc_2023.csv'
# changed = '/Users/msizemor/Desktop/STND_scen/1_aeo_energy_price_projections_nerc_2023.csv'
# df_1 = pd.read_csv(unchanged)
# print(df_1.head())
# # df_1.to_excel('/Users/msizemor/Desktop/STND_scen/aeo_energy_price_projections_nerc_2023.xlsx', index=False)

# df_1_add = df_1['regionName']
# df_1['nerc_region_desc'] = df_1['regionName']

# # print(df_1.columns)


# # Dictionary of region descriptions to region abbreviation 
# reg_desc_abbr = {"Midcontinent / Central":"MISC",
# "Southwest Power Pool / South":"SPPS",
# "Western Electricity Coordinating Council / California North":"CANO",
# "Northeast Power Coordinating Council / Upstate New York":"NYUP",
# "Northeast Power Coordinating Council / New England":"ISNE",
# "PJM / Commonwealth Edison":"PJMC",
# "Texas Reliability Entity":"TRE",
# "PJM / West":"PJMW",
# "SERC Reliability Corporation / Southeastern":"SRSE",
# "Southwest Power Pool / North":"SPPN",
# "Northeast Power Coordinating Council / New York City and Long Island":"NYCW",
# "PJM / Dominion":"PJMD",
# "Western Electricity Coordinating Council / Northwest Power Pool Area":"NWPP",
# "Western Electricity Coordinating Council / Basin":"BASN",
# "Midcontinent / South":"MISS",
# "PJM / East":"PJME",
# "Southwest Power Pool / Central":"SPPC",
# "Midcontinent / East":"MISE",
# "SERC Reliability Corporation / Central":"SRCE",
# "Western Electricity Coordinating Council / Rockies":"RMRG",
# "SERC Reliability Corporation / East":"SRCA",
# "Midcontinent / West":"MISW",
# "Western Electricity Coordinating Council / Southwest":"SRSG",
# "Florida Reliability Coordinating Council":"FRCC",
# "Western Electricity Coordinating Council / California South":"CASO",
# 'High Economic Growth':'AEO2023 High Economic Growth',
# 'Low Oil Price':'AEO2023 Low Oil Price', 
# 'High Uptake of Inflation Reduction Act':'AEO2023 High Uptake of Inflation Reduction Act',
# 'Reference case':'AEO2023 Reference case',
# 'Low Economic Growth':'AEO2023 Low Economic Growth',
# 'Low Uptake of Inflation Reduction Act':'AEO2023 Low Uptake of Inflation Reduction Act',
# 'High Oil Price':'AEO2023 High Oil Price',
# 'No Inflation Reduction Act':'AEO2023 No Inflation Reduction Act',
# 'Electricity : Electricity Demand : Residential':'res',
# 'Electricity : Electricity Demand : Industrial':'ind',
# 'Electricity : Electricity Demand : Commercial/Other':"com"
# }

# # Use for load projections:
# # 'Electricity : Electricity Demand : Residential':'res',
# # 'Electricity : Electricity Demand : Industrial':'ind',
# # 'Electricity : Electricity Demand : Commercial/Other':"com"

# # Usef for rate escalation
# # 'Electricity : End-Use Prices : Residential':'res',
# # 'Electricity : End-Use Prices : Industrial':'ind',
# # 'Electricity : End-Use Prices : Commercial':"com"
# # Replace values, drop unused columns, rename columns, 
# # df_1['nerc_region_abbr'] = df_1['nerc_region_abbr'].replace(reg_desc_abbr)

# df_1 = df_1.drop(columns={"unit", 'Unnamed: 0', 'history', "scenario", 'tableId', 'tableName'})

# df_1['fuel_type'] = 'electricity'
# print(df_1.head())

# df_1 = df_1.rename(columns={"period":"year",
#               "value":'billions_kwh', 
#               "regionName":"nerc_region_abbr",
#               "regionId":"nerc_region_ID", 
#               "scenarioDescription":"scenario", 
#               "seriesName":'sector_abbr'})

# df_1['nerc_region_abbr'] = df_1['nerc_region_abbr'].replace(reg_desc_abbr)
# df_1['sector_abbr'] = df_1['sector_abbr'].replace(reg_desc_abbr)

# print(df_1['nerc_region_abbr'])
# # Re-index columns 
# new_cols = ['year', 'billions_kwh', 'sector_abbr', 'nerc_region_ID','nerc_region_abbr', 'nerc_region_desc', 'fuel_type', 'scenario']
# df_1 = df_1[new_cols]

# print(df_1.columns)
# # df_1['nerc_region_ID'] = (df_1['nerc_region_ID'].astype(str))

# # Save/update CSV file 
# df_1.to_excel('reformatted_aeo_load_projections_nerc_2023.xlsx', index=False)







# ############################################################################
# Code for calculating rate escalation and load growth 


# Set up arrays containing relevant row values for processing
# Each year, 2022-2050
# years = np.arange(2022,2051)

# # Each region
# region_abbr = ['TRE', 'FRCC', 'MISW', 'MISC', 'MISE', 'MISS', 'ISNE', 
#             'NYCW', 'NYUP', 'PJME', 'PJMW', 'PJMC', 'PJMD', 'SRCA', 
#             'SRSE', 'SRCE', 'SPPS', 'SPPC', 'SPPN', 'SRSG', 'CANO', 'CASO', 
#             'NWPP', 'RMRG', 'BASN'] 

# # Each scenario 
# scenarios = ['AEO2023 High Economic Growth', 'AEO2022 Reference case',
#  'AEO2023 Low Oil Price', 'AEO2023 High Uptake of Inflation Reduction Act',
#  'AEO2023 Reference case', 'AEO2023 Low Economic Growth',
#  'AEO2023 Low Uptake of Inflation Reduction Act', 'AEO2023 High Oil Price',
#  'AEO2023 No Inflation Reduction Act']


# def by_sector(df, years, region_abbr,  sector, scenario):
#     '''
#     Helper function to calculate the growth factors by each sector.
#     For load growth projection, use 'billions_kwh', load_multiplier new columns
#     For rate escalation use 'cents_per_kwh', escalation_factor new column
#     '''
#     start_year = 2022
#     final_df = []

#     # Use year as first filter on data
#     for i in range(len(years)):
#         # Filter data by years
#         year = years[i]
#         for j in range(len(region_abbr)):
#             # Filter data further based on relevant year and specific region and scenario
#             ref_df = df.loc[(df['year']==start_year) &(df['nerc_region_abbr']==region_abbr[j]) & (df['sector_abbr']==sector)]
#             new_df = df.loc[(df['year']==year) &(df['nerc_region_abbr']==region_abbr[j]) & (df['sector_abbr']==sector)]

#             for k in range(len(scenario)):
#                 # Select data points from reference and relevant year based on scenario
#                 scen_ref = ref_df.loc[(ref_df['scenario']==scenario[k])]
#                 scen_new = new_df.loc[(new_df['scenario']==scenario[k])]
                
#                 # Reduce down to a specific value for math
#                 ref = scen_ref['billions_kwh'].values
#                 new = scen_new['billions_kwh'].values
                
#                 # Use fraction to fill values of growth
#                 scen_new['load_multiplier'] = new/ref

#                 # Put new data into empty array
#                 final_df.append(scen_new)
    
#     # Combine new data into pandas dataframe        
#     new_df = pd.concat(final_df)

#     return new_df

# # print(list(df_1['nerc_region_abbr'].unique()))
# res_df = by_sector(df_1, years, region_abbr, 'res', scenarios)
# com_df = by_sector(df_1, years, region_abbr, 'com', scenarios)
# ind_df = by_sector(df_1, years, region_abbr, 'ind', scenarios)

# # Recombine all three sectors into one dataframe
# frames = [res_df, com_df, ind_df]
# df_3 = pd.concat(frames)

# # Remove unnecessary column
# df_3 = df_3.drop(columns='billions_kwh')

# # Map sector abbreviation to full word and apply change to newly created 'sector column'
# sect_name = {'res':'Residential',
#             'com':'Commercial',
#             'ind':'Industrial'}

# df_3['sector'] = df_3['sector_abbr']

# df_3['sector'] = df_3['sector'].replace(sect_name)

# # Update region description with full names
# region_name = {'MISC':'Midcontinent / Central', 
# 'SPPS':'Southwest Power Pool / South', 
# 'CANO':'Western Electricity Coordinating Council / California North', 
# 'NYUP':'Northeast Power Coordinating Council / Upstate New York',
# 'ISNE':'Northeast Power Coordinating Council / New England', 
# 'PJMC':'PJM / Commonwealth Edison', 
# 'TRE':'Texas Reliability Entity', 
# 'PJMW':'PJM / West', 
# 'SRSE':'SERC Reliability Corporation / Southeastern', 
# 'SPPN':'Southwest Power Pool / North', 
# 'NYCW':'Northeast Power Coordinating Council / New York City and Long Island', 
# 'PJMD':'PJM / Dominion', 
# 'NWPP':'Western Electricity Coordinating Council / Northwest Power Pool Area', 
# 'BASN':'Western Electricity Coordinating Council / Basin', 
# 'MISS':'Midcontinent / South', 
# 'PJME':'PJM / East', 
# 'SPPC':'Southwest Power Pool / Central', 
# 'MISE':'Midcontinent / East', 
# 'SRCE':'SERC Reliability Corporation / Central', 
# 'RMRG':'Western Electricity Coordinating Council / Rockies', 
# 'SRCA':'SERC Reliability Corporation / East', 
# 'MISW':'Midcontinent / West', 
# 'SRSG':'Western Electricity Coordinating Council / Southwest', 
# 'FRCC':'Florida Reliability Coordinating Council', 
# 'CASO':'Western Electricity Coordinating Council / California South'}


# df_3['nerc_region_desc'] = df_3['nerc_region_desc'].replace(region_name)
# print(df_3)
# df_3.to_excel('/Users/msizemor/Desktop/STND_scen/new_aeo_load_growth_projections_nerc_2023.xlsx', index=False)
# # ############################################################################
# # # Code for adding past years to escalation files 

# df_1 = pd.read_csv('/Users/msizemor/Desktop/STND_scen/new_aeo_load_growth_projections_nerc_2023.csv')
# # Set up arrays containing relevant row values for processing
# # Each year, 2014-2021
# years = np.arange(2014,2022)


# def extrapolate_esc(df, years, region_abbr,  sector_abbr, scenario):
#     '''
#     Helper function to calculate the growth factors by each sector.
#     For load projection, use 'billions_kwh' 
#     For rate escalation use 'cents_per_kwh'
#     '''
#     # Dictionary with longer sector names
#     sect_name = {'res':'Residential',
#                 'com':'Commercial',
#                 'ind':'Industrial'}
    
#     # Dictionary with longer region names
#     region_name = {'MISC':'Midcontinent / Central', 
#                     'SPPS':'Southwest Power Pool / South', 
#                     'CANO':'Western Electricity Coordinating Council / California North', 
#                     'NYUP':'Northeast Power Coordinating Council / Upstate New York',
#                     'ISNE':'Northeast Power Coordinating Council / New England', 
#                     'PJMC':'PJM / Commonwealth Edison', 
#                     'TRE':'Texas Reliability Entity', 
#                     'PJMW':'PJM / West', 
#                     'SRSE':'SERC Reliability Corporation / Southeastern', 
#                     'SPPN':'Southwest Power Pool / North', 
#                     'NYCW':'Northeast Power Coordinating Council / New York City and Long Island', 
#                     'PJMD':'PJM / Dominion', 
#                     'NWPP':'Western Electricity Coordinating Council / Northwest Power Pool Area', 
#                     'BASN':'Western Electricity Coordinating Council / Basin', 
#                     'MISS':'Midcontinent / South', 
#                     'PJME':'PJM / East', 
#                     'SPPC':'Southwest Power Pool / Central', 
#                     'MISE':'Midcontinent / East', 
#                     'SRCE':'SERC Reliability Corporation / Central', 
#                     'RMRG':'Western Electricity Coordinating Council / Rockies', 
#                     'SRCA':'SERC Reliability Corporation / East', 
#                     'MISW':'Midcontinent / West', 
#                     'SRSG':'Western Electricity Coordinating Council / Southwest', 
#                     'FRCC':'Florida Reliability Coordinating Council', 
#                     'CASO':'Western Electricity Coordinating Council / California South'}

#     # Dictionary matching region abbr to region ID
#     reg_id = {'TRE': '5-1', 
#                 'FRCC': '5-2',
#                 'MISW': '5-3', 
#                 'MISC': '5-4', 
#                 'MISE': '5-5', 
#                 'MISS': '5-6', 
#                 'ISNE': '5-7', 
#                 'NYCW': '5-8', 
#                 'NYUP': '5-9', 
#                 'PJME': '5-10', 
#                 'PJMW': '5-11', 
#                 'PJMC': '5-12', 
#                 'PJMD': '5-13', 
#                 'SRCA': '5-14', 
#                 'SRSE': '5-15', 
#                 'SRCE': '5-16', 
#                 'SPPS': '5-17', 
#                 'SPPC': '5-18', 
#                 'SPPN': '5-19', 
#                 'SRSG': '5-20', 
#                 'CANO': '5-21', 
#                 'CASO': '5-22', 
#                 'NWPP': '5-23', 
#                 'RMRG': '5-24', 
#                 'BASN': '5-25'}

#     add_row = []
#     for i in range(len(years)):
#     # Filter data by years
#         for j in range(len(region_abbr)):
#         # Filter by region 
#             id = reg_id[region_abbr[j]]
#             name = region_name[region_abbr[j]]

#             for k in range(len(scenario)):
#             # Filter by scenario
#                 scen = scenario[k]
#                 # Assign pulled data values to correct positions in a new list to append to dataframe
#                 row = [years[i], sector_abbr, id, region_abbr[i], name, 'electricity', scen, 1, sect_name[sector_abbr]]
#                 add_row.append(row)
    
#     return add_row


# # Create new rows for each scenarion, region, year, and sector 
# res_df = extrapolate_esc(df_1, years, region_abbr, 'res', scenarios)
# com_df = extrapolate_esc(df_1, years, region_abbr, 'com', scenarios)
# ind_df = extrapolate_esc(df_1, years, region_abbr, 'ind', scenarios)

# # Put each new row into existing dataframe
# for i in range(len(res_df)):
#     df_1.loc[len(df_1.index)] = res_df[i]
#     df_1.loc[len(df_1.index)] = com_df[i]
#     df_1.loc[len(df_1.index)] = ind_df[i]


# df_1.to_excel('/Users/msizemor/Desktop/STND_scen/final_aeo_load_growth_projections_nerc_2023.xlsx', index=False)