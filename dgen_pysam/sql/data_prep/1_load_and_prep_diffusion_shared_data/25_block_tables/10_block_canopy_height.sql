set role 'diffusion-writers';

------------------------------------------------------------------------------------------
-- create table for small blocks
DROP TABLE IF EXISTS diffusion_blocks.block_canopy_height_small_blocks;
CREATE UNLOGGED TABLE diffusion_blocks.block_canopy_height_small_blocks 
(
	pgid bigint,
	canopy_ht_m integer
);

select parsel_2('dav-gis', 'mgleason', 'mgleason',
				'diffusion_blocks.block_geoms_small', 'pgid',
				'select a.pgid, ST_Value(b.rast, a.the_point_4326)/10. as canopy_ht_m
				FROM diffusion_blocks.block_geoms_small a
				LEFT JOIN diffusion_data_wind.canopy_height_100x100 b
				ON ST_Intersects(a.the_point_4326, b.rast)',
				'diffusion_blocks.block_canopy_height_small_blocks', 'a', 16
				);


------------------------------------------------------------------------------------------
-- create table for big blocks
DROP TABLE IF EXISTS diffusion_blocks.block_canopy_height_big_blocks;
CREATE UNLOGGED TABLE diffusion_blocks.block_canopy_height_big_blocks 
(
	pgid bigint,
	canopy_ht_m integer
);


select parsel_2('dav-gis', 'mgleason', 'mgleason',
				'diffusion_blocks.block_geoms_big', 'pgid',
				'with a as
				(
					SELECT a.pgid,
						   ST_SummaryStats(ST_Clip(b.rast, a.the_poly_4326)) as stats
					FROM diffusion_blocks.block_geoms_big a
					LEFT JOIN diffusion_data_wind.canopy_height_100x100 b
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
					CASE WHEN count > 0 THEN sum/count/10.
					ELSE NULL
					END as canopy_ht_m
				FROM c;',
				'diffusion_blocks.block_canopy_height_big_blocks', 'a', 16
				);


------------------------------------------------------------------------------------------
-- QA/QC -- small blocks
-- add primary key
ALTER TABLE diffusion_blocks.block_canopy_height_small_blocks
ADD PRIMARY KEY (pgid);

-- check row count
select count(*)
FROM diffusion_blocks.block_canopy_height_small_blocks;
-- 5968895

-- check for nulls
select count(*)
FROM diffusion_blocks.block_canopy_height_small_blocks
where canopy_ht_m is null;
-- 2084988 rows -- 2 million!

-- how many have null canopy ht but canopy pct > 0
select count(*)
FROM diffusion_blocks.block_canopy_height_small_blocks a
left join diffusion_blocks.block_canopy_cover b
ON a.pgid = b.pgid
where a.canopy_ht_m is null
and b.canopy_pct > 0;
-- 1113852
-- 1 million!

-- try to fix using polygons instead of pts
DROP TABLE IF EXISTS diffusion_blocks.block_canopy_height_small_blocks_polys;
CREATE TABLE diffusion_blocks.block_canopy_height_small_blocks_polys AS
with a as
(
	SELECT a.pgid,
		   ST_SummaryStats(ST_Clip(c.rast, b.the_poly_4326)) as stats
	FROM diffusion_blocks.block_canopy_height_small_blocks a
	LEFT JOIN diffusion_blocks.block_geoms_small b
	ON a.pgid = b.pgid
	INNER JOIN diffusion_data_wind.canopy_height_100x100 c
	ON ST_Intersects(b.the_poly_4326, c.rast)
	where a.canopy_ht_m is null
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
SELECT c.pgid, sum/count/10. as canopy_ht_m
FROM c
where count > 0;
-- this produces a table with z eros rows --- so it has no effect on fixing the problem

-- drop the temporary table
DROP TABLE IF EXISTS diffusion_blocks.block_canopy_height_small_blocks_polys;

-- fix remainders as follows:
-- where canopy_pct = 0, set to 0
-- where canopy_pct is null, set to null
-- where canopy_pct > 0, set to 5 m 
-- (This is the minimum height for tree canopy cover in the NLCD pct canopy cover raster
-- Remaining areas are those that likely had no trees in 2000 (vintage of canopy height raster),
-- so I am going to assume that they are small trees as of 2011)
with b as
(
	select a.pgid, b.canopy_pct
	FROM diffusion_blocks.block_canopy_height_small_blocks a
	left join diffusion_blocks.block_canopy_cover b
	ON a.pgid = b.pgid
	where a.canopy_ht_m is null
)
UPDATE diffusion_blocks.block_canopy_height_small_blocks a
SET canopy_ht_m = case when b.canopy_pct = 0 then 0
		       WHEN b.canopy_pct is null then null
		   else 5
		   end
from b
where a.pgid = b.pgid;
-- 2084988 rows

-- how many nulls left?
select count(*)
FROM diffusion_blocks.block_canopy_height_small_blocks
where canopy_ht_m is null;
-- 23016 nulls 

-- where are they?
select distinct b.state_abbr
FROM diffusion_blocks.block_canopy_height_small_blocks a
left join diffusion_blocks.block_geoms b
ON a.pgid = b.pgid
where a.canopy_ht_m is null
order by b.state_abbr;
-- AK and HI only -- all set

------------------------------------------------------------------------------------------
-- QA/QC -- big blocks
-- add primary key
ALTER TABLE diffusion_blocks.block_canopy_height_big_blocks
ADD PRIMARY KEY (pgid);

-- check row count
select count(*)
FROM diffusion_blocks.block_canopy_height_big_blocks;
-- 4566276

-- check for nulls
select count(*)
FROM diffusion_blocks.block_canopy_height_big_blocks
where canopy_ht_m is null;
-- 999308 nulls 

-- how many have null canopy ht but canopy pct > 0
select count(*)
FROM diffusion_blocks.block_canopy_height_big_blocks a
left join diffusion_blocks.block_canopy_cover b
ON a.pgid = b.pgid
where a.canopy_ht_m is null
and b.canopy_pct > 0;
-- 277452

-- fix as follows:
-- where canopy_pct = 0, set to 0
-- where canopy_pct is null, set to null
-- where canopy_pct > 0, set to 5 m 
-- (This is the minimum height for tree canopy cover in the NLCD pct canopy cover raster
-- Remaining areas are those that likely had no trees in 2000 (vintage of canopy height raster),
-- so I am going to assume that they are small trees as of 2011)
with b as
(
	select a.pgid, b.canopy_pct
	FROM diffusion_blocks.block_canopy_height_big_blocks a
	left join diffusion_blocks.block_canopy_cover b
	ON a.pgid = b.pgid
	where a.canopy_ht_m is null
)
UPDATE diffusion_blocks.block_canopy_height_big_blocks a
SET canopy_ht_m = case when b.canopy_pct = 0 then 0
		       WHEN b.canopy_pct is null then null
		   else 5
		   end
from b
where a.pgid = b.pgid;
-- 999308 rows

-- how many nulls left?
select count(*)
FROM diffusion_blocks.block_canopy_height_big_blocks
where canopy_ht_m is null;
-- 27625 nulls 

-- where are they?
select distinct b.state_abbr
FROM diffusion_blocks.block_canopy_height_big_blocks a
left join diffusion_blocks.block_geoms b
ON a.pgid = b.pgid
where a.canopy_ht_m is null
order by b.state_abbr;
-- AK and HI only -- all set


--------------------------------------------------------------------------------------------------
-- combine the two tables

DROP TABLE IF EXISTS diffusion_blocks.block_canopy_height;
CREATE TABLE diffusion_blocks.block_canopy_height AS
SELECT *
from diffusion_blocks.block_canopy_height_small_blocks
UNION ALL
select *
FROM diffusion_blocks.block_canopy_height_big_blocks;
-- 10535171 rows

-- add primary key
ALTER TABLE diffusion_blocks.block_canopy_height
ADD PRIMARY KEY (pgid);

-- drop the intermediate tables
DROP TABLE IF EXISTS diffusion_blocks.block_canopy_height_small_blocks;
DROP TABLE IF EXISTS diffusion_blocks.block_canopy_height_big_blocks;