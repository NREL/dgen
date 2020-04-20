# -*- coding: utf-8 -*-
"""
Created on Mon Nov 24 16:47:13 2014

@author: mgleason
"""

import json
import urllib
import urllib2
import numpy as np
import pandas as pd
#import os


def get_urdb_rate_keys_by_sector(sector):
    ### MAKE THE REQUEST TO OPENEI FOR THE RATE DATA OF THE SPECIFIED RATE KEY
    
    # API LINKS:
    # http://en.openei.org/services/doc/rest/util_rates?version=3
    # http://en.openei.org/wiki/Help:US_Utility_Rate_Database_API_Tutorial#Requesting_Utility_Company_Data_with_OpenEI_API

    if sector.lower() not in ['residential', 'commercial', 'industrial', 'lighting']:
        raise ValueError("sector must be one of ['residential', 'commercial', 'industrial', 'lighting']")

    api = 'http://en.openei.org/services/rest/utility_rates?'
    
    params = {'version' : 3,
              'format' : 'json',
              'detail' : 'minimal',
              'approved': 'true',
              'sector': sector.lower().title()
              }
    
    # initialize a list to hold all of the results
    # set the initial values for the while boolean variable and for the offset
    raw_rates = []
    more = True
    offset = 0
    while more:
        # update the offset parameter
        params['offset'] = offset      
        params_encode = urllib.urlencode(params)
        
        url = api+params_encode
        o = urllib2.urlopen(url)
        response = json.loads(o.read())
        o.close()
        
        # check how many rates were returned
        if len(response['items']) == 0: 
            more = False
        else:
            raw_rates.extend(response['items'])
            offset = len(raw_rates)

    # extract just the utility name and rate_key
    all_rates = []
    for rate in raw_rates:
        d = {}
        d['utility_name'] = rate['utility']
        d['rate_key'] = rate['label']
        all_rates.append(d)
    
    # convert to a dataframe
    rates_df = pd.DataFrame.from_dict(all_rates)    
    
    return rates_df


def get_urdb_by_key(rate_key):
    ### MAKE THE REQUEST TO OPENEI FOR THE RATE DATA OF THE SPECIFIED RATE KEY
    
    # API LINKS:
    # http://en.openei.org/services/doc/rest/util_rates?version=3
    # http://en.openei.org/wiki/Help:US_Utility_Rate_Database_API_Tutorial#Requesting_Utility_Company_Data_with_OpenEI_API

    api = 'http://en.openei.org/services/rest/utility_rates?'
    
    
    
    params = {'version' : 3,
              'format' : 'json',
              'detail' : 'full',
              'getpage': rate_key
              }
              
    params_encode = urllib.urlencode(params)
    
    url = api+params_encode
    o = urllib2.urlopen(url)
    response = json.loads(o.read())
    o.close()
    
    # check that data was actually returned
    if len(response['items']) == 0:
        raise ValueError("No data returned by the URDB for rate with ID %s" % rate_key)
    
    raw = response['items'][0]
    
    # add some basic identifying parameters
    raw['jsonurl'] = url
    raw['guid'] = rate_key
    raw['rateurl'] = "http://en.openei.org/apps/USURDB/rate/view/" + rate_key
    
    
    return raw
        

def save_urdb(rate_key, outfile):
    ### MAKE THE REQUEST TO OPENEI FOR THE RATE DATA OF THE SPECIFIED RATE KEY
    
    # API LINKS:
    # http://en.openei.org/services/doc/rest/util_rates?version=3
    # http://en.openei.org/wiki/Help:US_Utility_Rate_Database_API_Tutorial#Requesting_Utility_Company_Data_with_OpenEI_API

    api = 'http://en.openei.org/services/rest/utility_rates?'
    
    
    
    params = {'version' : 3,
              'format' : 'json',
              'detail' : 'full',
              'getpage': rate_key
              }
              
    params_encode = urllib.urlencode(params)
    
    url = api+params_encode
    o = urllib2.urlopen(url)
    f = file(outfile, 'w')
    f.write(o.read())
    o.close()
    f.close()
    
    return 1


def generate_meta_field_names():
    
    # key is the key used by URDB, value is the key used by SAM
    fields = {  'name' : 'ur_schedule_name',
                'utility' : 'ur_name',
                'source' : 'ur_source',
                'guid' : 'urdb_rate_id',
                'rateurl' : 'rateurl',
                'jsonurl' : 'jsonurl'}
    
    return fields


def generate_basic_rate_field_names():
    
    ### SET UP FIELD NAMES TO EXTRACT FROM THE RAW DATA
    

    # key is the key used by URDB, value is the key used by SAM
    fields =      {         'annualmincharge' : 'ur_annual_min_charge', # 
                            'minmonthlycharge' : 'ur_monthly_min_charge', #
                            'fixedmonthlycharge' : 'ur_monthly_fixed_charge' #
                        }
    
    return fields


def generate_applicability_field_names():

    fields = {               'peakkwcapacityhistory' : 'ur_demand_history',
                            'peakkwcapacitymax' : 'ur_demand_max',
                            'peakkwcapacitymin' : 'ur_demand_min',
                            'peakkwhusagehistory' : 'ur_energy_history',
                            'peakkwhusagemax' : 'ur_energy_max',
                            'peakkwhusagemin' : 'ur_energy_min',
                            'voltagemaximum' : 'ur_voltage_max',
                            'voltageminimum' : 'ur_voltage_min',
                            'voltagecategory' : 'ur_voltage_category',
                            'phasewiring' : 'ur_phase_wiring'
                }    

    return fields
    
    
def generate_schedule_field_names():
    
    fields =       {'energyweekdayschedule' : 'ur_ec_sched_weekday',
                    'energyweekendschedule' : 'ur_ec_sched_weekend',
                    'demandweekdayschedule' : 'ur_dc_sched_weekday',
                    'demandweekendschedule' : 'ur_dc_sched_weekend'}
                    
    return fields
    

def json_default(json, key, default_val):
    
    if key in json.keys():
        return json[key]
    else:
        return default_val


def retrieve_diurnal_data(json, key):
    
    raw_array = np.array(json[key])
    # check array dimensions
    if raw_array.shape[0] <> 12:
        raise ValueError("Number of months in %s is not equal to 12" % key)
    if raw_array.shape[1] <> 24:
            raise ValueError("Number of hours in %s is not equal to 24" % key)
    # increment all values by 1 to correspond to period indexing in energy rate structure
    diurnal_data = (raw_array + 1).tolist()
    return diurnal_data


def extract_energy_rate_structure(raw_json):

    #==============================================================================
    #  TOU ENERGY CHARGE STRUCTURE
    #==============================================================================
    
    field_template = "ur_ec_p%s_t%s_"
    d = {}
    ec_enable = False
    if 'energyratestructure' in raw_json.keys():
        ers_periods = raw_json['energyratestructure']
        if type(ers_periods) == list:
            period_count = len(ers_periods)
            if period_count > 12:
                raise ValueError('Number of periods in energyratestructure is greater than 12')
            for period in range(0, period_count):
                ers_tiers = ers_periods[period]
                if type(ers_tiers) == list:
                    tier_count = len(ers_tiers)
                    if tier_count > 6:
                        raise ValueError('Number of tiers in energyratestructure is greater than 6')
                    for tier in range(0, tier_count):
                        field_base = field_template % (period+1, tier+1)
                        # extract by key if available, otherwise set to default
                        energy_max = json_default(ers_tiers[tier], 'max', 1e38)
                        energy_buy = json_default(ers_tiers[tier], 'rate', 0.0)
                        energy_sell = json_default(ers_tiers[tier], 'sell', 0.0)
                        energy_adj = json_default(ers_tiers[tier], 'adj', 0.0)
                        buy_rate = energy_buy + energy_adj
                        d[field_base + 'ub'] = energy_max
                        d[field_base + 'br'] = buy_rate
                        d[field_base + 'sr'] = energy_sell
                        if not(ec_enable) and buy_rate <> 0:
                            ec_enable = True
    
    d['ur_ec_enable'] = int(ec_enable)
    
    return d


def extract_flat_demand_charge_structure(raw_json):
    
    #==============================================================================
    #  FLAT DEMAND STRUCTURE
    #==============================================================================
    
    # initialize the output dictionary
    d = {}    

    # check whether this info is provided in the json file
    if 'flatdemandstructure' in raw_json.keys() and 'flatdemandmonths' in raw_json.keys():
        # extract the flat demand months and flat demand structure
        fds_periods = raw_json['flatdemandstructure']    
        fdm_periods = raw_json['flatdemandmonths']
        # make sure both are lists
        if type(fds_periods) == list and type(fdm_periods) == list:
            
            
            # extract the array that indicates which period applies to each of the 12 months in the year
            months = ["jan", "feb", "mar", "apr", "may", "jun", "jul", "aug", "sep", "oct", "nov", "dec" ]
            # ensure there are 12 months in fdm_periods
            fdm_period_count = len(fdm_periods)
            if fdm_period_count <> 12:
                raise ValueError('Number of periods in flatdemandmonths is not equal to 12') 
            flat_demand_months = dict(zip(months, fdm_periods))
            
            
            # extract the flat demand periods and tiers
            # create dictionaries to hold the flat demand charges and upper bounds for each period/tier
            flat_demand_parameters = {}
            # make sure there are no more than 12 periods in the flat demand structure
            fds_period_count = len(fds_periods)
            if fds_period_count > 12:
                raise ValueError('Number of periods in flatdemandstructure is greater than 12')
            for period in range(0, fds_period_count):
                # extract the tiers in this period
                fds_tiers = fds_periods[period]
                # make sure the fds_tiers object is a list
                if type(fds_tiers) == list:
                    # make sure there are no more than 6 tiers
                    tier_count = len(fds_tiers)
                    if tier_count > 6:
                        raise ValueError('Number of tiers in flatdemandstructure is greater than 6')         
                    # add a dictionary for this period to the dictionary
                    flat_demand_parameters[period] = {}
                    for tier in range(0, tier_count):
                        # add this tier to the dictionary
                        flat_demand_parameters[period][tier] = {}
                        # extract by key if available, otherwise set to default            
                        flat_demand_max = json_default(fds_tiers[tier], 'max', 1e38)
                        flat_demand_rate = json_default(fds_tiers[tier], 'rate', 0.0)
                        flat_demand_adj = json_default(fds_tiers[tier], 'adj', 0.0)
                        flat_demand_charge = flat_demand_rate + flat_demand_adj
                        # assign to dictionary
                        flat_demand_parameters[period][tier]['charge'] = flat_demand_charge
                        flat_demand_parameters[period][tier]['max'] = flat_demand_max

         
            # loop through 12 months, extracting the relevant charges/upper bounds for the corresponding period and its tiers
            # set up the template for output dictionary keys
            field_template = "ur_dc_%s_t%s_"   
            for month, period in flat_demand_months.iteritems():
                # this line is necessary due to some bugginess in urdb
                if period in flat_demand_parameters.keys():
                    period_params = flat_demand_parameters[period]
                    tiers = period_params.keys()
                    for tier in tiers:
                        tier_params = period_params[tier]
                        field_base = field_template % (month, tier+1)    
                        flat_demand_charge = tier_params['charge']
                        flat_demand_max = tier_params['max']
                        d[field_base + 'ub'] = flat_demand_max                
                        d[field_base + 'dc'] = flat_demand_charge
    
    
    return d
    
    
def extract_tou_demand_charge_structure(raw_json):    
    
    #==============================================================================
    #  TOU DEMAND STRUCTURE
    #==============================================================================    

    # initialize the output dictionary
    d = {}    
    
    # set up the template for output dictionary keys
    field_template = "ur_dc_p%s_t%s_"
    
    # check whether this info is provided in the json file
    if 'demandratestructure' in raw_json.keys():
        drs_periods = raw_json['demandratestructure']
        # check that the object is a list
        if type(drs_periods) == list:
            # make sure there are no more than 12 periods
            period_count = len(drs_periods)
            if period_count > 12:
                raise ValueError('Number of periods in demandratestructure is greater than 12')
            for period in range(0, period_count):
                # extract the tiers for this period
                drs_tiers = drs_periods[period]
                # make sure the tiers object is a list
                if type(drs_tiers) == list:
                    # make sure there are no more than 6 tiers
                    tier_count = len(drs_tiers)
                    if tier_count > 6:
                        raise ValueError('Number of tiers in demandratestructure is greater than 6')
                    for tier in range(0, tier_count):
                        field_base = field_template % (period+1, tier+1)
                        # extract by key if available, otherwise set to default            
                        demand_max = json_default(drs_tiers[tier], 'max', 1e38)
                        demand_rate = json_default(drs_tiers[tier], 'rate', 0.0)
                        demand_adj = json_default(drs_tiers[tier], 'adj', 0.0)  
                        demand_charge = demand_rate + demand_adj
                        d[field_base + 'ub'] = demand_max                
                        d[field_base + 'dc'] = demand_charge
 
    
    return d


def extract_sam_fields(raw_json):
          
    # initialize the output dictionary
    rate = {}
    

    # get the dictionary of basic rate fields
    basic_rate_fields = generate_basic_rate_field_names()
    # add each field that applies to the data pulled from openEI
    for urdb_key, sam_key in basic_rate_fields.iteritems():
        if urdb_key in raw_json.keys():
            rate[sam_key] = raw_json[urdb_key]  
            

    # get the dictionary of schedule fields (for energy charge and demand charge schedules)
    schedule_fields = generate_schedule_field_names()
    for urdb_key, sam_key in schedule_fields.iteritems():        
        if urdb_key in raw_json.keys():        
            rate[sam_key] = retrieve_diurnal_data(raw_json, urdb_key)                
            
            
    # get the complex rate structures
    energy_charge_structure = extract_energy_rate_structure(raw_json)    
    flat_demand_charge_structure = extract_flat_demand_charge_structure(raw_json)
    tou_demand_charge_structure = extract_tou_demand_charge_structure(raw_json)
    # add these to the rate dictionary
    rate.update(energy_charge_structure)
    rate.update(flat_demand_charge_structure)
    rate.update(tou_demand_charge_structure)
    # update the dc_enable field (if any of the ur_dc_*_dc fields are nonzero, set it true)
    demand_charge_rates = [rate[k] for k in rate.keys() if k.endswith('_dc') and k.startswith('ur_dc') and rate[k] <> 0]
    if len(demand_charge_rates) > 0:
        rate['ur_dc_enable'] = 1
    else:
        rate['ur_dc_enable'] = 0


    # Manually add additional fields
    # net metering
    # defaults to true if not specified (we will want to change this in the diffusion modeling)
    if 'usenetmetering' in raw_json.keys():
        rate['ur_enable_net_metering'] = raw_json['usenetmetering']
    else:
        rate['ur_enable_net_metering'] = True
        
    # "fixed energy rates - URDB handles as energy charges" (not sure what this means -- taken from source code)
    # my interpretation of this is that these are always treated as zeros when the data comes from URDB
    rate['ur_flat_buy_rate'] = 0
    rate['ur_flat_sell_rate'] = 0
    
    
    # get the applicability fields
    applicability = {}
    applicability_fields = generate_applicability_field_names()
    for urdb_key, sam_key in applicability_fields.iteritems():        
        if urdb_key in raw_json.keys():        
            applicability[sam_key] = raw_json[urdb_key]  
            
            
    # get metadata info
    meta = {}
    # get the dictionary of metadata fields
    meta_fields = generate_meta_field_names()
    for urdb_key, sam_key in meta_fields.iteritems():        
        if urdb_key in raw_json.keys():        
            meta[sam_key] = raw_json[urdb_key]  
    # manually add descriptive text
    meta['ur_description'] = '. '.join([str(raw_json[k]) for k in ['description','basicinformationcomments','energycomments','demandcomments'] if k in raw_json.keys()])


    # combine into a final dictionary
    out_json = meta.copy()
    out_json['sam_json'] = rate
    out_json['applicability'] = applicability

    return out_json
    

def urdb_rate_to_sam_structure(rate_key):

    raw_json = get_urdb_by_key(rate_key)
    out_json = extract_sam_fields(raw_json)

    return out_json



#if __name__ == '__main__':
#    # set a rate key to test
#
#    # commercial rate with flat demand and energy charges
#    # rate_key = '539f70f6ec4f024411ece0b1'    
#
#    # commercial rate with flat demand and energy charges
#    rate_key = '539f6b82ec4f024411ec9db9'
#
#    # commercial rate with tou demand , flat demand, and energy charges
#    rate_key = '539fb91bec4f024bc1dc1ef1'
#    
#    # get the raw json from urdb
#    raw_json = get_urdb(rate_key)
#    print raw_json['rateurl']
#    
#    # get the simple fields
#    r = extract_sam_fields(raw_json)
#    n = extract_energy_rate_structure(raw_json)    
#    f = extract_flat_demand_charge_structure(raw_json)
#    t = extract_tou_demand_charge_structure(raw_json)
          
            


