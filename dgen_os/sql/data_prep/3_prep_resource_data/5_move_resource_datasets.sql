-- move the solar datasets
SET Role 'server-superusers';

SELECT add_schema('diffusion_resource_solar', 'diffusion');

set role 'diffusion-writers';

ALTER TABLE diffusion_solar.solar_resource_annual_e SET SCHEMA diffusion_resource_solar;
ALTER TABLE diffusion_solar.solar_resource_annual_s SET SCHEMA diffusion_resource_solar;
ALTER TABLE diffusion_solar.solar_resource_annual_se SET SCHEMA diffusion_resource_solar;
ALTER TABLE diffusion_solar.solar_resource_annual_sw SET SCHEMA diffusion_resource_solar;
ALTER TABLE diffusion_solar.solar_resource_annual_w SET SCHEMA diffusion_resource_solar;

ALTER TABLE diffusion_solar.solar_resource_hourly_e SET SCHEMA diffusion_resource_solar;
ALTER TABLE diffusion_solar.solar_resource_hourly_s SET SCHEMA diffusion_resource_solar;
ALTER TABLE diffusion_solar.solar_resource_hourly_se SET SCHEMA diffusion_resource_solar;
ALTER TABLE diffusion_solar.solar_resource_hourly_sw SET SCHEMA diffusion_resource_solar;
ALTER TABLE diffusion_solar.solar_resource_hourly_w SET SCHEMA diffusion_resource_solar;

-- move parent tables
ALTER TABLE diffusion_solar.solar_resource_hourly SET SCHEMA diffusion_resource_solar;
ALTER TABLE diffusion_solar.solar_resource_annual SET SCHEMA diffusion_resource_solar;

---------------------------------------------------------------------------------------------------
-- move the wind datasets
SET Role 'server-superusers';

SELECT add_schema('diffusion_resource_wind', 'diffusion');

set role 'diffusion-writers';

ALTER TABLE diffusion_wind.wind_resource_annual_turbine_1 SET SCHEMA diffusion_resource_wind;
ALTER TABLE diffusion_wind.wind_resource_annual_turbine_2 SET SCHEMA diffusion_resource_wind;
ALTER TABLE diffusion_wind.wind_resource_annual_turbine_3 SET SCHEMA diffusion_resource_wind;
ALTER TABLE diffusion_wind.wind_resource_annual_turbine_4 SET SCHEMA diffusion_resource_wind;
ALTER TABLE diffusion_wind.wind_resource_annual_turbine_5 SET SCHEMA diffusion_resource_wind;
ALTER TABLE diffusion_wind.wind_resource_annual_turbine_6 SET SCHEMA diffusion_resource_wind;
ALTER TABLE diffusion_wind.wind_resource_annual_turbine_7 SET SCHEMA diffusion_resource_wind;
ALTER TABLE diffusion_wind.wind_resource_annual_turbine_8 SET SCHEMA diffusion_resource_wind;

ALTER TABLE diffusion_wind.wind_resource_hourly_turbine_1 SET SCHEMA diffusion_resource_wind;
ALTER TABLE diffusion_wind.wind_resource_hourly_turbine_2 SET SCHEMA diffusion_resource_wind;
ALTER TABLE diffusion_wind.wind_resource_hourly_turbine_3 SET SCHEMA diffusion_resource_wind;
ALTER TABLE diffusion_wind.wind_resource_hourly_turbine_4 SET SCHEMA diffusion_resource_wind;
ALTER TABLE diffusion_wind.wind_resource_hourly_turbine_5 SET SCHEMA diffusion_resource_wind;
ALTER TABLE diffusion_wind.wind_resource_hourly_turbine_6 SET SCHEMA diffusion_resource_wind;
ALTER TABLE diffusion_wind.wind_resource_hourly_turbine_7 SET SCHEMA diffusion_resource_wind;
ALTER TABLE diffusion_wind.wind_resource_hourly_turbine_8 SET SCHEMA diffusion_resource_wind;


-- move parent tables
ALTER TABLE diffusion_wind.wind_resource_hourly SET SCHEMA diffusion_resource_wind;
ALTER TABLE diffusion_wind.wind_resource_annual SET SCHEMA diffusion_resource_wind;