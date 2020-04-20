select *
FROM diffusion_shared.county_geom
where county_id = 2961;

DROP VIEW IF EXISTS dg_wind.genesee_county_pt_grid_us_res;
CREATE VIEW dg_wind.genesee_county_pt_grid_us_res AS
with a as
(
	select x, y, the_geom_4326, county_id, utility_type, iiijjjicf_id, wind_incentive_array_id, 
	       solar_incentive_array_id, pca_reg, reeds_reg, solar_re_9809_gid, 
	       hdf_load_index, the_geom_96703, canopy_pct, canopy_ht_m, blkgrp_ownocc_sf_hu, 
	       hi_dev_pct, acres_per_hu, hu_portion, gid, ranked_rate_array_id, 
	       blkgrp_ownocc_sf_hu_portion, ST_Expand(the_geom_4326, 0.0009) as the_grid_4326,
	       CASE WHEN acres_per_hu < 0.5 then 0
		    when acres_per_hu >= 0.5 and acres_per_hu < 1 THEN 20
		    when acres_per_hu >= 1 and acres_per_hu < 2 THEN 30
		    when acres_per_hu >= 2 and acres_per_hu < 3 THEN 40
		    when acres_per_hu >= 3 and acres_per_hu < 4 THEN 50
		    when acres_per_hu >= 4 THEN 80
	       end as maxht_hu,
	       CASE WHEN canopy_pct >= 25 and canopy_ht_m >= 13 THEN 40
		    else 20
	       end as minht_can
	FROM diffusion_shared.pt_grid_us_res
	where county_id = 2961
)
select a.*,
       CASE WHEN maxht_hu = 0 or  minht_can > maxht_hu THEN 'X'
	    when minht_can = maxht_hu THEN maxht_hu::text
            else minht_can::Text || ' - ' || maxht_hu::TEXT
            end as ht_range
from a;

DROP TABLE IF EXISTS dg_wind.genesee_county_census_2010_block_geom;
CREATE TABLE dg_wind.genesee_county_census_2010_block_geom AS
SELECT a.*, b.housing_units, 
	CASE WHEN b.housing_units > 0 THEN (a.aland10/4046.86)::numeric/b.housing_units
				   else 100
				   end as acres_per_hu
FROM census_2010.block_geom_ny a
LEFT JOIN diffusion_wind_data.census_2010_block_housing_units b
ON a.gisjoin = b.gisjoin
where a.countyfp10 = '037';

