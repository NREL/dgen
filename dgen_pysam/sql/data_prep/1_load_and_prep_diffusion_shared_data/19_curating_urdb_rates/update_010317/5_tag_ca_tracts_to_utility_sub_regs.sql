--Tag CA Tracks to utility sub region
	-- CA utilities are parsed up by sub region
	-- use centroid of the track to identify which region it belongs to
		-- using centroid of track because it will make joins easier downstream
	-- ca_tract_id | utility_eia_id | utility_reg_gid
--------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------
-- 1. Create Lkup table with eia_ids and gids
------------------------------------------------
	-- some rates apply to the entire region while others apply to a sub region only
	-- we create a lkup to handle these irregularities
drop table if exists diffusion_data_shared.ca_subregion_eia_id_and_gids_lkup ;
create table diffusion_data_shared.ca_subregion_eia_id_and_gids_lkup as (
	with sub_regions as (	
		select eia_id, util_reg_gid, utility_region, state_fips, the_geom_96703
		from diffusion_data_shared.urdb_rates_geoms_20170103
		where utility_region != 'None' and state_fips = '06'
	)
	select 
		eia_id,
		util_reg_gid,
		state_fips,
		utility_region,
		the_geom_96703
	from sub_regions
	);


------------------------------------------------
-- 2. Tag CA Block Centroids to a Utility
------------------------------------------------
-- Use the geometry column from diffusion_data_shared.ca_eia_id_and_gids_lkup to tag block centroids to utility
drop table if exists diffusion_data_shared.ca_subregion_tracts_to_util_reg;
create table diffusion_data_shared.ca_subregion_tracts_to_util_reg
	(
		tract_id_alias bigint,
		util_reg_gid bigint
	);

drop table if exists diffusion_blocks.tract_geoms_ca_subregion;
create table diffusion_blocks.tract_geoms_ca_subregion as (
	select * 
	from diffusion_blocks.tract_geoms
	where state_fips = '06'
);

SELECT parsel_2('dav-gis','mmooney','mmooney', 'diffusion_blocks.tract_geoms_ca_subregion', 'tract_id_alias', 
	'with ca_tracts as 
	(
		select tract_id_alias, st_centroid(the_geom_96703) as the_point_96703 
		from diffusion_blocks.tract_geoms_ca_subregion as x
	)
	select a.tract_id_alias, b.util_reg_gid
	from ca_tracts a
	left join diffusion_data_shared.ca_subregion_eia_id_and_gids_lkup b
	on st_intersects(a.the_point_96703, b.the_geom_96703);', 
	'diffusion_data_shared.ca_subregion_tracts_to_util_reg', 'aa', 30);

-- delete table 
drop table if exists diffusion_blocks.tract_geoms_ca_subregion;


---- B. QAQC (TODO)
--	-- B1. Check to see that the same number of tracts are in the table as block_tract
--	-- B2. Check to make sure there are no duplicate tract pgids
--	-- B2. Check to make sure that all tracts were assigned to a utility
-- Remove tracts that do not intersect (they will not be used)

	-- Check for duplicates
	-- Compare total CA tracts
	select count(*) from diffusion_data_shared.ca_subregion_tracts_to_util_reg 
	-- 8487 (good)
	select count(distinct (tract_id_alias, util_reg_gid)) from diffusion_data_shared.ca_subregion_tracts_to_util_reg 
	-- 8487(good)
	-- Check if there are nulls
	select * from diffusion_data_shared.ca_subregion_tracts_to_util_reg where util_reg_gid is null
	-- Originally there were 64 nulls -- this makes sense because most of CA is covered by utilities with a sub territory, but not all
	-- New Update (1/3/17) --> 3841 Nulls
			-- this makes sense because only 2 of the utilites with territories were included this go around and SDG was not included 
			-- and we are counting the number of tracts, not counties

-- delete the nulls
delete from diffusion_data_shared.ca_subregion_tracts_to_util_reg where util_reg_gid is null



