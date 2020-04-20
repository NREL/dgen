set role 'diffusion-writers';

drop table if exists diffusion_geo.hvac_life_expectancy;
CREATE TABLE diffusion_geo.hvac_life_expectancy
(
	sector_abbr varchar(3),
	dataset text,
	space_equip text,
	space_fuel text,
	space_type text,
	mean numeric,
	std numeric,
	dist_type text
);

\COPY  diffusion_geo.hvac_life_expectancy FROM '/Volumes/Staff/mgleason/dGeo/Data/Source_Data/HVAC_Life_Expectancy/hvac_life_expectancy_mg.csv' with csv header;