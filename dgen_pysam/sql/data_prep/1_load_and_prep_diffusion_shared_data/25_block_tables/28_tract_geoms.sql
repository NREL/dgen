set role 'server-superusers';

DROP TABLE IF EXISTS diffusion_blocks.tract_geoms;
CREATE TABLE  diffusion_blocks.tract_geoms AS
select a.tract_id_alias, a.state_fips, a.county_fips, a.tract_fips,
	b.geoid10 as geoid, b.gisjoin as gisjoin,
	b.name10 as name, b.namelsad10 as namelsad, 
	b.aland10 as aland, b.awater10 as awater,
	b.geom as the_geom_96703
FROM diffusion_blocks.tract_ids a
LEFT join census_2010.geometries_tract b
ON a.state_fips = b.statefp10
and a.county_fips  = b.countyfp10
and a.tract_fips = b.tractce10;

-- add primary key
ALTER TABLE diffusion_blocks.tract_geoms
ADD PRIMARY KEY (tract_id_alias);

-- add 4326 geom
ALTER TABLE diffusion_blocks.tract_geoms
ADD COLUMN the_geom_4326 geometry;

UPDATE  diffusion_blocks.tract_geoms
SET the_geom_4326 = ST_Transform(the_geom_96703, 4326);

-- create geom indices
CREATE INDEX tract_geoms_gist_the_geom_4326
ON diffusion_blocks.tract_geoms
USING GIST(the_geom_4326);

CREATE INDEX tract_geoms_gist_the_geom_96703
ON diffusion_blocks.tract_geoms
USING GIST(the_geom_96703);

-- vaccuum
vacuum analyze diffusion_blocks.tract_geoms;
----------------------------------------------------------------

-- QAQC
-- make sure row count matches tract_id
select count(*)
FROM diffusion_blocks.tract_geoms;
-- 72739

-- make sure row count matches tract_id
select count(*)
FROM diffusion_blocks.tract_ids;
-- 72739 -- all set
