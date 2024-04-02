"""
Functions for pulling data
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


def create_tech_subfolders(out_scen_path, techs, out_subfolders):
    """
    Creates subfolders for results of each specified technology
    
    Parameters
    ----------
    out_scen_path : 'directory'
        Path for the scenario folder to send results
    techs : 'string'
        Technology type 
    out_subfolders : 'dict'
        Dictionary of empty subfolder paths for solar

    Returns
    -------
    out_subfolders : 'dict'
        Dictionary with subfolder paths for solar

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
    input_scenario : 'directory'
        Scenario inputs pulled from excel file within diffusion/inputs_scenarios folder
    scen_name : 'string'
        Scenario Name 
    scenario_names : 'list'
        List of scenario names
    out_dir : 'directory'
        Output directory for scenario subfolders
    dup_n : 'int'
        Number to track duplicate scenarios in scenario_names. Default is 0 unless otherwise specified.
    
    Returns
    -------
    out_scen_path : 'directory'
        Path for the scenario subfolders to send results
    scenario_names
        Populated list of scenario names
    dup_n : 'int'
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
def create_output_schema(pg_conn_string, role, suffix, scenario_list, source_schema='diffusion_template', include_data=True):
    """
    Creates output schema that will be dropped into the database
    
    Parameters
    ----------
    pg_conn_string : 'string'
        String to connect to pgAdmin database
    role : 'string'
        Owner of schema 
    suffix : 'string'
        String to mark the time that model is kicked off. Added to end of schema to act as a unique indentifier
    source_schema : 'SQL schema'
        Schema to be used as template for the output schema
    include_data : 'bool'
        If True includes data from diffusion_shared schema. Default is False
    
    Returns
    -------
    dest_schema : 'SQL schema'
        Output schema that will house the final results
    """

    inputs = locals().copy()
    logger.info('Creating output schema based on {source_schema}'.format(**inputs))

    con, cur = utilfunc.make_con(pg_conn_string, role)

    # check that the source schema exists
    sql = """SELECT count(*)
            FROM pg_catalog.pg_namespace
            WHERE nspname = '{source_schema}';""".format(**inputs)
    check = pd.read_sql(sql, con)
    if check['count'][0] != 1:
        msg = "Specified source_schema ({source_schema}) does not exist.".format(**inputs)
        raise ValueError(msg)

    scen_suffix = os.path.split(scenario_list[0])[1].split('_')[2].rstrip('.xlsm')

    dest_schema = 'diffusion_results_{0}_{1}'.format(suffix, scen_suffix)
    inputs['dest_schema'] = dest_schema

    sql = '''SELECT diffusion_shared.clone_schema('{source_schema}', '{dest_schema}', '{role}', {include_data});'''.format(**inputs)
    cur.execute(sql)
    con.commit()

    logger.info('\tOutput schema is: {}'.format(dest_schema))

    return dest_schema


@decorators.fn_timer(logger=logger, tab_level=1, prefix='')
def drop_output_schema(pg_conn_string, schema, delete_output_schema):
    """
    Deletes output schema from database if set to true
    
    Parameters
    ----------
    pg_conn_string : 'string'
        String to connect to pgAdmin database
    schema : 'SQL schema'
        Schema that will be deleted
    delete_output_schema : 'bool'
        If set to True in config.py, deletes output schema
    
    """

    inputs = locals().copy()

    if delete_output_schema == True:
        logger.info('Dropping the Output Schema ({}) from Database'.format(schema))

        con, cur = utilfunc.make_con(pg_conn_string, role="postgres")
        #con, cur = utilfunc.make_con(pg_conn_string, role="diffusion-schema-writers")
        sql = '''DROP SCHEMA IF EXISTS {schema} CASCADE;'''.format(**inputs)
        cur.execute(sql)
        con.commit()
    else:
        logger.warning(
            "The output schema  (%(schema)s) has not been deleted. Please delete manually when you are finished analyzing outputs." % inputs)


def get_sectors(cur, schema):
    '''
    Return the sectors to model from table view in postgres.
        
    Parameters
    ----------    
    cur : 'SQL cursor'
        Cursor
    schema : 'SQL schema'
        Schema in which the sectors exist        

    Returns
    -------
    sectors : 'dict'
        Dictionary of sectors to be modeled in table view in postgres

    '''

    sql = '''SELECT sectors
              FROM {}.sectors_to_model;'''.format(schema)
    cur.execute(sql)
    sectors = cur.fetchone()['sectors']
    return sectors


def get_technologies(con, schema):

    '''
    Return the technologies to model from table view in postgres.
        
    Parameters
    ----------    
    con : 'SQL connection'
        Connection
    schema : 'SQL schema'
        Schema in which the technologies exist        

    Returns
    -------
    techs : 'list'
        List of technologies to be modeled in table view in postgres

    '''

    sql = """SELECT 
                CASE WHEN run_tech = 'Solar + Storage' THEN 'solar'::text
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


def get_bass_params(con, schema):

    '''
    Return the bass diffusion parameters to use in the model from table view in postgres.
        
    Parameters
    ----------    
    con : 'SQL connection'
        Connection
    schema : 'SQL schema'
        Schema in which the sectors exist        

    Returns
    -------
    bass_df : 'pd.df'
        Pandas DataFrame of state abbreviation, p, q, teq_yr1 (time equivalency), sector abbreviation, and the technology.

    '''

    inputs = locals().copy()

    sql = """SELECT state_abbr,
                    p,
                    q,
                    teq_yr1,
                    sector_abbr,
                    tech
             FROM {schema}.input_solar_bass_params;""".format(**inputs)

    bass_df = pd.read_sql(sql, con, coerce_float=True)
    bass_df.rename(columns={'p':'bass_param_p',
                            'q':'bass_param_q'}, inplace=True)

    return bass_df


def get_state_incentives(con):

    '''
    Return the state incentives to use in the model from table view in postgres.
        
    Parameters
    ----------    
    con : 'SQL connection'
        Connection       

    Returns
    -------
    state_incentives : 'pd.df'
        Pandas DataFrame of state financial incentives.

    '''

    # changed from 2019 to 2020
    sql = """SELECT * FROM diffusion_shared.state_incentives_2020;"""

    state_incentives = pd.read_sql(sql, con)

    return state_incentives


def get_itc_incentives(con, schema):

    '''
    Return the Investment Tax Credit incentives to use in the model from table view in postgres.
        
    Parameters
    ----------    
    con : 'SQL connection'
        Connection       
    schema : 'SQL schema'
        Schema in which the sectors exist 

    Returns
    -------
    itc_options : 'pd.df'
        Pandas DataFrame of ITC financial incentives.

    '''

    inputs = locals().copy()

    sql = """SELECT year, substring(lower(sector), 1, 3) as sector_abbr,
                    itc_fraction, tech, min_size_kw, max_size_kw
             FROM {schema}.input_main_itc_options;""".format(**inputs)
    itc_options = pd.read_sql(sql, con)
    itc_options.rename(columns={'itc_fraction':'itc_fraction_of_capex'}, inplace=True)

    return itc_options


def get_max_market_share(con, schema):

    '''
    Return the max market share from database, select curve based on scenario_options,
    and interpolate to tenth of a year.
    Use passed parameters to determine ownership typ.
        
    Parameters
    ----------    
    con : 'SQL connection'
        Connection       
    schema : 'SQL schema'
        Schema - string - for technology i.e. diffusion_solar

    Returns
    -------
    max_market_share : 'pd.df'
        Pandas DataFrame to join on main df to determine max share keys are sector & payback period.

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


def get_rate_escalations(con, schema):
    '''
    Return rate escalation multipliers from database. Escalations are filtered and applied in calc_economics,
    resulting in an average real compounding rate growth. This rate is then used to calculate cash flows.
        
    Parameters
    ----------    
    con : 'SQL connection'
        Connection       
    schema : 'SQL schema'
        Schema produced when model is run 

    Returns
    -------
    rate_escalations : 'pd.df'
        Pandas DataFrame with county_id, sector, year, escalation_factor, and source as columns.
    '''


    inputs = locals().copy()
    
    sql = """SELECT year, county_id, sector_abbr, nerc_region_abbr,
                    escalation_factor as elec_price_multiplier
            FROM {schema}.rate_escalations_to_model
            ORDER BY year, county_id, sector_abbr""".format(**inputs)
    rate_escalations = pd.read_sql(sql, con, coerce_float = False)
    
    return rate_escalations


def get_load_growth(con, schema):

    '''
    Return rate load growth values applied to electricity load.
        
    Parameters
    ----------    
    con : 'SQL connection'
        Connection       
    schema : 'SQL schema'
        Schema produced when model is run 

    Returns
    -------
    df : 'pd.df'
        Pandas DataFrame with year, county_id, sector_abbr, nerc_region_abbr, load_multiplier as columns.
    '''

    inputs = locals().copy()

    sql = """SELECT year, county_id, sector_abbr, nerc_region_abbr, load_multiplier
            FROM {schema}.load_growth_to_model;""".format(**inputs)

    df = pd.read_sql(sql, con, coerce_float=False)

    return df


def get_technology_costs_solar(con, schema):

    '''
    Return technology costs for solar.
        
    Parameters
    ----------    
    con : 'SQL connection'
        Connection       
    schema : 'SQL schema'
        Schema produced when model is run 

    Returns
    -------
    df : 'pd.df'
        Pandas DataFrame with year, sector_abbr, system_capex_per_kw, system_om_per_kw, system_variable_om_per_kw as columns.
    '''

    
    inputs = locals().copy()
    
    sql = """SELECT year,
                    sector_abbr,
                    system_capex_per_kw,
                    system_om_per_kw,
                    system_variable_om_per_kw
            FROM {schema}.input_pv_prices_to_model;""".format(inputs)
    df = pd.read_sql(sql, con, coerce_float = False)

    return df 

    
def get_annual_inflation(con, schema):
    '''
    Return the inflation rate set in the input sheet. Constant for all years & sectors.
        
    Parameters
    ----------    
    con : 'SQL connection'
        Connection       
    schema : 'SQL schema'
        diffusion_shared.input_main_market_inflation 

    Returns
    -------
    df.values[0][0] : 'float'
        Float object that represents the inflation rate (e.g. 0.025 which corresponds to 2.5%).
    '''

    inputs = locals().copy()
    sql = '''SELECT *
             FROM diffusion_shared.input_main_market_inflation;'''.format(**inputs)
    df = pd.read_sql(sql, con)
    df.rename(columns={'inflation':'inflation_rate'}, inplace=True)
    return df.values[0][0]  # Just want the inflation as a float (for now)


#%%
def make_output_directory_path(suffix):
    '''
    Creates and returns a directory named 'results' with the timestamp associated with the model run appended. Note, this directory stores 
    metadata associated with the a model run, however, the results of the model run are in the 'agent_outputs' table within the
    schema created with each run in the database. 
    '''

    out_dir = '{}/runs/results_{}'.format(os.path.dirname(os.getcwd()), suffix)

    return out_dir


def get_input_scenarios():
    '''
    Returns a list of the input scenario excel files specified in the input_scenarios directory.

    Returns
    -------
    scenarios : 'list' 
        a list of the input scenario excel files specified in the input_scenarios directory.
    '''

    scenarios = [s for s in glob.glob(
        "../input_scenarios/*.xls*") if not '~$' in s]

    return scenarios


def create_model_years(start_year, end_year, increment=2):

    '''
    Return a list of model years ranging between the specified model start year and end year that increments by 2 year time steps.
        
    Parameters
    ----------    
    start_year : 'int'
        starting year of the model (e.g. 2014)       
    end_year : 'int'
        ending year of the model (e.g. 2050) 

    Returns
    -------
    model_years : 'list'
        list of model years ranging between the specified model start year and end year that increments by 2 year time steps.
    '''

    model_years = list(range(start_year, end_year + 1, increment))

    return model_years


def summarize_scenario(scenario_settings, model_settings):
    '''
    Log high level secenario settings
    '''

    # summarize high level secenario settings
    logger.info('Scenario Settings:')   
    logger.info('\tScenario Name: {}'.format(scenario_settings.scen_name))
    logger.info('\tRegion: {}'.format(scenario_settings.region))
    logger.info('\tSectors: {}'.format(list(scenario_settings.sectors.values())))
    logger.info('\tTechnologies: {}'.format(scenario_settings.techs))
    logger.info('\tYears: {0} - {1}'.format(model_settings.start_year, scenario_settings.end_year))

    return

#%%
def get_scenario_options(cur, schema, pg_params):
    '''
    Pull scenario options and log the user running the scenario from dB
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

    '''
    Returns net metering data for states with available data. Note, many states don't have net metering and or
    the data in diffusion_shared.nem_state_limits_2019 may be incomplete or out of date.
        
    Parameters
    ----------    
    con : 'SQL connection'
        Connection       
    schema : 'SQL schema'
        Schema produced when model is run 

    Returns
    -------
    df : 'pd.df'
        Pandas DataFrame with net metering data.
    '''
    
    sql = "SELECT *, 'BAU'::text as scenario FROM diffusion_shared.nem_state_limits_2019;"
    df = pd.read_sql(sql, con, coerce_float=False)
    
    return df

def get_nem_state_by_sector(con, schema):

    '''
    Returns net metering data for states by sector with available data. Note, many states don't have net metering and or
    the data in diffusion_shared.nem_scenario_bau_2019 may be incomplete or out of date.

    Special handling of DC: System size is unknown until bill calculator runs and differing compensation styles can
    potentially result in different optimal system sizes. Here we assume only res customers (assumed system_size_kw < 100)
    are eligible for full retail net metering; com/ind (assumed system_size_kw >= 100) only eligible for net billing.
        
    Parameters
    ----------    
    con : 'SQL connection'
        Connection       
    schema : 'SQL schema'
        Schema produced when model is run 

    Returns
    -------
    df : 'pd.df'
        Pandas DataFrame with net metering data.
    '''

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

    '''
    Returns net metering data for utility by sector with available data. Note, many utilities don't have net metering and or
    the data in diffusion_shared.nem_scenario_bau_by_utility_2019 may be incomplete or out of date.
        
    Parameters
    ----------    
    con : 'SQL connection'
        Connection       
    schema : 'SQL schema'
        Schema produced when model is run 

    Returns
    -------
    df : 'pd.df'
        Pandas DataFrame with net metering data.
    '''

    sql = "SELECT *, 'BAU'::text as scenario FROM diffusion_shared.nem_scenario_bau_by_utility_2019;"
    df = pd.read_sql(sql, con, coerce_float=False)
    
    df.rename(columns={'max_pv_kw_limit':'nem_system_kw_limit'}, inplace=True)

    return df

def get_selected_scenario(con, schema):

    '''
    Returns net metering scenario selected in the input sheet. Note, net metering data and or scenarios may
    be incomplete or out of date.
        
    Parameters
    ----------    
    con : 'SQL connection'
        Connection       
    schema : 'SQL schema'
        Schema produced when model is run 

    Returns
    -------
    df : 'pd.df'
        Pandas DataFrame with net metering data.
    '''

    sql = "SELECT * FROM diffusion_shared.input_main_nem_selected_scenario;".format(schema)
    df = pd.read_sql(sql, con, coerce_float=False)
    value = df['val'][0]

    return value

def get_state_to_model(con, schema):

    '''
    Returns the region to model as specified in the input sheet. Note, selecting an ISO will select the 
    proper geographies (counties and or states) in import_agent_file() in 'input_data_functions.py'.
    Selecting the United States (national run) will result in every state, excluding Alaska and Hawaii,
    but including D.C., being returned as a list.
        
    Parameters
    ----------    
    con : 'SQL connection'
        Connection       
    schema : 'SQL schema'
        Schema produced when model is run 

    Returns
    -------
    state_to_model : 'list'
        List of states to model.
    '''

    sql = "SELECT * FROM {}.states_to_model;".format(schema)
    df = pd.read_sql(sql, con, coerce_float=False)

    state_to_model = df.state_abbr.tolist()
    
    return state_to_model