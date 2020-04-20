select *
from diffusion_template.input_main_scenario_options;


select *
FROM diffusion_template.input_main_market_inflation;


select *
FROM diffusion_template.input_main_market_projections
order by 1;

-- select *
-- FROM diffusion_solar.market_projections
-- order by 1;


select *
from diffusion_template.input_main_market_flat_electric_rates
order by 1;

-- select *
-- from diffusion_solar.user_defined_electric_rates
-- order by 1;


select *
from diffusion_template.input_main_market_rate_type_weights
order by 1;

-- select *
-- from diffusion_solar.rate_type_weights
-- order by 1;


select *
FROM diffusion_template.input_main_market_carbon_intensities
order by 1;

-- select *
-- FROM diffusion_solar.manual_carbon_intensities
-- order by 1;


select *
FROM diffusion_template.input_main_nem_utility_types
order by 1;


select *
FROM diffusion_template.input_main_nem_avoided_costs
order by 1;

-- select *
-- FROM diffusion_solar.nem_scenario_avoided_costs
-- order by 1


select *
FROM  diffusion_template.input_main_nem_selected_scenario;


select *
FROM diffusion_template.input_main_nem_user_defined_scenario;


select *
FROM diffusion_template.input_main_nem_scenario;

-- select *
-- FROM diffusion_shared.nem_scenario_bau;
-- 
-- select *
-- FROM diffusion_shared.nem_scenario_none_everywhere;
-- 
-- select *
-- FROM diffusion_shared.nem_scenario_full_everywhere;


select *
FROM diffusion_template.input_solar_cost_projections_res
order by 1;

select *
FROM diffusion_template.input_solar_cost_projections_com
order by 1;

select *
FROM diffusion_template.input_solar_cost_projections_ind
order by 1;

select *
FROM diffusion_template.input_solar_cost_projections
order by 1;

-- select *
-- FROM diffusion_solar.solar_cost_projections
-- order by 1;


select *
FROM diffusion_template.input_solar_cost_learning_rates
order by 1;

-- select *
-- FROM diffusion_solar.learning_rates
-- order by 1;


select *
FROM diffusion_template.input_solar_cost_assumptions
order by 1;

-- select cost_assumptions
-- from diffusion_solar.scenario_options;


select *
FROM diffusion_template.input_solar_cost_projections_to_model
order by 1, sector;

-- select *
-- from diffusion_solar.cost_projections_to_model
-- order by 1, sector;


select *
FROM diffusion_template.input_solar_performance_improvements
order by 1;

-- select *
-- FROM diffusion_solar.solar_performance_improvements
-- order by 1;


select *
from diffusion_template.input_solar_performance_annual_system_degradation;

-- select ann_system_degradation
-- from diffusion_solar.scenario_options;


select *
FROM diffusion_template.input_solar_performance_system_sizing_factors
order by 1;

-- select *
-- from diffusion_solar.system_sizing_factors
-- order by 1;


select *
from diffusion_template.input_solar_finances_res
order by 1;

select *
from diffusion_template.input_solar_finances_com
order by 1;

select *
from diffusion_template.input_solar_finances_ind
order by 1;

select *
FROM diffusion_template.input_solar_finances
order by 1, 2;

-- select *
-- FROM diffusion_solar.financial_parameters
-- order by 1, 2;


select *
from diffusion_template.input_solar_finances_max_market_share
order by 1, 2;

-- select *
-- from diffusion_solar.user_defined_max_market_share
-- order by 1, 2;


select *
FROM diffusion_template.input_solar_finances_depreciation_schedule
order by 1;

-- select *
-- FROM diffusion_solar.depreciation_schedule
-- order by 1;









select *
from diffusion_template.input_wind_finances_res
order by 1;

select *
from diffusion_template.input_wind_finances_com
order by 1;

select *
from diffusion_template.input_wind_finances_ind
order by 1;

select *
FROM diffusion_template.input_wind_finances
order by 1, 2;

-- select *
-- FROM diffusion_wind.financial_parameters
-- order by 1, 2;


select *
from diffusion_template.input_wind_finances_max_market_share
order by 1, 2;

-- select *
-- from diffusion_wind.user_defined_max_market_share
-- order by 1, 2;


select *
FROM diffusion_template.input_wind_finances_depreciation_schedule
order by 1;

-- select *
-- FROM diffusion_wind.depreciation_schedule
-- order by 1;


select *
FROM diffusion_template.input_solar_leasing_availability
order by 1, 2;

-- select *
-- FROM diffusion_solar.leasing_availability
-- order by 1, 2;


select *
FROM diffusion_template.input_wind_leasing_availability
order by 1, 2;

-- select *
-- FROM diffusion_wind.leasing_availability
-- order by 1, 2;


select *
FROM diffusion_template.input_solar_incentive_options;

-- select overwrite_exist_inc, incentive_start_year
-- from diffusion_solar.scenario_options;


select *
FROM diffusion_template.input_solar_incentive_utility_types;

-- select utility_type_iou, utility_type_muni, utility_type_coop, utility_type_allother
-- from diffusion_solar.scenario_options;


select *
FROM diffusion_template.input_solar_incentives
order by 1, 2, 3, 10;

-- select *
-- FROM diffusion_solar.manual_incentives
-- order by 1, 2, 3, 11;




select *
FROM diffusion_template.input_wind_incentive_options;

-- select overwrite_exist_inc, incentive_start_year
-- from diffusion_wind.scenario_options;


select *
FROM diffusion_template.input_wind_incentive_utility_types;

-- select utility_type_iou, utility_type_muni, utility_type_coop, utility_type_allother
-- from diffusion_wind.scenario_options;


select *
FROM diffusion_template.input_wind_incentives
order by 1, 2, 3, 10;

-- select *
-- FROM diffusion_wind.manual_incentives
-- order by 1, 2, 3, 11;


select *
FROM diffusion_template.input_wind_cost_projections
order by 1, turbine_size_kw;

-- select *
-- FROM diffusion_wind.wind_cost_projections
-- order by 1, turbine_size_kw;


select year, turbine_size_kw, power_curve_id
FROM diffusion_template.input_wind_performance_improvements
order by turbine_size_kw, year;

-- select year, turbine_size_kw, power_curve_id
-- FROM diffusion_wind.wind_performance_improvements
-- order by turbine_size_kw, year;


select year, turbine_size_kw, derate_factor
from diffusion_template.input_wind_performance_gen_derate_factors
order by  turbine_size_kw, year;

-- select year, turbine_size_kw, derate_factor
-- from diffusion_wind.wind_generation_derate_factors
-- order by  turbine_size_kw, year;


select *
FROM diffusion_template.input_wind_performance_system_sizing_factors
order by 1;

-- select *
-- FROM diffusion_wind.system_sizing_factors
-- order by 1;


select *
FROM diffusion_template.input_wind_siting_apply_parcel_size;

select *
FROM diffusion_template.input_wind_siting_apply_hi_dev;

select *
FROM diffusion_template.input_wind_siting_apply_canopy_clearance;

select *
FROM diffusion_template.input_wind_siting_parcel_size_raw
order by 1;

select *
FROM diffusion_template.input_wind_siting_hi_dev_raw
order by 1;

select *
FROM diffusion_template.input_wind_siting_canopy_clearance_raw
order by 1;



select *
FROM diffusion_template.input_wind_siting_parcel_size
order by 1;

-- select *
-- FROM diffusion_wind.min_acres_per_hu_lkup
-- order by 1;


select *
FROM diffusion_template.input_wind_siting_hi_dev
order by 1;

-- select *
-- FROM diffusion_wind.max_hi_dev_pct_lkup
-- order by 1;


select *
FROM diffusion_template.input_wind_siting_canopy_clearance
order by 1;

-- select *
-- FROM diffusion_wind.required_canopy_clearance_lkup
-- order by 1;