import numpy as np
import pandas as pd
import decorators
import datetime
from scipy import optimize

import config
import settings
import utility_functions as utilfunc
import agent_mutation
import dispatch_functions as dFuncs
import tariff_functions as tFuncs
import general_functions as gFuncs

import PySAM.Battwatts as battery
import PySAM.BatteryTools as batt_tools
import PySAM.Utilityrate5 as utility
import PySAM.Cashloan as cashloan


#==============================================================================
# Load logger
logger = utilfunc.get_logger()
#==============================================================================

#%%
def calc_system_size_and_financial_performance(agent, dynamic_system_sizing=True, rate_switch_table=None):
    """
    Calculate the optimal system and battery size and generation profile, and resulting bill savings and financil metrics.
    
    Parameters
    ----------
    agent : 'pd.df'
        individual agent object.
    dynamic_system_sizing : 'bool'
        If true, enable dynamic sizing which calculates the system size that maximizes system NPV, else use a fixed ratio

    Returns
    -------
    agent: 'pd.df'
        Adds several features to the agent dataframe:

        - **agent_id**
        - **system_kw** - system capacity selected by agent
        - **batt_kw** - battery capacity selected by agent
        - **batt_kwh** - battery energy capacity
        - **npv** - net present value of system + storage
        - **cash_flow**  - array of annual cash flows from system adoption
        - **batt_dispatch_profile** - array of hourly battery dispatch
        - **annual_energy_production_kwh** - annual energy production (kwh) of system
        - **naep** - normalized annual energy production (kwh/kW) of system
        - **capacity_factor** - annual capacity factor
        - **first_year_elec_bill_with_system** - first year electricity bill with adopted system ($/yr)
        - **first_year_elec_bill_savings** - first year electricity bill savings with adopted system ($/yr)
        - **first_year_elec_bill_savings_frac** - fraction of savings on electricity bill in first year of system adoption
        - **max_system_kw** - maximum system size allowed as constrained by roof size or not exceeding annual consumption 
        - **first_year_elec_bill_without_system** - first year electricity bill without adopted system ($/yr)
        - **avg_elec_price_cents_per_kwh** - first year electricity price (c/kwh)
        - **cbi** - ndarray of capacity-based incentives applicable to agent
        - **ibi** - ndarray of investment-based incentives applicable to agent
        - **pbi** - ndarray of performance-based incentives applicable to agent
        - **cash_incentives** - ndarray of cash-based incentives applicable to agent
        - **export_tariff_result** - summary of structure of retail tariff applied to agent
    """

    logger.info(agent.loc['county_id'])
   
    if config.VERBOSE:
        print("County ID:", agent.loc['county_id'])
    
    # connect to Postgres and configure connection
    model_settings = settings.init_model_settings()
    con, cur = utilfunc.make_con(model_settings.pg_conn_string, model_settings.role)
    
    # Set resolution of dispatcher    
    d_inc_n_est = 10    
    DP_inc_est = 12
    d_inc_n_acc = 20     
    DP_inc_acc = 12

    # Extract load profile after applying offset
    norm_scaled_load_profiles_df = agent_mutation.elec.get_and_apply_normalized_load_profiles(con, agent)
    load_profile = pd.Series(norm_scaled_load_profiles_df['consumption_hourly']).iloc[0]
    del norm_scaled_load_profiles_df
    
    agent.loc['timesteps_per_year'] = 1

    # Using the scale offset factor of 1E6 for capacity factors
    norm_scaled_pv_cf_profiles_df = agent_mutation.elec.get_and_apply_normalized_hourly_resource_solar(con, agent)
    pv_cf_profile = pd.Series(norm_scaled_pv_cf_profiles_df['solar_cf_profile'].iloc[0]) /  1e6

    del norm_scaled_pv_cf_profiles_df
    
    agent.loc['naep'] = float(np.sum(pv_cf_profile))
    
    # Create battery object
    batt = dFuncs.Battery()
    batt_ratio = 3.0

    tariff = tFuncs.Tariff(dict_obj=agent.loc['tariff_dict'])

    # Create export tariff object
    if agent.loc['nem_system_kw_limit'] != 0:
        export_tariff = tFuncs.Export_Tariff(full_retail_nem=True)
        export_tariff.periods_8760 = tariff.e_tou_8760
        export_tariff.prices = tariff.e_prices_no_tier
    else:
        export_tariff = tFuncs.Export_Tariff(full_retail_nem=False)

    original_bill, original_results = tFuncs.bill_calculator(load_profile, tariff, export_tariff)
    agent.loc['first_year_elec_bill_without_system'] = original_bill * agent.loc['elec_price_multiplier'] 

    if agent.loc['first_year_elec_bill_without_system'] == 0: 
        agent.loc['first_year_elec_bill_without_system'] = 1.0

    agent.loc['avg_elec_price_cents_per_kwh'] = agent.loc['first_year_elec_bill_without_system'] / agent.loc['load_kwh_per_customer_in_bin']

    #=========================================================================#
    # Estimate bill savings revenue from a set of solar+storage system sizes
    #=========================================================================#    
    
    # Set PV sizes to evaluate
    max_size_load = agent.loc['load_kwh_per_customer_in_bin']/agent.loc['naep']
    max_size_roof = agent.loc['developable_roof_sqft'] * agent.loc['pv_kw_per_sqft']
    agent.loc['max_system_kw'] = min(max_size_load, max_size_roof)

    if dynamic_system_sizing:
        # Size the PV system based on the optimal NPV value. Default is to search over 10% increments of generation to load ratios. This adds to the model run time.
        pv_sizes = np.arange(0, 1.1, 0.1) * agent.loc['max_system_kw']
    else:
        # Size the PV system depending on NEM availability, either to 95% of load w/NEM, or 50% w/o NEM. In both cases, roof size is a constraint.
        if export_tariff.full_retail_nem:
            pv_sizes = np.array([min(max_size_load * 0.95, max_size_roof)])
        else:
            pv_sizes = np.array([min(max_size_load * 0.5, max_size_roof)])

    # Set battery sizes to evaluate
    # Only evaluate a battery if there are demand charges, TOU energy charges, or no NEM
    #batt_inc = 3
    #if hasattr(tariff, 'd_flat_prices') or hasattr(tariff, 'd_tou_prices') or tariff.e_max_difference>0.02 or export_tariff.full_retail_nem==False:
    #    batt_powers = np.linspace(0, np.array(agent.loc['max_demand_kw']) * 0.2, batt_inc)
    #else:
    #    batt_powers = np.zeros(1)
    batt_powers = np.zeros(1)
        
    # Calculate the estimation parameters for each PV size
    est_params_df = pd.DataFrame(index=pv_sizes)
    est_params_df['estimator_params'] = 'temp'

    for pv_size in pv_sizes:
        load_and_pv_profile = load_profile - pv_size * pv_cf_profile
        est_params_df.at[pv_size, 'estimator_params'] = dFuncs.calc_estimator_params(load_and_pv_profile, tariff, export_tariff, batt.eta_charge, batt.eta_discharge)
    
    # Create df with all combinations of solar+storage sizes
    system_df = pd.DataFrame(gFuncs.cartesian([pv_sizes, batt_powers]), columns=['pv', 'batt_kw'])
    system_df['est_bills'] = None

    pv_kwh_by_year = np.array([sum(x) for x in np.split(np.array(pv_cf_profile), agent.loc['timesteps_per_year'])])
    pv_kwh_by_year = np.concatenate([(pv_kwh_by_year - ( pv_kwh_by_year * agent.loc['pv_degradation_factor'] * i)) for i in range(1, agent.loc['economic_lifetime_yrs']+1)])
    system_df['kwh_by_timestep'] = system_df['pv'].apply(lambda x: x * pv_kwh_by_year)

    n_sys = len(system_df)
    
    for i in system_df.index:    
        pv_size = system_df['pv'][i].copy()
        load_and_pv_profile = load_profile - pv_size*pv_cf_profile
        
        agent, one_time_charge = agent_mutation.elec.apply_rate_switch(rate_switch_table, agent, pv_size)
        tariff = tFuncs.Tariff(dict_obj=agent.loc['tariff_dict'])
        
        # for buy all sell all agents: calculate value of generation based on wholesale prices and subtract from original bill
        if agent.loc['compensation_style'] == 'buy all sell all':
            
            sell_all = np.sum(pv_size * pv_cf_profile * agent.loc['wholesale_elec_price_dollars_per_kwh'])
            system_df.loc[i, 'est_bills'] = original_bill - sell_all
        
        # for net billing agents: if system size within policy limits, set sell rate to wholesale price -- otherwise, set sell rate to 0
        elif agent.loc['compensation_style'] == 'net billing':
            
            export_tariff = tFuncs.Export_Tariff(full_retail_nem=False)
            if pv_size<=agent.loc['nem_system_kw_limit']:
                export_tariff.set_constant_sell_price(agent.loc['wholesale_elec_price_dollars_per_kwh'])
            else:
                export_tariff.set_constant_sell_price(0.)
    
            batt_power = system_df['batt_kw'][i].copy()
            batt.set_cap_and_power(batt_power*batt_ratio, batt_power)  
    
            if batt_power > 0:
                estimator_params = est_params_df.loc[system_df['pv'][i].copy(), 'estimator_params']
                estimated_results = dFuncs.determine_optimal_dispatch(load_profile, pv_size*pv_cf_profile, batt, tariff, export_tariff, estimator_params=estimator_params, estimated=True, DP_inc=DP_inc_est, d_inc_n=d_inc_n_est, estimate_demand_levels=True)
                system_df.loc[i, 'est_bills'] = estimated_results['bill_under_dispatch']  
            else:
                bill_with_PV, _ = tFuncs.bill_calculator(load_and_pv_profile, tariff, export_tariff)
                system_df.loc[i, 'est_bills'] = bill_with_PV + one_time_charge
        
        # for net metering agents: if system size within policy limits, set full_retail_nem=True -- otherwise set export value to wholesale price
        elif agent.loc['compensation_style'] == 'net metering':
            
            if pv_size<=agent.loc['nem_system_kw_limit']:
                export_tariff = tFuncs.Export_Tariff(full_retail_nem=True)
                export_tariff.periods_8760 = tariff.e_tou_8760
                export_tariff.prices = tariff.e_prices_no_tier
            else:
                export_tariff = tFuncs.Export_Tariff(full_retail_nem=False)
                export_tariff.set_constant_sell_price(agent.loc['wholesale_elec_price_dollars_per_kwh'])
    
            batt_power = system_df['batt_kw'][i].copy()
            batt.set_cap_and_power(batt_power*batt_ratio, batt_power)  
    
            if batt_power > 0:
                estimator_params = est_params_df.loc[system_df['pv'][i].copy(), 'estimator_params']
                estimated_results = dFuncs.determine_optimal_dispatch(load_profile, pv_size*pv_cf_profile, batt, tariff, export_tariff, estimator_params=estimator_params, estimated=True, DP_inc=DP_inc_est, d_inc_n=d_inc_n_est, estimate_demand_levels=True)
                system_df.loc[i, 'est_bills'] = estimated_results['bill_under_dispatch']  
            else:
                bill_with_PV, _ = tFuncs.bill_calculator(load_and_pv_profile, tariff, export_tariff)
                system_df.loc[i, 'est_bills'] = bill_with_PV + one_time_charge
            
        # for agents with no compensation mechanism: set sell rate to 0 and calculate bill with net load profile
        else:
            
            export_tariff = tFuncs.Export_Tariff(full_retail_nem=False)
            export_tariff.set_constant_sell_price(0.)
            
            batt_power = system_df['batt_kw'][i].copy()
            batt.set_cap_and_power(batt_power*batt_ratio, batt_power)  
    
            if batt_power > 0:
                estimator_params = est_params_df.loc[system_df['pv'][i].copy(), 'estimator_params']
                estimated_results = dFuncs.determine_optimal_dispatch(load_profile, pv_size*pv_cf_profile, batt, tariff, export_tariff, estimator_params=estimator_params, estimated=True, DP_inc=DP_inc_est, d_inc_n=d_inc_n_est, estimate_demand_levels=True)
                system_df.loc[i, 'est_bills'] = estimated_results['bill_under_dispatch']  
            else:
                bill_with_PV, _ = tFuncs.bill_calculator(load_and_pv_profile, tariff, export_tariff)
                system_df.loc[i, 'est_bills'] = bill_with_PV + one_time_charge
            
            

    system_df['batt_kwh'] = system_df['batt_kw'] * batt_ratio
    
    # Calculate bill savings cash flow
    # elec_price_multiplier is the scalar increase in the cost of electricity since 2016, when the tariffs were curated
    # elec_price_escalator is this agent's assumption about how the price of electricity will change in the future.
    avg_est_bill_savings = (original_bill - np.array(system_df['est_bills'])).reshape([n_sys, 1]) * agent.loc['elec_price_multiplier']
    est_bill_savings = np.zeros([n_sys, agent.loc['economic_lifetime_yrs']+1])
    est_bill_savings[:,1:] = avg_est_bill_savings
    escalator = (np.zeros(agent.loc['economic_lifetime_yrs']+1) + agent.loc['elec_price_escalator'] + 1)**list(range(agent.loc['economic_lifetime_yrs']+1))
    degradation = (np.zeros(agent.loc['economic_lifetime_yrs']+1) + 1 - agent.loc['pv_degradation_factor'])**list(range(agent.loc['economic_lifetime_yrs']+1))
    est_bill_savings = est_bill_savings * escalator * degradation
    system_df['est_bill_savings'] = est_bill_savings[:, 1]
        
    # simple representation of 70% minimum of batt charging from PV in order to
    # qualify for the ITC. Here, if batt kW is greater than 25% of PV kW, no ITC.
    batt_chg_frac = np.where(system_df['pv'] >= system_df['batt_kw']*4.0, 1.0, 0)
        
    #=========================================================================#
    # Determine financial performance of each system size
    #=========================================================================#
        
    cash_incentives = np.array([0]*system_df.shape[0])

    if not isinstance(agent.loc['state_incentives'],float):
        investment_incentives = calculate_investment_based_incentives(system_df, agent)
        capacity_based_incentives = calculate_capacity_based_incentives(system_df, agent)

        default_expiration = datetime.date(agent.loc['year'] + agent.loc['economic_lifetime_yrs'],1,1)
        pbi_by_timestep_functions = {
                                    "default":
                                            {   'function':eqn_flat_rate,
                                                'row_params':['pbi_usd_p_kwh','incentive_duration_yrs','end_date'],
                                                'default_params':[0, agent.loc['economic_lifetime_yrs'], default_expiration],
                                                'additional_params':[agent.loc['year'], agent.loc['timesteps_per_year']]},
                                    "SREC":
                                            {   'function':eqn_linear_decay_to_zero,
                                                'row_params':['pbi_usd_p_kwh','incentive_duration_yrs','end_date'],
                                                'default_params':[0, 10, default_expiration],
                                                'additional_params':[agent.loc['year'], agent.loc['timesteps_per_year']]}
                                      }
        production_based_incentives =  calculate_production_based_incentives(system_df, agent, function_templates=pbi_by_timestep_functions)

    else:
        investment_incentives = np.zeros(system_df.shape[0])
        capacity_based_incentives = np.zeros(system_df.shape[0])
        production_based_incentives = np.tile( np.array([0]*agent.loc['economic_lifetime_yrs']), (system_df.shape[0],1))

    cf_results_est = cashflow_constructor(est_bill_savings, 
                         np.array(system_df['pv']), agent.loc['system_capex_per_kw'], agent.loc['system_om_per_kw'],
                         np.array(system_df['batt_kw'])*batt_ratio, np.array(system_df['batt_kw']),
                         agent.loc['batt_capex_per_kw'], agent.loc['batt_capex_per_kwh'],
                         agent.loc['batt_om_per_kw'], agent.loc['batt_om_per_kwh'],
                         batt_chg_frac,
                         agent.loc['sector_abbr'], agent.loc['itc_fraction_of_capex'], agent.loc['deprec_sch'],
                         agent['tax_rate'], 0, agent['real_discount_rate'],
                         agent.loc['economic_lifetime_yrs'], agent.loc['inflation_rate'],
                         agent.loc['down_payment_fraction'], agent.loc['loan_interest_rate'], agent.loc['loan_term_yrs'],
                         cash_incentives,investment_incentives, capacity_based_incentives, production_based_incentives)
                    
    system_df['npv'] = cf_results_est['npv']
   
    #=========================================================================#
    # Select system size and business model for this agent
    #=========================================================================# 
    index_of_best_fin_perform_ho = system_df['npv'].idxmax()

    opt_pv_size = system_df['pv'][index_of_best_fin_perform_ho].copy()
    opt_batt_power = system_df['batt_kw'][index_of_best_fin_perform_ho].copy()

    opt_batt_cap = opt_batt_power*batt_ratio
    batt.set_cap_and_power(opt_batt_cap, opt_batt_power)
    
    agent, one_time_charge = agent_mutation.elec.apply_rate_switch(rate_switch_table, agent, opt_pv_size)
    tariff = tFuncs.Tariff(dict_obj=agent.loc['tariff_dict'])
    
    # for buy all sell all agents: calculate value of generation based on wholesale prices and subtract from original bill
    if agent.loc['compensation_style'] == 'buy all sell all':
        
        sell_all = np.sum(opt_pv_size * pv_cf_profile * agent.loc['wholesale_elec_price_dollars_per_kwh'])
        opt_bill = original_bill - sell_all

        # package into "dummy" dispatch results dictionary
        accurate_results = {'bill_under_dispatch' : opt_bill, 'batt_dispatch_profile' : np.zeros(len(load_profile))}
    
    # for net billing agents: if system size within policy limits, set sell rate to wholesale price -- otherwise, set sell rate to 0
    elif agent.loc['compensation_style'] == 'net billing':
        
        export_tariff = tFuncs.Export_Tariff(full_retail_nem=False)
        if opt_pv_size<=agent.loc['nem_system_kw_limit']:
            export_tariff.set_constant_sell_price(agent.loc['wholesale_elec_price_dollars_per_kwh'])
        else:
            export_tariff.set_constant_sell_price(0.)

        accurate_results = dFuncs.determine_optimal_dispatch(load_profile, opt_pv_size*pv_cf_profile, batt, tariff, export_tariff, estimated=False, d_inc_n=d_inc_n_acc, DP_inc=DP_inc_acc)
    
    # for net metering agents: if system size within policy limits, set full_retail_nem=True -- otherwise set export value to wholesale price
    elif agent.loc['compensation_style'] == 'net metering':
        
        export_tariff = tFuncs.Export_Tariff(full_retail_nem=True)
        if opt_pv_size<=agent.loc['nem_system_kw_limit']:
            export_tariff = tFuncs.Export_Tariff(full_retail_nem=True)
            export_tariff.periods_8760 = tariff.e_tou_8760
            export_tariff.prices = tariff.e_prices_no_tier
        else:
            export_tariff = tFuncs.Export_Tariff(full_retail_nem=False)
            export_tariff.set_constant_sell_price(agent.loc['wholesale_elec_price_dollars_per_kwh'])

        accurate_results = dFuncs.determine_optimal_dispatch(load_profile, opt_pv_size*pv_cf_profile, batt, tariff, export_tariff, estimated=False, d_inc_n=d_inc_n_acc, DP_inc=DP_inc_acc)

    # for agents with no compensation mechanism: set sell rate to 0 and calculate bill with net load profile
    else:
        
        export_tariff = tFuncs.Export_Tariff(full_retail_nem=False)
        export_tariff.set_constant_sell_price(0.)
        
        accurate_results = dFuncs.determine_optimal_dispatch(load_profile, opt_pv_size*pv_cf_profile, batt, tariff, export_tariff, estimated=False, d_inc_n=d_inc_n_acc, DP_inc=DP_inc_acc)

    # add system size class
    system_size_breaks = [0.0, 2.5, 5.0, 10.0, 20.0, 50.0, 100.0, 250.0, 500.0, 750.0, 1000.0, 1500.0, 3000.0]
    
    #=========================================================================#
    # Determine dispatch trajectory for chosen system size
    #=========================================================================#     
    
    opt_bill = accurate_results['bill_under_dispatch'] + one_time_charge
    agent.loc['first_year_elec_bill_with_system'] = opt_bill * agent.loc['elec_price_multiplier']
    agent.loc['first_year_elec_bill_savings'] = agent.loc['first_year_elec_bill_without_system'] - agent.loc['first_year_elec_bill_with_system']
    agent.loc['first_year_elec_bill_savings_frac'] = agent.loc['first_year_elec_bill_savings'] / agent.loc['first_year_elec_bill_without_system']
    opt_bill_savings = np.zeros([1, agent.loc['economic_lifetime_yrs'] + 1])
    opt_bill_savings[:, 1:] = (original_bill - opt_bill)
    opt_bill_savings = opt_bill_savings * agent.loc['elec_price_multiplier'] * escalator * degradation
    
    # If the batt kW is less than 25% of the PV kW, apply the ITC
    batt_chg_frac = int( opt_batt_power/opt_pv_size < 0.25)

    cash_incentives = np.array([cash_incentives[index_of_best_fin_perform_ho]])
    investment_incentives = np.array([investment_incentives[index_of_best_fin_perform_ho]])
    capacity_based_incentives = np.array([capacity_based_incentives[index_of_best_fin_perform_ho]])
    production_based_incentives = np.array(production_based_incentives[index_of_best_fin_perform_ho])
    
    cf_results_opt = cashflow_constructor(opt_bill_savings, 
                     opt_pv_size, agent.loc['system_capex_per_kw'], agent.loc['system_om_per_kw'],
                     opt_batt_cap, opt_batt_power,
                     agent.loc['batt_capex_per_kw'], agent.loc['batt_capex_per_kwh'],
                     agent['batt_om_per_kw'], agent['batt_om_per_kwh'],
                     batt_chg_frac,
                     agent.loc['sector_abbr'], agent.loc['itc_fraction_of_capex'], agent.loc['deprec_sch'],
                     agent.loc['tax_rate'], 0, agent.loc['real_discount_rate'],
                     agent.loc['economic_lifetime_yrs'], agent.loc['inflation_rate'],
                     agent.loc['down_payment_fraction'], agent.loc['loan_interest_rate'], agent.loc['loan_term_yrs'],
                     cash_incentives, investment_incentives, capacity_based_incentives, production_based_incentives)
                     
    #=========================================================================#
    # Package results
    #=========================================================================# 

    agent.loc['system_kw'] = opt_pv_size
    agent.loc['batt_kw'] = opt_batt_power
    agent.loc['batt_kwh'] = opt_batt_cap
    agent.loc['npv'] = cf_results_opt['npv'][0]
    agent.loc['cash_flow'] = cf_results_opt['cf'][0]
    agent.loc['batt_dispatch_profile'] = accurate_results['batt_dispatch_profile']

    agent.loc['bill_savings'] = opt_bill_savings
    agent.loc['annual_energy_production_kwh'] = agent.loc['system_kw'] * agent.loc['naep']
    agent.loc['capacity_factor'] = agent.loc['naep']/8760
    agent.loc['system_size_factors'] = np.where(agent.loc['system_kw'] == 0, 0, pd.cut([agent.loc['system_kw']], system_size_breaks))[0]
    agent.loc['cbi'] = float(capacity_based_incentives)
    agent.loc['ibi'] = float(investment_incentives)
    agent.loc['pbi'] = production_based_incentives
    agent.loc['cash_incentives'] = cash_incentives
    agent.loc['pct_state_incentives'] = round(float((capacity_based_incentives + investment_incentives + sum(production_based_incentives) + cash_incentives) / cf_results_opt['installed_cost']),2)
    agent['export_tariff_results'] = original_results
        
    out_cols = ['agent_id',
                'system_kw',
                'batt_kw',
                'batt_kwh',
                'npv',
                'cash_flow',
                'batt_dispatch_profile',
                'annual_energy_production_kwh',
                'naep',
                'capacity_factor',
                'first_year_elec_bill_with_system',
                'first_year_elec_bill_savings',
                'first_year_elec_bill_savings_frac',
                'max_system_kw',
                'first_year_elec_bill_without_system',
                'avg_elec_price_cents_per_kwh',
                'cbi',
                'ibi',
                'pbi',
                'cash_incentives',
                'pct_state_incentives',
                'export_tariff_results'
                ]

    return agent[out_cols]

#%%
def cashflow_constructor(bill_savings,
                         pv_size, pv_price, pv_om,
                         batt_cap, batt_power,
                         batt_cost_per_kw, batt_cost_per_kwh,
                         batt_om_per_kw, batt_om_per_kwh,
                         batt_chg_frac,
                         sector, itc, deprec_sched,
                         fed_tax_rate, state_tax_rate, real_discount_rate,
                         analysis_years, inflation,
                         down_payment_fraction, loan_interest_rate_real, loan_term_yrs,
                         cash_incentives, ibi, cbi, pbi):
    """
    Calculate the system cash flows based on the capex, opex, bill savings, incentives, tax implications, and other factors

    Parameters
    ----------
    bill_savings : "numpy.ndarray"
        Annual bill savings ($/yr) from system adoption from 1st year through system lifetime
    pv_size : "numpy.float64"
        system capacity selected by agent (kW)
    pv_price : "float"
        system capex ($/kW)
    pv_om : "float"
        system operation and maintanence cost ($/kW)
    batt_cap : "numpy.float64"
        energy capacity of battery selected (kWh)
    batt_power : "numpy.float64"
        demand capacity of battery selected (kW)
    batt_cost_per_kw : "float"
        capex of battery per kW installed ($/kW)
    batt_cost_per_kwh : "float"
        capex of battery per kWh installed ($/kWh)
    batt_om_per_kw : "float"
        opex of battery per kW installed ($/kW-yr)
    batt_om_per_kwh : "float"
        opex of battery per kW installed ($/kWh-yr)
    batt_chg_frac : "int"
        fraction of the battery's energy that it gets from a co-hosted PV system. Used for ITC calculation.
    sector : "str"
        agent sector
    itc : "float"
        fraction of capex offset by federal investment tax credit
    deprec_sched : "list"
        fraction of capex eligible for tax-based depreciation
    fed_tax_rate : "float"
        average tax rate as fraction from federal taxes
    state_tax_rate : "int"
        average tax rate as fraction from state taxes
    real_d : "float"
        annua discount rate in real terms
    analysis_years : "int"
        number of years to use in economic analysis
    inflation : "float"
        annual average inflation rate as fraction e.g. 0.025
    down_payment_fraction : "int"
        fraction of capex used as system down payment
    loan_rate_real : "float"
        real interest rate for debt payments
    loan_term : "int"
        number of years for loan term
    cash_incentives : "numpy.ndarray"
        array describing eligible cash-based incentives e.g. $
    ibi : "numpy.ndarray"
        array describing eligible investment-based incentives e.g. 0.2
    cbi : "numpy.ndarray"
        array describing eligible one-time capacity-based incentives e.g. $/kW
    pbi : "numpy.ndarray"
        array describing eligible ongoing performance-based incentives e.g $/kWh-yr

    Returns
    -------
    - **cf**: 'dtype' - Annual cash flows of project investment ($/yr)
    - **cf_discounted**: 'dtype' - Annual discounted cash flows of project investment ($/yr)
    - **npv**: 'dtype' - Net present value ($) of project investment using WACC
    - **bill_savings**: 'dtype' - nominal cash flow of the annual bill savings over the lifetime of the system
    - **after_tax_bill_savings**: 'dtype' - Effective after-tax bill savings (electricity costs are tax-deductible for commercial entities)
    - **pv_cost**: 'dtype' - Capex of system in ($)
    - **batt_cost**: 'dtype' - Capex of battery in ($)
    - **installed_cost**: 'dtype' - Combined capex of system + battery
    - **up_front_cost**: 'dtype' - Capex in 0th year as down payment
    - **batt_om_cf**: 'dtype' - Annual cashflows of battery opex
    - **operating_expenses**: 'dtype' - Combined annual opex of system + battery ($/yr) 
    - **pv_itc_value**: 'dtype' - Absolute value of investment tax credit for system ($)
    - **batt_itc_value**: 'dtype' - Absolute value of investment tax credit for battery ($)
    - **itc_value**: 'dtype' - Absolute value of investment tax credit for combined system + battery ($)
    - **deprec_basis**: 'dtype' - Absolute value of depreciable basis of system ($)
    - **deprec_deductions**: 'dtype' - Annual amount of depreciable capital in given year ($) 
    - **initial_debt**: 'dtype' - Amount of debt for loan ($)
    - **annual_principal_and_interest_payment**: 'dtype' - Annual amount of debt service payment, principal + interest ($)
    - **debt_balance**: 'dtype' - Annual amount of debt remaining in given year ($)
    - **interest_payments**: 'dtype' - Annual amount of interest payment in given year ($)
    - **principal_and_interest_payments**: 'dtype' - Array of annual principal and interest payments ($)
    - **total_taxable_income**: 'dtype' - Amount of stateincome from incentives eligible for taxes
    - **state_deductions**: 'dtype' - Reduction to state taxable income from interest, operating expenses, or bill savings depending on sector
    - **total_taxable_state_income_less_deductions**: 'dtype' - Total taxable state income less any applicable deductions
    - **state_income_taxes**: 'dtype' - Amount of state income tax i.e. net taxable income by tax rate
    - **fed_deductions**: 'dtype' - Reduction to federal taxable income from interest, operating expenses, or bill savings depending on sector
    - **total_taxable_fed_income_less_deductions**: 'dtype' - Total taxable federal income less any applicable deductions
    - **fed_income_taxes**: 'dtype' - Amount of federal income tax i.e. net taxable income by tax rate
    - **interest_payments_tax_savings**: 'dtype' - Amount of tax savings from deductions of interest payments
    - **operating_expenses_tax_savings**: 'dtype' - Amount of tax savings from deductions of operating expenses
    - **deprec_deductions_tax_savings**: 'dtype' - Amount of tax savings from deductions of capital depreciation
    - **elec_OM_deduction_decrease_tax_liability**: 'dtype' - Amount of tax savings from deductions of electricity costs as deductible business expense
    """

    #################### Massage inputs ########################################
    # If given just a single value for an agent-specific variable, repeat that
    # variable for each agent. This assumes that the variable is intended to be
    # applied to each agent.

    if np.size(np.shape(bill_savings)) == 1:
        shape = (1, analysis_years + 1)
    else:
        shape = (np.shape(bill_savings)[0], analysis_years + 1)
    n_agents = shape[0]

    if np.size(sector) != n_agents or n_agents == 1: 
        sector = np.repeat(sector, n_agents)
    if np.size(fed_tax_rate) != n_agents or n_agents == 1: 
        fed_tax_rate = np.repeat(fed_tax_rate, n_agents)
    if np.size(state_tax_rate) != n_agents or n_agents == 1: 
        state_tax_rate = np.repeat(state_tax_rate, n_agents)
    if np.size(itc) != n_agents or n_agents == 1: 
        itc = np.repeat(itc, n_agents)
    if np.size(pv_size) != n_agents or n_agents == 1: 
        pv_size = np.repeat(pv_size, n_agents)
    if np.size(pv_price) != n_agents or n_agents == 1: 
        pv_price = np.repeat(pv_price, n_agents)
    if np.size(pv_om) != n_agents or n_agents == 1: 
        pv_om = np.repeat(pv_om, n_agents)
    if np.size(batt_cap) != n_agents or n_agents == 1: 
        batt_cap = np.repeat(batt_cap, n_agents)
    if np.size(batt_power) != n_agents or n_agents == 1: 
        batt_power = np.repeat(batt_power, n_agents)
    if np.size(batt_cost_per_kw) != n_agents or n_agents == 1: 
        batt_cost_per_kw = np.repeat(batt_cost_per_kw, n_agents)
    if np.size(batt_cost_per_kwh) != n_agents or n_agents == 1: 
        batt_cost_per_kwh = np.repeat(batt_cost_per_kwh,n_agents)
    if np.size(batt_chg_frac) != n_agents or n_agents == 1: 
        batt_chg_frac = np.repeat(batt_chg_frac, n_agents)
    if np.size(batt_om_per_kw) != n_agents or n_agents == 1: 
        batt_om_per_kw = np.repeat(batt_om_per_kw, n_agents)
    if np.size(batt_om_per_kwh) != n_agents or n_agents == 1: 
        batt_om_per_kwh = np.repeat(batt_om_per_kwh, n_agents)
    if np.size(real_discount_rate) != n_agents or n_agents == 1: 
        real_discount_rate = np.repeat(real_discount_rate, n_agents)
    if np.size(down_payment_fraction) != n_agents or n_agents == 1: 
        down_payment_fraction = np.repeat(down_payment_fraction, n_agents)
    if np.size(loan_interest_rate_real) != n_agents or n_agents == 1:
        loan_interest_rate_real = np.repeat(loan_interest_rate_real, n_agents)
    if np.size(ibi) != n_agents or n_agents == 1:
        ibi = np.repeat(ibi, n_agents)
    if np.size(cbi) != n_agents or n_agents == 1:
        cbi = np.repeat(cbi, n_agents)
    if len(pbi) != n_agents:
        if len(pbi) > 0:
            pbi = np.tile(pbi[0], (n_agents, 1))
        else:
            pbi = np.tile(np.array([0] * analysis_years), (n_agents, 1))

    if np.array(deprec_sched).ndim == 1 or n_agents == 1:
        deprec_sched = np.array(deprec_sched)


    #################### Setup #########################################
    effective_tax_rate = fed_tax_rate * (1 - state_tax_rate) + state_tax_rate
    nominal_discount_rate = (1 + real_discount_rate) * (1 + inflation) - 1
    cf = np.zeros(shape)
    inflation_adjustment = (1 + inflation) ** np.arange(analysis_years + 1)

    #################### Bill Savings #########################################
    # For C&I customers, bill savings are reduced by the effective tax rate,
    # assuming the cost of electricity could have otherwise been counted as an
    # O&M expense to reduce federal and state taxable income.
    bill_savings = bill_savings * inflation_adjustment  # Adjust for inflation
    after_tax_bill_savings = np.zeros(shape)
    # reduce value of savings because they could have otherwise be written off as operating expenses
    after_tax_bill_savings = (bill_savings.T * (1 - (sector != 'res') * effective_tax_rate)).T

    cf += bill_savings

    #################### Installed Costs ######################################
    # Assumes that cash incentives, IBIs, and CBIs will be monetized in year 0,
    # reducing the upfront installed cost that determines debt levels.
    pv_cost = pv_size * pv_price  # assume pv_price includes initial inverter purchase
    batt_cost = batt_power * batt_cost_per_kw + batt_cap * batt_cost_per_kwh
    installed_cost = pv_cost + batt_cost
    net_installed_cost = installed_cost - cash_incentives - ibi - cbi
    up_front_cost = net_installed_cost * down_payment_fraction
    cf[:, 0] -= up_front_cost

    #################### Operating Expenses ###################################
    # Nominally includes O&M, replacement costs, fuel, insurance, and property
    # tax - although currently only includes O&M and replacements.
    # All operating expenses increase with inflation
    operating_expenses_cf = np.zeros(shape)
    batt_om_cf = np.zeros(shape)

    # Battery O&M (replacement costs added to base O&M when costs were ingested)
    batt_om_cf[:, 1:] = (batt_power * batt_om_per_kw + batt_cap * batt_om_per_kwh).reshape(n_agents, 1)

    # PV O&M
    operating_expenses_cf[:, 1:] = (pv_om * pv_size).reshape(n_agents, 1)

    operating_expenses_cf += batt_om_cf
    operating_expenses_cf = operating_expenses_cf * inflation_adjustment
    cf -= operating_expenses_cf
    
    #################### PBI #########################################
    # IBI, CBI, and cash is already included in netting the up front cost
    cf[:, 1:] += pbi

    #################### Federal ITC #########################################
    pv_itc_value = pv_cost * itc
    batt_itc_value = batt_cost * itc * batt_chg_frac * (batt_chg_frac >= 0.75)
    itc_value = pv_itc_value + batt_itc_value
    # itc value added in fed_tax_savings_or_liability

    #################### Depreciation #########################################
    # Depreciable basis is the amount of capital investment that can be depreciated on taxes
    # Basis is defined in U.S. tax law as thesum of total installed cost and total
    # construction financing costs, less 50% of ITC and any incentives that
    # reduce the depreciable basis.
    deprec_deductions = np.zeros(shape)
    deprec_basis = installed_cost - itc_value * 0.5
    deprec_deductions[:, 1: np.size(deprec_sched) + 1] = np.array([x * deprec_sched.T for x in deprec_basis])
    # to be used later in fed tax calcs

    #################### Debt cash flow #######################################
    # Deduct loan interest payments from state & federal income taxes for res
    # mortgage and C&I. No deduction for res loan.
    # note that the debt balance in year0 is different from principal if there
    # are any ibi or cbi. Not included here yet.
    # debt balance, interest payment, principal payment, total payment

    # Input loan rate is in real terms, but we are calculating these cash flows in nominal terms
    loan_interest_rate_nom = (1 + loan_interest_rate_real) * (1 + inflation) - 1

    initial_debt = net_installed_cost - up_front_cost
    annual_principal_and_interest_payment = initial_debt * (loan_interest_rate_nom * (1 + loan_interest_rate_nom) ** loan_term_yrs) / ((1 + loan_interest_rate_nom) ** loan_term_yrs - 1)
    debt_balance = np.zeros(shape)
    interest_payments = np.zeros(shape)
    principal_and_interest_payments = np.zeros(shape)

    debt_balance[:, :loan_term_yrs] = (initial_debt * ((1 + loan_interest_rate_nom.reshape(n_agents, 1)) ** np.arange(loan_term_yrs)).T).T - (annual_principal_and_interest_payment * (((1 + loan_interest_rate_nom).reshape(n_agents,1) ** np.arange(loan_term_yrs) - 1.0) / loan_interest_rate_nom.reshape(n_agents, 1)).T).T
    interest_payments[:, 1:] = (debt_balance[:, :-1].T * loan_interest_rate_nom).T
    principal_and_interest_payments[:, 1:loan_term_yrs + 1] = annual_principal_and_interest_payment.reshape(n_agents, 1)

    cf -= principal_and_interest_payments

    #################### State Income Tax #########################################
    # Per SAM, taxable income is CBIs and PBIs (but not IBIs)
    # Assumes no state depreciation
    # Assumes that revenue from DG is not taxable income
    total_taxable_income = np.zeros(shape)
    total_taxable_income[:, 1] = cbi
    total_taxable_income[:, 1:] += pbi

    state_deductions = np.zeros(shape)
    state_deductions += (interest_payments.T * (sector != 'res')).T
    state_deductions += (operating_expenses_cf.T * (sector != 'res')).T
    state_deductions -= (bill_savings.T * (sector != 'res')).T

    total_taxable_state_income_less_deductions = total_taxable_income - state_deductions
    state_income_taxes = (total_taxable_state_income_less_deductions.T * state_tax_rate).T

    state_tax_savings_or_liability = -state_income_taxes

    cf += state_tax_savings_or_liability

    ################## Federal Income Tax #########################################
    # Assumes all deductions are federal
    fed_deductions = np.zeros(shape)
    fed_deductions += (interest_payments.T * (sector != 'res')).T
    fed_deductions += (deprec_deductions.T * (sector != 'res')).T
    fed_deductions += state_income_taxes
    fed_deductions += (operating_expenses_cf.T * (sector != 'res')).T
    fed_deductions -= (bill_savings.T * (sector != 'res')).T

    total_taxable_fed_income_less_deductions = total_taxable_income - fed_deductions
    fed_income_taxes = (total_taxable_fed_income_less_deductions.T * fed_tax_rate).T

    fed_tax_savings_or_liability_less_itc = -fed_income_taxes

    cf += fed_tax_savings_or_liability_less_itc
    cf[:, 1] += itc_value

    ######################## Packaging tax outputs ############################
    interest_payments_tax_savings = (interest_payments.T * effective_tax_rate).T
    operating_expenses_tax_savings = (operating_expenses_cf.T * effective_tax_rate).T
    deprec_deductions_tax_savings = (deprec_deductions.T * fed_tax_rate).T
    elec_OM_deduction_decrease_tax_liability = (bill_savings.T * effective_tax_rate).T

    ########################### Post Processing ###############################

    # Calculate NPV
    powers = np.zeros(shape, int)
    powers[:, :] = np.array(list(range(analysis_years + 1)))
    discounts = np.zeros(shape, float)
    discounts[:, :] = (1 / (1 + nominal_discount_rate)).reshape(n_agents, 1)
    cf_discounted = cf * np.power(discounts, powers)
    npv = np.sum(cf_discounted, 1)

    ########################### Package Results ###############################

    results = {
        'cf': cf,
        'cf_discounted': cf_discounted,
        'npv': npv,
        'bill_savings': bill_savings,
        'after_tax_bill_savings': after_tax_bill_savings,
        'pv_cost': pv_cost,
        'batt_cost': batt_cost,
        'installed_cost': installed_cost,
        'up_front_cost': up_front_cost,
        'batt_om_cf': batt_om_cf,
        'operating_expenses': operating_expenses_cf,
        'pv_itc_value': pv_itc_value,
        'batt_itc_value': batt_itc_value,
        'itc_value': itc_value,
        'deprec_basis': deprec_basis,
        'deprec_deductions': deprec_deductions,
        'initial_debt': initial_debt,
        'annual_principal_and_interest_payment': annual_principal_and_interest_payment,
        'debt_balance': debt_balance,
        'interest_payments': interest_payments,
        'principal_and_interest_payments': principal_and_interest_payments,
        'total_taxable_income': total_taxable_income,
        'state_deductions': state_deductions,
        'total_taxable_state_income_less_deductions': total_taxable_state_income_less_deductions,
        'state_income_taxes': state_income_taxes,
        'fed_deductions': fed_deductions,
        'total_taxable_fed_income_less_deductions': total_taxable_fed_income_less_deductions,
        'fed_income_taxes': fed_income_taxes,
        'interest_payments_tax_savings': interest_payments_tax_savings,
        'operating_expenses_tax_savings': operating_expenses_tax_savings,
        'deprec_deductions_tax_savings': deprec_deductions_tax_savings,
        'elec_OM_deduction_decrease_tax_liability': elec_OM_deduction_decrease_tax_liability
        }

    return results


# %%
# ==============================================================================

def calc_npv(cfs, dr):
    """
    Calculate the net present value of a series of cash flows

    Parameters
    ----------
    cfs : "numpy.ndarray"
        Annual cash flows of investment, where 0th index refers to 0th year of investment
    dr : "numpy.ndarray"
        Discount rate to use in discounting cash flows

    Returns
    -------
    - **npv**: 'dtype' - Net present value ($)
    """

    dr = dr[:, np.newaxis]
    tmp = np.empty(cfs.shape)
    tmp[:, 0] = 1
    tmp[:, 1:] = 1 / (1 + dr)
    drm = np.cumprod(tmp, axis=1)
    npv = (drm * cfs).sum(axis=1)
    return npv

def calc_payback_vectorized(cfs, tech_lifetime):
    """
    Calculate the payback period in years for a given cash flow. Payback is defined as the first year where cumulative cash flows are positive.
    Cash flows that do not result in payback are given a period of 30.1

    Parameters
    ----------
    cfs : "numpy.ndarray"
        Annual cash flows of investment, where 0th index refers to 0th year of investment
    tech_lifetime : "numpy.ndarray"
        Number of years to assume for technology lifetime

    Returns
    -------
    - **payback_period**: 'numpy.ndarray' - Payback period in years
    """
    
    years = np.array([np.arange(0, tech_lifetime)] * cfs.shape[0])
    
    cum_cfs = cfs.cumsum(axis = 1)   
    no_payback = np.logical_or(cum_cfs[:, -1] <= 0, np.all(cum_cfs <= 0, axis = 1))
    instant_payback = np.all(cum_cfs > 0, axis = 1)
    neg_to_pos_years = np.diff(np.sign(cum_cfs)) > 0
    base_years = np.amax(np.where(neg_to_pos_years, years, -1), axis = 1)
    # replace values of -1 with 30
    base_years_fix = np.where(base_years == -1, tech_lifetime - 1, base_years)
    base_year_mask = years == base_years_fix[:, np.newaxis]
    # base year values
    base_year_values = cum_cfs[:, :-1][base_year_mask]
    next_year_values = cum_cfs[:, 1:][base_year_mask]
    frac_years = base_year_values/(base_year_values - next_year_values)
    pp_year = base_years_fix + frac_years
    pp_precise = np.where(no_payback, 30.1, np.where(instant_payback, 0, pp_year))
    
    # round to nearest 0.1 to join with max_market_share
    pp_final = np.array(pp_precise).round(decimals =1)
    
    return pp_final

def virr(cfs, precision=0.005, rmin=0, rmax1=0.3, rmax2=0.5):
    """
    Vectorized IRR calculator. First calculate a 3D array of the discounted
    cash flows along cash flow series, time period, and discount rate. Sum over time to
    collapse to a 2D array which gives the NPV along a range of discount rates
    for each cash flow series. Next, find crossover where NPV is zero--corresponds
    to the lowest real IRR value. For performance, negative IRRs are not calculated
    -- returns "-1", and values are only calculated to an acceptable precision.

    Parameters
    ----------
    cfs : "numpy.ndarray"
        Annual cash flows of investment, where 0th index refers to 0th year of investment
    precision : "numeric"
        Increment (precision) of IRR, which is not calculated exactly
    rmin : "numeric"
        minimum value of IRR to calculate 
    rmax1 : "numeric"
        maximum value of IRR to calculate at the precision step value
    rmax2 : "numeric"
        upper bound of the outer IRR band. eg 50%. Values in the outer band are calculated to 1% precision, IRRs outside the upper band return the rmax2 value

    Returns
    -------
    - **irr**: 'numpy.ndarray' - internal rate of return of cashflows e.g. 0.05
    """

    if cfs.ndim == 1:
        cfs = cfs.reshape(1, len(cfs))

    # Range of time periods
    years = np.arange(0, cfs.shape[1])

    # Range of the discount rates
    rates_length1 = int((rmax1 - rmin) / precision) + 1
    rates_length2 = int((rmax2 - rmax1) / 0.01)
    rates = np.zeros((rates_length1 + rates_length2,))
    rates[:rates_length1] = np.linspace(0, 0.3, rates_length1)
    rates[rates_length1:] = np.linspace(0.31, 0.5, rates_length2)

    # Discount rate multiplier rows are years, cols are rates
    drm = (1 + rates) ** -years[:, np.newaxis]

    # Calculate discounted cfs
    discounted_cfs = cfs[:, :, np.newaxis] * drm

    # Calculate NPV array by summing over discounted cashflows
    npv = discounted_cfs.sum(axis=1)

    # Convert npv into boolean for positives (0) and negatives (1)
    signs = npv < 0

    # Find the pairwise differences in boolean values
    # sign crosses over, the pairwise diff will be True
    crossovers = np.diff(signs, 1, 1)

    # Extract the irr from the first crossover for each row
    irr = np.min(np.ma.masked_equal(rates[1:] * crossovers, 0), 1)

    # deal with negative irrs
    negative_irrs = cfs.sum(1) < 0
    r = np.where(negative_irrs, -1, irr)

    # where the implied irr exceeds 0.5, simply cap it at 0.5
    r = np.where(irr.mask * (negative_irrs == False), 0.5, r)

    # where cashflows are all zero, set irr to nan
    r = np.where(np.all(cfs == 0, axis=1), np.nan, r)

    return r

#%%
@decorators.fn_timer(logger = logger, tab_level = 2, prefix = '')
def calc_financial_performance(dataframe):
    """
    Function to calculate the payback period and join it on the agent dataframe

    Parameters
    ----------
    dataframe : "pd.df"
        Agent dataframe

    Returns
    -------
    - **dataframe**: 'pd.df' - Agent dataframe with payback period joined on dataframe
    """

    dataframe = dataframe.reset_index()
    cfs = np.vstack(dataframe['cash_flow']).astype(np.float)    
    
    # calculate payback period
    tech_lifetime = np.shape(cfs)[1] - 1
    payback = calc_payback_vectorized(cfs, tech_lifetime)

    # All agents (residential and non-residential use payback period)
    dataframe['payback_period'] = payback
    dataframe = dataframe.set_index('agent_id')

    return dataframe

@decorators.fn_timer(logger = logger, tab_level = 2, prefix = '')
def calc_max_market_share(dataframe, max_market_share_df):

    in_cols = list(dataframe.columns)
    dataframe = dataframe.reset_index()
    
    dataframe['business_model'] = 'host_owned'
    dataframe['metric'] = 'payback_period'
    
    # Convert metric value to integer as a primary key, then bound within max market share ranges
    max_payback = max_market_share_df[max_market_share_df.metric == 'payback_period'].payback_period.max()
    min_payback = max_market_share_df[max_market_share_df.metric == 'payback_period'].payback_period.min()
    max_mbs = max_market_share_df[max_market_share_df.metric == 'percent_monthly_bill_savings'].payback_period.max()
    min_mbs = max_market_share_df[max_market_share_df.metric == 'percent_monthly_bill_savings'].payback_period.min()
    
    # copy the metric valeus to a new column to store an edited version
    payback_period_bounded = dataframe['payback_period'].values.copy()
    
    # where the metric value exceeds the corresponding max market curve bounds, set the value to the corresponding bound
    payback_period_bounded[np.where((dataframe.metric == 'payback_period') & (dataframe['payback_period'] < min_payback))] = min_payback
    payback_period_bounded[np.where((dataframe.metric == 'payback_period') & (dataframe['payback_period'] > max_payback))] = max_payback    
    payback_period_bounded[np.where((dataframe.metric == 'percent_monthly_bill_savings') & (dataframe['payback_period'] < min_mbs))] = min_mbs
    payback_period_bounded[np.where((dataframe.metric == 'percent_monthly_bill_savings') & (dataframe['payback_period'] > max_mbs))] = max_mbs
    dataframe['payback_period_bounded'] = payback_period_bounded

    # scale and round to nearest int    
    dataframe['payback_period_as_factor'] = (dataframe['payback_period_bounded'] * 100).round().astype('int')
    # add a scaled key to the max_market_share dataframe too
    max_market_share_df['payback_period_as_factor'] = (max_market_share_df['payback_period'] * 100).round().astype('int')

    # Join the max_market_share table and dataframe in order to select the ultimate mms based on the metric value. 
    dataframe = pd.merge(dataframe, max_market_share_df[['sector_abbr', 'max_market_share', 'metric', 'payback_period_as_factor', 'business_model']], 
        how = 'left', on = ['sector_abbr', 'metric','payback_period_as_factor','business_model'])
    
    out_cols = in_cols + ['max_market_share', 'metric']    

    return dataframe[out_cols]

def calc_lcoe(df, inflation_rate, econ_life = 20):
    ''' LCOE calculation, following ATB assumptions. There will be some small differences
    since the model is already in real terms and doesn't need conversion of nominal terms
    
    IN: df
        deprec schedule
        inflation rate
        econ life -- investment horizon, may be different than system lifetime.
    
    OUT: lcoe - numpy array - Levelized cost of energy (c/kWh) 
    '''
    
    # extract a list of the input columns
    in_cols = df.columns.tolist()
    
    df['IR'] = inflation_rate
    df['DF'] = 1 - df['down_payment_fraction']
    df['CoE'] = df['discount_rate']
    df['CoD'] = df['loan_interest_rate']
    df['TR'] = df['tax_rate']
    
    
    df['WACC'] = ((1 + ((1-df['DF'])*((1+df['CoE'])*(1+df['IR'])-1)) + (df['DF'] * ((1+df['CoD'])*(1+df['IR']) - 1) *  (1 - df['TR'])))/(1 + df['IR'])) -1
    df['CRF'] = (df['WACC'])/ (1 - (1/(1+df['WACC'])**econ_life))# real crf
    
    #df = df.merge(deprec_schedule, how = 'left', on = ['tech','year'])
    df['PVD'] = calc_npv(np.array(list(df['deprec'])),((1+df['WACC'] * 1+ df['IR'])-1)) # Discount rate used for depreciation is 1 - (WACC + 1)(Inflation + 1)
    df['PVD'] /= (1 + df['WACC']) # In calc_npv we assume first entry of an array corresponds to year zero; the first entry of the depreciation schedule is for the first year, so we need to discount the PVD by one additional year
    
    df['PFF'] = (1 - df['TR'] * df['PVD'])/(1 - df['TR'])#project finance factor
    df['CFF'] = 1 # construction finance factor -- cost of capital during construction, assume projects are built overnight, which is not true for larger systems   
    df['OCC'] = df['installed_costs_dollars_per_kw'] # overnight capital cost $/kW
    df['GCC'] = 0 # grid connection cost $/kW, assume cost of interconnecting included in OCC
    df['FOM']  = df['fixed_om_dollars_per_kw_per_yr'] # fixed o&m $/kW-yr
    df['CF'] = df['annual_energy_production_kwh']/df['system_size_kw']/8760 # capacity factor
    df['VOM'] = df['variable_om_dollars_per_kwh'] #variable O&M $/kWh
    
    df['lcoe'] = 100 * (((df['CRF'] * df['PFF'] * df['CFF'] * (df['OCC'] * 1 + df['GCC']) + df['FOM'])/(df['CF'] * 8760)) + df['VOM'])# LCOE 2014c/kWh
    
    out_cols = in_cols + ['lcoe']    
    
    return df[out_cols]

def calc_payback(cfs,revenue,costs,tech_lifetime):
    '''payback calculator ### VECTORIZE THIS ###
    IN: cfs - numpy array - project cash flows ($/yr)
    OUT: pp - numpy array - interpolated payback period (years)
    '''
    cum_cfs = cfs.cumsum(axis = 1)
    out = []
    for x in cum_cfs:
        if x[-1] < 0: # No payback if the cum. cfs are negative in the final year
            pp = 30
        elif all(x<0): # Is positive cashflow ever achieved?
            pp = 30
        elif all(x>0): # Is positive cashflow instantly achieved?
            pp = 0
        else:
            # Return the last year where cumulative cfs changed from negative to positive
            base_year = np.where(np.diff(np.sign(x))>0)[0] 
            if base_year.size > 0:      
                base_year = base_year.max()
                frac_year = x[base_year]/(x[base_year] - x[base_year+1])
                pp = base_year + frac_year
            else: # If the array is empty i.e. never positive cfs, pp = 30
                pp = 30
        out.append(pp)
    return np.array(out).round(decimals =1) # must be rounded to nearest 0.1 to join with max_market_share

#%%
def check_incentive_constraints(incentive_data, temp, system_costs):
    # Reduce the incentive if is is more than the max allowable payment (by percent total costs)
    if not pd.isnull(incentive_data['max_incentive_usd']):
        temp = temp.apply(lambda x: min(x, incentive_data['max_incentive_usd']))

    # Reduce the incentive if is is more than the max allowable payment (by percent of total installed costs)
    if not pd.isnull(incentive_data['max_incentive_pct']):
        temp = temp.combine(system_costs * incentive_data['max_incentive_pct'], min)

    # Set the incentive to zero if it is less than the minimum incentive
    if not pd.isnull(incentive_data['min_incentive_usd']):
        temp = temp * temp.apply(lambda x: int(x > incentive_data['min_incentive_usd']))

    return temp

# %%
def calculate_investment_based_incentives(system_df, agent):
    # Get State Incentives that have a valid Investment Based Incentive value (based on percent of total installed costs)
    cbi_list = agent.loc['state_incentives'].loc[pd.notnull(agent.loc['state_incentives']['ibi_pct'])]

    # Create a empty dataframe to store cumulative ibi's for each system configuration
    result = np.zeros(system_df.shape[0])

    # Loop through each incenctive and add it to the result df
    for row in cbi_list.to_dict('records'):
        if row['tech'] == 'solar':
            # Size filer calls a function to check for valid system size limitations - a boolean so if the size in invalid it will add zero's to the results df
            size_filter = check_minmax(system_df['pv'], row['min_kw'], row['max_kw'])

            # Scale costs based on system size
            system_costs = (system_df['pv'] * agent.loc['system_capex_per_kw'])

        if row['tech'] == 'storage':
            # Size filer calls a function to check for valid system size limitations - a boolean so if the size in invalid it will add zero's to the results df
            size_filter = check_minmax(system_df['batt_kwh'], row['min_kwh'], row['max_kwh'])
            size_filter = size_filter * check_minmax(system_df['batt_kw'], row['min_kw'], row['max_kw'])

            # Calculate system costs
            system_costs = (system_df['batt_kw'] * agent.loc['batt_capex_per_kw']) + (system_df['batt_kwh'] * agent.loc['batt_capex_per_kwh'])

        # Total incentive
        temp = (system_costs * row['ibi_pct']) * size_filter

        # Add the result to the cumulative total
        result += check_incentive_constraints(row, temp,system_costs)

    return np.array(result)

#%%
def calculate_capacity_based_incentives(system_df, agent):

    # Get State Incentives that have a valid Capacity Based Incentive value (based on $ per watt)
    cbi_list = agent.loc['state_incentives'].loc[pd.notnull(agent.loc['state_incentives']['cbi_usd_p_w']) | pd.notnull(agent.loc['state_incentives']['cbi_usd_p_wh'])]

    # Create a empty dataframe to store cumulative cbi's for each system configuration
    result = np.zeros(system_df.shape[0])

    # Loop through each incenctive and add it to the result df
    for row in cbi_list.to_dict('records'):

        if row['tech'] == 'solar':
            # Size filer calls a function to check for valid system size limitations - a boolean so if the size in invalid it will add zero's to the results df
            size_filter = check_minmax(system_df['pv'], row['min_kw'], row['max_kw'])

            # Calculate incentives
            temp = (system_df['pv'] * (row['cbi_usd_p_w']*1000)) * size_filter

            # Calculate system costs
            system_costs = system_df['pv'] * agent.loc['system_capex_per_kw']


        if row['tech'] == 'storage' and not np.isnan(row['cbi_usd_p_wh']):
            # Size filer calls a function to check for valid system size limitations - a boolean so if the size in invalid it will add zero's to the results df
            size_filter = check_minmax(system_df['batt_kwh'], row['min_kwh'], row['max_kwh'])
            size_filter = size_filter * check_minmax(system_df['batt_kw'], row['min_kw'], row['max_kw'])

            # Calculate incentives
            temp = row['cbi_usd_p_wh']* system_df['batt_kw'] * 1000  * size_filter

            # Calculate system costs
            system_costs = (system_df['batt_kw'] * agent.loc['batt_capex_per_kw']) + (system_df['batt_kwh'] * agent.loc['batt_capex_per_kwh'])

        result += check_incentive_constraints(row, temp, system_costs)

    return np.array(result)

#%%
def check_minmax(value, min_, max_):
    #Returns 1 if the value is within a valid system size limitation - works for single numbers and arrays (assumes valid is system size limitation are not known)

    output = value.apply(lambda x: True)

    if isinstance(min_,float):
        if not np.isnan(min_):
            output = output * value.apply(lambda x: x >= min_)

    if isinstance(max_, float):
        if not np.isnan(max_):
            output = output * value.apply(lambda x: x <= max_)

    return output

#%%
def get_expiration(end_date, current_year, timesteps_per_year):
    #Calculates the timestep at which the end date occurs based on pytoh datetime.date objects and a number of timesteps per year
    return  float(((end_date - datetime.date(current_year, 1, 1)).days / 365.0) * timesteps_per_year)

#%%
def eqn_builder(method,incentive_info, info_params, default_params,additional_data):
    #Builds an equation to scale a series of timestep values
        #method:            'linear_decay' linearly drop from the full price to zero at a given timestep (used for SREC's currently)
        #                   'flat_rate' used as a defualt to keep the consistent value until an endpoint at which point the value is always zero
        #incentive_info:    a row from the agent['state_incentives'] dataframe from which to draw info to customize and equation
        #incentive params:  an array containing the names of the params in agent['state_incentives'] to use in the equation
        #default params:    an array of default values for each incentive param. Entries must match the order of the incentive params.
        #additional_data:    Addtional data can be used to customize the equation

    #Loop through params and grab the default value is the agent['state_incentives'] entry does not have a valid value for it
    for i, r in enumerate(info_params):
        try:
            if np.isnan(incentive_info[r]):
                incentive_info[r] = default_params[i]
        except:
            if incentive_info[r] is None:
                incentive_info[r] = default_params[i]

    pbi_usd_p_kwh = float(incentive_info[info_params[0]])
    years = float(incentive_info[info_params[1]])
    end_date = incentive_info[info_params[2]]

    current_year = int(additional_data[0])
    timesteps_per_year = float(additional_data[1])

    #Get the timestep at which the incentive expires
    try:
        #Find expiration timestep by explict program end date
        expiration = get_expiration(end_date, current_year, timesteps_per_year)
    except:
        #Assume the incetive applies for all years if there is an error in the previous step
        expiration = years * timesteps_per_year

    #Reduce the expiration if there is a cap on the number of years the incentive can be applied
    expiration = min(years * timesteps_per_year, expiration)

    if method =='linear_decay':
        #Linear decline to zero at expiration
        def function(ts):
            if ts > expiration:
                return  0.0
            else:
                if expiration - ts < 1:
                    fraction = expiration - ts
                else:
                    fraction = 1
                return fraction * (pbi_usd_p_kwh + ((-1 * (pbi_usd_p_kwh / expiration) * ts)))

        return function


    if method == 'flat_rate':
        # Flat rate until expiration, and then zero
        def function(ts):
            if ts > expiration:
                return 0.0
            else:
                if expiration - ts < 1:
                    fraction = expiration - ts
                else:
                    fraction = 1

                return fraction * pbi_usd_p_kwh

        return function

#%%
def eqn_linear_decay_to_zero(incentive_info, info_params, default_params,additional_params):
    return eqn_builder('linear_decay',incentive_info, info_params, default_params,additional_params)

#%%
def eqn_flat_rate(incentive_info, info_params, default_params,additional_params):
    return eqn_builder('flat_rate', incentive_info, info_params, default_params,additional_params)

#%%
def calculate_production_based_incentives(system_df, agent, function_templates={}):

    # Get State Incentives that have a valid Production Based Incentive value
    pbi_list = agent.loc['state_incentives'].loc[pd.notnull(agent.loc['state_incentives']['pbi_usd_p_kwh'])]

    # Create a empty dataframe to store cumulative pbi's for each system configuration (each system should have an array as long as the number of years times the number of timesteps per year)
    result = np.tile( np.array([0]*agent.loc['economic_lifetime_yrs']*agent.loc['timesteps_per_year']), (system_df.shape[0],1))

    #Loop through incentives
    for row in pbi_list.to_dict('records'):
        #Build boolean array to express if system sizes are valid
        size_filter = check_minmax(system_df['pv'], row['min_kw'], row['max_kw'])

        if row['tech'] == 'solar':
            # Get the incentive type - this should match a key in the function dictionary
            if row['incentive_type'] in list(function_templates.keys()):
                f_name = row['incentive_type']
            else:
                f_name = 'default'

            # Grab infomation about the incentive from the function template
            fn = function_templates[f_name]

            # Vectorize the function
            f =  np.vectorize(fn['function'](row,fn['row_params'],fn['default_params'],fn['additional_params']))

            # Apply the function to each row (containing an array of timestep values)
            temp = system_df['kwh_by_timestep'].apply(lambda x: x * f(list(range(0,len(x)))))

            #Add the pbi the cumulative total
            result = result + list(temp * size_filter)

    #Sum the incentive at each timestep by year for each system size
    result =  [np.array([sum(x) for x in np.split(x,agent.loc['economic_lifetime_yrs'] )]) for x in result]

    return result



#%%
def calc_system_performance(kw, pv, utilityrate, loan, batt, costs, ur_metering_option=0, en_batt=True, batt_simple_dispatch=0):
    """
    Executes Battwatts, Utilityrate5, and Cashloan PySAM modules with system sizes (kw) as input
    
    Parameters
    ----------
    kw: Capacity (in kW)
    pv: Dictionary with generation_hourly and consumption_hourly
    utilityrate: PySAM Utilityrate5 module
    loan: PySAM Cashloan module
    batt: PySAM Battwatts module
    costs: Dictionary with system costs
    ur_metering_option: Customer billing method
        - ur_metering_option = 0 (single meter with monthly rollover credits in kWh)
        - ur_metering_option = 1 (single meter with monthly rollover credits in $)
        - ur_metering_option = 2 (single meter with no monthly rollover credits (net billing))
        - ur_metering_option = 3 (single meter with monthly rollover credits in kWh (net billing))
        - ur_metering_option = 4 (two meters with all generation sold and all load purchased)
    en_batt: Enable battery
    batt_simple_dispatch: batt.Battery.batt_simple_dispatch
        - batt_simple_dispatch = 0 (peak shaving look ahead)
        - batt_simple_dispatch = 1 (peak shaving look behind)

    Returns
    -------
    -loan.Outputs.npv: the negative net present value of system + storage to be optimized for system sizing
    """

    inv_eff = 0.96  # default SAM inverter efficiency for PV
    gen_hourly = pv['generation_hourly']
    load_hourly = pv['consumption_hourly']  # same field as 'load_kwh_per_customer_in_bin_initial' when summed

    dc = [(i * kw) * 1000 for i in gen_hourly] # W
    ac = [i * inv_eff for i in dc] # W
    gen = [i / 1000 for i in ac] # W to kW
    
    # Set up battery, with system generation conditional on the battery generation being included
    if en_batt:

        batt.Battery.dc = dc
        batt.Battery.ac = ac
        batt.Battery.batt_simple_enable = 1
        batt.Battery.batt_simple_chemistry = 1  # default value is 1: li ion for residential
        batt.Battery.batt_simple_dispatch = batt_simple_dispatch
        batt.Battery.batt_simple_meter_position = 0  # default value
        batt.Battery.inverter_efficiency = 100  # recommended by Darice for dc-connected
        batt.Battery.load = load_hourly

        # PV to Battery ratio (kW) - From Ashreeta, 02/08/2020
        pv_to_batt_ratio = 1.31372
        batt_capacity_to_power_ratio = 2 # hours of operation
        
        desired_size = kw / pv_to_batt_ratio # Default SAM value for residential systems is 10 
        desired_power = desired_size / batt_capacity_to_power_ratio

        batt_inputs = {
            'batt_chem': batt.Battery.batt_simple_chemistry,
            'batt_Qfull': 2.5, # default SAM value
            'batt_Vnom_default': 3.6, # default SAM value
            'batt_ac_or_dc': 0,  # dc-connected
            'desired_power': desired_power,
            'desired_capacity': desired_size,
            'desired_voltage': 500,
            'size_by_ac_not_dc': 0,  # dc-connected
            'inverter_eff': batt.Battery.inverter_efficiency
            # 'batt_dc_dc_efficiency': (optional)
        }

        # Default values for lead acid batteries
        if batt.Battery.batt_simple_chemistry == 0:
            batt_inputs['LeadAcid_q10'] = 93.2
            batt_inputs['LeadAcid_q20'] = 100
            batt_inputs['LeadAcid_qn'] = 58.12
            # batt_inputs['LeadAcid_tn']: (optional)

        # PySAM.BatteryTools.size_li_ion_battery is the same as dGen_battery_sizing_battwatts.py
        batt_outputs = batt_tools.size_li_ion_battery(batt_inputs)

        computed_size = batt_outputs['batt_computed_bank_capacity']
        computed_power = batt_outputs['batt_power_discharge_max_kwdc']

        batt.Battery.batt_simple_kwh = computed_size
        batt.Battery.batt_simple_kw = computed_power

        batt.execute()
       
        utilityrate.SystemOutput.gen = batt.Outputs.gen

        loan.BatterySystem.en_batt = 1
        loan.BatterySystem.batt_computed_bank_capacity = batt.Outputs.batt_bank_installed_capacity
        loan.BatterySystem.batt_bank_replacement = batt.Outputs.batt_bank_replacement
        loan.BatterySystem.battery_per_kWh = costs['batt_capex_per_kwh']
        
        # Battery capacity-based System Costs amount [$/kWcap]
        loan.SystemCosts.om_capacity1 = [costs['batt_om_per_kw']]
        # Battery production-based System Costs amount [$/MWh]
        loan.SystemCosts.om_production1 = [costs['batt_om_per_kwh'] * 1000]
        
        # Battery capacity for System Costs values [kW]
        loan.SystemCosts.om_capacity1_nameplate = batt.Battery.batt_simple_kw
        # Battery production for System Costs values [kWh]
        loan.SystemCosts.om_production1_values = [batt.Battery.batt_simple_kwh] # should this be batt.Outputs.batt_bank_installed_capacity?

        batt_costs = (costs['batt_capex_per_kw']*batt.Battery.batt_simple_kw) + (costs['batt_capex_per_kwh'] * batt.Battery.batt_simple_kwh)
    else:
        batt.Battery.batt_simple_enable = 0
        utilityrate.SystemOutput.gen = gen
        batt_costs = 0
    
    # Execute utility rate module
    utilityrate.Load.load = load_hourly
    utilityrate.ElectricityRates.ur_metering_option = ur_metering_option
    
    utilityrate.execute()
    
    # Execute financial module
    loan.FinancialParameters.system_capacity = kw
    loan.SystemOutput.annual_energy_value = utilityrate.Outputs.annual_energy_value
    loan.SystemOutput.gen = utilityrate.SystemOutput.gen
    loan.ThirdPartyOwnership.elec_cost_with_system = utilityrate.Outputs.elec_cost_with_system
    loan.ThirdPartyOwnership.elec_cost_without_system = utilityrate.Outputs.elec_cost_without_system

    # Total installed cost = ((system cost per kw) * kw) + ((batt cost per kwh) * kwh) + ((batt cost per kw) * kw) + sales tax 
    system_costs = costs['system_capex_per_kw'] * kw # multiply by costs['cap_cost_multiplier'] ?
    direct_costs = system_costs + batt_costs

    # sales_tax = 0.05 * (direct_costs * 0.52) # default sales tax rates from SAM
    sales_tax = 0 
    loan.SystemCosts.total_installed_cost = direct_costs + sales_tax
    
    loan.execute()

    return -loan.Outputs.npv


def calc_system_size_and_performance(agent, rate_switch_table=None):
    """
    Calculate the optimal system and battery size and generation profile, and resulting bill savings and financial metrics.
    
    Parameters
    ----------
    agent : 'pd.df'
        individual agent object.

    Returns
    -------
    agent: 'pd.df'
        Adds several features to the agent dataframe:

        - **agent_id**
        - **system_kw** - system capacity selected by agent
        - **batt_kw** - battery capacity selected by agent
        - **batt_kwh** - battery energy capacity
        - **npv** - net present value of system + storage
        - **cash_flow**  - array of annual cash flows from system adoption
        - **batt_dispatch_profile** - array of hourly battery dispatch
        - **annual_energy_production_kwh** - annual energy production (kwh) of system
        - **naep** - normalized annual energy production (kwh/kW) of system
        - **capacity_factor** - annual capacity factor
        - **first_year_elec_bill_with_system** - first year electricity bill with adopted system ($/yr)
        - **first_year_elec_bill_savings** - first year electricity bill savings with adopted system ($/yr)
        - **first_year_elec_bill_savings_frac** - fraction of savings on electricity bill in first year of system adoption
        - **max_system_kw** - maximum system size allowed as constrained by roof size or not exceeding annual consumption 
        - **first_year_elec_bill_without_system** - first year electricity bill without adopted system ($/yr)
        - **avg_elec_price_cents_per_kwh** - first year electricity price (c/kwh)
        - **cbi** - ndarray of capacity-based incentives applicable to agent
        - **ibi** - ndarray of investment-based incentives applicable to agent
        - **pbi** - ndarray of performance-based incentives applicable to agent
        - **cash_incentives** - ndarray of cash-based incentives applicable to agent
        - **export_tariff_result** - summary of structure of retail tariff applied to agent
    """

    # Initialize new DB connection    
    model_settings = settings.init_model_settings()
    con, cur = utilfunc.make_con(model_settings.pg_conn_string, model_settings.role)

    # PV
    pv = dict()

    # Extract load profile after applying offset
    norm_scaled_load_profiles_df = agent_mutation.elec.get_and_apply_normalized_load_profiles(con, agent)
    pv['consumption_hourly'] = pd.Series(norm_scaled_load_profiles_df['consumption_hourly']).iloc[0]
    del norm_scaled_load_profiles_df

    # Using the scale offset factor of 1E6 for capacity factors
    norm_scaled_pv_cf_profiles_df = agent_mutation.elec.get_and_apply_normalized_hourly_resource_solar(con, agent)
    pv['generation_hourly'] = pd.Series(norm_scaled_pv_cf_profiles_df['solar_cf_profile'].iloc[0]) /  1e6
    del norm_scaled_pv_cf_profiles_df
    
    agent.loc['naep'] = float(np.sum(pv['generation_hourly']))

    # Battwatts
    batt = battery.default("PVWattsResidential")

    # Utilityrate5
    utilityrate = utility.default("PVWattsResidential")
    tariff_dict = agent.loc['tariff_dict']
    

    ######################################
    ###--------- UTILITYRATE5 ---------###
    ###--- SYSTEM LIFETIME SETTINGS ---###
    ######################################
    
    # Inflation rate [%]
    utilityrate.Lifetime.inflation_rate = agent.loc['inflation_rate']
    
    # Number of years in analysis [years]
    utilityrate.Lifetime.analysis_period = agent.loc['economic_lifetime_yrs']
    
    # Lifetime hourly system outputs [0/1]; Options: 0=hourly first year,1=hourly lifetime
    utilityrate.Lifetime.system_use_lifetime_output = 0


    ######################################
    ###--------- UTILITYRATE5 ---------###
    ###---- DEGRADATION/ESCALATION ----###
    ######################################
    
    # Annual energy degradation [%]
    degradation = [agent.loc['pv_degradation_factor'] * 100] # convert decimal to %
    utilityrate.SystemOutput.degradation = degradation
    # Annual electricity rate escalation [%/year]
    utilityrate.ElectricityRates.rate_escalation  = [agent.loc['elec_price_escalator'] * 100] # is this being applied how we expect?
    
    
    ######################################
    ###--------- UTILITYRATE5 ---------###
    ###---- NET METERING SETTINGS -----###
    ######################################
    
    # Dictionary to map dGen compensation styles to PySAM options
    nem_options = {'net metering':0, 'net billing':2, 'buy all sell all':4, 'none':2} # TODO: confirm these options as they relate to dGen compensation styles
    # Metering options [0=net energy metering,1=net energy metering with $ credits,2=net billing,3=net billing with carryover to next month,4=buy all - sell all]
    utilityrate.ElectricityRates.ur_metering_option = nem_options[agent.loc['compensation_style']]
    # Year end sell rate [$/kWh]
    utilityrate.ElectricityRates.ur_nm_yearend_sell_rate = agent.loc['wholesale_elec_price_dollars_per_kwh'] * agent.loc['elec_price_multiplier'] # TODO:?
    
    
    ######################################
    ###--------- UTILITYRATE5 ---------###
    ###--- FIXED AND ANNUAL CHARGES ---###
    ######################################
    
    # Monthly fixed charge [$]
    utilityrate.ElectricityRates.ur_monthly_fixed_charge = tariff_dict['fixed_charge']
    # Annual minimum charge [$]
    utilityrate.ElectricityRates.ur_annual_min_charge = 0. # not currently tracked in URDB rate attribute downloads
    # Monthly minimum charge [$]
    utilityrate.ElectricityRates.ur_monthly_min_charge = 0. # not currently tracked in URDB rate attribute downloads
    
    
    ######################################
    ###--------- UTILITYRATE5 ---------###
    ###-------- DEMAND CHARGES --------###
    ######################################
    
    # Enable demand charge
    utilityrate.ElectricityRates.ur_dc_enable = (tariff_dict['d_flat_exists']) | (tariff_dict['d_tou_exists'])
    
    if utilityrate.ElectricityRates.ur_dc_enable:
    
        if tariff_dict['d_flat_exists']:
            
            # Reformat demand charge table from dGen format
            n_periods = len(tariff_dict['d_flat_levels'][0])
            n_tiers = len(tariff_dict['d_flat_levels'])
            ur_dc_flat_mat = []
            for period in range(n_periods):
                for tier in range(n_tiers):
                    row = [period, tier+1, tariff_dict['d_flat_levels'][tier][period], tariff_dict['d_flat_prices'][tier][period]]
                    ur_dc_flat_mat.append(row)
            
            # Demand rates (flat) table
            utilityrate.ElectricityRates.ur_dc_flat_mat = ur_dc_flat_mat
        
        
        if tariff_dict['d_tou_exists']:
            
            # Reformat demand charge table from dGen format
            n_periods = len(tariff_dict['d_tou_levels'][0])
            n_tiers = len(tariff_dict['d_tou_levels'])
            ur_dc_tou_mat = []
            for period in range(n_periods):
                for tier in range(n_tiers):
                    row = [period+1, tier+1, tariff_dict['d_tou_levels'][tier][period], tariff_dict['d_tou_prices'][tier][period]]
                    ur_dc_tou_mat.append(row)
            
            # Demand rates (TOU) table
            utilityrate.ElectricityRates.ur_dc_tou_mat = ur_dc_tou_mat
    
    
        # Reformat 12x24 tables - original are indexed to 0, PySAM needs index starting at 1
        d_wkday_12by24 = []
        for m in range(len(tariff_dict['d_wkday_12by24'])):
            row = [x+1 for x in tariff_dict['d_wkday_12by24'][m]]
            d_wkday_12by24.append(row)
            
        d_wkend_12by24 = []
        for m in range(len(tariff_dict['d_wkend_12by24'])):
            row = [x+1 for x in tariff_dict['d_wkend_12by24'][m]]
            d_wkend_12by24.append(row)

        # Demand charge weekday schedule
        utilityrate.ElectricityRates.ur_dc_sched_weekday = d_wkday_12by24
        # Demand charge weekend schedule
        utilityrate.ElectricityRates.ur_dc_sched_weekend = d_wkend_12by24
    
    
    ######################################
    ###--------- UTILITYRATE5 ---------###
    ###-------- ENERGY CHARGES --------###
    ######################################
    
    if tariff_dict['e_exists']:
        
        # Dictionary to map dGen max usage units to PySAM options
        max_usage_dict = {'kWh':0, 'kWh/kW':1, 'kWh daily':2, 'kWh/kW daily':3}
        
        # Reformat energy charge table from dGen format
        n_periods = len(tariff_dict['e_levels'][0])
        n_tiers = len(tariff_dict['e_levels'])
        ur_ec_tou_mat = []
        for period in range(n_periods):
            for tier in range(n_tiers):
                row = [period+1, tier+1, tariff_dict['e_levels'][tier][period], max_usage_dict[tariff_dict['energy_rate_unit']], tariff_dict['e_prices'][tier][period], 0]
                ur_ec_tou_mat.append(row)
        
        # Energy rates table
        utilityrate.ElectricityRates.ur_ec_tou_mat = ur_ec_tou_mat
        
        # Reformat 12x24 tables - original are indexed to 0, PySAM needs index starting at 1
        e_wkday_12by24 = []
        for m in range(len(tariff_dict['e_wkday_12by24'])):
            row = [x+1 for x in tariff_dict['e_wkday_12by24'][m]]
            e_wkday_12by24.append(row)
            
        e_wkend_12by24 = []
        for m in range(len(tariff_dict['e_wkend_12by24'])):
            row = [x+1 for x in tariff_dict['e_wkend_12by24'][m]]
            e_wkend_12by24.append(row)
        
        # Energy charge weekday schedule
        utilityrate.ElectricityRates.ur_ec_sched_weekday = e_wkday_12by24
        # Energy charge weekend schedule
        utilityrate.ElectricityRates.ur_ec_sched_weekend = e_wkend_12by24
        
    
    ######################################
    ###--------- UTILITYRATE5 ---------###
    ###-------- BUY/SELL RATES --------###
    ######################################
    
    # Enable time step sell rates [0/1]
    utilityrate.ElectricityRates.ur_en_ts_sell_rate = 0
    
    # Time step sell rates [0/1]
    utilityrate.ElectricityRates.ur_ts_sell_rate = [0.]
    
    # Time step buy rates [0/1]
    # utilityrate.ElectricityRates.ur_ts_buy_rate 
    
    # Set sell rate equal to buy rate [0/1]
    utilityrate.ElectricityRates.ur_sell_eq_buy = 0
    
    
    ######################################
    ###--------- UTILITYRATE5 ---------###
    ###-------- MISC. SETTINGS --------###
    ######################################
    
    # Use single monthly peak for TOU demand charge; options: 0=use TOU peak,1=use flat peak
    utilityrate.ElectricityRates.TOU_demand_single_peak = 0 # ?
    
    # Optionally enable/disable electricity_rate [years]
    utilityrate.ElectricityRates.en_electricity_rates = 1
    
    
    ######################################
    ###----------- CASHLOAN -----------###
    ###----- FINANCIAL PARAMETERS -----###
    ######################################
    
    loan = cashloan.default("PVWattsResidential")

    loan.Lifetime.system_use_lifetime_output = 0  # default value: outputs first year info only

    loan.FinancialParameters.inflation_rate = agent.loc['inflation_rate']
    loan.FinancialParameters.analysis_period = agent.loc['economic_lifetime_yrs']
    loan.FinancialParameters.loan_term = agent.loc['loan_term_yrs']
    loan.FinancialParameters.loan_rate = agent.loc['loan_interest_rate'] * 100 # decimal to %
    loan.FinancialParameters.debt_fraction = 100 - agent.loc['down_payment_fraction']
    loan.FinancialParameters.real_discount_rate = agent.loc['real_discount_rate'] * 100 # decimal to %
    loan.FinancialParameters.system_heat_rate = 0
    loan.FinancialParameters.market = 0 if agent.loc['sector_abbr'] == 'res' else 1
    loan.FinancialParameters.mortgage = 0 # default value - standard loan (no mortgage)
    loan.FinancialParameters.salvage_percentage = 0
    loan.FinancialParameters.insurance_rate = 0 # ?

    # SAM defaults to ~70% federal tax rate, ~30% state tax rate
    loan.FinancialParameters.federal_tax_rate = [(agent.loc['tax_rate'] * 100) * 0.7]
    loan.FinancialParameters.state_tax_rate = [(agent.loc['tax_rate'] * 100) * 0.3]

    loan.BatterySystem.batt_replacement_option = 2 # user schedule
    batt_replacement_schedule = [0 for i in range(0, agent.loc['batt_lifetime_yrs'] - 1)] + [1]
    loan.BatterySystem.batt_replacement_schedule = np.array(batt_replacement_schedule)

    loan.SystemOutput.degradation = degradation

    ######################################
    ###----------- CASHLOAN -----------###
    ###--------- SYSTEM COSTS ---------###
    ######################################
    
    loan.BatterySystem.battery_per_kWh = agent.loc['batt_capex_per_kwh']
    loan.SystemCosts.om_capacity = [agent.loc['system_om_per_kw'] + agent.loc['system_variable_om_per_kw']] # system
    loan.SystemCosts.om_capacity1 = [agent.loc['batt_om_per_kw']] # battery

    system_costs = dict()
    system_costs['system_capex_per_kw'] = agent.loc['system_capex_per_kw']
    system_costs['system_om_per_kw'] = agent.loc['system_om_per_kw']
    system_costs['system_variable_om_per_kw'] = agent.loc['system_variable_om_per_kw']
    system_costs['cap_cost_multiplier'] = agent.loc['cap_cost_multiplier']
    system_costs['batt_capex_per_kw'] = agent.loc['batt_capex_per_kw']
    system_costs['batt_capex_per_kwh'] = agent.loc['batt_capex_per_kwh']
    system_costs['batt_om_per_kw'] = agent.loc['batt_om_per_kw']
    system_costs['batt_om_per_kwh'] = agent.loc['batt_om_per_kwh']


    ######################################
    ###----------- CASHLOAN -----------###
    ###--------- DEPRECIATION ---------###
    ######################################
    
    # TODO: loan.Depreciation
    
    ######################################
    ###----------- CASHLOAN -----------###
    ###----- TAX CREDIT INCENTIVES ----###
    ######################################
    
    loan.TaxCreditIncentives.itc_fed_percent = agent.loc['itc_fraction_of_capex']
    
    ######################################
    ###----------- CASHLOAN -----------###
    ###------ PAYMENT INCENTIVES ------###
    ######################################

    
    # From dGen - calc_system_size_and_financial_performance()
    max_size_load = agent.loc['load_kwh_per_customer_in_bin'] / agent.loc['naep']
    max_size_roof = agent.loc['developable_roof_sqft'] * agent.loc['pv_kw_per_sqft']
    max_system_kw = min(max_size_load, max_size_roof)
    #tol = 0.5 if max_system_kw > 1.0 else 0.0001
    tol = 0.25 * max_system_kw
    

    # Calculate the PV system size that maximizes the agent's NPV, to a tolerance of 0.5 kW. 
    # Note that the optimization is technically minimizing negative NPV
    # ! As is, because of the tolerance this function would not necessarily return a system size of 0 or max PV size if those are optimal
    res_with_batt = optimize.minimize_scalar(calc_system_performance,
                                             args = (pv, utilityrate, loan, batt, system_costs, 0, True, 0),
                                             bounds = (0, max_system_kw),
                                             method = 'bounded',
                                             tol = tol)

    # PySAM Module outputs with battery
    batt_outputs = batt.Outputs.export()
    batt_loan_outputs = loan.Outputs.export()
    batt_util_outputs = utilityrate.Outputs.export()
    batt_annual_energy_kwh = np.sum(utilityrate.SystemOutput.gen)

    batt_kw = batt.Battery.batt_simple_kw
    batt_kwh = batt.Battery.batt_simple_kwh
    batt_dispatch_profile = batt.Outputs.batt_power # ?

    # Run without battery 
    res_no_batt = optimize.minimize_scalar(calc_system_performance, 
                                           args = (pv, utilityrate, loan, batt, system_costs, 0, False, 0),
                                           bounds = (0, max_system_kw),
                                           method = 'bounded',
                                           tol = tol)

    # PySAM Module outputs without battery
    no_batt_loan_outputs = loan.Outputs.export()
    no_batt_util_outputs = utilityrate.Outputs.export()
    no_batt_annual_energy_kwh = np.sum(utilityrate.SystemOutput.gen)

    # Retrieve NPVs of system with batt and system without batt
    npv_w_batt = batt_loan_outputs['npv']
    npv_no_batt = no_batt_loan_outputs['npv']

    # Choose the system with the higher NPV
    if npv_w_batt >= npv_no_batt:
        system_kw = res_with_batt.x
        payback = batt_loan_outputs['payback']
        annual_energy_production_kwh = batt_annual_energy_kwh
        first_year_elec_bill_with_system = batt_util_outputs['elec_cost_with_system_year1']
        first_year_elec_bill_without_system = batt_util_outputs['elec_cost_without_system_year1']

        npv = npv_w_batt
        cash_flow = list(batt_loan_outputs['cf_payback_with_expenses']) # ?

        cbi_total = batt_loan_outputs['cbi_total']
        cbi_total_fed = batt_loan_outputs['cbi_total_fed']
        cbi_total_oth = batt_loan_outputs['cbi_total_oth']
        cbi_total_sta = batt_loan_outputs['cbi_total_sta']
        cbi_total_uti = batt_loan_outputs['cbi_total_uti']

        ibi_total = batt_loan_outputs['ibi_total']
        ibi_total_fed = batt_loan_outputs['ibi_total_fed']
        ibi_total_oth = batt_loan_outputs['ibi_total_oth']
        ibi_total_sta = batt_loan_outputs['ibi_total_sta']
        ibi_total_uti = batt_loan_outputs['ibi_total_uti']

        cf_pbi_total = batt_loan_outputs['cf_pbi_total']
        pbi_total_fed = batt_loan_outputs['cf_pbi_total_fed']
        pbi_total_oth = batt_loan_outputs['cf_pbi_total_oth']
        pbi_total_sta = batt_loan_outputs['cf_pbi_total_sta']
        pbi_total_uti = batt_loan_outputs['cf_pbi_total_uti']


    else:
        system_kw = res_no_batt.x
        payback = no_batt_loan_outputs['payback']
        annual_energy_production_kwh = no_batt_annual_energy_kwh
        first_year_elec_bill_with_system = no_batt_util_outputs['elec_cost_with_system_year1']
        first_year_elec_bill_without_system = no_batt_util_outputs['elec_cost_without_system_year1']

        npv = npv_no_batt
        cash_flow = list(no_batt_loan_outputs['cf_payback_with_expenses'])

        batt_kw = 0
        batt_kwh = 0
        batt_dispatch_profile = np.nan

        cbi_total = no_batt_loan_outputs['cbi_total']
        cbi_total_fed = no_batt_loan_outputs['cbi_total_fed']
        cbi_total_oth = no_batt_loan_outputs['cbi_total_oth']
        cbi_total_sta = no_batt_loan_outputs['cbi_total_sta']
        cbi_total_uti = no_batt_loan_outputs['cbi_total_uti']

        ibi_total = no_batt_loan_outputs['ibi_total']
        ibi_total_fed = no_batt_loan_outputs['ibi_total_fed']
        ibi_total_oth = no_batt_loan_outputs['ibi_total_oth']
        ibi_total_sta = no_batt_loan_outputs['ibi_total_sta']
        ibi_total_uti = no_batt_loan_outputs['ibi_total_uti']

        cf_pbi_total = no_batt_loan_outputs['cf_pbi_total']
        pbi_total_fed = no_batt_loan_outputs['cf_pbi_total_fed']
        pbi_total_oth = no_batt_loan_outputs['cf_pbi_total_oth']
        pbi_total_sta = no_batt_loan_outputs['cf_pbi_total_sta']
        pbi_total_uti = no_batt_loan_outputs['cf_pbi_total_uti']
        

    # change 0 value to 1 to avoid divide by zero errors
    if first_year_elec_bill_without_system == 0:
        first_year_elec_bill_without_system = 1.0

    # Add outputs to agent df    
    naep = annual_energy_production_kwh / system_kw
    first_year_elec_bill_savings = first_year_elec_bill_without_system - first_year_elec_bill_with_system
    first_year_elec_bill_savings_frac = first_year_elec_bill_savings / first_year_elec_bill_without_system
    avg_elec_price_cents_per_kwh = first_year_elec_bill_without_system / agent.loc['load_kwh_per_customer_in_bin']

    agent.loc['system_kw'] = system_kw
    agent.loc['npv'] = npv
    agent.loc['cash_flow'] = cash_flow
    agent.loc['annual_energy_production_kwh'] = annual_energy_production_kwh
    agent.loc['naep'] = naep
    agent.loc['capacity_factor'] = agent.loc['naep'] / 8760
    agent.loc['first_year_elec_bill_with_system'] = first_year_elec_bill_with_system
    agent.loc['first_year_elec_bill_savings'] = first_year_elec_bill_savings
    agent.loc['first_year_elec_bill_savings_frac'] = first_year_elec_bill_savings_frac
    agent.loc['max_system_kw'] = max_system_kw
    agent.loc['first_year_elec_bill_without_system'] = first_year_elec_bill_without_system
    agent.loc['avg_elec_price_cents_per_kwh'] = avg_elec_price_cents_per_kwh
    agent.loc['batt_kw'] = batt_kw
    agent.loc['batt_kwh'] = batt_kwh
    agent.loc['batt_dispatch_profile'] = batt_dispatch_profile

    # Financial outputs (find out which ones to include): 
    agent.loc['cbi'] = np.array({'cbi_total': cbi_total,
            'cbi_total_fed': cbi_total_fed,
            'cbi_total_oth': cbi_total_oth,
            'cbi_total_sta': cbi_total_sta,
            'cbi_total_uti': cbi_total_uti
           })
    agent.loc['ibi'] = np.array({'ibi_total': ibi_total,
            'ibi_total_fed': ibi_total_fed,
            'ibi_total_oth': ibi_total_oth,
            'ibi_total_sta': ibi_total_sta,
            'ibi_total_uti': ibi_total_uti
           })
    agent.loc['pbi'] = np.array({'pbi_total': cf_pbi_total,
            'pbi_total_fed': pbi_total_fed,
            'pbi_total_oth': pbi_total_oth,
            'pbi_total_sta': pbi_total_sta,
            'pbi_total_uti': pbi_total_uti
            })
    agent.loc['cash_incentives'] = '' # TODO
    agent.loc['export_tariff_results'] = '' # TODO

    outputs = {'npv': npv,
               'payback': payback,
               'first_year_bill_without_system': first_year_elec_bill_without_system,
               'first_year_bill_with_system': first_year_elec_bill_with_system,
               'system_size_kw': system_kw
              }

    out_cols = ['agent_id',
                'system_kw',
                'batt_kw',
                'batt_kwh',
                'npv',
                'cash_flow',
                'batt_dispatch_profile',
                'annual_energy_production_kwh',
                'naep',
                'capacity_factor',
                'first_year_elec_bill_with_system',
                'first_year_elec_bill_savings',
                'first_year_elec_bill_savings_frac',
                'max_system_kw',
                'first_year_elec_bill_without_system',
                'avg_elec_price_cents_per_kwh',
                'cbi',
                'ibi',
                'pbi',
                'cash_incentives',
                'export_tariff_results'
                ]

    return agent[out_cols]

