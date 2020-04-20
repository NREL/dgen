---------------------------------------------------------------
-- CARVE UP HYDROTHERMAL POLY RESOURCE LAND BY DEVELOPMENT
---------------------------------------------------------------

-------------------------------------
-- select all blocks with buildings
-------------------------------------
drop table if exists diffusion_data_geo.blocks_with_buildings_geoms;
set role 'diffusion-writers';
create table diffusion_data_geo.blocks_with_buildings_geoms as (
select a.* from
diffusion_blocks.block_geoms a
inner join diffusion_blocks.blocks_with_buildings b
on a.pgid = b.pgid);--

-- create index
create index blocks_with_blgs on diffusion_data_geo.blocks_with_buildings_geoms using GIST (the_poly_96703);


------------------------------------------
-- Create Fishnets & Clip to Boundaries
------------------------------------------
drop table if exists diffusion_data_geo.hydro_resource_poly_fishnets_aw;
--create table mmooney.temp as (select uid, av_resarea_km2, ben_heat_mwt_30yr, aw_km2, (st_area(the_geom_96703)* 1000000) as cell_area_km2, st_fishnet(the_geom_96703, (aw_km2 * 1000000)) as the_geom_96703 from diffusion_geo.resources_hydro_poly where uid= 'DA058')

set role 'diffusion-writers';

drop table if exists diffusion_data_geo.hydro_resource_poly_fishnets_aw_all;
create table diffusion_data_geo.hydro_resource_poly_fishnets_aw_all as (
with a as
(
--create fishnets
select uid, av_resarea_km2, ben_heat_mwt_30yr, 
aw_km2, (st_area(the_geom_96703)/ 1000000) as cell_area_km2, 
st_fishnet(the_geom_96703, (cast(aw_km2 as numeric))*1000) as the_geom_96703 
from diffusion_geo.resources_hydro_poly 

)
-- create fishnet ids and other ids
select row_number() OVER () as gid, row_number() OVER (PARTITION BY a.uid) as uid_cell_id, a.*
from a
);

drop table if exists diffusion_data_geo.hydro_resource_poly_fishnets_aw_with_bldgs;
create table diffusion_data_geo.hydro_resource_poly_fishnets_aw_with_bldgs as (
select distinct f.* from (
select b.gid, b.uid_cell_id, b.uid, b.av_resarea_km2, st_area(b.the_geom_96703)/1000000 as cell_area_km2, 
((st_area(b.the_geom_96703)/1000000)/b.av_resarea_km2) as perc_cell_area, b.ben_heat_mwt_30yr, 
(b.ben_heat_mwt_30yr * ((st_area(b.the_geom_96703)/1000000)/b.av_resarea_km2) ) as perc_ben_heat_mwt_30yr, 
st_intersection(b.the_geom_96703, c.the_geom_96703) as the_geom_96703
from diffusion_data_geo.hydro_resource_poly_fishnets_aw_all b, diffusion_geo.resources_hydro_poly c
where b.uid = c.uid and st_intersects(b.the_geom_96703, c.the_geom_96703)) as f
);

delete from diffusion_data_geo.hydro_resource_poly_fishnets_aw_with_bldgs
where gid not in (select d.gid from diffusion_data_geo.hydro_resource_poly_fishnets_aw_with_bldgs d, diffusion_data_geo.blocks_with_buildings_geoms e
where st_intersects(d.the_geom_96703, e.the_poly_96703));


-----------------------------------------------------
-- Identify Intersecting Blocks & Append to Array
-----------------------------------------------------


set role 'diffusion-writers';
create table diffusion_geo.blocks_with_blgs_intersecting_hydro_fishnet as  (select gid, uid_cell_id, b.pgid as block_pgids FROM diffusion_data_geo.hydro_resource_poly_fishnets_aw_with_bldgs a INNER JOIN diffusion_data_geo.blocks_with_buildings_geoms b ON st_intersects(a.the_geom_96703, b.the_poly_96703));


-- create final table with resource geometries
set role 'diffusion-writers';
drop table if exists diffusion_geo.hydrothermal_resource_poly_carveouts_by_block;
create table diffusion_geo.hydrothermal_resource_poly_carveouts_by_block as 
	(
		select gid, 
		uid_cell_id, uid,
		NULL::NUMERIC as res_area_km2,
		st_area(the_geom_96703)/1000000 as cell_area_km2,
		perc_cell_area as pct_cell_area,
		NULL::NUMERIC as res_beneficial_heat_1e18_joules,
		NULL::NUMERIC as res_beneficial_heat_mwh_30yrs,
		NULL::NUMERIC as cell_pct_beneficial_heat_1e18_joules,
		NULL::NUMERIC as cell_pct_beneficial_heat_mwh_30yrs,
		the_geom_96703
		from diffusion_data_geo.hydro_resource_poly_fishnets_aw_with_bldgs
	);

-----------------------------------------------------
-- Calculate Beneficial Heat
-----------------------------------------------------
update diffusion_geo.hydrothermal_resource_poly_carveouts_by_block a
	set res_area_km2 = (select b.gis_res_area_km2 from diffusion_geo.resources_hydrothermal_poly b where a.uid = b.uid limit 1),
	res_beneficial_heat_1e18_joules = (select b.beneficial_heat_1e18_joules from diffusion_geo.resources_hydrothermal_poly b where a.uid = b.uid limit 1),
	res_beneficial_heat_mwh_30yrs = (select b.beneficial_heat_mwh_30yrs from diffusion_geo.resources_hydrothermal_poly b where a.uid = b.uid  limit 1);

update diffusion_geo.hydrothermal_resource_poly_carveouts_by_block
	set pct_cell_area = cell_area_km2/ res_area_km2;
update diffusion_geo.hydrothermal_resource_poly_carveouts_by_block
	set cell_pct_beneficial_heat_1e18_joules = res_beneficial_heat_1e18_joules / (pct_cell_area * 100),
	cell_pct_beneficial_heat_mwh_30yrs = res_beneficial_heat_mwh_30yrs / (pct_cell_area * 100);


-- Clean Up schemas
-- DROP TABLE diffusion_data_geo.hydro_resource_poly_fishnets_aw;
-- DROP TABLE diffusion_data_geo.hydro_resource_poly_fishnets_aw_all;
-- DROP TABLE diffusion_data_geo.hydro_resource_poly_fishnets_aw_temp;
-- DROP TABLE diffusion_data_geo.hydro_resource_poly_fishnets_aw_temp2;
-- DROP TABLE diffusion_data_geo.hydro_resource_poly_fishnets_aw_with_bldgs;
-- DROP TABLE diffusion_data_geo.carveouts_hydropoly_fishnets_spaced_by_aw_with_blocks;
-- drop table if exists diffusion_geo.blocks_with_blgs_intersecting_hydro_fishnets;
-- 
-- set role 'diffusion-writers';
-- create table diffusion_data_geo.resources_hydrothermal_poly_carveouts_by_block as (
-- select * from diffusion_geo.resources_hydrothermal_poly_carveouts_by_block);
-- DROP TABLE diffusion_geo.resources_hydrothermal_poly_carveouts_by_block;



