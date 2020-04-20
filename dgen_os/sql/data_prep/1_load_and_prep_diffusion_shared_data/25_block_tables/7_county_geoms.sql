set role 'diffusion-writers';

----------------------------------------------------------------------------------------------------------------
DROP TABLE IF EXISTS diffusion_blocks.county_geoms;
CREATE TABLE diffusion_blocks.county_geoms As
with a as
(
	select distinct state_fips, county_fips
	from diffusion_blocks.block_geoms
),
b as
(
	select a.state_fips, a.county_fips, 
		b.geoid10,b.name10 as county, ST_Transform(b.the_geom_4269, 96703) as the_geom_96703_detailed,
		ST_Transform(c.the_geom_4269, 96703) as the_geom_96703_500k,
		ST_Transform(d.the_geom_4269, 96703) as the_geom_96703_5m,
		ST_Transform(e.the_geom_4269, 96703) as the_geom_96703_20m
	from a
	LEFT JOIN census_2010.county_geom_tl b
	ON  a.state_fips || a.county_fips = b.geoid10
	LEFT JOIN census_2010.county_geom_500k c
	ON  a.state_fips || a.county_fips = c.geoid10
	LEFT JOIN census_2010.county_geom_5m d
	ON  a.state_fips || a.county_fips = d.geoid10
	LEFT JOIN census_2010.county_geom_20m e
	ON  a.state_fips || a.county_fips = e.geoid10
)
select b.*, c.state_abbr, 
	d.state,
	e.region as census_region, e.division as census_division, e.division_abbr as census_division_abbr
from b
left join diffusion_shared.state_fips_lkup c
ON b.state_fips::INTEGER = c.state_fips
LEFT JOIN diffusion_shared.state_abbr_lkup d
ON c.state_abbr = d.state_abbr
LEFT JOIN eia.census_regions_20140123 e
ON c.state_abbr = e.state_abbr;
-- 3143 rows

----------------------------------------------------------------------------------------------------------------
-- add aliased primary key
ALTER TABLE diffusion_blocks.county_geoms
ADD county_id serial PRIMARY KEY;

----------------------------------------------------------------------------------------------------------------
-- add constraints
ALTER TABLE diffusion_blocks.county_geoms
ADD CONSTRAINT county_geoms_geoid10_unique
UNIQUE (geoid10);

ALTER TABLE diffusion_blocks.county_geoms
ALTER COLUMN geoid10 set not null;

ALTER TABLE diffusion_blocks.county_geoms
ALTER COLUMN state_fips set not null;

ALTER TABLE diffusion_blocks.county_geoms
ALTER COLUMN county_fips set not null;

ALTER TABLE diffusion_blocks.county_geoms
ALTER COLUMN state_abbr set not null;

ALTER TABLE diffusion_blocks.county_geoms
ALTER COLUMN census_division_abbr set not null;
----------------------------------------------------------------------------------------------------------------
-- create indices
CREATE INDEX county_geoms_btree_state_fips
ON diffusion_blocks.county_geoms
USING BTREE(state_fips);

CREATE INDEX county_geoms_btree_county_fips
ON diffusion_blocks.county_geoms
USING BTREE(county_fips);

CREATE INDEX county_geoms_btree_state_abbr
ON diffusion_blocks.county_geoms
USING BTREE(state_abbr);

CREATE INDEX county_geoms_btree_census_division_abbr
ON diffusion_blocks.county_geoms
USING BTREE(census_division_abbr);

CREATE INDEX county_geoms_gist_the_geom_96703_detailed
ON diffusion_blocks.county_geoms
USING GIST(the_geom_96703_detailed);

CREATE INDEX county_geoms_gist_the_geom_96703_500k
ON diffusion_blocks.county_geoms
USING GIST(the_geom_96703_500k);

CREATE INDEX county_geoms_gist_the_geom_96703_5m
ON diffusion_blocks.county_geoms
USING GIST(the_geom_96703_5m);

CREATE INDEX county_geoms_gist_the_geom_96703_20m
ON diffusion_blocks.county_geoms
USING GIST(the_geom_96703_20m);

------------------------------------------------------------------------------------------------
-- add in a geography column (using the 500k version)
ALTER TABLE diffusion_blocks.county_geoms
ADD COLUMN the_geog_500k geography;

UPDATE diffusion_blocks.county_geoms
set the_geog_500k = ST_Transform(the_geom_96703_500k, 4326)::GEOGRAPHY;

-- add an index
create index county_geoms_gist_the_geog_500k
ON diffusion_blocks.county_geoms
USING GIST(the_geog_500k);

-- also add for the POS
ALTER TABLE diffusion_blocks.county_geoms
ADD COLUMN the_geog_pos_500k geography;

UPDATE diffusion_blocks.county_geoms
set the_geog_pos_500k = ST_Transform(ST_PointOnSurface(the_geom_96703_500k),4326)::GEOGRAPHY

-- add an index
create index county_geoms_gist_the_geog_pos_500k
ON diffusion_blocks.county_geoms
USING GIST(the_geog_pos_500k);

------------------------------------------------------------------------------------------------
-- add reeds and pca regions
ALTER TABLE diffusion_blocks.county_geoms
ADD COLUMN pca_reg integer,
ADD COLUMN reeds_reg integer;

with b as
(
	select a.county_id, b.pca_reg, b.demreg as reeds_reg
	from diffusion_blocks.county_geoms a
	LEFT JOIN reeds.reeds_regions b
	ON ST_Intersects(ST_PointOnSurface(a.the_geom_96703_500k), b.the_geom_96703)
	WHERE b.pca_reg NOT IN (135,136)
)
UPDATE diffusion_blocks.county_geoms a
set (pca_reg, reeds_reg) = (b.pca_reg, b.reeds_reg)
from b
where a.county_id = b.county_id;
-- 3104 rows affected

select *
FROM diffusion_blocks.county_geoms
where pca_reg is null
or reeds_reg is null;
-- review in Q -- there are a handful of coastal states in VA/NC/MD that can be fixed with a polygon overlay
-- the remainder are HI and AK, which have no reeds regions


with b as
(
	select a.county_id, b.pca_reg, b.demreg as reeds_reg
	from diffusion_blocks.county_geoms a
	LEFT JOIN reeds.reeds_regions b
	ON ST_Intersects(a.the_geom_96703_500k, b.the_geom_96703)
	WHERE a.pca_reg is null
	and b.pca_reg NOT IN (135,136)
	
)
UPDATE diffusion_blocks.county_geoms a
set (pca_reg, reeds_reg) = (b.pca_reg, b.reeds_reg)
from b
where a.county_id = b.county_id
and a.pca_reg is null;
-- 5 rows fixed

-- check the remaining nulls
select distinct state_abbr
FROM diffusion_blocks.county_geoms
where pca_reg is null;
-- AK and HI only
-- all set

-- add an index on these new columns
CREATE INDEX county_geoms_btree_reeds_reg
ON diffusion_blocks.county_geoms
USING BTREE(reeds_reg);

CREATE INDEX county_geoms_btree_pca_reg
ON diffusion_blocks.county_geoms
USING BTREE(pca_reg);

------------------------------------------------------------------------------------------------
-- add in the old county id field (from diffusion_shared.county_id
ALTER TABLE diffusion_blocks.county_geoms
ADD COLUMN old_county_id integer;

UPDATE  diffusion_blocks.county_geoms a
set old_county_id = b.county_id
FROM diffusion_shared.county_geom b
where a.state_fips::INTEGER = b.state_fips
and a.county_fips = b.county_fips;
-- 3138 rows

-- check for nulls
select  *
FROM diffusion_blocks.county_geoms
where old_county_id is null;
-- 5 counties in Alaska -- okay to ignore for now but probably not forever..

------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------
-- add in the reportable domains
ALTER TABLE diffusion_blocks.county_geoms
ADD COLUMN reportable_domain integer;

UPDATE diffusion_blocks.county_geoms a
set reportable_domain = b.reportable_domain
FROM eia.recs_2009_state_to_reportable_domain_lkup b
where a.state_abbr = b.state_abbr;
-- 3143 rows

-- check for nulls
select count(*)
FROM diffusion_blocks.county_geoms
where reportable_domain is null;
-- 0 -- all set


-- vacuum
VACUUM ANALYZE diffusion_blocks.county_geoms;