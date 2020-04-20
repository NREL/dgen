set role 'diffusion-writers';



------------------------------------------------------------------------------------------------------
-- COM
------------------------------------------------------------------------------------------------------
-- add columns to table
ALTER TABLE diffusion_shared.pt_grid_us_com
ADD COLUMN acres_per_bldg numeric,
ADD COLUMN bldg_type_probs integer[];


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
		a.aland10/4046.86 as aland_acres,
		array
		[
			b.com1i::INTEGER, b.com2i::INTEGER, b.com3i::INTEGER, b.com4i::INTEGER, b.com5i::INTEGER, 
			b.com6i::INTEGER, b.com7i::INTEGER, b.com8i::INTEGER, b.com9i::INTEGER, b.com10i::INTEGER, 
			b.edu1i::INTEGER, b.edu2i::INTEGER,
			b.gov1i::INTEGER, b.gov2i::INTEGER, 
			b.rel1i::INTEGER, 
			b.res4i::INTEGER, b.res5i::INTEGER, b.res6i::INTEGER
		] as bldg_type_probs
	from diffusion_data_wind.pt_grid_us_com_new_census_2010_block_lkup a
	LEFT JOIN hazus.hzbldgcountoccupb b
	ON a.block_gisjoin = b.census_2010_gisjoin
	where b.has_bldgs = True
)
UPDATE diffusion_shared.pt_grid_us_com a
set (acres_per_bldg, bldg_type_probs) = 
    (CASE 
	WHEN b.bldg_count > 0 THEN b.aland_acres/b.bldg_count
	ELSE 1000 
     END,
     b.bldg_type_probs
    )
FROM b
where a.gid = b.gid;
-- 1498830 rows updated

-- add a comment on the column defining the order of the fuel types
COMMENT ON COLUMN diffusion_shared.pt_grid_us_com.bldg_type_probs IS
'Bldg Types are (in order): com1, com2, com3, com4, com5, com6, com7, com8, com9, com10, edu1, edu2, gov1, gov2, rel1, res4, res5, res6';

------------------------------------------------------------------------------------
-- QA/QC for acres_per_bldg
select count(*)
FROM diffusion_shared.pt_grid_us_com;
--1603958 -- row counts do not match those updated

-- check for zeros
select count(*)
from diffusion_shared.pt_grid_us_com
where acres_per_bldg = 0;
-- 0  -- good

-- check for values = 1000
select count(*)
from diffusion_shared.pt_grid_us_com
where acres_per_bldg = 1000;
-- 0 -- perfect, no blocks that had zero buildings... except for the nulls below...

-- check for nulls
select count(*)
from diffusion_shared.pt_grid_us_com
where acres_per_bldg is null;
-- 105128

-- what to do with these?
DROP TABLE IF EXISTS diffusion_data_shared.pt_grid_us_com_no_cdms_bldgs;
CREATE TABLE diffusion_data_shared.pt_grid_us_com_no_cdms_bldgs AS
select a.*
FROM diffusion_shared.pt_grid_us_com a
where acres_per_bldg is null;
-- 105128 rows

-- inspected the in Q -- they actually seem reasonably correct as non-commercial
-- some have bldgs, but they are res; others have no development at all

-- delete them
DELeTE FROM diffusion_shared.pt_grid_us_com a
where acres_per_bldg is null;
-- 105128 rows deleted

-- map it for a couple counties?
DROP TABLE IF EXISTS diffusion_data_shared.pt_grid_us_com_boulder_county_extract;
CREATE TABLE diffusion_data_shared.pt_grid_us_com_boulder_county_extract AS
select *
FROM diffusion_shared.pt_grid_us_com
where county_id = 549;
-- 1420 rows
-- in areas where there is primarily commercial activity
-- this DEFINITELY improves the previous estimates that used acres per hu --
-- many areas just had the default size of 100 acres per HU -- now they are refined lower,
-- and much lower in some cases -- e.g., from 100 to <2 or 3



-- for conservative purposes, add a column that is the smaller of acres_per_hu and acres_per_building 
ALTER TABLE diffusion_shared.pt_grid_us_com
ADD COLUMN acres_per_hu_or_bldg numeric;

-- (ignore cases where acres_per_hu = 100, since these were just backfilled values for where no hu exist)
UPDATE diffusion_shared.pt_grid_us_com
SET acres_per_hu_or_bldg = CASE WHEN acres_per_hu = 100 THEN acres_per_bldg
			   ELSE r_min(array[acres_per_hu, acres_per_bldg])
			   END;
-- 1498830 rows updated

-- make sure no nulls
select count(*)
FROM diffusion_shared.pt_grid_us_com
where acres_per_hu_or_bldg is null;
-- 0 -- all set

-- make sure no 100s
select count(*)
FROM diffusion_shared.pt_grid_us_com
where acres_per_hu_or_bldg = 100;
-- 0 -- all set

-- how many have values that are smaller because of the bldgs?
select count(*)
FROM diffusion_shared.pt_grid_us_com
where acres_per_hu_or_bldg < acres_per_hu;
-- 875,715 -- this is slightly more than 1/2, which seems reasonable

------------------------------------------------------------------------------------
-- QA/QC for bldg type array
-- check for empty array or array of all zero

-- check for nulls
select count(*)
FROM diffusion_shared.pt_grid_us_com
where bldg_type_probs is null
or bldg_type_probs = array[]::INTEGER[];
-- 0 -- good

-- check for pts with sum of all probs = 0
select count(*)
FROM diffusion_shared.pt_grid_us_com
where r_array_sum(bldg_type_probs) = 0;
-- 287,571

-- archive these
DROP TABLE IF EXISTS diffusion_data_shared.pt_grid_us_com_no_bldg_types;
CREATE TABLE diffusion_data_shared.pt_grid_us_com_no_bldg_types AS
SELECT *
FROM diffusion_shared.pt_grid_us_com
where r_array_sum(bldg_type_probs) = 0;
-- 287571 rows
-- look at these in Q

-- alot of these do look like they are isolated pts in residential areas, so i guess it is reasonable to delte them
-- even though there are so many

-- delete
DELETE FROM diffusion_shared.pt_grid_us_com
where r_array_sum(bldg_type_probs) = 0;
-- 287571 points deleted

-- upon further consideration, these should not be deleted at this point in time 
-- (if they are removed, some counties will have no commercial points)
-- (also, to avoid this problem, we are switching to use the hazus data directly instead of pt grids)
-- re-add them to the main table for legacy purposes
INSERT INTO diffusion_shared.pt_grid_us_com
select *
FROM diffusion_data_shared.pt_grid_us_com_no_bldg_types;
-- 287571 points re-added

------------------------------------------------------------------------------------------------
-- create a table that defines the order of all commercial bldg types
DROP TABLE IF EXISTS diffusion_shared.cdms_bldg_type_array_com;
CREATE TABLE diffusion_shared.cdms_bldg_type_array_com
(
	bldg_type_array text[]
);

INSERT INTO diffusion_shared.cdms_bldg_type_array_com
select array
[
	'com1', 
	'com2', 
	'com3', 
	'com4', 
	'com5', 
	'com6', 
	'com7', 
	'com8', 
	'com9', 
	'com10', 
	'edu1', 
	'edu2', 
	'gov1', 
	'gov2', 
	'rel1', 
	'res4', 
	'res5', 
	'res6'
];
-- note: the formatting matches the distinct space_heat_fuel values in diffusion_shared.eia_microdata_recs_2009_expanded_bldgs


select *
FROM diffusion_shared.cdms_bldg_type_array_com;
-- looks good!
