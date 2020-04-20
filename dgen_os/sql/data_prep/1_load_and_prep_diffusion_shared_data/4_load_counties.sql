INSERT INTO diffusion_shared.county_geom (county_id,county,state,state_abbr, the_geom_4326)
SELECT a.gid as county_id, a.NAME as county, a.state_name as state, b.state_abbr, a.the_geom_4326
FROM esri.dtl_cnty_all_multi a
LEFT JOIN esri.dtl_state b
ON a.state_name = b.state_name

-- create spatial index
CREATE INDEX county_geom_the_geom_4326_gist
  ON diffusion_shared.county_geom
  USING gist
  (the_geom_4326);

-- add in census division
ALTER TABLE diffusion_shared.county_geom ADD COLUMN census_division_abbr text;

UPDATE diffusion_shared.county_geom a
SET census_division_abbr = b.division_abbr
FROM eia.census_regions b
WHERE a.state = b.state_name;


-- add in census region
ALTER TABLE diffusion_shared.county_geom ADD COLUMN census_region text;

UPDATE diffusion_shared.county_geom a
SET census_region = b.region
FROM eia.census_regions b
WHERE a.state = b.state_name;

CREATE INDEX county_geom_census_region_btree ON diffusion_shared.county_geom USING btree(census_region);

-- add other srid geometries and indices
ALTER TABLE  diffusion_shared.county_geom 
ADD COLUMN the_geom_900914 geometry;

UPDATE diffusion_shared.county_geom SET the_geom_900914 = ST_Transform(the_geom_4326,900914);

ALTER TABLE  diffusion_shared.county_geom 
ADD COLUMN the_geom_900915 geometry;

UPDATE diffusion_shared.county_geom SET the_geom_900915 = ST_Transform(the_geom_4326,900915);

ALTER TABLE  diffusion_shared.county_geom 
ADD COLUMN the_geom_900916 geometry;

UPDATE diffusion_shared.county_geom SET the_geom_900916 = ST_Transform(the_geom_4326,900916);

ALTER TABLE  diffusion_shared.county_geom 
ADD COLUMN the_geom_96703 geometry;

UPDATE diffusion_shared.county_geom SET the_geom_96703 = ST_Transform(the_geom_4326,96703);

CREATE INDEX county_geom_the_geom_900914_gist ON diffusion_shared.county_geom USING gist(the_geom_900914);
CREATE INDEX county_geom_the_geom_900915_gist ON diffusion_shared.county_geom USING gist(the_geom_900915);
CREATE INDEX county_geom_the_geom_900916_gist ON diffusion_shared.county_geom USING gist(the_geom_900916);
CREATE INDEX county_geom_the_geom_96703_gist ON diffusion_shared.county_geom USING gist(the_geom_96703);


CLUSTER diffusion_shared.county_geom USING county_geom_the_geom_4326_gist;

VACUUM ANALYZE diffusion_shared.county_geom;


-- fix any invalid geometries
UPDATE diffusion_shared.county_geom
SET the_geom_4326 = ST_Buffer(the_geom_4326,0)
where ST_Isvalid(the_geom_4326) = false;

UPDATE diffusion_shared.county_geom
SET the_geom_900914 = ST_Buffer(the_geom_900914,0)
where ST_Isvalid(the_geom_900914) = false;

UPDATE diffusion_shared.county_geom
SET the_geom_900915 = ST_Buffer(the_geom_900915,0)
where ST_Isvalid(the_geom_900915) = false;

UPDATE diffusion_shared.county_geom
SET the_geom_900916 = ST_Buffer(the_geom_900916,0)
where ST_Isvalid(the_geom_900916) = false;

UPDATE diffusion_shared.county_geom
SET the_geom_96703 = ST_Buffer(the_geom_96703,0)
where ST_Isvalid(the_geom_96703) = false;


-- add column that corresponds to recs data "reportable_domain"
ALTER TABLE diffusion_shared.county_geom
ADD COLUMN recs_2009_reportable_domain integer;

UPDATE diffusion_shared.county_geom a
SET recs_2009_reportable_domain = b.reportable_domain
FROM diffusion_shared.eia_reportable_domain_to_state_recs_2009 b
where a.state = b.state_name;

-- add an index
CREATE INDEX county_geom_recs_2009_reportable_domain_btree 
ON diffusion_shared.county_geom 
using btree(recs_2009_reportable_domain);

SELECT *
FROM diffusion_shared.county_geom
where recs_2009_reportable_domain is null;

-- add county fips
ALTER TABLE diffusion_shared.county_geom 
ADD column county_fips character varying(3);

UPDATE diffusion_shared.county_geom  a
SET county_fips = b.cnty_fips
from esri.dtl_cnty_all_multi_20110101 b
where a.county_id = b.gid;

select count(*)
FROM diffusion_shared.county_geom
where county_fips is null;

-- add index
CREATE INDEX county_geom_county_fips_btree 
ON diffusion_shared.county_geom 
using btree(county_fips);
