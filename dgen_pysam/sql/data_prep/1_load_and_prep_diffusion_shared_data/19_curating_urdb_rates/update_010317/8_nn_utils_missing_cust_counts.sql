-- *****************************************************
-- Important Notes on Nearest Neighbor
-- *****************************************************
-- We know that we are missing 31
-- Nearest neighbor performed on two seperate "objects":
	-- 1. nearest neighbor for those utilities where we were missing counts for a specific sector (but where we have the counts for their other sectors)
	-- 2. nearest neighbor for those utilities that never matched up with the 861 tables
-- Nearest neighbor:
	-- we took the average customer counts for all utilies of the same type and sector within the same state and within 50-miles of the utility in question

--------------------------------------------------------------------------------------------------------------------------------------

-----------------------------------------------------
-- 1. Perfrom NN & Merge with known customer counts 
-----------------------------------------------------
	drop table if exists diffusion_data_shared.utils_with_customer_counts_20170103;
	create table diffusion_data_shared.utils_with_customer_counts_20170103 as (
		with 
		-- Identify which records are missing counts for a sector
		not_missing_null as (
			select * 
			from diffusion_data_shared.temp_utils_with_customer_counts_20170103
			where cust_cnt is null
			order by eia_id),
		-- Identify which recrods are not missing data
		not_missing_not_null as (
			select * 
			from diffusion_data_shared.temp_utils_with_customer_counts_20170103
			where cust_cnt is not null order by eia_id
			),
		-- Perform NN on not_missing_null to see if we can find some customer counts
		nn1 as (
			select 
				a.util_reg_gid, 
				a.eia_id,
				a.state_abbr, 
				a.sector, 
				a.utility_type, 
				avg(b.cust_cnt) as cust_cnt, 
				a.the_geom_96703
			from not_missing_null a
			left join not_missing_not_null b
			on 
				a.utility_type = b.utility_type and
				st_distance(a.the_geom_96703, b.the_geom_96703) <= 80467.2 and 
				a.sector = b.sector and
				a.state_abbr = b.state_abbr
			group by 
				a.util_reg_gid,
				a.eia_id,
				a.state_abbr,
				a.sector,
				a.utility_type,
				a.the_geom_96703
			),
		-- Perform NN on those ids that we had no 861 data for
		nn2 as (
			select 
				a.util_reg_gid, 
				a.eia_id,
				a.state_abbr, 
				a.sector, 
				a.utility_type, 
				avg(b.cust_cnt) as cust_cnt, 
				a.the_geom_96703
			from diffusion_data_shared.temp_utils_missing_customer_counts_20170103 a
			left join diffusion_data_shared.temp_utils_with_customer_counts_20170103 b
			on 
				a.utility_type = b.utility_type and
				st_distance(a.the_geom_96703, b.the_geom_96703) <= 80467.2 and 
				a.sector = b.sector and
				a.state_abbr = b.state_abbr
			group by 
				a.util_reg_gid,
				a.eia_id,
				a.state_abbr,
				a.sector,
				a.utility_type,
				a.the_geom_96703
			),
		x as (
		select * from not_missing_not_null
		union all
		select * from nn1
		union all
		select * from nn2
		order by util_reg_gid, state_abbr, sector, utility_type, cust_cnt)
		select distinct util_reg_gid, eia_id, state_abbr, sector, utility_type, cust_cnt);

update diffusion_data_shared.utils_with_customer_counts_20170103 a 
set utility_type = (select b.utility_type from diffusion_data_shared.utils_with_customer_counts_20161005 b where a.eia_id = b.eia_id and a.state_abbr = b.state_abbr and a.sector = b.sector)
where a.cust_cnt is null

update diffusion_data_shared.utils_with_customer_counts_20170103 a 
set cust_cnt = (select b.cust_cnt from diffusion_data_shared.utils_with_customer_counts_20161005 b where a.eia_id = b.eia_id and a.state_abbr = b.state_abbr and a.sector = b.sector)
where a.cust_cnt is null
--------------------------------------------------
-- 2. Sanity Checks
--------------------------------------------------
	-- 1. check total eia_id count
		select count (distinct eia_id) from diffusion_data_shared.utils_with_customer_counts_20170103
		-- total = 1059 (good)
	-- 2. Check duplicates
	-- 3. check if there are any null values for customer counts (for all sectors)
		select * from diffusion_data_shared.utils_with_customer_counts_20170103
		where cust_cnt is null order by eia_id
			-- 28 rows are null
			-- affects 6 utility companies:
			--	"11235"
			-- "26751"
			-- "5553"
			-- "8022"
			-- "925"
			-- "No eia id given"


		-- I'm going to leave these as null for now unless we come up with some other way to treat these

	-- 3. QGIS --> Note -- I checked in QGIS and nearest neighbor worked great
		-- within 50 miles, with the same utility type, same sector, and same state

--------------------------------------------------
-- 2.  Clean Up
--------------------------------------------------
-- Delete temporary tables:
drop table if exists diffusion_data_shared.temp_utils_with_customer_counts_20170103;
drop table if exists diffusion_data_shared.temp_utils_missing_customer_counts_20170103;

-- Change owner
alter table diffusion_data_shared.utils_with_customer_counts_20170103
owner to "diffusion-writers";

-- Fix utility type issue for DC Rates
update diffusion_data_shared.utils_with_customer_counts_20170103 
set utility_type = 'Investor Owned'
where eia_id = '15270';
	-- Note -- in the future, we will need to find another way to join utility_type to the table rather than using the previous version of the rates table because if there are new utilities, then we run into this issue