set role 'diffusion-writers';

DROP TABLE IF EXISTS diffusion_shared.acs_2012_blockgroup_housing_units_by_fuel_type;
CREATE TABLE diffusion_shared.acs_2012_blockgroup_housing_units_by_fuel_type 
(
	gisjoin text primary key,
	natural_gas integer,
	propane integer,
	electricity integer,
	distallate_fuel_oil integer,
	coal_or_coke integer,
	wood integer,
	solar_energy integer,
	other integer,
	no_fuel integer
);

\COPY diffusion_shared.acs_2012_blockgroup_housing_units_by_fuel_type FROM '/Volumes/Staff/mgleason/dGeo/Data/Source_Data/ACS2008_2012_Blockgroup_HeatingFuelTypes/nhgis0035_csv/nhgis0035_ds191_20125_2012_blck_grp_simplified.csv' with csv header;


select count(*)
FROM diffusion_shared.acs_2012_blockgroup_housing_units_by_fuel_type;
-- 220333