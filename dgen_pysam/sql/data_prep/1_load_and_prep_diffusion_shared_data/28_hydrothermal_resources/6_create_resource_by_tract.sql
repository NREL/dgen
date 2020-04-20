------------------------------------------------------------
-- A. Create Tract Resource Tables (from Lookup) -- POLYS
------------------------------------------------------------
drop table if exists diffusion_geo.hydro_poly_tracts;
create table diffusion_geo.hydro_poly_tracts as 
	(
		select 
		a.tract_id_alias, 
		a.resource_uid, 
		'hydrothermal'::TEXT as resource_type,
		b.sys_type,
		b.min_depth_m, 
		b.max_depth_m, 
		b.res_temp_deg_c, 
		a.area_of_intersection_sqkm as area_of_res_in_tract_sqkm,
		b.res_thickness_km,
		b.area_per_well_km2 as area_per_well_sqkm,
		round((a.area_of_intersection_sqkm/b.area_per_well_km2),0) as n_wells_in_tract,
		round(diffusion_geo.extractable_resource_joules_production_plan((a.area_of_intersection_sqkm/b.area_per_well_km2), b.res_temp_deg_c)/3600000000, 3) as extractable_resource_in_tract_mwh,
		NULL::numeric as extractable_resource_per_well_in_tract_mwh
		from diffusion_geo.hydro_poly_lkup a
		left join diffusion_geo.resources_hydrothermal_poly b
		on a.resource_uid = b.uid
	);
	-- 3127 rows affected = total # from lkup √

-- Delete any records where n_wells_in_tract = 0
delete from diffusion_geo.hydro_poly_tracts
where n_wells_in_tract = 0;

-- Update resource_per_well_in_tract
update diffusion_geo.hydro_poly_tracts
	set extractable_resource_per_well_in_tract_mwh = round(extractable_resource_in_tract_mwh / n_wells_in_tract, 3);

-- Total = 1,388 (after removing most records of 0 n_wells_in_tract)

-- ******************-- ******************-- ******************
-- * NOte: I calcualted reservoir thickenss by km (not m) to be consistent with the xlsx
-- ******************-- ******************-- ******************

------------------------------------------------------------
-- B. Create Tract Resource Tables (from Lookup) -- POINTS
------------------------------------------------------------
drop table if exists diffusion_geo.hydro_pt_tracts;
create table diffusion_geo.hydro_pt_tracts as 
	(
		select 
		a.tract_id_alias, 
		a.resource_uid, 
		'hydrothermal'::TEXT as resource_type,
		b.sys_type,
		b.min_depth_m, 
		b.max_depth_m, 
		b.res_temp_deg_c, 
		b.res_vol_km3,
		1::NUMERIC as n_wells_in_tract,
		round(b.mean_resource_1e18_joules * 1e18 / 3600000000, 3) as extractable_resource_in_tract_mwh,
		round(b.mean_resource_1e18_joules * 1e18 / 3600000000, 3) as extractable_resource_per_well_in_tract_mwh
		from diffusion_geo.hydro_pt_lkup a
		left join diffusion_geo.resources_hydrothermal_pt b
		on a.resource_uid = b.uid
	);

select * from diffusion_geo.hydro_pt_tracts;


-- ******************-- ******************-- ******************
-- ** Note: "reservoir_temp_deg_c" was listed 2x in your notes. is this a typo?"
-- 2. For points, extractable_resource_in_tract_mwh and extractable_resource_per_well_in_tract_mwh
	-- are the same exact value. Is this correct?
-- ******************-- ******************-- ******************
