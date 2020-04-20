SET ROLE 'dg_wind-writers';
DROP TABLE IF EXISTS dg_wind.acs_2013_tenure_by_housing_units_in_structure;
CREATE TABLE dg_wind.acs_2013_tenure_by_housing_units_in_structure
(
	gisjoin text,
	year character varying(9),
	state text,
	statea integer,
	county text,
	countya integer,
	full_county_name text,
	tot_occu_h integer,
	own_occu_h integer,
	own_occu_1str_detached_h integer,
	own_occu_1str_attached_h integer,
	own_occu_mobile_h integer
);

SET ROLE 'server-superusers';
SET client_encoding to "LATIN1";
COPY dg_wind.acs_2013_tenure_by_housing_units_in_structure FROM '/srv/home/mgleason/data/dg_wind/nhgis0014_ds201_20135_2013_county_simplified.csv'
WITH CSV HEADER;
SET client_encoding TO 'UNICODE';
SET ROLE 'dg_wind-writers';

-- have to join on fips codes, which requires some prejoins
DROP TABLE IF EXISTS dg_wind.county_housing_units;
CREATE TABLE dg_wind.county_housing_units AS
SELECT a.county_id, a.state, a.county, 
	a.state_fips, a.county_fips::integer as county_fips,
	b.tot_occu_h,
	b.own_occu_1str_detached_h + b.own_occu_1str_attached_h + b.own_occu_mobile_h as own_occu_1str_all,
	(b.own_occu_1str_detached_h + b.own_occu_1str_attached_h + b.own_occu_mobile_h)::numeric/tot_occu_h as perc_own_occu_1str_housing
FROM diffusion_shared.county_geom a
LEFT JOIN dg_wind.acs_2013_tenure_by_housing_units_in_structure b
ON a.state_fips = b.statea
and a.county_fips::integer = b.countya;

-- check for nulls
select *
FROM dg_wind.county_housing_units
where perc_own_occu_1str_housing is null;

-- 3 counties in alaska
-- 3;'Prince of Wales-Outer Ketchikan' fips = 201
-- 9;'Skagway-Hoonah-Angoon' fips = 232
-- 4;'Wrangell-Petersburg' fips = 280

-- look for these in the acs table
SELECT *
FROM dg_wind.acs_2013_tenure_by_housing_units_in_structure
where state = 'Alaska'
ORDER BY county;
-- these counties exist -- they are just separate in ACS


-- sum them to fix
WITH b AS 
(
	SELECT sum(tot_occu_h) as tot_occu_h, 
	       sum(own_occu_1str_detached_h + own_occu_1str_attached_h + own_occu_mobile_h) as own_occu_1str_all,
	       sum(own_occu_1str_detached_h + own_occu_1str_attached_h + own_occu_mobile_h)::numeric/sum(tot_occu_h) as perc_own_occu_1str_housing

	FROM dg_wind.acs_2013_tenure_by_housing_units_in_structure
	WHERE full_county_name in ('Skagway Municipality, Alaska','Hoonah-Angoon Census Area, Alaska')
)
UPDATE dg_wind.county_housing_units a
SET (tot_occu_h, own_occu_1str_all, perc_own_occu_1str_housing) = (b.tot_occu_h, b.own_occu_1str_all, b.perc_own_occu_1str_housing)
FROM b
where a.county_id = 9;


WITH b AS 
(
	SELECT sum(tot_occu_h) as tot_occu_h, 
	       sum(own_occu_1str_detached_h + own_occu_1str_attached_h + own_occu_mobile_h) as own_occu_1str_all,
	       sum(own_occu_1str_detached_h + own_occu_1str_attached_h + own_occu_mobile_h)::numeric/sum(tot_occu_h) as perc_own_occu_1str_housing

	FROM dg_wind.acs_2013_tenure_by_housing_units_in_structure
	WHERE full_county_name in ('Wrangell City and Borough, Alaska','Petersburg Census Area, Alaska')
)
UPDATE dg_wind.county_housing_units a
SET (tot_occu_h, own_occu_1str_all, perc_own_occu_1str_housing) = (b.tot_occu_h, b.own_occu_1str_all, b.perc_own_occu_1str_housing)
FROM b
where a.county_id = 4;


WITH b AS 
(
	SELECT sum(tot_occu_h) as tot_occu_h, 
	       sum(own_occu_1str_detached_h + own_occu_1str_attached_h + own_occu_mobile_h) as own_occu_1str_all,
	       sum(own_occu_1str_detached_h + own_occu_1str_attached_h + own_occu_mobile_h)::numeric/sum(tot_occu_h) as perc_own_occu_1str_housing

	FROM dg_wind.acs_2013_tenure_by_housing_units_in_structure
	WHERE full_county_name in ('Prince of Wales-Hyder Census Area, Alaska')
)
UPDATE dg_wind.county_housing_units a
SET (tot_occu_h, own_occu_1str_all, perc_own_occu_1str_housing) = (b.tot_occu_h, b.own_occu_1str_all, b.perc_own_occu_1str_housing)
FROM b
where a.county_id = 3;

-- confirm nothing is missing now
-- look for unjoined data
SELECT *
FROM dg_wind.county_housing_units
where perc_own_occu_1str_housing is null;

-- copy data to diffusion_shared schema
set role 'server-superusers';
DROP TABLE IF EXISTS diffusion_shared.county_housing_units CASCADE;
CREATE TABLE diffusion_shared.county_housing_units AS
SELECT county_id, perc_own_occu_1str_housing 
FROM  dg_wind.county_housing_units;

ALTER TABLE diffusion_shared.county_housing_units OWNER TO "diffusion-writers";


ALTER TABLE diffusion_shared.county_housing_units
ADD primary key (county_id);

