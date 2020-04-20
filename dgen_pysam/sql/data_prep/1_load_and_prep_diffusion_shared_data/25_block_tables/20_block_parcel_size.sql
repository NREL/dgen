SET ROLE 'diffusion-writers';

------------------------------------------------------------------------------------------
DROP TABLE IF EXISTS diffusion_blocks.block_parcel_size;
CREATE TABLE  diffusion_blocks.block_parcel_size 
(
	pgid bigint,
	acres_per_bldg numeric,
	acres_per_hu NUMERIC,
	acres_per_hu_or_bldg numeric
);

select parsel_2('dav-gis', 'mgleason', 'mgleason',
		'diffusion_blocks.block_geoms', 'pgid',
		'with a as
		(
			SELECT a.pgid, 
				CASE WHEN b.bldg_count_all > 0 THEN a.aland_sqm/4046.86/b.bldg_count_all 
				ELSE 1000
				END as acres_per_bldg,
				CASE WHEN c.housing_units > 0 THEN a.aland_sqm/4046.86/c.housing_units 
				ELSE 1000
				END as acres_per_hu
			FROM diffusion_blocks.block_geoms a
			LEFT JOIN diffusion_blocks.block_bldg_counts b
			ON a.pgid = b.pgid
			LEFT JOIN diffusion_blocks.block_housing_units c
			ON a.pgid = c.pgid
		)
		select pgid, acres_per_bldg, acres_per_hu,
			case when acres_per_bldg < acres_per_hu then acres_per_bldg
			when acres_per_hu < acres_per_bldg then acres_per_hu
			WHEN acres_per_hu = acres_per_bldg then acres_per_hu
			ELSE NULL
			END as acres_per_hu_or_bldg
		from a',
		'diffusion_blocks.block_parcel_size', 'a', 16
);


------------------------------------------------------------------------------------------
-- QAQC

-- add primary key
ALTER TABLE diffusion_blocks.block_parcel_size
ADD PRIMARY KEY (pgid);

-- check count
select count(*)
FROM diffusion_blocks.block_parcel_size;
-- 10535171

-- check nulls
select count(*)
FROM diffusion_blocks.block_parcel_size
where acres_per_bldg is null;
-- 0

select count(*)
FROM diffusion_blocks.block_parcel_size
where acres_per_hu is null;
-- 0

select count(*)
FROM diffusion_blocks.block_parcel_size
WHERE acres_per_hu_or_bldg is null;
-- 0 nulls

-- check for values of 1000 (meaning, no bldgs/hu)
select count(*)
FROM diffusion_blocks.block_parcel_size
where acres_per_bldg = 1000;
-- 3712225

select count(*)
FROM diffusion_blocks.block_parcel_size
where acres_per_hu = 1000;
-- 4155208

select count(*)
FROM diffusion_blocks.block_parcel_size
where acres_per_hu_or_bldg = 1000;
-- 3627751 -- these are grid cells where buildings and HU don't exist ,so it's not a problem taht they are 1000s



