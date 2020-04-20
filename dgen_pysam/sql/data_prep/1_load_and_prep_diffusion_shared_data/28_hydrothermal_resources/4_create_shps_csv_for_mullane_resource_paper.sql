--------------------------------------------------
-- Create View for CSV Export -- All System Types
--------------------------------------------------
set role 'diffusion-writers';
drop view if exists diffusion_geo.resources_hydrothermal;
create view diffusion_geo.resources_hydrothermal as 
	(
		select 
		uid as unique_id,
		geo_area as geothermal_area,
		sys_type as system_type,
		state,
		county,
		geo_province as geologic_province,
		res_temp_deg_c as reservoir_temperature_deg_c,
		min_depth_m,
		max_depth_m,
		res_vol_km3 as reservoir_volume_km3 ,
		gis_res_area_km2 as reservoir_area_km2,
		area_per_well_km2,
		n_wells as number_of_wells,
		accessible_resource_base_1e18_joules,
		mean_resource_1e18_joules as resource_1e18_joules,
		beneficial_heat_1e18_joules,
		beneficial_heat_mw_30yrs,
		beneficial_heat_mwh,
		reference
		from diffusion_geo.resources_hydrothermal_poly

		UNION ALL

		select 
		uid as unique_id,
		geo_area as geothermal_area,
		sys_type as system_type,
		state,
		county,
		geo_province as geologic_province,
		res_temp_deg_c as reservoir_temperature_deg_c,
		min_depth_m,
		max_depth_m,
		res_vol_km3 as reservoir_volume_km3 ,
		gis_res_area_km2 as reservoir_area_km2,
		area_per_well_km2,
		n_wells as number_of_wells,
		accessible_resource_base_1e18_joules,
		mean_resource_1e18_joules as resource_1e18_joules,
		beneficial_heat_1e18_joules,
		beneficial_heat_mw_30yrs,
		beneficial_heat_mwh,
		reference
		from diffusion_geo.resources_hydrothermal_pt
	);

-------------------------------------------------------
-- Create view for shapefiles -- field names are short
-------------------------------------------------------
set role 'diffusion-writers';
drop view if exists diffusion_geo.resources_hydrothermal_shp;
create view diffusion_geo.resources_hydrothermal_shp as 
	(
		select 
		uid,
		geo_area,
		sys_type,
		state,
		county,
		geo_province as geo_prov,
		res_temp_deg_c as res_temp,
		min_depth_m as min_depth,
		max_depth_m as max_depth,
		res_vol_km3 as res_vol,
		gis_res_area_km2 as reskm2,
		area_per_well_km2 as wellkm2,
		n_wells,
		accessible_resource_base_1e18_joules as accresbase,
		mean_resource_1e18_joules as resource,
		beneficial_heat_1e18_joules as benheatj,
		beneficial_heat_mw_30yrs as benheatmwt,
		beneficial_heat_mwh as benheatmwh,
		reference,
		st_transform(the_geom_96703, 4326) as the_geom_4326

		from diffusion_geo.resources_hydrothermal_poly

		UNION ALL

		select
		uid,
		geo_area,
		sys_type,
		state,
		county,
		geo_province as geo_prov,
		res_temp_deg_c as res_temp,
		min_depth_m as min_depth,
		max_depth_m as max_depth,
		res_vol_km3 as res_vol,
		gis_res_area_km2 as reskm2,
		area_per_well_km2 as wellkm2,
		n_wells,
		accessible_resource_base_1e18_joules as accresbase,
		mean_resource_1e18_joules as resource,
		beneficial_heat_1e18_joules as benheatj,
		beneficial_heat_mw_30yrs as benheatmwt,
		beneficial_heat_mwh as benheatmwh,
		reference,
		st_transform(the_geom_96703, 4326) as the_geom_4326
		from diffusion_geo.resources_hydrothermal_pt
	);


-- confirm calculations align with michelle's
select unique_id, geothermal_area, system_type, accessible_resource_base_1e18_joules, 
mean_resource_1e18_joules, beneficial_heat_1e18_joules, beneficial_heat_1e18_joules
from diffusion_geo.resources_hydrothermal
-- check #s with 'US Low T Hydrothermal Resource Data.xlsx'

-- export CSV
\COPY (SELECT * FROM diffusion_geo.resources_hydrothermal) TO '/Users/mmooney/Dropbox (NREL GIS Team)/Projects/2016_01_27_dGeo/Documents/resources/Data/Output/Data_Share/US_Low_Temp_Data_Export/080316/us_low_temp_hydro_080316.csv' with csv header;

-- export SHP
pgsql2shp -g the_geom_4326 -f '/Users/mmooney/Dropbox (NREL GIS Team)/Projects/2016_01_27_dGeo/Documents/resources/Data/Output/Data_Share/US_Low_Temp_Data_Export/080316/shapefiles/us_low_temp_hydro_poly_080316.shp' -h gispgdb -u mmooney -P mmooney dav-gis "select * from diffusion_geo.resources_hydrothermal_shp where sys_type != 'isolated system'";
pgsql2shp -g the_geom_4326 -f '/Users/mmooney/Dropbox (NREL GIS Team)/Projects/2016_01_27_dGeo/Documents/resources/Data/Output/Data_Share/US_Low_Temp_Data_Export/080316/shapefiles/us_low_temp_hydro_pt_080316.shp' -h gispgdb -u mmooney -P mmooney dav-gis "select * from diffusion_geo.resources_hydrothermal_shp where sys_type = 'isolated system'";

-- Confirm there are no duplicate Ids:
select unique_id, count(*) from diffusion_geo.resources_hydrothermal group by unique_id having count(*)>1
update diffusion_data_geo.delineated_areas as a