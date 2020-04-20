
------------------------------------------------------------------------------------------------------------

-- calculate distances
-- use centroid geographies as the best trade off of speed + accuracy
DROP TABLE IF EXISTS diffusion_data_shared.block_block_county_to_lidar_city_distances_lkup;
CREATE TABLE diffusion_data_shared.block_county_to_lidar_city_distances_lkup AS
SELECT a.county_id, b.city_id, b.city, b.state, b.year, b.basename,
	ST_Distance(a.the_geog_pos_500k, b.rasd_the_point_on_surface_geog) as dist_m
FROM diffusion_blocks.county_geoms a
LEFT JOIN pv_rooftop_dsolar_integration.solar_gid b
	ON a.census_region = b.census_region;
-- 148608 rows

		
-- create indices
CREATE INDEX block_county_to_lidar_city_distances_lkup_county_id_btree
ON diffusion_data_shared.block_county_to_lidar_city_distances_lkup
USING BTREE(county_id);

CREATE INDEX block_county_to_lidar_city_distances_lkup_year_btree
ON diffusion_data_shared.block_county_to_lidar_city_distances_lkup
USING BTREE(year);

CREATE INDEX block_county_to_lidar_city_distances_lkup_dist_m_btree
ON diffusion_data_shared.block_county_to_lidar_city_distances_lkup
USING BTREE(dist_m);
