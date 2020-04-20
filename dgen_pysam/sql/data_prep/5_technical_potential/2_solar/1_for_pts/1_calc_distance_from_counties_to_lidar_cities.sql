--------------------------------------------------------------------------------------------------------
-- add geography columns to the two input tables
-- county_geom
ALTER TABLE diffusion_shared.county_geom
ADD COLUMN the_geog geography;

UPDATE diffusion_shared.county_geom
set the_geog = the_geom_4326::geography;

-- solar_gid
-- add 4326 first
ALTER TABLE pv_rooftop_dsolar_integration.solar_gid
ADD COLUMN rasd_the_geom_4326 geometry;

UPDATE pv_rooftop_dsolar_integration.solar_gid
SEt rasd_the_geom_4326 = ST_Transform(rasd_the_geom_96703, 4326);

-- then add geog
ALTER TABLE pv_rooftop_dsolar_integration.solar_gid
ADD COLUMN rasd_the_geog geography;

UPDATE pv_rooftop_dsolar_integration.solar_gid
set rasd_the_geog = rasd_the_geom_4326::geography;

-- add indices
CREATE INDEX county_geom_the_geog_gist
ON diffusion_shared.county_geom
USING GIST(the_geog);

CREATE INDEX solar_gid_rasd_the_geom_4326_gist
ON pv_rooftop_dsolar_integration.solar_gid
USING GIST(rasd_the_geom_4326);

CREATE INDEX county_geom_the_geog_gist
ON pv_rooftop_dsolar_integration.solar_gid
USING GIST(rasd_the_geog);

-- add geography for point on surface
ALTER TABLE diffusion_shared.county_geom
ADD the_point_on_surface_geog geography;

update diffusion_shared.county_geom
set the_point_on_surface_geog = ST_PointOnSurface(the_geom_4326)::geography;

ALTER TABLE pv_rooftop_dsolar_integration.solar_gid
ADD rasd_the_point_on_surface_geog geography;

update pv_rooftop_dsolar_integration.solar_gid
set rasd_the_point_on_surface_geog = ST_PointOnSurface(rasd_the_geom_4326)::geography;
--------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------

-- now calculate distances
-- use centroid geographies as the best trade off of speed + accuracy
DROP TABLE IF EXISTS diffusion_data_shared.county_to_lidar_city_distances_lkup;
CREATE TABLE diffusion_data_shared.county_to_lidar_city_distances_lkup AS
SELECT a.county_id, b.city_id, b.city, b.state, b.year, b.basename,
	ST_Distance(a.the_point_on_surface_geog, b.rasd_the_point_on_surface_geog) as dist_m
FROM diffusion_shared.county_geom a
LEFT JOIN pv_rooftop_dsolar_integration.solar_gid b
	ON a.census_region = b.census_region;
-- 148536 rows

		
-- create indices
CREATE INDEX county_to_lidar_city_distances_lkup_county_id_btree
ON diffusion_data_shared.county_to_lidar_city_distances_lkup
USING BTREE(county_id);

CREATE INDEX county_to_lidar_city_distances_lkup_year_btree
ON diffusion_data_shared.county_to_lidar_city_distances_lkup
USING BTREE(year);

CREATE INDEX county_to_lidar_city_distances_lkup_dist_m_btree
ON diffusion_data_shared.county_to_lidar_city_distances_lkup
USING BTREE(dist_m);
