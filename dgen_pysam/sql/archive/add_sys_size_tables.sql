set role 'diffusion-writers';
DROP TABLE IF EXIStS diffusion_solar.system_sizing_factors;
CREATE TABLE diffusion_solar.system_sizing_factors
(
	sector_abbr character varying(3),
	sys_size_target_nem numeric,
	sys_size_target_no_nem numeric
);

ALTER TABLE  diffusion_solar.system_sizing_factors
add constraint sys_size_target_nem_check CHECK (sys_size_target_nem >= 0.01 and sys_size_target_nem <= 1);

ALTER TABLE  diffusion_solar.system_sizing_factors
add constraint sys_size_target_no_nem_check CHECK (sys_size_target_no_nem >= 0.01 and sys_size_target_no_nem <= 1);


DROP TABLE IF EXIStS diffusion_wind.system_sizing_factors;
CREATE TABLE diffusion_wind.system_sizing_factors
(
	sector_abbr character varying(3),
	sys_size_target_nem numeric,
	sys_oversize_limit_nem numeric,
	sys_size_target_no_nem numeric,
	sys_oversize_limit_no_nem numeric
);

ALTER TABLE  diffusion_wind.system_sizing_factors
add constraint sys_size_target_nem_check CHECK (sys_size_target_nem >= 0.01 and sys_size_target_nem <= 1);

ALTER TABLE  diffusion_wind.system_sizing_factors
add constraint sys_size_target_no_nem_check CHECK (sys_size_target_no_nem >= 0.01 and sys_size_target_no_nem <= 1);

ALTER TABLE  diffusion_wind.system_sizing_factors
add constraint sys_oversize_limit_nem_check CHECK (sys_oversize_limit_nem >= 1);

ALTER TABLE  diffusion_wind.system_sizing_factors
add constraint sys_oversize_limit_no_nem_check CHECK (sys_oversize_limit_no_nem >= 1);

select *
FROM diffusion_wind.system_sizing_factors;

select *
FROM diffusion_solar.system_sizing_factors;
