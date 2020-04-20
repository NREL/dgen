set role 'diffusion-writers';

DROP TABLE IF EXISTS diffusion_shared.county_thermal_demand_res;
CREATE TABLE diffusion_shared.county_thermal_demand_res
(
	state_fips varchar(2),
	county_fips varchar(3),
	fips varchar(5),
	state text,
	county text,
	housing_units integer,
	county_weight numeric,
	space_heating_thermal_load_mmbtu numeric,
	water_heating_thermal_load_mmbtu numeric,
	space_cooling_thermal_load_mmbtu numeric
);

------------------------------------------------------------------------------------------------
-- RESIDENTIAL

-- load residential data
\COPY diffusion_shared.county_thermal_demand_res FROM '/Volumes/Staff/mgleason/dGeo/Data/Source_Data/Thermal_Demand_kmccabe/simplified/res_county_demand_tbtu_simplified_2016_03_18.csv' with csv header;

-- note: data comes in in tbtu -- convert to mmbtu
UPDATE diffusion_shared.county_thermal_demand_res
set space_heating_thermal_load_mmbtu = space_heating_thermal_load_mmbtu * 1e6;

UPDATE diffusion_shared.county_thermal_demand_res
set water_heating_thermal_load_mmbtu = water_heating_thermal_load_mmbtu * 1e6;

UPDATE diffusion_shared.county_thermal_demand_res
set space_cooling_thermal_load_mmbtu = space_cooling_thermal_load_mmbtu * 1e6;



-- add total_heating_thermal_load_tbtu numeric,
ALTER TABLE diffusion_shared.county_thermal_demand_res
ADD COLUMN total_heating_thermal_load_mmbtu numeric;

UPDATE diffusion_shared.county_thermal_demand_res
set total_heating_thermal_load_mmbtu = space_heating_thermal_load_mmbtu + water_heating_thermal_load_mmbtu;
-- 3141 rows


-- add sector_abbr column
ALTER TABLE diffusion_shared.county_thermal_demand_res
ADD COLUMN sector_abbr varchar(3);

UPDATE diffusion_shared.county_thermal_demand_res
set sector_abbr = 'res';
-- 3141 rows

-- fix fips codes (left pad)
update diffusion_shared.county_thermal_demand_res
set state_fips = lpad(state_fips, 2, '0');

update diffusion_shared.county_thermal_demand_res
set county_fips = lpad(county_fips, 3, '0');

update diffusion_shared.county_thermal_demand_res
set fips = lpad(fips, 5, '0');

-- check count and compare to county_geom table
select count(*)
FROM diffusion_shared.county_thermal_demand_res;
-- 3141 counties

-- how many in county geom table?
select count(*)
FROM diffusion_shared.county_geom;
-- 3141 -- match -- good sign, but check joins

-- are there any missing counties?
select count(*)
from diffusion_shared.county_geom a
FULL OUTER join diffusion_shared.county_thermal_demand_res b
ON lpad(a.state_fips::TEXT, 2, '0') = b.state_fips
and a.county_fips = b.county_fips
where a.county_fips is null
OR b.county_fips is null;
-- 0 rows -- all set!

-- add county id column
ALTER TABLE diffusion_shared.county_thermal_demand_res
ADD COLUMN county_id integer;

UPDATE diffusion_shared.county_thermal_demand_res a
set county_id = b.county_id
from diffusion_shared.county_geom b
where a.state_fips = lpad(b.state_fips::TEXT, 2, '0')
and a.county_fips = b.county_fips;
-- 3141 rows

-- check for nulls?
select count(*)
FROM diffusion_shared.county_thermal_demand_res
where county_id is null;
-- 0 -- all set

-- add state_abbr
ALTER TABLE diffusion_shared.county_thermal_demand_res
ADD COLUMN state_abbr varchar(2);

UPDATE diffusion_shared.county_thermal_demand_res a
set state_abbr = b.state_abbr
from diffusion_shared.county_geom b
where a.county_id = b.county_id;
-- 3141 rows affecteds

-- add primary key
ALTER TABLE diffusion_shared.county_thermal_demand_res
ADD PRIMARY KEY (county_id);


-- check for cases where water heating is more than space heating
select *
FROM diffusion_shared.county_thermal_demand_res
where space_heating_thermal_load_mmbtu < water_heating_thermal_load_mmbtu;
-- 118 rows
-- all in FL, AZ, part of CA, and HI -- makes sense

-- how about cooling exceeding space heating?
select *
FROM diffusion_shared.county_thermal_demand_res
where space_heating_thermal_load_mmbtu < space_cooling_thermal_load_mmbtu;
-- rows in GA, HI, FL, AL, AZ, MS
-- 216 rows -- all seem reasonable

------------------------------------------------------------------------------------------------

-- create a view for mapping
-- set role 'dgeo-writers';
-- DROP TABLE IF EXISTS dgeo.county_thermal_demand_res;
-- CREATE TABLE dgeo.county_thermal_demand_res AS
-- SELECT b.the_geom_96703, a.*
-- from diffusion_shared.county_thermal_demand_res a
-- LEFT JOIN diffusion_shared.county_geom b
-- ON a.county_id = b.county_id;