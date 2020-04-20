-- This code parses up the geometries of a CA utility pased on whether the rate belongs to the full utility geometry (no climate zone) 
-- or whether the rate is a climate zone specific rate and therefore belongs to a parsed up zonal geometry
-- see 3_account_for_ca_climate_zones.sql notes for more information

--------------------------------------------------------------------------------------------------------------------------------------

--------------------------------------------------
-- Create a temporary sam data table (part 2)
--------------------------------------------------
set role 'diffusion-writers';
	-- * Note, this takes a while (~60 minutes)
	drop table if exists diffusion_data_shared.urdb_rates_sam_min_max;
	create table diffusion_data_shared.urdb_rates_sam_min_max as (
		select a.*, 
		get_key(a.json, 'peak_kW_capacity_min') as demand_min, 
		get_key(a.json, 'peak_kW_capacity_max') as demand_max, 
		get_key(a.json, 'kWh_useage_min') as energy_min, 
		get_key(a.json, 'kWh_useage_max') as energy_max
		from diffusion_data_shared.temp_sam_joins a);

	drop table if exists diffusion_data_shared.urdb_rates_sam_min_max_20161005;
	create table diffusion_data_shared.urdb_rates_sam_min_max_20161005 as (
		select a.* 
		from
		diffusion_data_shared.urdb_rates_sam_min_max

----------------------------------------------------
-- Create Union Geometries for each Utility Region
----------------------------------------------------
	-- Assign a unique GID for each Utility State and Region geometry (util_reg_gid)
	drop table if exists diffusion_data_shared.urdb_rates_geoms_20161005;
	create table diffusion_data_shared.urdb_rates_geoms_20161005 as (
		with a as (
				with a as (
					with a as (
						select distinct eia_id, state_fips from urdb_rates.utility_county_geoms_20161005 where utility_region is null)
					select a.*, (row_number()  over())::bigint as util_reg_gid from a)
				select a.*, st_collectionextract(st_collect(b.the_geom_96703),3) as the_geom_96703
				from a
				left join urdb_rates.utility_county_geoms_20161005 b
				on a.eia_id = b.eia_id and a.state_fips = b.state_fips where b.utility_region is null--and a.state_fips = b.state_fips and a.utility_region = b.utility_region
				group by a.eia_id, a.state_fips, a.util_reg_gid, b.eia_id, b.state_fips),
		b as (
				with a as (
					with a as (
						select distinct a.eia_id, a.state_fips, a.utility_region from urdb_rates.utility_county_geoms_20161005 a where a.utility_region is not null order by a.eia_id, a.utility_region)
					select a.*, 1276 + (row_number()  over() )::bigint as util_reg_gid from a)

				select a.*, st_collectionextract(st_collect(b.the_geom_96703),3) as the_geom_96703
				from a
				left join urdb_rates.utility_county_geoms_20161005 b
				on a.eia_id = b.eia_id and a.state_fips = b.state_fips and a.utility_region = b.utility_region
				group by a.eia_id, a.state_fips, a.utility_region, a.util_reg_gid, b.eia_id, b.state_fips, b.utility_region)
		select a.eia_id, a.state_fips, 'None'::text as utility_region, a.util_reg_gid, a.the_geom_96703 from a
		union all select b.eia_id, b.state_fips, b.utility_region, b.util_reg_gid, b.the_geom_96703 from b);

	-- Switch Nulls to 'None' for subterritory name in sam_min_max to help with joining (next step)
		update diffusion_data_shared.urdb_rates_sam_min_max
		set utility_region = 'None' where utility_region is null;


----------------------------------------------------
-- Create Attribute Lookup Table for Rates
----------------------------------------------------
	drop table if exists diffusion_data_shared.urdb_rates_attrs_lkup_20161005;
	create table diffusion_data_shared.urdb_rates_attrs_lkup_20161005 as (
		with st as (select distinct state_fips, state_abbr from urdb_rates.utility_county_geoms_20161005)
		select
			(row_number() over())::bigint as rate_util_reg_gid,
			b.util_reg_gid, 	
			a.rate_id_alias, 
			a.eia_id, 
			a.utility_type,
			a.res_com as sector,
			c.state_abbr,
			b.state_fips, 
			b.utility_region as sub_territory_name, 
			a.demand_min,
			a.demand_max,
			a.energy_min,
			a.energy_max
		from diffusion_data_shared.urdb_rates_sam_min_max a
		left join diffusion_data_shared.urdb_rates_geoms_20161005 b
		on a.eia_id = b.eia_id and a.state_fips = b.state_fips and a.utility_region = b.utility_region
		left join st c
		on b.state_fips = c.state_fips
		);

	-- remove 'None' from subterritory name
		update diffusion_data_shared.urdb_rates_sam_min_max
		set utility_region = NULL where utility_region = 'None';

		update diffusion_data_shared.urdb_rates_attrs_lkup_20161005
			set sub_territory_name = NULL where sub_territory_name = 'None';

	-- QAQC
		select count(*) from diffusion_data_shared.urdb_rates_attrs_lkup_20161005 --limit 400
			-- 6938 total

-----------------
-- Make Indicies
-----------------
create index urdb_rates_geoms_20161005_gist_96703 on diffusion_data_shared.urdb_rates_geoms_20161005 using gist(the_geom_96703);
create index urdb_rates_geoms_20161005_btree_util_reg_gid on diffusion_data_shared.urdb_rates_geoms_20161005 using btree(util_reg_gid);
create index urdb_rates_geoms_20161005_btree_eia_id on diffusion_data_shared.urdb_rates_geoms_20161005 using btree(eia_id);
create index urdb_rates_geoms_20161005_btree_state_fips on diffusion_data_shared.urdb_rates_geoms_20161005 using btree(state_fips);

create index urdb_rates_attrs_lkup_20161005_btree_util_reg_gid on diffusion_data_shared.urdb_rates_attrs_lkup_20161005 using btree(util_reg_gid);
create index urdb_rates_attrs_lkup_20161005_btree_eia_id on diffusion_data_shared.urdb_rates_attrs_lkup_20161005 using btree(eia_id);
create index urdb_rates_attrs_lkup_20161005_btree_state_fips on diffusion_data_shared.urdb_rates_attrs_lkup_20161005 using btree(state_fips);
create index urdb_rates_attrs_lkup_20161005_btree_util_reg on diffusion_data_shared.urdb_rates_attrs_lkup_20161005 using btree(utility_region);
create index urdb_rates_attrs_lkup_20161005_btree_rate_util_reg_gid on diffusion_data_shared.urdb_rates_attrs_lkup_20161005 using btree(rate_util_reg_gid);


------------
-- QAQC
------------
	-- Check Geometry is Q
		-- the county boundaries are not dissolved but the geometry is a multipolygon (good)
		-- no unique util_reg_gid crosses state lines (good)

	-- Check to make sure there are no duplicates
		with a as (select utility_region_id_alias, count(*) from diffusion_data_shared.urdb_rate_geoms_20161005 
		group by utility_region_id_alias 
		order by count(utility_region_id_alias))
		select * from a where count !=1
		-- no duplicates!
