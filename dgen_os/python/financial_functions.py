import numpy as np
import pandas as pd
import decorators
import datetime
from scipy import optimize

import settings
import utility_functions as utilfunc
import agent_mutation

import pyarrow as pa
import pyarrow.parquet as pq

import PySAM.Battwatts as battery
import PySAM.BatteryTools as batt_tools
import PySAM.Utilityrate5 as utility
import PySAM.Cashloan as cashloan


#==============================================================================
# Load logger
logger = utilfunc.get_logger()
#==============================================================================


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

    # Calculate system costs
    system_costs = costs['system_capex_per_kw'] * kw
    direct_costs = (system_costs + batt_costs) * costs['cap_cost_multiplier']

    sales_tax = 0
    loan.SystemCosts.total_installed_cost = direct_costs + sales_tax
    
    loan.execute()

    return -loan.Outputs.npv


def calc_system_size_and_performance(agent, sectors, rate_switch_table=None):
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

    #load_profile_df = agent_mutation.elec.get_and_apply_agent_load_profiles(con, agent) # for full release, don't uncomment

    state_path = model_settings.load_path


    if any('res' in ele for ele in sectors):
        #load_profile_df = agent_mutation.elec.get_and_apply_residential_agent_load_profiles(con, 'res', agent) # *** for full release, don't uncomment ***
        de_ts = pd.read_parquet(state_path)
        s = str(agent.loc['bldg_id'])  # *** query 8760 by bdlg_id (residential version reformats bldg_id to str) ***

    elif any('com' in ele for ele in sectors):
        #load_profile_df = agent_mutation.elec.get_and_apply_commercial_agent_load_profiles(con, 'com', agent) # *** for full release, don't uncomment ***
        de_ts = pd.read_parquet(state_path)
        de_ts.rename(columns=lambda t: int(t.strip()), inplace=True) # *** get's rid of leading zeros & converts from str to int for com ***
        s = agent.loc['bldg_id']                                     # query 8760 by bdlg_id (commercial version)


    load_profile = pd.Series(de_ts[s].to_list())
    pv['consumption_hourly'] = load_profile


    #pv['consumption_hourly'] = pd.Series(load_profile_df['consumption_hourly']).iloc[0] # *** for full release, don't uncomment ***

    # Using the scale offset factor of 1E6 for capacity factors
    norm_scaled_pv_cf_profiles_df = agent_mutation.elec.get_and_apply_normalized_hourly_resource_solar(con, agent)
    pv['generation_hourly'] = pd.Series(norm_scaled_pv_cf_profiles_df['solar_cf_profile'].iloc[0]) /  1e6
    del norm_scaled_pv_cf_profiles_df
    
    agent.loc['naep'] = float(np.sum(pv['generation_hourly']))

    # Battwatts
    if agent.loc['sector_abbr'] == 'res':
        batt = battery.default("PVWattsBatteryResidential")
    else:
        batt = battery.default("PVWattsBatteryCommercial")

    # Utilityrate5
    if agent.loc['sector_abbr'] == 'res':
        utilityrate = utility.default("PVWattsBatteryResidential")
    else:
        utilityrate = utility.default("PVWattsBatteryCommercial")
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

    # Initiate cashloan model and set market-specific variables
    # Assume res agents do not evaluate depreciation at all
    # Assume non-res agents only evaluate federal depreciation (not state)
    if agent.loc['sector_abbr'] == 'res':
        loan = cashloan.default("PVWattsBatteryResidential")
        loan.FinancialParameters.market = 0
        loan.Depreciation.depr_fed_type = 0
        loan.Depreciation.depr_sta_type = 0
    else:
        loan = cashloan.default("PVWattsBatteryCommercial")
        loan.FinancialParameters.market = 1
        loan.Depreciation.depr_fed_type = 1
        loan.Depreciation.depr_sta_type = 0

    loan.Lifetime.system_use_lifetime_output = 0  # default value: outputs first year info only

    loan.FinancialParameters.inflation_rate = agent.loc['inflation_rate']
    loan.FinancialParameters.analysis_period = agent.loc['economic_lifetime_yrs']
    loan.FinancialParameters.loan_term = agent.loc['loan_term_yrs']
    loan.FinancialParameters.loan_rate = agent.loc['loan_interest_rate'] * 100 # decimal to %
    loan.FinancialParameters.debt_fraction = 100 - agent.loc['down_payment_fraction']
    loan.FinancialParameters.real_discount_rate = agent.loc['real_discount_rate'] * 100 # decimal to %
    loan.FinancialParameters.system_heat_rate = 0
    #loan.FinancialParameters.market = 0 if agent.loc['sector_abbr'] == 'res' else 1
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
    ###----- TAX CREDIT INCENTIVES ----###
    ######################################
    
    loan.TaxCreditIncentives.itc_fed_percent = agent.loc['itc_fraction_of_capex']
    
    ######################################
    ###----------- CASHLOAN -----------###
    ###------ PAYMENT INCENTIVES ------###
    ######################################
    
    # TODO: loan.PaymentIncentives

    
    # From dGen - calc_system_size_and_financial_performance()
    max_size_load = agent.loc['load_kwh_per_customer_in_bin'] / agent.loc['naep']
    max_size_roof = agent.loc['developable_roof_sqft'] * agent.loc['pv_kw_per_sqft']
    max_system_kw = min(max_size_load, max_size_roof)
    
    # set tolerance for minimize_scalar based on max_system_kw value
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
    batt_loan_outputs = loan.Outputs.export()
    batt_util_outputs = utilityrate.Outputs.export()
    batt_annual_energy_kwh = np.sum(utilityrate.SystemOutput.gen)

    batt_kw = batt.Battery.batt_simple_kw
    batt_kwh = batt.Battery.batt_simple_kwh
    batt_dispatch_profile = batt.Outputs.batt_power 

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
    agent.loc['cash_incentives'] = ''
    agent.loc['export_tariff_results'] = '' 

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


#%%
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


#%%
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


#%%
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

