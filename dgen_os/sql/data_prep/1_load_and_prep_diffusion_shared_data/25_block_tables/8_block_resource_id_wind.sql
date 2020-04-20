set role 'diffusion-writers';

------------------------------------------------------------------------------------------
-- create table for small blocks
DROP TABLE IF EXISTS diffusion_blocks.block_resource_id_wind_small_blocks;
CREATE TABLE diffusion_blocks.block_resource_id_wind_small_blocks 
(
	pgid bigint,
	iiijjjicf_id integer
);

select parsel_2('dav-gis', 'mgleason', 'mgleason',
				'diffusion_blocks.block_geoms_small', 'pgid',
				'select a.pgid, ST_Value(b.rast, a.the_point_4326) as iiijjjicf_id
				FROM diffusion_blocks.block_geoms_small a
				LEFT JOIN aws_2014.iiijjjicf_200m_raster_100x100 b
				ON ST_Intersects(a.the_point_4326, b.rast)',
				'diffusion_blocks.block_resource_id_wind_small_blocks', 'a', 16
				);


------------------------------------------------------------------------------------------
-- create table for big blocks
DROP TABLE IF EXISTS diffusion_blocks.block_resource_id_wind_big_blocks;
CREATE TABLE diffusion_blocks.block_resource_id_wind_big_blocks 
(
	pgid bigint,
	iiijjjicf_id integer
);


select parsel_2('dav-gis', 'mgleason', 'mgleason',
				'diffusion_blocks.block_geoms_big', 'pgid',
				'with a as
				(
					SELECT a.pgid,
						   ST_ValueCount(ST_Clip(b.rast, a.the_poly_4326)) as vc
					FROM diffusion_blocks.block_geoms_big a
					LEFT JOIN aws_2014.iiijjjicf_200m_raster_100x100 b
					ON ST_Intersects(a.the_poly_4326, b.rast)
				),
				b as
				(
					select b.pgid, (a.vc).value, (a.vc).count
					from diffusion_blocks.block_geoms_big b
					LEFT JOIN a
					ON b.pgid = a.pgid
				),
				c as
				(
					select b.pgid, b.value, sum(b.count) as count
					from b
					group by b.pgid, b.value
				)
				select distinct ON (c.pgid) c.pgid, c.value as iiijjjicf_id
				FROM c
				ORDER BY c.pgid asc, c.count desc;',
				'diffusion_blocks.block_resource_id_wind_big_blocks', 'a', 16
				);


------------------------------------------------------------------------------------------
-- QA/QC -- small blocks
-- add primary key
ALTER TABLE diffusion_blocks.block_resource_id_wind_small_blocks
ADD PRIMARY KEY (pgid);

-- check row count
select count(*)
FROM diffusion_blocks.block_resource_id_wind_small_blocks;
-- 5968895

-- check for nulls
select count(*)
FROM diffusion_blocks.block_resource_id_wind_small_blocks
where iiijjjicf_id is null;
-- 23177 rows

-- where are these
select a.*, b.state_abbr
FROM diffusion_blocks.block_resource_id_wind_small_blocks a
left join diffusion_blocks.block_geoms b
ON a.pgid = b.pgid
where a.iiijjjicf_id is null
order by b.state_abbr;
-- several states on the boundaries (WA, TX, ND, etc.)
-- plus AK and HI, which won't have results

-- fix using nearest neighbor in the same county with good data
with a as
(
	select a.pgid, b.state_fips, b.county_fips, b.the_point_96703
	from diffusion_blocks.block_resource_id_wind_small_blocks a
	left join diffusion_blocks.block_geoms b
	ON a.pgid = b.pgid
	where a.iiijjjicf_id is null
),
b as
(
	select a.pgid, a.iiijjjicf_id, b.state_fips, b.county_fips, b.the_point_96703
	from diffusion_blocks.block_resource_id_wind_small_blocks a
	left join diffusion_blocks.block_geoms b
	ON a.pgid = b.pgid
	where a.iiijjjicf_id is NOT null
),
c as
(
	select a.pgid, b.iiijjjicf_id, 
		ST_Distance(a.the_point_96703, b.the_point_96703) as dist_m
	from a
	left join b
	ON a.state_fips = b.state_fips
	and a.county_fips = b.county_fips
),
d AS
(
	select distinct on (c.pgid) c.pgid, c.iiijjjicf_id
	from c
	ORDER BY c.pgid ASC, c.dist_m asc
)
UPDATE diffusion_blocks.block_resource_id_wind_small_blocks e
set iiijjjicf_id = d.iiijjjicf_id
from d
where e.pgid = d.pgid
AND e.iiijjjicf_id is null;
-- 11430 rows

-- recheck for nulls
select count(*)
FROM diffusion_blocks.block_resource_id_wind_small_blocks
where iiijjjicf_id is null;
--23016

-- where are these
select distinct b.state_abbr
FROM diffusion_blocks.block_resource_id_wind_small_blocks a
left join diffusion_blocks.block_geoms b
ON a.pgid = b.pgid
where a.iiijjjicf_id is null;
-- all in AK and HI -- all set

------------------------------------------------------------------------------------------
-- QA/QC -- big blocks
-- add primary key
ALTER TABLE diffusion_blocks.block_resource_id_wind_big_blocks
ADD PRIMARY KEY (pgid);

-- check row count
select count(*)
FROM diffusion_blocks.block_resource_id_wind_big_blocks;
-- 4566276

-- check for nulls
select count(*)
FROM diffusion_blocks.block_resource_id_wind_big_blocks
where iiijjjicf_id is null;
-- 108915 nulls 

-- where are these
select distinct b.state_abbr
FROM diffusion_blocks.block_resource_id_wind_big_blocks a
left join diffusion_blocks.block_geoms b
ON a.pgid = b.pgid
where a.iiijjjicf_id is null
order by b.state_abbr;
-- several states  --- what's going on here?
-- create a view to look at in Q

DROP TABLE IF EXISTS diffusion_blocks.block_resource_id_wind_big_blocks_no_resource;
CREATE TABLE diffusion_blocks.block_resource_id_wind_big_blocks_no_resource AS
select b.*
FROM diffusion_blocks.block_resource_id_wind_big_blocks a
left join diffusion_blocks.block_geoms b
ON a.pgid = b.pgid
where a.iiijjjicf_id is null;
-- 108915 rows
-- a lot of these are sliver polygons -- prob no housing units, but can be fixed using centroid overlay

-- drop the temp geom table
DROP TABLE IF EXISTS diffusion_blocks.block_resource_id_wind_big_blocks_no_resource;

-- using centroid overlay to fix the problematic points
WITH b as
(
	select a.pgid, ST_Value(c.rast, b.the_point_4326) as iiijjjicf_id
	FROM diffusion_blocks.block_resource_id_wind_big_blocks a
	left join diffusion_blocks.block_geoms_big b
	ON a.pgid = b.pgid
	INNER JOIN aws_2014.iiijjjicf_200m_raster_100x100 c
	ON ST_Intersects(b.the_point_4326, c.rast)
	where a.iiijjjicf_id is null
)
UPDATE diffusion_blocks.block_resource_id_wind_big_blocks a
SET iiijjjicf_id = b.iiijjjicf_id
FROM b
WHERe a.pgid = b.pgid
and a.iiijjjicf_id is null;
-- 81290 rows

-- check for nulls
select count(*)
FROM diffusion_blocks.block_resource_id_wind_big_blocks
where iiijjjicf_id is null;
-- 27644 nulls 

-- where are these
select distinct b.state_abbr
FROM diffusion_blocks.block_resource_id_wind_big_blocks a
left join diffusion_blocks.block_geoms b
ON a.pgid = b.pgid
where a.iiijjjicf_id is null
order by b.state_abbr;
-- AK, HI, and border states


-- fix the remainders using nearest neighbor in the same county with good data
with a as
(
	select a.pgid, b.state_fips, b.county_fips, b.the_point_96703
	from diffusion_blocks.block_resource_id_wind_big_blocks a
	left join diffusion_blocks.block_geoms b
	ON a.pgid = b.pgid
	where a.iiijjjicf_id is null
),
b as
(
	select a.pgid, a.iiijjjicf_id, b.state_fips, b.county_fips, b.the_point_96703
	from diffusion_blocks.block_resource_id_wind_big_blocks a
	left join diffusion_blocks.block_geoms b
	ON a.pgid = b.pgid
	where a.iiijjjicf_id is NOT null
),
c as
(
	select a.pgid, b.iiijjjicf_id, 
		ST_Distance(a.the_point_96703, b.the_point_96703) as dist_m
	from a
	left join b
	ON a.state_fips = b.state_fips
	and a.county_fips = b.county_fips
),
d AS
(
	select distinct on (c.pgid) c.pgid, c.iiijjjicf_id
	from c
	ORDER BY c.pgid ASC, c.dist_m asc
)
UPDATE diffusion_blocks.block_resource_id_wind_big_blocks e
set iiijjjicf_id = d.iiijjjicf_id
from d
where e.pgid = d.pgid
AND e.iiijjjicf_id is null;
-- 27644 rows

-- recheck for nulls
select count(*)
FROM diffusion_blocks.block_resource_id_wind_big_blocks
where iiijjjicf_id is null;
-- 27625

-- where are these
select distinct b.state_abbr
FROM diffusion_blocks.block_resource_id_wind_big_blocks a
left join diffusion_blocks.block_geoms b
ON a.pgid = b.pgid
where a.iiijjjicf_id is null;
-- all in AK and HI -- all set


--------------------------------------------------------------------------------------------------
-- combine the two tables

DROP TABLE IF EXISTS diffusion_blocks.block_resource_id_wind;
CREATE TABLE diffusion_blocks.block_resource_id_wind AS
SELECT *
from diffusion_blocks.block_resource_id_wind_small_blocks
UNION ALL
select *
FROM diffusion_blocks.block_resource_id_wind_big_blocks;
-- 10535171 rows

-- add primary key
ALTER TABLE diffusion_blocks.block_resource_id_wind
ADD PRIMARY KEY (pgid);

-- drop the intermediate tables
DROP TABLE IF EXISTS diffusion_blocks.block_resource_id_wind_small_blocks;
DROP TABLE IF EXISTS diffusion_blocks.block_resource_id_wind_big_blocks;