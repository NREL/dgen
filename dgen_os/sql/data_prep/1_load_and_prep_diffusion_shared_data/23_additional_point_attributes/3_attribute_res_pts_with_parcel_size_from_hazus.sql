set role 'diffusion-writers';

------------------------------------------------------------------------------------------------------
-- check that previously created block lookup tables fully capture all pts in the pt grid tables
select count(*)
from diffusion_shared.pt_grid_us_res a
LEFT JOIN diffusion_data_wind.pt_grid_us_res_new_census_2010_block_lkup b
ON a.gid = b.gid
where b.gid is null;
-- 0 missing - all set

select count(*)
from diffusion_shared.pt_grid_us_com a
LEFT JOIN diffusion_data_wind.pt_grid_us_com_new_census_2010_block_lkup b
ON a.gid = b.gid
where b.gid is null;
-- 0 missing - all set

select count(*)
from diffusion_shared.pt_grid_us_ind a
LEFT JOIN diffusion_data_wind.pt_grid_us_ind_new_census_2010_block_lkup b
ON a.gid = b.gid
where b.gid is null;
-- 0 missing - all set

-- all are complete!
------------------------------------------------------------------------------------------------------


------------------------------------------------------------------------------------------------------
-- RES
------------------------------------------------------------------------------------------------------
-- add new column to table
ALTER TABLE diffusion_shared.pt_grid_us_res
ADD COLUMN acres_per_bldg numeric;

WITH b as
(
	select a.gid, 
		(b.res1i + b.res2i + b.res3ai + b.res3bi + b.res3ci + b.res3di + b.res3ei + b.res3fi + b.res4i + b.res5i + b.res6i + 
		b.com1i + b.com2i + b.com3i + b.com4i + b.com5i + b.com6i + b.com7i + b.com8i + b.com9i + b.com10i + 
		b.ind1i + b.ind2i + b.ind3i + b.ind4i + b.ind5i + b.ind6i + 
		b.agr1i + 
		b.rel1i + 
		b.gov1i + b.gov2i + 
		b.edu1i + b.edu2i) as bldg_count, 
		a.aland10/4046.86 as aland_acres
	from diffusion_data_wind.pt_grid_us_res_new_census_2010_block_lkup a
	LEFT JOIN hazus.hzbldgcountoccupb b
	ON a.block_gisjoin = b.census_2010_gisjoin
	where b.has_bldgs = True
)
UPDATE diffusion_shared.pt_grid_us_res a
set acres_per_bldg = CASE 
			WHEN b.bldg_count > 0 THEN b.aland_acres/b.bldg_count
			ELSE 1000 
		      END
FROM b
where a.gid = b.gid;
-- 5738717 rows updated

select count(*)
FROM diffusion_shared.pt_grid_us_res;
-- 5751535 -- row counts do not match

-- check for zeros
select count(*)
from diffusion_shared.pt_grid_us_res
where acres_per_bldg = 0;
-- 0 -- good

-- check for values = 1000
select count(*)
from diffusion_shared.pt_grid_us_res
where acres_per_bldg = 1000;
-- 0 -- perfect, no blocks that had zero buildings... except for the nulls below...

-- check for nulls
select count(*)
from diffusion_shared.pt_grid_us_res
where acres_per_bldg is null;
-- 12818

DROP TABLE IF EXISTS diffusion_data_shared.pt_grid_us_res_no_cdms_bldgs;
CREATE TABLE diffusion_data_shared.pt_grid_us_res_no_cdms_bldgs AS
select a.*, b.housing_units
FROM diffusion_shared.pt_grid_us_res a
LEFT JOIN diffusion_data_wind.pt_grid_us_res_new_census_2010_block_lkup b
ON a.gid = b.gid
where acres_per_bldg is null;
-- 12818 rows

-- what is the most housing_units in this table?
select max(housing_units), avg(housing_units), min(housing_units)
FROM diffusion_data_shared.pt_grid_us_res_no_cdms_bldgs;
-- 79, 1.11, 1
-- so, these are mostly very sparsely populated

-- how many above 5 HU?
select count(*)
FROM diffusion_data_shared.pt_grid_us_res_no_cdms_bldgs
where housing_units > 5; -- 67

-- how many above 10?
-- how many above 5 HU?
select count(*)
FROM diffusion_data_shared.pt_grid_us_res_no_cdms_bldgs
where housing_units > 10; -- 24

-- given how infrequently these have large numbers of HU,
-- it seems reasonable to just backfill these with the acres_per_hu

UPDATE diffusion_shared.pt_grid_us_res
set acres_per_bldg = acres_per_hu
WHERE acres_per_bldg is null;
-- 12818 rows fixed

-- recheck for nulls
select count(*)
from diffusion_shared.pt_grid_us_res
where acres_per_bldg is null;
-- 0 -- all set

-- map it for a couple counties?
DROP TABLE IF EXISTS diffusion_data_shared.pt_us_res_grid_boulder_county_extract;
CREATE TABLE diffusion_data_shared.pt_us_res_grid_boulder_county_extract AS
select *
FROM diffusion_shared.pt_grid_us_res
where county_id = 549;
-- 5397 rows

-- for conservative purposes, add a column that is the smaller of acres_per_hu and acres_per_building
ALTER TABLE diffusion_shared.pt_grid_us_res
ADD COLUMN acres_per_hu_or_bldg numeric;

UPDATE diffusion_shared.pt_grid_us_res
SET acres_per_hu_or_bldg = r_min(array[acres_per_hu, acres_per_bldg]);

-- make sure no nulls
select count(*)
FROM diffusion_shared.pt_grid_us_res
where acres_per_hu_or_bldg is null;
-- 0 -- all set