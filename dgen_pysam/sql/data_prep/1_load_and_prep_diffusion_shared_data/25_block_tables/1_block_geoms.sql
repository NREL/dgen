set role 'diffusion-writers';

------------------------------------------------------------------------------------------
-- create the table
DROP TABLE IF EXISTS diffusion_blocks.block_geoms;
CREATE TABLE diffusion_blocks.block_geoms AS
SELECT  pgid, 
	gisjoin, 
	geoid10 as geoid,
	state_abbr,
	statefp10 as state_fips,
	countyfp10 as county_fips,
	tractce10 as tract_fips,
	ur10 as urban_rural,
	aland10 as aland_sqm,
	awater10 as awater_sqm,
	the_geom_4326 as the_poly_4326,
	ST_Transform(the_point_on_surface_102003, 4326) as the_point_4326,
	ST_Transform(the_geom_4326, 96703) as the_poly_96703,
	ST_Transform(the_point_on_surface_102003, 96703) as the_point_96703,
	aland10 > 40468.6 as exceeds_10_acres
FROM census_2010.block_geom_parent
where aland10 > 0 -- ignore blocks with no land
and statefp10 <> '72'; -- ignore puerto rico
-- 10,535,171 rows
------------------------------------------------------------------------------------------
-- add primary key
ALTER TABLE diffusion_blocks.block_geoms
ADD PRIMARY KEY (pgid);

------------------------------------------------------------------------------------------
-- add unique constraints
ALTER TABLE diffusion_blocks.block_geoms
ADD CONSTRAINT block_geoms_unique_gisjoin
UNIQUE (gisjoin);

ALTER TABLE diffusion_blocks.block_geoms
ADD CONSTRAINT block_geoms_unique_geoid
UNIQUE (geoid);

------------------------------------------------------------------------------------------
-- add indices
CREATE INDEX block_geoms_btree_state_abbr
ON diffusion_blocks.block_geoms
USING BTREE(state_abbr);

CREATE INDEX block_geoms_btree_state_fips
ON diffusion_blocks.block_geoms
USING BTREE(state_fips);

CREATE INDEX block_geoms_btree_county_fips
ON diffusion_blocks.block_geoms
USING BTREE(county_fips);

CREATE INDEX block_geoms_btree_tract_fips
ON diffusion_blocks.block_geoms
USING BTREE(tract_fips);

CREATE INDEX block_geoms_btree_exceeds_10_acres
ON diffusion_blocks.block_geoms
USING BTREE(exceeds_10_acres);

CREATE INDEX block_geoms_gist_the_poly_4326
ON diffusion_blocks.block_geoms
USING GIST(the_poly_4326);

CREATE INDEX block_geoms_gist_the_point_4326
ON diffusion_blocks.block_geoms
USING GIST(the_point_4326);

CREATE INDEX block_geoms_gist_the_poly_96703
ON diffusion_blocks.block_geoms
USING GIST(the_poly_96703);

CREATE INDEX block_geoms_gist_the_point_96703
ON diffusion_blocks.block_geoms
USING GIST(the_point_96703);

------------------------------------------------------------------------------------------
-- cluster the data by state
CLUSTER diffusion_blocks.block_geoms USING block_geoms_btree_state_fips;

------------------------------------------------------------------------------------------
-- vacuum
vacuum analyze diffusion_blocks.block_geoms;

------------------------------------------------------------------------------------------