ALTER TABLE diffusion_wind.scenario_options
-- DROP COLUMN  res_sys_size_target,
-- DROP COLUMN  com_sys_size_target,
-- DROP COLUMN  ind_sys_size_target;
add COLUMN res_sys_size_target numeric,
add COLUMN com_sys_size_target numeric,
add COLUMN ind_sys_size_target numeric,
add COLUMN res_oversize_limit numeric,
add COLUMN com_oversize_limit numeric,
add COLUMN ind_oversize_limit numeric;

ALTER TABLE diffusion_wind.scenario_options
add constraint res_sys_size_target_check CHECK (res_sys_size_target >= 0.01 and res_sys_size_target <= 1);

ALTER TABLE diffusion_wind.scenario_options
add constraint com_sys_size_target_check CHECK (com_sys_size_target >= 0.01 and com_sys_size_target <= 1);

ALTER TABLE diffusion_wind.scenario_options
add constraint ind_sys_size_target_check CHECK (ind_sys_size_target >= 0.01 and ind_sys_size_target <= 1);

ALTER TABLE diffusion_wind.scenario_options
add constraint res_oversize_limit_check CHECK (res_oversize_limit >= 1);

ALTER TABLE diffusion_wind.scenario_options
add constraint com_oversize_limit_check CHECK (com_oversize_limit >= 1);

ALTER TABLE diffusion_wind.scenario_options
add constraint ind_oversize_limit_Check CHECK (ind_oversize_limit >= 1);


select *
FROM diffusion_wind.scenario_options