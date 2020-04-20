set role 'diffusion-writers';

-- for better disaggregations of the recs thermal demand data,
-- we are going to use totals calculated from the microdata and summed to reportable domain by climate zone

-- previously, I've compiled the RECS climate zone data to county_geom table, but that table is slightly 
-- different than the counties identified in the ACS 2013 data

-- so, we need to merge these two datasets in a manner that makes them consistent
-- in this case, we'll do it by reformatting the county_geom table to the ACS housing units
DROP TABLE IF EXISTS diffusion_shared.acs_2013_county_housing_units;
CREATE TABLE diffusion_shared.acs_2013_county_housing_units
(
	state_fips varchar(2),
	county_fips varchar(3),
	fips varchar(5),
	state text,
	county text,
	housing_units integer
);

\COPY diffusion_shared.acs_2013_county_housing_units from '/Volumes/Staff/mgleason/dGeo/Data/Source_Data/Thermal_Demand_kmccabe/simplified/archive/residential_county_housing_units_only_2016_02_29.csv' with csv header;

-- fix fips codes (left pad)
update diffusion_shared.acs_2013_county_housing_units
set state_fips = lpad(state_fips, 2, '0');

update diffusion_shared.acs_2013_county_housing_units
set county_fips = lpad(county_fips, 3, '0');

update diffusion_shared.acs_2013_county_housing_units
set fips = lpad(fips, 5, '0');

-- check count
select count(*)
FROM diffusion_shared.acs_2013_county_housing_units;
-- 3143

-- does this match the updated county geom table?
select count(*)
FROM diffusion_blocks.county_geoms;
-- 3143

-- does it match row-wise?
select count(*)
FROM diffusion_blocks.county_geoms a
FULL OUTER join diffusion_shared.acs_2013_county_housing_units b
on a.state_fips = b.state_fips
and a.county_fips = b.county_fips
where b.county_fips is null
or a.county_fips is null;
-- 0 -- yes all set

-- how many in the old county geom table?
select count(*)
FROM diffusion_blocks.county_geom;
-- 3141 -- close, good sign, but still a few counties must be off


-- which county_geom rows are missing from ACS table?
select *
from diffusion_shared.county_geom a
left join diffusion_shared.acs_2013_county_housing_units b
ON lpad(a.state_fips::TEXT, 2, '0') = b.state_fips
and a.county_fips = b.county_fips
where b.county_fips is null;
-- 9,Skagway-Hoonah-Angoon,Alaska,2,232
-- 4,Wrangell-Petersburg,Alaska,2,280
-- 3,Prince of Wales-Outer Ketchikan,Alaska,2,201

-- which ACS rows are missing from county_geom table
select *
from diffusion_shared.acs_2013_county_housing_units b
left join diffusion_shared.county_geom a
ON lpad(a.state_fips::TEXT, 2, '0') = b.state_fips
and a.county_fips = b.county_fips
where a.county_fips is null;
-- Alaska,Hoonah-Angoon Census Area
-- Alaska,Petersburg Borough
-- Alaska,Prince of Wales-Hyder Census Area
-- Alaska,Skagway Municipality
-- Alaska,Wrangell City and Borough

-- should be able to fix as follows
-- Alaska,Hoonah-Angoon Census Area -- maps to 9,Skagway-Hoonah-Angoon,Alaska 2,232
-- Alaska,Petersburg Borough -- maps to  4,Wrangell-Petersburg,Alaska 2,280
-- Alaska,Prince of Wales-Hyder Census Area -- maps to 3,Prince of Wales-Outer Ketchikan,Alaska 2,201
-- Alaska,Skagway Municipality -- maps to 9,Skagway-Hoonah-Angoon,Alaska 2,232
-- Alaska,Wrangell City and Borough -- maps to  4,Wrangell-Petersburg,Alaska 2,280

-- add the RECS climate zone and reportable domain
ALTEr TABLE diffusion_shared.acs_2013_county_housing_units
ADD recs_climate_region_pub integer,
ADD recs_reportable_domain integer;

UPdATE diffusion_shared.acs_2013_county_housing_units a
set (recs_climate_region_pub, recs_reportable_domain) = (b.climate_zone_building_america, b.recs_2009_reportable_domain)
from diffusion_shared.county_geom b
where a.county_fips = b.county_fips
and a.state_fips::INTEGER = b.state_fips;
-- 3138 rows

-- check for nulls?
select *
from diffusion_shared.acs_2013_county_housing_units
where recs_climate_region_pub is null
or recs_reportable_domain is null;
-- 5 rows identified above

-- fix manually
UPdATE diffusion_shared.acs_2013_county_housing_units a
set (recs_climate_region_pub, recs_reportable_domain) = (b.climate_zone_building_america, b.recs_2009_reportable_domain)
from diffusion_shared.county_geom b
where a.fips = '02105'
and b.county_id = 9;

UPdATE diffusion_shared.acs_2013_county_housing_units a
set (recs_climate_region_pub, recs_reportable_domain) = (b.climate_zone_building_america, b.recs_2009_reportable_domain)
from diffusion_shared.county_geom b
where a.fips = '02230'
and b.county_id = 9;

UPdATE diffusion_shared.acs_2013_county_housing_units a
set (recs_climate_region_pub, recs_reportable_domain) = (b.climate_zone_building_america, b.recs_2009_reportable_domain)
from diffusion_shared.county_geom b
where a.fips = '02195'
and b.county_id = 4;

UPdATE diffusion_shared.acs_2013_county_housing_units a
set (recs_climate_region_pub, recs_reportable_domain) = (b.climate_zone_building_america, b.recs_2009_reportable_domain)
from diffusion_shared.county_geom b
where a.fips = '02275'
and b.county_id = 4;

UPdATE diffusion_shared.acs_2013_county_housing_units a
set (recs_climate_region_pub, recs_reportable_domain) = (b.climate_zone_building_america, b.recs_2009_reportable_domain)
from diffusion_shared.county_geom b
where a.fips = '02198'
and b.county_id = 3;

-- recheck for nulls
select *
from diffusion_shared.acs_2013_county_housing_units
where recs_climate_region_pub is null
or recs_reportable_domain is null;
-- 0 -- all set

-- add description fields
ALTEr TABLE diffusion_shared.acs_2013_county_housing_units
ADD recs_climate_region_pub_desc text,
ADD recs_reportable_domain_desc text;

UPDATE diffusion_shared.acs_2013_county_housing_units
set recs_climate_region_pub_desc = 
	CASE
		WHEN recs_climate_region_pub = 1 THEN 'Very Cold/Cold'
		WHEN recs_climate_region_pub = 2 THEN 'Hot-Dry/Mixed-Dry'
		WHEN recs_climate_region_pub = 3 THEN 'Hot-Humid'
		WHEN recs_climate_region_pub = 4 THEN 'Mixed-Humid'
		WHEN recs_climate_region_pub = 5 THEN 'Marine'
	END;
-- 3141 rows

UPDATE diffusion_shared.acs_2013_county_housing_units
set recs_reportable_domain_desc = 
	CASE
		WHEN recs_reportable_domain = 1 THEN 'Connecticut, Maine, New Hampshire, Rhode Island, Vermont'
		WHEN recs_reportable_domain = 2 THEN 'Massachusetts'
		WHEN recs_reportable_domain = 3 THEN 'New York'
		WHEN recs_reportable_domain = 4 THEN 'New Jersey'
		WHEN recs_reportable_domain = 5 THEN 'Pennsylvania'
		WHEN recs_reportable_domain = 6 THEN 'Illinois'
		WHEN recs_reportable_domain = 7 THEN 'Indiana, Ohio'
		WHEN recs_reportable_domain = 8 THEN 'Michigan'
		WHEN recs_reportable_domain = 9 THEN 'Wisconsin'
		WHEN recs_reportable_domain = 10 THEN 'Iowa, Minnesota, North Dakota, South Dakota'
		WHEN recs_reportable_domain = 11 THEN 'Kansas, Nebraska'
		WHEN recs_reportable_domain = 12 THEN 'Missouri'
		WHEN recs_reportable_domain = 13 THEN 'Virginia'
		WHEN recs_reportable_domain = 14 THEN 'Delaware, District of Columbia, Maryland, West Virginia'
		WHEN recs_reportable_domain = 15 THEN 'Georgia'
		WHEN recs_reportable_domain = 16 THEN 'North Carolina, South Carolina'
		WHEN recs_reportable_domain = 17 THEN 'Florida'
		WHEN recs_reportable_domain = 18 THEN 'Alabama, Kentucky, Mississippi'
		WHEN recs_reportable_domain = 19 THEN 'Tennessee'
		WHEN recs_reportable_domain = 20 THEN 'Arkansas, Louisiana, Oklahoma'
		WHEN recs_reportable_domain = 21 THEN 'Texas'
		WHEN recs_reportable_domain = 22 THEN 'Colorado'
		WHEN recs_reportable_domain = 23 THEN 'Idaho, Montana, Utah, Wyoming'
		WHEN recs_reportable_domain = 24 THEN 'Arizona'
		WHEN recs_reportable_domain = 25 THEN 'Nevada, New Mexico'
		WHEN recs_reportable_domain = 26 THEN 'California'
		WHEN recs_reportable_domain = 27 THEN 'Alaska, Hawaii, Oregon, Washington'
	END;
-- 3143 rows

-- check for nulls?
select count(*)
from diffusion_shared.acs_2013_county_housing_units
where recs_climate_region_pub_desc is null
or recs_reportable_domain_desc is null;

-- dump the data out for kevin
\COPY diffusion_shared.acs_2013_county_housing_units TO '/Volumes/Staff/mgleason/dGeo/Data/Output/counties_to_recs_regions_lkup/county_housing_units_w_recs_regions_2016_04_05.csv' with csv header;