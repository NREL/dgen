"""
Functions for pulling data
Created on Mon Mar 24 08:59:44 2014
@author: mgleason and bsigrin
"""
import psycopg2 as pg
import time
import numpy as np
import pandas as pd
import datetime
from datetime import datetime
from multiprocessing import Process, JoinableQueue
from io import StringIO
import gzip
import subprocess
import os
import psutil
import decorators
import utility_functions as utilfunc
import shutil
import glob
import pickle
import sys
import logging
import imp
imp.reload(logging)
import sqlalchemy
import json

#==============================================================================
# Load logger
logger = utilfunc.get_logger()
#==============================================================================


#==============================================================================
# configure psycopg2 to treat numeric values as floats (improves
# performance of pulling data from the database)
DEC2FLOAT = pg.extensions.new_type(
    pg.extensions.DECIMAL.values,
    'DEC2FLOAT',
    lambda value, curs: float(value) if value is not None else None)
pg.extensions.register_type(DEC2FLOAT)
#==============================================================================

#%%
@decorators.fn_timer(logger=logger, tab_level=2, prefix='')
def aggregate_outputs_solar(agent_df, year, is_first_year,
                            scenario_settings, out_scen_path,
                            interyear_results_aggregations=None):
                                
    ''' 
    Aggregate agent-level results into ba-level results for the given year. 
    
    Parameters
    ----------
    **agent_df** : 'pd.df'
        Dataframe of agents 
    **year** : 'int'
        Year
    **is_first_year** : 'bool'
        If True, creates dataframe with ba as index
    **scenario_settings** : 'object'
        Object which contains scenario settings
    **out_scen_path** : 'directory'
        Path for the scenario folder to send re
    **interyear_results_aggregations** : 'dict'
        Dictionary of dataframes of ba-level results from previous years

    Returns
    -------
    **interyear_results_aggregations** : 'dict'
        Dictionary of dataframes of ba-level results for the given year

    '''
                                
    # Unpack results dict from previous years
    if interyear_results_aggregations != None:
        ba_cum_pv_mw = interyear_results_aggregations['ba_cum_pv_mw']
        ba_cum_batt_mw = interyear_results_aggregations['ba_cum_batt_mw']
        ba_cum_batt_mwh = interyear_results_aggregations['ba_cum_batt_mwh']
        dispatch_all_adopters = interyear_results_aggregations['dispatch_all_adopters']
        dispatch_by_ba_and_year = interyear_results_aggregations['dispatch_by_ba_and_year']
        
    #==========================================================================================================
    # Set up objects
    #==========================================================================================================   
    ba_list = np.unique(np.array(agent_df['ba']))
        
    col_list_8760 = list(['ba', 'year'])
    hour_list = list(np.arange(1,8761))
    col_list_8760 = col_list_8760 + hour_list
    
    if is_first_year == True:  
        # PV and batt capacities
        ba_cum_pv_mw = pd.DataFrame(index=ba_list)
        ba_cum_batt_mw = pd.DataFrame(index=ba_list)
        ba_cum_batt_mwh = pd.DataFrame(index=ba_list)
    
        # Battery dispatches
        dispatch_by_ba_and_year = pd.DataFrame(columns = col_list_8760)
    
    # Set up for groupby
    agent_df['index'] = list(range(len(agent_df)))
    agent_df_to_group = agent_df[['ba', 'index']]
    agents_grouped = agent_df_to_group.groupby(['ba']).aggregate(lambda x: tuple(x))
    
    #==========================================================================================================
    # Aggregate PV and Batt capacity by reeds region
    #========================================================================================================== 
    agent_cum_capacities = agent_df[[ 'ba', 'system_kw_cum']]
    ba_cum_pv_kw_year = agent_cum_capacities.groupby(by='ba').sum()
    ba_cum_pv_kw_year['ba'] = ba_cum_pv_kw_year.index
    ba_cum_pv_mw[year] = ba_cum_pv_kw_year['system_kw_cum'] / 1000.0
    ba_cum_pv_mw.round(3).to_csv(out_scen_path + '/dpv_MW_by_ba_and_year.csv', index_label='ba')                     
    
    agent_cum_batt_mw = agent_df[[ 'ba', 'batt_kw_cum']]
    agent_cum_batt_mw['batt_mw_cum'] = agent_cum_batt_mw['batt_kw_cum'] / 1000.0
    agent_cum_batt_mwh = agent_df[[ 'ba', 'batt_kwh_cum']]
    agent_cum_batt_mwh['batt_mwh_cum'] = agent_cum_batt_mwh['batt_kwh_cum'] / 1000.0
    
    ba_cum_batt_mw_year = agent_cum_batt_mw.groupby(by='ba').sum()
    ba_cum_batt_mwh_year = agent_cum_batt_mwh.groupby(by='ba').sum()
    
    ba_cum_batt_mw[year] = ba_cum_batt_mw_year['batt_mw_cum']
    ba_cum_batt_mw.round(3).to_csv(out_scen_path + '/batt_MW_by_ba_and_year.csv', index_label='ba')                     
    
    ba_cum_batt_mwh[year] = ba_cum_batt_mwh_year['batt_mwh_cum']
    ba_cum_batt_mwh.round(3).to_csv(out_scen_path + '/batt_MWh_by_ba_and_year.csv', index_label='ba') 
    
    
    #==========================================================================================================
    # Aggregate PV generation profiles and calculate capacity factor profiles
    #==========================================================================================================   
    # DPV CF profiles are only calculated for the last year, since they change
    # negligibly from year-to-year. A ten-year degradation is applied, to 
    # approximate the age of a mature fleet.
    if year==scenario_settings.model_years[-1]:
        pv_gen_by_agent = np.vstack(agent_df['solar_cf_profile']).astype(np.float) / 1e6 * np.array(agent_df['system_kw_cum']).reshape(len(agent_df), 1)
        
        # Sum each agent's profile into a total dispatch in each BA
        pv_gen_by_ba = np.zeros([len(ba_list), 8760])
        for ba_n, ba in enumerate(ba_list):
            list_of_agent_indicies = np.array(agents_grouped.loc[ba, 'index'])
            pv_gen_by_ba[ba_n, :] = np.sum(pv_gen_by_agent[list_of_agent_indicies, :], axis=0)
       
        # Apply ten-year degradation
        pv_deg_rate = agent_df.loc[agent_df.index[0], 'pv_degradation_factor'] 
        pv_gen_by_ba = pv_gen_by_ba * (1-pv_deg_rate)**10   
        
        # Change the numpy array into pandas dataframe
        pv_gen_by_ba_df = pd.DataFrame(pv_gen_by_ba, columns=hour_list)
        pv_gen_by_ba_df.index = ba_list

        # Convert generation into capacity factor by diving by total capacity
        pv_cf_by_ba = pv_gen_by_ba_df[hour_list].divide(ba_cum_pv_mw[year]*1000.0, 'index')
        pv_cf_by_ba['ba'] = ba_list
    
        # write output
        pv_cf_by_ba = pv_cf_by_ba[['ba'] + hour_list]
        pv_cf_by_ba.round(3).to_csv(out_scen_path + '/dpv_cf_by_ba.csv', index=False) 

    
    #==========================================================================================================
    # Aggregate storage dispatch trajectories
    #==========================================================================================================   
    if scenario_settings.output_batt_dispatch_profiles == True:

        # Change 8760's in cells into a numpy array
        dispatch_new_adopters = np.vstack(agent_df['batt_dispatch_profile']).astype(np.float) * np.array(agent_df['new_adopters']).reshape(len(agent_df), 1) / 1000.0
        
        # Sum each agent's profile into a total dispatch for new adopters in each BA
        dispatch_new_adopters_by_ba = np.zeros([len(ba_list), 8760])
        for ba_n, ba in enumerate(ba_list):
            list_of_agent_indicies = np.array(agents_grouped.loc[ba, 'index'])
            dispatch_new_adopters_by_ba[ba_n, :] = np.sum(dispatch_new_adopters[list_of_agent_indicies, :], axis=0)
        
        # Change the numpy array into pandas dataframe
        dispatch_new_adopters_by_ba_df = pd.DataFrame(dispatch_new_adopters_by_ba, columns=hour_list)
        dispatch_new_adopters_by_ba_df['ba'] = ba_list
        
        
        ## Add the new adopter's dispatches to the previous adopter's dispatches
        if is_first_year == True:
            dispatch_all_adopters = dispatch_new_adopters_by_ba_df.copy()        
        else:
            dispatch_all_adopters[hour_list] = dispatch_all_adopters[hour_list] + dispatch_new_adopters_by_ba_df[hour_list]
        
        # Append this year's total to the running df
        dispatch_all_adopters['year'] = year
        dispatch_by_ba_and_year = dispatch_by_ba_and_year.append(dispatch_all_adopters)
            
        # Degrade systems by two years
        batt_deg_rate = 0.982
        dispatch_all_adopters[hour_list] = dispatch_all_adopters[hour_list] * batt_deg_rate**2
        
        # If it is the final year, write outputs
        if year==scenario_settings.model_years[-1]:
            dispatch_by_ba_and_year = dispatch_by_ba_and_year[['ba', 'year'] + hour_list] # reorder the columns
            dispatch_by_ba_and_year['year'] = np.array(dispatch_by_ba_and_year['year'], int)
            dispatch_by_ba_and_year.round(3).to_csv(out_scen_path + '/dispatch_by_ba_and_year_MW.csv', index=False)
    
                                      
    #==========================================================================================================
    # Aggregate 8760's into ReEDS timeslices
    #==========================================================================================================                                        
    if year==scenario_settings.model_years[-1]:  
        print("aggregating by timeslice...")                      
                                                  
        ba_list = list(pv_cf_by_ba['ba'])
            
        ts_list = list()
        for ts in np.arange(1, 18):
            ts_list = ts_list + ["H{}".format(ts)]
        
        ts_map = pd.read_csv('timeslice_8760_wH17.csv')
        ts_map = ts_map[['hour'] + ba_list]

        ts_map_tidy = pd.melt(ts_map, id_vars="hour", value_vars=ba_list, var_name='ba', value_name="ts")

        #==========================================================================================================
        # Aggregate PV CF by timeslice
        #==========================================================================================================        
        ts_cf_tidy = pd.DataFrame(columns=['ba', 'ts'])
        pv_cf_by_ba.set_index('ba', inplace=True)
        pv_cf_by_ba = pv_cf_by_ba.transpose()
        pv_cf_by_ba['hour'] = [int(numeric_string) for numeric_string in pv_cf_by_ba.index.values]
                
        pv_cf_by_ba_tidy = pd.melt(pv_cf_by_ba, id_vars='hour', value_vars=ba_list, var_name="ba", value_name="cf")
            
        ts_and_cf_tidy = pd.merge(ts_map_tidy, pv_cf_by_ba_tidy, how='left', on=['hour', 'ba'])
            
        ts_cf_tidy = ts_and_cf_tidy[['ba', 'cf', 'ts']].groupby(['ba', 'ts']).mean().reset_index()
                    
        ts_cf_wide = ts_cf_tidy.pivot(index='ba', columns='ts', values='cf')
   
        ts_cf_wide[ts_list].round(3).to_csv(out_scen_path + '/dpv_cf_by_ba_ts.csv')
                
        
        #==========================================================================================================
        # Aggregate dispatch by timeslice
        #========================================================================================================== 
        ts_dispatch_all_years = pd.DataFrame()           
        for year_i in np.arange(2014, scenario_settings.model_years[-1]+1, 2):
            dispatch_year = dispatch_by_ba_and_year[dispatch_by_ba_and_year['year']==year_i]
            dispatch_year = dispatch_year.drop(['year'], axis=1)
            dispatch_year.set_index('ba', inplace=True)
            dispatch_year = dispatch_year.transpose()
            dispatch_year['hour'] = [int(numeric_string) for numeric_string in dispatch_year.index.values]
                    
            dispatch_year_tidy = pd.melt(dispatch_year, id_vars='hour', value_vars=ba_list, var_name="ba", value_name="dispatch")
            
            ts_and_dispatch_tidy = pd.merge(ts_map_tidy, dispatch_year_tidy, how='left', on=['hour', 'ba'])
            ts_and_dispatch_tidy_ts = ts_and_dispatch_tidy[['ba', 'dispatch', 'ts']].groupby(['ba', 'ts']).mean().reset_index()
                
            ts_dispatch_wide = ts_and_dispatch_tidy_ts.pivot(index='ba', columns='ts', values='dispatch')
            ts_dispatch_wide['year'] = year_i
            ts_dispatch_wide['ba'] = ts_dispatch_wide.index.values
            ts_dispatch_all_years = pd.concat([ts_dispatch_all_years, ts_dispatch_wide], ignore_index=True, sort=False)
                
        ts_dispatch_all_years['year'] = np.array(ts_dispatch_all_years['year'], int)
        ts_dispatch_all_years[['year', 'ba']+ts_list].round(3).to_csv(out_scen_path + '/dispatch_by_ba_and_year_MW_ts.csv', index=False)
        print("done aggregating by timeslice")                      


    #==========================================================================================================
    # Package interyear results
    #========================================================================================================== 
    interyear_results_aggregations = {'ba_cum_pv_mw':ba_cum_pv_mw,
                                      'ba_cum_batt_mw':ba_cum_batt_mw,
                                      'ba_cum_batt_mwh':ba_cum_batt_mwh,
                                      'dispatch_all_adopters':dispatch_all_adopters,
                                      'dispatch_by_ba_and_year':dispatch_by_ba_and_year}
 
    return interyear_results_aggregations
    
#%%

def create_tech_subfolders(out_scen_path, techs, out_subfolders):
    """
    Creates subfolders for results of each specified technology
    
    Parameters
    ----------
    **out_scen_path** : 'directory'
        Path for the scenario folder to send results
    **techs** : 'string'
        Technology type 
    **out_subfolders** : 'dict'
        Dictionary of empty subfolder paths for wind and solar

    Returns
    -------
    out_subfolders : 'dict'
        Dictionary with subfolder paths for wind and solar

    """

    for tech in techs:
        # set output subfolders
        out_tech_path = os.path.join(out_scen_path, tech)
        os.makedirs(out_tech_path)
        out_subfolders[tech].append(out_tech_path)

    return out_subfolders


def create_scenario_results_folder(input_scenario, scen_name, scenario_names, out_dir, dup_n=0):
    """
    Creates scenario results directories
    
    Parameters
    ----------
    **input_scenario** : 'directory'
        Scenario inputs pulled from excel file within diffusion/inputs_scenarios folder
    **scen_name** : 'string'
        Scenario Name 
    **scenario_names** : 'list'
        List of scenario names
    **out_dir** : 'directory'
        Output directory for scenario subfolders
    **dup_n** : 'int'
        Number to track duplicate scenarios in scenario_names. Default is 0 unless otherwise specified.
    
    Returns
    -------
    out_scen_path : 'directory'
        Path for the scenario subfolders to send results
    **scenario_names**
        Populated list of scenario names
    **dup_n** : 'int'
        Number to track duplicate scenarios, stepped up by 1 from original value if there is a duplicate

    """

    if scen_name in scenario_names:
        logger.info("Warning: Scenario name {0} is a duplicate. Renaming to {1}_{2}".format((
            scen_name, scen_name, dup_n)))
        scen_name = "{0}_{1}".format((scen_name, dup_n))
        dup_n += 1
    scenario_names.append(scen_name)
    out_scen_path = os.path.join(out_dir, scen_name)
    os.makedirs(out_scen_path)
    # copy the input scenario spreadsheet
    if input_scenario is not None:
        shutil.copy(input_scenario, out_scen_path)

    return out_scen_path, scenario_names, dup_n


@decorators.fn_timer(logger=logger, tab_level=1, prefix='')
def create_output_schema(pg_conn_string, role, suffix, scenario_list, source_schema='diffusion_template', include_data=False):
    """
    Creates output schema that will be dropped into the database
    
    Parameters
    ----------
    **pg_conn_string** : 'string'
        String to connect to pgAdmin database
    **role** : 'string'
        Owner of schema 
    **suffix** : 'string'
        String to mark the time that model is kicked off. Added to end of schema to act as a unique indentifier
    **source_schema** : 'SQL schema'
        Schema to be used as template for the output schema
    **include_data** : 'bool'
        If True includes data from diffusion_shared schema. Default is False
    
    Returns
    -------
    dest_schema : 'SQL schema'
        Output schema that will house the final results
    """

    inputs = locals().copy()
    suffix = utilfunc.get_formatted_time()
    suffix_microsecond = datetime.now().strftime('%f')
    logger.info('Creating output schema based on {source_schema}'.format(**inputs))

    con, cur = utilfunc.make_con(pg_conn_string, role="postgres")

    # check that the source schema exists
    sql = """SELECT count(*)
            FROM pg_catalog.pg_namespace
            WHERE nspname = '{source_schema}';""".format(**inputs)
    check = pd.read_sql(sql, con)
    if check['count'][0] != 1:
        msg = "Specified source_schema ({source_schema}) does not exist.".format(**inputs)
        raise ValueError(msg)

#    scen_suffix = scenario_list[0].split('/')[2].split('_')[2].rstrip('.xlsm')
    scen_suffix = os.path.split(scenario_list[0])[1].split('_')[2].rstrip('.xlsm')
#    dest_schema = 'diffusion_results_%s' % suffix+suffix_microsecond+'_'+scen_suffix
    dest_schema = 'diffusion_results_{}'.format(suffix+suffix_microsecond+'_'+scen_suffix)
    inputs['dest_schema'] = dest_schema

    sql = '''SELECT diffusion_shared.clone_schema('{source_schema}', '{dest_schema}', '{role}', {include_data});'''.format(**inputs)
    cur.execute(sql)
    con.commit()

    # clear output results tables (this ensures that outputs are empty for each model run)
    clear_outputs(con, cur, dest_schema)

    logger.info('\tOutput schema is: {}'.format(dest_schema))

    return dest_schema


@decorators.fn_timer(logger=logger, tab_level=1, prefix='')
def drop_output_schema(pg_conn_string, schema, delete_output_schema):
    """
    Deletes output schema from database if set to true
    
    Parameters
    ----------
    **pg_conn_string** : 'string'
        String to connect to pgAdmin database
    **schema** : 'SQL schema'
        Schema that will be deleted
    **delete_output_schema** : 'bool'
        If set to True in config.py, deletes output schema
    
    """

    inputs = locals().copy()

    if delete_output_schema == True:
        logger.info('Dropping the Output Schema ({}) from Database'.format(schema))

        con, cur = utilfunc.make_con(pg_conn_string, role="postgres")
        sql = '''DROP SCHEMA IF EXISTS {schema} CASCADE;'''.format(**inputs)
        cur.execute(sql)
        con.commit()
    else:
        logger.warning(
            "The output schema  (%(schema)s) has not been deleted. Please delete manually when you are finished analyzing outputs." % inputs)


def clear_outputs(con, cur, schema):
    """
    Deletes all rows from the res, com, and ind output tables

    Parameters
    ----------    
    **con** : 'SQL connection'
        SQL connection to connect to database
    **cur** : 'SQL cursor'
        Cursor
    **schema** : 'SQL schema'
        Schema from which output tables will be deleted

    """

    # create a dictionary out of the input arguments -- this is used through
    # sql queries
    inputs = locals().copy()

    sql = """DELETE FROM {schema}.outputs_res;
            DELETE FROM {schema}.outputs_com;
            DELETE FROM {schema}.outputs_ind;
            DELETE FROM {schema}.cumulative_installed_capacity_solar;
            DELETE FROM {schema}.cumulative_installed_capacity_wind;
            DELETE FROM {schema}.yearly_technology_costs_solar;
            DELETE FROM {schema}.yearly_technology_costs_wind;
            """.format(**inputs)
    cur.execute(sql)
    con.commit()


@decorators.fn_timer(logger=logger, tab_level=2, prefix='')
def index_output_table(con, cur, schema):
    """
    Creates Indeces in output table based on year, state, sector, system size, payback period, and technology

    Parameters
    ----------    
    **con** : 'SQL connection'
        SQL connection to connect to database
    **cur** : 'SQL cursor'
        Cursor
    **schema** : 'SQL schema'
        Schema from which output tables exist

    """

    inputs = locals().copy()

    # create indices that will be needed for various aggregations in R visualization script

    #for f in ['year', 'state_abbr', 'sector', 'system_size_factors', 'metric', 'turbine_height_m', 'tech']:
    for f in ['year', 'state_abbr', 'sector', 'system_size_factors', 'metric', 'tech']:
        try:
            sql = '''CREATE INDEX agent_outputs_{0}_btree ON {1}.agent_outputs USING BTREE({2});
             '''.format((f,schema,f))
            cur.execute(sql)
            con.commit()
        except:
            print("Warning: Could not index {}".format(f))


#%%

def get_sectors(cur, schema):
    '''
    Return the sectors to model from table view in postgres.
        
    Parameters
    ----------    
    **cur** : 'SQL cursor'
        Cursor
    **schema** : 'SQL schema'
        Schema in which the sectors exist        

    Returns
    -------
    **sectors** : 'dict'
        Dictionary of sectors to be modeled in table view in postgres

    '''

    sql = '''SELECT sectors
              FROM {}.sectors_to_model;'''.format(schema)
    cur.execute(sql)
    sectors = cur.fetchone()['sectors']
    return sectors


def get_technologies(con, schema):

    sql = """SELECT 
                CASE WHEN run_tech = 'Solar + Storage' THEN 'solar'::text
                     WHEN run_tech = 'Wind' THEN 'wind'::text
                     WHEN run_tech = 'Geothermal Heat Pump' THEN 'ghp'::text
                     WHEN run_tech = 'Geothermal Direct Use' THEN 'du'::text
                END AS tech
            FROM {}.input_main_scenario_options;""".format(schema)

    # get the data
    df = pd.read_sql(sql, con)
    # convert to a simple list
    techs = df.tech.tolist()

    if len(techs) == 0:
        raise ValueError(
            "No technologies were selected to be run in the input sheet.")

    return techs



def get_agent_file_scenario(con, schema):

    sql = """SELECT agent_file as agent_file_status
            FROM {}.input_main_scenario_options;""".format(schema)

    # get the data
    df = pd.read_sql(sql, con)
    # convert to a simple list
    agent_file_status = df.agent_file_status.iloc[0]

    if agent_file_status is None:
        raise ValueError(
            "No pre-generated pkl agent file was provided to be run in the input sheet.")

    return agent_file_status


def cleanup_incentives(df, dsire_opts):

    # add in columns that may be missing
    for col in ['increment_4_capacity_kw', 'increment_4_rebate_dlrs_kw',
                'pbi_fit_max_size_for_dlrs_calc_kw', 'tax_credit_dlrs_kw',
                'pbi_fit_min_output_kwh_yr', 'increment_3_rebate_dlrs_kw',
                'increment_4_rebate_dlrs_kw']:
        if col not in df.columns:
            df[col] = np.nan

    # isolate the output columns
    out_cols = df.columns

    # merge the dsire options dataframe
    df = pd.merge(df, dsire_opts, how='left', on=['tech'])

    # fix data types for float columns (may come in as type 'O' due to all nulls)
    float_cols = ['increment_1_capacity_kw',
                  'increment_2_capacity_kw',
                  'increment_3_capacity_kw',
                  'increment_4_capacity_kw',
                  'increment_1_rebate_dlrs_kw',
                  'increment_2_rebate_dlrs_kw',
                  'increment_3_rebate_dlrs_kw',
                  'increment_4_rebate_dlrs_kw',
                  'pbi_fit_duration_years',
                  'pbi_fit_max_size_kw',
                  'pbi_fit_min_output_kwh_yr',
                  'pbi_fit_min_size_kw',
                  'pbi_dlrs_kwh',
                  'fit_dlrs_kwh',
                  'pbi_fit_max_dlrs',
                  'pbi_fit_pcnt_cost_max',
                  'ptc_duration_years',
                  'ptc_dlrs_kwh',
                  'max_dlrs_yr',
                  'rebate_dlrs_kw',
                  'rebate_max_dlrs',
                  'rebate_max_size_kw',
                  'rebate_min_size_kw',
                  'rebate_pcnt_cost_max',
                  'max_tax_credit_dlrs',
                  'max_tax_deduction_dlrs',
                  'tax_credit_pcnt_cost',
                  'tax_deduction_pcnt_cost',
                  'tax_credit_max_size_kw',
                  'tax_credit_min_size_kw']

    df.loc[:, float_cols] = df[float_cols].astype(float)

    # replace null values with defaults
    max_dlrs = 1e9
    dlrs_per_kwh = 0
    dlrs_per_kw = 0
    max_size_kw = 10000
    min_size_kw = 0
    min_output_kwh_yr = 0
    increment_incentive_kw = 0
    pcnt_cost_max = 100
    # percent cost max
    df.loc[:, 'rebate_pcnt_cost_max'] = df.rebate_pcnt_cost_max.fillna(
        pcnt_cost_max)
    # expiration date
    df.loc[:, 'ptc_end_date'] = df.ptc_end_date.astype(
        'O').fillna(df['dsire_default_exp_date'])
    df.loc[:, 'pbi_fit_end_date'] = df.pbi_fit_end_date.astype('O').fillna(
        df['dsire_default_exp_date'])  # Assign expiry if no date
    # max dollars
    df.loc[:, 'max_dlrs_yr'] = df.max_dlrs_yr.fillna(max_dlrs)
    df.loc[:, 'pbi_fit_max_dlrs'] = df.pbi_fit_max_dlrs.fillna(max_dlrs)
    df.loc[:, 'max_tax_credit_dlrs'] = df.max_tax_credit_dlrs.fillna(max_dlrs)
    df.loc[:, 'rebate_max_dlrs'] = df.rebate_max_dlrs.fillna(max_dlrs)
    # dollars per kwh
    df.loc[:, 'ptc_dlrs_kwh'] = df.ptc_dlrs_kwh.fillna(dlrs_per_kwh)
    # dollars per kw
    df.loc[:, 'rebate_dlrs_kw'] = df.rebate_dlrs_kw.fillna(dlrs_per_kw)
    # max size
    df.loc[:, 'tax_credit_max_size_kw'] = df.tax_credit_max_size_kw.fillna(
        max_size_kw)
    df.loc[:, 'pbi_fit_max_size_kw'] = df.pbi_fit_min_size_kw.fillna(
        max_size_kw)
    df.loc[:, 'rebate_max_size_kw'] = df.rebate_min_size_kw.fillna(max_size_kw)
    # min size
    df.loc[:, 'pbi_fit_min_size_kw'] = df.pbi_fit_min_size_kw.fillna(
        min_size_kw)
    df.loc[:, 'rebate_min_size_kw'] = df.rebate_min_size_kw.fillna(min_size_kw)
    # minimum output kwh
    df.loc[:, 'pbi_fit_min_output_kwh_yr'] = df[
        'pbi_fit_min_output_kwh_yr'].fillna(min_output_kwh_yr)
    # increment incentives
    increment_vars = ['increment_1_capacity_kw', 'increment_2_capacity_kw', 'increment_3_capacity_kw', 'increment_4_capacity_kw',
                      'increment_1_rebate_dlrs_kw', 'increment_2_rebate_dlrs_kw', 'increment_3_rebate_dlrs_kw', 'increment_4_rebate_dlrs_kw']
    df.loc[:, increment_vars] = df[
        increment_vars].fillna(increment_incentive_kw)

    return df[out_cols]


def get_dsire_settings(con, schema):

    inputs = locals().copy()

    sql = """SELECT * FROM {schema}.input_main_dsire_incentive_options;""".format(**inputs)

    dsire_opts = pd.read_sql(sql, con, coerce_float=True)

    return dsire_opts


def get_incentives_cap(con, schema):

    inputs = locals().copy()

    sql = """SELECT * FROM {schema}.input_main_incentives_cap;""".format(**inputs)

    incentives_cap = pd.read_sql(sql, con, coerce_float=True)

    return incentives_cap


def get_bass_params(con, schema):

    inputs = locals().copy()

    sql = """SELECT state_abbr,
                    p,
                    q,
                    teq_yr1,
                    sector_abbr,
                    tech
             FROM {schema}.input_solar_bass_params

             UNION ALL

             SELECT state_abbr,
                    p,
                    q,
                    teq_yr1,
                    sector_abbr,
                    tech
             FROM {schema}.input_wind_bass_params

             UNION ALL

             SELECT state_abbr,
                    p,
                    q,
                    teq_yr1,
                    sector_abbr,
                    tech
             FROM {schema}.input_ghp_bass_params;""".format(**inputs)

    bass_df = pd.read_sql(sql, con, coerce_float=True)
    bass_df.rename(columns={'p':'bass_param_p',
                            'q':'bass_param_q'}, inplace=True)

    return bass_df


def get_state_incentives(con):

    sql = """SELECT * FROM diffusion_shared.state_incentives_2017;"""

    state_incentives = pd.read_sql(sql, con)

    return state_incentives


def get_itc_incentives(con, schema):

    inputs = locals().copy()

    sql = """SELECT year, substring(lower(sector), 1, 3) as sector_abbr,
                    itc_fraction, tech, min_size_kw, max_size_kw
             FROM {schema}.input_main_itc_options;""".format(**inputs)
    itc_options = pd.read_sql(sql, con)
    itc_options.rename(columns={'itc_fraction':'itc_fraction_of_capex'}, inplace=True)

    return itc_options


def get_dsire_incentives(cur, con, schema, techs, sectors, pg_conn_string, dsire_opts):
    # create a dictionary out of the input arguments -- this is used through sql queries
    inputs = locals().copy()

    if 'solar' in techs:
        sql = """SELECT c.*, 'solar'::TEXT as tech
                    FROM diffusion_solar.incentives c;"""
    else:
        sql = """SELECT c.*, 'solar'::TEXT as tech
                    FROM diffusion_solar.incentives c
                    LIMIT 0;"""

    # get the data
    df = pd.read_sql(sql, con, coerce_float=True)
    # clean it up
    df = cleanup_incentives(df, dsire_opts)

    return df


def get_state_dsire_incentives(cur, con, schema, techs, dsire_opts):

    # create a dictionary out of the input arguments -- this is used through sql queries
    inputs = locals().copy()

    sql_list = []
    for tech in techs:
        inputs['tech'] = tech
        sql =   """SELECT *
                   FROM diffusion_{tech}.state_dsire_incentives
                """.format(inputs)
        sql_list.append(sql)

    sql = ' UNION ALL '.join(sql_list)
    # get the data
    df = pd.read_sql(sql, con, coerce_float=True)

    # isolate the output columns
    out_cols = df.columns

    # fill in expiration dates with default from input sheet if missing merge dsire opts
    df = pd.merge(df, dsire_opts, how='left', on=['tech'])
    # fill in missing values
    df.loc[:, 'exp_date'] = df.exp_date.astype(
        'O').fillna(df['dsire_default_exp_date'])

    # convert exp_date to datetime
    df['exp_date'] = pd.to_datetime(df['exp_date'])

    return df[out_cols]

def calc_state_dsire_incentives(df, state_dsire_df, year):

    # convert current year into a datetime object (assume current date is the
    # first day of the 2 year period ending in YEAR)
    df['cur_date'] = pd.to_datetime((df['year'] - 2).apply(str))

    # calculate installed costs
    df['ic'] = df['installed_costs_dollars_per_kw'] * df['system_size_kw']

    # join data frames
    inc = pd.merge(df, state_dsire_df, how='left', on=[
                   'state_abbr', 'sector_abbr', 'tech'])

    # drop rows that don't fit within the correct ranges for system size
    inc = inc[(inc['system_size_kw'] >= inc['min_size_kw']) &
              (inc['system_size_kw'] < inc['max_size_kw'])]
    # drop rows that don't fit within correct aep range
    inc = inc[(inc['aep'] >= inc['min_aep_kwh']) &
              (inc['aep'] < inc['max_aep_kwh'])]
    # drop rows that don't fit within the correct date
    inc = inc[inc['cur_date'] <= inc['exp_date']]

    # calculate ITC
    inc['value_of_itc'] = 0.0
    inc.loc[inc['incentive_type'] == 'ITC',
            'value_of_itc'] = np.minimum( inc['val_pct_cost'] * inc['ic'] *
            (inc['system_size_kw'] >= inc['min_size_kw']) *
            (inc['system_size_kw'] < inc['max_size_kw']) *
            (inc['cur_date'] <= inc['exp_date']),

            inc['cap_dlrs']
    )

    # calculate PTC
    inc['value_of_ptc'] = 0.0
    inc.loc[inc['incentive_type'] == 'PTC',
            'value_of_ptc'] = np.minimum(
        inc['dlrs_per_kwh'] * inc['aep'] *
        (inc['system_size_kw'] >= inc['min_size_kw']) *
        (inc['system_size_kw'] < inc['max_size_kw']) *
        (inc['aep'] >= inc['min_aep_kwh']) *
        (inc['aep'] < inc['max_aep_kwh']) *
        (inc['cur_date'] <= inc['exp_date']),

        np.minimum(
            inc['cap_dlrs'],
            inc['cap_pct_cost'] * inc['ic']
        )
    )
    inc['ptc_length'] = 0.0
    inc.loc[inc['incentive_type'] == 'PTC',
            'ptc_length'] = inc['duration_years']

    # calculate capacity based rebates
    inc['value_of_cap_rebate'] = 0.0
    inc.loc[inc['incentive_type'] == 'capacity_based_rebate',
            'value_of_cap_rebate'] = np.minimum(
        (inc['dlrs_per_kw'] * (inc['system_size_kw'] - inc['fixed_kw']) + inc['fixed_dlrs']) *
        (inc['system_size_kw'] >= inc['min_size_kw']) *
        (inc['system_size_kw'] < inc['max_size_kw']) *
        (inc['cur_date'] <=
         inc['exp_date']),
        np.minimum(
            inc['cap_dlrs'],
            inc['cap_pct_cost'] * inc['ic']
        )
    )
    # calculate production based rebates
    inc['value_of_prod_rebate'] = 0.0
    inc.loc[inc['incentive_type'] == 'production_based_rebate',
            'value_of_prod_rebate'] = np.minimum(
                                                (inc['dlrs_per_kwh'] * (inc['aep'] - inc['fixed_kwh']) + inc['fixed_dlrs']) *
                                                (inc['system_size_kw'] >= inc['min_size_kw']) *
                                                (inc['system_size_kw'] < inc['max_size_kw']) *
                                                (inc['aep'] >= inc['min_aep_kwh']) *
                                                (inc['aep'] < inc['max_aep_kwh']) *
                                                (inc['cur_date'] <=
                                                 inc['exp_date']),
        np.minimum(
                                                    inc['cap_dlrs'],
                                                    inc['cap_pct_cost'] *
                                                    inc['ic']
                                                )
    )

    # calculate FIT
    inc['value_of_pbi_fit'] = 0.0
    inc.loc[inc['incentive_type'] == 'PBI',
            'value_of_pbi_fit'] = np.minimum(
        np.minimum(
            inc['dlrs_per_kwh'] * inc['aep'] + inc['fixed_dlrs'],
            inc['cap_dlrs_yr']
        ) *
        (inc['system_size_kw'] >= inc['min_size_kw']) *
        (inc['system_size_kw'] < inc['max_size_kw']) *
        (inc['aep'] >= inc['min_aep_kwh']) *
        (inc['aep'] < inc['max_aep_kwh']) *
        (inc['cur_date'] <=
         inc['exp_date']),
        inc['cap_pct_cost'] * inc['ic']
    )
    inc['pbi_fit_length'] = 0.0
    inc.loc[inc['incentive_type'] == 'PBI',
            'pbi_fit_length'] = inc['duration_years']

    # calculate ITD
    inc['value_of_itd'] = 0.0
    inc.loc[inc['incentive_type'] == 'ITD',
            'value_of_itd'] = np.minimum(
        inc['val_pct_cost'] * inc['ic'] *
        (inc['system_size_kw'] >= inc['min_size_kw']) *
        (inc['system_size_kw'] < inc['max_size_kw']) *
        (inc['cur_date'] <=
         inc['exp_date']),
        inc['cap_dlrs']
    )

    # combine tax credits and deductions
    inc['value_of_tax_credit_or_deduction'] = inc[
        'value_of_itc'] + inc['value_of_itc']
    # combine cap and prod rebates
    inc['value_of_rebate'] = inc['value_of_cap_rebate'] + \
        inc['value_of_prod_rebate']
    # add "value of increment" for backwards compatbility with old dsire and
    # manual incentives (note: this is already built into rebates)
    inc['value_of_increment'] = 0.0

    # sum results to customer bins
    out_cols = ['tech',
                'sector_abbr',
                'county_id',
                'bin_id',
                'business_model',
                'value_of_increment',
                'value_of_pbi_fit',
                'value_of_ptc',
                'pbi_fit_length',
                'ptc_length',
                'value_of_rebate',
                'value_of_tax_credit_or_deduction']
    sum_cols = ['value_of_increment',
                'value_of_pbi_fit',
                'value_of_ptc',
                'value_of_rebate',
                'value_of_tax_credit_or_deduction']
    max_cols = ['pbi_fit_length',
                'ptc_length']  # there should never be multiples of either of these, so taking the max is the correct choice
    group_cols = ['tech',
                  'sector_abbr',
                  'county_id',
                  'bin_id',
                  'business_model']
    if inc.shape[0] > 0:
        inc_summed = inc[group_cols +
                         sum_cols].groupby(group_cols).sum().reset_index()
        inc_max = inc[group_cols +
                      max_cols].groupby(group_cols).max().reset_index()
        inc_combined = pd.merge(inc_summed, inc_max, how='left', on=group_cols)
    else:
        inc_combined = inc[out_cols]

    return inc_combined[out_cols]


def get_srecs(cur, con, schema, techs, pg_conn_string, dsire_opts):
    # create a dictionary out of the input arguments -- this is used through sql queries
    inputs = locals().copy()

    sql_list = []
    for tech in techs:
        inputs['tech'] = tech
        sql =   """SELECT *, '{tech}'::TEXT as tech
                    FROM diffusion_{tech}.srecs
                """.format(**inputs)
        sql_list.append(sql)

    sql = ' UNION ALL '.join(sql_list)
    # get the data
    df = pd.read_sql(sql, con, coerce_float=True)
    # clean it up
    df = cleanup_incentives(df, dsire_opts)

    return df


def get_max_market_share(con, schema):
    ''' Pull max market share from dB, select curve based on scenario_options, and interpolate to tenth of a year.
        Use passed parameters to determine ownership type

        IN: con - pg con object - connection object
            schema - string - schema for technology i.e. diffusion_solar


        OUT: max_market_share  - pd dataframe - dataframe to join on main df to determine max share
                                                keys are sector & payback period
    '''

    sql = '''SELECT metric_value,
                    sector_abbr,
                    max_market_share,
                    metric,
                    source,
                    business_model
             FROM {0}.max_market_curves_to_model

             UNION ALL

            SELECT 30.1 as metric_value,
                    sector_abbr,
                    0::NUMERIC as max_market_share,
                    metric,
                    source,
                    business_model
            FROM {1}.max_market_curves_to_model
            WHERE metric_value = 30
            AND metric = 'payback_period'
            AND business_model = 'host_owned';'''.format(schema, schema)
    max_market_share = pd.read_sql(sql, con)
    max_market_share.rename(columns={'metric_value':'payback_period'}, inplace=True)

    return max_market_share


def get_market_projections(con, schema):
    ''' Pull market projections table from dB

        IN: con - pg con object - connection object
        OUT: market_projections - numpy array - table containing various market projections
    '''
    sql = '''SELECT *
             FROM {}.input_main_market_projections;'''.format(schema)
    return pd.read_sql(sql, con)


def calc_dsire_incentives(df, dsire_incentives, srecs, cur_year, dsire_opts, assumed_duration=10):
    '''
    Calculate the value of incentives based on DSIRE database. There may be many incentives per each customer bin (county_id+bin_id),
    so the value is calculated for each row (incentives)
    and then groupedby county_id & bin_id, summing over incentives value. For multiyear incentives (ptc/pbi/fit), this requires
    assumption that incentives are disbursed over 10 years.

    IN: inc - pandas dataframe (df) - main df joined by dsire_incentives
        cur_year - scalar - current model year
        default_exp_yr - scalar - assumed expiry year if none given
        assumed duration - scalar - assumed duration of multiyear incentives if none given
    OUT: value_of_incentives - pandas df - Values of incentives by type. For
                                        mutiyear incentves, the (undiscounted) lifetime value is given
    '''

    dsire_df = pd.merge(df, dsire_incentives, how='left', on=[
                        'state_abbr', 'sector_abbr', 'tech'])
    srecs_df = pd.merge(df, srecs, how='left', on=[
                        'state_abbr', 'sector_abbr', 'tech'])

    # combine sr and inc
    inc = pd.concat([dsire_df, srecs_df], axis=0, ignore_index=True, sort=False)
    # merge dsire opts
    inc = pd.merge(inc, dsire_opts, how='left', on='tech')

    # Shorten names
    inc['ic'] = inc['installed_costs_dollars_per_kw'] * inc['system_size_kw']

    cur_date = np.array([datetime.date(cur_year, 1, 1)] * len(inc))

    # 1. # Calculate Value of Increment Incentive
    # The amount of capacity that qualifies for the increment
    inc['cap_1'] = np.minimum(
        inc.increment_1_capacity_kw, inc['system_size_kw'])
    inc['cap_2'] = np.maximum(
        inc['system_size_kw'] - inc.increment_1_capacity_kw, 0)
    inc['cap_3'] = np.maximum(
        inc['system_size_kw'] - inc.increment_2_capacity_kw, 0)
    inc['cap_4'] = np.maximum(
        inc['system_size_kw'] - inc.increment_3_capacity_kw, 0)

    inc['est_value_of_increment'] = inc['cap_1'] * inc.increment_1_rebate_dlrs_kw + inc['cap_2'] * \
        inc.increment_2_rebate_dlrs_kw + \
        inc['cap_3'] * inc.increment_3_rebate_dlrs_kw + \
        inc['cap_4'] * inc.increment_4_rebate_dlrs_kw
    inc.loc[:, 'est_value_of_increment'] = inc[
        'est_value_of_increment'].fillna(0)
    inc['value_of_increment'] = np.minimum(inc['est_value_of_increment'], 0.2 * inc[
                                           'installed_costs_dollars_per_kw'] * inc['system_size_kw'])

    # 2. # Calculate lifetime value of PBI & FIT
    # Is the incentive still valid
    inc['pbi_fit_still_exists'] = cur_date <= inc.pbi_fit_end_date
    # suppress errors where pbi_fit_min or max _size_kw is nan -- this will
    # only occur for rows with no incentives
    with np.errstate(invalid='ignore'):
        inc['pbi_fit_cap'] = np.where(
            inc['system_size_kw'] < inc.pbi_fit_min_size_kw, 0, inc['system_size_kw'])
        inc.loc[:, 'pbi_fit_cap'] = np.where(
            inc['pbi_fit_cap'] > inc.pbi_fit_max_size_kw, inc.pbi_fit_max_size_kw, inc['pbi_fit_cap'])
    inc['pbi_fit_aep'] = np.where(
        inc['aep'] < inc.pbi_fit_min_output_kwh_yr, 0, inc['aep'])

    # If exists pbi_fit_kwh > 0 but no duration, assume duration
    inc.loc[(inc.pbi_fit_dlrs_kwh > 0) & inc.pbi_fit_duration_years.isnull(
    ), 'pbi_fit_duration_years'] = assumed_duration
    inc['value_of_pbi_fit'] = (inc['pbi_fit_still_exists'] * np.minimum(
        inc.pbi_fit_dlrs_kwh, inc.max_dlrs_yr) * inc['pbi_fit_aep']).astype('float64')
    inc.loc[:, 'value_of_pbi_fit'] = np.minimum(
        inc['value_of_pbi_fit'], inc.pbi_fit_max_dlrs)
    inc.loc[:, 'value_of_pbi_fit'] = inc.value_of_pbi_fit.fillna(0)
    inc['length_of_pbi_fit'] = inc.pbi_fit_duration_years.fillna(0)

    # 3. # Lifetime value of the pbi/fit. Assume all pbi/fits are disbursed over 10 years.
    # This will get the undiscounted sum of incentive correct, present value
    # may have small error
    inc['lifetime_value_of_pbi_fit'] = inc[
        'length_of_pbi_fit'] * inc['value_of_pbi_fit']

    # Calculate first year value and length of PTC
    # Is the incentive still valid
    inc['ptc_still_exists'] = cur_date <= inc.ptc_end_date
    inc['ptc_max_size'] = np.minimum(
        inc['system_size_kw'], inc.tax_credit_max_size_kw)
    inc.loc[(inc.ptc_dlrs_kwh > 0) & (inc.ptc_duration_years.isnull()),
            'ptc_duration_years'] = assumed_duration
    with np.errstate(invalid='ignore'):
        inc['value_of_ptc'] = np.where(inc['ptc_still_exists'] & inc.system_size_kw > 0, np.minimum(
            inc.ptc_dlrs_kwh * inc.aep * (inc['ptc_max_size'] / inc.system_size_kw), inc.max_dlrs_yr), 0)
    inc.loc[:, 'value_of_ptc'] = inc.value_of_ptc.fillna(0)
    inc.loc[:, 'value_of_ptc'] = np.where(inc['value_of_ptc'] < inc.max_tax_credit_dlrs, inc[
                                          'value_of_ptc'], inc.max_tax_credit_dlrs)
    inc['length_of_ptc'] = inc.ptc_duration_years.fillna(0)

    # Lifetime value of the ptc. Assume all ptcs are disbursed over 10 years
    # This will get the undiscounted sum of incentive correct, present value
    # may have small error
    inc['lifetime_value_of_ptc'] = inc['length_of_ptc'] * inc['value_of_ptc']

    # 4. #Calculate Value of Rebate
    inc['rebate_cap'] = np.where(
        inc['system_size_kw'] < inc.rebate_min_size_kw, 0, inc['system_size_kw'])
    inc.loc[:, 'rebate_cap'] = np.where(
        inc['rebate_cap'] > inc.rebate_max_size_kw, inc.rebate_max_size_kw, inc['rebate_cap'])
    inc['value_of_rebate'] = inc.rebate_dlrs_kw * inc['rebate_cap']
    inc.loc[:, 'value_of_rebate'] = np.minimum(
        inc.rebate_max_dlrs, inc['value_of_rebate'])
    inc.loc[:, 'value_of_rebate'] = np.minimum(
        inc.rebate_pcnt_cost_max * inc['ic'], inc['value_of_rebate'])
    inc.loc[:, 'value_of_rebate'] = inc.value_of_rebate.fillna(0)
    # overwrite these values with zero where the incentive has expired
    inc.loc[:, 'value_of_rebate'] = np.where(np.array(datetime.date(cur_year, 1, 1)) >= np.array(
        inc['dsire_default_exp_date']), 0.0, inc['value_of_rebate'])

    # 5. # Calculate Value of Tax Credit
    # Assume able to fully monetize tax credits

    # check whether the credits are still active (this can be applied universally because DSIRE does not provide specific info
    # about expirations for each tax credit or deduction).
    # Assume that expiration date is inclusive e.g. consumer receives
    # incentive in 2016 if expiration date of 2016 (or greater)
    inc.loc[inc.tax_credit_pcnt_cost.isnull(), 'tax_credit_pcnt_cost'] = 0
    inc.loc[inc.tax_credit_pcnt_cost >= 1,
            'tax_credit_pcnt_cost'] = 0.01 * inc.tax_credit_pcnt_cost
    inc.loc[inc.tax_deduction_pcnt_cost.isnull(), 'tax_deduction_pcnt_cost'] = 0
    inc.loc[inc.tax_deduction_pcnt_cost >= 1,
            'tax_deduction_pcnt_cost'] = 0.01 * inc.tax_deduction_pcnt_cost
    inc['tax_pcnt_cost'] = inc.tax_credit_pcnt_cost + \
        inc.tax_deduction_pcnt_cost

    inc.max_tax_credit_dlrs = np.where(
        inc.max_tax_credit_dlrs.isnull(), 1e9, inc.max_tax_credit_dlrs)
    inc.max_tax_deduction_dlrs = np.where(
        inc.max_tax_deduction_dlrs.isnull(), 1e9, inc.max_tax_deduction_dlrs)
    inc['max_tax_credit_or_deduction_value'] = np.maximum(
        inc.max_tax_credit_dlrs, inc.max_tax_deduction_dlrs)

    inc['tax_credit_dlrs_kw'] = inc['tax_credit_dlrs_kw'].fillna(0)

    inc['value_of_tax_credit_or_deduction'] = inc['tax_pcnt_cost'] * \
        inc['ic'] + inc['tax_credit_dlrs_kw'] * inc['system_size_kw']
    inc.loc[:, 'value_of_tax_credit_or_deduction'] = np.minimum(
        inc['max_tax_credit_or_deduction_value'], inc['value_of_tax_credit_or_deduction'])
    inc.loc[:, 'value_of_tax_credit_or_deduction'] = np.where(inc.tax_credit_max_size_kw < inc['system_size_kw'], inc[
                                                              'tax_pcnt_cost'] * inc.tax_credit_max_size_kw * inc.installed_costs_dollars_per_kw, inc['value_of_tax_credit_or_deduction'])
    inc.loc[:, 'value_of_tax_credit_or_deduction'] = pd.Series(
        inc['value_of_tax_credit_or_deduction']).fillna(0)
    #value_of_tax_credit_or_deduction[np.isnan(value_of_tax_credit_or_deduction)] = 0
    inc.loc[:, 'value_of_tax_credit_or_deduction'] = inc[
        'value_of_tax_credit_or_deduction'].astype(float)
    # overwrite these values with zero where the incentive has expired
    inc.loc[:, 'value_of_tax_credit_or_deduction'] = np.where(np.array(datetime.date(cur_year, 1, 1)) >= np.array(
        inc['dsire_default_exp_date']), 0.0, inc['value_of_tax_credit_or_deduction'])

    # sum results to customer bins
    if inc.shape[0] > 0:
        inc_summed = inc[['tech', 'sector_abbr', 'county_id', 'bin_id', 'business_model', 'value_of_increment', 'lifetime_value_of_pbi_fit', 'lifetime_value_of_ptc',
                          'value_of_rebate', 'value_of_tax_credit_or_deduction']].groupby(['tech', 'sector_abbr', 'county_id', 'bin_id', 'business_model']).sum().reset_index()
    else:
        inc_summed = inc[['tech', 'sector_abbr', 'county_id', 'bin_id', 'business_model', 'value_of_increment',
                          'lifetime_value_of_pbi_fit', 'lifetime_value_of_ptc', 'value_of_rebate', 'value_of_tax_credit_or_deduction']]

    inc_summed.loc[:, 'value_of_pbi_fit'] = inc_summed[
        'lifetime_value_of_pbi_fit'] / assumed_duration
    inc_summed['pbi_fit_length'] = assumed_duration

    inc_summed.loc[:, 'value_of_ptc'] = inc_summed[
        'lifetime_value_of_ptc'] / assumed_duration
    inc_summed['ptc_length'] = assumed_duration

    return inc_summed[['tech', 'sector_abbr', 'county_id', 'bin_id', 'business_model', 'value_of_increment', 'value_of_pbi_fit', 'value_of_ptc', 'pbi_fit_length', 'ptc_length', 'value_of_rebate', 'value_of_tax_credit_or_deduction']]


def get_rate_escalations(con, schema):
    '''
    Get rate escalation multipliers from database. Escalations are filtered and applied in calc_economics,
    resulting in an average real compounding rate growth. This rate is then used to calculate cash flows
    
    IN: con - connection to server
    OUT: DataFrame with county_id, sector, year, escalation_factor, and source as columns
    '''  
    inputs = locals().copy()
    
    sql = """SELECT year, county_id, sector_abbr, nerc_region_abbr,
                    escalation_factor as elec_price_multiplier
            FROM {schema}.rate_escalations_to_model
            ORDER BY year, county_id, sector_abbr""".format(**inputs)
    rate_escalations = pd.read_sql(sql, con, coerce_float = False)
    
    return rate_escalations


def get_load_growth(con, schema):

    inputs = locals().copy()

    sql = """SELECT year, county_id, sector_abbr, nerc_region_abbr, load_multiplier
            FROM {schema}.load_growth_to_model;""".format(**inputs)

    df = pd.read_sql(sql, con, coerce_float=False)

    return df


def get_technology_costs_solar(con, schema):
    
    inputs = locals().copy()
    
    sql = """SELECT year,
                    sector_abbr,
                    system_capex_per_kw,
                    system_om_per_kw,
                    system_variable_om_per_kw
            FROM {schema}.input_pv_prices_to_model;""".format(inputs)
    df = pd.read_sql(sql, con, coerce_float = False)

    return df


def get_storage_costs(con, schema):

    inputs = locals().copy()

    sql = """SELECT year,
                    sector_abbr,
                    batt_capex_per_kwh,
                    batt_capex_per_kw,
                    batt_om_per_kwh,
                    batt_om_per_kw,
                    batt_replace_frac_kwh,
                    batt_replace_frac_kw
            FROM {schema}.input_storage_cost_projections_to_model;""".format(**inputs)
    df = pd.read_sql(sql, con, coerce_float = False)

    return df  


def get_wholesale_electricity_prices(con, schema):

    inputs = locals().copy()

    sql = """SELECT year,
                    state_abbr,
                    wholesale_elec_price_cents_per_kwh
            FROM {schema}.input_wholesale_electricity_prices_to_model;""".format(**inputs)
    df = pd.read_sql(sql, con, coerce_float = False)

    return df

    
def get_annual_inflation(con, schema):
    '''
    Get inflation rate (constant for all years & sectors)

    IN: con - connection to server, schema
    OUT: Float value of inflation rate
    '''
    inputs = locals().copy()
    sql = '''SELECT *
             FROM {schema}.input_main_market_inflation;'''.format(**inputs)
    df = pd.read_sql(sql, con)
    df.rename(columns={'inflation':'inflation_rate'}, inplace=True)
    return df.values[0][0]  # Just want the inflation as a float (for now)


def fill_jagged_array(vals, lens, cols):
    '''
    Create a 'jagged' array filling each row with a value of variable length.
    vals and lens must be equal length; cols gives the number of columns of the
    output ndarray

    IN:
        vals - np array containing values to fill
        lens - np array containing lengths of values to fill
        cols - integer of number of columns in output array

    OUT:

        jagged numpy array
    '''

    rows = vals.shape[0]
    # create a 1d array of zeros, same size as array b
    z = np.zeros((rows,), dtype=int)

    # combine a and b within a 1d array in an alternating manner
    az = np.vstack((vals, z)).ravel(1)
    # calculate the number of repeats necessary for the zeros, then combine
    # with b in a 1d array in an alternating manner
    bz = np.vstack((lens, cols - lens)).ravel(1)
    # use the repeate function to repeate elements in az by the factors in bz,
    # then reshape to the final array size and shape
    r = np.repeat(az, bz).reshape((rows, cols))
    return r


def calc_value_of_itc(df, itc_options, year):

    # create duplicates of the itc data for each business model
    # host-owend
    itc_ho = itc_options.copy()
    # set the business model
    itc_ho['business_model'] = 'host_owned'

    # tpo
    itc_tpo_nonres = itc_options[itc_options['sector_abbr'] != 'res'].copy()
    itc_tpo_res = itc_options[itc_options['sector_abbr'] == 'com'].copy()
    # reset the sector_abbr to res
    itc_tpo_res.loc[:, 'sector_abbr'] = 'res'
    # combine the data
    itc_tpo = pd.concat([itc_tpo_nonres, itc_tpo_res], axis=0, ignore_index=True, sort=False)
    # set the business model
    itc_tpo['business_model'] = 'tpo'

    # concatente the business models
    itc_all = pd.concat([itc_ho, itc_tpo], axis=0, ignore_index=True, sort=False)

    row_count = df.shape[0]
    # merge to df
    df = pd.merge(df, itc_all, how='left', on=['sector_abbr', 'year', 'business_model', 'tech'])
    # drop the rows that are outside of the allowable system sizes
    df = df[(df['system_size_kw'] > df['min_size_kw']) &
            (df['system_size_kw'] <= df['max_size_kw'])]
    # confirm shape hasn't changed
    if df.shape[0] != row_count:
        raise ValueError('Row count of dataframe changed during merge')

#    # Calculate the value of ITC (accounting for reduced costs from state/local incentives)
    df['applicable_ic'] = (df['installed_costs_dollars_per_kw'] * df['system_size_kw']) - (
        df['value_of_tax_credit_or_deduction'] + df['value_of_rebate'] + df['value_of_increment'])
    df['value_of_itc'] = (
        df['applicable_ic'] *
        df['itc_fraction_of_capex'] *
        # filter for system sizes (only applies to wind) [ this is redundant
        # with the filter above ]
        (df['system_size_kw'] > df['min_size_kw']) *
        (df['system_size_kw'] <= df['max_size_kw'])
    )

    df = df.drop(['applicable_ic', 'itc_fraction_of_capex'], axis=1)

    return df


#%%
#%%
def make_output_directory_path(suffix):

    out_dir = '{}/runs/results_{}'.format(os.path.dirname(os.getcwd()), suffix)

    return out_dir


def get_input_scenarios():

    scenarios = [s for s in glob.glob(
        "../input_scenarios/*.xls*") if not '~$' in s]

    return scenarios


def create_model_years(start_year, end_year, increment=2):

    model_years = list(range(start_year, end_year + 1, increment))

    return model_years


def summarize_scenario(scenario_settings, model_settings):

    # summarize high level secenario settings
    logger.info('Scenario Settings:')   
    logger.info('\tScenario Name: {}'.format(scenario_settings.scen_name))
    logger.info('\tRegion: {}'.format(scenario_settings.region))
    logger.info('\tSectors: {}'.format(list(scenario_settings.sectors.values())))
    logger.info('\tTechnologies: {}'.format(scenario_settings.techs))
    logger.info('\tYears: {0} - {1}'.format(model_settings.start_year, scenario_settings.end_year))

    return

#%%


@decorators.fn_timer(logger=logger, tab_level=2, prefix='')
#%%


def get_canned_agents(tech_mode, region, agents_type):
    # get the agents from canned agents
    in_agents = './canned_agents/{0}/agents_{1}.pkl'.format(tech_mode, agents_type)
    agents = unpickle(in_agents)

    # check that scenario region matches canned agent region
    in_region = './canned_agents/{}/region.pkl'.format(tech_mode)
    agents_region = unpickle(in_region)
    if agents_region != region:
        raise ValueError(
            'Region set in scenario inputs does not match region of canned agents. Change input region to {}'.format(agents_region))

    return agents


def unpickle(in_file):

    # confirm that file exists
    if os.path.exists(in_file) == True:
        pkl = open(in_file, 'rb')
        obj = pickle.load(pkl)
        pkl.close()
    else:
        raise ValueError(
            "{} does not exist. Change 'mode' in config.py to 'setup_develop' and re-run to create this file.".format(in_file))

    return obj


def store_pickle(out_obj, out_file):

    # pickle the rates df
    pkl = open(out_file, 'wb')
    pickle.dump(out_obj, pkl)
    pkl.close()



def get_scenario_options(cur, schema, pg_params):
    ''' Pull scenario options and log the user running the scenario from dB
    '''
    inputs = locals().copy()
    inputs['user'] = str(pg_params.get("user"))

    # log username to identify the user running the particular scenario
    sql = '''ALTER TABLE {schema}.input_main_scenario_options ADD COLUMN scenario_user text;
            UPDATE {schema}.input_main_scenario_options SET scenario_user = '{user}' WHERE scenario_name IS NOT NULL'''.format(**inputs)
    cur.execute(sql)

    sql = '''SELECT *
             FROM {schema}.input_main_scenario_options;'''.format(**inputs)
    cur.execute(sql)

    results = cur.fetchall()[0]
    return results

#%%
def get_nem_state(con, schema):
    sql = "SELECT *, 'BAU'::text as scenario FROM diffusion_shared.nem_state_limits_2019;"
    df = pd.read_sql(sql, con, coerce_float=False)
    
    return df

def get_nem_state_by_sector(con, schema):
    sql = "SELECT *, 'BAU'::text as scenario FROM diffusion_shared.nem_scenario_bau_2019;"
    df = pd.read_sql(sql, con, coerce_float=False)
    
    # special handling of DC: we don't know system size until bill calculator and differing compensation styles will
    # potentially result in different optimal system sizes. Here we assume only res customers (assumed system_size_kw < 100)
    # are eligible for full retail net metering; com/ind (assumed system_size_kw >= 100) only eligible for net billing.
    df = df[~((df['state_abbr'] == 'DC') & (df['sector_abbr'] == 'res') & (df['compensation_style'] == 'net billing'))]
    df = df[~((df['state_abbr'] == 'DC') & (df['sector_abbr'] != 'res') & (df['compensation_style'] == 'net metering'))]
    df['min_pv_kw_limit'] = np.where(((df['state_abbr'] == 'DC') & (df['sector_abbr'] != 'res')), 0., df['min_pv_kw_limit'])
    
    df.rename(columns={'max_pv_kw_limit':'nem_system_kw_limit'}, inplace=True)

    return df

def get_nem_utility_by_sector(con, schema):
    sql = "SELECT *, 'BAU'::text as scenario FROM diffusion_shared.nem_scenario_bau_by_utility_2019;"
    df = pd.read_sql(sql, con, coerce_float=False)
    
    df.rename(columns={'max_pv_kw_limit':'nem_system_kw_limit'}, inplace=True)

    return df

def get_selected_scenario(con, schema):
    sql = "SELECT * FROM {}.input_main_nem_selected_scenario;".format(schema)
    df = pd.read_sql(sql, con, coerce_float=False)
    value = df['val'][0]

    return value

