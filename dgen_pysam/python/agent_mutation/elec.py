# -*- coding: utf-8 -*-

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

# configure psycopg2 to treat numeric values as floats (improves
# performance of pulling data from the database)
DEC2FLOAT = pg.extensions.new_type(pg.extensions.DECIMAL.values,
                                   'DEC2FLOAT',
                                   lambda value, curs: float(value) if value is not None else None)
pg.extensions.register_type(DEC2FLOAT)


#%%
def adjust_roof_area(agent_df):
    """
    Function to make the roof areas of the agent_df equal the roof
    area from lidar data. 
    
    """
    
    agent_df = agent_df.reset_index()
    agent_df_thin = agent_df[['developable_roof_sqft', 'customers_in_bin', 'state_abbr', 'sector_abbr','county_id']]
    
    #RES
    res_roof_areas_by_county = pd.read_csv('res_developable_roof_by_county.csv')
    res_roof_areas_by_county = res_roof_areas_by_county[res_roof_areas_by_county['sector_abbr']=='res']
    res_roof_areas_by_county['actual_developable_roof_sqft'] = res_roof_areas_by_county['developable_roof_sng_own_sqft']
    res_roof_areas_by_county = res_roof_areas_by_county[['actual_developable_roof_sqft', 'county_id','sector_abbr']]

    res_df = agent_df_thin[agent_df_thin['sector_abbr']=='res']
    res_df['total_developable_roof_sqft'] = res_df['developable_roof_sqft'] * res_df['customers_in_bin']
    
    res_areas_by_county = res_df[['county_id', 'total_developable_roof_sqft']].groupby(by='county_id').sum()
    res_areas_by_county = res_areas_by_county.reset_index()
    
    res_areas_by_county = pd.merge(res_areas_by_county, res_roof_areas_by_county, on='county_id')
    res_areas_by_county['roof_adjustment'] = res_areas_by_county['actual_developable_roof_sqft'] / res_areas_by_county['total_developable_roof_sqft']
    
    agent_df_res = pd.merge(agent_df[agent_df['sector_abbr']=='res'], res_areas_by_county[['roof_adjustment', 'county_id']], on= 'county_id')
    agent_df_res['developable_roof_sqft'] = agent_df_res['developable_roof_sqft'] * agent_df_res['roof_adjustment']

    #NON RES
    non_res_roof_areas_by_state = pd.read_csv('nonres_developable_roof_by_county.csv')
    non_res_roof_areas_by_state['actual_developable_roof_sqft'] = non_res_roof_areas_by_state['developable_roof_sqft']
    non_res_roof_areas_by_state = non_res_roof_areas_by_state[['actual_developable_roof_sqft', 'county_id']][non_res_roof_areas_by_state['sector_abbr']!='res']

    nonres_df = agent_df_thin[agent_df_thin['sector_abbr']!='res']
    nonres_df['total_developable_roof_sqft'] = nonres_df['developable_roof_sqft'] * nonres_df['customers_in_bin']

    nonres_areas_by_state = nonres_df[['county_id', 'total_developable_roof_sqft']].groupby(by='county_id').sum()
    nonres_areas_by_state = nonres_areas_by_state.reset_index()

    nonres_areas_by_state = pd.merge(nonres_areas_by_state, non_res_roof_areas_by_state, on='county_id')

    nonres_areas_by_state['roof_adjustment'] = nonres_areas_by_state['actual_developable_roof_sqft'] / nonres_areas_by_state['total_developable_roof_sqft']

    agent_df_nonres = pd.merge(agent_df[agent_df['sector_abbr']!='res'], nonres_areas_by_state[['roof_adjustment', 'county_id']], on=['county_id'])

    agent_df_nonres['developable_roof_sqft'] = agent_df_nonres['developable_roof_sqft'] * agent_df_nonres['roof_adjustment']

    agent_df = pd.concat([agent_df_nonres,agent_df_res], sort=False)

    agent_df = agent_df.set_index('agent_id')
    
    return agent_df

#%%
def select_tariff_driver(agent_df, prng, rates_rank_df, rates_json_df, default_res_rate_lkup, con, engine, role, schema, n_workers=mp.cpu_count()):

    if 'ix' not in os.name:
        logger.info('Within ThreadPool')
        EXECUTOR = concur_f.ThreadPoolExecutor       
    else:
        logger.info('Within ProcessPool')
        EXECUTOR = concur_f.ProcessPoolExecutor

    seed = prng.get_state()[1][0]

    futures = []
    results = []

    logger.info('Number of Workers is {}'.format(n_workers))

    # Chunk the large agent dataframe into smaller chunks to be processed by all the available processors
    # calculate the chunk size as an integer to split the dataframe
    if n_workers > int(agent_df.shape[0]):
        n_workers = int(agent_df.shape[0])-1
        logger.info('Agent Chunk size less than n_workers so re-assigning n_workers as {}'.format(n_workers))

    chunk_size = int(agent_df.shape[0]/n_workers)
    
    # chunk the dataframe according to the chunksize calculated above
    chunks = [agent_df.loc[agent_df.index[i:i + chunk_size]] for i in range(0, agent_df.shape[0], chunk_size)]


    with EXECUTOR(max_workers=n_workers) as executor:
        for agent_chunks in chunks:

            for agent_id, agent in agent_chunks.iterrows():
         
                prng.seed(seed)
                # Filter for list of tariffs available to this agent
                agent_rate_list = rates_rank_df.loc[agent_id].drop_duplicates()
                if np.isscalar(agent_rate_list['rate_id_alias']):
                    rate_list = [agent_rate_list['rate_id_alias']]
                else:
                	rate_list = agent_rate_list['rate_id_alias']
                agent_rate_jsons = rates_json_df[rates_json_df.index.isin(rate_list)]
                
                # There can be more than one utility that is potentially applicable
                # to each agent (e.g., if the agent is in a county where more than 
                # one utility has service). Select which one by random.
                utility_list = np.unique(agent_rate_jsons['eia_id'])
    
                # Do a random draw from the utility_list using the same seed as generated in dgen_model.py and return the utility_id that was selected
                utility_id = prng.choice(utility_list)
                
                # If agent is in residential sector and selected utility is included in the default residential rate table, assign default rate only.
                # Otherwise, proceed as before by returning all rates applicable to agent.
                if (utility_id in default_res_rate_lkup['eia_id'].values) & (agent.loc['sector_abbr'] == 'res'):
                    rate_id = default_res_rate_lkup[default_res_rate_lkup['eia_id'] == utility_id]['rate_id_alias'].values[0]
                    agent_rate_jsons = get_electric_rates_json(con, [rate_id])
                    agent_rate_jsons = agent_rate_jsons.set_index('rate_id_alias')
                    # agent_rate_jsons = agent_rate_jsons.loc[[rate_id]]
                else:
                    agent_rate_jsons = agent_rate_jsons[agent_rate_jsons['eia_id']==utility_id]

                # Get agent's load profile from database to pass to select_tariff
                norm_scaled_load_profiles_df = get_and_apply_normalized_load_profiles(con, agent)
                load_profile = pd.Series(norm_scaled_load_profiles_df['consumption_hourly']).iloc[0]
                del norm_scaled_load_profiles_df
                
                futures.append(executor.submit(select_tariff, agent, agent_rate_jsons, load_profile))

            results = [future.result() for future in futures]
            gc.collect()

    agent_df = pd.concat(results, axis=1, sort=False).T
    agent_df.index.name = 'agent_id'

    # Write a lookup table to postgresql database with agent_id and rate attributes i.e. tariff_name, and tariff_id
    agent_rate_lkup_df = agent_df[['tariff_id', 'tariff_name']]
    agent_rate_lkup_df = agent_rate_lkup_df.reset_index()
    
    agent_rate_lkup_df.to_sql(name='agent_tariff_lkup_new', con=engine, schema=schema, index=False, if_exists='replace')
    
    return agent_df


#%%
def select_tariff(agent, rates_json_df, load_profile):

    # Create export tariff object
    export_tariff = tFuncs.Export_Tariff(full_retail_nem=True)

    #=========================================================================#
    # Tariff selection
    #=========================================================================#
    rates_json_df['bills'] = 0.0
    if len(rates_json_df) > 1:
        # determine which of the tariffs has the cheapest cost of electricity without a system
        for index in rates_json_df.index:
            tariff_dict = rates_json_df.loc[index, 'rate_json']
            tariff = tFuncs.Tariff(dict_obj=tariff_dict)
            bill, _ = tFuncs.bill_calculator(load_profile, tariff, export_tariff)
            rates_json_df.loc[index, 'bills'] = bill

    # Select the tariff that had the cheapest electricity. Note that there is
    # currently no rate switching, if it would be cheaper once a system is
    # installed. This is currently for computational reasons.
    rates_json_df['tariff_ids'] = rates_json_df.index
    tariff_name = rates_json_df.loc[rates_json_df['bills'].idxmin(), 'rate_name']
    tariff_id = rates_json_df.loc[rates_json_df['bills'].idxmin(), 'tariff_ids']
    tariff_dict = rates_json_df.loc[tariff_id, 'rate_json']
    # TODO: Patch for daily energy tiers. Remove once bill calculator is improved.
    if 'energy_rate_unit' in tariff_dict:
        if tariff_dict['energy_rate_unit'] == 'kWh daily': tariff_dict['e_levels'] = np.array(tariff_dict['e_levels']) * 30.0
    tariff = tFuncs.Tariff(dict_obj=tariff_dict)

    # Removes the two 8760's from the dictionary, since these will be built from
    # 12x24's now
    if 'd_tou_8760' in list(tariff_dict.keys()): del tariff_dict['d_tou_8760']
    if 'e_tou_8760' in list(tariff_dict.keys()): del tariff_dict['e_tou_8760']

    agent['tariff_name'] = tariff_name
    agent['tariff_dict'] = tariff_dict
    agent['tariff_id'] = tariff_id

    return agent


#%%
def get_default_res_rates(con):
    
    sql = """SELECT * FROM diffusion_shared.default_res_rate_lkup_2019"""
           
    dataframe = pd.read_sql(sql, con, coerce_float=False)
    
    return dataframe


#%%
def apply_solar_capacity_factor_profile(dataframe, hourly_resource_df):

    # record the columns in the input dataframe
    in_cols = list(dataframe.columns)

    # join the index that corresponds to the agent's solar resource to the
    # agent dataframe
    dataframe = dataframe.reset_index()
    dataframe = pd.merge(dataframe, hourly_resource_df, how='left', on=[
                         'sector_abbr', 'tech', 'county_id', 'bin_id'])
    dataframe['solar_cf_profile'] = dataframe['generation_hourly']
    dataframe = dataframe.set_index('agent_id')

    # subset to only the desired output columns
    out_cols = in_cols + ['solar_cf_profile']
    dataframe = dataframe[out_cols]

    return dataframe


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

    dataframe = dataframe.reset_index()
    
    # specify relevant NEM columns
    nem_columns = ['compensation_style','nem_system_kw_limit']
    
    # check if utility-specific NEM parameters apply to any agents - need to join on state too (e.g. Pacificorp UT vs Pacificorp ID)
    temp_df = pd.merge(dataframe, net_metering_utility_df[
                        ['eia_id','sector_abbr','state_abbr']+nem_columns], how='left', on=['eia_id','sector_abbr','state_abbr'])
    
    # filter agents with non-null nem_system_kw_limit - these are agents WITH utility NEM
    agents_with_utility_nem = temp_df[pd.notnull(temp_df['nem_system_kw_limit'])]
    
    # filter agents with null nem_system_kw_limit - these are agents WITHOUT utility NEM
    agents_without_utility_nem = temp_df[pd.isnull(temp_df['nem_system_kw_limit'])].drop(nem_columns, axis=1)
    # merge agents with state-specific NEM parameters
    agents_without_utility_nem = pd.merge(agents_without_utility_nem, net_metering_state_df[
                        ['state_abbr', 'sector_abbr']+nem_columns], how='left', on=['state_abbr', 'sector_abbr'])
    
    # re-combine agents list and fill nan's
    dataframe = pd.concat([agents_with_utility_nem, agents_without_utility_nem], sort=False)
    dataframe['compensation_style'].fillna('none', inplace=True)
    dataframe['nem_system_kw_limit'].fillna(0, inplace=True)
    
    dataframe = dataframe.set_index('agent_id')

    return dataframe


#%%
@decorators.fn_timer(logger=logger, tab_level=2, prefix='')
def apply_pv_tech_performance(dataframe, pv_tech_traj):

    dataframe = dataframe.reset_index()

    dataframe = pd.merge(dataframe, pv_tech_traj, how='left', on=['sector_abbr', 'year'])
                         
    dataframe = dataframe.set_index('agent_id')

    return dataframe
    

#%%
@decorators.fn_timer(logger=logger, tab_level=2, prefix='')
def apply_depreciation_schedule(dataframe, deprec_sch):

    dataframe = dataframe.reset_index()

    dataframe = pd.merge(dataframe, deprec_sch[['sector_abbr', 'deprec_sch', 'year']],
                         how='left', on=['sector_abbr', 'year'])
                         
    dataframe = dataframe.set_index('agent_id')


    return dataframe

    
#%%
@decorators.fn_timer(logger=logger, tab_level=2, prefix='')
def apply_pv_prices(dataframe, pv_price_traj):

    dataframe = dataframe.reset_index()

    # join the data
    dataframe = pd.merge(dataframe, pv_price_traj, how='left', on=['sector_abbr', 'year'])

    # apply the capital cost multipliers
    dataframe['system_capex_per_kw'] = (dataframe['system_capex_per_kw'] * dataframe['cap_cost_multiplier'])

    dataframe = dataframe.set_index('agent_id')

    return dataframe


#%%
@decorators.fn_timer(logger = logger, tab_level = 2, prefix = '')
def apply_batt_prices(dataframe, batt_price_traj, batt_tech_traj, year):

    dataframe = dataframe.reset_index()

    # Merge on prices
    dataframe = pd.merge(dataframe, batt_price_traj[['batt_capex_per_kwh', 'batt_capex_per_kw', 'sector_abbr', 'year']], 
                         how = 'left', on = ['sector_abbr', 'year'])
                     
    batt_price_traj = pd.merge(batt_price_traj, batt_tech_traj, on=['year', 'sector_abbr'])
    batt_price_traj['replace_year'] = batt_price_traj['year'] - batt_price_traj['batt_lifetime_yrs']
                         
    # Add replacement cost payments to base O&M 
    storage_replace_values = batt_price_traj[batt_price_traj['replace_year']==year]
    storage_replace_values['kw_replace_price'] = storage_replace_values['batt_capex_per_kw'] * storage_replace_values['batt_replace_frac_kw']
    storage_replace_values['kwh_replace_price'] = storage_replace_values['batt_capex_per_kwh'] * storage_replace_values['batt_replace_frac_kwh']
    
    # Calculate the present value of the replacements
    replace_discount = 0.06 # Use a different discount rate to represent the discounting of the third party doing the replacing
    storage_replace_values['kw_replace_present'] = storage_replace_values['kw_replace_price'] * 1 / (1.0+replace_discount)**storage_replace_values['batt_lifetime_yrs']
    storage_replace_values['kwh_replace_present'] = storage_replace_values['kwh_replace_price'] * 1 / (1.0+replace_discount)**storage_replace_values['batt_lifetime_yrs']

    # Calculate the level of annual payments whose present value equals the present value of a replacement
    storage_replace_values['batt_om_per_kw'] += storage_replace_values['kw_replace_present'] * (replace_discount*(1+replace_discount)**20) / ((1+replace_discount)**20 - 1)
    storage_replace_values['batt_om_per_kwh'] += storage_replace_values['kwh_replace_present'] * (replace_discount*(1+replace_discount)**20) / ((1+replace_discount)**20 - 1)

    dataframe = pd.merge(dataframe, storage_replace_values[['sector_abbr', 'batt_om_per_kwh', 'batt_om_per_kw']], how='left', on=['sector_abbr'])
    
    dataframe = dataframe.set_index('agent_id')

    return dataframe

    
#%%
@decorators.fn_timer(logger=logger, tab_level=2, prefix='')
def apply_batt_tech_performance(dataframe, batt_tech_traj):

    dataframe = dataframe.reset_index()

    dataframe = dataframe.merge(batt_tech_traj, how='left', on=['year', 'sector_abbr'])
    
    dataframe = dataframe.set_index('agent_id')
    
    return dataframe


#%%
@decorators.fn_timer(logger=logger, tab_level=2, prefix='')
def apply_financial_params(dataframe, financing_terms, itc_options, inflation_rate):

    dataframe = dataframe.reset_index()

    dataframe = dataframe.merge(financing_terms, how='left', on=['year', 'sector_abbr'])

    dataframe = dataframe.merge(itc_options[['itc_fraction_of_capex', 'year', 'tech', 'sector_abbr']], 
                                how='left', on=['year', 'tech', 'sector_abbr'])

    dataframe['inflation_rate'] = inflation_rate
    
    dataframe = dataframe.set_index('agent_id')
    
    return dataframe


#%%
@decorators.fn_timer(logger=logger, tab_level=2, prefix='')
def apply_load_growth(dataframe, load_growth_df):

    dataframe = dataframe.reset_index()
    
    dataframe["county_id"] = dataframe.county_id.astype(int)

    dataframe = pd.merge(dataframe, load_growth_df, how='left', on=['year', 'sector_abbr', 'county_id'])
    
    # for res, load growth translates to kwh_per_customer change
    dataframe['load_kwh_per_customer_in_bin'] = np.where(dataframe['sector_abbr']=='res',
                                                dataframe['load_kwh_per_customer_in_bin_initial'] * dataframe['load_multiplier'],
                                                dataframe['load_kwh_per_customer_in_bin_initial'])
                                                
    # for C&I, load growth translates to customer count change
    dataframe['customers_in_bin'] = np.where(dataframe['sector_abbr']!='res',
                                                dataframe['customers_in_bin_initial'] * dataframe['load_multiplier'],
                                                dataframe['customers_in_bin_initial'])
                                                
    # for all sectors, total kwh_in_bin changes
    dataframe['load_kwh_in_bin'] = dataframe['load_kwh_in_bin_initial'] * dataframe['load_multiplier']
    
    dataframe = dataframe.set_index('agent_id')

    return dataframe


#%%
@decorators.fn_timer(logger=logger, tab_level=2, prefix='')
def calculate_developable_customers_and_load(dataframe):

    dataframe = dataframe.reset_index()

    dataframe['developable_agent_weight'] = dataframe['pct_of_bldgs_developable'] * dataframe['customers_in_bin']
    dataframe['developable_load_kwh_in_bin'] = dataframe['pct_of_bldgs_developable'] * dataframe['load_kwh_in_bin']

    dataframe = dataframe.set_index('agent_id')

    return dataframe


#%%
@decorators.fn_timer(logger=logger, tab_level=2, prefix='')
def get_electric_rates(cur, con, schema, sectors, seed, pg_conn_string):

    # NOTE: This function creates a lookup table for the agents in each sector, providing
    #       the county_id and bin_id for each agent, along with the rate_id_alias and rate_source.
    # This information is used in "get_electric_rate_tariffs" to load in the
    # actual rate tariff for each agent.

    inputs = locals().copy()

    msg = "\tGenerating Electric Rate Tariff Lookup Table for Agents"
    logger.info(msg)

    df_list = []
    for sector_abbr, sector in sectors.items():
        inputs['sector_abbr'] = sector_abbr
        inputs['sector_initial'] = sector_abbr[0].upper()

        sql1 =  """DROP TABLE IF EXISTS {schema}.agent_electric_rate_tariffs_lkup_{sector_abbr};
                    CREATE UNLOGGED TABLE {schema}.agent_electric_rate_tariffs_lkup_{sector_abbr} AS (
                        WITH a AS
                        (
                                SELECT a.agent_id, a.tract_id_alias, a.county_id, a.max_demand_kw, a.avg_monthly_kwh, 
                                    d.rate_id_alias, 
                                    e.rate_rank,
                                    e.rank_utility_type,
                                    e.rate_type_tou,
                                    e.min_demand_kw as rate_min_demand_kw,
                                    e.max_demand_kw as rate_max_demand_kw,
                                    e.min_energy_kwh as rate_min_energy_kwh,
                                    e.max_energy_kwh as rate_max_energy_kwh,
                                    e.sector as rate_sector
                                FROM {schema}.agent_core_attributes_{sector_abbr} a
                                LEFT JOIN diffusion_shared.tract_geoms_2015 b
                                    ON a.state_fips = b.state_fips AND a.county_fips = b.county_fips AND a.tract_fips = b.tract_fips
                                LEFT JOIN diffusion_shared.ventyx_tracts_mappings c
                                    ON b.gisjoin = c.gisjoin
                                INNER JOIN diffusion_shared.urdb3_rate_jsons_20190528 d
                                    ON c.urdb_id = d.eia_id AND '{sector_initial}' = d.res_com
                                INNER JOIN (SELECT DISTINCT ON (rate_id_alias) * FROM diffusion_shared.cntys_ranked_rates_lkup_20190528) e
                                    ON a.state_fips = b.state_fips AND a.county_fips = b.county_fips AND d.rate_id_alias = e.rate_id_alias
                    ),""".format(**inputs)

        # Add logic for Commercial and Industrial
        if sector_abbr != 'res':
            if sector_abbr == 'ind':
                inputs['sector_priority_1'] = 'I'
                inputs['sector_priority_2'] = 'C'
            elif sector_abbr == 'com':
                inputs['sector_priority_1'] = 'C'
                inputs['sector_priority_2'] = 'I'

            # Select Appropriate Rates and Rank the Ranked Rates based on
            # Sector
            sql2 = """b AS
                    (
                        SELECT a.*,
                            (CASE WHEN rate_sector = '{sector_priority_1}' THEN 1
                                WHEN rate_sector = '{sector_priority_2}' THEN 2 END)::int as sector_rank

                        FROM a
                        WHERE rate_sector != 'R'
                            AND ((a.max_demand_kw <= a.rate_max_demand_kw)
                                  AND (a.max_demand_kw >= a.rate_min_demand_kw))
                            AND ((a.avg_monthly_kwh <= a.rate_max_energy_kwh)
                                  AND (a.avg_monthly_kwh >= a.rate_min_energy_kwh))
                    ),
                    c as
                    (
                            SELECT *, rank() OVER (PARTITION BY agent_id ORDER BY rate_rank ASC, sector_rank
                            ASC) as rank
                            FROM b
                    )""".format(**inputs)

        elif sector_abbr == 'res':
            sql2 = """b AS
                    (
                        SELECT a.*
                        FROM a
                        WHERE rate_sector = 'R'
                            AND ((a.max_demand_kw <= a.rate_max_demand_kw)
                                  AND (a.max_demand_kw >= a.rate_min_demand_kw))
                            AND ((a.avg_monthly_kwh <= a.rate_max_energy_kwh)
                                  AND (a.avg_monthly_kwh >= a.rate_min_energy_kwh))
                    ),
                    c as
                    (
                            SELECT *, rank() OVER (PARTITION BY agent_id ORDER BY rate_rank ASC) as rank
                            FROM b
                    )"""

        sql3 = """ SELECT agent_id, rate_id_alias, rank, rate_type_tou
                    FROM c
                    WHERE rank = 1
                    );"""

        sql = sql1 + sql2 + sql3
        cur.execute(sql)
        con.commit()

        # get the rates
        sql = """SELECT agent_id, rate_id_alias, rate_type_tou, '{sector_abbr}'::VARCHAR(3) as sector_abbr
               FROM  {schema}.agent_electric_rate_tariffs_lkup_{sector_abbr} a""".format(**inputs)


        # sql = """SELECT agent_id, rate_id_alias, rate_type_tou, '{sector_abbr}'::VARCHAR(3) as sector_abbr
        #        FROM  {schema}.agent_electric_rate_tariffs_lkup_{sector_abbr} a
        #        WHERE rate_id_alias NOT IN (4175, 7280, 8623, 11106, 11107, 12044)""".format(**inputs)



        df_sector = pd.read_sql(sql, con, coerce_float=False)
        df_list.append(df_sector)

    # combine the dfs
    df = pd.concat(df_list, axis=0, ignore_index=True, sort=False)
    df = df.set_index('agent_id')

    return df


#%%
@decorators.fn_timer(logger=logger, tab_level=2, prefix='')
def check_rate_coverage(dataframe, rates_rank_df):

    # assign a tariff to agents that are missing one
    agent_ids = set(dataframe.index)
    rate_agent_ids = set(rates_rank_df.index)
    missing_agents = list(agent_ids.difference(rate_agent_ids))
    
    # map res/com tariffs based on most likely tariff in state
    res_tariffs = {
                    'AL':{'rate_id_alias':17512,'rate_type_tou':True}, # Family Dwelling Service
                    'AR':{'rate_id_alias':14767,'rate_type_tou':True}, # Optional Residential Time-Of-Use (RT) Single Phase
                    'AZ':{'rate_id_alias':16831,'rate_type_tou':True}, # Residential Time of Use (Saver Choice) TOU-E
                    'CA':{'rate_id_alias':16959,'rate_type_tou':True}, # E-1 -Residential Service Baseline Region P
                    'CO':{'rate_id_alias':16818,'rate_type_tou':True}, # Residential Service (Schedule R)
                    'CT':{'rate_id_alias':15787,'rate_type_tou':False}, # Rate 1 - Residential Electric Service
                    'DC':{'rate_id_alias':14986,'rate_type_tou':True}, # Residential - Schedule R
                    'DE':{'rate_id_alias':11650,'rate_type_tou':True}, # Residential Service
                    'FL':{'rate_id_alias':16909,'rate_type_tou':False}, # RS-1 Residential Service
                    'GA':{'rate_id_alias':15036,'rate_type_tou':True}, # SCHEDULE R-22 RESIDENTIAL SERVICE
                    'IA':{'rate_id_alias':11762,'rate_type_tou':True}, # Optional Residential Service
                    'ID':{'rate_id_alias':12577,'rate_type_tou':False}, # Schedule 1: Residential Rates
                    'IL':{'rate_id_alias':17316,'rate_type_tou':True}, # DS-1 Residential Zone 1
                    'IN':{'rate_id_alias':16425,'rate_type_tou':False}, # RS - Residential Service
                    'KS':{'rate_id_alias':8304,'rate_type_tou':True}, # M System Residential Service
                    'KY':{'rate_id_alias':13497,'rate_type_tou':False}, # Residential Service
                    'LA':{'rate_id_alias':17094,'rate_type_tou':True}, # Residential and Farm Service - Single Phase (RS-L)
                    'MA':{'rate_id_alias':17211,'rate_type_tou':False}, # Greater Boston Residential R-1 (A1)
                    'MD':{'rate_id_alias':15166,'rate_type_tou':False}, # Residential Service (R)
                    'ME':{'rate_id_alias':17243,'rate_type_tou':False}, # A Residential Standard Offer Service (Bundled)
                    'MI':{'rate_id_alias':15844,'rate_type_tou':True}, # Residential Service - Secondary (Rate RS)
                    'MN':{'rate_id_alias':16617,'rate_type_tou':True}, # Residential Service - Overhead Standard (A01)
                    'MO':{'rate_id_alias':17498,'rate_type_tou':True}, # 1(M) Residential Service Rate
                    'MS':{'rate_id_alias':13676,'rate_type_tou':False}, # Residential Service Single Phase (RS-37C)
                    'MT':{'rate_id_alias':5316,'rate_type_tou':False}, # Single Phase
                    'NC':{'rate_id_alias':13819,'rate_type_tou':True}, # Residential Service (RES-41) Single Phase
                    'ND':{'rate_id_alias':13877,'rate_type_tou':True}, # Residential Service Rate 10
                    'NE':{'rate_id_alias':13535,'rate_type_tou':True}, # Residential Service
                    'NH':{'rate_id_alias':14432,'rate_type_tou':False}, # Residential Service
                    'NJ':{'rate_id_alias':15894,'rate_type_tou':True}, # RS - Residential Service
                    'NM':{'rate_id_alias':16989,'rate_type_tou':True}, # 1A (Residential Service)
                    'NV':{'rate_id_alias':14856,'rate_type_tou':False}, # D-1 (Residential Service)
                    'NY':{'rate_id_alias':15882,'rate_type_tou':False}, # SC1- Zone A
                    'OH':{'rate_id_alias':15918,'rate_type_tou':True}, # RS (Residential Service)
                    'OK':{'rate_id_alias':15766,'rate_type_tou':True}, # Residential Service (R-1)
                    'OR':{'rate_id_alias':17082,'rate_type_tou':False}, # Schedule 4 - Residential (Single Phase)
                    'PA':{'rate_id_alias':14746,'rate_type_tou':False}, # RS (Residential Service)
                    'RI':{'rate_id_alias':16189,'rate_type_tou':False}, # A-16 (Residential Service)
                    'SC':{'rate_id_alias':16952,'rate_type_tou':False}, # Residential - RS (SC)
                    'SD':{'rate_id_alias':1182,'rate_type_tou':False}, # Town and Rural Residential Rate
                    'TN':{'rate_id_alias':15624,'rate_type_tou':False}, # Residential Electric Service
                    'TX':{'rate_id_alias':15068,'rate_type_tou':True}, # Residential Service - Time Of Day
                    'UT':{'rate_id_alias':17082,'rate_type_tou':False}, # Schedule 4 - Residential (Single Phase)
                    'VA':{'rate_id_alias':17472,'rate_type_tou':True}, # Residential Schedule 1
                    'VT':{'rate_id_alias':13757,'rate_type_tou':False}, # Rate 01 Residential Service
                    'WA':{'rate_id_alias':16396,'rate_type_tou':False}, # 10 (Residential and Farm Primary General Service)
                    'WI':{'rate_id_alias':16593,'rate_type_tou':False}, # Residential Rg-1
                    'WV':{'rate_id_alias':16521,'rate_type_tou':False}, # Residential Service A
                    'WY':{'rate_id_alias':17082,'rate_type_tou':False} # Schedule 4 - Residential (Single Phase)
                    }
    
    com_tariffs = {
                    'AL':{'rate_id_alias':16462,'rate_type_tou':True}, # BTA - BUSINESS TIME ADVANTAGE (OPTIONAL) - Transmission
                    'AR':{'rate_id_alias':14768,'rate_type_tou':False}, # Small General Service (SGS)
                    'AZ':{'rate_id_alias':10920,'rate_type_tou':True}, # LGS-TOU- N - Large General Service Time-of-Use
                    'CA':{'rate_id_alias':16983,'rate_type_tou':True}, # A-10 Medium General Demand Service (Transmission Voltage)
                    'CO':{'rate_id_alias':14824,'rate_type_tou':True}, # Transmission Time Of Use  (Schedule TTOU)
                    'CT':{'rate_id_alias':15804,'rate_type_tou':False}, # Rate 35 Intermediate General Electric Service
                    'DC':{'rate_id_alias':16156,'rate_type_tou':True}, # General Service (Schedule GS)
                    'DE':{'rate_id_alias':1164,'rate_type_tou':False}, # Schedule LC-P Large Commercial Primary
                    'FL':{'rate_id_alias':13463,'rate_type_tou':True}, # SDTR-1 (Option A)
                    'GA':{'rate_id_alias':1883,'rate_type_tou':True}, # SCHEDULE TOU-MB-4 TIME OF USE - MULTIPLE BUSINESS
                    'IA':{'rate_id_alias':11776,'rate_type_tou':True}, # Three Phase Farm
                    'ID':{'rate_id_alias':15169,'rate_type_tou':False}, # Large General Service (3 Phase)-Schedule 21
                    'IL':{'rate_id_alias':1553,'rate_type_tou':False}, # General Service Three Phase standard
                    'IN':{'rate_id_alias':16426,'rate_type_tou':False}, # CS - Commercial Service
                    'KS':{'rate_id_alias':14943,'rate_type_tou':False}, # Generation Substitution Service
                    'KY':{'rate_id_alias':16502,'rate_type_tou':True}, # Retail Transmission Service
                    'LA':{'rate_id_alias':17104,'rate_type_tou':False}, # Large General Service (LGS-L)
                    'MA':{'rate_id_alias':17271,'rate_type_tou':False}, # Western Massachusetts Primary General Service G-2
                    'MD':{'rate_id_alias':2655,'rate_type_tou':False}, # Commercial
                    'ME':{'rate_id_alias':17401,'rate_type_tou':False}, # General Service Rate
                    'MI':{'rate_id_alias':5446,'rate_type_tou':False}, # Large Power Service (LP4)
                    'MN':{'rate_id_alias':13857,'rate_type_tou':False}, # General Service (D16) Transmission
                    'MO':{'rate_id_alias':17500,'rate_type_tou':True}, # 2(M) Small General Service - Single phase
                    'MS':{'rate_id_alias':16589,'rate_type_tou':True}, # General Service - Low Voltage Single-Phase (GS-LVS-14)
                    'MT':{'rate_id_alias':10885,'rate_type_tou':False}, # Three Phase
                    'NC':{'rate_id_alias':13830,'rate_type_tou':False}, # General Service (GS-41)
                    'ND':{'rate_id_alias':13898,'rate_type_tou':False}, # Small General Electric Service rate 20 (Demand Metered; Non-Demand)
                    'NE':{'rate_id_alias':13536,'rate_type_tou':True}, # General Service Single-Phase
                    'NH':{'rate_id_alias':14444,'rate_type_tou':False}, # GV Commercial and Industrial Service
                    'NJ':{'rate_id_alias':14566,'rate_type_tou':True}, # AGS Secondary- BGS-RSCP
                    'NM':{'rate_id_alias':16991,'rate_type_tou':True}, # 2A (Small Power Service)
                    'NV':{'rate_id_alias':13374,'rate_type_tou':True}, # OGS-2-TOU
                    'NY':{'rate_id_alias':17186,'rate_type_tou':False}, # SC-9 - General Large High Tension Service [Westchester]
                    'OH':{'rate_id_alias':15932,'rate_type_tou':True}, # GS (General Service-Secondary)
                    'OK':{'rate_id_alias':15775,'rate_type_tou':True}, # GS-TOU (General Service Time-Of-Use)
                    'OR':{'rate_id_alias':17056,'rate_type_tou':False}, # Small Non-Residential Direct Access Service, Single Phase (Rate 532)
                    'PA':{'rate_id_alias':7237,'rate_type_tou':False}, # Large Power 2 (LP2)
                    'RI':{'rate_id_alias':16192,'rate_type_tou':False}, # G-02 (General C & I Rate)
                    'SC':{'rate_id_alias':14950,'rate_type_tou':False}, # 3 (Municipal  Power Service)
                    'SD':{'rate_id_alias':3685,'rate_type_tou':False}, # Small Commercial
                    'TN':{'rate_id_alias':15631,'rate_type_tou':False}, # Large General Service (Subtransmission/Transmission)
                    'TX':{'rate_id_alias':6113,'rate_type_tou':False}, # Medium Non-Residential LSP POLR
                    'UT':{'rate_id_alias':3516,'rate_type_tou':False}, # SCHEDULE GS - 3 Phase General Service
                    'VA':{'rate_id_alias':13834,'rate_type_tou':True}, # Small General Service Schedule 5
                    'VT':{'rate_id_alias':13758,'rate_type_tou':False}, # Rate 06: General Service
                    'WA':{'rate_id_alias':16397,'rate_type_tou':False}, # 40 (Large Demand General Service over 3MW - Primary)
                    'WI':{'rate_id_alias':15013,'rate_type_tou':True}, # Cg-7 General Service Time-of-Day (Primary)
                    'WV':{'rate_id_alias':16523,'rate_type_tou':False}, # General Service C
                    'WY':{'rate_id_alias':3911,'rate_type_tou':False} # General Service (GS)-Three phase
                    }
    
    # map industrial tariffs based on census division
    ind_tariffs = {
                    'SA':{'rate_id_alias':15044,'rate_type_tou':True}, # Georgia Power Co, Schedule TOU-GSD-10 Time Of Use - General Service Demand
                    'WSC':{'rate_id_alias':17163,'rate_type_tou':False}, # Southwestern Public Service Co (Texas), Large General Service - Inside City Limits 115 KV
                    'PAC':{'rate_id_alias':17109,'rate_type_tou':True}, # PacifiCorp (Oregon), Schedule 47 - Secondary (Less than 4000 kW)
                    'MA':{'rate_id_alias':16018,'rate_type_tou':True}, # New York State Elec & Gas Corp, All Regions - SERVICE CLASSIFICATION NO. 7-1 Large General Service TOU - Secondary -ESCO                   
                    'MTN':{'rate_id_alias':16823,'rate_type_tou':True}, # Public Service Co of Colorado, Secondary General Service (Schedule SG)                   
                    'ENC':{'rate_id_alias':16547,'rate_type_tou':True}, # Wisconsin Power & Light Co, Industrial Power Cp-1 (Secondary)                   
                    'NE':{'rate_id_alias':14917,'rate_type_tou':True}, # Delmarva Power, General Service - Primary                   
                    'ESC':{'rate_id_alias':16424,'rate_type_tou':True}, # Alabama Power Co, LPM - LIGHT AND POWER SERVICE - MEDIUM                   
                    'WNC':{'rate_id_alias':15015,'rate_type_tou':True} # Northern States Power Co - Wisconsin, Cg-9.1 Large General Time-of-Day Primary Mandatory Customers
                   }

    if len(missing_agents) > 0:
        # print "agents who are missing tariffs:", (missing_agents)
        for missing_agent_id in missing_agents:
            agent_row = dataframe.loc[missing_agent_id]
            if agent_row['sector_abbr'] == 'res':
                agent_row['rate_id_alias'] = res_tariffs[agent_row['state_abbr']]['rate_id_alias']
                agent_row['rate_type_tou'] = res_tariffs[agent_row['state_abbr']]['rate_type_tou']
            elif agent_row['sector_abbr'] == 'ind':
                agent_row['rate_id_alias'] = ind_tariffs[agent_row['census_division_abbr']]['rate_id_alias']
                agent_row['rate_type_tou'] = ind_tariffs[agent_row['census_division_abbr']]['rate_type_tou']
            else:
                agent_row['rate_id_alias'] = com_tariffs[agent_row['state_abbr']]['rate_id_alias']
                agent_row['rate_type_tou'] = com_tariffs[agent_row['state_abbr']]['rate_type_tou']
            rates_rank_df = rates_rank_df.append(agent_row[['sector_abbr', 'rate_id_alias', 'rate_type_tou']])

    missing_agents = list(set(dataframe.index).difference(set(rates_rank_df.index)))
    if len(missing_agents) > 0:
        raise ValueError('Some agents are missing electric rates, including the following agent_ids: {}'.format(missing_agents))
    logger.info('Agents with Missing Electric Rates are {}'.format(missing_agents))

    return rates_rank_df


#%%
@decorators.fn_timer(logger=logger, tab_level=2, prefix='')
def identify_selected_rate_ids(rates_rank_df):

    unique_rate_ids = rates_rank_df['rate_id_alias'].unique().tolist()

    return unique_rate_ids


#%%
def get_electric_rates_json(con, unique_rate_ids):

    inputs = locals().copy()

    # reformat the rate list for use in postgres query
    inputs['rate_id_list'] = utilfunc.pylist_2_pglist(unique_rate_ids)
    inputs['rate_id_list'] = inputs['rate_id_list'].replace("L", "")

    # get (only the required) rate jsons from postgres
    sql = """SELECT a.rate_id_alias, a.rate_name, a.eia_id, a.json as rate_json
             FROM diffusion_shared.urdb3_rate_jsons_20190528 a
             WHERE a.rate_id_alias in ({rate_id_list});""".format(**inputs)
    df = pd.read_sql(sql, con, coerce_float=False)

    return df


#%%
@decorators.fn_timer(logger=logger, tab_level=2, prefix='')
def filter_nem_year(df, year):

    # Filter by Sector Specific Sunset Years
    df = df.loc[(df['first_year'] <= year) & (df['sunset_year'] >= year)]

    return df


#%%
@decorators.fn_timer(logger=logger, tab_level=2, prefix='')
def get_nem_settings(state_limits, state_by_sector, utility_by_sector, selected_scenario, year, state_capacity_by_year, cf_during_peak_demand):

    # Find States That Have Not Sunset
    valid_states = filter_nem_year(state_limits, year)

    # Filter States to Those That Have Not Exceeded Cumulative Capacity Constraints
    valid_states['filter_year'] = pd.to_numeric(valid_states['max_reference_year'], errors='coerce')
    valid_states['filter_year'][valid_states['max_reference_year'] == 'previous'] = year - 2
    valid_states['filter_year'][valid_states['max_reference_year'] == 'current'] = year
    valid_states['filter_year'][pd.isnull(valid_states['filter_year'])] = year

    state_df = pd.merge(state_capacity_by_year, valid_states , how='left', on=['state_abbr'])
    state_df = state_df[state_df['year'] == state_df['filter_year'] ]
    state_df = state_df.merge(cf_during_peak_demand, on = 'state_abbr')

    state_df = state_df.loc[ pd.isnull(state_df['max_cum_capacity_mw']) | ( pd.notnull( state_df['max_cum_capacity_mw']) & (state_df['cum_capacity_mw'] < state_df['max_cum_capacity_mw']))]
    # Calculate the maximum MW of solar capacity before reaching the NEM cap. MW are determine on a generation basis during the period of peak demand, as determined by ReEDS.
    # CF during peak period is based on ReEDS H17 timeslice, assuming average over south-facing 15 degree tilt systems (so this could be improved by using the actual tilts selected)
    state_df['max_mw'] = (state_df['max_pct_cum_capacity']/100) * state_df['peak_demand_mw'] / state_df['solar_cf_during_peak_demand_period']
    state_df = state_df.loc[ pd.isnull(state_df['max_pct_cum_capacity']) | ( pd.notnull( state_df['max_pct_cum_capacity']) & (state_df['max_mw'] > state_df['cum_capacity_mw']))]

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
    state_result = pd.merge( full_state_list.drop_duplicates(), valid_state_sector, how='left', on=['state_abbr','sector_abbr'] )
    state_result['nem_system_kw_limit'].fillna(0, inplace=True)
    
    # Return Utility/Sector data (or null) for all combinations of utilities and sectors
    full_utility_list = utility_by_sector.loc[ utility_by_sector['scenario'] == 'BAU' ].loc[:, ['eia_id','sector_abbr','state_abbr']]
    utility_result = pd.merge( full_utility_list.drop_duplicates(), valid_utility_sector, how='left', on=['eia_id','sector_abbr','state_abbr'] )
    utility_result['nem_system_kw_limit'].fillna(0, inplace=True)

    return state_result, utility_result


#%%
@decorators.fn_timer(logger=logger, tab_level=2, prefix='')
def get_core_agent_attributes(con, schema, region):

    inputs = locals().copy()

    # get the agents from postgres
    sql = """SELECT *
             FROM {schema}.agent_core_attributes_all;""".format(**inputs)

    df = pd.read_sql(sql, con, coerce_float=False)
    df = df.set_index('agent_id')

    return df


#%%
@decorators.fn_timer(logger=logger, tab_level=2, prefix='')
def get_annual_resource_wind(con, schema, year, sectors):

    inputs = locals().copy()

    df_list = []
    for sector_abbr, sector in sectors.items():
        inputs['sector_abbr'] = sector_abbr
        sql = """SELECT 'wind'::VARCHAR(5) as tech,
                        '{sector_abbr}'::VARCHAR(3) as sector_abbr,
                        a.county_id, a.bin_id,
                    	COALESCE(b.turbine_height_m, 0) as turbine_height_m,
                    	COALESCE(b.turbine_size_kw, 0) as turbine_size_kw,
                    	coalesce(c.interp_factor, 0) as power_curve_interp_factor,
                    	COALESCE(c.power_curve_1, -1) as power_curve_1,
                    	COALESCE(c.power_curve_2, -1) as power_curve_2,
                    	COALESCE(d.aep, 0) as naep_1,
                    	COALESCE(e.aep, 0) as naep_2
                FROM  {schema}.agent_core_attributes_{sector_abbr} a
                LEFT JOIN {schema}.agent_allowable_turbines_lkup_{sector_abbr} b
                    	ON a.county_id = b.county_id
                    	and a.bin_id = b.bin_id
                LEFT JOIN {schema}.input_wind_performance_power_curve_transitions c
                    	ON b.turbine_size_kw = c.turbine_size_kw
                         AND c.year = {year}
                LEFT JOIN diffusion_resource_wind.wind_resource_annual d
                    	ON a.i = d.i
                    	AND a.j = d.j
                    	AND a.cf_bin = d.cf_bin
                    	AND b.turbine_height_m = d.height
                    	AND c.power_curve_1 = d.turbine_id
                LEFT JOIN diffusion_resource_wind.wind_resource_annual e
                    	ON a.i = e.i
                    	AND a.j = e.j
                    	AND a.cf_bin = e.cf_bin
                    	AND b.turbine_height_m = e.height
                    	AND c.power_curve_2 = e.turbine_id;""".format(**inputs)
        df_sector = pd.read_sql(sql, con, coerce_float=False)
        df_list.append(df_sector)

    df = pd.concat(df_list, axis=0, ignore_index=True, sort=False)

    return df


#%%
@decorators.fn_timer(logger=logger, tab_level=2, prefix='')
def apply_technology_performance_wind(resource_wind_df, tech_performance_wind_df):

    resource_wind_df = pd.merge(resource_wind_df, tech_performance_wind_df, how='left', on=[
                                'tech', 'turbine_size_kw'])
    resource_wind_df['naep'] = (resource_wind_df['power_curve_interp_factor'] * (resource_wind_df['naep_2'] -
                                                                                 resource_wind_df['naep_1']) + resource_wind_df['naep_1']) * resource_wind_df['wind_derate_factor']

    return resource_wind_df


#%%
@decorators.fn_timer(logger=logger, tab_level=2, prefix='')
def get_normalized_load_profiles(con, schema, sectors):

    inputs = locals().copy()

    df_list = []
    for sector_abbr, sector in sectors.items():
        inputs['sector_abbr'] = sector_abbr
        sql = """SELECT a.agent_id, '{sector_abbr}'::VARCHAR(3) as sector_abbr,
                        a.county_id, a.bin_id,
                        b.nkwh as consumption_hourly,
                        1e8 as scale_offset
                 FROM {schema}.agent_core_attributes_{sector_abbr} a
                 LEFT JOIN diffusion_load_profiles.energy_plus_normalized_load_{sector_abbr} b
                     ON a.crb_model = b.crb_model
                     AND a.hdf_load_index = b.hdf_index;""".format(**inputs)
        df_sector = pd.read_sql(sql, con, coerce_float=False)
        df_list.append(df_sector)

    df = pd.concat(df_list, axis=0, ignore_index=True, sort=False)
    df = df.set_index('agent_id')
    df = df[['consumption_hourly', 'scale_offset']]

    return df


#%%
def get_and_apply_normalized_load_profiles(con, agent):

    inputs = locals().copy()

    inputs['sector_abbr'] = agent.loc['sector_abbr']
    inputs['crb_model'] = agent.loc['crb_model']
    inputs['hdf_load_index'] = agent.loc['hdf_load_index']
    
    sql = """SELECT crb_model, hdf_index,
                    nkwh as consumption_hourly,
                    1e8 as scale_offset
             FROM diffusion_load_profiles.energy_plus_normalized_load_{sector_abbr} b
                 WHERE crb_model = '{crb_model}'
                 AND hdf_index = '{hdf_load_index}';""".format(**inputs)
                           
    df = pd.read_sql(sql, con, coerce_float=False)

    df = df[['consumption_hourly', 'scale_offset']]
    df['load_kwh_per_customer_in_bin'] = agent.loc['load_kwh_per_customer_in_bin']
    # apply the scale offset to convert values to float with correct precision
    df = df.apply(scale_array_precision, axis=1, args=(
        'consumption_hourly', 'scale_offset'))
    
    # scale the normalized profile to sum to the total load
    df = df.apply(scale_array_sum, axis=1, args=(
        'consumption_hourly', 'load_kwh_per_customer_in_bin'))

    return df


#%%
def get_and_apply_normalized_hourly_resource_solar(con, agent):

    inputs = locals().copy()
    
    inputs['solar_re_9809_gid'] = agent.loc['solar_re_9809_gid']
    inputs['tilt'] = agent.loc['tilt']
    inputs['azimuth'] = agent.loc['azimuth']
    
    sql = """SELECT solar_re_9809_gid, tilt, azimuth,
                    cf as generation_hourly,
                    1e6 as scale_offset
            FROM diffusion_resource_solar.solar_resource_hourly
                WHERE solar_re_9809_gid = '{solar_re_9809_gid}'
                AND tilt = '{tilt}'
                AND azimuth = '{azimuth}';""".format(**inputs)
    df = pd.read_sql(sql, con, coerce_float=False)

    df = df[['generation_hourly', 'scale_offset']]
    # rename the column generation_hourly to solar_cf_profile
    df.rename(columns={'generation_hourly':'solar_cf_profile'}, inplace=True)
          
    return df


#%%
def scale_array_precision(row, array_col, prec_offset_col):

    row[array_col] = np.array(
        row[array_col], dtype='float64') / row[prec_offset_col]

    return row


#%%
def scale_array_sum(row, array_col, scale_col):

    hourly_array = np.array(row[array_col], dtype='float64')
    row[array_col] = hourly_array / \
        hourly_array.sum() * np.float64(row[scale_col])

    return row


#%%
@decorators.fn_timer(logger=logger, tab_level=2, prefix='')
def apply_normalized_load_profiles(dataframe, load_df):

    # record the columns in the input dataframe
    in_cols = list(dataframe.columns)
    # join the dataframe and load_df
    dataframe = dataframe.join(load_df, how='left')
    # apply the scale offset to convert values to float with correct precision
    dataframe = dataframe.apply(scale_array_precision, axis=1, args=(
        'consumption_hourly', 'scale_offset'))
    # scale the normalized profile to sum to the total load
    dataframe = dataframe.apply(scale_array_sum, axis=1, args=(
        'consumption_hourly', 'load_kwh_per_customer_in_bin'))

    # subset to only the desired output columns
    out_cols = in_cols + ['consumption_hourly']

    dataframe = dataframe[out_cols]

    return dataframe


#%%
@decorators.fn_timer(logger=logger, tab_level=2, prefix='')
def get_normalized_hourly_resource_solar(con, schema, sectors, techs):

    inputs = locals().copy()

    if 'solar' in techs:
        df_list = []
        for sector_abbr, sector in sectors.items():
            inputs['sector_abbr'] = sector_abbr
            sql = """SELECT 'solar'::VARCHAR(5) as tech,
                            '{sector_abbr}'::VARCHAR(3) as sector_abbr,
                            a.county_id, a.bin_id,
                            b.cf as generation_hourly,
                            1e6 as scale_offset
                    FROM {schema}.agent_core_attributes_{sector_abbr} a
                    LEFT JOIN diffusion_resource_solar.solar_resource_hourly b
                        ON a.solar_re_9809_gid = b.solar_re_9809_gid
                        AND a.tilt = b.tilt
                        AND a.azimuth = b.azimuth;""".format(**inputs)
            df_sector = pd.read_sql(sql, con, coerce_float=False)
            df_list.append(df_sector)

        df = pd.concat(df_list, axis=0, ignore_index=True, sort=False)
    else:
        # return empty dataframe with correct fields
        out_cols = {
            'tech': 'object',
            'sector_abbr': 'object',
                    'county_id': 'int64',
                    'bin_id': 'int64',
                    'generation_hourly': 'object',
                    'scale_offset': 'float64'
        }
        df = pd.DataFrame()
        for col, dtype in out_cols.items():
            df[col] = pd.Series([], dtype=dtype)

    return df


#%%
@decorators.fn_timer(logger=logger, tab_level=2, prefix='')
def get_normalized_hourly_resource_wind(con, schema, sectors, cur, agents, techs):

    if 'wind' in techs:
        inputs = locals().copy()

        # isolate the information from agents regarding the power curves and
        # hub heights for each agent
        system_sizes_df = agents.dataframe[agents.dataframe['tech'] == 'wind'][
            ['sector_abbr', 'county_id', 'bin_id', 'i', 'j', 'cf_bin', 'turbine_height_m', 'power_curve_1', 'power_curve_2']]
        system_sizes_df['turbine_height_m'] = system_sizes_df[
            'turbine_height_m'].astype(np.int64)
        system_sizes_df['power_curve_1'] = system_sizes_df[
            'power_curve_1'].astype(np.int64)
        system_sizes_df['power_curve_2'] = system_sizes_df[
            'power_curve_2'].astype(np.int64)

        df_list = []
        for sector_abbr, sector in sectors.items():
            inputs['sector_abbr'] = sector_abbr
            # write the power curve(s) and turbine heights for each agent to
            # postgres
            sql = """DROP TABLE IF EXISTS {schema}.agent_selected_turbines_{sector_abbr};
                    CREATE UNLOGGED TABLE {schema}.agent_selected_turbines_{sector_abbr}
                    (
                        county_id integer,
                        bin_id integer,
                        i integer,
                        j integer,
                        cf_bin integer,
                        turbine_height_m integer,
                        power_curve_1 integer,
                        power_curve_2 integer
                    );""".format(**inputs)
            cur.execute(sql)
            con.commit()

            system_sizes_sector_df = system_sizes_df[system_sizes_df['sector_abbr'] == sector_abbr][
                ['county_id', 'bin_id', 'i', 'j', 'cf_bin', 'turbine_height_m', 'power_curve_1', 'power_curve_2']]
            system_sizes_sector_df['turbine_height_m'] = system_sizes_sector_df[
                'turbine_height_m'].astype(np.int64)

            s = StringIO()
            # write the data to the stringIO
            system_sizes_sector_df.to_csv(s, index=False, header=False)
            # seek back to the beginning of the stringIO file
            s.seek(0)
            # copy the data from the stringio file to the postgres table
            cur.copy_expert(
                'COPY {schema}.agent_selected_turbines_{sector_abbr} FROM STDOUT WITH CSV'.format(**inputs), s)
            # commit the additions and close the stringio file (clears memory)
            con.commit()
            s.close()

            # add primary key
            sql = """ALTER TABLE {schema}.agent_selected_turbines_{sector_abbr}
                     ADD PRIMARY KEY (county_id, bin_id);""".format(**inputs)
            cur.execute(sql)
            con.commit()

            # add indices
            sql = """CREATE INDEX agent_selected_turbines_{sector_abbr}_btree_i
                     ON {schema}.agent_selected_turbines_{sector_abbr}
                     USING BTREE(i);

                     CREATE INDEX agent_selected_turbines_{sector_abbr}_btree_j
                     ON {schema}.agent_selected_turbines_{sector_abbr}
                     USING BTREE(j);

                     CREATE INDEX agent_selected_turbines_{sector_abbr}_btree_cf_bin
                     ON {schema}.agent_selected_turbines_{sector_abbr}
                     USING BTREE(cf_bin);

                     CREATE INDEX agent_selected_turbines_{sector_abbr}_btree_turbine_height_m
                     ON {schema}.agent_selected_turbines_{sector_abbr}
                     USING BTREE(turbine_height_m);

                     CREATE INDEX agent_selected_turbines_{sector_abbr}_btree_power_curve_1
                     ON {schema}.agent_selected_turbines_{sector_abbr}
                     USING BTREE(power_curve_1);

                     CREATE INDEX agent_selected_turbines_{sector_abbr}_btree_power_curve_2
                     ON {schema}.agent_selected_turbines_{sector_abbr}
                     USING BTREE(power_curve_2);""".format(**inputs)
            cur.execute(sql)
            con.commit()

            sql = """SELECT 'wind'::VARCHAR(5) as tech,
                            '{sector_abbr}'::VARCHAR(3) as sector_abbr,
                            a.county_id, a.bin_id,
                            COALESCE(b.cf, array_fill(1, array[8760])) as generation_hourly_1,
                            COALESCE(c.cf, array_fill(1, array[8760])) as generation_hourly_2,
                            1e3 as scale_offset
                    FROM {schema}.agent_selected_turbines_{sector_abbr} a
                    LEFT JOIN diffusion_resource_wind.wind_resource_hourly b
                        ON a.i = b.i
                        	AND a.j = b.j
                        	AND a.cf_bin = b.cf_bin
                        	AND a.turbine_height_m = b.height
                        	AND a.power_curve_1 = b.turbine_id
                    LEFT JOIN diffusion_resource_wind.wind_resource_hourly c
                        ON a.i = c.i
                        	AND a.j = c.j
                        	AND a.cf_bin = c.cf_bin
                        	AND a.turbine_height_m = c.height
                        	AND a.power_curve_2 = c.turbine_id;""".format(**inputs)
            df_sector = pd.read_sql(sql, con, coerce_float=False)
            df_list.append(df_sector)

        df = pd.concat(df_list, axis=0, ignore_index=True, sort=False)
    else:
        # return empty dataframe with correct fields
        out_cols = {
            'tech': 'object',
            'sector_abbr': 'object',
                    'county_id': 'int64',
                    'bin_id': 'int64',
                    'generation_hourly_1': 'object',
                    'generation_hourly_2': 'object',
                    'scale_offset': 'float64'
        }
        df = pd.DataFrame()
        for col, dtype in out_cols.items():
            df[col] = pd.Series([], dtype=dtype)

    return df


#%%
def interpolate_array(row, array_1_col, array_2_col, interp_factor_col, out_col):

    if row[interp_factor_col] != 0:
        interpolated = row[interp_factor_col] * \
            (row[array_2_col] - row[array_1_col]) + row[array_1_col]
    else:
        interpolated = row[array_1_col]
    row[out_col] = interpolated

    return row


#%%
@decorators.fn_timer(logger=logger, tab_level=2, prefix='')
def apply_normalized_hourly_resource_wind(dataframe, hourly_resource_df, techs):

    if 'wind' in techs:
        # record the columns in the input dataframe
        in_cols = list(dataframe.columns)

        # join resource data to dataframe
        dataframe = pd.merge(dataframe, hourly_resource_df, how='left', on=[
                             'sector_abbr', 'tech', 'county_id', 'bin_id'])
        # apply the scale offset to convert values to float with correct
        # precision
        dataframe = dataframe.apply(scale_array_precision, axis=1, args=(
            'generation_hourly_1', 'scale_offset'))
        dataframe = dataframe.apply(scale_array_precision, axis=1, args=(
            'generation_hourly_2', 'scale_offset'))
        # interpolate power curves
        dataframe = dataframe.apply(interpolate_array, axis=1, args=(
            'generation_hourly_1', 'generation_hourly_2', 'power_curve_interp_factor', 'generation_hourly'))
        # scale the normalized profile by the system size
        dataframe = dataframe.apply(
            scale_array_sum, axis=1, args=('generation_hourly', 'aep'))
        # subset to only the desired output columns
        out_cols = in_cols + ['generation_hourly']
        dataframe = dataframe[out_cols]
    else:
        out_cols = {'generation_hourly': 'object'}
        for col, dtype in out_cols.items():
            dataframe[col] = pd.Series([], dtype=dtype)

    return dataframe


#%%
@decorators.fn_timer(logger=logger, tab_level=2, prefix='')
def apply_carbon_intensities(dataframe, carbon_intensities):

    dataframe = dataframe.reset_index()

    dataframe = pd.merge(dataframe, carbon_intensities, how='left', on=['state_abbr', 'year'])

    dataframe = dataframe.set_index('agent_id')

    return dataframe
    

#%%
@decorators.fn_timer(logger=logger, tab_level=2, prefix='')
def apply_wholesale_elec_prices(dataframe, wholesale_elec_prices):

    dataframe = dataframe.reset_index()

    dataframe = pd.merge(dataframe, wholesale_elec_prices, how='left', on=['county_id', 'year'])

    dataframe = dataframe.set_index('agent_id')

    return dataframe


#%%
@decorators.fn_timer(logger=logger, tab_level=2, prefix='')
def get_state_starting_capacities(con, schema):

    inputs = locals().copy()

    sql = """SELECT *
             FROM {schema}.state_starting_capacities_to_model;""".format(**inputs)
    df = pd.read_sql(sql, con)

    return df

#%%
@decorators.fn_timer(logger=logger, tab_level=2, prefix='')
def apply_state_incentives(dataframe, state_incentives, year, start_year, state_capacity_by_year, end_date = datetime.date(2029, 1, 1)):

    dataframe = dataframe.reset_index()

    # Fill in missing end_dates
    if bool(end_date):
        state_incentives['end_date'][pd.isnull(state_incentives['end_date'])] = end_date

    #Adjust incenctives to account for reduced values as adoption increases
    yearly_escalation_function = lambda value, end_year: max(value - value * (1.0 / (end_year - start_year)) * (year-start_year) , 0)
    for field in ['pbi_usd_p_kwh','cbi_usd_p_w','ibi_pct','cbi_usd_p_wh']:
        state_incentives[field] = state_incentives.apply(lambda row: yearly_escalation_function(row[field],row['end_date'].year),axis=1)
        
    # Filter Incentives by the Years in which they are valid
    state_incentives = state_incentives.loc[
        pd.isnull(state_incentives['start_date']) | (pd.to_datetime(state_incentives['start_date']).dt.year <= year)]
    state_incentives = state_incentives.loc[
        pd.isnull(state_incentives['end_date']) | (pd.to_datetime(state_incentives['end_date']).dt.year >= year)]

    # Combine valid incentives with the cumulative metrics for each state up until the current year
    state_incentives_mg = state_incentives.merge(state_capacity_by_year.loc[state_capacity_by_year['year'] == year],
                                                 how='left', on=["state_abbr"])

    # Filter where the states have not exceeded their cumulative installed capacity (by mw or pct generation) or total program budget
    #state_incentives_mg = state_incentives_mg.loc[pd.isnull(state_incentives_mg['incentive_cap_total_pct']) | (state_incentives_mg['cum_capacity_pct'] < state_incentives_mg['incentive_cap_total_pct'])]
    state_incentives_mg = state_incentives_mg.loc[pd.isnull(state_incentives_mg['incentive_cap_total_mw']) | (state_incentives_mg['cum_capacity_mw'] < state_incentives_mg['incentive_cap_total_mw'])]
    state_incentives_mg = state_incentives_mg.loc[pd.isnull(state_incentives_mg['budget_total_usd']) | (state_incentives_mg['cum_incentive_spending_usd'] < state_incentives_mg['budget_total_usd'])]

    output  =[]
    for i in state_incentives_mg.groupby(['state_abbr', 'sector_abbr']):
        row = i[1]
        state, sector = i[0]
        output.append({'state_abbr':state, 'sector_abbr':sector,"state_incentives":row})

    state_inc_df = pd.DataFrame(columns=['state_abbr', 'sector_abbr', 'state_incentives'])
    state_inc_df = pd.concat([state_inc_df, pd.DataFrame.from_records(output)], sort=False)
    
    dataframe = pd.merge(dataframe, state_inc_df, on=['state_abbr','sector_abbr'], how='left')
    
    dataframe = dataframe.set_index('agent_id')

    return dataframe

#%%
@decorators.fn_timer(logger=logger, tab_level=2, prefix='')
def estimate_initial_market_shares(dataframe, state_starting_capacities_df):

    # record input columns
    in_cols = list(dataframe.columns)

    # find the total number of customers in each state (by technology and
    # sector)
    state_total_developable_customers = dataframe[['state_abbr', 'sector_abbr', 'tech', 'developable_agent_weight']].groupby(
        ['state_abbr', 'sector_abbr', 'tech']).sum().reset_index()
    state_total_agents = dataframe[['state_abbr', 'sector_abbr', 'tech', 'developable_agent_weight']].groupby(
        ['state_abbr', 'sector_abbr', 'tech']).count().reset_index()
    # rename the final columns
    state_total_developable_customers.columns = state_total_developable_customers.columns.str.replace(
        'developable_agent_weight', 'developable_customers_in_state')
    state_total_agents.columns = state_total_agents.columns.str.replace(
        'developable_agent_weight', 'agent_count')
    # merge together
    state_denominators = pd.merge(state_total_developable_customers, state_total_agents, how='left', on=[
                                  'state_abbr', 'sector_abbr', 'tech'])

    # merge back to the main dataframe
    dataframe = pd.merge(dataframe, state_denominators, how='left', on=[
                         'state_abbr', 'sector_abbr', 'tech'])

    # merge in the state starting capacities
    dataframe = pd.merge(dataframe, state_starting_capacities_df, how='left',
                         on=['tech', 'state_abbr', 'sector_abbr'])

    # determine the portion of initial load and systems that should be allocated to each agent
    # (when there are no developable agnets in the state, simply apportion evenly to all agents)
    dataframe['portion_of_state'] = np.where(dataframe['developable_customers_in_state'] > 0,
                                             dataframe[
                                                 'developable_agent_weight'] / dataframe['developable_customers_in_state'],
                                             1. / dataframe['agent_count'])
    # apply the agent's portion to the total to calculate starting capacity and systems
    dataframe['adopters_cum_last_year'] = dataframe['portion_of_state'] * dataframe['systems_count']
    dataframe['system_kw_cum_last_year'] = dataframe['portion_of_state'] * dataframe['capacity_mw'] * 1000.0
    dataframe['batt_kw_cum_last_year'] = 0.0
    dataframe['batt_kwh_cum_last_year'] = 0.0

    dataframe['market_share_last_year'] = np.where(dataframe['developable_agent_weight'] == 0, 0,
                                                   dataframe['adopters_cum_last_year'] / dataframe['developable_agent_weight'])

    dataframe['market_value_last_year'] = dataframe['system_capex_per_kw'] * dataframe['system_kw_cum_last_year']

    # reproduce these columns as "initial" columns too
    dataframe['initial_number_of_adopters'] = dataframe['adopters_cum_last_year']
    dataframe['initial_pv_kw'] = dataframe['system_kw_cum_last_year']
    dataframe['initial_market_share'] = dataframe['market_share_last_year']
    dataframe['initial_market_value'] = 0

    # isolate the return columns
    return_cols = ['initial_number_of_adopters', 'initial_pv_kw', 'initial_market_share', 'initial_market_value',
                   'adopters_cum_last_year', 'system_kw_cum_last_year', 'batt_kw_cum_last_year', 'batt_kwh_cum_last_year', 'market_share_last_year', 'market_value_last_year']

    dataframe[return_cols] = dataframe[return_cols].fillna(0)

    out_cols = in_cols + return_cols

    return dataframe[out_cols]


#%%
@decorators.fn_timer(logger=logger, tab_level=2, prefix='')
def apply_market_last_year(dataframe, market_last_year_df):
    
    dataframe = dataframe.merge(market_last_year_df, on=['agent_id'], how='left')
    return dataframe


#%%
@decorators.fn_timer(logger=logger, tab_level=2, prefix='')
def estimate_total_generation(dataframe):

    dataframe['total_gen_twh'] = ((dataframe['number_of_adopters'] - dataframe['initial_number_of_adopters'])
                                  * dataframe['annual_energy_production_kwh'] * 1e-9) + (0.23 * 8760 * dataframe['initial_pv_kw'] * 1e-6)

    return dataframe


#%%   
@decorators.fn_timer(logger=logger, tab_level=2, prefix='')
def calc_state_capacity_by_year(con, schema, load_growth, peak_demand_mw, is_first_year, year,solar_agents, last_year_installed_capacity):

    if is_first_year:
        df = last_year_installed_capacity.query('tech == "solar"').groupby('state_abbr')['capacity_mw'].sum().reset_index()
        # Not all states have starting capacity, don't want to drop any states thus left join on peak_demand
        df = peak_demand_mw.merge(df,how = 'left').fillna(0)
        df['peak_demand_mw'] = df['peak_demand_mw_2014']
        df['cum_capacity_mw'] = df['capacity_mw']

    else:
        df = last_year_installed_capacity.copy()
        df['cum_capacity_mw'] = df['system_kw_cum']/1000
#        # Load growth is resolved by census region, so a lookup table is needed
#        df = df.merge(census_division_lkup, on = 'state_abbr')
        load_growth_this_year = load_growth.loc[(load_growth['year'] == year) & (load_growth['sector_abbr'] == 'res')]
        load_growth_this_year = pd.merge(solar_agents.df[['state_abbr', 'county_id']], load_growth_this_year, how='left', on=['county_id'])
        load_growth_this_year = load_growth_this_year.groupby('state_abbr')['load_multiplier'].mean().reset_index()
        df = df.merge(load_growth_this_year, on = 'state_abbr')
        
        df = peak_demand_mw.merge(df,how = 'left', on = 'state_abbr').fillna(0)
        df['peak_demand_mw'] = df['peak_demand_mw_2014'] * df['load_multiplier']

    df["cum_capacity_pct"] = 0
    df["cum_incentive_spending_usd"] = 0
    df['year'] = year
    
    df = df[["state_abbr","cum_capacity_mw","cum_capacity_pct","cum_incentive_spending_usd","peak_demand_mw","year"]]
    
    return df

#%%
def get_and_apply_eia_ids(dataframe, con):
    
    dataframe = dataframe.reset_index()
    dataframe["tract_id_alias"] = dataframe.tract_id_alias.astype(int)
    
    inputs = locals().copy()
    inputs['tract_alias_list'] = utilfunc.pylist_2_pglist(dataframe['tract_id_alias'].unique().tolist())
    inputs['tract_alias_list'] = inputs['tract_alias_list'].replace("L", "")
    
    # get lookup between tract_id_alias and eia_id based on ventyx_tracts_mappings table
    sql = """SELECT b.tract_id_alias, a.urdb_id as eia_id
                FROM diffusion_shared.ventyx_tracts_mappings a
                LEFT JOIN diffusion_blocks.tract_geoms b
                ON a.gisjoin = b.gisjoin
                WHERE b.tract_id_alias IN ({tract_alias_list});""".format(**inputs)
    eia_id_lkup = pd.read_sql(sql, con, coerce_float=False)
    
    dataframe = pd.merge(dataframe, eia_id_lkup, how='left', on='tract_id_alias')
    
    dataframe = dataframe.set_index('agent_id')
    
    return dataframe


#%%
def get_rate_switch_table(con):
    
    # get rate switch table from database
    sql = """SELECT * FROM diffusion_shared.rate_switch_lkup_2019;"""
    rate_switch_table = pd.read_sql(sql, con, coerce_float=False)
    rate_switch_table = rate_switch_table.reset_index(drop=True)
    
    return rate_switch_table

def apply_rate_switch(rate_switch_table, agent, system_size_kw):
    
    rate_switch_table.rename(columns={'rate_id_alias':'tariff_id', 'json':'tariff_dict'}, inplace=True)
    rate_switch_table = rate_switch_table[(rate_switch_table['eia_id'] == agent.loc['eia_id']) &
                                          (rate_switch_table['res_com'] == str(agent.loc['sector_abbr']).upper()[0]) &
                                          (rate_switch_table['min_pv_kw_limit'] <= system_size_kw) &
                                          (rate_switch_table['max_pv_kw_limit'] > system_size_kw)]
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
        # don't update agent attributes, return one time charge of $0
        one_time_charge = 0.
    
    
    return agent, one_time_charge



#%%
@decorators.fn_timer(logger=logger, tab_level=2, prefix='')
def reassign_agent_tariffs(dataframe, con):

    # define rates to use in replacement of incorrect tariffs
    
    # map res/com tariffs based on most likely tariff in state
    res_tariffs = {
                    'AL':17512, # Family Dwelling Service
                    'AR':14767, # Optional Residential Time-Of-Use (RT) Single Phase
                    'AZ':16831, # Residential Time of Use (Saver Choice) TOU-E
                    'CA':16959, # E-1 -Residential Service Baseline Region P
                    'CO':16818, # Residential Service (Schedule R)
                    'CT':15787, # Rate 1 - Residential Electric Service
                    'DC':14986, # Residential - Schedule R
                    'DE':11650, # Residential Service
                    'FL':16909, # RS-1 Residential Service
                    'GA':15036, # SCHEDULE R-22 RESIDENTIAL SERVICE
                    'IA':11762, # Optional Residential Service
                    'ID':12577, # Schedule 1: Residential Rates
                    'IL':17316, # DS-1 Residential Zone 1
                    'IN':16425, # RS - Residential Service
                    'KS':8304, # M System Residential Service
                    'KY':13497, # Residential Service
                    'LA':17094, # Residential and Farm Service - Single Phase (RS-L)
                    'MA':17211, # Greater Boston Residential R-1 (A1)
                    'MD':15166, # Residential Service (R)
                    'ME':17243, # A Residential Standard Offer Service (Bundled)
                    'MI':15844, # Residential Service - Secondary (Rate RS)
                    'MN':16617, # Residential Service - Overhead Standard (A01)
                    'MO':17498, # 1(M) Residential Service Rate
                    'MS':13676, # Residential Service Single Phase (RS-37C)
                    'MT':5316, # Single Phase
                    'NC':13819, # Residential Service (RES-41) Single Phase
                    'ND':13877, # Residential Service Rate 10
                    'NE':13535, # Residential Service
                    'NH':14432, # Residential Service
                    'NJ':15894, # RS - Residential Service
                    'NM':16989, # 1A (Residential Service)
                    'NV':14856, # D-1 (Residential Service)
                    'NY':15882, # SC1- Zone A
                    'OH':15918, # RS (Residential Service)
                    'OK':15766, # Residential Service (R-1)
                    'OR':17082, # Schedule 4 - Residential (Single Phase)
                    'PA':14746, # RS (Residential Service)
                    'RI':16189, # A-16 (Residential Service)
                    'SC':16952, # Residential - RS (SC)
                    'SD':1182, # Town and Rural Residential Rate
                    'TN':15624, # Residential Electric Service
                    'TX':15068, # Residential Service - Time Of Day
                    'UT':17082, # Schedule 4 - Residential (Single Phase)
                    'VA':17472, # Residential Schedule 1
                    'VT':13757, # Rate 01 Residential Service
                    'WA':16396, # 10 (Residential and Farm Primary General Service)
                    'WI':16593, # Residential Rg-1
                    'WV':16521, # Residential Service A
                    'WY':17082 # Schedule 4 - Residential (Single Phase)
                    }
    
    com_tariffs = {
                    'AL':16462, # BTA - BUSINESS TIME ADVANTAGE (OPTIONAL) - Transmission
                    'AR':14768, # Small General Service (SGS)
                    'AZ':10920, # LGS-TOU- N - Large General Service Time-of-Use
                    'CA':16983, # A-10 Medium General Demand Service (Transmission Voltage)
                    'CO':14824, # Transmission Time Of Use  (Schedule TTOU)
                    'CT':15804, # Rate 35 Intermediate General Electric Service
                    'DC':16156, # General Service (Schedule GS)
                    'DE':1164, # Schedule LC-P Large Commercial Primary
                    'FL':13463, # SDTR-1 (Option A)
                    'GA':1883, # SCHEDULE TOU-MB-4 TIME OF USE - MULTIPLE BUSINESS
                    'IA':11776, # Three Phase Farm
                    'ID':15169, # Large General Service (3 Phase)-Schedule 21
                    'IL':1553, # General Service Three Phase standard
                    'IN':16426, # CS - Commercial Service
                    'KS':14943, # Generation Substitution Service
                    'KY':16502, # Retail Transmission Service
                    'LA':17104, # Large General Service (LGS-L)
                    'MA':17271, # Western Massachusetts Primary General Service G-2
                    'MD':2655, # Commercial
                    'ME':17401, # General Service Rate
                    'MI':5446, # Large Power Service (LP4)
                    'MN':13857, # General Service (D16) Transmission
                    'MO':17500, # 2(M) Small General Service - Single phase
                    'MS':16589, # General Service - Low Voltage Single-Phase (GS-LVS-14)
                    'MT':10885, # Three Phase
                    'NC':13830, # General Service (GS-41)
                    'ND':13898, # Small General Electric Service rate 20 (Demand Metered; Non-Demand)
                    'NE':13536, # General Service Single-Phase
                    'NH':14444, # GV Commercial and Industrial Service
                    'NJ':14566, # AGS Secondary- BGS-RSCP
                    'NM':16991, # 2A (Small Power Service)
                    'NV':13374, # OGS-2-TOU
                    'NY':17186, # SC-9 - General Large High Tension Service [Westchester]
                    'OH':15932, # GS (General Service-Secondary)
                    'OK':15775, # GS-TOU (General Service Time-Of-Use)
                    'OR':17056, # Small Non-Residential Direct Access Service, Single Phase (Rate 532)
                    'PA':7237, # Large Power 2 (LP2)
                    'RI':16192, # G-02 (General C & I Rate)
                    'SC':14950, # 3 (Municipal  Power Service)
                    'SD':3685, # Small Commercial
                    'TN':15631, # Large General Service (Subtransmission/Transmission)
                    'TX':6113, # Medium Non-Residential LSP POLR
                    'UT':3516, # SCHEDULE GS - 3 Phase General Service
                    'VA':13834, # Small General Service Schedule 5
                    'VT':13758, # Rate 06: General Service
                    'WA':16397, # 40 (Large Demand General Service over 3MW - Primary)
                    'WI':15013, # Cg-7 General Service Time-of-Day (Primary)
                    'WV':16523, # General Service C
                    'WY':3911 # General Service (GS)-Three phase
                    }
    
    # map industrial tariffs based on census division
    ind_tariffs = {
                    'SA':15044, # Georgia Power Co, Schedule TOU-GSD-10 Time Of Use - General Service Demand
                    'WSC':17163, # Southwestern Public Service Co (Texas), Large General Service - Inside City Limits 115 KV
                    'PAC':17109, # PacifiCorp (Oregon), Schedule 47 - Secondary (Less than 4000 kW)
                    'MA':16018, # New York State Elec & Gas Corp, All Regions - SERVICE CLASSIFICATION NO. 7-1 Large General Service TOU - Secondary -ESCO                   
                    'MTN':16823, # Public Service Co of Colorado, Secondary General Service (Schedule SG)                   
                    'ENC':16547, # Wisconsin Power & Light Co, Industrial Power Cp-1 (Secondary)                   
                    'NE':14917, # Delmarva Power, General Service - Primary                   
                    'ESC':16424, # Alabama Power Co, LPM - LIGHT AND POWER SERVICE - MEDIUM                   
                    'WNC':15015 # Northern States Power Co - Wisconsin, Cg-9.1 Large General Time-of-Day Primary Mandatory Customers
                   }
    
    dataframe = dataframe.reset_index()

    # separate agents with incorrect and correct rates
    bad_rates = dataframe.loc[np.in1d(dataframe['tariff_id'], [4175, 7280, 8623, 11106, 11107, 12044])]
    good_rates = dataframe.loc[~np.in1d(dataframe['tariff_id'], [4175, 7280, 8623, 11106, 11107, 12044])]
    
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


