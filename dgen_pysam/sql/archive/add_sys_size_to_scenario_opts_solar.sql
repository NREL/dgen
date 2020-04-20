ALTER TABLE diffusion_solar.scenario_options
-- DROP COLUMN  res_system_sizing,
-- DROP COLUMN  com_system_sizing,
-- DROP COLUMN  ind_system_sizing;
add COLUMN res_sys_size_target numeric,
add COLUMN com_sys_size_target numeric,
add COLUMN ind_sys_size_target numeric;

ALTER TABLE diffusion_solar.scenario_options
add constraint res_sys_size_target_check CHECK (res_sys_size_target >= 0.01 and res_sys_size_target <= 1);

ALTER TABLE diffusion_solar.scenario_options
add constraint com_sys_size_target_check CHECK (com_sys_size_target >= 0.01 and com_sys_size_target <= 1);

ALTER TABLE diffusion_solar.scenario_options
add constraint ind_sys_size_target_check CHECK (ind_sys_size_target >= 0.01 and ind_sys_size_target <= 1);


select *
FROM diffusion_solar.scenario_options