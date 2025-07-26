import os
import multiprocessing



#==============================================================================
#   get postgres connection parameters
#==============================================================================
# get the path of the current file
model_path = os.path.dirname(os.path.abspath(__file__))

# set the name of the pg_params_file
pg_params_file = 'pg_params_connect.json'

#==============================================================================
#   model start year
#==============================================================================
start_year = 2026

#==============================================================================
#   set number of parallel processes to run postgres queries
#==============================================================================
if os.environ.get('LOCAL_CORES'):
    pg_procs = multiprocessing.cpu_count()
else:
    pg_procs = 12

#==============================================================================
#   set role for database (default is postgres)
#==============================================================================
role = 'postgres'

#==============================================================================
#   local cores
#==============================================================================
local_cores = multiprocessing.cpu_count()//2
#==============================================================================
#  Should the output schema be deleted after the model run
#==============================================================================
delete_output_schema = False

#==============================================================================
#  Set switch for dynamic sizing
#==============================================================================
dynamic_system_sizing = True

#==============================================================================
#  Runtime Tests
#==============================================================================
NULL_COLUMN_EXCEPTIONS = ['state_incentives', 'pct_state_incentives', 'batt_dispatch_profile', 'export_tariff_results']

CHANGED_DTYPES_EXCEPTIONS = []
MISSING_COLUMN_EXCEPTIONS = []

#==============================================================================
#  Detailed Output
#==============================================================================
VERBOSE = False

#==============================================================================
#  Define Directories
#==============================================================================

cwd = os.getcwd() #should be /python
pdir = os.path.abspath('..') #should be /dgen or whatever it is called

OBSERVED_DEPLOYMENT_BY_STATE = os.path.join(pdir, 'input_data','observed_deployment_by_state_sector_2020.csv')