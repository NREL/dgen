
--------------------------------------------------
-- Merge Tables with Desired Fields -- Polygons
--------------------------------------------------
set role 'diffusion-writers';
drop table if exists diffusion_geo.resources_hydrothermal_poly cascade;
create table diffusion_geo.resources_hydrothermal_poly as 
(
		(select 
		uid,
		geo_area,
		'delineated area'::text as sys_type,
		state,
		county,
		geo_province,
		av_restemp as res_temp_deg_c,
		min_depth_m,
		max_depth_m,
		res_thickness_km,
		av_resarea_km2 * res_thickness_km as res_vol_km3,
		round((cast(st_area(the_geom_96703) as numeric)/1000000),3) as gis_res_area_km2,
		round(av_resarea_km2, 3) as orig_res_area_km2,
		round(cast(aw_km2 as numeric), 3) as area_per_well_km2,
		NULL::NUMERIC as n_wells,
		NULL::NUMERIC as accessible_resource_base_1e18_joules,
		NULL::NUMERIC as mean_resource_1e18_joules,
		NULL::NUMERIC as beneficial_heat_1e18_joules,
		NULL::NUMERIC as beneficial_heat_mw_30yrs,
		NULL::NUMERIC as beneficial_heat_mwh,
		'USGS Circular 892'::text as reference,
		notes,
		the_geom_96703
		from diffusion_data_geo.delineated_areas)
	
	UNION ALL 

		(select 
		uid,
		geo_area,
		'coastal plain'::text as sys_type,
		state,
		county,
		geo_province,
		av_restemp as res_temp_deg_c,
		min_depth_m,
		max_depth_m,
		res_thickness_km,
		av_resarea_km2 * res_thickness_km as res_vol_km3,
		round((cast(st_area(the_geom_96703) as numeric)/1000000),3) as gis_res_area_km2,
		round(av_resarea_km2, 3) as orig_res_area_km2,
		round(cast(aw_km2 as numeric), 3) as area_per_well_km2,
		NULL::NUMERIC as n_wells,
		NULL::NUMERIC as accessible_resource_base_1e18_joules,
		NULL::NUMERIC as mean_resource_1e18_joules,
		NULL::NUMERIC as beneficial_heat_1e18_joules,
		NULL::NUMERIC as beneficial_heat_mw_30yrs,
		NULL::NUMERIC as beneficial_heat_mwh,
		'USGS Circular 892'::text as reference,
		NULL::TEXT as notes,
		the_geom_96703
		from diffusion_data_geo.coastal_plains)

	UNION ALL

		(select 
		uid,
		geo_area,
		'sedimentary basin'::text as sys_type,
		state,
		county,
		geo_province,
		av_restemp as res_temp_deg_c,
		min_depth_m,
		max_depth_m,
		res_thickness_km,
		av_resarea_km2 * res_thickness_km as res_vol_km3,
		round((cast(st_area(the_geom_96703) as numeric)/1000000),3) as gis_res_area_km2,
		round(av_resarea_km2, 3) as orig_res_area_km2,
		round(cast(aw_km2 as numeric), 3) as area_per_well_km2,
		NULL::NUMERIC as n_wells,
		NULL::NUMERIC as accessible_resource_base_1e18_joules,
		NULL::NUMERIC as mean_resource_1e18_joules,
		NULL::NUMERIC as beneficial_heat_1e18_joules,
		NULL::NUMERIC as beneficial_heat_mw_30yrs,
		NULL::NUMERIC as beneficial_heat_mwh,
		'USGS Circular 892'::text as reference,
		notes,
		the_geom_96703
		from diffusion_data_geo.sed_basins)
	);

--------------------------------------------------
-- Merge Tables with Desired Fields -- Points
--------------------------------------------------
set role 'diffusion-writers';
drop table if exists diffusion_geo.resources_hydrothermal_pt cascade;
create table diffusion_geo.resources_hydrothermal_pt as 
	(
		select 
		uid,
		geo_area,
		'isolated system'::text as sys_type,
		state,
		county,
		geo_province,
		av_restemp as res_temp_deg_c,
		min_depth_m,
		max_depth_m,
		res_vol_km3,
		NULL::NUMERIC as gis_res_area_km2,
		round(cast(((||/ res_vol_km3) * (||/ res_vol_km3)) as numeric),3) as orig_res_area_km2,
		round(cast(((||/ res_vol_km3) * (||/ res_vol_km3)) as numeric),3) as area_per_well_km2,
		1::NUMERIC as n_wells,
		NULL::NUMERIC as accessible_resource_base_1e18_joules,
		NULL::NUMERIC as mean_resource_1e18_joules,
		NULL::NUMERIC as beneficial_heat_1e18_joules,
		NULL::NUMERIC as beneficial_heat_mw_30yrs,
		NULL::NUMERIC as beneficial_heat_mwh,
		source as reference,
		NULL::TEXT as notes,
		the_geom_96703
		from diffusion_data_geo.iso_sys
	);

--------------------------------------------------
-- Calculate NWells
--------------------------------------------------
-- n_wells = area/ area_per_well
update diffusion_geo.resources_hydrothermal_poly
	set n_wells= round((gis_res_area_km2/area_per_well_km2), 0);

select * from diffusion_geo.resources_hydrothermal_poly;

--------------------------------------------------
-- Find Counties for Missing Counties
--------------------------------------------------
set role 'mmooney';
update diffusion_geo.resources_hydrothermal_pt a
set county = (select b.name from esri.dtl_cnty_all_multi_20110101 b where st_intersects(b.the_geom_96703, a.the_geom_96703) = TRUE);
set role 'diffusion-writers';

--------------------------------------------------
-- Set Res_area for iso_sys to 1-km2 where vol is 1km3 
--------------------------------------------------

update diffusion_geo.resources_hydrothermal_pt a
set gis_res_area_km2 = 1
where res_vol_km3 = 1;

update diffusion_geo.resources_hydrothermal_pt a
set gis_res_area_km2 = (||/ res_vol_km3) * (||/ res_vol_km3)
where res_vol_km3 != 1;

select * from diffusion_geo.resources_hydrothermal_pt;



--------------------------------------------------
-- Update References to be Parenthetical
--------------------------------------------------
update diffusion_geo.resources_hydrothermal_pt 
set reference = (CASE WHEN reference = 'USGS Circular 892' THEN 'Reeds et al. 1893' 
		WHEN reference = 'Muffler et al. 1979' THEN 'USGS Circular 790' 
		WHEN reference = 'Geothermal Prospector, USGS Fact Sheet 2008' THEN 'Williams et al. 2008' 
		ELSE ''
		END);

update diffusion_geo.resources_hydrothermal_poly 
set reference = (CASE WHEN reference = 'USGS Circular 892' THEN 'Reeds et al. 1893' 
		WHEN reference = 'Muffler et al. 1979' THEN 'USGS Circular 790' 
		WHEN reference = 'Geothermal Prospector, USGS Fact Sheet 2008' THEN 'Williams et al. 2008' 
		ELSE ''
		END);


--------------------------------------------------
-- Calculate Resource 
--------------------------------------------------
-- Polygons
update diffusion_geo.resources_hydrothermal_poly
	set accessible_resource_base_1e18_joules = round(diffusion_geo.accessible_resource_joules(res_vol_km3, res_temp_deg_c)/1e18,3),
	mean_resource_1e18_joules = round(diffusion_geo.extractable_resource_joules_production_plan(n_wells, res_temp_deg_c)/1e18,3),
	beneficial_heat_1e18_joules = round(diffusion_geo.beneficial_heat_joules_production_plan(n_wells, res_temp_deg_c)/1e18,3),
	beneficial_heat_mw_30yrs = round(diffusion_geo.beneficial_heat_joules_production_plan(n_wells, res_temp_deg_c)/3600000000/(30*8760),3),
	beneficial_heat_mwh = round(diffusion_geo.beneficial_heat_joules_production_plan(n_wells, res_temp_deg_c)/3600000000, 3);

-- Points
update diffusion_geo.resources_hydrothermal_pt
	set accessible_resource_base_1e18_joules = round(diffusion_geo.accessible_resource_joules(res_vol_km3, res_temp_deg_c)/1e18, 3),
	mean_resource_1e18_joules = round(diffusion_geo.extractable_resource_joules_recovery_factor(res_vol_km3, res_temp_deg_c, 0.125, 15, 2.6)/1e18, 3),
	beneficial_heat_1e18_joules = round(diffusion_geo.beneficial_heat_joules_recovery_factor(res_vol_km3, res_temp_deg_c, 0.125, 25, 0.6, 2.6)/1e18, 3),
	beneficial_heat_mw_30yrs = round(diffusion_geo.beneficial_heat_joules_recovery_factor(res_vol_km3, res_temp_deg_c, 0.125, 25, 0.6, 2.6)/3600000000/(30*8760), 3),
	beneficial_heat_mwh = round(diffusion_geo.beneficial_heat_joules_recovery_factor(res_vol_km3, res_temp_deg_c, 0.125, 55, 0.6, 2.6)/3600000000, 3);


--------------------------------------------------
-- Update Beneficial Heat to 0 where Negative
--------------------------------------------------
update diffusion_geo.resources_hydrothermal_poly 
set accessible_resource_base_1e18_joules  = (CASE WHEN accessible_resource_base_1e18_joules < 0 THEN 0 
											 ELSE accessible_resource_base_1e18_joules END),
mean_resource_1e18_joules = (CASE WHEN mean_resource_1e18_joules < 0 THEN 0 
							 ELSE mean_resource_1e18_joules END),
beneficial_heat_1e18_joules = (CASE WHEN beneficial_heat_1e18_joules < 0 THEN 0
								ELSE beneficial_heat_1e18_joules END),
beneficial_heat_mw_30yrs = (CASE WHEN beneficial_heat_mw_30yrs < 0 THEN 0
							 ELSE beneficial_heat_mw_30yrs END),
beneficial_heat_mwh = (CASE WHEN beneficial_heat_mwh < 0 THEN 0
							 ELSE beneficial_heat_mwh END);

update diffusion_geo.resources_hydrothermal_pt 
set accessible_resource_base_1e18_joules  = (CASE WHEN accessible_resource_base_1e18_joules < 0 THEN 0 
											 ELSE accessible_resource_base_1e18_joules END),
mean_resource_1e18_joules = (CASE WHEN mean_resource_1e18_joules < 0 THEN 0 
							 ELSE mean_resource_1e18_joules END),
beneficial_heat_1e18_joules = (CASE WHEN beneficial_heat_1e18_joules < 0 THEN 0
								ELSE beneficial_heat_1e18_joules END),
beneficial_heat_mw_30yrs = (CASE WHEN beneficial_heat_mw_30yrs < 0 THEN 0
							 ELSE beneficial_heat_mw_30yrs END),
beneficial_heat_mwh = (CASE WHEN beneficial_heat_mwh < 0 THEN 0
							 ELSE beneficial_heat_mwh END);
