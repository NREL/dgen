import pandas as pd
import numpy as np
import os
import sqlalchemy
from sqlalchemy import text
import data_functions as datfunc
import utility_functions as utilfunc
import agent_mutation
from agents import Agents
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
    engine : :class: `sqlalchemy.Engine`
        SQL engine to intepret SQL query

    schema : str
        SQL schema to pull table from 

    name : str
        Name of the table from which fields are retrieved

    Returns
    -------
    array : :class: `numpy.array`
        Numpy array of columns
    
    """
    # Query the relevant SQL table
    sql = "SELECT column_name FROM information_schema.columns WHERE table_schema = '{}' AND table_name   = '{}'".format(schema, name)
    
    # Concatenate the returned table values into one array
    array = np.concatenate(pd.read_sql_query(sql, engine).values)
    
    return array

def df_to_psql(df, engine, schema, owner, name, if_exists='replace', append_transformations=False):
    """
    Uploads dataframe to database
    
    Parameters
    ----------
    df : :class: `pandas.DataFrame`
        Dataframe to upload to database

    engine : :class: `sqlalchemy.Engine`
        SQL engine to intepret SQL query 

    schema : str
        Schema in which to upload df

    owner : str
        Owner of schema

    name : str
        Name to be given to table that is uploaded

    if_exists : str, Optional
        If table exists and if `if_exists` set to 'replace', replaces table in database. If table exists and 
        `if_exists` is set to 'append', appends table in database. 
        Default is 'replace', other options is 'append'
    
    append_transformations : bool, Optional
        Append the dataframe data to the SQL database
        Default is 'False'
    
    Returns
    -------
    df : :class: `pandas.DataFrame`
        Dataframe that was uploaded to database

    """

    d_types = {}
    transform = {}
    f_d_type = {}
    sql_type = {}

    delete_list = []
    orig_fields = df.columns.values
    df.columns = [i.lower() for i in orig_fields]
    
    # Based on values in the columns, assign the corresponding SQL data type
    for f in df.columns:

        # Filter for columns that do contain data
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

    # Drop columns that are empty
    df = df.drop(delete_list, axis=1)

    # For any items in the "transfor" dictionary, append them to the database
    for k, v in list(transform.items()):
        if append_transformations:
            df[k + "_" + f_d_type[k]] = df[k].apply(v)
            sql_type[k + "_" + f_d_type[k]] = sql_type[k]
            del df[k]
            del sql_type[k]
        else:
            df[k] = df[k].apply(v)   

    conn = engine.connect()
    
    # Append to the database if defined by function call
    if if_exists == 'append':
        fields = [i.lower() for i in get_psql_table_fields(engine, schema, name)]
        for f in list(set(df.columns.values) - set(fields)):
            with conn.begin():
                sql = text("ALTER TABLE {}.{} ADD COLUMN {} {}".format(schema, name, f, sql_type[f]))
                conn.execute(sql)
    
    # Send dataframe to SQL database 
    df.to_sql(name, engine, schema=schema, index=False, dtype=d_types, if_exists=if_exists)
    sql = text('ALTER TABLE {}."{}" OWNER to "{}"'.format(schema, name, owner))
    conn.execute(sql)

    # Clean up and close SQL connections
    conn.close()
    engine.dispose() 

    # Set dataframe columns to the original column names
    df.columns = orig_fields
    
    return df
    

#%%
def get_scenario_settings(schema, con):
    """
    Creates dataframe of default scenario settings from input_main_scenario_options table
    
    Parameters
    ----------
    schema : str
        Schema in which to look for the scenario settings

    con : :class: `psycopg2.connection`
        SQL connection to connect to database

    Returns
    -------
    df : :class: `pandas.DataFrame`
        Dataframe of default scenario settings

    """
    # Create the SQL query
    sql = "SELECT * FROM {}.input_main_scenario_options".format(schema)
    
    # Query SQL database table
    df = pd.read_sql(sql, con)

    return df


def get_userdefined_scenario_settings(schema, table_name, con):
    """
    Creates dataframe of user created scenario settings
    
    Parameters
    ----------
    schema : str
        Schema in which to look for the scenario settings
    
    table_name : str
        Name of the table from which fields are retrieved
    
    con : :clas: `psycopg2.connection`
        SQL connection to connect to database

    Returns
    -------
    df : :class: `pandas.DataFrame`
        Dataframe of user created scenario settings

    """
    # Create the SQL query
    sql = "SELECT * FROM {}.{}".format(schema, table_name)
    
    # Query SQL database table
    df = pd.read_sql(sql, con)

    return df


#%%
def import_table(scenario_settings, con, engine, role, input_name, csv_import_function=None):
    """
    Imports table from csv given the name of the csv
    
    Parameters
    ----------
    scenario_settings : :class: `settings.ScenarioSettings`
        Custom object in which to look for the scenario settings

    con : :class: `psycopg2.connection`
        SQL connection to connect to database

    engine : :class: `sqlalchemy.Engine`
        SQL engine to intepret SQL query 

    role : str
        Owner of schema

    input_name : str
        Name of the csv file that should be imported   

    csv_import_function : `input_data_functions.Object`, Optional
        Specific function to import and format csv. Check Notes section for more information on use
        Default is None
        Options are: deprec_schedule, melt_year, process_wholesale_elec_prices, stacked_sectors, and process_elec_price_trajectories
    
    Returns
    -------
    df : :class: `pandas.DataFrame`
        Dataframe of the table that was imported

    Notes
    -----
    - csv_import_function calls the import functions defined in this file. The general function call style is:
        'input_data_functions.import_function_name'
    """

    # Set scenario and scema settings 
    schema = scenario_settings.schema
    shared_schema = 'diffusion_shared'
    input_data_dir = scenario_settings.input_data_dir
    user_scenario_settings = get_scenario_settings(schema, con)
    scenario_name = user_scenario_settings[input_name].values[0]

    if scenario_name == 'User Defined':

        userdefined_table_name = "input_" + input_name + "_user_defined"
        scenario_userdefined_name = get_userdefined_scenario_settings(schema, userdefined_table_name, con)
        scenario_userdefined_value = scenario_userdefined_name['val'].values[0]
        
        # Read in the local user defined dataset as a pandas dataframe
        df = pd.read_csv(os.path.join(input_data_dir, input_name, scenario_userdefined_value + '.csv'), index_col=False)

        # Use the defined csv import function to read in the csv file
        if csv_import_function is not None:
            df = csv_import_function(df)

        df_to_psql(df, engine, shared_schema, role, scenario_userdefined_value)

    else:
        # For non user defined scenarios, query the relevant SQL database
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
    df : :class: `pandas.DataFrame`
        Dataframe to be sorted by sector. 
    
    Returns
    -------
    output : :class: `pandas.DataFrame`
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
    df : :class: `pandas.DataFrame`
        Dataframe to be sorted by sector. 
    
    Returns
    -------
    df : :class: `pandas.DataFrame`
        Input dataframe with depreciation schedule sorted by year

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
    parameter_name : `string`
        Name of the parameter value in dataframe. 
    
    Returns
    -------
    function : `function`
        Function that melts years and parameter value to row axis

    """

    def function(df):
        """
        Unpivots years and values from columns of dataframe to rows for each state abbreviation
    
        Parameters
        ----------
        df : :class: `pandas.DataFrame`
            Dataframe to be unpivot. 
    
        Returns
        -------
        df_tidy : :class: `pandas.DataFrame`
            Dataframe with every other year and the parameter value for that year as rows for each state 

        """
    
        years = np.arange(2014, 2051, 2)
        years = [str(year) for year in years]

        df_tidy = pd.melt(df, id_vars='state_abbr', value_vars=years, var_name='year', value_name=parameter_name)

        df_tidy['year'] = df_tidy['year'].astype(int)

        return df_tidy

    return function


#%%
def import_agent_file(scenario_settings, con, model_settings, agent_file_status, input_name):
    """
    Generates new agents or uses pre-generated agents from provided .pkl file
    
    Parameters
    ----------
    scenario_settings : :class: `settings.ScenarioSettings`
        Custom object in which to look for the scenario settings

    con : :class: `psycopg2.connection`
        SQL connection to connect to database

    model_settings : :class: `settings.ModelSettings`
        Model settings that apply to all scenarios

    agent_file_status : str
        Attribute that describes whether to use pre-generated agent file or create new  
        Function and model only allows use of pre-generated agent files

    input_name : str
        Pickle file name of pre-generated agent table 
    
    Returns
    -------
    solar_agents : :class: `agents.Agents`
        Instance of Agents class with pre-generated agents

    Raises
    ------
        ValueError 
            Raised if region in the pickle file  
            "Region not present within pre-generated agent file - Edit Inputsheet"
        
        ValueError
            Raised if agent supplied does not confirm to correct standards. See references for the template
            "Generating agents is not supported at this time. Please select "Use pre-generated Agents" in the input sheet')"

    References
    ----------
    Pre-generated agents for selected region as a pickle file can be downloaded from here: https://data.openei.org/s3_viewer?bucket=oedi-data-lake&prefix=dgen%2F

    """
    # Define scenario specific values for model run 
    schema = scenario_settings.schema
    input_agent_dir = model_settings.input_agent_dir
    state_to_model = scenario_settings.state_to_model

    ISO_List = ['ERCOT', 'NEISO', 'NYISO', 'CAISO', 'PJM', 'MISO', 'SPP']

    if agent_file_status == 'Use pre-generated Agents':
        # Create a table in the SQL database with the user defined sceanrio settings
        userdefined_table_name = "input_" + input_name + "_user_defined"
        scenario_userdefined_name = get_userdefined_scenario_settings(schema, userdefined_table_name, con)
        scenario_userdefined_value = scenario_userdefined_name['val'].values[0]

        # Read in the agent pickle file
        solar_agents_df = pd.read_pickle(os.path.join(input_agent_dir, scenario_userdefined_value+".pkl"))

        # Depending on if the agent files is part of an ISO or state, select agent down for correct region
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
    elec_price_traj : :class: `pandas.DataFrame`
        Dataframe of electricity prices by year and ReEDS balancing areas
    
    Returns
    -------
    elec_price_change_traj : :class: `pandas.DataFrame`
        Dataframe of annual electricity price change factors from base year

    Notes
    -----
    The price trajectory is calculated at the balancing areas level. With county mapped to balancing areas. 

    """

    county_to_ba_lkup = pd.read_csv('county_to_ba_mapping.csv')

    # For SS19, when using Retail Electricity Prices from ReEDS
    base_year_prices = elec_price_traj[elec_price_traj['year']==2018]
    
    # Rename columns to match what is found in model
    base_year_prices.rename(columns={'elec_price_res':'res_base',
                                     'elec_price_com':'com_base',
                                     'elec_price_ind':'ind_base'}, inplace=True)
    
    elec_price_change_traj = pd.merge(elec_price_traj, base_year_prices[['res_base', 'com_base', 'ind_base', 'ba']], on='ba')

    # Assign new electricity price change columns by sector based on the trajectory price and base price for that sector
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
    
    # Re-combine the sector electriciity price projections into one dataframe
    elec_price_change_traj = pd.concat([res_df, com_df, ind_df], ignore_index=True, sort=False)
    
    # Add the county name and balancing area (ba) information to the dataframe
    elec_price_change_traj = pd.merge(county_to_ba_lkup, elec_price_change_traj, how='left', on=['ba'])
    
    # Remove balancing area column from dataframe
    elec_price_change_traj.drop(['ba'], axis=1, inplace=True)  

    return elec_price_change_traj


#%%
def process_wholesale_elec_prices(wholesale_elec_price_traj):
    """
    Returns the trajectory of the change in wholesale electricity prices over time
    
    Parameters
    ----------
    wholesale_elec_price_traj : :class: `pandas.DataFrame`
        Dataframe of wholesale electricity prices by year and ReEDS BA
    
    Returns
    -------
    wholesale_elec_price_change_traj : :class: `pandas.DataFrame`
        Dataframe of annual electricity price change factors from base year, 

    Notes
    -----
    The price change is calculated at the balancing areas level. With county mapped to balancing areas. 

    """

    county_to_ba_lkup = pd.read_csv('county_to_ba_mapping.csv')

    # Create a list of valid years for the model to use
    years = np.arange(2014, 2051, 2)
    years = [str(year) for year in years]

    # Un-pivot wholesale price dataframe, preserving the balancing area column (ba)
    wholesale_elec_price_change_traj = pd.melt(wholesale_elec_price_traj, id_vars='ba', value_vars=years, var_name='year', value_name='wholesale_elec_price_dollars_per_kwh')

    # Change the data tpype of the 'year' column to be "int"
    wholesale_elec_price_change_traj['year'] = wholesale_elec_price_change_traj['year'].astype(int)
    
    # Merge in the county and balancing area data to the price change trajectory, merging on the balancing area column of both dataframes 
    wholesale_elec_price_change_traj = pd.merge(county_to_ba_lkup, wholesale_elec_price_change_traj, how='left', on=['ba'])
    
    # Remove balancing area column from dataframe
    wholesale_elec_price_change_traj.drop(['ba'], axis=1, inplace=True)
    
    return wholesale_elec_price_change_traj
