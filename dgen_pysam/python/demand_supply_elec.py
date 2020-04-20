# -*- coding: utf-8 -*-
"""
Created on Thu May 26 11:29:02 2016

@author: mgleason
"""
import decorators
import utility_functions as utilfunc


#%% GLOBAL SETTINGS

# load logger
logger = utilfunc.get_logger()


#%%
@decorators.fn_timer(logger = logger, tab_level = 2, prefix = '')
def setup_resource_data(cur, con, schema, seed):
    
    # DO NOTHING -- NOT USED IN ELEC
    return
    
 
#%%
@decorators.fn_timer(logger = logger, tab_level = 2, prefix = '')
def get_plant_cost_data(con, schema, year):
    
    # DO NOTHING -- NOT USED IN ELEC
    return
    
    
#%%
@decorators.fn_timer(logger = logger, tab_level = 2, prefix = '')
def get_plant_cost_and_performance_data(resource_df, costs_df):
    
    # DO NOTHING -- NOT USED IN ELEC
    return


#%%
@decorators.fn_timer(logger = logger, tab_level = 2, prefix = '')
def get_reservoir_factors(resource_df, costs_df):
    
    # DO NOTHING -- NOT USED IN ELEC
    return


#%%
@decorators.fn_timer(logger = logger, tab_level = 2, prefix = '')
def get_plant_finance_data(con, schema, year):

    # DO NOTHING -- NOT USED IN ELEC
    return
    
#%%
@decorators.fn_timer(logger = logger, tab_level = 2, prefix = '')
def get_plant_construction_factor_data(con, schema, year):
    
    # DO NOTHING -- NOT USED IN ELEC
    return
    
    
#%%
@decorators.fn_timer(logger = logger, tab_level = 2, prefix = '')
def get_plant_depreciation_data(con, schema, year):

    # DO NOTHING -- NOT USED IN ELEC
    return


#%%
@decorators.fn_timer(logger = logger, tab_level = 2, prefix = '')
def get_distribution_network_data():
    
    # DO NOTHING -- NOT USED IN ELEC
    return