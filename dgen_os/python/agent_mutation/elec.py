import psycopg2 as pg
import numpy as np
import pandas as pd
import decorators
import datetime
import utility_functions as utilfunc
from io import StringIO
import os
import gc
import multiprocessing as mp
import concurrent.futures as concur_f
import tariff_functions as tFuncs
import sqlalchemy

# GLOBAL SETTINGS

# load logger
logger = utilfunc.get_logger()

# configure psycopg2 to treat numeric values as floats (improves performance of pulling data from the database)
DEC2FLOAT = pg.extensions.new_type(pg.extensions.DECIMAL.values,
                                   'DEC2FLOAT',
                                   lambda value, curs: float(value) if value is not None else None)
pg.extensions.register_type(DEC2FLOAT)


#%%
@decorators.fn_timer(logger=logger, tab_level=2, prefix='')
def apply_elec_price_multiplier_and_escalator(dataframe, year, elec_price_change_traj):
    '''
    Obtain a single scalar multiplier for each agent, that is the cost of
    electricity relative to 2016 (when the tariffs were curated).
    Also calculate the compound annual growth rate (CAGR) for the price of
    electricity from present year to 2050, which will be the escalator that
    agents use to project electricity changes in their bill calculations.
    
    elec_price_multiplier = change in present-year elec cost to 2016
    elec_price_escalator = agent's assumption about future price changes
    Note that many customers will not differentiate between real and nominal,
    and therefore many would overestimate the real escalation of electriicty
    prices.


    Parameters
    ----------    
    dataframe : :class: `pandas.DataFrame`
        Agent dataframe       
    year : `int`
        The year for which you want multiplier values for
    elec_price_change_traj : :class: `pandas.DataFrame`
        DataFrame of electricity prices' trajectories over time. See the 
        'input_elec_prices_user_defined' table in the database.

    Returns
    -------
    dataframe : :class: `pandas.DataFrame`
        Agent DataFrame with elec_price_multiplier and elec_price_escalator data merged in.

    '''
    
    dataframe = dataframe.reset_index()

    # get current year multiplier values
    elec_price_multiplier_df = elec_price_change_traj[elec_price_change_traj['year']==year].reset_index(drop=True)

    # copy to the multiplier_df for escalator calcs
    year_cap = min(year, 2040)
    elec_price_escalator_df = elec_price_change_traj[elec_price_change_traj['year']==year_cap].reset_index(drop=True)

    # get final year multiplier values and attach to escalator_df
    final_year = np.max(elec_price_change_traj['year'])
    final_year_df = elec_price_change_traj[elec_price_change_traj['year']==final_year].reset_index(drop=True)
    elec_price_escalator_df['final_year_values'] = final_year_df['elec_price_multiplier'].reset_index(drop=True)
    
    # calculate CAGR for time period between final year and current year
    elec_price_escalator_df['elec_price_escalator'] = (elec_price_escalator_df['final_year_values'] / elec_price_escalator_df['elec_price_multiplier'])**(1.0/(final_year-year_cap)) - 1.0

    # et upper and lower bounds of escalator at 1.0 and -1.0, based on historic elec price growth rates
    elec_price_escalator_df['elec_price_escalator'] = np.clip(elec_price_escalator_df['elec_price_escalator'], -.01, .01)

    # merge multiplier and escalator values back to agent dataframe
    dataframe = pd.merge(dataframe, elec_price_multiplier_df[['elec_price_multiplier', 'sector_abbr', 'county_id']], how='left', on=['sector_abbr', 'county_id'])
    dataframe = pd.merge(dataframe, elec_price_escalator_df[['sector_abbr', 'county_id', 'elec_price_escalator']],
                         how='left', on=['sector_abbr', 'county_id'])

    dataframe = dataframe.set_index('agent_id')

    return dataframe

#%%
@decorators.fn_timer(logger=logger, tab_level=2, prefix='')
def apply_export_tariff_params(dataframe, net_metering_state_df, net_metering_utility_df):

    """
    Apply DER export tariffs if there are any 

    Parameters
    ----------    
    dataframe : :class: `pandas.DataFrame`
        Agent dataframe       
    net_metering_state_df : :class: `pandas.DataFrame`
        DataFrame that contains the state level export tariffs 
    net_metering_utility_df : :class: `pandas.DataFrame`
        DataFrame that contains the utility level export tariffs 

    Returns
    -------
    dataframe : :class: `pandas.DataFrame`
        Agent DataFrame with DER export tariffs appended

    """

    dataframe = dataframe.reset_index()
    
    # specify relevant NEM columns
    nem_columns = ['compensation_style','nem_system_kw_limit']
    net_metering_utility_df = net_metering_utility_df[['eia_id','sector_abbr','state_abbr']+nem_columns]
    
    # check if utility-specific NEM parameters apply to any agents - need to join on state too (e.g. Pacificorp UT vs Pacificorp ID)
    temp_df = pd.merge(dataframe, net_metering_utility_df, how='left', on=['eia_id','sector_abbr','state_abbr'])
    
    # filter agents with non-null nem_system_kw_limit - these are agents WITH utility NEM
    agents_with_utility_nem = temp_df[pd.notnull(temp_df['nem_system_kw_limit'])]
    
    # filter agents with null nem_system_kw_limit - these are agents WITHOUT utility NEM
    agents_without_utility_nem = temp_df[pd.isnull(temp_df['nem_system_kw_limit'])].drop(nem_columns, axis=1)
    
    # merge agents with state-specific NEM parameters
    net_metering_state_df =  net_metering_state_df[['state_abbr', 'sector_abbr']+nem_columns]
    agents_without_utility_nem = pd.merge(agents_without_utility_nem, net_metering_state_df, how='left', on=['state_abbr', 'sector_abbr'])
    
    # re-combine agents list and fill nan's
    dataframe = pd.concat([agents_with_utility_nem, agents_without_utility_nem], sort=False)
    dataframe['compensation_style'].fillna('none', inplace=True)
    dataframe['nem_system_kw_limit'].fillna(0, inplace=True)
    
    dataframe = dataframe.set_index('agent_id')

    return dataframe


#%%
@decorators.fn_timer(logger=logger, tab_level=2, prefix='')
def apply_pv_tech_performance(dataframe, pv_tech_traj):

    '''
    Parameters
    ----------    
    dataframe : :class: `pandas.DataFrame`
        Agent DataFrame       
    pv_tech_traj : :class: `pandas.DataFrame`
        DataFrame of PV tech performance over time. See the 
        'input_pv_tech_performance_user_defined' table in the database.

    Returns
    -------
    dataframe : :class: `pandas.DataFrame`
        Agent DataFrame with depreciation schedule  parameters merged in.

    '''

    dataframe = dataframe.reset_index()

    # Combine the pv_tech_traj DataFrame to the agent DataFrame
    dataframe = pd.merge(dataframe, pv_tech_traj, how='left', on=['sector_abbr', 'year'])
                         
    dataframe = dataframe.set_index('agent_id')

    return dataframe
    

#%%
@decorators.fn_timer(logger=logger, tab_level=2, prefix='')
def apply_depreciation_schedule(dataframe, deprec_sch):
    
    '''
    Parameters
    ----------    
    dataframe : :class: `pandas.DataFrame`
        Agent DataFrame       
    deprec_sch : :class: `pandas.DataFrame`
        DataFrame of depreciation schedule 

    Returns
    -------
    dataframe : :class: `pandas.DataFrame`
        Agent DataFrame with pv tech performance parameters merged in.

    '''

    dataframe = dataframe.reset_index()

    # Merge depreciation schedule on to agent DataFrame
    dataframe = pd.merge(dataframe, deprec_sch[['sector_abbr', 'deprec_sch', 'year']],
                         how='left', on=['sector_abbr', 'year'])
                         
    dataframe = dataframe.set_index('agent_id')

    return dataframe

    
#%%
@decorators.fn_timer(logger=logger, tab_level=2, prefix='')
def apply_pv_prices(dataframe, pv_price_traj):

    '''
    Parameters
    ----------    
    dataframe : :class: `pandas.DataFrame`
        Agent DataFrame      
    pv_price_traj : :class: `pandas.DataFrame`
        DataFrame of PV price trajectories over time. See the 
        'input_pv_prices_user_defined' table in the database.

    Returns
    -------
    dataframe : :class: `pandas.DataFrame`
        Agent DataFrame with pv price parameters merged in.

    '''

    dataframe = dataframe.reset_index()

    # join the data
    dataframe = pd.merge(dataframe, pv_price_traj, how='left', on=['sector_abbr', 'year'])

    # apply the capital cost multipliers
    #dataframe['system_capex_per_kw'] = (dataframe['system_capex_per_kw'] * dataframe['cap_cost_multiplier'])

    dataframe = dataframe.set_index('agent_id')

    return dataframe


#%%
@decorators.fn_timer(logger = logger, tab_level = 2, prefix = '')
def apply_batt_prices(dataframe, batt_price_traj):

    '''
    Parameters
    ----------    
    dataframe : :class: `pandas.DataFrame`
        Agent DataFrame     
    batt_price_traj : :class: `pandas.DataFrame`
        DataFrame of battery price trajectories over time. See the 
        'input_batt_prices_user_defined' table in the database.

    Returns
    -------
    dataframe : :class: `pandas.DataFrame`
        Agent DataFrame with battery price and tech parameters merged in.

    '''

    dataframe = dataframe.reset_index()

    # Merge on prices
    dataframe = pd.merge(dataframe, batt_price_traj[['year','sector_abbr',
                                                     'batt_capex_per_kwh','batt_capex_per_kw','linear_constant',
                                                     'batt_om_per_kwh','batt_om_per_kw']],
                         how = 'left', on = ['sector_abbr', 'year'])
                     
    
    dataframe = dataframe.set_index('agent_id')

    return dataframe


@decorators.fn_timer(logger=logger, tab_level=2, prefix='')
def apply_pv_plus_batt_prices(dataframe, pv_plus_batt_price_traj):

    '''
    Parameters
    ----------    
    dataframe : :class: `pandas.DataFrame`
        Agent dataframe       
    pv_plus_batt_price_traj : :class: `pandas.DataFrame`
        DataFrame of battery price trajectories over time. See the 
        'input_pv_plus_batt_prices_user_defined' table in the database.
    batt_tech_traj : :class: `pandas.DataFrame`
        DataFrame of battery tech trajectories over time. See the 
        'input_batt_tech_performance_user_defined' table in the database.

    Returns
    -------
    dataframe : :class: `pandas.DataFrame`
        Agent DataFrame with pv plus battery price parameters and battery tech parameters merged in.

    '''
    
    dataframe = dataframe.reset_index()
    
    # rename cost columns -- PV+batt configuration has distinct costs
    pv_plus_batt_price_traj.rename(columns={'system_capex_per_kw':'system_capex_per_kw_combined',
                              'batt_capex_per_kwh':'batt_capex_per_kwh_combined',
                              'batt_capex_per_kw':'batt_capex_per_kw_combined',
                              'linear_constant':'linear_constant_combined',
                              'batt_om_per_kw':'batt_om_per_kw_combined',
                              'batt_om_per_kwh':'batt_om_per_kwh_combined'}, inplace=True)

    # Merge on prices
    dataframe = pd.merge(dataframe, pv_plus_batt_price_traj[['year','sector_abbr',
                                                             'system_capex_per_kw_combined',
                                                             'batt_capex_per_kwh_combined','batt_capex_per_kw_combined',
                                                             'linear_constant_combined',
                                                             'batt_om_per_kw_combined','batt_om_per_kwh_combined']], 
                         how = 'left', on = ['year', 'sector_abbr'])
    
    dataframe = dataframe.set_index('agent_id')

    return dataframe


#%%
@decorators.fn_timer(logger=logger, tab_level=2, prefix='')
def apply_value_of_resiliency(dataframe, value_of_resiliency):

    '''
    Note, value of resiliency (VOR) is not currently used in the open source version of the model.

    Parameters
    ----------    
    dataframe : :class: `pandas.DataFrame`
        Agent dataframe       
    vaule_of_resiliency : :class: `pandas.DataFrame`
        DataFrame of financials pertaining to the value of resiliency. See the 
        'input_value_of_resiliency_user_defined' table in the database.

    Returns
    -------
    dataframe : :class: `pandas.DataFrame`
        Agent DataFrame with value of resiliency parameters merged in.

    '''
             
    dataframe = dataframe.reset_index()

    # Merge value of resiliency onto agent DataFrame
    dataframe = dataframe.merge(value_of_resiliency[['state_abbr','sector_abbr','value_of_resiliency_usd']], how='left', on=['state_abbr', 'sector_abbr'])
             
    dataframe = dataframe.set_index('agent_id')
    
    return dataframe

    
#%%
@decorators.fn_timer(logger=logger, tab_level=2, prefix='')
def apply_batt_tech_performance(dataframe, batt_tech_traj):

    '''
    Parameters
    ----------    
    dataframe : :class: `pandas.DataFrame`
        Agent DataFrame       
    batt_tech_traj : :class: `pandas.DataFrame`
        DataFrame of battery tech trajectories over time. See the 
        'input_batt_tech_performance_user_defined' table in the database.

    Returns
    -------
    dataframe : :class: `pandas.DataFrame`
        Agent DataFrame with battery tech parameters merged in.

    '''

    dataframe = dataframe.reset_index()

    # Merge battery tech trajectory onto agent DataFrame
    dataframe = dataframe.merge(batt_tech_traj, how='left', on=['year', 'sector_abbr'])
    
    dataframe = dataframe.set_index('agent_id')
    
    return dataframe


#%%
@decorators.fn_timer(logger=logger, tab_level=2, prefix='')
def apply_financial_params(dataframe, financing_terms, itc_options, inflation_rate):

    '''

    Applies financial parameters specified in input sheet to agent dataframe.

    Parameters
    ----------    
    dataframe : :class: `pandas.DataFrame`
        Agent DataFrame       
    financing_terms : :class: `pandas.DataFrame`
        DataFrame of financing terms.
    itc_options ::class: `pandas.DataFrame`
        DataFrame of different ITC (investment tax credit) parameters, namely 'itc_fraction_of_capex'
        that is merged to the agent dataframe on year, technology, and sector.
    inflation_rate : `float`
        Rate of inflation specified in the input sheet as a percentage (e.g. 2.5%).

    Returns
    -------
    dataframe : :class: `pandas.DataFrame`
        Agent DataFrame with financial parameters merged in.

    '''
    dataframe = dataframe.reset_index()

    # Merge financing terms onto agent DataFrame
    dataframe = dataframe.merge(financing_terms, how='left', on=['year', 'sector_abbr'])

    # Merge ITC options on to DataFrame
    dataframe = dataframe.merge(itc_options[['itc_fraction_of_capex', 'year', 'tech', 'sector_abbr']], 
                                how='left', on=['year', 'tech', 'sector_abbr'])
    
    # Set inflation rate data to 'inflation_rate' column in agent DataFrame
    dataframe['inflation_rate'] = inflation_rate
    
    dataframe = dataframe.set_index('agent_id')

    return dataframe


#%%
@decorators.fn_timer(logger=logger, tab_level=2, prefix='')
def apply_load_growth(dataframe, load_growth_df):

    """
    Applies a load growth factor to agent loads when iterating over the years

    Parameters
    ----------    
    dataframe : :class: `pandas.DataFrame`
        Agent DataFrame       
    load_growth_df : :class: `pandas.DataFrame`
        DataFrame that contans the load growth multiplier at the county, sector, region, and year level. 

    Returns
    -------
    dataframe : 'pd.DataFrame'
        Agent DataFrame with load growth factored in. 

    """

    dataframe = dataframe.reset_index()
    
    # Create 'county_id' column in agent DataFrame
    dataframe["county_id"] = dataframe.county_id.astype(int)
    
    # Merge load growth data onto agent DataFrame
    dataframe = pd.merge(dataframe, load_growth_df, how='left', on=['year', 'sector_abbr', 'county_id'])

    # For residential agents, load growth translates to kwh_per_customer change
    dataframe['load_kwh_per_customer_in_bin'] = np.where(dataframe['sector_abbr']=='res',
                                                dataframe['load_kwh_per_customer_in_bin_initial'] * dataframe['load_multiplier'],
                                                dataframe['load_kwh_per_customer_in_bin_initial'])
                                                
    # For commerical and industrial agents, load growth translates to customer count change
    dataframe['customers_in_bin'] = np.where(dataframe['sector_abbr']!='res',
                                                dataframe['customers_in_bin_initial'] * dataframe['load_multiplier'],
                                                dataframe['customers_in_bin_initial'])
    
    # Create 'total kwh_in_bin' for all sectors 
    dataframe['load_kwh_in_bin'] = dataframe['load_kwh_in_bin_initial'] * dataframe['load_multiplier']

    dataframe = dataframe.set_index('agent_id')
    print(dataframe)
    return dataframe


#%%
@decorators.fn_timer(logger=logger, tab_level=2, prefix='')
def calculate_developable_customers_and_load(dataframe):

    """
    Apply DER export tariffs if there are any 

    Parameters
    ----------    
    dataframe : :class: `pandas.DataFrame`
        Agent DataFrame       

    Returns
    -------
    dataframe : :class: `pandas.DataFrame`
        Agent DataFrame with DER export tariffs appended

    """

    dataframe = dataframe.reset_index()

    # Create 'developable_agent_weight' columns based on % of buildings developable and # of customers for the agent
    dataframe['developable_agent_weight'] = dataframe['pct_of_bldgs_developable'] * dataframe['customers_in_bin']

    # Create 'developable_load_kwh_in_bin' column based on % of buildings developable and load lwh for the agent
    dataframe['developable_load_kwh_in_bin'] = dataframe['pct_of_bldgs_developable'] * dataframe['load_kwh_in_bin']

    dataframe = dataframe.set_index('agent_id')

    return dataframe


#%%
def get_electric_rates_json(con, unique_rate_ids):

    """
    Gets new electricity rates from the SQL database if a utility rate is identified as "bad"
    Uses urdb3_rate_jsons_20200721 version

    Parameters
    ----------    
    con: :class: `psycopg2.connection`
        Connection variable using psycopg2.

    unique_rate_ids: :class: 'pandas.DataFrame'
        DataFrame with utility rate ids to be collected from SQL database. 

    Returns
    -------
    dataframe : :class: `pandas.DataFrame`
        DataFrame with corrected utility rates/tariffs

    """
    
    inputs = locals().copy()

    # Reformat the rate list for use in postgres query
    inputs['rate_id_list'] = utilfunc.pylist_2_pglist(unique_rate_ids)
    inputs['rate_id_list'] = inputs['rate_id_list'].replace("L", "")

    # Get (only the required) rate jsons from postgres
    sql = """SELECT a.rate_id_alias, a.rate_name, a.eia_id, a.json as rate_json
             FROM diffusion_shared.urdb3_rate_jsons_20200721 a
             WHERE a.rate_id_alias in ({rate_id_list});""".format(**inputs)
    
    # Query SQL database for the relevant utility rates
    df = pd.read_sql(sql, con, coerce_float=False)

    return df



#%%
@decorators.fn_timer(logger=logger, tab_level=2, prefix='')
def filter_nem_year(df, year):

    """
    Filter the data for valid NEM program end date 

    Parameters
    ----------    
    df : :class: `pandas.DataFrame`
        The DataFrame containing the state-level net energy metering program details       
    year : `int`
        The year of simulation 

    Returns
    -------
    df : :class: `pandas.DataFrame`
        Final NEM dataset that is filtered for the current simulation year  

    """

    # Filter by Sector Specific Sunset Years
    df = df.loc[(df['first_year'] <= year) & (df['sunset_year'] >= year)]

    return df


#%%
@decorators.fn_timer(logger=logger, tab_level=2, prefix='')
def get_nem_settings(state_limits, state_by_sector, utility_by_sector, selected_scenario, year, state_capacity_by_year, cf_during_peak_demand):

    """
    Reads the rate switch table from a SQL database
    
    Parameters
    ----------
    state_limits : :class: `pandas.DataFrame`
        DataFrame containing any limits that are associated to ongoing solar programs at the state level 

    state_by_sector : :class: `pandas.DataFrame`
        DataFrame tables, at state and sectoral level, the solar program characteristics 

    utility_by_sector : :class: `pandas.DataFrame`
        DataFrame containing any limits that are associated to ongoing solar programs at the utility level

    selected_scenario : `string`
        Text describing the scenatio using which the programs are evaluated over time. Valid option is 'Wholesale'

    year : `int`
        The year of sumulation 

    state_capacity_by_year : :class: `pandas.DataFrame`
        DataFrame containing the cumulative adoption characteristcs at the state level  

    cf_during_peak_demand : :class: `pandas.DataFrame`
        State level solar capacity factor during peak demand 

    Returns
    -------
    state_result: :class: `pandas.DataFrame`
        DataFrame updated with state level net energy metering data based on current adoption levels 
    
    utility_result: :class: `pandas.DataFrame`
        DataFrame updated with utility level net energy metering data based on current adoption levels 
    
    """

    # Find States That Have Not Sunset
    valid_states = filter_nem_year(state_limits, year)

    # Filter States to Those That Have Not Exceeded Cumulative Capacity Constraints
    valid_states['filter_year'] = pd.to_numeric(valid_states['max_reference_year'], errors='coerce')
    valid_states['filter_year'][valid_states['max_reference_year'] == 'previous'] = year - 2
    valid_states['filter_year'][valid_states['max_reference_year'] == 'current'] = year
    valid_states['filter_year'][pd.isnull(valid_states['filter_year'])] = year

    # Merge state capacity DataFrame with the valid state level NEM data
    state_df = pd.merge(state_capacity_by_year, valid_states , how='left', on=['state_abbr'])
    state_df = state_df[state_df['year'] == state_df['filter_year'] ]
    state_df = state_df.merge(cf_during_peak_demand, on = 'state_abbr')

    # Filter out dataFrame for where state cumulative installations is less than the maximum installations for NEM
    state_df = state_df.loc[ pd.isnull(state_df['max_cum_capacity_mw']) | ( pd.notnull( state_df['max_cum_capacity_mw']) & (state_df['cum_system_mw'] < state_df['max_cum_capacity_mw']))]
    
    # Calculate the maximum MW of solar capacity before reaching the NEM cap. MW are determine on a generation basis during the period of peak demand, as determined by ReEDS.
    # CF during peak period is based on ReEDS H17 timeslice, assuming average over south-facing 15 degree tilt systems (so this could be improved by using the actual tilts selected)
    state_df['max_mw'] = (state_df['max_pct_cum_capacity']/100) * state_df['peak_demand_mw'] / state_df['solar_cf_during_peak_demand_period']
    state_df = state_df.loc[ pd.isnull(state_df['max_pct_cum_capacity']) | ( pd.notnull( state_df['max_pct_cum_capacity']) & (state_df['max_mw'] > state_df['cum_system_mw']))]

    # Filter state and sector data to those that have not sunset
    selected_state_by_sector = state_by_sector.loc[state_by_sector['scenario'] == selected_scenario]
    valid_state_sector = filter_nem_year(selected_state_by_sector, year)

    # Filter state and sector data to those that match states which have not sunset/reached peak capacity
    valid_state_sector = valid_state_sector[valid_state_sector['state_abbr'].isin(state_df['state_abbr'].values)]
    
    # Filter utility and sector data to those that have not sunset
    selected_utility_by_sector = utility_by_sector.loc[utility_by_sector['scenario'] == selected_scenario]
    valid_utility_sector = filter_nem_year(selected_utility_by_sector, year)
    
    # Filter out utility/sector combinations in states where capacity constraints have been reached
    # Assumes that utilities adhere to broader state capacity constraints, and not their own
    valid_utility_sector = valid_utility_sector[valid_utility_sector['state_abbr'].isin(state_df['state_abbr'].values)]

    # Return State/Sector data (or null) for all combinations of states and sectors
    full_state_list = state_by_sector.loc[ state_by_sector['scenario'] == 'BAU' ].loc[:, ['state_abbr', 'sector_abbr']]
    state_result = pd.merge( full_state_list, valid_state_sector, how='left', on=['state_abbr','sector_abbr'] )
    state_result['nem_system_kw_limit'].fillna(0, inplace=True)
    
    # Return Utility/Sector data (or null) for all combinations of utilities and sectors
    full_utility_list = utility_by_sector.loc[ utility_by_sector['scenario'] == 'BAU' ].loc[:, ['eia_id','sector_abbr','state_abbr']]
    utility_result = pd.merge( full_utility_list, valid_utility_sector, how='left', on=['eia_id','sector_abbr','state_abbr'] )
    utility_result['nem_system_kw_limit'].fillna(0, inplace=True)

    return state_result, utility_result


def get_and_apply_agent_load_profiles(con, agent):
    '''
    con: :class: `psycopg2.connection`
        Connection variable using psycopg2. 
    
    agent: :class: `pandas.DataFrame`
        Agent DataFrame to add the load profile to 

    Returns
    -------
    df: :class: `pandas.DataFrame`
        Agent DataFrame with load profile attached
    
    '''

    inputs = locals().copy()

    # Assign new columns to the inputs dataset
    inputs['bldg_id'] = agent.loc['bldg_id']
    inputs['sector_abbr'] = agent.loc['sector_abbr']
    inputs['state_abbr'] = agent.loc['state_abbr']
    
    # Query SQL database for the correct load profile based on agent bldg_id, sector_abbr, and state_abbr
    sql = """SELECT bldg_id, sector_abbr, state_abbr,
                    kwh_load_profile as consumption_hourly
             FROM diffusion_load_profiles.{sector_abbr}stock_load_profiles
                 WHERE bldg_id = {bldg_id} 
                 AND sector_abbr = '{sector_abbr}'
                 AND state_abbr = '{state_abbr}';""".format(**inputs)
                           
    df = pd.read_sql(sql, con, coerce_float=False)

    # Select only the hourly consumption column from the returned SQL query 
    df = df[['consumption_hourly']]
    
    # Assign the load kwh per customer based on the values found in the agent DataFrame
    df['load_kwh_per_customer_in_bin'] = agent.loc['load_kwh_per_customer_in_bin']

    # Scale the normalized profile to sum to the total load
    df = df.apply(scale_array_sum, axis=1, args=(
        'consumption_hourly', 'load_kwh_per_customer_in_bin'))
    
    return df

#%%
def get_and_apply_normalized_hourly_resource_solar(con, agent):
    '''
    con: :class: `psycopg2.connection`
        Connection variable using psycopg2. 
    
    agent: :class: `pandas.DataFrame`
        Agent DataFrame to add the hourly solar resource data to 

    Returns
    -------
    df: :class: `pandas.DataFrame`
        Agent DataFrame with hourly solar resource data attached
    
    '''
    inputs = locals().copy()

    # Assign new columns to the inputs dataset based on the agent values
    inputs['solar_re_9809_gid'] = agent.loc['solar_re_9809_gid']
    inputs['tilt'] = agent.loc['tilt']
    inputs['azimuth'] = agent.loc['azimuth']
    
    # Query SQL database using solar_re_9809_gid, tilt, and azimuth values 
    sql = """SELECT solar_re_9809_gid, tilt, azimuth,
                    cf as generation_hourly,
                    1e6 as scale_offset
            FROM diffusion_resource_solar.solar_resource_hourly
                WHERE solar_re_9809_gid = '{solar_re_9809_gid}'
                AND tilt = '{tilt}'
                AND azimuth = '{azimuth}';""".format(**inputs)

    df = pd.read_sql(sql, con, coerce_float=False)

    # Subset returned data 
    df = df[['generation_hourly', 'scale_offset']]

    # Rename the column generation_hourly to solar_cf_profile
    df.rename(columns={'generation_hourly':'solar_cf_profile'}, inplace=True)
          
    return df


#%%
# def scale_array_precision(row, array_col, prec_offset_col):
#     """
#     Apply DER export tariffs if there are any 

#     Parameters
#     ----------    
#     dataframe : :class: `pandas.DataFrame`
#         Agent dataframe       
#     net_metering_state_df : :class: `pandas.DataFrame`
#         DataFrame that contains the state level export tariffs 
#     net_metering_utility_df : :class: `pandas.DataFrame`
#         DataFrame that contains the utility level export tariffs 

#     Returns
#     -------
#     dataframe : :class: `pandas.DataFrame`
#         Agent dataFrame with DER export tariffs appended

#     """
#     row[array_col] = np.array(
#         row[array_col], dtype='float64') / row[prec_offset_col]

#     return row


#%%
def scale_array_sum(row, array_col, scale_col):
    """
    Scale a normalized profile (array) to a sum value

    Parameters
    ----------    
    row : :class: `pandas.DataFrame`
        DataFrame containing arrays to be scaled/summed     
    array_col : `string`
        Column name from row DataFrame containing the array of interest
    scale_col : `string`
        Column name from row DataFrame containing the scale factor of interest

    Returns
    -------
    row : :class: `pandas.DataFrame`
        DataFrame with array column scaled and summed

    """

    hourly_array = np.array(row[array_col], dtype='float64')
    row[array_col] = hourly_array / \
        hourly_array.sum() * np.float64(row[scale_col])

    return row


#%%
# def interpolate_array(row, array_1_col, array_2_col, interp_factor_col, out_col):
#     """
#     Apply DER export tariffs if there are any 

#     Parameters
#     ----------    
#     dataframe : :class: `pandas.DataFrame`
#         Agent dataframe       
#     net_metering_state_df : :class: `pandas.DataFrame`
#         DataFrame that contains the state level export tariffs 
#     net_metering_utility_df : :class: `pandas.DataFrame`
#         DataFrame that contains the utility level export tariffs 

#     Returns
#     -------
#     dataframe : :class: `pandas.DataFrame`
#         Agent dataFrame with DER export tariffs appended

#     """


#     if row[interp_factor_col] != 0:
#         interpolated = row[interp_factor_col] * \
#             (row[array_2_col] - row[array_1_col]) + row[array_1_col]
#     else:
#         interpolated = row[array_1_col]
#     row[out_col] = interpolated

#     return row

#%%
@decorators.fn_timer(logger=logger, tab_level=2, prefix='')
def apply_carbon_intensities(dataframe, carbon_intensities):

    """
    Add carbon intensity data for state and year to the agent DataFrame 

    Parameters
    ----------    
    dataframe : :class: `pandas.DataFrame`
        Agent dataframe       
    carbon_intensities : :class: `pandas.DataFrame`
        DataFrame that contains the state level carbon intensity data

    Returns
    -------
    dataframe : :class: `pandas.DataFrame`
        Agent dataFrame with carbon intensity data appended

    """

    dataframe = dataframe.reset_index()

    # Combine the carbin intensity data to the agent file 
    dataframe = pd.merge(dataframe, carbon_intensities, how='left', on=['state_abbr', 'year'])

    dataframe = dataframe.set_index('agent_id')

    return dataframe
    
#%%
@decorators.fn_timer(logger=logger, tab_level=2, prefix='')
def apply_wholesale_elec_prices(dataframe, wholesale_elec_prices):

    """
    Apply wholesale electricity prices to the agent DataFrame

    Parameters
    ----------    
    dataframe : :class: `pandas.DataFrame`
        Agent dataframe       
    net_metering_state_df : :class: `pandas.DataFrame`
        DataFrame that contains the state level export tariffs 
    net_metering_utility_df : :class: `pandas.DataFrame`
        DataFrame that contains the utility level export tariffs 

    Returns
    -------
    dataframe : :class: `pandas.DataFrame`
        Agent dataFrame with DER export tariffs appended

    """

    dataframe = dataframe.reset_index()

    dataframe = pd.merge(dataframe, wholesale_elec_prices, how='left', on=['county_id', 'year'])

    dataframe = dataframe.set_index('agent_id')

    return dataframe


#%%
@decorators.fn_timer(logger=logger, tab_level=2, prefix='')
def get_state_starting_capacities(con, schema):
    
    """
    Get the starting capacities

    Parameters
    ----------    
    con : :class: `psycopg2.connection`
        SQL connection to connect to database 
   
    schema : `str`
        The name of the schema to be imported

    Returns
    -------
    df : :class: `pandas.DataFrame`
        DataFrame that contains the starting capacity of the DERs

    """ 
    inputs = locals().copy()

    # sql = """SELECT *
    #          FROM {schema}.state_starting_capacities_to_model;""".format(**inputs)
    # df = pd.read_sql(sql, con)


    # get state starting capacities for both solar and storage, distinguished by column names
    sql = """WITH all_combos AS(
                 SELECT state_abbr, unnest(ARRAY['res','com','ind']) as sector_abbr
                 FROM diffusion_shared.state_abbr_lkup
                 WHERE state_abbr NOT IN ('AK','HI','PR')
             ), solar AS(
                 SELECT sector_abbr, state_abbr, system_mw, systems_count AS pv_systems_count
                 FROM {schema}.state_starting_capacities_to_model
                 WHERE tech = 'solar'
             ), storage AS(
                 SELECT sector_abbr, state_abbr, system_mw AS batt_mw, system_mwh as batt_mwh, systems_count AS batt_systems_count
                 FROM {schema}.state_starting_capacities_to_model
                 WHERE tech = 'storage'
             )
             SELECT a.state_abbr, a.sector_abbr, b.system_mw, c.batt_mw, c.batt_mwh, b.pv_systems_count, c.batt_systems_count
             FROM all_combos a
             LEFT JOIN solar b
                 ON a.state_abbr = b.state_abbr AND a.sector_abbr = b.sector_abbr
             LEFT JOIN storage c
                 ON a.state_abbr = c.state_abbr AND a.sector_abbr = c.sector_abbr;""".format(**inputs)
    df = pd.read_sql(sql, con).fillna(0.)

    return df

#%%
@decorators.fn_timer(logger=logger, tab_level=2, prefix='')
def apply_state_incentives(dataframe, state_incentives, year, start_year, state_capacity_by_year, end_date = datetime.date(2029, 1, 1)):

    """
    Apply any applicable state incentives 

    Parameters
    ----------    
    dataframe : :class: `pandas.DataFrame`
        Agent dataframe   

    state_incentives : :class: `pandas.DataFrame`
        DataFrame that contains the state level incentives

    year : :class: `pandas.DataFrame`
        Current model year 

    start_year : int
        Start year of the model run

    state_capacity_by_year : :class: `pandas.DataFrame`
        Starting (installed) capacity of the state

    end_date :class: `datetime.date`, optional
        End date for incentives. Default is January 1, 2029 (1/1/2029)

    Returns
    -------
    dataframe : :class: `pandas.DataFrame`
        Agent dataFrame with state incentives appended

    """

    dataframe = dataframe.reset_index()

    # Fill in missing end_dates
    if bool(end_date):
        state_incentives['end_date'][pd.isnull(state_incentives['end_date'])] = end_date

    # Adjust incenctives to account for reduced values as adoption increases
    yearly_escalation_function = lambda value, end_year: max(value - value * (1.0 / (end_year - start_year)) * (year-start_year), 0)
    for field in ['pbi_usd_p_kwh','cbi_usd_p_w','ibi_pct','cbi_usd_p_wh']:
        state_incentives[field] = state_incentives.apply(lambda row: yearly_escalation_function(row[field], row['end_date'].year), axis=1)
        
    # Filter Incentives by the Years in which they are valid
    state_incentives = state_incentives.loc[
        pd.isnull(state_incentives['start_date']) | (pd.to_datetime(state_incentives['start_date']).dt.year <= year)]
    state_incentives = state_incentives.loc[
        pd.isnull(state_incentives['end_date']) | (pd.to_datetime(state_incentives['end_date']).dt.year >= year)]
    
    # Combine valid incentives with the cumulative metrics for each state up until the current year
    state_capacity_by_year = state_capacity_by_year.loc[state_capacity_by_year['year'] == year]
    state_incentives_mg = state_incentives.merge(state_capacity_by_year,
                                                 how='left', on=["state_abbr"])
 
    # Filter where the states have not exceeded their cumulative installed capacity (by mw or pct generation) or total program budget
    state_incentives_mg = state_incentives_mg.loc[pd.isnull(state_incentives_mg['incentive_cap_total_mw']) | (state_incentives_mg['cum_system_mw'] < state_incentives_mg['incentive_cap_total_mw'])]
    state_incentives_mg = state_incentives_mg.loc[pd.isnull(state_incentives_mg['budget_total_usd']) | (state_incentives_mg['cum_incentive_spending_usd'] < state_incentives_mg['budget_total_usd'])]

    output  =[]
    for i in state_incentives_mg.groupby(['state_abbr', 'sector_abbr']):
        row = i[1]
        state, sector = i[0]
        output.append({'state_abbr':state, 'sector_abbr':sector,"state_incentives":row})
    
    # Create a DataFrame containing the relevant state incentives
    state_inc_df = pd.DataFrame(columns=['state_abbr', 'sector_abbr', 'state_incentives'])
    state_inc_df = pd.concat([state_inc_df, pd.DataFrame.from_records(output)], sort=False)

    # Merge valid state incentives onto the agent dataframe
    dataframe = pd.merge(dataframe, state_inc_df, on=['state_abbr','sector_abbr'], how='left')
    
    dataframe = dataframe.set_index('agent_id')
    
    return dataframe

#%%
@decorators.fn_timer(logger=logger, tab_level=2, prefix='')
def estimate_initial_market_shares(dataframe, state_starting_capacities_df):

    """
    Apply DER export tariffs if there are any 

    Parameters
    ----------    
    dataframe : :class: `pandas.DataFrame`
        Agent dataframe       
    state_starting_capacities_df : :class: `pandas.DataFrame`
        DataFrame that contains the state level starting (installed) capacities
    
    Returns
    -------
    dataframe : :class: `pandas.DataFrame`
        Agent dataFrame with intial market share attached

    """

    # record input columns
    in_cols = list(dataframe.columns)

    # find the total number of customers in each state (by technology and sector)
    state_total_developable_customers = dataframe[['state_abbr', 'sector_abbr', 'tech', 'developable_agent_weight']].groupby(
        ['state_abbr', 'sector_abbr', 'tech']).sum().reset_index()
    state_total_agents = dataframe[['state_abbr', 'sector_abbr', 'tech', 'developable_agent_weight']].groupby(
        ['state_abbr', 'sector_abbr', 'tech']).count().reset_index()
    
    # Rename the final columns
    state_total_developable_customers.columns = state_total_developable_customers.columns.str.replace(
        'developable_agent_weight', 'developable_customers_in_state')
    state_total_agents.columns = state_total_agents.columns.str.replace(
        'developable_agent_weight', 'agent_count')
    
    # Merge together
    state_denominators = pd.merge(state_total_developable_customers, state_total_agents, how='left', on=[
                                  'state_abbr', 'sector_abbr', 'tech'])

    # Merge back to the main dataframe
    dataframe = pd.merge(dataframe, state_denominators, how='left', on=[
                         'state_abbr', 'sector_abbr', 'tech'])

    # Merge in the state starting capacities
    dataframe = pd.merge(dataframe, state_starting_capacities_df, how='left',
                         on=['state_abbr', 'sector_abbr'])
    

    # determine the portion of initial load and systems that should be allocated to each agent
    # (when there are no developable agents in the state, simply apportion evenly to all agents)
    dataframe['portion_of_state'] = np.where(dataframe['developable_customers_in_state'] > 0,
                                             dataframe[
                                                 'developable_agent_weight'] / dataframe['developable_customers_in_state'],
                                             1. / dataframe['agent_count'])

    # apply the agent's portion to the total to calculate starting capacity and systems
    dataframe['adopters_cum_last_year'] = dataframe['portion_of_state'] * dataframe['pv_systems_count']
    dataframe['batt_adopters_cum_last_year'] = dataframe['portion_of_state'] * dataframe['batt_systems_count']
    dataframe['system_kw_cum_last_year'] = dataframe['portion_of_state'] * dataframe['system_mw'] * 1000.
    dataframe['batt_kw_cum_last_year'] = dataframe['portion_of_state'] * dataframe['batt_mw'] * 1000.0
    dataframe['batt_kwh_cum_last_year'] = dataframe['portion_of_state'] * dataframe['batt_mwh'] * 1000.0

    dataframe['market_share_last_year'] = np.where(dataframe['developable_agent_weight'] == 0, 0,
                                                   dataframe['adopters_cum_last_year'] / dataframe['developable_agent_weight'])

    dataframe['market_value_last_year'] = dataframe['system_capex_per_kw'] * dataframe['system_kw_cum_last_year']

    # reproduce these columns as "initial" columns too
    dataframe['initial_number_of_adopters'] = dataframe['adopters_cum_last_year']
    dataframe['initial_pv_kw'] = dataframe['system_kw_cum_last_year']
    dataframe['initial_batt_kw'] = dataframe['batt_kw_cum_last_year']
    dataframe['initial_batt_kwh'] = dataframe['batt_kwh_cum_last_year']
    dataframe['initial_market_share'] = dataframe['market_share_last_year']
    dataframe['initial_market_value'] = 0

    # isolate the return columns
    return_cols = ['initial_number_of_adopters','initial_pv_kw','initial_batt_kw','initial_batt_kwh','initial_market_share','initial_market_value',
                   'adopters_cum_last_year','system_kw_cum_last_year','batt_kw_cum_last_year','batt_kwh_cum_last_year','market_share_last_year','market_value_last_year']

    dataframe[return_cols] = dataframe[return_cols].fillna(0)

    out_cols = in_cols + return_cols

    return dataframe[out_cols]


#%%
@decorators.fn_timer(logger=logger, tab_level=2, prefix='')
def apply_market_last_year(dataframe, market_last_year_df):
    
    """
    Apply the adoption data from last (model) year market simulation 
    
    Parameters
    ----------
    dataframe : :class: `pandas.DataFrame`
        The agent dataframe 

    market_last_year_df: :class: `pandas.DataFrame`
        DataFrame containing market share from the previous year

    Returns
    -------
    dataframe : :class: `pandas.DataFrame`

    """

    dataframe = dataframe.merge(market_last_year_df, on=['agent_id'], how='left')
    
    return dataframe


#%%
@decorators.fn_timer(logger=logger, tab_level=2, prefix='')
def estimate_total_generation(dataframe):

    """
    Estimates total generation of new adopters for the agent 

    Parameters
    ----------    
    dataframe : :class: `pandas.DataFrame`
        Agent dataframe       

    Returns
    -------
    dataframe : :class: `pandas.DataFrame`
        Agent DataFrame with 'total_gen_twh' column added

    """

    dataframe['total_gen_twh'] = ((dataframe['number_of_adopters'] - dataframe['initial_number_of_adopters'])
                                  * dataframe['annual_energy_production_kwh'] * 1e-9) + (0.23 * 8760 * dataframe['initial_pv_kw'] * 1e-6)

    return dataframe


#%%   
@decorators.fn_timer(logger=logger, tab_level=2, prefix='')
def calc_state_capacity_by_year(load_growth, peak_demand_mw, is_first_year, year,solar_agents, last_year_installed_capacity):
    
    """
    Calculate the state capacity for the model year to perform validation 
    
    Parameters
    ----------    
    load_growth : :class: `pandas.DataFrame`
        DataFrame that contains the load growth multiplier at the county, sector, region, and year level. 

    peak_demand_mw : :class: `pandas.DataFrame`
        state level peak demand based on 2014 data 
    
    is_first_year : `bool`
        boolean to say if this is first year 
    
    year : `int`
        The year of simulation 
    
    solar_agents : :class: `agents.Agents`
        Agent file that is of the class "agents" 

    last_year_installed_capacity : :class: `pandas.DataFrame`
        DataFrame containing information on the previous year installed capacity for the agent
    
    Returns
    -------
    df : :class: `pandas.DataFrame`
        DataFrame containing state (installed) capacity, load growth, and peak demand

    """

    if is_first_year:
        # get state starting capacities for solar & storage and sum by state
        df = last_year_installed_capacity.groupby('state_abbr')[['system_mw','batt_mw','batt_mwh']].sum().reset_index()
        df.rename(columns={'system_mw':'cum_system_mw', 'batt_mw':'cum_batt_mw', 'batt_mwh':'cum_batt_mwh'}, inplace=True)
        
        # Not all states have starting capacity, don't want to drop any states thus left join on peak_demand
        df = peak_demand_mw.merge(df, how='left').fillna(0)
        
        # rename columns
        df.rename(columns={'peak_demand_mw_2014':'peak_demand_mw'}, inplace=True)


    else:
        # If not the first model year, use already assigned values from agent
        df = last_year_installed_capacity.copy()
        df['cum_system_mw'] = df['system_kw_cum']/1000
        df['cum_batt_mw'] = df['batt_kw_cum']/1000
        df['cum_batt_mwh'] = df['batt_kwh_cum']/1000

        # Select for the relevant load growth for the agent and merge values to load_growth_this_year DataFrame
        load_growth_this_year = load_growth.loc[(load_growth['year'] == year) & (load_growth['sector_abbr'] == 'res')]
        load_growth_this_year = pd.merge(solar_agents.df[['state_abbr', 'county_id']], load_growth_this_year, how='left', on=['county_id'])
        load_growth_this_year = load_growth_this_year.groupby('state_abbr')['load_multiplier'].mean().reset_index()
        df = df.merge(load_growth_this_year, on = 'state_abbr')
        
        # Combine peak demand for the state with load growth and installed capacity (from df)
        df = peak_demand_mw.merge(df, how='left', on='state_abbr').fillna(0)
        df['peak_demand_mw'] = df['peak_demand_mw_2014'] * df['load_multiplier']

    # TODO: drop cum_capacity_pct from table (misnomer)
    df['cum_capacity_pct'] = 0
    # TODO: enforce program spending cap
    df['cum_incentive_spending_usd'] = 0
    df['year'] = year
    
    # Select for only relevant columns in df to be returned
    df = df[['state_abbr','cum_system_mw','cum_batt_mw','cum_batt_mwh','cum_capacity_pct','cum_incentive_spending_usd','peak_demand_mw','year']]
    
    return df


#%%
def get_rate_switch_table(con):
    
    """
    Reads the rate switch table from a SQL database and returns it as a Pandas DataFrame
    
    Parameters
    ----------
    con : :class: `psycopg2.connection`
        SQL connection to connect to database

    Returns
    -------
    rate_switch_table: :class: `pandas.DataFrame`
        a dataframe that has the cross walk to switch rate ids when DERs are adopted. 
    
    """

    # get rate switch table from database
    sql = """SELECT * FROM diffusion_shared.rate_switch_lkup_2020;"""

    rate_switch_table = pd.read_sql(sql, con, coerce_float=False)
    rate_switch_table = rate_switch_table.reset_index(drop=True)
    
    return rate_switch_table

def apply_rate_switch(rate_switch_table, agent, system_size_kw, tech='solar'):
    
    """
    Updates the tariff rates and associated attributes for the agent when a utility 
    has a rate switch when adopting distributed generation and/or storage technologies
    
    Parameters
    ----------
    rate_switch_table : :class: `pandas.DataFrame`
        DataFrame containing details on how utility rates will switch due to adoption of distributed 
        generation and/or storage adoption
    
    agent : :class: `pandas.Series`
        Attributes of a single agent 

    system_size_kw : float
        PV System size or Battery Capacity (in kW) 
    
    tech : string, default 'solar'
        Technology label to classify if the model is doing solar only or solar and storage 
        Options: 'solar' and 'storage'

    Returns
    -------
    agent : :class: `pandas.Series`
        Single agent updated with rate switch related attributes
        
    one_time_charge : float
        One time charge value for relevant tariff rates used by agent
    
    Notes
    -----
    1) Rate switch only occurs when system size is greater than zero. When system size is greater than 0, the agent is updated with values for 
        Net Energy Metering (set to 1e6), the relevant (new) tariff ID, and new tariff dictionary of rates.
    2) Regardless of the system size, a one time charge is also created and set for the model to use for the agent. 
        For system sizes > 0, the one time charge is taken from the rate switch table. For system sizes = 0, the one time charge is set to 0.
    3) the rate switch table is maintained manually and needs periodic update.

    """
    # Filter rate switch table for relevant technology, change column names for consistency with agent DataFrame
    rate_switch_table = rate_switch_table.loc[rate_switch_table['tech'] == tech]
    rate_switch_table.rename(columns={'rate_id_alias':'tariff_id', 'json':'tariff_dict'}, inplace=True)
    
    # Filter rate switch table further to match agent values
    rate_switch_table = rate_switch_table[(rate_switch_table['eia_id'] == agent.loc['eia_id']) &
                                          (rate_switch_table['res_com'] == str(agent.loc['sector_abbr']).upper()[0]) &
                                          (rate_switch_table['min_kw_limit'] <= system_size_kw) &
                                          (rate_switch_table['max_kw_limit'] > system_size_kw)]

    rate_switch_table = rate_switch_table.reset_index(drop=True)
    
    # check if a DG rate is applicable to agent
    if (system_size_kw > 0) & (len(rate_switch_table) == 1):
        # if valid DG rate available to agent, force NEM on
        agent['nem_system_kw_limit'] = 1e6
        
        # update agent attributes to DG rate
        agent['tariff_id'] = rate_switch_table['tariff_id'][0]
        agent['tariff_dict'] = rate_switch_table['tariff_dict'][0]
        
        # return any one time charges (e.g., interconnection fees)
        one_time_charge = rate_switch_table['one_time_charge'][0]
    
    else:
        # If system size = 0 and/or len(rate_switch_table) != 1, don't update agent attributes, return one time charge of $0
        one_time_charge = 0.
    
    return agent, one_time_charge


#%%
@decorators.fn_timer(logger=logger, tab_level=2, prefix='')
def reassign_agent_tariffs(dataframe, con):

    """
    The function reassigns any tariffs that are wrong. 
    
    Parameters
    ----------
    dataframe: :class: `pandas.DataFrame`
        The agent DataFrame. 

    con: :class: `psycopg2.connection`
        The connection variable to connect to the SQL database using psycopg2. 

    Returns
    -------
    dataframe: :class: `pandas.DataFrame`
        The agent dataframe with any updated tariffs 

    """

    # define rates to use in replacement of incorrect tariffs
    
    # map res/com tariffs based on most likely tariff in state
    res_tariffs = {
                    'AL':17279, # Family Dwelling Service
                    'AR':16671, # Optional Residential Time-Of-Use (RT) Single Phase
                    'AZ':15704, # Residential Time of Use (Saver Choice) TOU-E
                    'CA':15747, # E-1 -Residential Service Baseline Region P
                    'CO':17078, # Residential Service (Schedule R)
                    'CT':16678, # Rate 1 - Residential Electric Service
                    'DC':16806, # Residential - Schedule R
                    'DE':11569, # Residential Service
                    'FL':16986, # RS-1 Residential Service
                    'GA':16649, # SCHEDULE R-22 RESIDENTIAL SERVICE
                    'IA':11693, # Optional Residential Service
                    'ID':16227, # Schedule 1: Residential Rates
                    'IL':16045, # DS-1 Residential Zone 1
                    'IN':15491, # RS - Residential Service
                    'KS':8178, # M System Residential Service
                    'KY':16566, # Residential Service
                    'LA':16352, # Residential and Farm Service - Single Phase (RS-L)
                    'MA':15953, # Greater Boston Residential R-1 (A1)
                    'MD':14779, # Residential Service (R)
                    'ME':15984, # A Residential Standard Offer Service (Bundled)
                    'MI':16265, # Residential Service - Secondary (Rate RS)
                    'MN':15556, # Residential Service - Overhead Standard (A01)
                    'MO':17207, # 1(M) Residential Service Rate
                    'MS':16788, # Residential Service Single Phase (RS-38C)
                    'MT':5216, # Single Phase
                    'NC':16938, # Residential Service (RES-41) Single Phase
                    'ND':14016, # Residential Service Rate 10
                    'NE':13817, # Residential Service
                    'NH':16605, # Residential Service
                    'NJ':16229, # RS - Residential Service
                    'NM':8692, # 1A (Residential Service)
                    'NV':16701, # D-1 (Residential Service)
                    'NY':16902, # SC1- Zone A
                    'OH':16892, # RS (Residential Service)
                    'OK':15258, # Residential Service (R-1)
                    'OR':15847, # Schedule 4 - Residential (Single Phase)
                    'PA':17237, # RS (Residential Service)
                    'RI':16598, # A-16 (Residential Service)
                    'SC':15744, # Residential - RS (SC)
                    'SD':1216, # Town and Rural Residential Rate
                    'TN':15149, # Residential Electric Service
                    'TX':16710, # Residential Service - Time Of Day
                    'UT':15847, # Schedule 4 - Residential (Single Phase)
                    'VA':17067, # Residential Schedule 1
                    'VT':16544, # Rate 01 Residential Service
                    'WA':16305, # 10 (Residential and Farm Primary General Service)
                    'WI':15543, # Residential Rg-1
                    'WV':15515, # Residential Service A
                    'WY':15847 # Schedule 4 - Residential (Single Phase)
                    }
    
    com_tariffs = {
                    'AL':15494, # BTA - BUSINESS TIME ADVANTAGE (OPTIONAL) - Primary
                    'AR':16674, # Small General Service (SGS)
                    'AZ':10742, # LGS-TOU- N - Large General Service Time-of-Use
                    'CA':17057, # A-10 Medium General Demand Service (Secondary Voltage)
                    'CO':17102, # Commercial Service (Schedule C)
                    'CT':16684, # Rate 35 Intermediate General Electric Service
                    'DC':15336, # General Service (Schedule GS)
                    'DE':1199, # Schedule LC-P Large Commercial Primary
                    'FL':13790, # SDTR-1 (Option A)
                    'GA':1905, # SCHEDULE TOU-MB-4 TIME OF USE - MULTIPLE BUSINESS
                    'IA':11705, # Three Phase Farm
                    'ID':14782, # Large General Service (3 Phase)-Schedule 21
                    'IL':1567, # General Service Three Phase standard
                    'IN':15492, # CS - Commercial Service
                    'KS':14736, # Generation Substitution Service
                    'KY':17179, # General Service (Single Phase)
                    'LA':17220, # Large General Service (LGS-L)
                    'MA':16005, # Western Massachusetts Primary General Service G-2
                    'MD':2659, # Commercial
                    'ME':16125, # General Service Rate
                    'MI':5355, # Large Power Service (LP4)
                    'MN':15566, # General Service (A14) Secondary Voltage
                    'MO':17208, # 2(M) Small General Service - Single phase
                    'MS':13427, # General Service - Low Voltage Single-Phase (GS-LVS-14)
                    'MT':10707, # Three Phase
                    'NC':16947, # General Service (GS-41)
                    'ND':14035, # Small General Electric Service rate 20 (Demand Metered; Non-Demand)
                    'NE':13818, # General Service Single-Phase
                    'NH':16620, # GV Commercial and Industrial Service
                    'NJ':17095, # AGS Secondary- BGS-RSCP
                    'NM':15769, # 2A (Small Power Service)
                    'NV':13724, # OGS-2-TOU
                    'NY':15940, # SC-9 - General Large High Tension Service [Westchester]
                    'OH':16873, # GS (General Service-Secondary)
                    'OK':17144, # GS-TOU (General Service Time-Of-Use)
                    'OR':15829, # Small Non-Residential Direct Access Service, Single Phase (Rate 532)
                    'PA':7066, # Large Power 2 (LP2)
                    'RI':16600, # G-02 (General C & I Rate)
                    'SC':16207, # 3 (Municipal  Power Service)
                    'SD':3650, # Small Commercial
                    'TN':15154, # Medium General Service (Primary)
                    'TX':6001, # Medium Non-Residential LSP POLR
                    'UT':3478, # SCHEDULE GS - 3 Phase General Service
                    'VA':16557, # Small General Service Schedule 5
                    'VT':16543, # Rate 06: General Service
                    'WA':16306, # 40 (Large Demand General Service over 3MW - Primary)
                    'WI':6620, # Cg-7 General Service Time-of-Day (Primary)
                    'WV':15518, # General Service C
                    'WY':3878 # General Service (GS)-Three phase
                    }
    
    # map industrial tariffs based on census division
    ind_tariffs = {
                    'SA':16657, # Georgia Power Co, Schedule TOU-GSD-10 Time Of Use - General Service Demand
                    'WSC':15919, # Southwestern Public Service Co (Texas), Large General Service - Inside City Limits 115 KV
                    'PAC':15864, # PacifiCorp (Oregon), Schedule 47 - Secondary (Less than 4000 kW)
                    'MA':16525, # New York State Elec & Gas Corp, All Regions - SERVICE CLASSIFICATION NO. 7-1 Large General Service TOU - Secondary -ESCO                   
                    'MTN':17101, # Public Service Co of Colorado, Secondary General Service (Schedule SG)                   
                    'ENC':15526, # Wisconsin Power & Light Co, Industrial Power Cp-1 (Secondary)                   
                    'NE':16635, # Delmarva Power, General Service - Primary                   
                    'ESC':15490, # Alabama Power Co, LPM - LIGHT AND POWER SERVICE - MEDIUM                   
                    'WNC':6642 # Northern States Power Co - Wisconsin, Cg-9.1 Large General Time-of-Day Primary Mandatory Customers
                   }
    
    dataframe = dataframe.reset_index()

    # separate agents with incorrect and correct rates
    bad_rates = dataframe.loc[np.in1d(dataframe['tariff_id'], [4145, 7111, 8498, 10953, 10954, 12003])]
    good_rates = dataframe.loc[~np.in1d(dataframe['tariff_id'], [4145, 7111, 8498, 10953, 10954, 12003])]
    
    # if incorrect rates exist, grab the correct ones from the rates table
    if len(bad_rates) > 0:
        
        # set new tariff_id based on location
        bad_rates['tariff_id'] = np.where(bad_rates['sector_abbr']=='res',
                                          bad_rates['state_abbr'].map(res_tariffs),
                                          np.where(bad_rates['sector_abbr']=='com',
                                                   bad_rates['state_abbr'].map(com_tariffs),
                                                   bad_rates['census_division_abbr'].map(ind_tariffs)))
        
        # get json objects for new rates and rename columns in preparation for merge
        new_rates_json_df = get_electric_rates_json(con, bad_rates['tariff_id'].tolist())
        new_rates_json_df = (new_rates_json_df
                             .drop(['rate_name','eia_id'], axis='columns')
                             .rename(columns={'rate_id_alias':'tariff_id','rate_json':'tariff_dict'})
                            )
        
        # drop bad tariff_dict from agent dataframe and merge correct one
        bad_rates = bad_rates.drop(['tariff_dict'], axis='columns')
        bad_rates = bad_rates.merge(new_rates_json_df, how='left', on='tariff_id')
    
    # reconstruct full agent dataframe
    dataframe = pd.concat([good_rates, bad_rates], ignore_index=True, sort=False)
    dataframe = dataframe.set_index('agent_id')

    return dataframe