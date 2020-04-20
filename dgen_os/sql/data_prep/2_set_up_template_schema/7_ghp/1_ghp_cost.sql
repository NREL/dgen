set role 'diffusion-writers';

-- res
DROP TABLE IF EXISTs diffusion_template.input_ghp_costs_res CASCADE;
CREATE TABLE diffusion_template.input_ghp_costs_res
(
	year integer NOT NULL,
	vertical_heat_exchanger_cost_dollars_per_ft numeric NOT NULL,
	horizontal_heat_exchanger_cost_dollars_per_ft numeric NOT NULL,
	ghp_cost_improvement_pct numeric NOT NULL,
	fixed_om_dollars_per_sf_per_year numeric NOT NULL,
	CONSTRAINT input_ghp_costs_res_year_fkey FOREIGN KEY (year)
		REFERENCES diffusion_config.sceninp_year_range (val) MATCH SIMPLE
		ON UPDATE NO ACTION ON DELETE RESTRICT
);

-- Com
DROP TABLE IF EXISTs diffusion_template.input_ghp_costs_com CASCADE;
CREATE TABLE diffusion_template.input_ghp_costs_com
(
	year integer NOT NULL,
	vertical_heat_exchanger_cost_dollars_per_ft numeric NOT NULL,
	horizontal_heat_exchanger_cost_dollars_per_ft numeric NOT NULL,
	ghp_cost_improvement_pct numeric NOT NULL,
	fixed_om_dollars_per_sf_per_year numeric NOT NULL,
	CONSTRAINT input_ghp_costs_com_year_fkey FOREIGN KEY (year)
		REFERENCES diffusion_config.sceninp_year_range (val) MATCH SIMPLE
		ON UPDATE NO ACTION ON DELETE RESTRICT
);




---- Create Views

DROP VIEW IF EXISTS diffusion_template.input_ghp_costs;
CREATE VIEW diffusion_template.input_ghp_costs as 
(
	--res, horizontal
	SELECT year, 
		'res'::char varying(3) as sector_abbr, 
		'horizontal'::text as sys_config,
		horizontal_heat_exchanger_cost_dollars_per_ft as heat_exchanger_cost_dollars_per_ft, 
		ghp_cost_improvement_pct, 
		fixed_om_dollars_per_sf_per_year
	FROM diffusion_template.input_ghp_costs_res
	UNION ALL
	-- res, vertical
		SELECT year, 
		'res'::char varying(3) as sector_abbr, 
		'vertical'::text as sys_config,
		vertical_heat_exchanger_cost_dollars_per_ft as heat_exchanger_cost_dollars_per_ft, 
		ghp_cost_improvement_pct, 
		fixed_om_dollars_per_sf_per_year
	FROM diffusion_template.input_ghp_costs_res
	UNION ALL
	-- com, horizontal
	SELECT year, 
		'com'::char varying(3) as sector_abbr, 
		'horizontal'::text as sys_config,
		horizontal_heat_exchanger_cost_dollars_per_ft as heat_exchanger_cost_dollars_per_ft, 
		ghp_cost_improvement_pct, 
		fixed_om_dollars_per_sf_per_year
	FROM diffusion_template.input_ghp_costs_com
	UNION ALL
	-- com, vertical
	SELECT year, 
		'com'::char varying(3) as sector_abbr, 
		'vertical'::text as sys_config,
		vertical_heat_exchanger_cost_dollars_per_ft as heat_exchanger_cost_dollars_per_ft, 
		ghp_cost_improvement_pct, 
		fixed_om_dollars_per_sf_per_year
	FROM diffusion_template.input_ghp_costs_com
);
