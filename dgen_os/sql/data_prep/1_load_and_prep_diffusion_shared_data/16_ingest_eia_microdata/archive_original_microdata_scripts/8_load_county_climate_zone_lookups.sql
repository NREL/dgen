-- create two lookup tables:
	-- counties to building america climate zones (RECS 2009, CBECS 2012)
	-- counties to cdd/hdd climate zones (CBECS 2003)

set role 'eia-writers';

------------------------------------------------------------------------
-- counties to building america climate zones (RECS 2009, CBECS 2012)

DROP TABLE IF EXISTS eia.climate_zones_building_america;
CREATE TABLE eia.climate_zones_building_america
(
	state_abbr character varying(2),
	state text,
	county text,
	climate_region text
);

-- attribute with source information
comment on table eia.climate_zones_building_america
is 'Based on information from: BUILDING AMERICA BEST PRACTICES SERIES VOLUME 7.1, High-Performance Home Technologies: Guide to Determining Climate Regions by County. PNNL and Oak Ridge. Accessible online: http://apps1.eere.energy.gov/buildings/publications/pdfs/building_america/ba_climateguide_7_1.pdf.';

SET ROLE 'server-superusers';
COPY eia.climate_zones_building_america
FROM '/home/mgleason/data/dg_wind/climate_zones/ba_climate_zones_by_county.csv'
with csv header;
set role 'eia-writers';

-- add state fips, county fips
ALTER TABLE eia.climate_zones_building_america
ADD COLUMN state_fips character varying(2),
ADD COLUMN county_fips character varying(3);

-- make sure there is a match for each city
-- match each city in BA to county_geom
select a.*
FROM eia.climate_zones_building_america a
left join diffusion_shared.county_geom b
ON a.state_abbr = b.state_abbr
and a.county = b.county
where b.state_abbr is null;
-- 0 -- all set

-- match each city in county_geom to BA
select count(*)
FROM diffusion_shared.county_geom a
left join eia.climate_zones_building_america b
ON a.state_abbr = b.state_abbr
and a.county = b.county
where b.state_abbr is null;
-- 0 -- all set

-- make sure row counts match
select count(*)
FROM diffusion_shared.county_geom;
-- 3141

select count(*)
FROM eia.climate_zones_building_america;
-- 3141

UPDATE eia.climate_zones_building_america a
SET (state_fips, county_fips) = (lpad(b.state_fips::text,2,'0'), b.county_fips)
FROM diffusion_shared.county_geom b
where a.state_abbr = b.state_abbr
and a.county = b.county;

-- check state fips look right
select distinct state_fips, state_abbr
FROM eia.climate_zones_building_america 
order by 1;
-- all set

-- make sure no nulls
select count(*)
FROM eia.climate_zones_building_america
where state_fips is null
or county_fips is null;
-- 0 -- all set

-- add general climate zone name and RECS2009 code for that general zone

ALTER TABLE eia.climate_zones_building_america
ADD COLUMN climate_region_pub_txt text,
add column climate_region_pub integer;


select distinct climate_region
from eia.climate_zones_building_america
order by 1;

UPDATE eia.climate_zones_building_america
set climate_region_pub_txt =
	case when climate_region in ('Cold', 'Very Cold', 'Subarctic') then 'Very Cold/Cold/Subarctic'
	     when climate_region in ('Hot-Dry', 'Mixed-Dry') then 'Hot-Dry/Mixed-Dry'
	     when climate_region = 'Hot-Humid' then 'Hot-Humid'
	     when climate_region = 'Mixed-Humid' then 'Mixed-Humid'
	     when climate_region = 'Marine' then 'Marine'
	end,
    climate_region_pub =
  	case when climate_region in ('Cold', 'Very Cold', 'Subarctic') then 1
	     when climate_region in ('Hot-Dry', 'Mixed-Dry') then 2
	     when climate_region = 'Hot-Humid' then 3
	     when climate_region = 'Mixed-Humid' then 4
	     when climate_region = 'Marine' then 5
	end;

-- check the results look right
-- assign subarctic to the 'cold, very cold' class (this isn't quite right, but subarctic isn't included in RECS 2009
-- so we'll need some surrogate for it
select distinct climate_region_pub, climate_region_pub_txt
from eia.climate_zones_building_america
order by 1;

-- add a comment on the columns
COMMENT ON COLUMN eia.climate_zones_building_america.climate_region_pub IS 
'Generalized climate region code. Corresponds to Climate_Region_Pub from RECS 2009 Microdata. Note that Subarctic climate_region are NOT included in region 1 for RECS 2009, but are here to make sure all counties have a mapping';

COMMENT ON COLUMN eia.climate_zones_building_america.climate_region_pub_txt IS 
'Generalized climate region description. Corresponds to descriptions of Climate_Region_Pub from RECS 2009 Microdata Variable and Response Codebook. Note that Subarctic climate_region are NOT included in region Very Cold/Cold for RECS 2009, but are here to make sure all counties have a mapping';

-- add a primary key
ALTER TABLE eia.climate_zones_building_america
ADD PRIMARY KEY (state_fips, county_fips);

------------------------------------------------------------------------
-- counties to cdd/hdd climate zones (CBECS 2003)

DROP TABLE IF EXISTS eia.climate_zones_cbecs_2003;
CREATE TABLE eia.climate_zones_cbecs_2003
(
	state_abbr character varying(2),
	county text,
	climate_zone integer
);

-- attribute with source information
comment on table eia.climate_zones_cbecs_2003
is 'Based on EIA, accessible online: http://www.eia.gov/consumption/commercial/data/archive/cbecs/CBECS%20climate%20zones%20by%20county.xls';

-- add a comment on the climate zone field
COMMENT ON COLUMN eia.climate_zones_cbecs_2003.climate_zone 
IS 'Climate zone used for 2003 CBECS data. Note: there may be multiple zones listed for a single county.';

SET ROLE 'server-superusers';
COPY eia.climate_zones_cbecs_2003
FROM '/home/mgleason/data/dg_wind/climate_zones/CBECS_2003_climate_zones_by_county.csv'
with csv header;
set role 'eia-writers';

-- how many rows are there?
select count(*)
FROM eia.climate_zones_cbecs_2003;
-- 3350


-- compare to county_geom
select count(*)
FROM diffusion_shared.county_geom;
-- 3141

-- counts don't match because there are a lot of dupes..
-- per the EIA website: 
-- "Usually, there is only one climate zone per county and the mapping is straightforward. 
-- However, in some of the Western states, the NOAA climate divisions (on which the CBECS 
-- climate zones are based) are defined more by drainage basins than by counties, and so
-- sometimes there is more than one climate zone per county."

-- how many distinct counties are there?
select distinct state_abbr, county
from eia.climate_zones_cbecs_2003;
-- 3108 rows

-- what's missing?
select distinct state_abbr
from eia.climate_zones_cbecs_2003
order by 1;
-- HI, AK, and DC

-- does the row count match county_geom if we exclude those three?
select count(*)
FROM diffusion_shared.county_geom
where state_abbr not in ('AK', 'HI', 'DC');
-- 3108 
-- yes

-- make sure we have full matches in both directions
select a.state_abbr, a.county
from diffusion_shared.county_geom a
left join eia.climate_zones_cbecs_2003 b
ON a.state_abbr = b.state_abbr
and lower(a.county) = lower(b.county)
where b.state_abbr is null
and a.state_abbr not in ('AK', 'HI', 'DC');
-- 0

select a.state_abbr, a.county
from eia.climate_zones_cbecs_2003 a
left join diffusion_shared.county_geom b
ON a.state_abbr = b.state_abbr
and lower(a.county) = lower(b.county)
where b.state_abbr is null
and a.state_abbr not in ('AK', 'HI', 'DC');
-- 0 all set

-- add data for DC, AK, and HI -- based on the eia map at http://www.eia.gov/consumption/commercial/maps.cfm
-- AK = zone 1
INSERT INTO eia.climate_zones_cbecs_2003
select state_abbr, county, 1
from diffusion_shared.county_geom
where state_abbr = 'AK';
-- 1 row

-- HI = Zones 4 and 5
INSERT INTO eia.climate_zones_cbecs_2003
select state_abbr, county,
	case when county in ('Hawaii','Maui') then 4
	     when county in ('Honolulu','Kauai','Kalawao') then 5
	end
from diffusion_shared.county_geom
where state_abbr = 'HI';
-- 5 rows

-- DC = zone 4
INSERT INTO eia.climate_zones_cbecs_2003
select state_abbr, county, 4
from diffusion_shared.county_geom
where state_abbr = 'DC';
-- 1 row

-- add the state and county fips codes (and state name)
ALTER TABLE eia.climate_zones_cbecs_2003
ADD COLUMN state_fips character varying(2),
ADD COLUMN county_fips character varying(3),
add column state text;

UPDATE eia.climate_zones_cbecs_2003 a
SET (state, state_fips, county_fips) = (b.state, lpad(b.state_fips::text,2,'0'), b.county_fips)
FROM diffusion_shared.county_geom b
where a.state_abbr = b.state_abbr
and lower(a.county) = lower(b.county);

-- make sure no nulls
select count(*)
FROM eia.climate_zones_cbecs_2003
where state_fips is null 
or county_fips is null
or state is null;
-- 0 rows

-- fix the counties with multiple climate zones
-- i don't know anything about the area weights for each climate zone/county, so
-- to fix the duplicates i will just randomly select one climate zone for each county
set seed to 1;
DROP TABLE IF EXISTS eia.climate_zones_cbecs_2003_1_zone_per_county;
CREATE TABLE eia.climate_zones_cbecs_2003_1_zone_per_county AS
with a as
(
	select *, random()
	from eia.climate_zones_cbecs_2003
), b
AS
(
	select *, row_number() OVEr (partition by state_abbr, county order by random desc)
	from a
)
select state, state_abbr, county, state_fips, county_fips, climate_zone 
FROM b
where row_number = 1;
-- 3141 rows

-- add a comment on this table
COMMENT ON TABLE eia.climate_zones_cbecs_2003_1_zone_per_county
IS 'Unlike eia.climate_zones_cbecs_2003, this table ensures that each county is only mapped to a single climate zone. In the absence of any useful information about which climate zone to pick when there are multiple for a given county, this table was created by randomly selecting a single climate zone from sets of multiples.';

COMMENT ON COLUMN eia.climate_zones_cbecs_2003.climate_zone 
IS 'Climate zone used for 2003 CBECS data.';

-- add a primary key
ALTER TABLE eia.climate_zones_cbecs_2003_1_zone_per_county
ADD PRIMARY KEY (state_fips, county_fips);



------------------------------------------------------------------------
-- carry this info over into diffusion_shared.county_geom
set role 'diffusion-writers';
ALTER TABLE diffusion_shared.county_geom
ADD COLUMN climate_zone_building_america integer,
add column climate_zone_cbecs_2003 integer;

UPDATE diffusion_shared.county_geom a
set climate_zone_building_america = b.climate_region_pub
from eia.climate_zones_building_america b
where a.state_fips = b.state_fips::integer
and a.county_fips = b.county_fips;

UPDATE diffusion_shared.county_geom a
set climate_zone_cbecs_2003 = b.climate_zone
from eia.climate_zones_cbecs_2003_1_zone_per_county b
where a.state_fips = b.state_fips::integer
and a.county_fips = b.county_fips;

-- ensure no nulls
select *
FROM diffusion_shared.county_geom
where climate_zone_cbecs_2003 is null
or climate_zone_building_america is null;
-- 0 rows

-- look at results in Q and compare to EIA maps
-- results look good for climate_zone_building_america
-- and good enough for climate_zone_cbecs_2003 (sinc we will be updating to cbecs 2012, which used the building america climate zones)

------------------------------------------------------------------------------------------
-- confirm that all combinations of climate zone + reportable domain or census_division_abbr
-- have corresponding populations from recs/cbecs microdata

-- they do not all have matches
-- the following queries show the issues, and give potential substitutions for fill
-- for the missing cross-sections, but the solution hasn't actually been implemented
-- see issue #363

-- recs
with a as
(
	select distinct recs_2009_reportable_domain as reportable_domain, 
			climate_zone_building_america as climate_zone
	from diffusion_shared.county_geom a
),
b as
(
	select distinct reportable_domain, 
				climate_zone
	from diffusion_shared.cbecs_recs_combined 
	where sector_abbr = 'res'
)
select *
FROM a
left join b
ON a.reportable_domain = b.reportable_domain
and a.climate_zone = b.climate_zone
where b.reportable_domain is null;
-- missing rep domain/climate zones are:
-- 22;2 - Colorado - Hot-Dry/Mixed-Dry -- use samples from NM (25)
-- 16;1 - NC/SC - Very Cold/Cold - Use Samples from WV? (14)
-- 20;2 - AR, LA, OK - Hot-Dry/Mixed-Dry -- this is OK only, use sample from TX (21)
-- 23;2 - ID, MT, UT, WY - Hot-Dry/Mixed-Dry  -- this is UT only, use sample from AZ (24)
-- 21;4 - TX - Mixed Humid - this is TX only -- use sample from OK (20)
-- 12;1 - MO - Very Cold/Cold - use sample from 11 (KS/NE)
-- 26;1 - CA - Very Cold/Cold - Use sample from NV (25)

-- cbecs
with a as
(
	select distinct census_division_abbr, 
			climate_zone_cbecs_2003 as climate_zone
	from diffusion_shared.county_geom a
),
b as
(
	select distinct census_division_abbr, 
				climate_zone
	from diffusion_shared.cbecs_recs_combined 
	where sector_abbr = 'com'
)
select *
FROM a
left join b
ON a.census_division_abbr = b.census_division_abbr
and a.climate_zone = b.climate_zone
where b.census_division_abbr is null;
-- missing combinations are:
-- MTN;4 -- use WSC 4?
-- SA;2 -- use MA 2
-- ENC;3 -- use ESC 3
-- MTN;3 -- use WSC 3




--------------------------------------------------------------------------------
-- check counts of climate x reportable domain/census division cross sections
-- from recs and cbecs

-- recs
with a as
(
	select reportable_domain, climate_zone, count(*) 
	from diffusion_shared.cbecs_recs_combined 
	where sector_abbr = 'res'
	group by reportable_domain, climate_zone
	order by count
),
b as
(
	select reportable_domain, count(*)
	from diffusion_shared.cbecs_recs_combined 
	where sector_abbr = 'res'
	group by reportable_domain
	order by count
),
c as
(
	select climate_zone, count(*)
	from diffusion_shared.cbecs_recs_combined 
	where sector_abbr = 'res'
	group by climate_zone
	order by count
)
select a.reportable_domain, a.climate_zone, a.count as x_count, 
	b.count as rd_count, 
	c.count as clim_count
from a
LEFT JOIN b
ON a.reportable_domain = b.reportable_domain
lEFT JOIN c
on a.climate_zone = c.climate_zone


-- cbecs
with a as
(
	select census_division_abbr, climate_zone, count(*)
	from diffusion_shared.cbecs_recs_combined 
	where sector_abbr = 'com'
	and climate_zone <= 5
	group by census_division_abbr, climate_zone
	order by count
),
b as
(
	select census_division_abbr, count(*)
	from diffusion_shared.cbecs_recs_combined 
	where sector_abbr = 'com'
	group by census_division_abbr
	order by count
),
c as
(
	select climate_zone, count(*)
	from diffusion_shared.cbecs_recs_combined 
	where sector_abbr = 'com'
	and climate_zone <= 5
	group by climate_zone
	order by count
)
select a.census_division_abbr, a.climate_zone, a.count as x_count,
	b.count as div_count,
	c.count as clim_count
FROM a
left join b
ON a.census_division_abbr = b.census_division_abbr
left join c
ON a.climate_zone = c.climate_zone;

-- some cross sections have REALLY small sample sizes in both recs and cbecs
-- potential solutions:
	-- 1) move to a higher aggregation level (reportable_domain --> census_division_abbr, census_division_abbr --> census_region)
	-- 2) manually group certain cross-sections that make sense to go togehter (e.g., cold CA + cold NV, etc.) to reach reaasonable sample sizes