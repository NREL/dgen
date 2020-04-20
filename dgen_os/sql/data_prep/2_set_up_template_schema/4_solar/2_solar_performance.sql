set role 'diffusion-writers';


DROP TABLE IF EXIStS diffusion_template.input_solar_performance_improvements;
CREATE TABLE diffusion_template.input_solar_performance_improvements
(
	year integer NOT NULL,
	efficiency_improvement_factor numeric NOT NULL,
	density_w_per_sqft numeric NOT NULL,
	inverter_lifetime_yrs integer NOT NULL,
	CONSTRAINT input_solar_performance_improvements_year_fkey FOREIGN KEY (year)
		REFERENCES diffusion_config.sceninp_year_range (val) MATCH SIMPLE
		ON UPDATE NO ACTION ON DELETE RESTRICT
);


DROP TABLE IF EXISTS diffusion_template.input_solar_performance_annual_system_degradation;
CREATE TABLE diffusion_template.input_solar_performance_annual_system_degradation
(
	ann_system_degradation numeric not null
);


DROP TABLE IF EXIStS diffusion_template.input_solar_performance_system_sizing_factors_raw CASCADE;
CREATE TABLE diffusion_template.input_solar_performance_system_sizing_factors_raw
(
	sector text not null,
	sys_size_target_nem numeric not null,
	sys_size_target_no_nem numeric not null,
	CONSTRAINT sys_size_target_nem_check 
		CHECK (sys_size_target_nem >= 0.01 AND sys_size_target_nem <= 1::numeric),
	CONSTRAINT sys_size_target_no_nem_check 
		CHECK (sys_size_target_no_nem >= 0.01 AND sys_size_target_no_nem <= 1::numeric),
	CONSTRAINT input_solar_performance_system_sizing_factors_sector_fkey FOREIGN KEY (sector)
		REFERENCES diffusion_config.sceninp_sector (sector) MATCH SIMPLE
		ON UPDATE NO ACTION ON DELETE RESTRICT
	
);

DROP VIEW IF EXIStS diffusion_template.input_solar_performance_system_sizing_factors;
CREATE VIeW diffusion_template.input_solar_performance_system_sizing_factors AS
select b.sector_abbr, a.sys_size_target_nem, a.sys_size_target_no_nem
from diffusion_template.input_solar_performance_system_sizing_factors_raw a
left join diffusion_config.sceninp_sector b
ON a.sector = b.sector;

