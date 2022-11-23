import pandas as pd
import numpy as np
import os
import sqlalchemy
import data_functions as datfunc
import utility_functions as utilfunc
import agent_mutation
from agents import Agents, Solar_Agents
from pandas import DataFrame
import json

# Load logger
logger = utilfunc.get_logger()

#%%

def get_psql_table_fields(engine, schema, name):
    """
    Creates numpy array of columns from specified schema and table
    
    Parameters
    ----------
    engine : 'SQL engine'
        SQL engine to intepret SQL query
    schema : 'SQL schema'
        SQL schema to pull table from 
    name : 'string'
        Name of the table from which fields are retrieved

    Returns
    -------
    numpy array : 'np.array'
        Numpy array of columns

    """

    sql = "SELECT column_name FROM information_schema.columns WHERE table_schema = '{}' AND table_name   = '{}'".format(schema, name)
    return np.concatenate(pd.read_sql_query(sql, engine).values)

def df_to_psql(df, engine, schema, owner, name, if_exists='replace', append_transformations=False):
    """
    Uploads dataframe to database
    
    Parameters
    ----------
    df : 'pd.df'
        Dataframe to upload to database
    engine : 'SQL table'
        SQL engine to intepret SQL query 
    schema : 'SQL schema'
        Schema in which to upload df
    owner : 'string'
        Owner of schema
    name : 'string'
        Name to be given to table that is uploaded
    if_exists : 'replace or append'
        If table exists and if if_exists set to replace, replaces table in database. If table exists and if if_exists set to append, appendss table in database. 
    append_transformations : 'bool'
        IDK
    
    Returns
    -------
    df : 'pd.df'
        Dataframe that was uploaded to database

    """

    d_types = {}
    transform = {}
    f_d_type = {}
    sql_type = {}

    delete_list = []
    orig_fields = df.columns.values
    df.columns = [i.lower() for i in orig_fields]
    for f in df.columns:
        df_filter = pd.notnull(df[f]).values
        if sum(df_filter) > 0:
            f_d_type[f] = type(df[f][df_filter].values[0]).__name__.lower()

            if f_d_type[f][0:3].lower() == 'int':
                sql_type[f] = 'INTEGER'

            if f_d_type[f][0:5].lower() == 'float':
                d_types[f] = sqlalchemy.types.NUMERIC
                sql_type[f] = 'NUMERIC'

            if f_d_type[f][0:3].lower() == 'str':
                sql_type[f] = 'VARCHAR'

            if f_d_type[f] == 'list':
                d_types[f] = sqlalchemy.types.ARRAY(sqlalchemy.types.STRINGTYPE)
                transform[f] = lambda x: json.dumps(x)
                sql_type[f] = 'VARCHAR'

            if f_d_type[f] == 'ndarray':
                d_types[f] = sqlalchemy.types.ARRAY(sqlalchemy.types.STRINGTYPE)
                transform[f] = lambda x: json.dumps(list(x))
                sql_type[f] = 'VARCHAR'

            if f_d_type[f] == 'dict':
                d_types[f] = sqlalchemy.types.STRINGTYPE
                transform[f] = lambda x: json.dumps(
                    dict([(k_v[0], list(k_v[1])) if (type(k_v[1]).__name__ == 'ndarray') else (k_v[0], k_v[1]) for k_v in list(x.items())]))
                sql_type[f] = 'VARCHAR'

            if f_d_type[f] == 'interval':
                d_types[f] = sqlalchemy.types.STRINGTYPE
                transform[f] = lambda x: str(x)
                sql_type[f] = 'VARCHAR'

            if f_d_type[f] == 'dataframe':
                d_types[f] = sqlalchemy.types.STRINGTYPE
                transform[f] = lambda x: x.to_json() if isinstance(x,DataFrame) else str(x)
                sql_type[f] = 'VARCHAR'
        else:
            orig_fields = [i for i in orig_fields if i.lower()!=f]
            delete_list.append(f)

    df = df.drop(delete_list, axis=1)

    for k, v in list(transform.items()):
        if append_transformations:
            df[k + "_" + f_d_type[k]] = df[k].apply(v)
            sql_type[k + "_" + f_d_type[k]] = sql_type[k]
            del df[k]
            del sql_type[k]
        else:
            df[k] = df[k].apply(v)   

    conn = engine.connect()
    if if_exists == 'append':
        fields = [i.lower() for i in get_psql_table_fields(engine, schema, name)]
        for f in list(set(df.columns.values) - set(fields)):
            sql = "ALTER TABLE {}.{} ADD COLUMN {} {}".format(schema, name, f, sql_type[f])
            conn.execute(sql)
        
    df.to_sql(name, engine, schema=schema, index=False, dtype=d_types, if_exists=if_exists)
    sql = 'ALTER TABLE {}."{}" OWNER to "{}"'.format(schema, name, owner)
    conn.execute(sql)

    conn.close()
    engine.dispose() 

    df.columns = orig_fields
    return df
    

#%%
def get_scenario_settings(schema, con):
    """
    Creates dataframe of default scenario settings from input_main_scenario_options table
    
    Parameters
    ----------
    schema : 'SQL schema'
        Schema in which to look for the scenario settings
    con : 'SQL connection'
        SQL connection to connect to database

    Returns
    -------
    df : 'pd.df'
        Dataframe of default scenario settings

    """

    sql = "SELECT * FROM {}.input_main_scenario_options".format(schema)
    df = pd.read_sql(sql, con)

    return df


def get_userdefined_scenario_settings(schema, table_name, con):
    """
    Creates dataframe of user created scenario settings
    
    Parameters
    ----------
    schema : 'SQL schema'
        Schema in which to look for the scenario settings
    con : 'SQL connection'
        SQL connection to connect to database

    Returns
    -------
    df : 'pd.df'
        Dataframe of user created scenario settings

    """

    sql = "SELECT * FROM {}.{}".format(schema, table_name)
    df = pd.read_sql(sql, con)

    return df


#%%
def import_table(scenario_settings, con, engine, role, input_name, csv_import_function=None):
    """
    Imports table from csv given the name of the csv
    
    Parameters
    ----------
    scenario_settings : 'SQL schema'
        Schema in which to look for the scenario settings
    con : 'SQL connection'
        SQL connection to connect to database
    engine : 'SQL engine'
        SQL engine to intepret SQL query
    role : 'string'
        Owner of schema
    input_name : 'string'
        Name of the csv file that should be imported     
    csv_import_function : 'function'
        Specific function to import and munge csv 
    
    Returns
    -------
    df : 'pd.df'
        Dataframe of the table that was imported

    """

    schema = scenario_settings.schema
    shared_schema = 'diffusion_shared'
    input_data_dir = scenario_settings.input_data_dir
    user_scenario_settings = get_scenario_settings(schema, con)
    scenario_name = user_scenario_settings[input_name].values[0]

    if scenario_name == 'User Defined':

        userdefined_table_name = "input_" + input_name + "_user_defined"
        scenario_userdefined_name = get_userdefined_scenario_settings(schema, userdefined_table_name, con)
        scenario_userdefined_value = scenario_userdefined_name['val'].values[0]
        
        df = pd.read_csv(os.path.join(input_data_dir, input_name, scenario_userdefined_value + '.csv'), index_col=False)

        if csv_import_function is not None:
            df = csv_import_function(df)

        df_to_psql(df, engine, shared_schema, role, scenario_userdefined_value)

    else:
        if input_name == 'elec_prices':
            df = datfunc.get_rate_escalations(con, scenario_settings.schema)
        elif input_name == 'load_growth':
            df = datfunc.get_load_growth(con, scenario_settings.schema)
        elif input_name == 'pv_prices':
            df = datfunc.get_technology_costs_solar(con, scenario_settings.schema)

    return df


#%%
def stacked_sectors(df):
    """
    Takes dataframe and sorts table fields by sector
    
    Parameters
    ----------
    df : 'pd.df'
        Dataframe to be sorted by sector. 
    
    Returns
    -------
    output : 'pd.df'
        Dataframe of the table that was imported and split by sector

    """

    sectors = ['res', 'ind','com','nonres','all']
    output = pd.DataFrame()
    core_columns = [x for x in df.columns if x.split("_")[-1] not in sectors]

    for sector in sectors:
        if sector in set([i.split("_")[-1] for i in df.columns]):
            sector_columns = [x for x in df.columns if x.split("_")[-1] == sector]
            rename_fields = {k:"_".join(k.split("_")[0:-1]) for k in sector_columns}

            temp =  df.loc[:,core_columns + sector_columns]
            temp = temp.rename(columns=rename_fields)
            if sector =='nonres':
                sector_list = ['com', 'ind']
            elif sector=='all':
                sector_list = ['com', 'ind','res']
            else:
                sector_list = [sector]
            for s in sector_list:
                temp['sector_abbr'] = s
                output = pd.concat([output, temp], ignore_index=True, sort=False)

    return output

#%%
def deprec_schedule(df):
    """
    Takes depreciation schedule and sorts table fields by depreciation year
    
    Parameters
    ----------
    df : 'pd.df'
        Dataframe to be sorted by sector. 
    
    Returns
    -------
    output : 'pd.df'
        Dataframe of depreciation schedule sorted by year

    """

    columns = ['1', '2', '3', '4', '5', '6']
    df['deprec_sch']=df.apply(lambda x: [x.to_dict()[y] for y in columns], axis=1)

    max_required_year = 2050
    max_input_year = np.max(df['year'])
    missing_years = np.arange(max_input_year + 1, max_required_year + 1, 1)
    last_entry = df[df['year'] == max_input_year]

    for year in missing_years:
        last_entry['year'] = year
        df = pd.concat([df,last_entry], ignore_index=True, sort=False)


    return df.loc[:,['year','sector_abbr','deprec_sch']]

#%%
def melt_year(parameter_name):
    """
    Returns a function to melt dataframe's columns of years and parameter values to the row axis
    
    Parameters
    ----------
    parameter name : 'string'
        Name of the parameter value in dataframe. 
    
    Returns
    -------
    function : 'function'
        Function that melts years and parameter value to row axis

    """

    def function(df):
        """
        Unpivots years and values from columns of dataframe to rows for each state abbreviation
    
        Parameters
        ----------
        df : 'pd.df'
            Dataframe to be unpivot. 
    
        Returns
        -------
        df_tidy : 'pd.df'
            Dataframe with every other year and the parameter value for that year as rows for each state 

        """
    
        years = np.arange(2014, 2051, 2)
        years = [str(year) for year in years]

        df_tidy = pd.melt(df, id_vars='state_abbr', value_vars=years, var_name='year', value_name=parameter_name)

        df_tidy['year'] = df_tidy['year'].astype(int)

        return df_tidy

    return function


#%%
def import_agent_file(scenario_settings, con, cur, engine, model_settings, agent_file_status, input_name):
    """
    Generates new agents or uses pre-generated agents from provided .pkl file
    
    Parameters
    ----------
    scenario_settings : 'SQL schema'
        Schema of the scenario settings
    con : 'SQL connection'
        SQL connection to connect to database
    cur : 'SQL cursor'
        Cursor
    engine : 'SQL engine'
        SQL engine to intepret SQL query
    model_settings : 'object'
        Model settings that apply to all scenarios
    agent_file_status : 'attribute'
        Attribute that describes whether to use pre-generated agent file or create new    
    input_name : 'string'
        .Pkl file name substring of pre-generated agent table 
    
    Returns
    -------
    solar_agents : 'Class'
        Instance of Agents class with either user pre-generated or new data

    """

    schema = scenario_settings.schema
    input_agent_dir = model_settings.input_agent_dir
    state_to_model = scenario_settings.state_to_model

    ISO_List = ['ERCOT', 'NEISO', 'NYISO', 'CAISO', 'PJM', 'MISO', 'SPP']

    if agent_file_status == 'Use pre-generated Agents':

        userdefined_table_name = "input_" + input_name + "_user_defined"
        scenario_userdefined_name = get_userdefined_scenario_settings(schema, userdefined_table_name, con)
        scenario_userdefined_value = scenario_userdefined_name['val'].values[0]

        solar_agents_df = pd.read_pickle(os.path.join(input_agent_dir, scenario_userdefined_value+".pkl"))

        if scenario_settings.region in ISO_List:
            solar_agents_df = pd.read_pickle(os.path.join(input_agent_dir, scenario_userdefined_value+".pkl"))

        else:
            solar_agents_df = solar_agents_df[solar_agents_df['state_abbr'].isin(state_to_model)]

        if solar_agents_df.empty:
            raise ValueError('Region not present within pre-generated agent file - Edit Inputsheet')
            
        solar_agents = Agents(solar_agents_df)

        solar_agents.on_frame(agent_mutation.elec.reassign_agent_tariffs, con)

    else:
        raise ValueError('Generating agents is not supported at this time. Please select "Use pre-generated Agents" in the input sheet')

    return solar_agents


#%%
def process_elec_price_trajectories(elec_price_traj):
    """
    Returns the trajectory of the change in electricity prices over time with 2018 as the base year
    
    Parameters
    ----------
    elec_price_traj : 'pd.df'
        Dataframe of electricity prices by year and ReEDS BA
    
    Returns
    -------
    elec_price_change_traj : 'pd.df'
        Dataframe of annual electricity price change factors from base year

    """

    county_to_ba_lkup = pd.read_csv('county_to_ba_mapping.csv')

    # For SS19, when using Retail Electricity Prices from ReEDS
    base_year_prices = elec_price_traj[elec_price_traj['year']==2018]
    
    base_year_prices.rename(columns={'elec_price_res':'res_base',
                                     'elec_price_com':'com_base',
                                     'elec_price_ind':'ind_base'}, inplace=True)
    
    elec_price_change_traj = pd.merge(elec_price_traj, base_year_prices[['res_base', 'com_base', 'ind_base', 'ba']], on='ba')

    elec_price_change_traj['elec_price_change_res'] = elec_price_change_traj['elec_price_res'] / elec_price_change_traj['res_base']
    elec_price_change_traj['elec_price_change_com'] = elec_price_change_traj['elec_price_com'] / elec_price_change_traj['com_base']
    elec_price_change_traj['elec_price_change_ind'] = elec_price_change_traj['elec_price_ind'] / elec_price_change_traj['ind_base']

    # Melt by sector
    res_df = pd.DataFrame(elec_price_change_traj['year'])
    res_df = elec_price_change_traj[['year', 'elec_price_change_res', 'ba']]
    res_df.rename(columns={'elec_price_change_res':'elec_price_multiplier'}, inplace=True)
    res_df['sector_abbr'] = 'res'
    
    com_df = pd.DataFrame(elec_price_change_traj['year'])
    com_df = elec_price_change_traj[['year', 'elec_price_change_com', 'ba']]
    com_df.rename(columns={'elec_price_change_com':'elec_price_multiplier'}, inplace=True)
    com_df['sector_abbr'] = 'com'
    
    ind_df = pd.DataFrame(elec_price_change_traj['year'])
    ind_df = elec_price_change_traj[['year', 'elec_price_change_ind', 'ba']]
    ind_df.rename(columns={'elec_price_change_ind':'elec_price_multiplier'}, inplace=True)
    ind_df['sector_abbr'] = 'ind'
    
    elec_price_change_traj = pd.concat([res_df, com_df, ind_df], ignore_index=True, sort=False)
    
    elec_price_change_traj = pd.merge(county_to_ba_lkup, elec_price_change_traj, how='left', on=['ba'])
    
    elec_price_change_traj.drop(['ba'], axis=1, inplace=True)  

    return elec_price_change_traj


#%%
def process_wholesale_elec_prices(wholesale_elec_price_traj):
    """
    Returns the trajectory of the change in wholesale electricity prices over time
    
    Parameters
    ----------
    wholesale_elec_price_traj : 'pd.df'
        Dataframe of wholesale electricity prices by year and ReEDS BA
    
    Returns
    -------
    wholesale_elec_price_change_traj : 'pd.df'
        Dataframe of annual electricity price change factors from base year

    """

    county_to_ba_lkup = pd.read_csv('county_to_ba_mapping.csv')
    
    years = np.arange(2014, 2051, 2)
    years = [str(year) for year in years]

    wholesale_elec_price_change_traj = pd.melt(wholesale_elec_price_traj, id_vars='ba', value_vars=years, var_name='year', value_name='wholesale_elec_price_dollars_per_kwh')

    wholesale_elec_price_change_traj['year'] = wholesale_elec_price_change_traj['year'].astype(int)
 
    wholesale_elec_price_change_traj = pd.merge(county_to_ba_lkup, wholesale_elec_price_change_traj, how='left', on=['ba'])
    
    wholesale_elec_price_change_traj.drop(['ba'], axis=1, inplace=True)
    
    return wholesale_elec_price_change_traj


#%%
def process_load_growth(load_growth):
    """
    Returns the trajectory of the load growth rates over time relative to a base year of 2014
    
    Parameters
    ----------
    load_growth : 'pd.df'
        Dataframe of annual load growth rates
    
    Returns
    -------
    load_growth_change_traj : 'pd.df'
        Dataframe of annual load growth rates relative to base year

    """

    base_year_load_growth = load_growth[load_growth['year']==2014]
    
    base_year_load_growth.rename(columns={'load_growth_res':'res_base',
                                     'load_growth_com':'com_base',
                                     'load_growth_ind':'ind_base'}, inplace=True)
    
    load_growth_change_traj = pd.merge(load_growth, base_year_load_growth[['res_base', 'com_base', 'ind_base', 'census_division_abbr']], on='census_division_abbr')

    load_growth_change_traj['load_growth_change_res'] = load_growth_change_traj['load_growth_res'] / load_growth_change_traj['res_base']
    load_growth_change_traj['load_growth_change_com'] = load_growth_change_traj['load_growth_com'] / load_growth_change_traj['com_base']
    load_growth_change_traj['load_growth_change_ind'] = load_growth_change_traj['load_growth_ind'] / load_growth_change_traj['ind_base']

    # Melt by sector
    res_df = pd.DataFrame(load_growth_change_traj['year'])
    res_df = load_growth_change_traj[['year', 'load_growth_change_res', 'census_division_abbr']]
    res_df.rename(columns={'load_growth_change_res':'load_multiplier'}, inplace=True)
    res_df['sector_abbr'] = 'res'
    
    com_df = pd.DataFrame(load_growth_change_traj['year'])
    com_df = load_growth_change_traj[['year', 'load_growth_change_com', 'census_division_abbr']]
    com_df.rename(columns={'load_growth_change_com':'load_multiplier'}, inplace=True)
    com_df['sector_abbr'] = 'com'
    
    ind_df = pd.DataFrame(load_growth_change_traj['year'])
    ind_df = load_growth_change_traj[['year', 'load_growth_change_ind', 'census_division_abbr']]
    ind_df.rename(columns={'load_growth_change_ind':'load_multiplier'}, inplace=True)
    ind_df['sector_abbr'] = 'ind'
    
    load_growth_change_traj = pd.concat([res_df, com_df, ind_df], ignore_index=True, sort=False)

    return load_growth_change_traj
