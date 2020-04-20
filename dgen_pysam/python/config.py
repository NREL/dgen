# -*- coding: utf-8 -*-

import os
import multiprocessing
import pandas as pd

#==============================================================================
# these are all variables that we can change, but don't want to expose to non-expert users
#==============================================================================

#==============================================================================
#   get postgres connection parameters
#==============================================================================
# get the path of the current file
model_path = os.path.dirname(os.path.abspath(__file__))

# set the name of the pg_params_file
pg_params_file = 'pg_params_atlas.json'

#==============================================================================
#   set the number of customer bins to model in each county
#==============================================================================
agents_per_region = 1
sample_pct = 0.02
min_agents = 3

#==============================================================================
#   model start year
#==============================================================================
start_year = 2014

#==============================================================================
#   set number of parallel processes to run postgres queries (this is ignored if parallelize = F)
#==============================================================================
pg_procs = 2

#==============================================================================
#   local cores
#==============================================================================
local_cores = multiprocessing.cpu_count()//2

#==============================================================================
#  Should the output schema be deleted after the model run
#==============================================================================
delete_output_schema = False

#==============================================================================
#  Set switch to determine if model should output ReEDS data (datfunc.aggregate_outputs_solar)
#==============================================================================
dynamic_system_sizing = True

#==============================================================================
#  Set switch to determine if model should output ReEDS data (datfunc.aggregate_outputs_solar)
#==============================================================================
output_reeds_data = False

#==============================================================================
#  Runtime Tests
#==============================================================================
NULL_COLUMN_EXCEPTIONS = ['state_incentives', 'pct_state_incentives', 'batt_dispatch_profile', 'export_tariff_results']
                        # 'market_share_last_year', 'max_market_share_last_year', 'adopters_cum_last_year', 'market_value_last_year', 'initial_number_of_adopters', 'initial_pv_kw', 'initial_market_share', 'initial_market_value', 'system_kw_cum_last_year', 'new_system_kw', 'batt_kw_cum_last_year', 'batt_kwh_cum_last_year',
CHANGED_DTYPES_EXCEPTIONS = []
MISSING_COLUMN_EXCEPTIONS = []

#==============================================================================
#  Detailed Output
#==============================================================================
VERBOSE = False

#==============================================================================
#  Define CSVS
#==============================================================================

# --- Define Directories ---
cwd = os.getcwd() #should be /python
pdir = os.path.abspath('..') #should be /dgen or whatever it is called

INSTALLED_CAPACITY_BY_STATE = os.path.join(pdir, 'input_data','installed_capacity_mw_by_state_sector.csv')