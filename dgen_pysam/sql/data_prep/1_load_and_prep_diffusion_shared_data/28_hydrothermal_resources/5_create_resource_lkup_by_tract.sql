----------------------------------------
-- A. Create Lookup Table for Hydro Poly
----------------------------------------
-- 1. Intersect Tracts by Resource and then Resource by Tracts
set role 'diffusion-writers';
drop table if exists diffusion_geo.hydro_poly_lkup;
create table diffusion_geo.hydro_poly_lkup  as (
	select t.tract_id_alias, r.uid as resource_uid,
	round(cast(st_area(st_intersection(r.the_geom_96703, t.the_geom_96703))/1000000 as numeric), 3)
	as area_of_intersection_sqkm
	from diffusion_geo.resources_hydrothermal_poly r
	left join 
	diffusion_blocks.tract_geoms t
	on st_intersects(r.the_geom_96703, t.the_geom_96703));

-- 2. Delete anything with super small intersection areas (less than 0.0001)
	delete from diffusion_geo.hydro_poly_lkup where area_of_intersection_sqkm = 0; -- 5 Rows affected

-- Total = 3127

----------------------------------------
-- B. Create Lookup Table for Hydro PT
----------------------------------------
-- 1. Intersect Tracts by Resource and then Resource by Tracts 
set role 'diffusion-writers';
drop table if exists diffusion_geo.hydro_pt_lkup;
create table diffusion_geo.hydro_pt_lkup  as (
	select cast(b.tract_id_alias as integer), a.uid as resource_uid
	from diffusion_geo.resources_hydrothermal_pt a
	left join diffusion_blocks.tract_geoms b
	on st_intersects(a.the_geom_96703, b.the_geom_96703));

-- 2. Delete Null Values since they are offshore
delete from diffusion_geo.hydro_pt_lkup where resource_uid = 'AK024' or resource_uid = 'CA113';

-- Total = 1212

----------------------------------------
-- C. Create Lookup Table for EGS
----------------------------------------
-- resource grid table = dgeo.smu_t35km_2016 
-- 1. Create empty lkup table
	set role 'diffusion-writers';
	drop table if exists diffusion_geo.egs_lkup;
	create table diffusion_geo.egs_lkup 
		(tract_id_alias integer,
		cell_gid integer,
		area_of_intersection_sqkm numeric);
-- 2. Intersect Tracts by Resource and then Resource by Tracts
	select parsel_2('dav-gis', 'mmooney', 'mmooney', 
		'dgeo.smu_t35km_2016', --split table
		'gid', -- splitting unique id
		'select b.tract_id_alias, a.gid,
		round(cast(st_area(st_intersection(a.the_geom_96703, b.the_geom_96703))/1000000 as numeric), 3)
		from dgeo.smu_t35km_2016 a
		left join diffusion_blocks.tract_geoms b
		on st_intersects(a.the_geom_96703, b.the_geom_96703)',
		'diffusion_geo.egs_lkup',
		'a',
		10);

-- 3. Delete tract_id_alias null values (100 records; these are located along peripheries of the US)
	delete from diffusion_geo.egs_lkup where tract_id_alias is null;

-- 4. Delete
	delete from diffusion_geo.egs_lkup where area_of_intersection_sqkm = 0; --2038

-- Total = 815437

-----------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------


---------------------------------------------
-- Part 2 -- Run Checks on the Lookup Tables
---------------------------------------------
-- 1. QAQC Hydrothermal Poly Lookup 
		-- 3132 rows total
		-- 184 total resource ids = 184 from resource_hydrothermal_poly (All resource ids accounted for)
		-- Check for duplicates in uid - tract_id_alias pairs
			with check_duplicates as (
				select distinct on (tract_id_alias, resource_uid, area_of_intersection_sqkm)
				tract_id_alias, resource_uid, area_of_intersection_sqkm, count(*) as cnt
				from diffusion_geo.hydro_poly_lkup
				group by tract_id_alias, resource_uid, area_of_intersection_sqkm
				)
				select count(*) from check_duplicates where cnt !=1;
			-- Total = 0 duplicates
					with check_duplicates as (
				select distinct on (tract_id_alias, resource_uid)
				tract_id_alias, resource_uid, count(*) as cnt
				from diffusion_geo.hydro_poly_lkup
				group by tract_id_alias, resource_uid)
				select count(*) from check_duplicates where cnt !=1;
			-- Total = 0 duplicates
		-- Check for NUll Values
			select * from diffusion_geo.hydro_poly_lkup where tract_id_alias is null; -- NO Null Values
			select * from diffusion_geo.hydro_poly_lkup where resource_uid is null; -- No Null values

-- 2. QAQC Hydrothermal Pt Lookup 
		-- 1214 rows total
		-- 184 total resource ids = 184 from resource_hydrothermal_poly (All resource ids accounted for)
				select count(distinct resource_uid) from diffusion_geo.hydro_pt_lkup; -- = 1214 uids
			-- total number of rows = total number of uids
				select count(distinct uid) from diffusion_geo.resources_hydrothermal_pt; -- = 1214
			-- total # of uids in lkup = total # of uids in source table
		-- Check for duplicates in uid - tract_id_alias pairs
				with check_duplicates as (
				select distinct on (tract_id_alias, resource_uid)
				tract_id_alias, resource_uid, count(*) as cnt
				from diffusion_geo.hydro_pt_lkup
				group by tract_id_alias, resource_uid)
				select count(*) from check_duplicates where cnt !=1
			-- Total = 0 duplicates
		-- Make sure there are no Null Values
			-- I found two null tract_id_alias - "AK024" and "CA113"
					select * from diffusion_geo.hydro_pt_lkup where tract_id_alias is null
				-- delete these resources since they are null and they are offshore/outside CONUS
					--delete from diffusion_geo.hydro_pt_lkup where resource_uid = 'AK024' or resource_uid = 'CA113'; -- this is duplicated above
				-- No more null values (after deleting)

-- 3. QAQC Hydrothermal EGS Lookup 
		-- Check total cell ids √
			select count(distinct cell_gid) from diffusion_geo.egs_lkup; -- = 473992 (orginally with null values)
			select count(distinct cell_gid) from dgeo.smu_t35km_2016;-- = 473992
		-- Check for duplicates √
					with check_duplicates as (
					select distinct on (tract_id_alias, cell_gid, area_of_intersection_sqkm)
					tract_id_alias, cell_gid, area_of_intersection_sqkm, count(*) as cnt
					from diffusion_geo.egs_lkup
					group by tract_id_alias, cell_gid, area_of_intersection_sqkm)
					select count(*) from check_duplicates where cnt !=1;
				-- Total = 0
		-- Look for null values
			-- tract_id_alias null values
				select * from diffusion_geo.egs_lkup where tract_id_alias is null
			-- create view to explore null values in QGIS
				drop view if exists diffusion_geo.temp;
				create view diffusion_geo.temp as (
					with b as (
						select * from dgeo.smu_t35km_2016 b
						left join diffusion_geo.egs_lkup a
						on b.gid = a.cell_gid)
					select * from b where b.tract_id_alias is null
					);
				-- drop view
					drop view if exists diffusion_geo.temp;
				-- Null Values are located around the peripheries of the US
			-- delete from diffusion_geo.egs_lkup where tract_id_alias is null
				--
