set role 'diffusion-writers';

DROP TABLE IF EXISTS diffusion_template.input_main_scenario_options CASCADE;
CREATE TABLE diffusion_template.input_main_scenario_options
(
	scenario_name text NOT NULL,
	tech_choice boolean not null,
	run_wind boolean not null,
	run_solar boolean not null,
	run_du boolean not null,
	run_ghp boolean not null,
	region text NOT NULL,
	end_year integer NOT NULL,
	markets text NOT NULL,
	load_growth_scenario text NOT NULL,
	res_rate_structure text NOT NULL,
	com_rate_structure text NOT NULL,
	ind_rate_structure text NOT NULL,
	res_rate_escalation text NOT NULL,
	com_rate_escalation text NOT NULL,
	ind_rate_escalation text NOT NULL,
	res_max_market_curve text NOT NULL,
	com_max_market_curve text NOT NULL,
	ind_max_market_curve text NOT NULL,
	storage_cost_projections text NOT NULL,
	carbon_price text NOT NULL,
	new_building_growth_scenario text NOT NULL,
	regional_heating_fuel_cost_trajectories text NOT NULL,
	random_generator_seed integer NOT NULL, -- doesn't need a constraint -- just needs to be integer
	-- add check/fkey constraints to ensure only valid values are entered in each column
	-- carbon price
	CONSTRAINT input_main_scenario_options_carbon_price_fkey FOREIGN KEY (carbon_price)
		REFERENCES diffusion_config.sceninp_carbon_price (val) MATCH SIMPLE,
	-- max market curves
	CONSTRAINT input_main_scenario_options_com_max_market_curve_fkey FOREIGN KEY (com_max_market_curve)
		REFERENCES diffusion_config.sceninp_max_market_curve_nonres (val) MATCH SIMPLE,
	CONSTRAINT input_main_scenario_options_res_max_market_curve_fkey FOREIGN KEY (res_max_market_curve)
		REFERENCES diffusion_config.sceninp_max_market_curve_res (val) MATCH SIMPLE,
	CONSTRAINT input_main_scenario_options_ind_max_market_curve_fkey FOREIGN KEY (ind_max_market_curve)
		REFERENCES diffusion_config.sceninp_max_market_curve_nonres (val) MATCH SIMPLE,
	-- rate escalations
	CONSTRAINT input_main_scenario_options_com_rate_escalation_fkey FOREIGN KEY (com_rate_escalation)
		REFERENCES diffusion_config.sceninp_rate_escalation (val) MATCH SIMPLE,
	CONSTRAINT input_main_scenario_options_ind_rate_escalation_fkey FOREIGN KEY (ind_rate_escalation)
		REFERENCES diffusion_config.sceninp_rate_escalation (val) MATCH SIMPLE,
	CONSTRAINT input_main_scenario_options_res_rate_escalation_fkey FOREIGN KEY (res_rate_escalation)
		REFERENCES diffusion_config.sceninp_rate_escalation (val) MATCH SIMPLE,
	-- rate structures
	CONSTRAINT input_main_scenario_options_com_rate_structure_fkey FOREIGN KEY (com_rate_structure)
		REFERENCES diffusion_config.sceninp_rate_structure (val) MATCH SIMPLE,
	CONSTRAINT input_main_scenario_options_ind_rate_structure_fkey FOREIGN KEY (ind_rate_structure)
		REFERENCES diffusion_config.sceninp_rate_structure (val) MATCH SIMPLE,
	CONSTRAINT input_main_scenario_options_res_rate_structure_fkey FOREIGN KEY (res_rate_structure)
		REFERENCES diffusion_config.sceninp_rate_structure (val) MATCH SIMPLE,
	-- end year
	CONSTRAINT input_main_scenario_options_end_year_fkey FOREIGN KEY (end_year)
		REFERENCES diffusion_config.sceninp_year_range (val) MATCH SIMPLE,
	-- load growth
	CONSTRAINT input_main_scenario_options_load_growth_scenario_fkey FOREIGN KEY (load_growth_scenario)
		REFERENCES diffusion_config.sceninp_load_growth_scenario (val) MATCH SIMPLE,
	-- markets (i.e., sectors)
	CONSTRAINT input_main_scenario_options_markets_fkey FOREIGN KEY (markets)
		REFERENCES diffusion_config.sceninp_markets (val) MATCH SIMPLE,
	-- storage cost projections
	CONSTRAINT input_main_scenario_options_storage_cost_projections_fkey FOREIGN KEY (storage_cost_projections)
		REFERENCES diffusion_config.sceninp_storage_cost_projections (val) MATCH SIMPLE,
	-- region
	CONSTRAINT input_main_scenario_options_region_fkey FOREIGN KEY (region)
		REFERENCES diffusion_config.sceninp_region (val) MATCH SIMPLE
);