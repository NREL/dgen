# -*- coding: utf-8 -*-
"""

Deprecated. Nullified by new PySAM code and will be taken out in Beta release.

"""

import requests as req
import numpy as np
import pandas as pd
import codecs
import json
import csv
import logging
logging.getLogger("requests").setLevel(logging.WARNING)


#%%
# Load configuration file, if one exists.
def load_config_params(config_file_name):
    '''
    Each user should fill in a config_template.json file.
    '''
    
    config = json.load(open('config.json','r'))
    
    return config


#%%
class Tariff:
    """
    Tariff Attributes:
    -urdb_id: id for utility rate database. US, not international. 
    -eia_id: The EIA assigned ID number for the utility associated with this tariff           
    -name: tariff name
    -utility: Name of utility this tariff is associated with
    -fixed_charge: Fixed monthly charge in $/mo.
    -peak_kW_capacity_max: The annual maximum kW of demand that a customer can have and still be on this tariff
    -peak_kW_capacity_min: The annula minimum kW of demand that a customer can have and still be on this tariff
    -kWh_useage_max: The maximum kWh of average monthly consumption that a customer can have and still be on this tariff
    -kWh_useage_min: The minimum kWh of average monthly consumption that a customer can have and still be on this tariff
    -sector: residential, commercial, or industrial
    -comments: comments from the urdb
    -description: tariff description from urdb
    -source: uri for the source of the tariff
    -uri: link the the urdb page
    -voltage_category: secondary, primary, transmission        
    -d_flat_exists: Boolean of whether there is a flat (not tou) demand charge component. Flat demand is also called monthly or seasonal demand. 
    -d_flat_n: Number of unique flat demand period constructions. Does NOT correspond to width of d_flat_x constructs.
    -d_flat_prices: The prices of each tier/period combination for flat demand. Rows are tiers, columns are months. Differs from TOU, where columns are periods.
    -d_flat_levels: The limit (total kW) of each of each tier/period combination for flat demand. Rows are tiers, columns are months. Differs from TOU, where columns are periods.
    -d_tou_exists = Boolean of whether there is a tou (not flat) demand charge component
    -d_tou_n = Number of unique tou demand periods. Minimum of 1, since I'm counting no-charge periods still as a period.
    -d_tou_prices = The prices of each tier/period combination for tou demand. Rows are tiers, columns are periods.    
    -d_tou_levels = The limit (total kW) of each of each tier/period combination for tou demand. Rows are tiers, columns are periods.
    -e_exists = Boolean of whether there is a flat (not tou) demand charge component
    -e_tou_exists = Boolean of whether there is a flat (not tou) demand charge component
    -e_n = Number of unique energy periods. Minimum of 1, since I'm counting no-charge periods still as a period.
    -e_prices = The prices of each tier/period combination for flat demand. Rows are tiers, columns are periods.    
    -e_levels = The limit (total kWh) of each of each tier/period combination for energy. Rows are tiers, columns are periods.
    -e_wkday_12by24: 12 by 24 period definition for weekday energy. Rows are months, columns are hours.
    -e_wkend_12by24: 12 by 24 period definition for weekend energy. Rows are months, columns are hours.
    -d_wkday_12by24: 12 by 24 period definition for weekday energy. Rows are months, columns are hours.
    -d_wkend_12by24: 12 by 24 period definition for weekend energy. Rows are months, columns are hours.
    -d_tou_8760
    -e_tou_8760
    -e_prices_no_tier
    -e_max_difference: The maximum energy price differential within any single day
    -energy_rate_unit: kWh or kWh/day - for guiding the bill calculations later
    -demand_rate_unit: kW or kW/day - for guiding the bill calculations later
    """
        
    def __init__(self, start_day=6, urdb_id=None, json_file_name=None, dict_obj=None, api_key=None):
                   
        #######################################################################
        ##### If given no urdb id or csv file name, create blank tariff #######
        #######################################################################
                   
        if urdb_id==None and json_file_name==None and isinstance(dict_obj,type(None)):
            # Default values for a blank tariff
            self.urdb_id = 'No urdb id given'               
            self.name = 'User defined tariff - no name specified'
            self.utility = 'User defined tariff - no name specified'
            self.fixed_charge = 0
            self.peak_kW_capacity_max = 1e99
            self.peak_kW_capacity_min = 0
            self.kWh_useage_max = 1e99
            self.kWh_useage_min = 0
            self.sector = 'No sector specified'
            self.comments = 'No comments given'
            self.description = 'No description given'
            self.source = 'No source given'
            self.uri = 'No uri given'
            self.voltage_category = 'No voltage category given' 
            self.eia_id = 'No eia id given' 
            self.demand_rate_unit = 'kW'
            self.energy_rate_unit = 'kWh'
            self.start_day = 6
            
            
            ###################### Blank Flat Demand Structure ########################
            self.d_flat_exists = False
            self.d_flat_n = 0
            self.d_flat_prices = np.zeros([1, 12])     
            self.d_flat_levels = np.zeros([1, 12])
            self.d_flat_levels[:,:] = 1e9
                
            
            #################### Blank Demand TOU Structure ###########################
            self.d_tou_exists = False
            self.d_tou_n = 1
            self.d_tou_prices = np.zeros([1, 1])     
            self.d_tou_levels = np.zeros([1, 1])
            
            
            ################ Blank Coincident Peak Structure ##################
            self.coincident_peak_exists = False            

            
            ######################## Blank Energy Structure ###########################
            self.e_exists = False
            self.e_tou_exists = False
            self.e_n = 1
            self.e_prices = np.zeros([1, 1])     
            self.e_levels = np.zeros([1, 1])
            
                
            ######################## Blank Schedules ###########################
            self.e_wkday_12by24 = np.zeros([12,24], int)
            self.e_wkend_12by24 = np.zeros([12,24], int)
            self.d_wkday_12by24 = np.zeros([12,24], int)
            self.d_wkend_12by24 = np.zeros([12,24], int)
            
            
            ################### Blank 12x24s as 8760s Schedule ########################
            self.d_tou_8760 = np.zeros(8760, int)
            self.e_tou_8760 = np.zeros(8760, int)
            
            
            ######################## Precalculations ######################################
            self.e_prices_no_tier = np.zeros([1, 1])
            self.e_max_difference = np.zeros([1, 1])

        
        #######################################################################
        # If given a urdb_id input argument, obtain and reshape that tariff through the URDB API 
        #######################################################################
        elif urdb_id != None:

            if api_key == None: 
                print("No URDB API key defined.")
            
            input_params = {'version':3,
                        'format':'json',
                        'detail':'full',
                        'getpage':urdb_id,
                        'api_key':api_key}
                        
            r = req.get('http://api.openei.org/utility_rates?', params=input_params)
        
            content = r.content
            tariff_original = json.loads(content, strict=False)['items'][0]

            if 'demandrateunit' in tariff_original: self.demand_rate_unit = tariff_original['demandrateunit']
            else: self.demand_rate_unit = 'kW'  
              
            if 'eiaid' in tariff_original: self.eia_id = tariff_original['eiaid']
            else: self.eia_id = 'No eia id given'                 
                
            if 'label' in tariff_original: self.urdb_id = tariff_original['label']
            else: self.urdb_id = 'No urdb id given'            
            
            if 'name' in tariff_original: self.name = tariff_original['name']
            else: self.name = 'No name specified'
                
            if 'utility' in tariff_original: self.utility = tariff_original['utility']
            else: self.utility = 'No utility specified'
                
            if 'fixedmonthlycharge' in tariff_original: self.fixed_charge = tariff_original['fixedmonthlycharge']
            else: self.fixed_charge = 0
                
            if 'peakkwcapacitymax' in tariff_original: self.peak_kW_capacity_max = tariff_original['peakkwcapacitymax']
            else: self.peak_kW_capacity_max = 1e99
                
            if 'peakkwcapacitymin' in tariff_original: self.peak_kW_capacity_min = tariff_original['peakkwcapacitymin']
            else: self.peak_kW_capacity_min = 0
                
            if 'peakkwhusagemax' in tariff_original: self.kWh_useage_max = tariff_original['peakkwhusagemax']
            else: self.kWh_useage_max = 1e99
                
            if 'peakkwhusagemin' in tariff_original: self.kWh_useage_min = tariff_original['peakkwhusagemin']
            else: self.kWh_useage_min = 0
                
            if 'sector' in tariff_original: self.sector = tariff_original['sector']
            else: self.sector = 'No sector given'
                
            if 'basicinformationcomments' in tariff_original: self.comments = tariff_original['basicinformationcomments']
            else: self.comments = 'No comments'

            if 'description' in tariff_original: self.description = tariff_original['description']
            else: self.description = 'No description'
                
            if 'source' in tariff_original: self.source = tariff_original['source']
            else: self.source = 'No source given'

            if 'uri' in tariff_original: self.uri = tariff_original['uri']
            else: self.uri = 'No uri given'
                
            if 'voltage_category' in tariff_original: self.voltage_category = tariff_original['voltage_category']
            else: self.voltage_category = 'No voltage category given'
                 
            
            ###################### Repackage Flat Demand Structure ########################
            if 'flatdemandstructure' in tariff_original:
                self.d_flat_exists = True
                d_flat_structure = tariff_original['flatdemandstructure']
                d_flat_month_indicies = tariff_original['flatdemandmonths']
                self.d_flat_n = np.min([len(np.unique(tariff_original['flatdemandmonths'])), len(d_flat_structure)])
                
                # Clip indicies so they are within the given array size (only occurs when tariff was entered into URDB incorrectly)       
                d_flat_month_indicies = np.clip(d_flat_month_indicies, 0, self.d_flat_n-1)
                
                # Determine the maximum number of tiers in the demand structure
                max_tiers = 1
                for period in range(self.d_flat_n):
                    n_tiers = len(d_flat_structure[period])
                    if n_tiers > max_tiers: max_tiers = n_tiers
                
                # Repackage Energy TOU Structure   
                self.d_flat_prices = np.zeros([max_tiers, 12])     
                self.d_flat_levels = np.zeros([max_tiers, 12])
                self.d_flat_levels[:,:] = 1e9
                for month in range(12):
                    for tier in range(len(d_flat_structure[period])):
                        self.d_flat_levels[tier, month] = d_flat_structure[d_flat_month_indicies[month]][tier].get('max', 1e9)
                        self.d_flat_prices[tier, month] = d_flat_structure[d_flat_month_indicies[month]][tier].get('rate', 0) + d_flat_structure[d_flat_month_indicies[month]][tier].get('adj', 0)
            else:
                self.d_flat_exists = False
                self.d_flat_n = 1
                self.d_flat_prices = np.zeros([1, 12])     
                self.d_flat_levels = np.zeros([1, 12])
                self.d_flat_levels[:,:] = 1e9
            
            #################### Repackage Demand TOU Structure ###########################
            if 'demandratestructure' in tariff_original:
                demand_structure = tariff_original['demandratestructure']
                self.d_tou_n = len(demand_structure)
                if self.d_tou_n > 1: self.d_tou_exists = True
                else: 
                    self.d_tou_exists = False
                    self.d_flat_exists = True
                
                # Determine the maximum number of tiers in the demand structure
                max_tiers = 1
                for period in range(self.d_tou_n):
                    n_tiers = len(demand_structure[period])
                    if n_tiers > max_tiers: max_tiers = n_tiers
                
                # Repackage Demand TOU Structure   
                self.d_tou_prices = np.zeros([max_tiers, self.d_tou_n])     
                self.d_tou_levels = np.zeros([max_tiers, self.d_tou_n])
                self.d_tou_levels[:,:] = 1e9
                for period in range(self.d_tou_n):
                    for tier in range(len(demand_structure[period])):
                        self.d_tou_levels[tier, period] = demand_structure[period][tier].get('max', 1e9)
                        self.d_tou_prices[tier, period] = demand_structure[period][tier].get('rate', 0) + demand_structure[period][tier].get('adj', 0)
            else:
                self.d_tou_exists = False
                self.d_tou_n = 1
                self.d_tou_prices = np.zeros([1, 1])     
                self.d_tou_levels = np.zeros([1, 1])
            
            ######################## No Coincident Peak from URDB #############
            self.coincident_peak_exists = False
            
            
            ######################## Repackage Energy Structure ###########################
            if 'energyratestructure' in tariff_original:
                self.e_exists = True
                energy_structure = tariff_original['energyratestructure']
                self.energy_rate_unit = energy_structure[0][0].get('unit','kWh')
                self.e_n = len(energy_structure)
                if self.e_n > 1: self.e_tou_exists = True
                else: self.e_tou_exists = False
                
                # Determine the maximum number of tiers in the demand structure
                max_tiers = 1
                for period in range(self.e_n):
                    n_tiers = len(energy_structure[period])
                    if n_tiers > max_tiers: max_tiers = n_tiers
                
                # Repackage Energy TOU Structure   
                self.e_prices = np.zeros([max_tiers, self.e_n])     
                self.e_levels = np.zeros([max_tiers, self.e_n])
                self.e_levels[:,:] = 1e9
                for period in range(self.e_n):
                    for tier in range(len(energy_structure[period])):
                        self.e_levels[tier, period] = energy_structure[period][tier].get('max', 1e9)
                        self.e_prices[tier, period] = energy_structure[period][tier].get('rate', 0) + energy_structure[period][tier].get('adj', 0)
            else:
                self.e_exists = False
                self.e_tou_exists = False
                self.e_n = 0
                self.e_prices = np.zeros([1, 1])     
                self.e_levels = np.zeros([1, 1])
                self.energy_rate_unit = 'kWh'
                
            ######################## Repackage Energy Schedule ###########################
            self.e_wkday_12by24 = np.zeros([12,24], int)
            self.e_wkend_12by24 = np.zeros([12,24], int)
            
            if 'energyweekdayschedule' in tariff_original:
                for month in range(12):
                    self.e_wkday_12by24[month, :] = tariff_original['energyweekdayschedule'][month]
                    self.e_wkend_12by24[month, :] = tariff_original['energyweekendschedule'][month]
                    
            # If the urdb 12by24 has a period that isn't defined in the tiers,
            # set that period to the 0th tier.
            max_e_period_in_matrix = np.max([self.e_wkday_12by24, self.e_wkend_12by24])
            max_e_period_in_prices = np.shape(self.e_prices)[1]
            for period in np.arange(max_e_period_in_prices, max_e_period_in_matrix+1, 1):
                self.e_wkday_12by24[self.e_wkday_12by24==period] = 0
                self.e_wkend_12by24[self.e_wkend_12by24==period] = 0
            
            ######################## Repackage Demand Schedule ###########################
            self.d_wkday_12by24 = np.zeros([12,24], int)
            self.d_wkend_12by24 = np.zeros([12,24], int)
            
            if 'demandweekdayschedule' in tariff_original:
                for month in range(12):
                    self.d_wkday_12by24[month, :] = tariff_original['demandweekdayschedule'][month]
                    self.d_wkend_12by24[month, :] = tariff_original['demandweekendschedule'][month]
                    
            # If the urdb 12by24 has a period that isn't defined in the tiers,
            # set that period to the 0th tier.
            max_d_period_in_matrix = np.max([self.d_wkday_12by24, self.d_wkend_12by24])
            max_d_period_in_prices = np.shape(self.d_tou_prices)[1]
            for period in np.arange(max_d_period_in_prices, max_d_period_in_matrix+1, 1):
                self.d_wkday_12by24[self.d_wkday_12by24==period] = 0
                self.d_wkend_12by24[self.d_wkend_12by24==period] = 0
            
            ################### Repackage 12x24s as 8760s Schedule ########################
            self.start_day = start_day                               
            self.d_tou_8760 = build_8760_from_12by24s(self.d_wkday_12by24, self.d_wkend_12by24, self.start_day)
            self.e_tou_8760 = build_8760_from_12by24s(self.e_wkday_12by24, self.e_wkend_12by24, self.start_day)

            
            ######################## Precalculations ######################################
            # Collapse the tiered price matrix down to just the maximum cost
            # in each tier, to be used during dispatch.
            self.e_prices_no_tier = np.max(self.e_prices, 0)
            
            # Determine the maximum differential in energy price within a day.
            e_12by24_max_prices_wkday = self.e_prices_no_tier[self.e_wkday_12by24]
            e_12by24_max_prices_wkend = self.e_prices_no_tier[self.e_wkend_12by24]
            e_max_price_differential_wkday = np.max(e_12by24_max_prices_wkday, 1) - np.min(e_12by24_max_prices_wkday, 1)
            e_max_price_differential_wkend = np.max(e_12by24_max_prices_wkend, 1) - np.min(e_12by24_max_prices_wkend, 1)
            self.e_max_difference = np.max([e_max_price_differential_wkday, e_max_price_differential_wkend])

        
        #######################################################################
        # If given a json input argument, construct a tariff from that file
        #######################################################################    
        elif json_file_name != None:
            
            obj_text = codecs.open(json_file_name, 'r', encoding='utf-8').read()
            d = json.loads(obj_text)
            for fieldname in list(d.keys()):
                if isinstance(d[fieldname], list):
                    d[fieldname] = np.array(d[fieldname])
                
            if 'urdb_id' in d: self.urdb_id = d['urdb_id']
            if 'name' in d: self.name = d['name']
            if 'utility' in d: self.utility = d['utility']
            if 'fixed_charge' in d: self.fixed_charge = d['fixed_charge']
            if 'peak_kW_capacity_max' in d: self.peak_kW_capacity_max = d['peak_kW_capacity_max']
            if 'peak_kW_capacity_min' in d: self.peak_kW_capacity_min = d['peak_kW_capacity_min']
            if 'kWh_useage_max' in d: self.kWh_useage_max = d['kWh_useage_max']
            if 'kWh_useage_min' in d: self.kWh_useage_min = d['kWh_useage_min']
            if 'sector' in d: self.sector = d['sector']
            if 'comments' in d: self.comments = d['comments']
            if 'description' in d: self.description = d['description']
            if 'source' in d: self.source = d['source']
            if 'uri' in d: self.uri = d['uri']
            if 'source' in d: self.source = d['source']
            if 'voltage_category' in d: self.voltage_category = d['voltage_category']
            if 'eia_id' in d: self.eia_id = d['eia_id']
            if 'energy_rate_unit' in d: self.energy_rate_unit = d['energy_rate_unit']
            if 'max_demand_charge' in d: self.max_demand_charge = d['max_demand_charge']
            
            
            ###################### Blank Flat Demand Structure ########################
            if 'd_flat_exists' in d: self.d_flat_exists = d['d_flat_exists']
            if 'd_flat_prices' in d: self.d_flat_prices = d['d_flat_prices']
            if 'd_flat_levels' in d: self.d_flat_levels = d['d_flat_levels']
            if 'd_flat_n' in d: self.d_flat_n = d['d_flat_n']
                
            
            #################### Blank Demand TOU Structure ###########################
            if 'd_tou_exists' in d: self.d_tou_exists = d['d_tou_exists']
            if 'd_tou_n' in d: self.d_tou_n = d['d_tou_n']
            if 'd_tou_prices' in d: self.d_tou_prices = d['d_tou_prices']
            if 'd_tou_levels' in d: self.d_tou_levels = d['d_tou_levels']

            
            #################### Coincident Peak Structure ###########################            
            if 'coincident_peak_exists' in d: self.coincident_peak_exists = d['coincident_peak_exists']
            else: self.coincident_peak_exists = False
            
            if 'coincident_style' in d: self.coincident_style = d['coincident_style']
            if 'coincident_hour_def' in d: self.coincident_hour_def = d['coincident_hour_def']
            if 'coincident_prices' in d: self.coincident_prices = d['coincident_prices']
            if 'coincident_levels' in d: self.coincident_levels = d['coincident_levels']
            if 'coincident_monthly_periods' in d: self.coincident_monthly_periods = d['coincident_monthly_periods']
            
            
            ######################## Blank Energy Structure ###########################
            if 'e_exists' in d: self.e_exists = d['e_exists']
            if 'e_tou_exists' in d: self.e_tou_exists = d['e_tou_exists']
            if 'e_n' in d: self.e_n = d['e_n']
            if 'e_prices' in d: self.e_prices = d['e_prices']
            if 'e_levels' in d: self.e_levels = d['e_levels']
            
                
            ######################## Blank Schedules ###########################
            if 'e_wkday_12by24' in d: self.e_wkday_12by24 = d['e_wkday_12by24']
            if 'e_wkend_12by24' in d: self.e_wkend_12by24 = d['e_wkend_12by24']
            if 'd_wkday_12by24' in d: self.d_wkday_12by24 = d['d_wkday_12by24']
            if 'd_wkend_12by24' in d: self.d_wkend_12by24 = d['d_wkend_12by24']
            
            
            ################### Blank 12x24s as 8760s Schedule ########################
            if 'd_tou_8760' in d: self.d_tou_8760 = d['d_tou_8760']
            if 'e_tou_8760' in d: self.e_tou_8760 = d['e_tou_8760']
            
            
            ######################## Precalculations ######################################
            if 'e_prices_no_tier' in d: self.e_prices_no_tier = d['e_prices_no_tier']
            if 'e_max_difference' in d: self.e_max_difference = d['e_max_difference']
            if 'start_day' in d: self.start_day = d['start_day']

            
        #######################################################################
        # If given a dict input, construct a tariff from that object
        #######################################################################    
        elif not isinstance(dict_obj,type(None)):
            if 'start_day' in dict_obj: self.start_day = dict_obj['start_day']
            else: self.start_day = 6

            if 'urdb_id' in dict_obj: self.urdb_id = dict_obj['urdb_id']
            if 'name' in dict_obj: self.name = dict_obj['name']
            if 'utility' in dict_obj: self.utility = dict_obj['utility']
            if 'sector' in dict_obj: self.sector = dict_obj['sector']
            if 'comments' in dict_obj: self.comments = dict_obj['comments']
            if 'description' in dict_obj: self.description = dict_obj['description']
            if 'source' in dict_obj: self.source = dict_obj['source']
            if 'uri' in dict_obj: self.uri = dict_obj['uri']
            if 'voltage_category' in dict_obj: self.voltage_category = dict_obj['voltage_category']
            if 'fixed_charge' in dict_obj: self.fixed_charge = dict_obj['fixed_charge']
            if 'peak_kW_capacity_max' in dict_obj: self.peak_kW_capacity_max = dict_obj['peak_kW_capacity_max']
            if 'peak_kW_capacity_min' in dict_obj: self.peak_kW_capacity_min = dict_obj['peak_kW_capacity_min']
            if 'kWh_useage_max' in dict_obj: self.kWh_useage_max = dict_obj['kWh_useage_max']
            if 'kWh_useage_min' in dict_obj: self.kWh_useage_min = dict_obj['kWh_useage_min']
            if 'eia_id' in dict_obj: self.eia_id = dict_obj['eia_id']
            if 'demand_rate_unit' in dict_obj: self.demand_rate_unit = dict_obj['demand_rate_unit']
            if 'energy_rate_unit' in dict_obj: self.energy_rate_unit = dict_obj['energy_rate_unit']


            ###################### Flat Demand Structure ########################
            if 'd_flat_exists' in dict_obj: self.d_flat_exists = dict_obj['d_flat_exists']
            if 'd_flat_n' in dict_obj: self.d_flat_n = dict_obj['d_flat_n']
            if 'd_flat_prices' in dict_obj: 
                self.d_flat_prices = np.array(dict_obj['d_flat_prices'])
                if 'd_flat_levels' in dict_obj: self.d_flat_levels = np.array(dict_obj['d_flat_levels'])
                else: self.d_flat_levels = np.zeros([1,np.shape(self.d_flat_prices)[1]]) + 1e9
            
            #################### Demand TOU Structure ###########################
            if 'd_tou_exists' in dict_obj: self.d_tou_exists = dict_obj['d_tou_exists']
            if 'd_tou_n' in dict_obj: self.d_tou_n = dict_obj['d_tou_n']
            if 'd_tou_prices' in dict_obj: 
                self.d_tou_prices = np.array(dict_obj['d_tou_prices'])    
                if 'd_tou_levels' in dict_obj: self.d_tou_levels = np.array(dict_obj['d_tou_levels'])
                else: self.d_tou_levels = np.zeros([1,np.shape(self.d_tou_prices)[1]]) + 1e9

            #################### Coincident Peak Structure ###########################            
            if 'coincident_style' in dict_obj: self.coincident_style = dict_obj['coincident_style']
            if 'coincident_hour_def' in dict_obj: self.coincident_hour_def = dict_obj['coincident_hour_def']
            if 'coincident_prices' in dict_obj: self.coincident_prices = dict_obj['coincident_prices']
            if 'coincident_levels' in dict_obj: self.coincident_levels = dict_obj['coincident_levels']
            if 'coincident_monthly_periods' in dict_obj: self.coincident_monthly_periods = dict_obj['coincident_monthly_periods']
            
            
            ######################## Energy Structure ###########################
            if 'e_exists' in dict_obj: self.e_exists = dict_obj['e_exists']
            if 'e_tou_exists' in dict_obj: self.e_tou_exists = dict_obj['e_tou_exists']
            if 'e_n' in dict_obj: self.e_n = dict_obj['e_n']
            if 'e_prices' in dict_obj: 
                self.e_prices = np.array(dict_obj['e_prices'])   
                if 'e_levels' in dict_obj: self.e_levels = np.array(dict_obj['e_levels'])
                else: self.e_levels = np.zeros([1,np.shape(self.e_prices)[1]]) + 1e9
                
            ######################## Schedules ###########################
            if 'e_wkday_12by24' in dict_obj: self.e_wkday_12by24 = np.array(dict_obj['e_wkday_12by24'])
            if 'e_wkend_12by24' in dict_obj: self.e_wkend_12by24 = np.array(dict_obj['e_wkend_12by24'])
            if 'd_wkday_12by24' in dict_obj: self.d_wkday_12by24 = np.array(dict_obj['d_wkday_12by24'])
            if 'd_wkend_12by24' in dict_obj: self.d_wkend_12by24 = np.array(dict_obj['d_wkend_12by24'])
            
            # If the 12by24 has a period that isn't defined in the tiers,
            # set that period to the 0th tier.
            if 'e_wkday_12by24' in dict_obj:
                max_e_period_in_matrix = np.max([self.e_wkday_12by24, self.e_wkend_12by24])
                max_e_period_in_prices = np.shape(self.e_prices)[1]
                for period in np.arange(max_e_period_in_prices, max_e_period_in_matrix+1, 1):
                    self.e_wkday_12by24[self.e_wkday_12by24==period] = 0
                    self.e_wkend_12by24[self.e_wkend_12by24==period] = 0
                
            # If the 12by24 has a period that isn't defined in the tiers,
            # set that period to the 0th tier.
            if 'd_wkday_12by24' in dict_obj:    
                max_d_period_in_matrix = np.max([self.d_wkday_12by24, self.d_wkend_12by24])
                max_d_period_in_prices = np.shape(self.d_tou_prices)[1]
                for period in np.arange(max_d_period_in_prices, max_d_period_in_matrix+1, 1):
                    self.d_wkday_12by24[self.d_wkday_12by24==period] = 0
                    self.d_wkend_12by24[self.d_wkend_12by24==period] = 0
                   
            
            ################### 12x24s as 8760s Schedule ########################
            # Build 8760's. Note that any ingested 8760's will be ignored
            if 'd_wkday_12by24' in dict_obj:                             
                self.d_tou_8760 = build_8760_from_12by24s(self.d_wkday_12by24, self.d_wkend_12by24, self.start_day)
                
            if 'e_wkday_12by24' in dict_obj:
                self.e_tou_8760 = build_8760_from_12by24s(self.e_wkday_12by24, self.e_wkend_12by24, self.start_day)                 
            
            ######################## Precalculations ######################################
            if 'e_prices' in dict_obj: self.e_max_difference = np.max(self.e_prices) - np.min(self.e_prices)
            if 'e_prices' in dict_obj: self.e_prices_no_tier = np.max(self.e_prices, 0)

    
    #######################################################################
    # Write the current class object to a json file
    #######################################################################     
    def write_json(self, json_file_name):
        
        d = self.__dict__
                
        d_prep_for_json = d.copy()
        
        # change ndarray dtypes to lists, since json doesn't know ndarrays
        for fieldname in list(d_prep_for_json.keys()):
            if isinstance(d_prep_for_json[fieldname], np.ndarray):
                d_prep_for_json[fieldname] = d_prep_for_json[fieldname].tolist()
        
        with open(json_file_name, 'w') as fp:
            json.dump(d_prep_for_json, fp)
            
    #######################################################################
    # Define TOU demand charge periods, levels, and prices
    #######################################################################             
    def define_d_tou(self, d_wkday_12by24, d_wkend_12by24, d_tou_levels, d_tou_prices):
        
        self.d_tou_levels = d_tou_levels
        self.d_tou_prices = d_tou_prices
        self.d_wkday_12by24 = d_wkday_12by24
        self.d_wkend_12by24 = d_wkend_12by24
        self.d_tou_n = int(np.shape(d_tou_levels)[1])
        if np.count_nonzero(d_tou_prices) == 0: self.d_tou_exists = False
        else: self.d_tou_exists = True
                
        self.d_tou_8760 = build_8760_from_12by24s(d_wkday_12by24, d_wkend_12by24, self.start_day)


    #######################################################################
    # Define Flat demand charge periods, levels, and prices
    #######################################################################             
    def define_d_flat(self, d_flat_levels, d_flat_prices):
        
        # If it is only handed one value for levels and prices, it assumes that
        # value applies to all months
        if np.size(d_flat_prices) == 1:
            self.d_flat_levels = np.array([[d_flat_levels]]).repeat(12).reshape(1,12)
            self.d_flat_prices = np.array([[d_flat_prices]]).repeat(12).reshape(1,12)
            self.d_flat_n = 1
        else:
            self.d_flat_levels = d_flat_levels
            self.d_flat_prices = d_flat_prices
            self.d_flat_n = np.size(np.unique(d_flat_prices))
        

        if np.all(d_flat_prices==0): self.d_flat_exists = False
        else: self.d_flat_exists = True
            

    #######################################################################
    # Define energy periods, levels, and prices
    #######################################################################             
    def define_e(self, e_wkday_12by24, e_wkend_12by24, e_levels, e_prices):
        
        self.e_levels = e_levels
        self.e_prices = e_prices
        self.e_wkday_12by24 = e_wkday_12by24
        self.e_wkend_12by24 = e_wkend_12by24
        self.e_n = int(np.shape(e_levels)[1])
        
        if np.count_nonzero(e_prices) == 0: self.e_exists = False
        else: self.e_exists = True
        
        if np.any(e_wkday_12by24 != np.repeat(e_wkday_12by24[:,0],24).reshape(12,24)): # TODO: add weekends
            self.e_tou_exists = True
        else: 
            self.d_tou_exists = False
            
        self.e_tou_8760 = build_8760_from_12by24s(e_wkday_12by24, e_wkend_12by24, self.start_day)

                
        ######################## Precalculations ######################################
        # Collapse the tiered price matrix down to just the maximum cost
        # in each tier, to be used during dispatch.
        self.e_prices_no_tier = np.max(self.e_prices, 0)
        
        # Determine the maximum differential in energy price within a day.
        e_12by24_max_prices_wkday = self.e_prices_no_tier[self.e_wkday_12by24]
        e_12by24_max_prices_wkend = self.e_prices_no_tier[self.e_wkend_12by24]
        e_max_price_differential_wkday = np.max(e_12by24_max_prices_wkday, 1) - np.min(e_12by24_max_prices_wkday, 1)
        e_max_price_differential_wkend = np.max(e_12by24_max_prices_wkend, 1) - np.min(e_12by24_max_prices_wkend, 1)
        self.e_max_difference = np.max([e_max_price_differential_wkday, e_max_price_differential_wkend])
        
    #######################################################################
    # Identify the maximum demand charge for this tariff
    ####################################################################### 
    def identify_max_demand_charge(self):
        
        # identify the max demand charge for each period for both flat and tou
        max_d_flat_prices = np.max(self.d_flat_prices, 0)
        max_d_tou_prices = np.max(self.d_tou_prices, 0)
        
        # recast the 12by24 in terms of the demand charge within each cell
        d_wkday_12by24_prices = max_d_tou_prices[self.d_wkday_12by24]
        d_wkend_12by24_prices = max_d_tou_prices[self.d_wkend_12by24]
        
        # add each month's flat charge to the corresponding row of the 12by24
        d_wkday_12by24_prices += max_d_flat_prices.reshape(12,1)
        d_wkend_12by24_prices += max_d_flat_prices.reshape(12,1)
        
        # determine the max between wkends and wkdays
        d_12by24_prices = np.maximum(d_wkday_12by24_prices, d_wkend_12by24_prices)
        
        # determine max demand charge
        self.max_demand_charge = np.max(d_12by24_prices)
                            
                 
#%%     
class Export_Tariff:
    """
    Structure of compensation for exported generation. Currently only two 
    styles: full-retail NEM, and instantanous TOU energy value. 
    """
    
    def __init__(self, full_retail_nem=True, 
                 prices = np.zeros([1, 1], float),
                 levels = np.zeros([1, 1], float),
                 periods_8760 = np.zeros(8760, int),
                 period_tou_n = 1):
     
        self.full_retail_nem = full_retail_nem
        self.prices = prices     
        self.levels = levels
        self.periods_8760 = periods_8760
        self.period_tou_n = period_tou_n
        
    def set_constant_sell_price(self, price):
        self.full_retail_nem = False
        self.prices = np.array([[price]], float)
        self.levels = np.array([[9999999]], float)
        self.periods_8760 = np.zeros(8760, int)
        self.period_tou_n = 1

#%%
def tiered_calc_vec(values, levels, prices):
    # Vectorized piecewise function calculator
    values = np.asarray(values)
    levels = np.asarray(levels)
    prices = np.asarray(prices)
    y = np.zeros(values.shape)

    # Credit at tier 1 for negative values
    y = y + ((values < 0)) * (values*prices[:][:][0])

    # Tier 1
    y = y + ((values >= 0) & (values < levels[:][:][0])) * (values*prices[:][:][0])

    # Tiers 2 and beyond    
    for tier in np.arange(1,np.size(levels,0)):
        y = y +  ((values >= levels[:][:][tier-1]) & (values < levels[:][:][tier])) * (
            ((values-levels[:][:][tier-1])*prices[:][:][tier]) + levels[:][:][tier-1]*prices[:][:][tier-1])  
    
    return y

#%%

def bill_calculator(load_profile, tariff, export_tariff):
    """
    Deprecated. Nullified by new PySAM code and will be taken out in Beta release
    """
    
    n_months = 12
    
    # Check if a window length is specified, assume hourly if none is given
    if hasattr(tariff, 'window_length_hours') == False: tariff.window_length_hours = 1.0
        
    # If load profile resolution is greater than necessary, average it. 
    if len(load_profile) > int(8760 / tariff.window_length_hours): 
        load_profile = np.array(load_profile).reshape(-1, int(len(load_profile)/int(8760 / tariff.window_length_hours))).mean(axis=1)

    # Note that if load profile resolution is lower than window resolution, it
    # will calculate the bill at the lower resolution    
    n_timesteps = len(load_profile)

    # If necessary, adjust the resolution of the 8760 period vectors
    if hasattr(tariff, 'd_tou_8760'):
        if len(tariff.d_tou_8760) > n_timesteps: tariff.d_tou_8760 = np.array(tariff.d_tou_8760.reshape(-1, len(tariff.d_tou_8760)/n_timesteps).mean(axis=1), int)
        if len(tariff.d_tou_8760) < n_timesteps:
            temp_array = np.zeros([len(tariff.d_tou_8760), n_timesteps/len(tariff.d_tou_8760)], int)
            temp_array[:,:] = tariff.d_tou_8760.reshape(len(tariff.d_tou_8760),1)
            tariff.d_tou_8760 = temp_array.reshape(n_timesteps)

    if hasattr(tariff, 'e_tou_8760'):
        if len(tariff.e_tou_8760) > n_timesteps: tariff.e_tou_8760 = np.array(tariff.e_tou_8760.reshape(-1, len(tariff.e_tou_8760)/n_timesteps).mean(axis=1), int)
        if len(tariff.e_tou_8760) < n_timesteps:
            temp_array = np.zeros([len(tariff.e_tou_8760), n_timesteps/len(tariff.e_tou_8760)], int)
            temp_array[:,:] = tariff.e_tou_8760.reshape(len(tariff.e_tou_8760),1)
            tariff.e_tou_8760 = temp_array.reshape(n_timesteps)

    if hasattr(export_tariff, 'periods_8760'):
        if len(export_tariff.periods_8760) > n_timesteps: export_tariff.periods_8760 = np.array(export_tariff.periods_8760.reshape(-1, len(export_tariff.periods_8760)/n_timesteps).mean(axis=1), int)
        if len(export_tariff.periods_8760) < n_timesteps:
            temp_array = np.zeros([len(export_tariff.periods_8760), n_timesteps/len(export_tariff.periods_8760)], int)
            temp_array[:,:] = export_tariff.periods_8760.reshape(len(export_tariff.periods_8760),1)
            export_tariff.periods_8760 = temp_array.reshape(n_timesteps)      
            
            
    # 8760 vector of month numbers
    month_hours = np.array([0, 744, 1416, 2160, 2880, 3624, 4344, 5088, 5832, 6552, 7296, 8016, 8760], int) * n_timesteps//8760
    month_index = np.zeros(n_timesteps, int)
    for month, hours in enumerate(month_hours):
        month_index[month_hours[month-1]:hours] = month-1
        
    # Temporary patch of daily kWh tiers
    if hasattr(tariff, 'energy_rate_unit'):
        if tariff.energy_rate_unit == 'kWh daily': tariff.e_levels = np.array(tariff.e_levels) * 30.0

    
    #=========================================================================#
    ################## Calculate TOU Demand Charges ###########################
    #=========================================================================#
    if hasattr(tariff, 'd_tou_8760'):
        # Cast the TOU periods into a boolean matrix
        d_tou_n = np.shape(tariff.d_tou_prices)[1]
        period_matrix = np.zeros([n_timesteps, d_tou_n*n_months], bool)
        period_matrix[list(range(n_timesteps)),tariff.d_tou_8760+month_index*d_tou_n] = True
        
        # Determine the max demand in each period of each month of each year
        load_distributed = load_profile[np.newaxis, :].T*period_matrix
        period_maxs = np.max(load_distributed, axis=0)
        
        # Calculate the cost of TOU demand charges
        d_TOU_period_charges = tiered_calc_vec(period_maxs, np.tile(tariff.d_tou_levels[:,0:d_tou_n], 12), np.tile(tariff.d_tou_prices[:,0:d_tou_n], 12))
       
        d_TOU_month_total_charges = np.zeros([n_months])
        for month in range(n_months):
            d_TOU_month_total_charges[month] = np.sum(d_TOU_period_charges[(month*d_tou_n):(month*d_tou_n + d_tou_n)])
    else:
        d_TOU_month_total_charges = np.zeros([n_months])
        period_maxs = np.zeros(0)
        
    #=========================================================================#
    ################# Calculate Flat Demand Charges ###########################
    #=========================================================================#
    if hasattr(tariff, 'd_flat_prices'):
        # Cast the seasons into a boolean matrix
        flat_matrix = np.zeros([n_timesteps, n_months], bool)
        flat_matrix[list(range(n_timesteps)),month_index] = True
        
        # Determine the max demand in each month of each year
        load_distributed = load_profile[np.newaxis, :].T*flat_matrix
        flat_maxs = np.max(load_distributed, axis=0)
        
        flat_charges = tiered_calc_vec(flat_maxs, tariff.d_flat_levels, tariff.d_flat_prices)  
    else:
        flat_charges = np.zeros([n_months])
        flat_maxs = np.zeros(0)
        
    #=========================================================================#
    ############# Calculate Coincident Peak Demand Charges ####################
    #=========================================================================#
    if hasattr(tariff, 'coincident_style'):
        if tariff.coincident_style == 0:
            # Input is a n by m array. Each row is a peak period and each set
            # of columns are the hours that define that period. For example,
            # [[100,200],[5100,5200]] would have two periods that are defined
            # by the average demand of hours [100,200] and [5100,5200]
            # respectively.
            # Coincident_monthly_periods is a 12-length array that maps the 
            # charges to the billing periods.
            coincident_demand_levels = np.average(load_profile[tariff.coincident_hour_def], 1)
            coincident_charges = tiered_calc_vec(coincident_demand_levels, tariff.coincident_levels, tariff.coincident_prices)
            coincident_monthly_charges = coincident_charges[tariff.coincident_monthly_periods]
    else:
        coincident_monthly_charges = np.zeros(12)
        coincident_demand_levels = None
    
    #=========================================================================#
    #################### Calculate Energy Charges #############################
    #=========================================================================#
    # Calculate energy charges without full retail NEM
    if hasattr(tariff, 'e_tou_8760'):
        e_n = np.shape(tariff.e_prices)[1]
        if export_tariff.full_retail_nem == False:
            imported_profile = np.clip(load_profile, 0, 1e99)
            exported_profile = np.clip(load_profile, -1e99, 0)
    
            # Calculate fixed schedule export_tariff 
            # Cast the TOU periods into a boolean matrix
            e_period_export_matrix = np.zeros([len(export_tariff.periods_8760), export_tariff.period_tou_n*n_months], bool)
            e_period_export_matrix[list(range(len(export_tariff.periods_8760))),export_tariff.periods_8760+month_index*export_tariff.period_tou_n] = True
            
            # Determine the energy consumed in each period of each month of each year
            load_distributed = exported_profile[np.newaxis, :].T*e_period_export_matrix
            export_period_sums = np.sum(load_distributed, axis=0)
            
            # Calculate the cost of TOU demand charges
            export_period_credits = tiered_calc_vec(export_period_sums, np.tile(export_tariff.levels[:,0:export_tariff.period_tou_n], 12), np.tile(export_tariff.prices[:,0:export_tariff.period_tou_n], 12))
            
            export_month_total_credits = np.zeros([n_months])
            for month in range(n_months):
                export_month_total_credits[month] = np.sum(export_period_credits[(month*export_tariff.period_tou_n):(month*export_tariff.period_tou_n + export_tariff.period_tou_n)])        
                
            # Calculate imported energy charges. 
            # Cast the TOU periods into a boolean matrix
            e_period_import_matrix = np.zeros([len(tariff.e_tou_8760), e_n*n_months], bool)
            e_period_import_matrix[list(range(len(tariff.e_tou_8760))),tariff.e_tou_8760+month_index*e_n] = True
            
            # Determine the max demand in each period of each month of each year
            load_distributed = imported_profile[np.newaxis, :].T*e_period_import_matrix
            e_period_import_sums = np.sum(load_distributed, axis=0)
            
            # Calculate the cost of TOU demand charges
            e_period_import_charges = tiered_calc_vec(e_period_import_sums, np.tile(tariff.e_levels, 12), np.tile(tariff.e_prices, 12))
            
            e_month_import_total_charges = np.zeros([n_months])
            for month in range(n_months):
                e_month_import_total_charges[month] = np.sum(e_period_import_charges[(month*e_n):(month*e_n + e_n)])
                
            e_month_total_net_charges = e_month_import_total_charges - export_month_total_credits
    
            # placeholder        
            e_period_charges = "placeholder"
            e_period_sums = "placeholder"
         
        # Calculate energy charges with full retail NEM 
        else:
            # Calculate imported energy charges with full retail NEM
            # Cast the TOU periods into a boolean matrix
            e_period_matrix = np.zeros([len(tariff.e_tou_8760), e_n*n_months], bool)
            e_period_matrix[list(range(len(tariff.e_tou_8760))),tariff.e_tou_8760+month_index*e_n] = True
            
            # Determine the energy consumed in each period of each month of each year netting exported electricity
            load_distributed = load_profile[np.newaxis, :].T*e_period_matrix
            e_period_sums = np.sum(load_distributed, axis=0)
            
            # Calculate the cost of TOU energy charges netting exported electricity
            e_period_charges = tiered_calc_vec(e_period_sums, np.tile(tariff.e_levels, 12), np.tile(tariff.e_prices, 12))
            
            e_month_total_net_charges = np.zeros([n_months])
            for month in range(n_months):
                e_month_total_net_charges[month] = np.sum(e_period_charges[(month*e_n):(month*e_n + e_n)])
            
            # Determine the value of NEM
            # Calculate imported energy charges with zero exported electricity
            imported_profile = np.clip(load_profile, 0, 1e99)
    
            # Determine the energy consumed in each period of each month of each year - without exported electricity
            imported_load_distributed = imported_profile[np.newaxis, :].T*e_period_matrix
            e_period_sums_imported = np.sum(imported_load_distributed, axis=0)
            
            # Calculate the cost of TOU energy charges without exported electricity
            e_period_imported_charges = tiered_calc_vec(e_period_sums_imported, np.tile(tariff.e_levels, 12), np.tile(tariff.e_prices, 12))
            
            e_month_total_import_charges = np.zeros([n_months])
            for month in range(n_months):
                e_month_total_import_charges[month] = np.sum(e_period_imported_charges[(month*e_n):(month*e_n + e_n)])
            
            # Determine how much  the exported electricity was worth by comparing
            # bills where it was netted against those where it wasn't
            export_month_total_credits = e_month_total_net_charges - e_month_total_import_charges
            
            e_period_import_sums = 'placeholder'
    else:
        e_month_total_net_charges = np.zeros(12)
        export_month_total_credits = np.zeros(12)
        e_period_charges = np.zeros(12*e_n)
        e_period_sums = np.zeros(12*e_n)
        e_period_import_sums = np.zeros(12*e_n)
        
    total_monthly_bills = d_TOU_month_total_charges + flat_charges + coincident_monthly_charges + e_month_total_net_charges + tariff.fixed_charge
    annual_bill = np.sum(total_monthly_bills)
        
        
        
    results_dict = {'annual_bill':annual_bill,
                    'd_charges':np.sum(d_TOU_month_total_charges + flat_charges),
                    'e_charges':np.sum(e_month_total_net_charges),
                    'fixed_charges':tariff.fixed_charge*12,
                    'monthly_total_bills':total_monthly_bills,
                    'monthly_d_charges':d_TOU_month_total_charges + flat_charges,
                    'monthly_d_tou_charges':d_TOU_month_total_charges,
                    'monthly_d_flat_charges':flat_charges,
                    'monthly_e_total_net_charges':e_month_total_net_charges,
                    'monthly_e_total_import_charges':e_month_total_net_charges-export_month_total_credits,
                    'monthly_e_total_export_credits':export_month_total_credits,
                    'period_kW_maxs':period_maxs,
                    'monthly_kW_maxs':flat_maxs,
                    'period_e_charges':e_period_charges,
                    'period_e_sums':e_period_sums,
                    'e_period_import_sums':e_period_import_sums,
                    'coincident_monthly_charges':coincident_monthly_charges,
                    'coincident_demand_levels':coincident_demand_levels
                    }
    
    return annual_bill, results_dict

    
#%%
# Bulk Downloader from URDB API
def download_tariffs_from_urdb(api_key, sector=None, utility=None, print_progress=False):
    '''
    Each user should get their own URDB API key: http://en.openei.org/services/api/signup/
    
    Sectors: Residential, Commercial, Industrial, Lighting
    
    '''
        
    fields = ['utility',
              'eiaid',
              'name',
              'label',
              'enddate',
              'demandrateunit',
              'flatdemandunit',
              'uri',
              'sector',
              'description',
              'source',
              'peakkwcapacitymax',
              'peakkwcapacitymin',
              'peakkwhuseagemax',
              'peakkwhuseagemin',
              'voltagecategory',
              'phasewiring']
              
    tariffs = pd.DataFrame(columns=fields)

    flag = True
    offset = 0
    chunk_count = 0
    
    input_params = {'version':3,
                'format':'json',
                'detail':'full',
                'limit':500,
                'api_key':api_key}
    
    if sector != None: input_params['sector'] = sector
    if utility != None: input_params['ratesforutility'] = utility
        
    while flag == True:
        input_params['offset'] = offset
    
        r = req.get('http://api.openei.org/utility_rates?', params=input_params)
        
        content = r.content
        tariff_list = json.loads(content, strict=False)['items']   
        
        if len(tariff_list) == 0:
            flag = False
        else:
            tariff_chunk = pd.DataFrame(index=list(range(500)), columns=fields)
            for count, tariff in enumerate(tariff_list):
                if 'utility' in tariff: tariff_chunk.loc[count, 'utility'] = tariff['utility'].encode('utf-8')
                if 'eiaid' in tariff: tariff_chunk.loc[count, 'eiaid'] = tariff['eiaid']
                if 'name' in tariff: tariff_chunk.loc[count, 'name'] = tariff['name'].encode('utf-8')
                if 'label' in tariff: tariff_chunk.loc[count, 'label'] = tariff['label']
                if 'enddate' in tariff: tariff_chunk.loc[count, 'enddate'] = tariff['enddate']
                if 'demandrateunit' in tariff: tariff_chunk.loc[count, 'demandrateunit'] = tariff['demandrateunit']
                if 'flatdemandunit' in tariff: tariff_chunk.loc[count, 'flatdemandunit'] = tariff['flatdemandunit']
                if 'uri' in tariff: tariff_chunk.loc[count, 'uri'] = tariff['uri'].encode('utf-8')
                if 'sector' in tariff: tariff_chunk.loc[count, 'sector'] = tariff['sector'].encode('utf-8')
                if 'description' in tariff: tariff_chunk.loc[count, 'description'] = tariff['description'].encode('utf-8')
                if 'source' in tariff: tariff_chunk.loc[count, 'source'] = tariff['source'].encode('utf-8')
                if 'peakkwcapacitymax' in tariff: tariff_chunk.loc[count, 'peakkwcapacitymax'] = tariff['peakkwcapacitymax']
                if 'peakkwcapacitymin' in tariff: tariff_chunk.loc[count, 'peakkwcapacitymin'] = tariff['peakkwcapacitymin']
                if 'peakkwhuseagemax' in tariff: tariff_chunk.loc[count, 'peakkwhuseagemax'] = tariff['peakkwhuseagemax']
                if 'peakkwhuseagemin' in tariff: tariff_chunk.loc[count, 'peakkwhuseagemin'] = tariff['peakkwhuseagemin']
                if 'voltagecategory' in tariff: tariff_chunk.loc[count, 'voltagecategory'] = tariff['voltagecategory'].encode('utf-8')
                if 'phasewiring' in tariff: tariff_chunk.loc[count, 'phasewiring'] = tariff['phasewiring'].encode('utf-8')
                            
            tariffs = tariffs.append(tariff_chunk.loc[:count, :], ignore_index=True)
            offset += len(tariff_list)
            
            chunk_count += len(tariff_list)
            if print_progress==True: print(chunk_count)
        
        
    return tariffs
    
    
#%%
# Filter tariff_df by a list of keywords in the tariff names, and unit types
    
def filter_tariff_df(tariff_df, 
                     keyword_list=None,
                     keyword_list_file=None,
                     demand_units_to_exclude=['hp', 'kVA', 'kW daily', 'hp daily', 'kVA daily'], 
                     remove_expired=True):
                         
    '''
    
    '''
    
    if keyword_list_file != None:
        keyword_list = []
        with open(keyword_list_file, 'rb') as f:
            reader = csv.reader(f)
            for item in reader:
                keyword_list = keyword_list + item
    elif keyword_list != None:
        keyword_list = keyword_list
    else:
        print('enter a keyword_list or keyword_list_file')
    
    tariffs_to_exclude = np.zeros(len(tariff_df), bool)
    keyword_count_df = pd.DataFrame(index=keyword_list)
    
    for keyword in keyword_list:
        tariffs_that_contain_keyword = tariff_df['name'].str.contains(keyword, case=False)
        tariffs_to_exclude = tariffs_that_contain_keyword + tariffs_to_exclude
        keyword_count_df.loc[keyword, 'num_of_tariffs_excluded'] = np.sum(tariffs_that_contain_keyword)
    
    for demand_unit in demand_units_to_exclude:
        tariffs_that_contain_unit = tariff_df['demandrateunit'] == demand_unit
        tariffs_that_contain_unit += tariff_df['flatdemandunit'] == demand_unit
        tariffs_to_exclude = tariffs_to_exclude + tariffs_that_contain_unit            
        
    tariffs_with_an_end_date = pd.isnull(tariff_df['enddate']) == False
        
    tariffs_to_exclude = tariffs_to_exclude + tariffs_with_an_end_date
        
    excluded_tariffs = tariff_df[tariffs_to_exclude==True]
    included_tariffs = tariff_df[tariffs_to_exclude==False]
                             
    return included_tariffs, excluded_tariffs, keyword_count_df
    
    
#%%
# Create 8760 from two 12x24's
def build_8760_from_12by24s(wkday_12by24, wkend_12by24, start_day=6):
    '''
    Start day of 6 equates to a Sunday
    '''
    
    month_hours = np.array([0, 744, 1416, 2160, 2880, 3624, 4344, 5088, 5832, 6552, 7296, 8016, 8760], int)
    
    month_index = np.zeros(8760, int)
    for month, hours in enumerate(month_hours):
        month_index[month_hours[month-1]:hours] = month-1

    period_8760 = np.zeros(8760, int)
    hour = 0
    day = start_day # Start on 6 because the load profiles we are using start on a Sunday
    for h in range(8760):
        if day < 5:
            period_8760[h] = wkday_12by24[month_index[h], hour]
        else:
            period_8760[h] = wkend_12by24[month_index[h], hour]
        hour += 1
        if hour == 24: hour = 0; day += 1
        if day == 7: day = 0
            
    return period_8760


#%%
def design_tariff_for_portfolio(agent_df, avg_rev, peak_hour_indicies, summer_month_indicies, rev_f_d, rev_f_e, rev_f_fixed):
    '''
    Builds a tariff that would extract a given $/kWh from a portfolio of 
    customers.
    
    Inputs:
        - agent_df: Dataframe of agents. Must contain load_profile and its 
                    weight in the portfolio.
        - avg_rev: $/kWh that the tariff would extract from the given portfolio
                    of customers.
        - rev_f_d: revenue strucutre for demand charges. Format is [fraction of
                    total revenue, fraction that comes from tou charges, 
                    fraction that comes from flat charges]
                    ex: [0.4875, 0.5, 0.5]
        - rev_f_d: revenue strucutre for energy charges. Format is [fraction of
                    total revenue, fraction that comes from off-peak hours, 
                    fraction that comes from on-peak hours]
                    ex: [0.4875, 0.20, 0.8]
        - rev_f_fixed: [fraction of revenue from fixed monthly charges].
                    ex: [0.025]
        
    Assumptions:
        - peak hours are the same between demand and energy.
        - peak hours only occur during the summer

    '''
    
    # Construct the 12x24 matricies for the given peak hours
    d_wkend_12by24 = np.zeros([12,24], int)
    d_wkday_12by24 = np.zeros([12,24], int)
    e_wkend_12by24 = np.zeros([12,24], int)
    e_wkday_12by24 = np.zeros([12,24], int)
    for peak_hour in peak_hour_indicies:
        d_wkday_12by24[summer_month_indicies, peak_hour] = 1
        e_wkday_12by24[summer_month_indicies, peak_hour] = 1
    
    # Build an 8760 of peak hours   
    d_tou_8760 = build_8760_from_12by24s(d_wkday_12by24, d_wkend_12by24, start_day=6)
    d_tou_n = 2
    
    # 8760 vector of month numbers
    month_hours = np.array([0, 744, 1416, 2160, 2880, 3624, 4344, 5088, 5832, 6552, 7296, 8016, 8760], int)
    month_index = np.zeros(8760, int)
    for month, hours in enumerate(month_hours):
        month_index[month_hours[month-1]:hours] = month-1
    
    period_matrix = np.zeros([8760, d_tou_n*12], bool)
    period_matrix[list(range(8760)),d_tou_8760+month_index*d_tou_n] = True
    
    # Define the dataframes that energy and demand values will be recorded in
    bld_peak_demands = pd.DataFrame()
    bld_flat_demands = pd.DataFrame()
    bld_peak_energy = pd.DataFrame()
    bld_offpeak_energy = pd.DataFrame()
    
    # Determine the peak demands and energy consumption for each building in
    # the portfolio
    for bld in list(agent_df.index):
        load_profile = agent_df.loc[bld, 'load_profile']
        load_distributed = load_profile[np.newaxis, :].T*period_matrix
    
        # Determine the max demands
        period_maxs = np.max(load_distributed, axis=0).reshape([2,12], order='F')
        bld_peak_demands[bld] = period_maxs[1,:]
        bld_flat_demands[bld] = np.max(period_maxs, axis=0)
        
        # Determine energy consumption
        period_sums = np.sum(load_distributed, axis=0).reshape([2,12], order='F')
        bld_peak_energy[bld] = period_sums[1,:]
        bld_offpeak_energy[bld] = period_sums[0,:]
    
    # Calculate the normalized revenue from each category
    normalized_consumption = np.sum(agent_df['f_in_this_portfolio'] * agent_df['aec'])
    norm_rev = normalized_consumption * avg_rev
    norm_rev_d_peak = norm_rev * rev_f_d[0] * rev_f_d[1]
    norm_rev_d_flat = norm_rev * rev_f_d[0] * rev_f_d[2]
    norm_rev_e_peak = norm_rev * rev_f_e[0] * rev_f_e[1]
    norm_rev_e_offpeak = norm_rev * rev_f_e[0] * rev_f_e[2]
    norm_rev_fixed = norm_rev * rev_f_fixed[0]
    
    # Calculate the prices that would result in the required revenue being
    # collected, for each category
    charge_d_peak = norm_rev_d_peak / np.sum(np.sum(bld_peak_demands)*agent_df['f_in_this_portfolio'])
    charge_d_flat = norm_rev_d_flat / np.sum(np.sum(bld_flat_demands)*agent_df['f_in_this_portfolio'])
    charge_e_peak = norm_rev_e_peak / np.sum(np.sum(bld_peak_energy)*agent_df['f_in_this_portfolio'])
    charge_e_offpeak = norm_rev_e_offpeak / np.sum(np.sum(bld_offpeak_energy)*agent_df['f_in_this_portfolio'])
    charge_fixed_monthly = norm_rev_fixed / np.sum(agent_df['f_in_this_portfolio']) / 12.0
    
    # Prepare variables for tariff definition
    d_tou_levels = np.array([[1e9, 1e9]])
    d_tou_prices = np.array([[0, charge_d_peak]])
    d_flat_levels = 1e9
    d_flat_prices = charge_d_flat
    e_levels = np.array([[1e9, 1e9]])
    e_prices = np.array([[charge_e_offpeak, charge_e_peak]]) # Check this!!! TODO
    
    # Define tariff
    tariff = Tariff()
    tariff.define_d_flat(d_flat_levels, d_flat_prices)
    tariff.define_d_tou(d_wkday_12by24, d_wkend_12by24, d_tou_levels, d_tou_prices)
    tariff.define_e(e_wkday_12by24, e_wkend_12by24, e_levels, e_prices)
    tariff.fixed_charge = charge_fixed_monthly
    
    export_tariff = Export_Tariff(full_retail_nem=True)
    for bld in list(agent_df.index):
        load_profile = agent_df.loc[bld, 'load_profile']
        original_bill, original_bill_results = bill_calculator(load_profile, tariff, export_tariff)
            
    return tariff
