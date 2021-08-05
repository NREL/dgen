import os
import warnings
import json
import pandas as pd
import utility_functions as utilfunc
import multiprocessing
import sys
import psycopg2.extras as pgx
import config
import data_functions as datfunc
from excel import excel_functions

#==============================================================================
# Load logger
logger = utilfunc.get_logger()
#==============================================================================


class ModelSettings(object):
    
    """
     Class containing the model settings parameters
     Attributes
     ----------
     model_init : float
     cdate : str
     out_dir : str
     input_agent_dir : str
     input_data_dir : str
     start_year : int
     input_scenarios : list
     pg_params_file : str
     role : str
     pg_params : dict
     pg_engine_params : dict
     pg_conn_string : str
     pg_engine_string : str
     pg_params_log : str
     model_path : bool
     local_cores : int
     pg_procs : int
     delete_output_schema : bool
     dynamic_system_sizing : bool
     """

    def __init__(self):

        self.model_init = None  # type is float
        self.cdate = None  # type is text
        self.out_dir = None  # doesn't exist already, check parent folder exists
        self.start_year = None  # must = 2014
        self.role = None  # type is text
        self.input_scenarios = None  # type is list, is not empty
        self.pg_params_file = None  # path exists
        self.pg_params = None  # type is dict, includes all elements
        self.pg_conn_string = None  # type is text
        self.pg_params_log = None  # type is text, doesn't include pw
        self.model_path = None  # path exists
        self.pg_procs = None  # int<=16
        self.local_cores = None  # int < cores on machine
        self.delete_output_schema = None  # bool
        self.dynamic_system_sizing = None  # bool

    def set(self, attr, value):

        self.__setattr__(attr, value)
        self.validate_property(attr)

    def get(self, attr):

        return self.__getattribute__(attr)

    def add_config(self, config):

        self.set('start_year', config.start_year)
        self.set('model_path', config.model_path)
        self.set('local_cores', config.local_cores)
        self.set('pg_procs', config.pg_procs)
        self.set('role', config.role)
        self.set_pg_params(config.pg_params_file)
        self.set('delete_output_schema', config.delete_output_schema)
        self.set('dynamic_system_sizing', config.dynamic_system_sizing)

    def set_pg_params(self, pg_params_file):

        # check that it exists
        pg_params, pg_conn_string = utilfunc.get_pg_params(
            os.path.join(self.model_path, pg_params_file))
        pg_engine_params, pg_engine_string = utilfunc.get_pg_engine_params(
            os.path.join(self.model_path, pg_params_file))
        pg_params_log = json.dumps(json.loads(pd.DataFrame([pg_params])[
                                   ['host', 'port', 'dbname', 'user']].iloc[0].to_json()), indent=4, sort_keys=True)

        self.set('pg_params_file', pg_params_file)
        self.set('pg_params', pg_params)
        self.set('pg_conn_string', pg_conn_string)
        self.set('pg_params_log', pg_params_log)
        self.set('pg_engine_params', pg_engine_params)
        self.set('pg_engine_string', pg_engine_string)

    def validate_property(self, property_name):

        # for all properties -- check not null
        if self.get(property_name) == None:
            raise ValueError('{} has not been set'.format(property_name))

        # validation for specific properties
        if property_name == 'model_init':
            # check type
            try:
                check_type(self.get(property_name), float)
            except TypeError as e:
                raise TypeError('Invalid {0}: {1}'.format(property_name, e))

        elif property_name == 'cdate':
            # check type
            try:
                check_type(self.get(property_name), str)
            except TypeError as e:
                raise TypeError('Invalid {0}: {1}'.format(property_name, e))

        elif property_name in ['out_dir','input_agent_dir','input_data_dir']:
            # check type
            try:
                check_type(self.get(property_name), str)
            except TypeError as e:
                raise TypeError('Invalid {0}: {1}'.format(property_name, e))

        elif property_name == 'start_year':
            # check type
            try:
                check_type(self.get(property_name), int)
            except TypeError as e:
                raise TypeError('Invalid {0}: {1}'.format(property_name, e))
            # assert equals 2014
            if self.start_year != 2014:
                raise ValueError(
                    'Invalid {}: must be set to 2014'.format(property_name))

        elif property_name == 'input_scenarios':
            # check type
            try:
                check_type(self.get(property_name), list)
            except TypeError as e:
                raise TypeError('Invalid {0}: {1}'.format(property_name, e))
            if len(self.input_scenarios) == 0:
                raise ValueError(
                    "Invalid {}: No input scenario spreadsheet were found in the input_scenarios folder.".format(property_name))

        elif property_name == 'pg_params_file':
            # check type
            try:
                check_type(self.get(property_name), str)
            except TypeError as e:
                raise TypeError('Invalid {0}: {1}'.format(property_name, e))
            # check the path exists
            if os.path.exists(self.pg_params_file) == False:
                raise ValueError('Invalid {}: does not exist'.format(property_name))

        elif property_name == 'role':
            # check type
            try:
                check_type(self.get(property_name), str)
            except TypeError as e:
                raise TypeError('Invalid {0}: {1}'.format(property_name, e))

            valid_options = ["postgres","diffusion-writers"]

            if self.role not in valid_options:
                raise ValueError("Invalid Database {0} as Database Role not supported. Valid options are: '{1}' but role currently set is: '{2}'".format(
                    property_name, valid_options[0], self.role))

        elif property_name in ['pg_params','pg_engine_params']:
            # check type
            try:
                check_type(self.get(property_name), dict)
            except TypeError as e:
                raise TypeError('Invalid {0}: {1}'.format(property_name, e))
            # check for all values
            required_keys = set(['dbname',
                                 'host',
                                 'port',
                                 'password',
                                 'user'])
            if set(self.pg_params.keys()).issubset(required_keys) == False:
                raise ValueError('Invalid {0}: missing required keys ({1})'.format(
                    property_name, required_keys))

        elif property_name in ['pg_conn_string','pg_engine_string']:
            # check type
            try:
                check_type(self.get(property_name), str)
            except TypeError as e:
                raise TypeError('Invalid {0}: {1}'.format(property_name, e))

        elif property_name == 'pg_params_log':
            # check type
            try:
                check_type(self.get(property_name), str)
            except TypeError as e:
                raise TypeError('Invalid {0}: {1}'.format(property_name, e))
            # check password is not included
            if 'password' in self.pg_params_log:
                raise ValueError(
                    'Invalid {}: password shoud not be included'.format(property_name))

        elif property_name == 'model_path':
            # check type
            try:
                check_type(self.get(property_name), str)
            except TypeError as e:
                raise TypeError('Invalid {0}: {1}'.format(property_name, e))
            # check the path exists
            if os.path.exists(self.model_path) == False:
                raise ValueError('Invalid {}: does not exist'.format(property_name))

        elif property_name == 'local_cores':
            # check type
            try:
                check_type(self.get(property_name), int)
            except TypeError as e:
                raise TypeError('Invalid {0}: {1}'.format(property_name, e))
            # check if too large
            if self.local_cores > multiprocessing.cpu_count():
                raise ValueError(
                    'Invalid {}: value exceeds number of CPUs on local machine'.format(property_name))

        elif property_name == 'pg_procs':
            # check type
            try:
                check_type(self.get(property_name), int)
            except TypeError as e:
                raise TypeError('Invalid {0}: {1}'.format(property_name, e))
            # warn if too large
            if self.pg_procs > 16:
                warnings.warn(
                    "High {}: may saturate the resources of the Postgres server".format(property_name))

        elif property_name == 'delete_output_schema':
            # check type
            try:
                check_type(self.get(property_name), bool)
            except TypeError as e:
                raise TypeError('Invalid {0}: {1}'.format(property_name, e))
                
        elif property_name == 'dynamic_system_sizing':
            # check type
            try:
                check_type(self.get(property_name), bool)
            except TypeError as e:
                raise TypeError('Invalid {0}: {1}'.format(property_name, e))

        else:
            print('No validation method for property {} exists.'.format(property_name))

    def validate(self):

        property_names = list(self.__dict__.keys())
        for property_name in property_names:
            self.validate_property(property_name)

        return


#%%
class ScenarioSettings(object):
    
    """Storage of all scenario specific inputs"""

    def __init__(self):

        self.scen_name = None  # type is text, no spaces?
        self.end_year = None
        self.region = None
        self.load_growth = None  # valid options only
        self.random_generator_seed = None  # int
        self.sectors = None  # valid options only
        self.techs = None  # valid options only
        self.input_scenario = None  # exists on disk
        self.schema = None  # string
        self.agent_file_status = None # valid options onl
        self.model_years = None  # starts at 2014 and ends <= 2050
        self.tech_mode = None  # valid options only
        self.state_to_model = None # valid state

    def set(self, attr, value):

        self.__setattr__(attr, value)
        self.validate_property(attr)

    def get(self, attr):

        return self.__getattribute__(attr)

    def add_scenario_options(self, scenario_options):

        self.set('scen_name', scenario_options['scenario_name'])
        self.set('end_year', scenario_options['end_year'])
        self.set('region', scenario_options['region'])
        self.set('load_growth', scenario_options[
                 'load_growth'])
        self.set('random_generator_seed', scenario_options[
                 'random_generator_seed'])

    def set_tech_mode(self):

        if sorted(self.techs) in [['wind'], ['solar']]:
            self.set('tech_mode', 'elec')

        elif self.techs == ['du']:
            self.set('tech_mode', 'du')

        elif self.techs == ['ghp']:
            self.set('tech_mode', 'ghp')

    def validate_property(self, property_name):

        # check not null
        if self.get(property_name) == None:
            raise ValueError('{} has not been set'.format(property_name))

        if property_name == 'scen_name':
            # check type
            try:
                check_type(self.get(property_name), str)
            except TypeError as e:
                raise TypeError('Invalid {0}: {1}'.format(property_name, e))
            # confirm no spaces
            if ' ' in self.scen_name:
                raise ValueError(
                    'Invalid {}: cannot contain spaces.'.format(property_name))

        elif property_name == 'end_year':
            try:
                check_type(self.get(property_name), int)
            except TypeError as e:
                raise TypeError('Invalid {0}: {1}'.format(property_name, e))
            # max of 2050
            if self.end_year > 2050:
                raise ValueError(
                    'Invalid {}: end_year must be <= 2050'.format(property_name))

        elif property_name == 'region':
            try:
                check_type(self.get(property_name), str)
            except TypeError as e:
                raise TypeError('Invalid {0}: {1}'.format(property_name, e))

        elif property_name == 'load_growth':
            try:
                check_type(self.get(property_name), str)
            except TypeError as e:
                raise TypeError('Invalid {0}: {1}'.format(property_name, e))

        elif property_name == 'random_generator_seed':
            try:
                check_type(self.get(property_name), int)
            except TypeError as e:
                raise TypeError('Invalid {0}: {1}'.format(property_name, e))

        elif property_name == 'sectors':
            try:
                check_type(self.get(property_name), dict)
            except TypeError as e:
                raise TypeError('Invalid {0}: {1}'.format(property_name, e))
            # check all values are valid
            valid_sectors = set(
                [('res', 'Residential'),
                 ('com', 'Commercial'),
                 ('ind', 'Industrial')]
            )
            if set(self.sectors.items()).issubset(valid_sectors) == False:
                raise ValueError(
                    'Invalid: the only allowable sectors are res, com, ind.')
            # if only ind was selected and tehcmode is ghp or du, do not run
            if list(self.sectors.keys()) == ['ind'] and self.tech_mode in ('ghp', 'du'):
                raise ValueError('Invalid {0}: Cannot run industrial sector for {1}'.format(property_name, self.tech_mode))
                warnings.warn(
                    'Industrial sector cannot be modeled for geothermal technologies at this time.')
            # drop 'ind' sector if selected for geo
            if list(self.sectors.keys()) != ['ind'] and 'ind' in list(self.sectors.keys()) and self.tech_mode in ('ghp', 'du'):
                self.sectors.pop('ind')
                warnings.warn(
                    'Industrial sector cannot be modeled for geothermal technologies at this time and will be ignored.')

        elif property_name == 'techs':
            try:
                check_type(self.get(property_name), list)
            except TypeError as e:
                raise TypeError('Invalid {0}: {1}'.format(property_name, e))

            valid_options = [
                ['wind'],
                ['solar'],
                ['du'],
                ['ghp']
            ]
            if sorted(self.techs) not in valid_options:
                raise ValueError("Invalid {0}: Cannot currently run that combination of technologies. Valid options are: {1}".format(
                    property_name, valid_options))

        elif property_name == 'agent_file_status':
            try:
                check_type(self.get(property_name), str)
            except TypeError as e:
                raise TypeError('Invalid {0}: {1}'.format(property_name, e))

        elif property_name == 'state_to_model':
            try:
                check_type(self.get(property_name), list)
            except TypeError as e:
                raise TypeError('Invalid {0}: {1}'.format(property_name, e))

        elif property_name == 'input_scenario':
            try:
                check_type(self.get(property_name), str)
            except TypeError as e:
                raise TypeError('Invalid {0}: {1}'.format(property_name, e))
            # check the path exists
            if os.path.exists(self.input_scenario) == False:
                raise ValueError('Invalid {}: does not exist'.format(property_name))

        elif property_name == 'schema':
            try:
                check_type(self.get(property_name), str)
            except TypeError as e:
                raise TypeError('Invalid {0}: {1}'.format(property_name, e))

        elif property_name == 'model_years':
            try:
                check_type(self.get(property_name), list)
            except TypeError as e:
                raise TypeError('Invalid {0}: {1}'.format(property_name, e))
            # sort ascending
            self.model_years.sort()
            # make sure starts at 2014
            if self.model_years[0] != 2014:
                raise ValueError(
                    'Invalid {}: Must begin with 2014.'.format(property_name))
            # last year must be <= 2050
            if self.model_years[-1] > 2050:
                raise ValueError(
                    'Invalid {}: End year must be <= 2050.'.format(property_name))

        elif property_name == 'tech_mode':
            try:
                check_type(self.get(property_name), str)
            except TypeError as e:
                raise TypeError('Invalid {0}: {1}'.format(property_name, e))
            # check valid options
            valid_options = ['elec',
                             'ghp',
                             'du']
            if self.tech_mode not in valid_options:
                raise ValueError('Invalid {0}: must be one of {1}'.format(property_name, valid_options))

        else:
            print('No validation method for property {} exists.'.format(property_name))

    def validate(self):

        property_names = list(self.__dict__.keys())
        for property_name in property_names:
            self.validate_property(property_name)

        return


def check_type(obj, expected_type):

    if isinstance(obj, expected_type) == False:
        raise TypeError('object type ({0}) does not match expected type ({1})'.format(type(obj), expected_type))


def init_model_settings():
    """initialize Model Settings object (this controls settings that apply to all scenarios to be executed)"""
    # initialize Model Settings object (this controls settings that apply to
    # all scenarios to be executed)
    model_settings = ModelSettings()

    # add the config to model settings; set model starting time, output directory based on run time, etc.
    model_settings.add_config(config)
    model_settings.set('model_init', utilfunc.get_epoch_time())
    model_settings.set('cdate', utilfunc.get_formatted_time())
    model_settings.set('out_dir', datfunc.make_output_directory_path(model_settings.cdate))
    model_settings.set('input_data_dir', '{}/input_data'.format(os.path.dirname(os.getcwd())))
    model_settings.set('input_agent_dir', '{}/input_agents'.format(os.path.dirname(os.getcwd())))
    model_settings.set('input_scenarios', datfunc.get_input_scenarios())
    # validate all model settings
    model_settings.validate()

    return model_settings


def init_scenario_settings(scenario_file, model_settings, con, cur):
    """load scenario specific data and configure output settings"""
    scenario_settings = ScenarioSettings()
    scenario_settings.set('input_scenario', scenario_file)

    logger.info("-------------Preparing Database-------------")
    # =========================================================================
    # DEFINE SCENARIO SETTINGS
    # =========================================================================
    try:
        # create an empty schema from diffusion_template
        new_schema = datfunc.create_output_schema(model_settings.pg_conn_string, model_settings.role, model_settings.cdate, model_settings.input_scenarios, source_schema = 'diffusion_template', include_data = False)
    except Exception as e:
        raise Exception('\tCreation of output schema failed with the following error: {}'.format(e))

    # set the schema
    scenario_settings.set('schema', new_schema)

    # load Input Scenario to the new schema
    try:
        excel_functions.load_scenario(scenario_settings.input_scenario, scenario_settings.schema, con, cur)
    except Exception as e:
        raise Exception('\tLoading failed with the following error: {}'.format(e))

    # read in high level scenario settings
    scenario_settings.set('techs', datfunc.get_technologies(con, scenario_settings.schema))

    # read in settings whether to use pre-generated agent file ('User Defined'- provide pkl file name) or generate new agents
    scenario_settings.set('agent_file_status', datfunc.get_agent_file_scenario(con, scenario_settings.schema))

    # Set scenario output dir

    # set tech_mode
    scenario_settings.set_tech_mode()
    scenario_settings.set('sectors', datfunc.get_sectors(cur, scenario_settings.schema))
    scenario_settings.add_scenario_options(datfunc.get_scenario_options(cur, scenario_settings.schema, model_settings.pg_params))
    scenario_settings.set('model_years', datfunc.create_model_years(model_settings.start_year, scenario_settings.end_year))
    scenario_settings.set('state_to_model', datfunc.get_state_to_model(con, scenario_settings.schema))
    # validate scenario settings
    scenario_settings.validate()

    return scenario_settings
