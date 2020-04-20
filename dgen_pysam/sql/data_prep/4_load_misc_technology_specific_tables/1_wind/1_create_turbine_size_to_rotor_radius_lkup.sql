set role 'diffusion-writers';

DROP TABLE IF EXISTS diffusion_wind.turbine_size_to_rotor_radius_lkup;
CREATE TABLE diffusion_wind.turbine_size_to_rotor_radius_lkup
(
	turbine_size_kw numeric primary key,
	rotor_radius_m numeric
);

\COPY diffusion_wind.turbine_size_to_rotor_radius_lkup FROM '/Users/mgleason/NREL_Projects/github/diffusion/analysis/1_dwind_tech_potential/input_files/turbine_size_to_rotor_radius_lkup.csv' WITH CSV HEADER;

select *
FROM diffusion_wind.turbine_size_to_rotor_radius_lkup;