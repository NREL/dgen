set role 'diffusion-writers';

----------------------------------------------------------------------------------------
-- residential
DROP TABLE IF EXISTS diffusion_points.point_microdata_res_us CASCADE;
SET seed to 1;
CREATE TABLE diffusion_points.point_microdata_res_us AS
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
		ROUND(a.acres_per_bldg,2) as acres_per_bldg,
		a.canopy_ht_m,
		a.canopy_pct,
		-- solar only
		a.solar_incentive_array_id,
		a.solar_re_9809_gid,
		a.ulocale,
		-- res only		
		sum(a.blkgrp_ownocc_sf_hu_portion) as point_weight
	FROM diffusion_points.pt_grid_us_res a
	LEFT JOIN diffusion_wind.ij_cfbin_lookup_res_pts_us b 
		ON a.gid = b.pt_gid
	GROUP BY a.county_id,
		a.pca_reg,
		a.reeds_reg,
		a.wind_incentive_array_id,
		a.ranked_rate_array_id,
		a.hdf_load_index,
		a.utility_type,
		-- wind only
		b.i, b.j, b.cf_bin,
		ROUND(a.acres_per_bldg, 2),
		a.canopy_ht_m,
		a.canopy_pct,	
		-- solar only
		a.ulocale,
		a.solar_incentive_array_id,
		a.solar_re_9809_gid
)
SELECT (row_number() OVER (ORDER BY county_id, random()))::integer as micro_id, *
FROM a
ORDER BY county_id;
--use setseed() and order by random() as a secondary sort key to ensure order will be the same if we have to re run
-- 5389783 rows

-- primary key and indices
ALTER TABLE diffusion_points.point_microdata_res_us
ADD primary key (micro_id);

CREATE INDEX point_microdata_res_us_county_id_btree
  ON diffusion_points.point_microdata_res_us
  USING btree (county_id);

CREATE INDEX point_microdata_res_us_utility_type_btree
  ON diffusion_points.point_microdata_res_us
  USING btree (utility_type);

VACUUM ANALYZE diffusion_points.point_microdata_res_us;

----------------------------------------------------------------------------------------
-- commercial

DROP TABLE IF EXISTS diffusion_points.point_microdata_com_us CASCADE;
SET seed to 1;
CREATE TABLE diffusion_points.point_microdata_com_us AS
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
		ROUND(a.acres_per_bldg, 2) as acres_per_bldg,
		a.canopy_ht_m,
		a.canopy_pct,
		-- solar only
		a.ulocale,
		a.solar_incentive_array_id,
		a.solar_re_9809_gid,
		--
		count(*)::integer as point_weight
	FROM diffusion_points.pt_grid_us_com a
	LEFT JOIN diffusion_wind.ij_cfbin_lookup_com_pts_us b 
	ON a.gid = b.pt_gid
	GROUP BY a.county_id,
		a.pca_reg,
		a.reeds_reg,
		a.wind_incentive_array_id,
		a.ranked_rate_array_id,
		a.hdf_load_index,
		a.utility_type,
		-- wind only
		b.i, b.j, b.cf_bin,
		ROUND(a.acres_per_bldg, 2),
		a.canopy_ht_m,
		a.canopy_pct,
		-- solar only
		a.ulocale,
		a.solar_incentive_array_id,
		a.solar_re_9809_gid
)
SELECT (row_number() OVER (ORDER BY county_id, random()))::integer as micro_id, *
FROM a
ORDER BY county_id;
--use setseed() and order by random() as a secondary sort key to ensure order will be the same if we have to re run
-- 1406317  rows

-- primary key and indices
ALTER TABLE diffusion_points.point_microdata_com_us
ADD primary key (micro_id);

CREATE INDEX point_microdata_com_us_county_id_btree
  ON diffusion_points.point_microdata_com_us
  USING btree (county_id);

CREATE INDEX point_microdata_com_us_utility_type_btree
  ON diffusion_points.point_microdata_com_us
  USING btree (utility_type);

VACUUM ANALYZE diffusion_points.point_microdata_com_us;


----------------------------------------------------------------------------------------------------
-- industrial

DROP TABLE IF EXISTS diffusion_points.point_microdata_ind_us CASCADE;
SET seed to 1;
CREATE TABLE diffusion_points.point_microdata_ind_us AS
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
		ROUND(a.acres_per_bldg, 2) as acres_per_bldg,
		a.canopy_ht_m,
		a.canopy_pct,
		-- solar only
		a.ulocale,
		a.solar_incentive_array_id,
		a.solar_re_9809_gid,
		count(*)::integer as point_weight
	FROM diffusion_points.pt_grid_us_ind a
	LEFT JOIN diffusion_wind.ij_cfbin_lookup_ind_pts_us b 
	ON a.gid = b.pt_gid
	GROUP BY a.county_id,
		a.pca_reg,
		a.reeds_reg,
		a.wind_incentive_array_id,
		a.ranked_rate_array_id,
		a.hdf_load_index,
		a.utility_type,
		-- wind only
		b.i, b.j, b.cf_bin,
		ROUND(a.acres_per_bldg, 2),
		a.canopy_ht_m,
		a.canopy_pct,
		-- solar only
		a.ulocale,
		a.solar_incentive_array_id,
		a.solar_re_9809_gid
)
SELECT (row_number() OVER (ORDER BY county_id, random()))::integer as micro_id, *
FROM a
ORDER BY county_id;
--use setseed() and order by random() as a secondary sort key to ensure order will be the same if we have to re run
-- 1023649 rows

-- primary key and indices
ALTER TABLE diffusion_points.point_microdata_ind_us
ADD primary key (micro_id);

CREATE INDEX point_microdata_ind_us_county_id_btree
  ON diffusion_points.point_microdata_ind_us
  USING btree (county_id);

CREATE INDEX point_microdata_ind_us_utility_type_btree
  ON diffusion_points.point_microdata_ind_us
  USING btree (utility_type);

VACUUM ANALYZE diffusion_points.point_microdata_ind_us;
