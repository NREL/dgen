set role 'diffusion-writers';

----------------------------------------------------------------------------------------
-- RESIDENTIAL

SELECT count(*)
FROM diffusion_shared.point_microdata_res_us a
LEFT JOIN diffusion_shared.county_geom b
ON a.county_id = b.county_id
WHERE b.state_abbr = 'ME';
-- 33801 rows to delete

DELETE FROM diffusion_shared.point_microdata_res_us a
USING diffusion_shared.county_geom b
WHERE a.county_id = b.county_id
AND b.state_abbr = 'ME';
-- 33801 rows deleted

-- create a new sequence to handle the micro_id
-- what is the current max id?
select max(micro_id)
FROM diffusion_shared.point_microdata_res_us;
-- 4635493

DROP SEQUENCE IF EXISTS diffusion_shared.point_microdata_res_us_micro_id_seq;
CREATE SEQUENCE diffusion_shared.point_microdata_res_us_micro_id_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 4635494
  CACHE 1;

-- add in the new microdata (based on the updated rates)
INSERT INTO diffusion_shared.point_microdata_res_us
WITH a AS
(
	SELECT a.county_id, 
		'p'::text || a.pca_reg::text AS pca_reg, 
		a.reeds_reg, 
		a.ranked_rate_array_id, 
		a.hdf_load_index,
		a.utility_type, 
		-- wind only
		a.wind_incentive_array_id,
		b.i, b.j, b.cf_bin, 
		a.hi_dev_pct,
		ROUND(a.acres_per_hu,2) as acres_per_hu,
		a.canopy_ht_m,
		a.canopy_pct >= 25 as canopy_pct_hi,
		-- solar only
		a.solar_incentive_array_id,
		a.solar_re_9809_gid,
		a.ulocale,
		-- res only		
		sum(a.blkgrp_ownocc_sf_hu_portion) as point_weight
	FROM diffusion_shared.pt_grid_us_res a
	LEFT JOIN diffusion_shared.county_geom c
		ON a.county_id = c.county_id
	LEFT JOIN diffusion_wind.ij_cfbin_lookup_res_pts_us b 
		ON a.gid = b.pt_gid
	where c.state_abbr = 'ME'
	GROUP BY a.county_id,
		a.pca_reg,
		a.reeds_reg,
		a.wind_incentive_array_id,
		a.ranked_rate_array_id,
		a.hdf_load_index,
		a.utility_type,
		-- wind only
		b.i, b.j, b.cf_bin,
		a.hi_dev_pct,
		ROUND(a.acres_per_hu,2),
		a.canopy_ht_m,
		a.canopy_pct >= 25,	
		-- solar only
		a.ulocale,
		a.solar_incentive_array_id,
		a.solar_re_9809_gid
)
SELECT nextval('diffusion_shared.point_microdata_res_us_micro_id_seq') as micro_id, *
FROM a
ORDER BY county_id;
-- 33753 rows addded (matches the original row count closely but not perfectly, as expected)

VACUUM ANALYZE diffusion_shared.point_microdata_res_us;

----------------------------------------------------------------------------------------
-- COMMERCIAL

SELECT count(*)
FROM diffusion_shared.point_microdata_com_us a
LEFT JOIN diffusion_shared.county_geom b
ON a.county_id = b.county_id
WHERE b.state_abbr = 'ME';
-- 10066 rows to delete

DELETE FROM diffusion_shared.point_microdata_com_us a
USING diffusion_shared.county_geom b
WHERE a.county_id = b.county_id
AND b.state_abbr = 'ME';
-- 10066 rows deleted

-- create a new sequence to handle the micro_id
-- what is the current max id?
select max(micro_id)
FROM diffusion_shared.point_microdata_com_us;
-- 1400715

DROP SEQUENCE IF EXISTS diffusion_shared.point_microdata_com_us_micro_id_seq;
CREATE SEQUENCE diffusion_shared.point_microdata_com_us_micro_id_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1400716
  CACHE 1;

-- add in the new microdata (based on the updated rates)
INSERT INTO diffusion_shared.point_microdata_com_us
WITH a AS
(
	SELECT a.county_id, 
		'p'::text || a.pca_reg::text AS pca_reg, 
		a.reeds_reg, 
		a.ranked_rate_array_id, 
		a.hdf_load_index,
		a.utility_type, 
		-- wind only
		a.wind_incentive_array_id,
		b.i, b.j, b.cf_bin, 
		a.hi_dev_pct,
		ROUND(a.acres_per_hu, 2) as acres_per_hu,
		a.canopy_ht_m,
		a.canopy_pct >= 25 as canopy_pct_hi,
		-- solar only
		a.ulocale,
		a.solar_incentive_array_id,
		a.solar_re_9809_gid,
		--
		count(*)::integer as point_weight
	FROM diffusion_shared.pt_grid_us_com a
	LEFT JOIN diffusion_shared.county_geom c
		ON a.county_id = c.county_id
	LEFT JOIN diffusion_wind.ij_cfbin_lookup_com_pts_us b 
		ON a.gid = b.pt_gid
	where c.state_abbr = 'ME'
	GROUP BY a.county_id,
		a.pca_reg,
		a.reeds_reg,
		a.wind_incentive_array_id,
		a.ranked_rate_array_id,
		a.hdf_load_index,
		a.utility_type,
		-- wind only
		b.i, b.j, b.cf_bin,
		a.hi_dev_pct,
		ROUND(a.acres_per_hu, 2),
		a.canopy_ht_m,
		a.canopy_pct >= 25,
		-- solar only
		a.ulocale,
		a.solar_incentive_array_id,
		a.solar_re_9809_gid
)
SELECT nextval('diffusion_shared.point_microdata_com_us_micro_id_seq') as micro_id, *
FROM a
ORDER BY county_id;
-- row count matches exactly, which is a bit suspicious...
-- I double checked that pt_grid_us_com has the updated ranked_rate_array_ids, so i guess we are all set

VACUUM ANALYZE diffusion_shared.point_microdata_com_us;


----------------------------------------------------------------------------------------------------
-- industrial

SELECT count(*)
FROM diffusion_shared.point_microdata_ind_us a
LEFT JOIN diffusion_shared.county_geom b
ON a.county_id = b.county_id
WHERE b.state_abbr = 'ME';
-- 5739 rows to delete

DELETE FROM diffusion_shared.point_microdata_ind_us a
USING diffusion_shared.county_geom b
WHERE a.county_id = b.county_id
AND b.state_abbr = 'ME';
-- 5739 rows deleted

-- create a new sequence to handle the micro_id
-- what is the current max id?
select max(micro_id)
FROM diffusion_shared.point_microdata_ind_us;
-- 1034230

DROP SEQUENCE IF EXISTS diffusion_shared.point_microdata_ind_us_micro_id_seq;
CREATE SEQUENCE diffusion_shared.point_microdata_ind_us_micro_id_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1034231
  CACHE 1;

-- add in the new microdata (based on the updated rates)
INSERT INTO diffusion_shared.point_microdata_ind_us
WITH a AS
(
	SELECT a.county_id, 
		'p'::text || a.pca_reg::text AS pca_reg, 
		a.reeds_reg, 
		a.wind_incentive_array_id,
		a.ranked_rate_array_id, 
		a.hdf_load_index,
		a.utility_type, 
		-- wind only
		b.i, b.j, b.cf_bin, 
		a.hi_dev_pct,
		ROUND(a.acres_per_hu, 2) as acres_per_hu,
		a.canopy_ht_m,
		a.canopy_pct >= 25 as canopy_pct_hi,
		-- solar only
		a.ulocale,
		a.solar_incentive_array_id,
		a.solar_re_9809_gid,
		count(*)::integer as point_weight
	FROM diffusion_shared.pt_grid_us_ind a
	LEFT JOIN diffusion_wind.ij_cfbin_lookup_ind_pts_us b 
	ON a.gid = b.pt_gid
	LEFT JOIN diffusion_shared.county_geom c
	ON a.county_id = c.county_id
	where c.state_abbr = 'ME'
	GROUP BY a.county_id,
		a.pca_reg,
		a.reeds_reg,
		a.wind_incentive_array_id,
		a.ranked_rate_array_id,
		a.hdf_load_index,
		a.utility_type,
		-- wind only
		b.i, b.j, b.cf_bin,
		a.hi_dev_pct,
		ROUND(a.acres_per_hu, 2),
		a.canopy_ht_m,
		a.canopy_pct >= 25,
		-- solar only
		a.ulocale,
		a.solar_incentive_array_id,
		a.solar_re_9809_gid
)
SELECT nextval('diffusion_shared.point_microdata_ind_us_micro_id_seq') as micro_id, *
FROM a
ORDER BY county_id;
-- 5739 -- also matches old count perfectly -- this must because the variable is not driven by rates but the other combination
-- of factors instead

VACUUM ANALYZE diffusion_shared.point_microdata_ind_us;
