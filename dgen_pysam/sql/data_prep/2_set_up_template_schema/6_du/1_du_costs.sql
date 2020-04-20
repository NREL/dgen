set role 'diffusion-writers';

-- plant costs --
-- subsurface
DROP TABLE IF EXISTs diffusion_template.input_du_cost_plant_subsurface CASCADE;
CREATE TABLE diffusion_template.input_du_cost_plant_subsurface
(
	year integer NOT NULL,
	future_drilling_cost_improvements_pct numeric NOT NULL,
	reservoir_stimulation_costs_per_wellset_dlrs numeric NOT NULL,
	exploration_slim_well_cost_pct_of_normal_well numeric not null,
	exploration_fixed_costs_dollars numeric not null,
	CONSTRAINT input_du_cost_plant_subsurface_year_fkey FOREIGN KEY (year)
		REFERENCES diffusion_config.sceninp_year_range (val) MATCH SIMPLE
		ON UPDATE NO ACTION ON DELETE RESTRICT
);
--surface
DROP TABLE IF EXISTs diffusion_template.input_du_cost_plant_surface CASCADE;
CREATE TABLE diffusion_template.input_du_cost_plant_surface
(
	year integer not null,
	plant_installation_costs_dollars_per_kw numeric not null,
	om_labor_costs_dlrs_per_kw_per_year numeric not null,
	om_plant_costs_pct_plant_cap_costs_per_year numeric not null,
	om_well_costs_pct_well_cap_costs_per_year numeric not null,
	distribution_network_construction_costs_dollars_per_m numeric not null,
	operating_costs_reservoir_pumping_costs_dollars_per_gal numeric not null,
	operating_costs_distribution_pumping_costs_dollars_per_gal_m numeric not null,
	natural_gas_peaking_boilers_dollars_per_kw numeric not null,
	CONSTRAINT input_du_cost_plant_surface_year_fkey FOREIGN KEY (year)
		REFERENCES diffusion_config.sceninp_year_range (val) MATCH SIMPLE
		ON UPDATE NO ACTION ON DELETE RESTRICT
);


-- End User costs --
-- res
DROP TABLE IF EXISTs diffusion_template.input_du_cost_user_res CASCADE;
CREATE TABLE diffusion_template.input_du_cost_user_res
(
	year integer not null,
	sys_connection_cost_dollars numeric not null,
	fixed_om_costs_dollars_sf_yr numeric not null,
	new_sys_installation_costs_dollars_sf numeric not null,
	retrofit_new_sys_installation_cost_multiplier numeric not null,
	CONSTRAINT input_du_cost_user_res_year_fkey FOREIGN KEY (year)
		REFERENCES diffusion_config.sceninp_year_range (val) MATCH SIMPLE
		ON UPDATE NO ACTION ON DELETE RESTRICT
);

-- com 
DROP TABLE IF EXISTs diffusion_template.input_du_cost_user_com CASCADE;
CREATE TABLE diffusion_template.input_du_cost_user_com
(
	year integer not null,
	sys_connection_cost_dollars numeric not null,
	fixed_om_costs_dollars_sf_yr numeric not null,
	new_sys_installation_costs_dollars_sf numeric not null,
	retrofit_new_sys_installation_cost_multiplier numeric not null,
	CONSTRAINT input_du_cost_user_com_year_fkey FOREIGN KEY (year)
		REFERENCES diffusion_config.sceninp_year_range (val) MATCH SIMPLE
		ON UPDATE NO ACTION ON DELETE RESTRICT
);

-- ind
DROP TABLE IF EXISTs diffusion_template.input_du_cost_user_ind CASCADE;
CREATE TABLE diffusion_template.input_du_cost_user_ind
(
	year integer not null,
	sys_connection_cost_dollars numeric not null,
	fixed_om_costs_dollars_sf_yr numeric not null,
	new_sys_installation_costs_dollars_sf numeric not null,
	retrofit_new_sys_installation_cost_multiplier numeric not null,
	CONSTRAINT input_du_cost_user_ind_year_fkey FOREIGN KEY (year)
		REFERENCES diffusion_config.sceninp_year_range (val) MATCH SIMPLE
		ON UPDATE NO ACTION ON DELETE RESTRICT
);




-- create view for end user costs 
DROP VIEW IF EXISTs diffusion_template.input_du_cost_user;
CREATE VIEW diffusion_template.input_du_cost_user AS
(
	--res
	SELECT *, 'res'::character varying(3) as sector_abbr
	FROM diffusion_template.input_du_cost_user_res

	UNION ALL
	--com
	SELECT *, 'com'::character varying(3) as sector_abbr
	FROM diffusion_template.input_du_cost_user_com

	UNION ALL
	--ind
	SELECT *, 'ind'::character varying(3) as sector_abbr
	FROM diffusion_template.input_du_cost_user_ind
);


