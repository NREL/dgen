set role 'diffusion-writers';

DROP TABLE IF EXISTS diffusion_wind.power_curve_lkup;
CREATE TABLE diffusion_wind.power_curve_lkup
(
	size_class text,
	perf_improvement_factor numeric,
	turbine_id integer
);

ALTER TABLE diffusion_wind.power_curve_lkup
ADD PRIMARY KEY (size_class, perf_improvement_factor);

\COPY diffusion_wind.power_curve_lkup from '/Users/mgleason/NREL_Projects/github/diffusion/sql/data_prep/2a_prep_wind_resource_data/2_update_wind_generation_data/1_create_powercurve_csvs/powercurve_lookup_2016_01_08.csv' with csv header;

-- check result
select *
FROM diffusion_wind.power_curve_lkup;