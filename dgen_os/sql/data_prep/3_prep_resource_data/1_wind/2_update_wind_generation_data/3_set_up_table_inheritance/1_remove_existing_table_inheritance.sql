Set role 'diffusion-writers';

------------------------------------------------------------------------------------------------------------
-- ANNUAL 

-- uninherit existing wind resource tables
ALTER TABLE diffusion_wind.wind_resource_current_residential_turbine NO INHERIT diffusion_wind.wind_resource_annual;
ALTER TABLE diffusion_wind.wind_resource_current_small_commercial_turbine NO INHERIT diffusion_wind.wind_resource_annual;
ALTER TABLE diffusion_wind.wind_resource_current_mid_size_turbine NO INHERIT diffusion_wind.wind_resource_annual;
ALTER TABLE diffusion_wind.wind_resource_current_large_turbine NO INHERIT diffusion_wind.wind_resource_annual;
ALTER TABLE diffusion_wind.wind_resource_residential_near_future_turbine NO INHERIT diffusion_wind.wind_resource_annual;
ALTER TABLE diffusion_wind.wind_resource_residential_far_future_turbine NO INHERIT diffusion_wind.wind_resource_annual;
ALTER TABLE diffusion_wind.wind_resource_sm_mid_lg_near_future_turbine NO INHERIT diffusion_wind.wind_resource_annual;
ALTER TABLE diffusion_wind.wind_resource_sm_mid_lg_far_future_turbine NO INHERIT diffusion_wind.wind_resource_annual;
-- confirm no inheritance remains
select count(*)
FROM diffusion_wind.wind_resource_annual;
-- 0 -- all set


------------------------------------------------------------------------------------------------------------
-- HOURLY 

-- uninherit existing wind resource tables
ALTER TABLE diffusion_wind.wind_resource_hourly_current_residential_turbine NO INHERIT diffusion_wind.wind_resource_hourly;
ALTER TABLE diffusion_wind.wind_resource_hourly_current_small_commercial_turbine NO INHERIT diffusion_wind.wind_resource_hourly;
ALTER TABLE diffusion_wind.wind_resource_hourly_current_mid_size_turbine NO INHERIT diffusion_wind.wind_resource_hourly;
ALTER TABLE diffusion_wind.wind_resource_hourly_current_large_turbine NO INHERIT diffusion_wind.wind_resource_hourly;
ALTER TABLE diffusion_wind.wind_resource_hourly_residential_near_future_turbine NO INHERIT diffusion_wind.wind_resource_hourly;
ALTER TABLE diffusion_wind.wind_resource_hourly_residential_far_future_turbine NO INHERIT diffusion_wind.wind_resource_hourly;
ALTER TABLE diffusion_wind.wind_resource_hourly_sm_mid_lg_near_future_turbine NO INHERIT diffusion_wind.wind_resource_hourly;
ALTER TABLE diffusion_wind.wind_resource_hourly_sm_mid_lg_far_future_turbine NO INHERIT diffusion_wind.wind_resource_hourly;
-- confirm no inheritance remains
select count(*)
FROM diffusion_wind.wind_resource_hourly;
-- 0 -- all set



-- drop tables (if necessary):
-- DROP TABLE IF EXISTS diffusion_wind.wind_resource_current_residential_turbine;
-- DROP TABLE IF EXISTS diffusion_wind.wind_resource_current_small_commercial_turbine;
-- DROP TABLE IF EXISTS diffusion_wind.wind_resource_current_mid_size_turbine;
-- DROP TABLE IF EXISTS diffusion_wind.wind_resource_current_large_turbine;
-- DROP TABLE IF EXISTS diffusion_wind.wind_resource_residential_near_future_turbine;
-- DROP TABLE IF EXISTS diffusion_wind.wind_resource_residential_far_future_turbine;
-- DROP TABLE IF EXISTS diffusion_wind.wind_resource_sm_mid_lg_near_future_turbine;
-- DROP TABLE IF EXISTS diffusion_wind.wind_resource_sm_mid_lg_far_future_turbine;
-- DROP TABLE IF EXISTS diffusion_wind.wind_resource_hourly_current_residential_turbine;
-- DROP TABLE IF EXISTS diffusion_wind.wind_resource_hourly_current_small_commercial_turbine;
-- DROP TABLE IF EXISTS diffusion_wind.wind_resource_hourly_current_mid_size_turbine;
-- DROP TABLE IF EXISTS diffusion_wind.wind_resource_hourly_current_large_turbine;
-- DROP TABLE IF EXISTS diffusion_wind.wind_resource_hourly_residential_near_future_turbine;
-- DROP TABLE IF EXISTS diffusion_wind.wind_resource_hourly_residential_far_future_turbine;
-- DROP TABLE IF EXISTS diffusion_wind.wind_resource_hourly_sm_mid_lg_near_future_turbine;
-- DROP TABLE IF EXISTS diffusion_wind.wind_resource_hourly_sm_mid_lg_far_future_turbine;
