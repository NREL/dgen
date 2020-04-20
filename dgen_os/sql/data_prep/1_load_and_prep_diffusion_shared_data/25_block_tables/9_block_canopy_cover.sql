set role 'diffusion-writers';

------------------------------------------------------------------------------------------
-- create table for small blocks
DROP TABLE IF EXISTS diffusion_blocks.block_canopy_cover_small_blocks;
CREATE UNLOGGED TABLE diffusion_blocks.block_canopy_cover_small_blocks 
(
	pgid bigint,
	canopy_pct integer
);

select parsel_2('dav-gis', 'mgleason', 'mgleason',
				'diffusion_blocks.block_geoms_small', 'pgid',
				'select a.pgid, ST_Value(b.rast, a.the_point_4326) as canopy_pct
				FROM diffusion_blocks.block_geoms_small a
				LEFT JOIN diffusion_data_wind.canopy_pct_100x100 b
				ON ST_Intersects(a.the_point_4326, b.rast)',
				'diffusion_blocks.block_canopy_cover_small_blocks', 'a', 16
				);


------------------------------------------------------------------------------------------
-- create table for big blocks
DROP TABLE IF EXISTS diffusion_blocks.block_canopy_cover_big_blocks;
CREATE UNLOGGED TABLE diffusion_blocks.block_canopy_cover_big_blocks 
(
	pgid bigint,
	canopy_pct integer
);


select parsel_2('dav-gis', 'mgleason', 'mgleason',
				'diffusion_blocks.block_geoms_big', 'pgid',
				'with a as
				(
					SELECT a.pgid,
						   ST_SummaryStats(ST_Clip(b.rast, a.the_poly_4326)) as stats
					FROM diffusion_blocks.block_geoms_big a
					LEFT JOIN diffusion_data_wind.canopy_pct_100x100 b
					ON ST_Intersects(a.the_poly_4326, b.rast)
				),
				b as
				(
					select b.pgid, (a.stats).sum, (a.stats).count
					from diffusion_blocks.block_geoms_big b
					LEFT JOIN a
					ON b.pgid = a.pgid
				),
				c as
				(
				select b.pgid, sum(b.sum) as sum,
						sum(b.count) as count
				from b
				group by b.pgid
				)
				SELECT c.pgid,
					CASE WHEN count > 0 THEN sum/count
					ELSE NULL
					END as canopy_pct
				FROM c;',
				'diffusion_blocks.block_canopy_cover_big_blocks', 'a', 16
				);


------------------------------------------------------------------------------------------
-- QA/QC -- small blocks
-- add primary key
ALTER TABLE diffusion_blocks.block_canopy_cover_small_blocks
ADD PRIMARY KEY (pgid);

-- check row count
select count(*)
FROM diffusion_blocks.block_canopy_cover_small_blocks;
-- 5968895

-- check for nulls
select count(*)
FROM diffusion_blocks.block_canopy_cover_small_blocks
where canopy_pct is null;
-- 48252 rows

-- where are these
select distinct b.state_abbr
FROM diffusion_blocks.block_canopy_cover_small_blocks a
left join diffusion_blocks.block_geoms b
ON a.pgid = b.pgid
where a.canopy_pct is null
order by b.state_abbr;
-- 37 states -- althought all seem to be either border or coastal

-- look at them in Q
DROP TABLE IF EXISTS diffusion_blocks.block_canopy_cover_small_blocks_no_data;
CREATE TABLE diffusion_blocks.block_canopy_cover_small_blocks_no_data AS
select b.*
from diffusion_blocks.block_canopy_cover_small_blocks a
left join diffusion_blocks.block_geoms b
ON a.pgid = b.pgid
where a.canopy_pct is null;
-- all missing data are around the borders and coastlines of hte US

-- drop the temporary geom table
DROP TABLE IF EXISTS diffusion_blocks.block_canopy_cover_small_blocks_no_data;

-- fix using nearest neighbor in the same county with good data
with a as
(
	select a.pgid, b.state_fips, b.county_fips, b.the_point_96703
	from diffusion_blocks.block_canopy_cover_small_blocks a
	left join diffusion_blocks.block_geoms b
	ON a.pgid = b.pgid
	where a.canopy_pct is null
),
b as
(
	select a.pgid, a.canopy_pct, b.state_fips, b.county_fips, b.the_point_96703
	from diffusion_blocks.block_canopy_cover_small_blocks a
	left join diffusion_blocks.block_geoms b
	ON a.pgid = b.pgid
	where a.canopy_pct is NOT null
),
c as
(
	select a.pgid, b.canopy_pct, 
		ST_Distance(a.the_point_96703, b.the_point_96703) as dist_m
	from a
	left join b
	ON a.state_fips = b.state_fips
	and a.county_fips = b.county_fips
),
d AS
(
	select distinct on (c.pgid) c.pgid, c.canopy_pct
	from c
	ORDER BY c.pgid ASC, c.dist_m asc
)
UPDATE diffusion_blocks.block_canopy_cover_small_blocks e
set canopy_pct = d.canopy_pct
from d
where e.pgid = d.pgid
AND e.canopy_pct is null;
-- 48252 rows

-- recheck for nulls
select count(*)
FROM diffusion_blocks.block_canopy_cover_small_blocks
where canopy_pct is null;
-- 23016

-- where are these
select distinct b.state_abbr
FROM diffusion_blocks.block_canopy_cover_small_blocks a
left join diffusion_blocks.block_geoms b
ON a.pgid = b.pgid
where a.canopy_pct is null;
-- all in AK and HI -- all set

------------------------------------------------------------------------------------------
-- QA/QC -- big blocks
-- add primary key
ALTER TABLE diffusion_blocks.block_canopy_cover_big_blocks
ADD PRIMARY KEY (pgid);

-- check row count
select count(*)
FROM diffusion_blocks.block_canopy_cover_big_blocks;
-- 4566276

-- check for nulls
select count(*)
FROM diffusion_blocks.block_canopy_cover_big_blocks
where canopy_pct is null;
-- 115222 nulls 

-- where are these
select distinct b.state_abbr
FROM diffusion_blocks.block_canopy_cover_big_blocks a
left join diffusion_blocks.block_geoms b
ON a.pgid = b.pgid
where a.canopy_pct is null
order by b.state_abbr;
-- all states  -- most likely this is borders/coastlines + sliver polys
-- create a view to look at in Q

-- use centroid overlay to fix the sliver blocks
WITH b as
(
	select a.pgid, ST_Value(c.rast, b.the_point_4326) as canopy_pct
	FROM diffusion_blocks.block_canopy_cover_big_blocks a
	left join diffusion_blocks.block_geoms_big b
	ON a.pgid = b.pgid
	INNER JOIN diffusion_data_wind.canopy_pct_100x100 c
	ON ST_Intersects(b.the_point_4326, c.rast)
	where a.canopy_pct is null
)
UPDATE diffusion_blocks.block_canopy_cover_big_blocks a
SET canopy_pct = b.canopy_pct
FROM b
WHERe a.pgid = b.pgid
and a.canopy_pct is null;
-- 87597 rows

-- check for nulls
select count(*)
FROM diffusion_blocks.block_canopy_cover_big_blocks
where canopy_pct is null;
-- 34003 nulls 

-- where are these
select distinct b.state_abbr
FROM diffusion_blocks.block_canopy_cover_big_blocks a
left join diffusion_blocks.block_geoms b
ON a.pgid = b.pgid
where a.canopy_pct is null
order by b.state_abbr;
-- AK, HI, and most border/coastal states


-- fix the remainders using nearest neighbor in the same county with good data
with a as
(
	select a.pgid, b.state_fips, b.county_fips, b.the_point_96703
	from diffusion_blocks.block_canopy_cover_big_blocks a
	left join diffusion_blocks.block_geoms b
	ON a.pgid = b.pgid
	where a.canopy_pct is null
),
b as
(
	select a.pgid, a.canopy_pct, b.state_fips, b.county_fips, b.the_point_96703
	from diffusion_blocks.block_canopy_cover_big_blocks a
	left join diffusion_blocks.block_geoms b
	ON a.pgid = b.pgid
	where a.canopy_pct is NOT null
),
c as
(
	select a.pgid, b.canopy_pct, 
		ST_Distance(a.the_point_96703, b.the_point_96703) as dist_m
	from a
	left join b
	ON a.state_fips = b.state_fips
	and a.county_fips = b.county_fips
),
d AS
(
	select distinct on (c.pgid) c.pgid, c.canopy_pct
	from c
	ORDER BY c.pgid ASC, c.dist_m asc
)
UPDATE diffusion_blocks.block_canopy_cover_big_blocks e
set canopy_pct = d.canopy_pct
from d
where e.pgid = d.pgid
AND e.canopy_pct is null;
-- 34003 rows

-- recheck for nulls
select count(*)
FROM diffusion_blocks.block_canopy_cover_big_blocks
where canopy_pct is null;
-- 27625

-- where are these
select distinct b.state_abbr
FROM diffusion_blocks.block_canopy_cover_big_blocks a
left join diffusion_blocks.block_geoms b
ON a.pgid = b.pgid
where a.canopy_pct is null;
-- all in AK and HI -- all set


--------------------------------------------------------------------------------------------------
-- combine the two tables

DROP TABLE IF EXISTS diffusion_blocks.block_canopy_cover;
CREATE TABLE diffusion_blocks.block_canopy_cover AS
SELECT *
from diffusion_blocks.block_canopy_cover_small_blocks
UNION ALL
select *
FROM diffusion_blocks.block_canopy_cover_big_blocks;
-- 10535171 rows

-- add primary key
ALTER TABLE diffusion_blocks.block_canopy_cover
ADD PRIMARY KEY (pgid);

-- drop the intermediate tables
DROP TABLE IF EXISTS diffusion_blocks.block_canopy_cover_small_blocks;
DROP TABLE IF EXISTS diffusion_blocks.block_canopy_cover_big_blocks;