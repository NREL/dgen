------------------------------------------------
-- load shapefiles to pg
------------------------------------------------
--shp2pgsql -s 4326 -c -g the_geom_4326 -D -I /Volumes/Staff/mgleason/dGeo/Data/Source_Data/USGS_Circular_892/mmooney/final/coastal_plains.shp diffusion_data_geo.coastal_plains_geom | psql -h gispgdb -U mmooney dav-gis
--shp2pgsql -s 4326 -c -g the_geom_4326 -D -I /Volumes/Staff/mgleason/dGeo/Data/Source_Data/USGS_Circular_892/mmooney/final/delineated_areas.shp diffusion_data_geo.delineated_areas_geom | psql -h gispgdb -U mmooney dav-gis
--shp2pgsql -s 4326 -c -g the_geom_4326 -D -I /Volumes/Staff/mgleason/dGeo/Data/Source_Data/USGS_Circular_892/mmooney/final/sed_basins.shp diffusion_data_geo.sed_basins_geom | psql -h gispgdb -U mmooney dav-gis
--shp2pgsql -s 4326 -c -g the_geom_4326 -D -I /Volumes/Staff/mgleason/dGeo/Data/Source_Data/USGS_Circular_892/mmooney/final/isolated_systems.shp diffusion_data_geo.iso_sys_geom | psql -h gispgdb -U mmooney dav-gis



------------------------------------------------
-- Create Tables for Resource Data
------------------------------------------------
-- Add Coastal Plains tabular data
set role 'diffusion-writers';

drop table if exists diffusion_data_geo.coastal_plains;
CREATE TABLE diffusion_data_geo.coastal_plains
(
	geo_area text,
	state text,
	county text,
	uid text,
	av_restemp numeric,
	av_resarea_km2 numeric,
	res_thickness_km numeric,
	min_depth_m numeric,
	max_depth_m numeric,
	n_wells numeric,
	av_gradient_above_res_dc_km numeric,
	aw_km2 numeric,
	mean_access_resourcebase_10e18J numeric,
	plus_minus numeric,
	mean_resource_10e18J numeric,
	ben_heat_mwt_30yr numeric,
	geo_province text,
	ben_heat_mwh_1 numeric,
	ref_temp numeric,
	ben_heat_mwh numeric
);

-- Add Delineated Areas tabular data
set role 'diffusion-writers';

drop table if exists diffusion_data_geo.delineated_areas;
CREATE TABLE diffusion_data_geo.delineated_areas
(
	geo_area text,
	state text,
	county text,
	uid text,
	av_restemp numeric,
	av_resarea_km2 numeric,
	res_thickness_km numeric,
	min_depth_m numeric,
	max_depth_m numeric,
	n_wells numeric,
	av_gradient_above_res_dc_km numeric,
	aw_km2 numeric,
	mean_access_resourcebase_10e18J numeric,
	plus_minus numeric,
	mean_resource_10e18J numeric,
	ben_heat_mwt_30yr numeric,
	geo_province text,
	ben_heat_mwh_1 numeric,
	ref_temp numeric,
	ben_heat_mwh numeric,
	notes text
);

-- Add Sed Basins tabular data
set role 'diffusion-writers';

drop table if exists diffusion_data_geo.sed_basins;
CREATE TABLE diffusion_data_geo.sed_basins
(
	geo_area text,
	state text,
	county text,
	uid text,
	av_restemp numeric,
	av_resarea_km2 numeric,
	res_thickness_km numeric,
	min_depth_m numeric,
	max_depth_m numeric,
	n_wells text,
	av_gradient_above_res_dc_km text,
	aw_km2 text,
	mean_access_resourcebase_10e18J numeric,
	plus_minus numeric,
	mean_resource_10e18J numeric,
	ben_heat_mwt_30yr numeric,
	geo_province text,
	ben_heat_mwh_1 numeric,
	ref_temp numeric,
	ben_heat_mwh numeric
);

-- Add Iso Systems tabular data
set role 'diffusion-writers';

drop table if exists diffusion_data_geo.iso_sys;
CREATE TABLE diffusion_data_geo.iso_sys
(
	geo_area text,
	state text,
	county text,
	uid text,
	av_restemp numeric,
	res_vol_km3 numeric,
	min_depth_m numeric,
	max_depth_m numeric,
	mean_access_resourcebase_10e18J numeric,
	plus_minus numeric,
	mean_resource_10e18J numeric,
	ben_heat_mwt_30yr numeric,
	geo_province text,
	ben_heat_mwh_1 numeric,
	ref_temp numeric,
	ben_heat_mwh numeric,
	source text
);

------------------------------------------------
-- Add tables to pg
------------------------------------------------
\COPY  diffusion_data_geo.coastal_plains FROM '/Volumes/Staff/mgleason/dGeo/Data/Source_Data/USGS_Circular_892/postgres_input_tables_hydro_resource_final/coastal_plains.csv' with csv header;
\COPY  diffusion_data_geo.delineated_areas FROM '/Volumes/Staff/mgleason/dGeo/Data/Source_Data/USGS_Circular_892/postgres_input_tables_hydro_resource_final/da.csv' with csv header;
\COPY  diffusion_data_geo.sed_basins FROM '/Volumes/Staff/mgleason/dGeo/Data/Source_Data/USGS_Circular_892/postgres_input_tables_hydro_resource_final/sed_basins.csv' with csv header;
\COPY  diffusion_data_geo.iso_sys FROM '/Volumes/Staff/mgleason/dGeo/Data/Source_Data/USGS_Circular_892/postgres_input_tables_hydro_resource_final/iso_sys.csv' with csv header;


------------------------------------------------
-- Make Random Updates
------------------------------------------------
-- delte uids that we are not including becuase their areas are too large
delete from diffusion_data_geo.delineated_areas where uid = 'DA133' or uid = 'DA086' or uid = 'DA132';

--drop DA145 and DA119 since we have no locational information for them
Delete from diffusion_data_geo.delineated_areas
where uid = 'DA119' or uid='DA145';

-- Fix aw_km2 with range values
alter table diffusion_data_geo.sed_basins
add column notes text;
update diffusion_data_geo.sed_basins
set notes = 'the original area per well (aw_km2) was reported as 54 to 70. The average is reported in aw_km2 column in order to perform calculations',
aw_km2 = '62'
where uid = 'DA147';

-- fix problems from mmullane's xlsx (uid = DA130)
update diffusion_data_geo.sed_basins
set aw_km2 = 70, av_gradient_above_res_dc_km = '30-40'
where uid = 'DA130';

--delete iso systems that have no UIDs
delete from diffusion_data_geo.iso_sys where uid is null;

-- Delete Golconda Hot Springs because it has a duplicate id of DA112 and in the original xlsx table, it has no location/geometry associated with it
Delete from diffusion_data_geo.delineated_areas
where uid = 'DA112' and geo_area = 'Golconda Hot Springs';

-- Rename IDs (ID224) beucase there duplicates of it
update diffusion_data_geo.iso_sys
set uid = 'ID224A' where uid = 'ID224' and geo_area = 'Wells near Willow Creek';
update diffusion_data_geo.iso_sys
set uid = 'ID224B' where uid = 'ID224' and geo_area = 'Willow Creek Hot Springs';



------------------------------------------------
-- Add Geometry
------------------------------------------------
-- Delineated Areas
alter table diffusion_data_geo.delineated_areas
add the_geom_4326 geometry, add the_geom_96703 geometry;
update diffusion_data_geo.delineated_areas as a
set the_geom_4326 = b.the_geom_4326,
	the_geom_96703 = st_transform(b.the_geom_4326, 96703)
from diffusion_data_geo.delineated_areas_geom as b
where a.uid = b.uid;

-- Sed Basins
alter table diffusion_data_geo.sed_basins
add the_geom_4326 geometry, add the_geom_96703 geometry;
update diffusion_data_geo.sed_basins as a
set the_geom_4326 = b.the_geom_4326,
	the_geom_96703 = st_transform(b.the_geom_4326, 96703)
from diffusion_data_geo.sed_basins_geom as b
where a.uid = b.uid;

-- Coastal Plains
alter table diffusion_data_geo.coastal_plains
add the_geom_4326 geometry, add the_geom_96703 geometry;
update diffusion_data_geo.coastal_plains as a
set the_geom_4326 = b.the_geom_4326,
	the_geom_96703 = st_transform(b.the_geom_4326, 96703)
from diffusion_data_geo.coastal_plains_geom as b
where a.uid = b.uid;

-- Iso Systems -- Add XY
alter table diffusion_data_geo.iso_sys
add the_geom_4326 geometry, add the_geom_96703 geometry;
update diffusion_data_geo.iso_sys as a
set the_geom_4326 = b.the_geom_4326,
	the_geom_96703 = st_transform(b.the_geom_4326, 96703)
from diffusion_data_geo.iso_sys_geom as b
where a.uid = b.uid;



