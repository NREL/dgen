set role 'diffusion-writers';

-- improvements
DROP TABLE IF EXISTs diffusion_template.input_ghp_performance_improvements CASCADE;
CREATE TABLE diffusion_template.input_ghp_performance_improvements
(
	year integer NOT NULL,
	ghp_heat_pump_lifetime_yrs numeric NOT NULL,
	ghp_efficiency_improvement_pct numeric NOT NULL,
	CONSTRAINT input_ghp_performance_improvements_year_fkey FOREIGN KEY (year)
		REFERENCES diffusion_config.sceninp_year_range (val) MATCH SIMPLE
		ON UPDATE NO ACTION ON DELETE RESTRICT
);