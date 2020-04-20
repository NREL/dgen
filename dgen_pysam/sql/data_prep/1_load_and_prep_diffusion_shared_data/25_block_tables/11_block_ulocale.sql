set role 'diffusion-writers';

------------------------------------------------------------------------------------------
-- create table for small blocks
DROP TABLE IF EXISTS diffusion_blocks.block_ulocale_small_blocks;
CREATE UNLOGGED TABLE diffusion_blocks.block_ulocale_small_blocks 
(
	pgid bigint,
	ulocale integer
);

select parsel_2('dav-gis', 'mgleason', 'mgleason',
				'diffusion_blocks.block_geoms_small', 'pgid',
				'select a.pgid, 
				CASE WHEN b.ulocale IS NULL THEN -999::INTEGER -- change nulls to -999
				    WHEN b.ulocale = 0 THEN -999::INTEGER -- use -999 instead of zero for unknown
				    WHEN b.ulocale IN (43, 42) THEN 41::INTEGER -- lump rural into one code
				    WHEN b.ulocale in (33, 32) THEN 31::INTEGER -- lump town into one code
				    ELSE b.ulocale::INTEGER
				END as ulocale
				FROM diffusion_blocks.block_geoms_small a
				LEFT JOIN pv_rooftop.locale b
				ON ST_Intersects(a.the_point_96703, b.the_geom_96703)',
				'diffusion_blocks.block_ulocale_small_blocks', 'a', 16
				);


------------------------------------------------------------------------------------------
-- create table for big blocks
DROP TABLE IF EXISTS diffusion_blocks.block_ulocale_big_blocks;
CREATE UNLOGGED TABLE diffusion_blocks.block_ulocale_big_blocks 
(
	pgid bigint,
	ulocale integer
);


select parsel_2('dav-gis', 'mgleason', 'mgleason',
				'diffusion_blocks.block_geoms_big', 'pgid',
				'with a as
				(
					SELECT a.pgid, 
						CASE WHEN b.ulocale IS NULL THEN -999::INTEGER -- change nulls to -999
						    WHEN b.ulocale = 0 THEN -999::INTEGER -- use -999 instead of zero for unknown
						    WHEN b.ulocale IN (43, 42) THEN 41::INTEGER -- lump rural into one code
						    WHEN b.ulocale in (33, 32) THEN 31::INTEGER -- lump town into one code
						    ELSE b.ulocale::INTEGER
						END as ulocale,
						ST_Area(ST_Intersection(a.the_poly_96703, ST_Buffer(b.the_geom_96703,0))) as int_area
					FROM diffusion_blocks.block_geoms_big a
					LEFT JOIN pv_rooftop.locale b
					ON ST_Intersects(a.the_poly_96703, b.the_geom_96703)
				),
				b as
				(
					select pgid, ulocale, sum(int_area) as int_area
					from a
					group by pgid, ulocale
				)
				select distinct on (pgid) pgid, ulocale
				from b
				order by pgid asc, int_area desc;',
				'diffusion_blocks.block_ulocale_big_blocks', 'a', 16
				);


------------------------------------------------------------------------------------------
-- QA/QC -- small blocks
-- add primary key
ALTER TABLE diffusion_blocks.block_ulocale_small_blocks
ADD PRIMARY KEY (pgid);
-- failed because there are dupes

-- why are there dupes?
select *
FROM diffusion_blocks.block_ulocale_small_blocks
where pgid = 8239793;
-- in Q, there are actually multiple overlapping locale boundaries in this location

-- how many are there?
WITH a as
(
	select pgid, count(ulocale)
	FROM diffusion_blocks.block_ulocale_small_blocks
	GROUP BY pgid
)
select count(*)
from a
where count > 1;
-- there are only two cases

-- fix by randomly keeping one
WITH a as
(
	select pgid, count(ulocale)
	FROM diffusion_blocks.block_ulocale_small_blocks
	GROUP BY pgid
)
select *
from a
where count > 1;
-- 8239793
-- 8239935

select *
FROM diffusion_blocks.block_ulocale_small_blocks
where pgid in (8239793, 8239935);
-- both have values of 31 (town) and 41 (rural) -- keep town for both since it is likely to have more lidar data

delete from diffusion_blocks.block_ulocale_small_blocks
where pgid in (8239793, 8239935)
and ulocale = 41;
-- 2 rows deleted

-- now add  the primary key
ALTER TABLE diffusion_blocks.block_ulocale_small_blocks
ADD PRIMARY KEY (pgid);

-- check row count
select count(*)
FROM diffusion_blocks.block_ulocale_small_blocks;
-- 5968895

-- check for nulls
select count(*)
FROM diffusion_blocks.block_ulocale_small_blocks
where ulocale is null;
-- 0 NULLS! -- all set

------------------------------------------------------------------------------------------
-- QA/QC -- big blocks
-- add primary key
ALTER TABLE diffusion_blocks.block_ulocale_big_blocks
ADD PRIMARY KEY (pgid);

-- check row count
select count(*)
FROM diffusion_blocks.block_ulocale_big_blocks;
-- 4566276

-- check for nulls
select count(*)
FROM diffusion_blocks.block_ulocale_big_blocks
where ulocale is null;
-- 0 -- all set!


--------------------------------------------------------------------------------------------------
-- combine the two tables

DROP TABLE IF EXISTS diffusion_blocks.block_ulocale;
CREATE TABLE diffusion_blocks.block_ulocale AS
SELECT *
from diffusion_blocks.block_ulocale_small_blocks
UNION ALL
select *
FROM diffusion_blocks.block_ulocale_big_blocks;
-- 10535171 rows

-- add primary key
ALTER TABLE diffusion_blocks.block_ulocale
ADD PRIMARY KEY (pgid);

-- drop the intermediate tables
DROP TABLE IF EXISTS diffusion_blocks.block_ulocale_small_blocks;
DROP TABLE IF EXISTS diffusion_blocks.block_ulocale_big_blocks;