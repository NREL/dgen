set role 'diffusion-writers';

--Baseline Residential
DROP TABLE IF EXISTs diffusion_template.input_baseline_system_costs_res CASCADE;
CREATE TABLE diffusion_template.input_baseline_system_costs_res 
(
	year integer not null,
	hvac_equipment_cost_improvement_pct numeric not null,
	fixed_om_dollars_per_sf_per_year numeric NOT NULL,
	CONSTRAINT input_baseline_system_costs_res_year_fkey FOREIGN KEY (year)
		REFERENCES diffusion_config.sceninp_year_range (val) MATCH SIMPLE
		ON UPDATE NO ACTION ON DELETE RESTRICT
);

--Baseline Commercial
DROP TABLE IF EXISTs diffusion_template.input_baseline_system_costs_com CASCADE;
CREATE TABLE diffusion_template.input_baseline_system_costs_com 
(
	year integer not null,
	hvac_equipment_cost_improvement_pct numeric not null,
	fixed_om_dollars_per_sf_per_year numeric NOT NULL,
	CONSTRAINT input_baseline_system_costs_com_year_fkey FOREIGN KEY (year)
		REFERENCES diffusion_config.sceninp_year_range (val) MATCH SIMPLE
		ON UPDATE NO ACTION ON DELETE RESTRICT
);



-- Create Views
DROP VIEW IF EXISTS diffusion_template.input_baseline_costs_hvac;
CREATE VIEW diffusion_template.input_baseline_costs_hvac AS 
(
	--res
	SELECT  year, 
			'res'::varchar(3) as sector_abbr, 
			hvac_equipment_cost_improvement_pct,
			fixed_om_dollars_per_sf_per_year
	FROM diffusion_template.input_baseline_system_costs_res
	UNION ALL
	-- com
	SELECT  year, 
			'com'::varchar(3) as sector_abbr, 
			hvac_equipment_cost_improvement_pct,
			fixed_om_dollars_per_sf_per_year
	FROM diffusion_template.input_baseline_system_costs_com
);