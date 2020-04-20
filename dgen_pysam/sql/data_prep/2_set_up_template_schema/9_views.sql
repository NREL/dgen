SET ROLE 'diffusion-writers';

-- create view of the valid states
DROP VIEW IF EXISTS diffusion_template.states_to_model CASCADE;
CREATE OR REPLACE VIEW diffusion_template.states_to_model AS
SELECT distinct a.state_abbr, a.state_fips
FROM diffusion_blocks.county_geoms a
INNER JOIN diffusion_template.input_main_scenario_options b
ON lower(a.state) = CASE WHEN b.region = 'United States' then lower(a.state)
		else lower(b.region)
		end
where a.state not in ('Hawaii','Alaska');

-- create view of the valid tracts
DROP VIEW IF EXISTS diffusion_template.tracts_to_model CASCADE;
CREATE OR REPLACE VIEW diffusion_template.tracts_to_model AS
SELECT distinct a.tract_id_alias, a.state_fips, a.county_fips, c.county_id
FROM diffusion_blocks.tract_ids a
INNER JOIN diffusion_template.states_to_model b
ON a.state_fips = b.state_fips
left join diffusion_blocks.county_geoms c
ON a.state_fips = c.state_fips
and a.county_fips = c.county_fips;


-- joined block microdata
DROP VIEW IF EXISTS diffusion_template.block_microdata_res_joined;
CREATE VIEW  diffusion_template.block_microdata_res_joined AS
SELECT a.*, 
	a.bldg_count_single_fam_res as sample_weight,
	a.bldg_count_res as sample_weight_geo
FROM diffusion_blocks.block_microdata_res a
INNER JOIN diffusion_template.states_to_model b
ON a.state_abbr = b.state_abbr;

DROP VIEW  IF EXISTS diffusion_template.block_microdata_com_joined;
CREATE VIEW  diffusion_template.block_microdata_com_joined AS
SELECT a.*, 
	a.bldg_count_com as sample_weight,
	a.bldg_count_com as sample_weight_geo
FROM diffusion_blocks.block_microdata_com a
INNER JOIN diffusion_template.states_to_model b
ON a.state_abbr = b.state_abbr;

DROP VIEW  IF EXISTS diffusion_template.block_microdata_ind_joined;
CREATE VIEW  diffusion_template.block_microdata_ind_joined AS
SELECT a.*, 
	a.bldg_count_ind as sample_weight,
	a.bldg_count_ind as sample_weight_geo
FROM diffusion_blocks.block_microdata_ind a
INNER JOIN diffusion_template.states_to_model b
ON a.state_abbr = b.state_abbr;

------------------------------------------------------------------------------------------------
-- create view of sectors to model
DROP VIEW IF EXIStS diffusion_template.sectors_to_model;
CREATE OR REPLACE VIEW diffusion_template.sectors_to_model AS
SELECT CASE WHEN markets = 'All' THEN 'res=>Residential,com=>Commercial,ind=>Industrial'::hstore
	    when markets = 'Only Residential' then 'res=>Residential'::hstore
	    when markets = 'Only Commercial' then 'com=>Commercial'::hstore
	    when markets = 'Only Industrial' then 'ind=>Industrial'::hstore
	   end as sectors
FROM diffusion_template.input_main_scenario_options;

set role 'diffusion-writers';
-- max market share
DROP VIEW IF EXISTS diffusion_template.max_market_curves_to_model;
CREATE OR REPLACE VIEW diffusion_template.max_market_curves_to_model As
with user_inputs as 
(
	-- user selections for host owned curves
	SELECT 'residential' as sector, 'res'::character varying(3) as sector_abbr, 'host_owned' as business_model,
		res_max_market_curve as source
	FROM diffusion_template.input_main_scenario_options
	UNION
	SELECT 'commercial' as sector, 'com'::character varying(3) as sector_abbr, 'host_owned' as business_model,
		com_max_market_curve as source
	FROM diffusion_template.input_main_scenario_options
	UNION
	SELECT 'industrial' as sector, 'ind'::character varying(3) as sector_abbr, 'host_owned' as business_model,
		ind_max_market_curve as source
	FROM diffusion_template.input_main_scenario_options
	UNION
	-- default selections for third party owned curves (only one option -- NREL)
	SELECT unnest(array['residential','commercial','industrial']) as sector, 
		unnest(array['res','com','ind']) as sector_abbr, 
		'tpo' as business_model,
		'NREL' as source	
),
all_maxmarket as 
(
	SELECT metric_value, sector, sector_abbr, max_market_share, metric, 
		source, business_model
	FROM diffusion_shared.max_market_share
)
SELECT a.*
FROM all_maxmarket a
INNER JOIN user_inputs b
ON a.sector = b.sector
and a.source = b.source
and a.business_model = b.business_model
order by sector, metric, metric_value;

-- create view for rate escalations
DROP VIEW IF EXISTS diffusion_template.rate_escalations_to_model;
CREATE OR REPLACE VIEW diffusion_template.rate_escalations_to_model AS
With cdas AS (
	SELECT distinct(census_division_abbr) as census_division_abbr, generate_series(2014,2080) as year
	FROM diffusion_shared.county_geom
	order by year, census_division_abbr
),
user_defined_gaps_res AS 
(
	SELECT b.census_division_abbr, b.year, 'res'::text as sector,
		a.user_defined_res_rate_escalations as escalation_factor,
		lag(a.user_defined_res_rate_escalations,1) OVER (PARTITION BY b.census_division_abbr ORDER BY b.year asc) as lag_factor,
		lead(a.user_defined_res_rate_escalations,1) OVER (PARTITION BY b.census_division_abbr ORDER BY b.year asc) as lead_factor,
		(array_agg(a.user_defined_res_rate_escalations) OVER (PARTITION BY b.census_division_abbr ORDER BY b.year ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING))[37] as last_factor,
		'User Defined'::text as source
	FROM cdas b
	LEFT JOIN diffusion_template.input_main_market_projections a
       on a.year = b.year
),
user_defined_gaps_com AS 
(
	SELECT b.census_division_abbr, b.year, 'com'::text as sector,
		a.user_defined_com_rate_escalations as escalation_factor,
		lag(a.user_defined_com_rate_escalations,1) OVER (PARTITION BY b.census_division_abbr ORDER BY b.year asc) as lag_factor,
		lead(a.user_defined_com_rate_escalations,1) OVER (PARTITION BY b.census_division_abbr ORDER BY b.year asc) as lead_factor,
		(array_agg(a.user_defined_com_rate_escalations) OVER (PARTITION BY b.census_division_abbr ORDER BY b.year ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING))[37] as last_factor,
		'User Defined'::text as source
	FROM cdas b
	LEFT JOIN diffusion_template.input_main_market_projections a
       on a.year = b.year
),
user_defined_gaps_ind AS 
(
	SELECT b.census_division_abbr, b.year, 'ind'::text as sector,
		a.user_defined_ind_rate_escalations as escalation_factor,
		lag(a.user_defined_ind_rate_escalations,1) OVER (PARTITION BY b.census_division_abbr ORDER BY b.year asc) as lag_factor,
		lead(a.user_defined_ind_rate_escalations,1) OVER (PARTITION BY b.census_division_abbr ORDER BY b.year asc) as lead_factor,
		(array_agg(a.user_defined_ind_rate_escalations) OVER (PARTITION BY b.census_division_abbr ORDER BY b.year ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING))[37] as last_factor,
		'User Defined'::text as source
	FROM cdas b
	LEFT JOIN diffusion_template.input_main_market_projections a
       on a.year = b.year
),
user_defined_gaps_all AS
(
	SELECT *
	FROM user_defined_gaps_res
	UNION
	SELECT *
	FROM user_defined_gaps_com
	UNION
	SELECT *
	FROM user_defined_gaps_ind
),
user_defined_filled AS
(
	SELECT census_division_abbr, year, sector,
	CASE WHEN escalation_factor is null and year <= 2050 THEN (lag_factor+lead_factor)/2
	     WHEN escalation_factor is null and year > 2050 THEN last_factor
	     ELSE escalation_factor
	END as escation_factor,
	source
	FROM user_defined_gaps_all
),
no_growth AS (
SELECT census_division_abbr, year, unnest(array['res','com','ind'])::text as sector,
		1::numeric as escalation_factor,
		'No Growth'::text as source
	FROM cdas
),
aeo AS 
(
	SELECT census_division_abbr, year, sector_abbr as sector, 
		escalation_factor, 
		source
	FROM diffusion_shared.aeo_rate_escalations_2014
	where year >= 2014

	UNION ALL

	SELECT census_division_abbr, year, sector_abbr as sector, 
		escalation_factor, 
		source
	FROM diffusion_shared.aeo_rate_escalations_2015
	where year >= 2014
),
esc_combined AS
(
	SELECT *
	FROM aeo

	UNION 

	SELECT *
	FROM no_growth

	UNION 

	SELECT *
	FROM user_defined_filled
),
inp_opts AS 
(
	SELECT 'res'::text as sector, res_rate_escalation as source
	FROM diffusion_template.input_main_scenario_options
	UNION
	SELECT 'com'::text as sector, com_rate_escalation as source
	FROM diffusion_template.input_main_scenario_options
	UNION
	SELECT 'ind'::text as sector, ind_rate_escalation as source
	FROM diffusion_template.input_main_scenario_options
)

SELECT a.census_division_abbr, a.year, a.sector, a.escalation_factor, a.source
FROM esc_combined a
INNER JOIN inp_opts b
ON a.sector = b.sector
and a.source = b.source;


-- create a view of all of the different types of rates
DROP VIEW IF EXISTS diffusion_template.all_rate_jsons;
CREATE VIEW diffusion_template.all_rate_jsons AS
-- urdb3 complex rates
SELECT 'urdb3'::character varying(5) as rate_source,
	rate_id_alias, 
	sam_json
FROM diffusion_shared.urdb3_rate_sam_jsons
UNION ALL
-- annual average flat rates (residential)
SELECT 'aares'::character varying(5) as rate_source,
	a.county_id as rate_id_alias, 
	('{"ur_flat_buy_rate" : ' || round(res_rate_cents_per_kwh/100,2)::text || '}')::JSON as sam_json
FROM diffusion_shared.ann_ave_elec_rates_by_county_2012 a
UNION ALL
-- annual average flat rates (commercial)
SELECT 'aacom'::character varying(5) as rate_source,
	a.county_id as rate_id_alias, 
	('{"ur_flat_buy_rate" : ' || round(com_rate_cents_per_kwh/100,2)::text || '}')::JSON as sam_json
FROM diffusion_shared.ann_ave_elec_rates_by_county_2012 a
UNION ALL
-- annual average flat rates (industrial)
SELECT 'aaind'::character varying(5) as rate_source,
	a.county_id as rate_id_alias, 
	('{"ur_flat_buy_rate" : ' || round(ind_rate_cents_per_kwh/100,2)::text || '}')::JSON as sam_json
FROM diffusion_shared.ann_ave_elec_rates_by_county_2012 a
UNION ALL
-- user-defined flat rates (residential)
SELECT 'udres'::character varying(5) as rate_source,
	a.state_fips as rate_id_alias, 
	('{"ur_flat_buy_rate" : ' || round(res_rate_dlrs_per_kwh,2)::text || '}')::JSON as sam_json
FROM diffusion_template.input_main_market_flat_electric_rates a
UNION ALL
-- user-defined flat rates (commercial)
SELECT 'udcom'::character varying(5) as rate_source,
	a.state_fips as rate_id_alias, 
	('{"ur_flat_buy_rate" : ' || round(com_rate_dlrs_per_kwh,2)::text || '}')::JSON as sam_json
FROM diffusion_template.input_main_market_flat_electric_rates a
UNION ALL
-- user-defined flat rates (industrial)
SELECT 'udind'::character varying(5) as rate_source,
	a.state_fips as rate_id_alias, 
	('{"ur_flat_buy_rate" : ' || round(ind_rate_dlrs_per_kwh,2)::text || '}')::JSON as sam_json
FROM diffusion_template.input_main_market_flat_electric_rates a;


------------------------------------------------------------------------------------------------
-- finances
set role 'diffusion-writers';

DROP VIEW IF EXISTS diffusion_template.input_finances;
CREATE VIEW diffusion_template.input_finances AS
select *, 'wind'::text as tech
from diffusion_template.input_wind_finances
UNION ALL
select *, 'solar'::text as tech
from diffusion_template.input_solar_finances
UNION ALL
SELECT *, 'ghp'::TEXT as tech
FROM diffusion_template.input_ghp_finances;

------------------------------------------------------------------------------------------------
-- finances
set role 'diffusion-writers';

DROP VIEW IF EXISTS diffusion_template.input_financial_parameters;
CREATE VIEW diffusion_template.input_financial_parameters AS
select year, business_model, sector_abbr, loan_term_yrs, loan_rate, down_payment, 
       discount_rate, tax_rate, length_of_irr_analysis_yrs, 'wind'::text as tech
from diffusion_template.input_wind_finances
UNION ALL
select year, business_model, sector_abbr, loan_term_yrs, loan_rate, down_payment, 
       discount_rate, tax_rate, length_of_irr_analysis_yrs, 'solar'::text as tech
from diffusion_template.input_solar_finances
UNION ALL
select year, business_model, sector_abbr, loan_term_yrs, loan_rate, down_payment, 
       discount_rate, tax_rate, length_of_irr_analysis_yrs, 'ghp'::text as tech
from diffusion_template.input_ghp_finances;

------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------
-- depreciation schedule
DROP VIEW IF EXISTS diffusion_template.input_finances_depreciation_schedule;
CREATE VIEW diffusion_template.input_finances_depreciation_schedule AS
SELECT *, 'wind'::text as tech
FROM diffusion_template.input_wind_finances_depreciation_schedule 
UNION ALL
SELECT *, 'solar'::text as tech
FROM diffusion_template.input_solar_finances_depreciation_schedule
UNION ALL
SELECT *, 'ghp'::text as tech
FROM diffusion_template.input_ghp_finances_depreciation_schedule;

------------------------------------------------------------------------------------------------
-- annual system degradation
DROP VIEW IF EXISTS diffusion_template.input_performance_annual_system_degradation;
CREATE VIEW diffusion_template.input_performance_annual_system_degradation AS
SELECT 0::numeric as ann_system_degradation, 'wind'::text as tech
UNION ALL
SELECT ann_system_degradation, 'solar'::text as tech
FROM diffusion_template.input_solar_performance_annual_system_degradation;

------------------------------------------------------------------------------------------------
-- load growth to model
DROP VIEW IF EXISTS diffusion_template.load_growth_to_model;
CREATE VIEW diffusion_template.load_growth_to_model as
select a.year, a.sector_abbr, a.census_division_abbr,
	a.scenario as load_growth_scenario, 
	a.load_multiplier
from diffusion_shared.aeo_load_growth_projections a
INNER JOIN diffusion_template.input_main_scenario_options b
ON lower(a.scenario) = lower(b.load_growth_scenario);
------------------------------------------------------------------------------------------------
-- leasing availability to model
DROP VIEW IF EXISTS diffusion_template.leasing_availability_to_model;
CREATE VIEW diffusion_template.leasing_availability_to_model AS
SELECT 'solar'::VARCHAR(5) as tech, a.*
FROM diffusion_template.input_solar_leasing_availability a
UNION ALL
SELECT 'wind'::VARCHAR(5) as tech, b.*
FROM diffusion_template.input_wind_leasing_availability b
UNION ALL
SELECT 'ghp'::VARCHAR(5) as tech, c.*
FROM diffusion_template.input_wind_leasing_availability c;

------------------------------------------------------------------------------------------------
-- starting_capacities to model
DROP VIEW IF EXISTS diffusion_template.state_starting_capacities_to_model;
CREATE VIEW diffusion_template.state_starting_capacities_to_model AS
SELECT 'solar'::VARCHAR(5) as tech, 
	'res'::VARCHAR(3) as sector_abbr,
	state_abbr,
	a.capacity_mw_residential as capacity_mw,
	a.systems_count_residential as systems_count
FROM diffusion_solar.starting_capacities_mw_2012_q4_us a
UNION ALL
SELECT 'solar'::VARCHAR(5) as tech, 
	'com'::VARCHAR(3) as sector_abbr,
	state_abbr,
	a.capacity_mw_commercial as capacity_mw,
	a.systems_count_commercial as systems_count
FROM diffusion_solar.starting_capacities_mw_2012_q4_us a
UNION ALL
SELECT 'solar'::VARCHAR(5) as tech, 
	'ind'::VARCHAR(3) as sector_abbr,
	state_abbr,
	a.capacity_mw_industrial as capacity_mw,
	a.systems_count_industrial as systems_count
FROM diffusion_solar.starting_capacities_mw_2012_q4_us a
UNION ALL
SELECT 'wind'::VARCHAR(5) as tech, 
	'res'::VARCHAR(3) as sector_abbr,
	state_abbr,
	a.capacity_mw_residential as capacity_mw,
	a.systems_count_residential as systems_count
FROM diffusion_wind.starting_capacities_mw_2012_q4_us a
UNION ALL
SELECT 'wind'::VARCHAR(5) as tech, 
	'com'::VARCHAR(3) as sector_abbr,
	state_abbr,
	a.capacity_mw_commercial as capacity_mw,
	a.systems_count_commercial as systems_count
FROM diffusion_wind.starting_capacities_mw_2012_q4_us a
UNION ALL
SELECT 'wind'::VARCHAR(5) as tech, 
	'ind'::VARCHAR(3) as sector_abbr,
	state_abbr,
	a.capacity_mw_industrial as capacity_mw,
	a.systems_count_industrial as systems_count
FROM diffusion_wind.starting_capacities_mw_2012_q4_us a;
------------------------------------------------------------------------------
set role 'diffusion-writers';
DROP VIEW IF EXISTS diffusion_template.tract_industrial_natural_gas_prices_to_model;
CREATE VIEW diffusion_template.tract_industrial_natural_gas_prices_to_model AS
with a as
(
	select a.tract_id_alias, c.census_division_abbr
	FROM diffusion_template.tracts_to_model a
	LEFT JOIN diffusion_blocks.tract_ids b
	ON a.tract_id_alias = b.tract_id_alias
	LEFT JOIN diffusion_blocks.county_geoms c
	ON b.state_fips = c.state_fips
	and b.county_fips = c.county_fips
),
b as
(
	select a.year, a.census_division_abbr, a.dlrs_per_mmbtu*3.412141 as dlrs_per_mwh
	FROM diffusion_shared.aeo_energy_price_projections_2015 a
	inner join diffusion_template.input_main_scenario_options b
	ON a.scenario = b.regional_heating_fuel_cost_trajectories
	where a.fuel_type = 'natural gas'
	and a.sector_abbr = 'ind'
)
select a.tract_id_alias, b.year, b.dlrs_per_mwh
from a
LEFT JOIN b
ON a.census_division_abbr = b.census_division_abbr;

------------------------------------------------------------------------------
set role 'diffusion-writers';
DROP VIEW IF EXISTS diffusion_template.aeo_energy_prices_to_model;
CREATE VIEW diffusion_template.aeo_energy_prices_to_model AS
select a.year,
	a.census_division_abbr,	
	a.sector_abbr,
	a.fuel_type, 
	a.dlrs_per_mmbtu * 0.003412141 as dlrs_per_kwh
FROM diffusion_shared.aeo_energy_price_projections_2015 a
inner join diffusion_template.input_main_scenario_options b
ON a.scenario = b.regional_heating_fuel_cost_trajectories;

set role 'diffusion-writers';
DROP VIEW IF EXISTS diffusion_template.new_building_growth_to_model;
CREATE VIEW diffusion_template.new_building_growth_to_model AS
select a.year,
	a.tract_id_alias,	
	a.new_bldgs_com,
	a.new_bldgs_res_single_family + a.new_bldgs_res_multi_family as new_bldgs_res
FROM  diffusion_blocks.tract_building_growth_aeo_2015  a
INNER JOIN diffusion_template.tracts_to_model b
ON a.tract_id_alias = b.tract_id_alias
inner join diffusion_template.input_main_scenario_options c
ON a.scenario = c.new_building_growth_scenario;
