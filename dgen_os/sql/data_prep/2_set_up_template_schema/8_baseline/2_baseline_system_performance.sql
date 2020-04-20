set role 'diffusion-writers';

DROP TABLE IF EXISTs diffusion_template.input_baseline_system_performance_res CASCADE;
CREATE TABLE diffusion_template.input_baseline_system_performance_res
(
	year integer not null,
	system_lifetime_yrs numeric not null,
	efficiency_improvement_pct numeric not null,
	CONSTRAINT input_baseline_system_performance_res_year_fkey FOREIGN KEY (year)
		REFERENCES diffusion_config.sceninp_year_range (val) MATCH SIMPLE
		ON UPDATE NO ACTION ON DELETE RESTRICT
);

----
-- Comm
DROP TABLE IF EXISTs diffusion_template.input_baseline_system_performance_com CASCADE;
CREATE TABLE diffusion_template.input_baseline_system_performance_com 
(
	year integer not null,
	system_lifetime_yrs numeric not null,
	efficiency_improvement_pct numeric not null,
	CONSTRAINT input_baseline_system_performance_com_year_fkey FOREIGN KEY (year)
		REFERENCES diffusion_config.sceninp_year_range (val) MATCH SIMPLE
		ON UPDATE NO ACTION ON DELETE RESTRICT
);




----------
-- Create views

DROP VIEW IF EXISTS diffusion_template.input_baseline_system_performance;
CREATE VIEW diffusion_template.input_baseline_system_performance AS 
(
	--res
	SELECT year, 
		'res'::char varying(3) as sector_abbr, 
		system_lifetime_yrs,
		efficiency_improvement_pct
	FROM diffusion_template.input_baseline_system_performance_res
	UNION ALL
	--com
	SELECT year, 
		'com'::char varying(3) as sector_abbr, 
		system_lifetime_yrs,
		efficiency_improvement_pct
	FROM diffusion_template.input_baseline_system_performance_com
);


