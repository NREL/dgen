set role 'diffusion-writers';

DROP TABLE IF EXISTS diffusion_geo.ornl_ghp_simulations CASCADE;
CREATE TABLE diffusion_geo.ornl_ghp_simulations
(
	baseline_type integer,
	tc_val varchar(4),
	gtc_btu_per_hftF NUMERIC,
	baseline_electricity_consumption_kwh NUMERIC,
	baseline_natural_gas_consumption_mbtu NUMERIC,
	baseline_site_energy_mbtu NUMERIC,
	baseline_source_energy_mbtu NUMERIC,
	baseline_carbon_emissions_mt NUMERIC,
	baseline_energy_cost NUMERIC,
	baseline_peak_electricity_demand_kw NUMERIC,
	gshp_electricity_consumption_kwh NUMERIC,
	gshp_natural_gas_consumption_mbtu NUMERIC,
	gshp_site_energy_mbtu NUMERIC,
	gshp_source_energy_mbtu NUMERIC,
	gshp_carbon_emissions_mt NUMERIC,
	gshp_energy_cost NUMERIC,
	gshp_peak_electricity_demand_kw NUMERIC,
	savings_abs_electricity_consumption_kwh NUMERIC,
	savings_abs_natural_gas_consumption_mbtu NUMERIC,
	savings_abs_site_energy_mbtu NUMERIC,
	savings_abs_source_energy_mbtu NUMERIC,
	savings_abs_carbon_emissions_mt NUMERIC,
	savings_abs_energy_cost NUMERIC,
	savings_abs_peak_electricity_demand_kw NUMERIC,
	savings_pct_electricity_consumption NUMERIC,
	savings_pct_natural_gas_consumption NUMERIC,
	savings_pct_site_energy NUMERIC,
	savings_pct_source_energy NUMERIC,
	savings_pct_carbon_emissions NUMERIC,
	savings_pct_energy_cost NUMERIC,
	savings_pct_peak_electricity_demand NUMERIC,
	crb_ghx_length_ft NUMERIC,
	crb_cooling_capacity_ton NUMERIC,
	length_per_ton_of_capacity_ft_ton NUMERIC,
	max_lft_f NUMERIC,
	min_lft_f NUMERIC,
	city TEXT,
	iecc_climate_zone TEXT
);

\COPY diffusion_geo.ornl_ghp_simulations FROM '/Users/kmccabe/dGeo/Data/ORNL_GHP_CRB_Simulations/ghp_simulation_results/consolidated/ghp_results_2016_10_11.csv' with csv header;

-- add primary key on building type, gtc, and city
ALTER TABLE diffusion_geo.ornl_ghp_simulations
ADD PRIMARY KEY (baseline_type, iecc_climate_zone, gtc_btu_per_hftF);

-- drop the data for tc_2 and 3 for ALL building types
DELETE FROM diffusion_geo.ornl_ghp_simulations
where tc_val in ('tc_2' , 'tc_3'); -- tc_2 = 25%, tc_3 = 75%
-- 312 rows deleted


-- fill in the pct savings values
UPDATE diffusion_geo.ornl_ghp_simulations
set savings_pct_electricity_consumption =
(baseline_electricity_consumption_kwh - gshp_electricity_consumption_kwh)/
baseline_electricity_consumption_kwh;

UPDATE diffusion_geo.ornl_ghp_simulations
set savings_pct_natural_gas_consumption =
COALESCE((baseline_natural_gas_consumption_mbtu - gshp_natural_gas_consumption_mbtu)/
NULLIF(baseline_natural_gas_consumption_mbtu, 0), 0);

UPDATE diffusion_geo.ornl_ghp_simulations
set savings_pct_site_energy =
(baseline_site_energy_mbtu - gshp_site_energy_mbtu)/
baseline_site_energy_mbtu;

UPDATE diffusion_geo.ornl_ghp_simulations
set savings_pct_source_energy =
(baseline_source_energy_mbtu - gshp_source_energy_mbtu)/
baseline_source_energy_mbtu;

UPDATE diffusion_geo.ornl_ghp_simulations
set savings_pct_carbon_emissions =
(baseline_carbon_emissions_mt - gshp_carbon_emissions_mt)/
baseline_carbon_emissions_mt;

UPDATE diffusion_geo.ornl_ghp_simulations
set savings_pct_energy_cost =
(baseline_energy_cost - gshp_energy_cost)/
baseline_energy_cost;
	
UPDATE diffusion_geo.ornl_ghp_simulations
set savings_pct_peak_electricity_demand =
(baseline_peak_electricity_demand_kw - gshp_peak_electricity_demand_kw)/
baseline_peak_electricity_demand_kw;
-- 156 rows

-- check values are reasonable
select  min(savings_pct_natural_gas_consumption), 
	avg(savings_pct_natural_gas_consumption),
	max(savings_pct_natural_gas_consumption)
FROM diffusion_geo.ornl_ghp_simulations;
-- -0.00797266514806378132,0.59347452814306774296,1.00000000000000000000
-- seem reasonable, except for the negative?

select  min(savings_pct_electricity_consumption), 
	avg(savings_pct_electricity_consumption),
	max(savings_pct_electricity_consumption)
FROM diffusion_geo.ornl_ghp_simulations;
-- -5.8816608996539792,-0.10566337986435603221,0.78106508875739644970
-- seem reasonable except for the magnitude of hte negative

-- look into these  more closely:
select savings_pct_natural_gas_consumption, *
FROM diffusion_geo.ornl_ghp_simulations
where savings_pct_natural_gas_consumption < 0;
-- hotel in San Diego -- makes sense because (from Xiaobing's FY16Q3 report)
-- "a smallportion of the baseline HVAC system (i.e., the makeup air system using a gas-fired furnace) was not
-- replaced with the GHP system due to the large swing of outdoor air temperature"


select savings_pct_electricity_consumption, iecc_climate_zone, *
FROM diffusion_geo.ornl_ghp_simulations
where savings_pct_electricity_consumption < 0
order by 1;
-- these numbers match the original values in Xiaobing's summary, so i think they are okay

-- look at results
select *
FROM diffusion_geo.ornl_ghp_simulations;