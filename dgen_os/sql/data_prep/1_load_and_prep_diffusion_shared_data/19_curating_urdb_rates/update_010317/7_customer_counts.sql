-- *****************************************************
-- Important Notes on Customer Counts
-- *****************************************************
-- I used a combination of 861 reports (from different years) to tag to utilities
	-- I started with 2014
	-- then looked at 2013, but it didn't add much to the number of missing customer counts, so i didnt end up using 2013
	-- then I looked at 2011 and it helped fill most of the missing gaps

-- Goal: determine the customer count per utility.
	-- we will later use these numbers to disaggregate utility customers to tracts
--------------------------------------------------------------------------------------------------------------------------------------


---------------------------------------------------------
-- Combine 2014 & 2011 Data
--------------------------------------------------------

-- 1. create view with utility regions that are missing customer counts
drop table if exists diffusion_data_shared.utils_missing_customer_counts_pt1_20170103 cascade;
create table diffusion_data_shared.utils_missing_customer_counts_pt1_20170103 as (
		with distinct_eia_id as (
			select distinct eia_id, state_abbr
			from diffusion_data_shared.urdb_rates_attrs_lkup_20170103),
		joins as (
			select a.utility_number, b.eia_id, b.state_abbr, cast(a.res_customers as int), cast(a.com_customers as int), cast(a.ind_customers as int)
			from eia.eia_861_2014_util_sales_cust a
			right join distinct_eia_id b
			on cast(a.utility_number as text) = b.eia_id and a.state = b.state_abbr
			order by a.utility_number desc),
		missing_cust_cnts as (
			select utility_number, eia_id, state_abbr from joins
			where (res_customers is null or res_customers = 0)
			and (com_customers is null or com_customers = 0)
			and (ind_customers is null or ind_customers = 0)
			order by state_abbr
			),
		not_missing_cust_cnts as (
			select utility_number, eia_id, state_abbr, res_customers, com_customers, ind_customers
			from joins
			where (res_customers is not null or res_customers != 0)
			and (com_customers is not null or com_customers != 0)
			and (ind_customers is not null or ind_customers != 0)
			order by state_abbr),
		distinct_gid as (
			select distinct a.util_reg_gid, a.eia_id, a.state_abbr, b.the_geom_96703 
			from diffusion_data_shared.urdb_rates_attrs_lkup_20170103 a
			left join diffusion_data_shared.urdb_rates_geoms_20170103 b
			on a.util_reg_gid = b.util_reg_gid),
		util_sector as (
			select distinct util_reg_gid, sector from  diffusion_data_shared.urdb_rates_attrs_lkup_20170103),
		gids_missing_cust_cnts as (
			select a.util_reg_gid, a.eia_id, a.state_abbr, a.the_geom_96703
			from distinct_gid a
			right join missing_cust_cnts b
			on a.eia_id = b.eia_id and a.state_abbr = b.state_abbr)
		select a.util_reg_gid, a.eia_id, a.state_abbr, --b.service_type
			a.the_geom_96703 
			from gids_missing_cust_cnts a
			left join eia.eia_861_2014_util_sales_cust b 
			on
				a.eia_id = cast(b.utility_number as text) and a.state_abbr = b.state);

-- check to see if these match up with the 2011 customer counts
	drop view if exists diffusion_data_shared.utils_with_customer_counts_20170103;
	create view diffusion_data_shared.utils_with_customer_counts_20170103 as (
		--get distinct eia_id for joining
		with distinct_eia_id as (
			select distinct eia_id, state_abbr
			from diffusion_data_shared.urdb_rates_attrs_lkup_20170103),
		-- join distinct_eia_id with 2014 customer data
		joins as (
			select a.utility_number, b.eia_id, b.state_abbr, 
				-- Add the customer counts by "Service Type" together
				sum(cast(a.res_customers as int)) as res_customers, 
				sum(cast(a.com_customers as int)) as com_customers, 
				sum(cast(a.ind_customers as int)) as ind_customers
			from eia.eia_861_2014_util_sales_cust a
			right join distinct_eia_id b
			on cast(a.utility_number as text) = b.eia_id and a.state = b.state_abbr
			group by a.utility_number, b.eia_id, b.state_abbr
			order by a.utility_number desc),
		-- identify which ids are not missing counts
		not_missing_cust_cnts as (
			select utility_number, eia_id, state_abbr, res_customers, com_customers, ind_customers
			from joins
			where (res_customers is not null or res_customers != 0)
			and (com_customers is not null or com_customers != 0)
			and (ind_customers is not null or ind_customers != 0)
			order by state_abbr),
		-- get distinct utility_reg_gid (+ attributes)
		distinct_gid as (
			select distinct a.util_reg_gid, a.eia_id, a.state_abbr, b.the_geom_96703 
			from diffusion_data_shared.urdb_rates_attrs_lkup_20170103 a
			left join diffusion_data_shared.urdb_rates_geoms_20170103 b
			on a.util_reg_gid = b.util_reg_gid),
		--util_sector as (
			--select distinct util_reg_gid, sector from diffusion_data_shared.urdb_rates_attrs_lkup_20170103),
		gids_not_missing_cust_cnts as (
			with part1 as (
				select distinct
					a.util_reg_gid, 
					a.eia_id, 
					a.state_abbr, 
					sum(b.res_customers) as res_customers, 
					sum(b.com_customers) as com_customers, 
					sum(b.ind_customers) as ind_customers, 
					a.the_geom_96703
			from distinct_gid a
			right join not_missing_cust_cnts b
			on a.eia_id = b.eia_id and a.state_abbr = b.state_abbr
			group by a.util_reg_gid, a.eia_id, a.state_abbr, a.the_geom_96703)
			select a.*--, b.service_type			
			from part1 a
			left join eia.eia_861_2014_util_sales_cust b 
			on
				a.eia_id = cast(b.utility_number as text) and a.state_abbr = b.state
			),
		-- Join with 2011 data (2011 data aligned with the missing_customer_counts table)
		file2 as (
			with part1 as (
				select distinct
					b.eia_id,
					a.state_code as state_abbr, 
					sum(a.residential_consumers) as res_customers, 
					sum(a.commercial_consumers) as com_customers,
					sum(a.industrial_consumers) as ind_customers
				from eia.eia_861_file_2_2011 a
				left join diffusion_data_shared.utils_missing_customer_counts_pt1_20170103 b
				on cast(a.utility_id as text)= b.eia_id and a.state_code = b.state_abbr
				where b.eia_id is not null
				group by b.eia_id, a.state_code
				),
			part2 as (
				select a.util_reg_gid, a.eia_id, a.state_abbr, b.res_customers, b.com_customers, b.ind_customers, a.the_geom_96703
				from distinct_gid a
				right join part1 b
				on a.eia_id = b.eia_id and a.state_abbr = b.state_abbr)
			select a.*--, b.service_type
			from part2 a
			left join eia.eia_861_file_2_2011 b
			on a.eia_id = cast(b.utility_id as text) and a.state_abbr = b.state_code)
-- 		file1 as (
-- 			with part1 as (
-- 				select distinct 
-- 					cast(utility_id as text) as eia_id, 
-- 					state_code as state_abbr,
-- 					residential_consumers as res_customers, 
-- 					commercial_consumers as com_customers,
-- 					industrial_consumers as ind_customers
-- 				from eia.eia_861_file_2_2011
-- 				where cast(utility_id as text) in
-- 					('25251', '3278', '40300', '26751', '25251', '40300', '3292', '40051', '26751', '26751', '40300', '25251', '13214', '25251', '26751', '40300', '14268', 'No eia id given', '25251', '25251', '26751', '27000', '6198', 'No eia id given', '14127', '3292', '5027', '17267', '26751', '12341', '20111', '3292', '4062', '942', '40299', '17184', '26751', '4062', 'No eia id given', '27000', 'No eia id given', '40300', 'No eia id given', '11235', '5553', '44372', '4062', '40382', '27000')
-- 				),
-- 			part2 as (
-- 				select a.util_reg_gid, a.eia_id, a.state_abbr, b.res_customers, b.com_customers, b.ind_customers, a.the_geom_96703
-- 				from distinct_gid a
-- 				right join part1 b
-- 				on a.eia_id = b.eia_id and a.state_abbr = b.state_abbr)
-- 			select a.*, b.service_type
-- 			from part2 a
-- 			left join eia.eia_861_file_1_2011 b
-- 			on a.eia_id = cast(b.utility_id as text) and a.state_abbr = b.state_code)
		select * from gids_not_missing_cust_cnts
		union all
		select * from file2
		--union all select * from file1
		);
	
-- remove utilities we found data for from the "missing" view	
	drop view if exists diffusion_data_shared.utils_missing_customer_counts_pt2_20170103;
	create view diffusion_data_shared.utils_missing_customer_counts_pt2_20170103 as (
		select 
			a.*, 
			b.eia_id as eia_id2, 
			res_customers, 
			com_customers, 
			ind_customers 
		from diffusion_data_shared.utils_missing_customer_counts_pt1_20170103 a
		left join diffusion_data_shared.utils_with_customer_counts_20170103 b
		on a.eia_id = b.eia_id
		where 
			b.eia_id is null
			and ((res_customers is null or res_customers = 0) 
				and (com_customers is null or com_customers = 0) 
				and (ind_customers is null or ind_customers = 0)));

-- count to compare
	select count(a.*) from diffusion_data_shared.utils_missing_customer_counts_pt1_20170103 a
	-- 473
	select count(b.*) from diffusion_data_shared.utils_missing_customer_counts_pt2_20170103 b
	-- 125
	select count(distinct b.eia_id) from diffusion_data_shared.utils_missing_customer_counts_pt2_20170103 b
	-- 1050 + 9 missing = 1059 -->total
--------------------------------------------
-- make final tables to speed things up later on
--------------------------------------------
	drop table if exists diffusion_data_shared.temp_utils_missing_customer_counts_20170103;
	create table diffusion_data_shared.temp_utils_missing_customer_counts_20170103 as (
		with u as (
			select distinct util_reg_gid, eia_id, sector, state_abbr, utility_type
			from diffusion_data_shared.urdb_rates_attrs_lkup_20170103)
		select a.util_reg_gid, a.eia_id, a.state_abbr, b.sector, b.utility_type, a.the_geom_96703
		from diffusion_data_shared.utils_missing_customer_counts_pt2_20170103 a
		left join u b
		on a.util_reg_gid = b.util_reg_gid
		order by a.util_reg_gid, a.state_abbr, b.sector, b.utility_type);

	-- B. Customer Count Table
	drop table if exists diffusion_data_shared.temp_utils_with_customer_counts_20170103;
	create table diffusion_data_shared.temp_utils_with_customer_counts_20170103 as ( 
		with u1 as (
			select distinct util_reg_gid, eia_id, sector, state_abbr, utility_type
			from diffusion_data_shared.urdb_rates_attrs_lkup_20170103),
		u2 as (
			select distinct * from diffusion_data_shared.utils_with_customer_counts_20170103),
		res as (
			select 
				a.util_reg_gid,
				a.eia_id, --a.service_type,
		 		a.state_abbr, 
		 		'R'::text as sector, 
		 		b.utility_type, 
		 		a.res_customers as cust_cnt,
		 		a.the_geom_96703
			from u2 a
			left join u1 b
			on a.util_reg_gid = b.util_reg_gid
			where b.sector = 'R'
			),
		com as (
			select 
				a.util_reg_gid,
				a.eia_id, --a.service_type,
		 		a.state_abbr, 
		 		'C'::text as sector, 
		 		b.utility_type, 
		 		a.com_customers as cust_cnt,
		 		a.the_geom_96703
			from u2 a
			left join u1 b
			on a.util_reg_gid = b.util_reg_gid
			where b.sector = 'C'
			),
		ind as (
			select 
				a.util_reg_gid,
				a.eia_id, --a.service_type,
		 		a.state_abbr, 
		 		'I'::text as sector, 
		 		b.utility_type, 
		 		a.ind_customers as cust_cnt,
		 		a.the_geom_96703
			from u2 a
			left join u1 b
			on a.util_reg_gid = b.util_reg_gid
			where b.sector = 'I'
			)
		select * from res 
		union all
		select * from com 
		union all
		select * from ind
		order by util_reg_gid, state_abbr, sector, utility_type);

-------------------
-- Clean Up
-------------------
-- drop temp views 
	drop view if exists diffusion_data_shared.utils_missing_customer_counts_pt1_20170103 cascade;
-- Update null values
	

-----------------
-- Sanity Checks
-----------------
	select count(distinct eia_id) from diffusion_data_shared.temp_utils_with_customer_counts_20170103;
	--1113 + 10 missing = 1123 which the total!
	-- 1050 + 9 missing = 1059
	select count(*) from diffusion_data_shared.temp_utils_missing_customer_counts_20170103 where state_abbr = 'CA';
	-- 0 = there are no missing utility cnts from CA (GOod!!)
	--------------------------------
	-- ** check service types **
	--------------------------------
		-- Note: I need to uncomment out the "service_type" text when creating the views for code to run successfully
--		with a as (
--			with a as (
--				select distinct eia_id 
--				from diffusion_data_shared.temp_utils_with_customer_counts_20170103),
--			d as (
--				select distinct eia_id, (service_type = 'Delivery')::boolean as delivery from diffusion_data_shared.temp_utils_with_customer_counts_20170103 where (service_type = 'Delivery') = true),
--			b as (
--				select distinct eia_id, (service_type = 'Bundled' or service_type = 'Bundle')::boolean as bundled 
--				from diffusion_data_shared.temp_utils_with_customer_counts_20170103 where (service_type = 'Bundled' or service_type = 'Bundle') = true),
--			e as (select distinct eia_id, (service_type = 'Energy')::boolean as energy from diffusion_data_shared.temp_utils_with_customer_counts_20170103 where (service_type = 'Energy') = True)
--			select a.eia_id, d.delivery, b.bundled, e.energy
--			from a
--			left join d on d.eia_id = a.eia_id
--			left join b on b.eia_id = a.eia_id
--			left join e on e.eia_id = a.eia_id
--			),
--		b as (
--		select eia_id, count(case when delivery is not null then delivery end) as delivery_count, count(case when bundled is not null then bundled end) as bundle_count, count(case when energy is not null then energy end) as energy_count
--		from a
--		group by eia_id)
--		--select * from b where energy_count > 0 -- 1 row: "12341" (1
--		--select * from b where delivery_count > 0 -- 49 rows; 45 of which are delivery AND bundle
--		select * from b where delivery_count > 0 and bundle_count = 0 -- 4 rows ("5609", "8883", "11522", "1179")
