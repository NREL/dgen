set role 'diffusion-writers';

DROP TABLE IF EXISTs diffusion_wind.power_curve_definitions;
CREATE TABLE diffusion_wind.power_curve_definitions
(
	windspeed_ms numeric,
	turbine_id integer,
	kwh numeric
);

\COPY diffusion_wind.power_curve_definitions FROM '/Users/mgleason/NREL_Projects/github/diffusion/sql/data_prep/2a_prep_wind_resource_data/2_update_wind_generation_data/1_create_powercurve_csvs/powercurve_update_tidy_2016_04_25.csv' with csv header;

ALTER TABLE diffusion_wind.power_curve_definitions
ADD PRIMARY KEY (turbine_id, windspeed_ms);

-- select *
-- FROM diffusion_wind.power_curve_definitions;