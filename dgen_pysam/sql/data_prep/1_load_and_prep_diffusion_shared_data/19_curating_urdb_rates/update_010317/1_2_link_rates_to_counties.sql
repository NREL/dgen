--------------------------------------------------------
-- 1. Make County-Rate Lookup Table
--------------------------------------------------------
-- 1. Add Urdb Rate ID to the eia_county_uids_lkup
create table urdb_rates.urdb_utility_eia_and_county_ids_lkup_20161005_with_urdb_id as (
select b.urdb_rate_id, a.* 
from  urdb_rates.urdb_utility_eia_and_county_ids_lkup_20161005 a 
left join urdb_rates.urdb3_verified_rates_sam_data_20161005 b
on a.rate_id_alias = b.rate_id_alias)

-- 2. Make County Geoms Table
	-- use existing county geoms as the basis
drop table if exists urdb_rates.urdb_utility_eia_and_county_ids_lkup_20170103 ;
create table urdb_rates.urdb_utility_eia_and_county_ids_lkup_20170103 as (
	with a as (
		select a.rate_id_alias, a.eia_id, a.urdb_rate_id, b.state_fips, b.cnty_fips 
		from urdb_rates.urdb3_verified_rates_sam_data_20170103 a 
		left join urdb_rates.urdb_utility_eia_and_county_ids_lkup_20161005_with_urdb_id b
		on a.urdb_rate_id = b.urdb_rate_id)
	select distinct a.rate_id_alias, a.eia_id, a.urdb_rate_id, a.state_fips, a.cnty_fips 
	from a
	);
	-- total = 38020
	-- make sure we still have potomac


-- 3. QAQC Check for null counties
	--select * from urdb_rates.urdb_utility_eia_and_county_ids_lkup_20170103
	--	where cnty_fips is null
	--	order by eia_id
			-- "14328" & "15270" & "17609"
			-- New Pacific Gas and Electric Co Rates (14328)
			-- New Southern California and Edison Rates (17609)
			-- New Utility = Potomac

-- 4. Make County Geoms Table (Attempt #2)
	-- this attempt accounts for the missing countys (where eia_id = "14328" & "15270" & "17609")
drop table if exists urdb_rates.urdb_utility_eia_and_county_ids_lkup_20170103 ;
create table urdb_rates.urdb_utility_eia_and_county_ids_lkup_20170103 as (
	with aa as (
		select a.rate_id_alias, a.eia_id, a.urdb_rate_id, b.state_fips, b.cnty_fips 
		from urdb_rates.urdb3_verified_rates_sam_data_20170103 a 
		left join urdb_rates.urdb_utility_eia_and_county_ids_lkup_20161005_with_urdb_id b
		on a.urdb_rate_id = b.urdb_rate_id),
	b as (
		select distinct a.rate_id_alias, a.eia_id, a.urdb_rate_id, a.state_fips, a.cnty_fips 
		from aa a
		where cnty_fips is not null
		),
	-- California Utilities (New Rates Only)
	c as (
		-- Todo -- Need to account for climate zones!!!!!!
		with a as (
			with a as (
				select distinct a.rate_id_alias, a.eia_id, a.urdb_rate_id, a.state_fips, a.cnty_fips 
				from aa a
				where cnty_fips is null and eia_id in ('14328', '17609')
				)
			select distinct a.rate_id_alias, a.eia_id, a.urdb_rate_id, b.state_fips, b.cnty_fips
			from a 
			left join urdb_rates.urdb_utility_eia_and_county_ids_lkup_20161005_with_urdb_id b
			on a.eia_id = b.eia_id -- climate zone?? 
		)
		select distinct a.rate_id_alias, a.eia_id, a.urdb_rate_id, a.state_fips, a.cnty_fips 
		from a
		),
	-- New Utilities (D.C. Metro Area)
	d as (
			with a as (
				-- get potomac utility territory region
				select * 
				from ventyx.electric_service_territories_20150701_multipart 
				where company_na like '%Potomac%' and city like 'Washington'
				),
			b as (
				select b.state_fips, b.cnty_fips
				from a
				left join esri.dtl_cnty_all_multi_20110101 b
				on st_intersects(a.the_geom_4326, b.the_geom_4326)
				),
			c as (
				select distinct a.rate_id_alias, a.eia_id, a.urdb_rate_id, a.state_fips, a.cnty_fips 
				from aa a
				where cnty_fips is null and eia_id in ('15270')
				)
			select a.rate_id_alias, a.eia_id, a.urdb_rate_id, b.state_fips, b.cnty_fips
			from c a, b
		)
	select b.* from b union all
	select c.* from c union all 
	select d.* from d

	);
		-- select count(distinct (a.rate_id_alias, a.eia_id, a.urdb_rate_id, a.state_fips, a.cnty_fips))
		-- from urdb_rates.urdb_utility_eia_and_county_ids_lkup_20170103 a\
		-- 		-- total = 39256; distinct total = 39256



--------------------------------------------------------
-- 2. Make County Geoms Table (for Geometries)
--------------------------------------------------------
	-- Do this once we are confident that all utility rates are assigned to its corresponding county
	drop table if exists urdb_rates.utility_county_geoms_20170103;
	create table urdb_rates.utility_county_geoms_20170103 as (
	select b.rate_id_alias, b.urdb_rate_id, b.eia_id, a.state_fips, a.county_fips, a.county, a.state, a.state_abbr, a.geoid10, a.the_geom_96703_5m as the_geom_96703
	from urdb_rates.urdb_utility_eia_and_county_ids_lkup_20170103 b
	left join diffusion_blocks.county_geoms a
	on a.state_fips = b.state_fips and a.county_fips = b.cnty_fips);

	-- Add Gist
	create index utility_county_geoms_20170103_gist on urdb_rates.utility_county_geoms_20170103 using gist(the_geom_96703);

	-- Check #s
		-- select count( distinct (rate_id_alias) ) from urdb_rates.utility_county_geoms_20170103;
		-- -- total distinct rate_id_alias = 4009
		-- select count(rate_id_alias) from urdb_rates.urdb3_verified_rates_sam_data_20170103;
		-- -- total distinct rate_id_alias = 4009 -- GOOD TO GO!!!!





-- get counts:

select count(distinct (eia_id)) from urdb_rates.urdb_utility_eia_and_county_ids_lkup_20170103
	-- total = 1059
select count(distinct (eia_id)) from urdb_rates.utility_county_geoms_20170103
	-- total = 1059

