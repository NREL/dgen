import numpy as np
import pandas as pd
import decorators
from scipy import optimize
import settings
import utility_functions as utilfunc
import agent_mutation
import PySAM.Battery as battery
import PySAM.BatteryTools as battery_tools
import PySAM.Utilityrate5 as utility
import PySAM.Cashloan as cashloan


#==============================================================================
# Load logger
logger = utilfunc.get_logger()
#==============================================================================


#%%
def calc_system_performance(kw, pv, utilityrate, loan, batt, costs, agent, rate_switch_table, en_batt=True, batt_dispatch='peak_shaving'):
    """
    Calculates the financial performance, in NPV, of the optimal system using PySAM modules
    
    Parameters
    ----------
    kw : float
        PV System size or PV Capacity (in kW) 

    pv : dict 
        Contains two attributes of the agent, hourly PV generation profile and hourly PV consumption, as an array (float) in kW for the whole year (8760)

    utilityrate : :class: `PySAM.Utilityrate5` 
        PySAM utility rate module that contais the utility rate assigned to each agent used for assessing the system performance

    loan : :class: `PySAM.Cashloan`
        PySAM module that contains the finanancial paramters used for calculating the system performance

    batt : :class: `PySAM.Battery`
        It is the simplified battery storage model from PySAM used for evaluating the system performance

    costs : dict
        Maps the cost components for Solar PV and the Battery systems as a scalar (float) value (?maps the cost component for the technology in questions?)

    agent : :class: `pandas.Series`
        Contains the attributes of one agent 

    rate_switch_table : :class: `pandas.DataFrame`
        Has details on how utility rates will switch with DG/storage adoption

    en_batt : bool, Optional
        When this arguement is True, battery is included in the analysis and vice versa when False. 
        Default is "True"

    batt_dispatch : str, Optional
        Parameters contains the battery dispatch model to be used in the analysis 
        Default is "Peak Shaving", all other options result in "Retail Rate Dispatch"
                
    Returns
    -------
    -loan.Outputs.npv : float
        The negative net present value of the system modeled calculated with the PySAM Cashloan module

    References
    ----------
    Please refer to PySAM documentation for additional information on the Battwatts, Utilityrate, and Cashloan modules. 
    https://nrel-pysam.readthedocs.io/en/main/index.html 

    """

    inv_eff = 0.96  # default SAM inverter efficiency for PV
    gen_hourly = pv['generation_hourly']
    load_hourly = pv['consumption_hourly']  # same field as 'load_kwh_per_customer_in_bin_initial' when summed

    dc = [(i * kw) * 1000 for i in gen_hourly] # W
    ac = [i * inv_eff for i in dc] # W
    gen = [i / 1000 for i in ac] # W to kW
    
    # Set up battery, with system generation conditional on the battery generation being included
    if en_batt:

        batt.BatterySystem.en_batt = 1
        batt.BatterySystem.batt_ac_or_dc = 1  # AC connected
        batt.BatteryCell.batt_chem =  1  # default value is 1: li ion for residential
        batt.BatterySystem.batt_meter_position = 0 # behind the meter

        # need to consider lifetime since pysam needs profiles for all years if considering replacement.
        batt.Lifetime.system_use_lifetime_output = 0
        batt.BatterySystem.batt_replacement_option = 0

        # PV to Battery ratio (kW) - From Ashreeta, 02/08/2020
        pv_to_batt_ratio = 1.31372
        batt_capacity_to_power_ratio = 2 # hours of operation
        
        desired_size = kw / pv_to_batt_ratio # Default SAM value for residential systems is 10 
        desired_power = desired_size / batt_capacity_to_power_ratio
        desired_voltage = 500 if agent.loc['sector_abbr'] != 'res' else 240
        
        # Size battery using desired parameters
        battery_tools.battery_model_sizing(batt, desired_power, desired_size, desired_voltage=desired_voltage, tol=1e38)

        # copy over gen and load
        batt.Load.load = load_hourly #kw
        batt.SystemOutput.gen = gen

        # Set dispatch option and associated parameters in detailed battery model
        if batt_dispatch =='peak_shaving':
            batt.BatteryDispatch.batt_dispatch_choice = 0
        else:
            batt.BatteryDispatch.batt_dispatch_choice = 4
        batt.BatteryDispatch.batt_dispatch_auto_can_charge = 1
        batt.BatteryDispatch.batt_dispatch_auto_can_clipcharge = 1
        batt.BatteryDispatch.batt_dispatch_auto_can_gridcharge = 1
        cycle_cost_list = [0.1]
        batt.BatteryDispatch.batt_cycle_cost = cycle_cost_list
        batt.BatteryDispatch.batt_cycle_cost_choice = 0

        batt.execute()

        # apply storage rate switch if computed_size is nonzero
        if batt.BatterySystem.batt_computed_bank_capacity > 0.:
            agent, one_time_charge = agent_mutation.elec.apply_rate_switch(rate_switch_table, agent, batt.BatterySystem.batt_computed_bank_capacity, tech='storage')
        else:
            one_time_charge = 0.
              
        # declare value for net billing sell rate
        if agent.loc['compensation_style']=='none':
            net_billing_sell_rate = 0.
        else:
            net_billing_sell_rate = agent.loc['wholesale_elec_price_dollars_per_kwh'] * agent.loc['elec_price_multiplier']
        
        utilityrate = process_tariff(utilityrate, agent.loc['tariff_dict'], net_billing_sell_rate)
        utilityrate.SystemOutput.gen = batt.SystemOutput.gen 
        loan.BatterySystem.en_batt = 1
        loan.BatterySystem.batt_computed_bank_capacity = batt.Outputs.batt_bank_installed_capacity
        loan.BatterySystem.batt_bank_replacement = batt.Outputs.batt_bank_replacement

        # specify number of O&M types (1 = PV+batt)
        loan.SystemCosts.add_om_num_types = 1
        # if PV system size nonzero, specify combined O&M costs; otherwise, specify standalone O&M costs
        if kw > 0:
            loan.BatterySystem.battery_per_kWh = costs['batt_capex_per_kwh_combined']
            
            loan.SystemCosts.om_capacity = [costs['system_om_per_kw_combined'] + costs['system_variable_om_per_kw_combined']]
            loan.SystemCosts.om_batt_capacity_cost = [costs['batt_om_per_kw_combined']]
            loan.SystemCosts.om_batt_variable_cost = [costs['batt_om_per_kwh_combined'] * 1000.]
            loan.SystemCosts.om_batt_replacement_cost = [0.]
            loan.SystemCosts.om_batt_nameplate = batt.Outputs.batt_bank_installed_capacity
            
            system_costs = costs['system_capex_per_kw_combined'] * kw

            # specify linear constant adder for PV+batt (combined) system
            linear_constant = agent.loc['linear_constant_combined']


        else:
            loan.BatterySystem.battery_per_kWh = costs['batt_capex_per_kwh']
            
            loan.SystemCosts.om_capacity = [costs['system_om_per_kw'] + costs['system_variable_om_per_kw']]
            loan.SystemCosts.om_batt_capacity_cost = [costs['batt_om_per_kw']]
            loan.SystemCosts.om_batt_variable_cost = [costs['batt_om_per_kwh'] * 1000.]
            loan.SystemCosts.om_batt_replacement_cost = [0.]
            loan.SystemCosts.om_batt_nameplate = batt.Outputs.batt_bank_installed_capacity
            
            system_costs = costs['system_capex_per_kw'] * kw

            # specify linear constant adder for standalone battery system
            linear_constant = agent.loc['linear_constant']

        
        # Battery production for System Costs values [kWh]
        #loan.SystemCosts.om_production1_values = [batt.Outputs.batt_bank_installed_capacity] # Use actual production from battery run for variable O&M
        loan.SystemCosts.om_production1_values = batt.Outputs.batt_annual_discharge_energy
 
        batt_costs = ((costs['batt_capex_per_kw_combined']* batt.BatterySystem.batt_power_charge_max_kwdc) + 
                      (costs['batt_capex_per_kwh_combined'] * batt.Outputs.batt_bank_installed_capacity))
        value_of_resiliency = agent.loc['value_of_resiliency_usd']
        
    else:
        batt.BatterySystem.en_batt = 0
        loan.BatterySystem.en_batt = 0
        loan.LCOS.batt_annual_charge_energy = [0]
        loan.LCOS.batt_annual_charge_from_system = [0]
        loan.LCOS.batt_annual_discharge_energy = [0]
        loan.LCOS.batt_capacity_percent = [0]
        loan.LCOS.batt_salvage_percentage = 0
        loan.LCOS.battery_total_cost_lcos = 0
        
        # apply solar rate switch if computed_size is nonzero
        if kw > 0:
            agent, one_time_charge = agent_mutation.elec.apply_rate_switch(rate_switch_table, agent, kw, tech='solar')
        else:
            one_time_charge = 0.

        # declare value for net billing sell rate
        if agent.loc['compensation_style']=='none':
            net_billing_sell_rate = 0.
        else:
            net_billing_sell_rate = agent.loc['wholesale_elec_price_dollars_per_kwh'] * agent.loc['elec_price_multiplier']
        
        # Instantiate the unique utility rates for the agent
        utilityrate = process_tariff(utilityrate, agent.loc['tariff_dict'], net_billing_sell_rate)
        utilityrate.SystemOutput.gen = gen
        
        # specify number of O&M types (0 = PV only)
        loan.SystemCosts.add_om_num_types = 0 # This is the PySAM default, can be removed

        # since battery system size is zero, specify standalone PV O&M costs
        loan.SystemCosts.om_capacity = [costs['system_om_per_kw'] + costs['system_variable_om_per_kw']]
        loan.SystemCosts.om_batt_replacement_cost = [0.]
        loan.SystemCosts.om_batt_nameplate = 0
        
        system_costs = costs['system_capex_per_kw'] * kw

        batt_costs = 0.

        # linear constant for standalone PV system is 0.
        linear_constant = 0.

        value_of_resiliency = 0.

    # Execute utility rate module
    utilityrate.Load.load = load_hourly

    utilityrate.execute()

    # Add incentives to the cashloan module
    loan = process_incentives(loan, gen_hourly, agent) 
    
    # Assign system capacity to calculate kw value
    loan.FinancialParameters.system_capacity = kw

    # Add value_of_resiliency -- should only apply from year 1 onwards, not to year 0
    annual_energy_value = ([utilityrate.Outputs.annual_energy_value[0]] + 
                           [x + value_of_resiliency for i,x in enumerate(utilityrate.Outputs.annual_energy_value) if i!=0])
    
    # Assign calculated values to the CashLoan module
    loan.SystemOutput.annual_energy_value = annual_energy_value 
    loan.SystemOutput.gen = utilityrate.SystemOutput.gen
    loan.ThirdPartyOwnership.elec_cost_with_system = utilityrate.Outputs.elec_cost_with_system
    loan.ThirdPartyOwnership.elec_cost_without_system = utilityrate.Outputs.elec_cost_without_system

    # Calculate system costs
    direct_costs = (system_costs + batt_costs) * costs['cap_cost_multiplier']
    sales_tax = 0.
    loan.SystemCosts.total_installed_cost = direct_costs + linear_constant + sales_tax + one_time_charge
    
    # Execute financial module 
    loan.execute()

    return -loan.Outputs.npv


def calc_system_size_and_performance(agent, rate_switch_table):
    """
    Calculate the optimal system and battery size and generation profile, and resulting bill savings and financial metrics.
    
    Parameters
    ----------
    agent : :class: `pandas.Series`
        Contains the attributes of one agent 
        
    rate_switch_table : :class: `pandas.DataFrame` 
        Has details on how utility rates will switch with DG/storage adoption
    
    Returns
    -------
    agent : :class: `pandas.Series`
        Updated agent object with new attributes representing the financial and size characteristics of the system to be adopted. 
        Check function notes for list of new attribtes.
        
    Notes
    -----
    Methodology: 
        -   This function uses three PySAM modules viz., Battwatts, Cashloan, and Utilityrate, to calculate the financial performance of the system to be installed by the agent.
        -   All the inputs for the three PySAM modules are assigned first assinged.  
        -   Then using *"calc_system_performance"*, *"scipy.optimize"*, and *"process_tariff"* function, optimized system (PV & Battery) size is calculated based on NPV. 
        -   Related financial characteristics of the selected system are assigned to the agent for adoption decision. 

    List of new variables added to the agent file: 
        -   agent_id
        -   system_kw - system capacity selected by agent
        -   batt_kw - battery capacity selected by agent
        -   batt_kwh - battery energy capacity
        -   npv - net present value of system + storage
        -   cash_flow  - array of annual cash flows from system adoption
        -   batt_dispatch_profile - array of hourly battery dispatch
        -   annual_energy_production_kwh - annual energy production (kwh) of system
        -   naep - normalized annual energy production (kwh/kW) of system
        -   capacity_factor - annual capacity factor
        -   first_year_elec_bill_with_system - first year electricity bill with adopted system ($/yr)
        -   first_year_elec_bill_savings - first year electricity bill savings with adopted system ($/yr)
        -   first_year_elec_bill_savings_frac - fraction of savings on electricity bill in first year of system adoption
        -   max_system_kw - maximum system size allowed as constrained by roof size or not exceeding annual consumption 
        -   first_year_elec_bill_without_system - first year electricity bill without adopted system ($/yr)
        -   avg_elec_price_cents_per_kwh - first year electricity price (c/kwh)
        -   cbi - ndarray of capacity-based incentives applicable to agent
        -   ibi - ndarray of investment-based incentives applicable to agent
        -   pbi - ndarray of performance-based incentives applicable to agent
        -   cash_incentives - ndarray of cash-based incentives applicable to agent
        -   export_tariff_result - summary of structure of retail tariff applied to agent

    References
    ----------
    Please refer to PySAM documentation for additional information on the Battwatts, Utilityrate, and Cashloan modules. 
    https://nrel-pysam.readthedocs.io/en/main/index.html 

    """

    # Initialize new DB connection    
    model_settings = settings.init_model_settings()
    con, cur = utilfunc.make_con(model_settings.pg_conn_string, model_settings.role)

    # add PV consumption profile to the agent 
    pv = dict()
    load_profile_df = agent_mutation.elec.get_and_apply_agent_load_profiles(con, agent)
    pv['consumption_hourly'] = pd.Series(load_profile_df['consumption_hourly']).iloc[0]
    del load_profile_df

    # Using the scale offset factor of 1E6 for capacity factors
    norm_scaled_pv_cf_profiles_df = agent_mutation.elec.get_and_apply_normalized_hourly_resource_solar(con, agent)
    pv['generation_hourly'] = pd.Series(norm_scaled_pv_cf_profiles_df['solar_cf_profile'].iloc[0]) /  1e6
    del norm_scaled_pv_cf_profiles_df
    
    # normalized annual energy production (kwh/kW) of system
    agent.loc['naep'] = float(np.sum(pv['generation_hourly'])) 

    # Set the battery type to use based on agent sector
    if agent.loc['sector_abbr'] == 'res':
        batt = battery.default("GenericBatteryResidential")
    else:
        batt = battery.default("GenericBatteryCommercial")

    # Instantiate utilityrate5 model based on agent sector
    if agent.loc['sector_abbr'] == 'res':
        utilityrate = utility.from_existing(batt, "GenericBatteryResidential")
    else:
        utilityrate = utility.from_existing(batt, "GenericBatteryCommercial")
    
    ######################################
    ###--------- UTILITYRATE5 ---------###
    ###--- SYSTEM LIFETIME SETTINGS ---###
    ######################################
    
    # Inflation rate [%]
    utilityrate.Lifetime.inflation_rate = agent.loc['inflation_rate'] * 100
    
    # Number of years in analysis [years]
    utilityrate.Lifetime.analysis_period = agent.loc['economic_lifetime_yrs']
    
    # Lifetime hourly system outputs [0/1]; Options: 0=hourly first year,1=hourly lifetime
    utilityrate.Lifetime.system_use_lifetime_output = 0

    ######################################
    ###--------- UTILITYRATE5 ---------###
    ###---- DEGRADATION/ESCALATION ----###
    ######################################
    
    # Annual energy degradation [%]
    utilityrate.SystemOutput.degradation = [agent.loc['pv_degradation_factor'] * 100] # convert decimal to %

    # Annual electricity rate escalation [%/year]
    utilityrate.ElectricityRates.rate_escalation  = [agent.loc['elec_price_escalator'] * 100] # convert decimal to %

    ######################################
    ###--------- UTILITYRATE5 ---------###
    ###---- NET METERING SETTINGS -----###
    ######################################
    
    # Dictionary to map dGen compensation styles to PySAM options
    nem_options = {'net metering':0, 'net billing':2, 'buy all sell all':4, 'none':2}
   
    # Metering options [0=net energy metering,1=net energy metering with $ credits,2=net billing,3=net billing with carryover to next month,4=buy all - sell all]
    utilityrate.ElectricityRates.ur_metering_option = nem_options[agent.loc['compensation_style']]
    
    # Year end sell rate [$/kWh]
    utilityrate.ElectricityRates.ur_nm_yearend_sell_rate = agent.loc['wholesale_elec_price_dollars_per_kwh'] * agent.loc['elec_price_multiplier']

    # Use compensation style to determine net billing sell rate
    if agent.loc['compensation_style']=='none':
        net_billing_sell_rate = 0.
    else:
        net_billing_sell_rate = agent.loc['wholesale_elec_price_dollars_per_kwh'] * agent.loc['elec_price_multiplier']
        
    ######################################
    ###--------- UTILITYRATE5 ---------###
    ###-------- BUY/SELL RATES --------###
    ######################################
    
    # Enable time step sell rates [0/1]
    utilityrate.ElectricityRates.ur_en_ts_sell_rate = 0
    
    # Time step sell rates [0/1]
    utilityrate.ElectricityRates.ur_ts_sell_rate = [0.]
    
    # Set sell rate equal to buy rate [0/1]
    utilityrate.ElectricityRates.ur_sell_eq_buy = 0
    
    ######################################
    ###--------- UTILITYRATE5 ---------###
    ###-------- MISC. SETTINGS --------###
    ######################################
    
    # Use single monthly peak for TOU demand charge; options: 0=use TOU peak,1=use flat peak
    utilityrate.ElectricityRates.TOU_demand_single_peak = 0 
    
    # Optionally enable/disable electricity_rate [years]
    utilityrate.ElectricityRates.en_electricity_rates = 1

    ######################################
    ###--------- UTILITYRATE5 ---------###
    ###----- TARIFF RESTRUCTURING -----###
    ######################################
   
    # Instantiate unique tariff rates for the agent
    utilityrate = process_tariff(utilityrate, agent.loc['tariff_dict'], net_billing_sell_rate)
    
    ######################################
    ###----------- CASHLOAN -----------###
    ###----- FINANCIAL PARAMETERS -----###
    ######################################

    # Initiate cashloan model and set market-specific variables
    # Assume res agents do not evaluate depreciation at all
    # Assume non-res agents only evaluate federal depreciation (not state)
    if agent.loc['sector_abbr'] == 'res':
        loan = cashloan.from_existing(utilityrate, "GenericBatteryResidential")
        loan.FinancialParameters.market = 0

    else:
        loan = cashloan.from_existing(utilityrate, "GenericBatteryCommercial")
        loan.FinancialParameters.market = 1

    # Assign values to PySAM CashLoan module
    loan.FinancialParameters.analysis_period = agent.loc['economic_lifetime_yrs']
    loan.FinancialParameters.debt_fraction = 100 - (agent.loc['down_payment_fraction'] * 100)
    loan.FinancialParameters.federal_tax_rate = [(agent.loc['tax_rate'] * 100) * 0.7] # SAM default
    loan.FinancialParameters.inflation_rate = agent.loc['inflation_rate'] * 100
    loan.FinancialParameters.insurance_rate = 0
    loan.FinancialParameters.loan_rate = agent.loc['loan_interest_rate'] * 100    
    loan.FinancialParameters.loan_term = agent.loc['loan_term_yrs']
    loan.FinancialParameters.mortgage = 0 # default value - standard loan (no mortgage)
    loan.FinancialParameters.prop_tax_assessed_decline = 5 # PySAM default
    loan.FinancialParameters.prop_tax_cost_assessed_percent = 95 # PySAM default
    loan.FinancialParameters.property_tax_rate = 0 # PySAM default
    loan.FinancialParameters.real_discount_rate = agent.loc['real_discount_rate'] * 100
    loan.FinancialParameters.salvage_percentage = 0    
    loan.FinancialParameters.state_tax_rate = [(agent.loc['tax_rate'] * 100) * 0.3] # SAM default
    loan.FinancialParameters.system_heat_rate = 0

    ######################################
    ###----------- CASHLOAN -----------###
    ###--------- SYSTEM COSTS ---------###
    ######################################
    
    # System costs that are input to loan.SystemCosts will depend on system configuration (PV, batt, PV+batt)
    # and are therefore specified in calc_system_performance()

    system_costs = dict()
    system_costs['system_capex_per_kw'] = agent.loc['system_capex_per_kw']
    system_costs['system_om_per_kw'] = agent.loc['system_om_per_kw']
    system_costs['system_variable_om_per_kw'] = agent.loc['system_variable_om_per_kw']
    system_costs['cap_cost_multiplier'] = agent.loc['cap_cost_multiplier']
    system_costs['batt_capex_per_kw'] = agent.loc['batt_capex_per_kw']
    system_costs['batt_capex_per_kwh'] = agent.loc['batt_capex_per_kwh']
    system_costs['batt_om_per_kw'] = agent.loc['batt_om_per_kw']
    system_costs['batt_om_per_kwh'] = agent.loc['batt_om_per_kwh']
    system_costs['linear_constant'] = agent.loc['linear_constant']

    # costs for PV+batt configuration are distinct from standalone techs
    system_costs['system_capex_per_kw_combined'] = agent.loc['system_capex_per_kw_combined']
    system_costs['system_om_per_kw_combined'] = agent.loc['system_om_per_kw']
    system_costs['system_variable_om_per_kw_combined'] = agent.loc['system_variable_om_per_kw']
    system_costs['batt_capex_per_kw_combined'] = agent.loc['batt_capex_per_kw_combined']
    system_costs['batt_capex_per_kwh_combined'] = agent.loc['batt_capex_per_kwh_combined']
    system_costs['batt_om_per_kw_combined'] = agent.loc['batt_om_per_kw_combined']
    system_costs['batt_om_per_kwh_combined'] = agent.loc['batt_om_per_kwh_combined']
    system_costs['linear_constant_combined'] = agent.loc['linear_constant_combined']
    

    ######################################
    ###----------- CASHLOAN -----------###
    ###---- DEPRECIATION PARAMETERS ---###
    ######################################
    
    if agent.loc['sector_abbr'] == 'res':
        loan.Depreciation.depr_fed_type = 0
        loan.Depreciation.depr_sta_type = 0
    else:
        loan.Depreciation.depr_fed_type = 1
        loan.Depreciation.depr_sta_type = 0
    
    ######################################
    ###----------- CASHLOAN -----------###
    ###----- TAX CREDIT INCENTIVES ----###
    ######################################
    
    loan.TaxCreditIncentives.itc_fed_percent = [agent.loc['itc_fraction_of_capex'] * 100]

    ######################################
    ###----------- CASHLOAN -----------###
    ###-------- BATTERY SYSTEM --------###
    ######################################

    loan.BatterySystem.batt_replacement_option = 2 # user schedule
    
    batt_replacement_schedule = [0 for i in range(0, agent.loc['batt_lifetime_yrs'] - 1)] + [1]
    loan.BatterySystem.batt_replacement_schedule_percent = batt_replacement_schedule
    
    ######################################
    ###----------- CASHLOAN -----------###
    ###-------- SYSTEM OUTPUT ---------###
    ######################################
    
    loan.SystemOutput.degradation = [agent.loc['pv_degradation_factor'] * 100]
    
    ######################################
    ###----------- CASHLOAN -----------###
    ###----------- LIFETIME -----------###
    ######################################
    
    loan.Lifetime.system_use_lifetime_output = 0

    ###################################### 
    ###-------- SYSTEM SIZING ---------### 
    ######################################

    # From dGen - calc_system_size_and_financial_performance()
    max_size_load = agent.loc['load_kwh_per_customer_in_bin'] / agent.loc['naep']
    max_size_roof = agent.loc['developable_roof_sqft'] * agent.loc['pv_kw_per_sqft']
    max_system_kw = min(max_size_load, max_size_roof)
    
    # set tolerance for minimize_scalar based on max_system_kw value
    tol = min(0.25 * max_system_kw, 0.5)
    min_system_kw = min(0.3, max_system_kw)

    # # Calculate the PV system size that maximizes the agent's NPV, to a tolerance of 0.5 kW. 
    # # Note that the optimization is technically minimizing negative NPV
    # # ! As is, because of the tolerance this function would not necessarily return a system size of 0 or max PV size if those are optimal
    batt_dispatch = 'peak_shaving' if agent.loc['sector_abbr'] != 'res' else 'price_signal_forecast'
    res_with_batt = optimize.minimize_scalar(calc_system_performance,
                                             args = (pv, utilityrate, loan, batt, system_costs, agent, rate_switch_table, True, batt_dispatch),
                                             bounds = (min_system_kw, max_system_kw),
                                             method = 'bounded',
                                             options={'xatol':tol})

    # PySAM Module outputs with battery
    batt_loan_outputs = loan.Outputs.export()
    batt_util_outputs = utilityrate.Outputs.export()
    batt_annual_energy_kwh = np.sum(utilityrate.SystemOutput.gen)

    batt_kw = batt.BatterySystem.batt_power_charge_max_kwdc
    batt_kwh = batt.Outputs.batt_bank_installed_capacity
    batt_dispatch_profile = batt.Outputs.batt_power 
    npv_w_batt = batt_loan_outputs['npv']

    # Optimize the system without battery
    res_no_batt = optimize.minimize_scalar(calc_system_performance, 
                                           args = (pv, utilityrate, loan, batt, system_costs, agent, rate_switch_table, False, 0),
                                           bounds = (0.0, max_system_kw),
                                           method = 'bounded',
                                           options={'xatol':tol})
                                        #    tol = tol)

    # PySAM Module outputs without battery
    no_batt_loan_outputs = loan.Outputs.export()
    no_batt_util_outputs = utilityrate.Outputs.export()
    no_batt_annual_energy_kwh = np.sum(utilityrate.SystemOutput.gen)

    # Retrieve NPVs of system with batt and system without batt
    npv_no_batt = no_batt_loan_outputs['npv']

    # Assign relevant values from optimization based on the system with the higher NPV
    if npv_w_batt >= npv_no_batt:
        system_kw = res_with_batt.x
        annual_energy_production_kwh = batt_annual_energy_kwh
        first_year_elec_bill_with_system = batt_util_outputs['elec_cost_with_system_year1']
        first_year_elec_bill_without_system = batt_util_outputs['elec_cost_without_system_year1']

        npv = npv_w_batt

        cash_flow = list(batt_loan_outputs['cf_payback_with_expenses']) 
        payback = batt_loan_outputs['payback']
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
        annual_energy_production_kwh = no_batt_annual_energy_kwh
        first_year_elec_bill_with_system = no_batt_util_outputs['elec_cost_with_system_year1']
        first_year_elec_bill_without_system = no_batt_util_outputs['elec_cost_without_system_year1']

        npv = npv_no_batt
        payback = no_batt_loan_outputs['payback']
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
    agent.loc['payback_period'] = np.round(np.where(np.isnan(payback), 30.1, payback), 1).astype(float)
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
    agent.loc['cash_incentives'] = ''
    agent.loc['export_tariff_results'] = '' 

    # List of comulmns to keep with the agent file when funciton is returned 
    out_cols = ['agent_id',
                'system_kw',
                'batt_kw',
                'batt_kwh',
                'npv',
                'payback_period',
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

#%%
def process_tariff(utilityrate, tariff_dict, net_billing_sell_rate):
    """
    Instantiate the UtilityRate5 PySAM model and process the agent's utility rate json object to conform with PySAM input formatting.
    
    Parameters
    ----------
    utilityrate : :class: `PySAM.Utilityrate5`
        UtilityRate5 object used for assessing the system performance

    tariff_dict :  dict
        An agent attribute that maps components of the tariff rate that will be used by PySAM UtilityRate Module

    net_billing_sell_rate : float
        Net billing sell rate ($/kW) set by the utility the agent is residing. 

    Returns
    -------
    utilityrate: :class: `PySAM.Utilityrate5`
        Processed UtilityRate5 object with new utility rate variables assigned
    
    Notes
    -----
    The utility rate for agent is first downloaded from the Utility Rate Database (URDB) as a JSON file and merged to the agent.  

    References
    ----------
    Details about Utilityrate object in PySAM can be found here: https://nrel-pysam.readthedocs.io/en/main/modules/Utilityrate.html#utilityrate 
    Details about Utility Rate Database can be found here: https://openei.org/wiki/Utility_Rate_Database 

    """    
    
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
    
    # Assign the demand charge, will assign a Bool
    utilityrate.ElectricityRates.ur_dc_enable = (tariff_dict['d_flat_exists']) | (tariff_dict['d_tou_exists'])
   
    # If there is a demand charge, calculate and assign relevant values to 'utilityrate'
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

        # If max usage units are 'kWh daily', divide max usage by 30 -- rate download procedure converts daily to monthly
        # modifier = 30. if tariff_dict['energy_rate_unit'] == 'kWh daily' else 1.
        
        # Reformat energy charge table from dGen format
        n_periods = len(tariff_dict['e_levels'][0])
        n_tiers = len(tariff_dict['e_levels'])
        ur_ec_tou_mat = []
        for period in range(n_periods):
            for tier in range(n_tiers):
                row = [period+1, tier+1, tariff_dict['e_levels'][tier][period], max_usage_dict[tariff_dict['energy_rate_unit']],
                 tariff_dict['e_prices'][tier][period], net_billing_sell_rate]
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
        
    
    return utilityrate


#%%
def process_incentives(loan, generation_hourly, agent):
    """
    Find and apply any appropriate incentives to the Cashloan PySAM module for the agent
    Incentives can be capacity based (CBI), production based (PBI), or investment based (IBI)
    
    Parameters
    ----------
    loan : :class: `PySAM.Cashloan`
        PySAM Cashloan object containing the finanancial paramters used for calculating the system performance 

    generation_hourly : :class: `pandas.Series`
        Contains hourly PV generation profile , as an array (float) in kW for the whole year (8760)

    agent : :class: `pandas.Series`
        Contains the attributes of one agent as an object 
    
    Returns
    -------
    loan : :class: `PySAM.Cashloan` 
        PySAM Cashloan object updated with relevant incentives applicable for the agent. 
    
    Notes
    ------
    - Only a maximum of two of each type of incentives per state can be applied to the agent. 

    """    

    ######################################
    ###----------- CASHLOAN -----------###
    ###------ PAYMENT INCENTIVES ------###
    ######################################

    # Read incentive dataframe from agent attributes
    incentive_df = agent.loc['state_incentives']
    
    # Check dtype of incentive_df - process incentives if pd.DataFrame, otherwise do not assign incentive values to cashloan
    if isinstance(incentive_df, pd.DataFrame):
        
        # Fill NaNs in incentive_df - assume max incentive duration of 5 years and max incentive value of $10,000
        incentive_df = incentive_df.fillna(value={'incentive_duration_yrs' : 5, 'max_incentive_usd' : 10000})
        
        # Filter for CBI's in incentive_df
        cbi_df = (incentive_df.loc[pd.notnull(incentive_df['cbi_usd_p_w'])]                  
                  .sort_values(['cbi_usd_p_w'], axis=0, ascending=False)
                  .reset_index(drop=True)
                 )
        
        # Process state capacity-based incentives (CBI)        
        # For multiple CBIs that are applicable to the agent, cap at 2 and use PySAM's "state" and "other" option
        if len(cbi_df) == 1:
            
            loan.PaymentIncentives.cbi_sta_amount = cbi_df['cbi_usd_p_w'].iloc[0]
            loan.PaymentIncentives.cbi_sta_deprbas_fed = 0
            loan.PaymentIncentives.cbi_sta_deprbas_sta = 0
            loan.PaymentIncentives.cbi_sta_maxvalue = cbi_df['max_incentive_usd'].iloc[0]
            loan.PaymentIncentives.cbi_sta_tax_fed = 0
            loan.PaymentIncentives.cbi_sta_tax_sta = 0
            
        elif len(cbi_df) >= 2:
            
            loan.PaymentIncentives.cbi_sta_amount = cbi_df['cbi_usd_p_w'].iloc[0]
            loan.PaymentIncentives.cbi_sta_deprbas_fed = 0
            loan.PaymentIncentives.cbi_sta_deprbas_sta = 0
            loan.PaymentIncentives.cbi_sta_maxvalue = cbi_df['max_incentive_usd'].iloc[0]
            loan.PaymentIncentives.cbi_sta_tax_fed = 1
            loan.PaymentIncentives.cbi_sta_tax_sta = 1
            
            loan.PaymentIncentives.cbi_oth_amount = cbi_df['cbi_usd_p_w'].iloc[1]
            loan.PaymentIncentives.cbi_oth_deprbas_fed = 0
            loan.PaymentIncentives.cbi_oth_deprbas_sta = 0
            loan.PaymentIncentives.cbi_oth_maxvalue = cbi_df['max_incentive_usd'].iloc[1]
            loan.PaymentIncentives.cbi_oth_tax_fed = 1
            loan.PaymentIncentives.cbi_oth_tax_sta = 1
            
        else:
            pass
        
        # Filter for PBI's in incentive_df
        pbi_df = (incentive_df.loc[pd.notnull(incentive_df['pbi_usd_p_kwh'])]
                  .sort_values(['pbi_usd_p_kwh'], axis=0, ascending=False)
                  .reset_index(drop=True)
                 )
        
        # Process state production-based incentives (CBI)
        agent.loc['timesteps_per_year'] = 1
        pv_kwh_by_year = np.array(list(map(lambda x: sum(x), np.split(np.array(generation_hourly), agent.loc['timesteps_per_year']))))
        pv_kwh_by_year = np.concatenate([(pv_kwh_by_year - (pv_kwh_by_year * agent.loc['pv_degradation_factor'] * i)) for i in range(1, agent.loc['economic_lifetime_yrs']+1)])
        
        # For multiple PBIs that are applicable to the agent, cap at 2 and use PySAM's "state" and "other" option
        if len(pbi_df) == 1:
            
            # Assign the incentives to the Cashloan Object
            # 'loan.*_*_amount' variable requires sequence -- repeat pbi_usd_p_kwh using incentive_duration_yrs 
            loan.PaymentIncentives.pbi_sta_amount = [pbi_df['pbi_usd_p_kwh'].iloc[0]] * int(pbi_df['incentive_duration_yrs'].iloc[0]) # Amount input [$/kWh] requires sequence
            loan.PaymentIncentives.pbi_sta_escal = 0.
            loan.PaymentIncentives.pbi_sta_tax_fed = 1
            loan.PaymentIncentives.pbi_sta_tax_sta = 1
            loan.PaymentIncentives.pbi_sta_term = pbi_df['incentive_duration_yrs'].iloc[0]
            
        elif len(pbi_df) >= 2:
            # Assign the incentives to the Cashloan Object
            # 'loan.*_*_amount' variable requires sequence -- repeat pbi_usd_p_kwh using incentive_duration_yrs 
            loan.PaymentIncentives.pbi_sta_amount = [pbi_df['pbi_usd_p_kwh'].iloc[0]] * int(pbi_df['incentive_duration_yrs'].iloc[0])
            loan.PaymentIncentives.pbi_sta_escal = 0.
            loan.PaymentIncentives.pbi_sta_tax_fed = 1
            loan.PaymentIncentives.pbi_sta_tax_sta = 1
            loan.PaymentIncentives.pbi_sta_term = pbi_df['incentive_duration_yrs'].iloc[0]
            
            # Repeat above for "other" pbi incentives
            loan.PaymentIncentives.pbi_oth_amount = [pbi_df['pbi_usd_p_kwh'].iloc[1]] * int(pbi_df['incentive_duration_yrs'].iloc[1])
            loan.PaymentIncentives.pbi_oth_escal = 0.
            loan.PaymentIncentives.pbi_oth_tax_fed = 1
            loan.PaymentIncentives.pbi_oth_tax_sta = 1
            loan.PaymentIncentives.pbi_oth_term = pbi_df['incentive_duration_yrs'].iloc[1]
            
        else:
            pass
        
        # Filter for IBI's in incentive_df
        ibi_df = (incentive_df.loc[pd.notnull(incentive_df['ibi_pct'])]
                  .sort_values(['ibi_pct'], axis=0, ascending=False)
                  .reset_index(drop=True)
                 )
        
        # For multiple IBIs that are applicable to the agent, cap at 2 and use PySAM's "state" and "other" option
        # NOTE: this specifies IBI percentage, instead of IBI absolute amount
        if len(ibi_df) == 1:
    
            loan.PaymentIncentives.ibi_sta_percent = ibi_df['ibi_pct'].iloc[0]
            loan.PaymentIncentives.ibi_sta_percent_deprbas_fed = 0
            loan.PaymentIncentives.ibi_sta_percent_deprbas_sta = 0
            loan.PaymentIncentives.ibi_sta_percent_maxvalue = ibi_df['max_incentive_usd'].iloc[0]
            loan.PaymentIncentives.ibi_sta_percent_tax_fed = 1
            loan.PaymentIncentives.ibi_sta_percent_tax_sta = 1
            
        elif len(ibi_df) >= 2:
            
            loan.PaymentIncentives.ibi_sta_percent = ibi_df['ibi_pct'].iloc[0]
            loan.PaymentIncentives.ibi_sta_percent_deprbas_fed = 0
            loan.PaymentIncentives.ibi_sta_percent_deprbas_sta = 0
            loan.PaymentIncentives.ibi_sta_percent_maxvalue = ibi_df['max_incentive_usd'].iloc[0]
            loan.PaymentIncentives.ibi_sta_percent_tax_fed = 1
            loan.PaymentIncentives.ibi_sta_percent_tax_sta = 1
            
            loan.PaymentIncentives.ibi_oth_percent = ibi_df['ibi_pct'].iloc[1]
            loan.PaymentIncentives.ibi_oth_percent_deprbas_fed = 0
            loan.PaymentIncentives.ibi_oth_percent_deprbas_sta = 0
            loan.PaymentIncentives.ibi_oth_percent_maxvalue = ibi_df['max_incentive_usd'].iloc[1]
            loan.PaymentIncentives.ibi_oth_percent_tax_fed = 1
            loan.PaymentIncentives.ibi_oth_percent_tax_sta = 1
            
        else:
            pass
        
    else:
        pass
    
    return loan

#%%
@decorators.fn_timer(logger = logger, tab_level = 2, prefix = '')
def calc_max_market_share(dataframe, max_market_share_df):
    """
    Calculates the maximum marketshare available for each agent. 
    
    Parameters
    ----------
    dataframe : :class: `pandas.DataFrame`
        Agent file with updated financial statistics for the optimal system size selected
            
    max_market_share_df : :class: `pandas.DataFrame`
        this is a dataframe that contains a lookup on the willingness to pay for each agent's payback period from the optimized system 
    
    Returns
    -------
    dataframe : :class: `pandas.DataFrame`
        Agent file with the maximum market share attribute added 
 
    Notes
    -----
    The relationship between payback period and maximum market share were determined using a consumer survey. 

    References
    ----------
    More details about the survey and the relationship can be found here. https://www.nrel.gov/docs/fy16osti/65231.pdf 

    """

    in_cols = list(dataframe.columns)
    dataframe = dataframe.reset_index()
    
    # Create new columns in dataframe
    dataframe['business_model'] = 'host_owned'
    dataframe['metric'] = 'payback_period'
    
    # Convert metric value to integer as a primary key, then bound within max market share ranges
    max_payback = max_market_share_df[max_market_share_df.metric == 'payback_period'].payback_period.max()
    min_payback = max_market_share_df[max_market_share_df.metric == 'payback_period'].payback_period.min()
    max_mbs = max_market_share_df[max_market_share_df.metric == 'percent_monthly_bill_savings'].payback_period.max()
    min_mbs = max_market_share_df[max_market_share_df.metric == 'percent_monthly_bill_savings'].payback_period.min()
    
    # Copy the metric values to a new column to store an edited version
    payback_period_bounded = dataframe['payback_period'].values.copy()
    
    # where the metric value exceeds the corresponding max market curve bounds, set the value to the corresponding bound
    payback_period_bounded[np.where((dataframe.metric == 'payback_period') & (dataframe['payback_period'] < min_payback))] = min_payback
    payback_period_bounded[np.where((dataframe.metric == 'payback_period') & (dataframe['payback_period'] > max_payback))] = max_payback    
    payback_period_bounded[np.where((dataframe.metric == 'percent_monthly_bill_savings') & (dataframe['payback_period'] < min_mbs))] = min_mbs
    payback_period_bounded[np.where((dataframe.metric == 'percent_monthly_bill_savings') & (dataframe['payback_period'] > max_mbs))] = max_mbs
    
    # Assign payback_period_bounded column to dataframe
    dataframe['payback_period_bounded'] = np.round(payback_period_bounded.astype(float), 1)

    # scale and round to nearest int    
    dataframe['payback_period_as_factor'] = (dataframe['payback_period_bounded'] * 100).round().astype('int')

    # add a scaled key to the max_market_share dataframe too
    max_market_share_df['payback_period_as_factor'] = (max_market_share_df['payback_period'] * 100).round().astype('int')

    # Join the max_market_share table and dataframe in order to select the ultimate mms based on the metric value. 
    dataframe = pd.merge(dataframe, max_market_share_df[['sector_abbr', 'max_market_share', 'metric', 'payback_period_as_factor', 'business_model']], 
        how = 'left', on = ['sector_abbr', 'metric','payback_period_as_factor','business_model'])
    
    # Select for only necessary columns to be returned with dataframe
    out_cols = in_cols + ['max_market_share', 'metric']    

    return dataframe[out_cols]
