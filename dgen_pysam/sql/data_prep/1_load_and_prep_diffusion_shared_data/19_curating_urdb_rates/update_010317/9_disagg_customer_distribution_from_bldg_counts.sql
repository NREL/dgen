-- *****************************************************
-- Important Notes on Disaggregation
-- *****************************************************
-- Unknown -> The distribution of customers within a utility territory
-- Known --> the distribution of agents (by tract and by county)

-- ** Big Picture Solution **:
--	* We need to use the distribution of # of agents (by county) to figure out the distribution of customers within a utility
-- 			* we are using distribution of # of agents (by county) to figure out the distribution of customers belonging to a utility TYPE
-- NOTE -- as of 1/3/17, we are using counties (not tracts) because this will speed up processing times later on

-- Check for Null Values *****
	-- we will need to perform another NN if we find nulls
--------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------
-- 1. Get the distribution of Agents Per Tract
------------------------------------------------
-- NOTE -- THIS TAKES FOREVER. NO NEED TO RECREATE
-- drop table if exists diffusion_data_shared.tract_bldg_counts;
-- create table diffusion_data_shared.tract_bldg_counts as (
-- 	select b.state_abbr, b.state_fips, b.county_fips, b.tract_fips, d.tract_id_alias,
-- 		sum(c.bldg_count_res) as bldg_count_res, 
-- 		sum(c.bldg_count_com) as bldg_count_com,
-- 		sum(c.bldg_count_ind) as bldg_count_ind
-- 	from diffusion_blocks.blocks_res a
-- 	left join diffusion_blocks.block_geoms b
-- 	on a.pgid = b.pgid
-- 	left join diffusion_blocks.block_bldg_counts c
-- 	on a.pgid = c.pgid
-- 	left join diffusion_blocks.tract_geoms d
-- 	on b.tract_fips = d.tract_fips and d.county_fips = b.county_fips and d.state_fips = b.state_fips
-- 	group by b.state_abbr, b.state_fips, b.county_fips, b.tract_fips, d.tract_id_alias);

-- create indices
create index tract_bldg_counts_state_fips on diffusion_data_shared.tract_bldg_counts using btree(state_fips);
create index tract_bldg_counts_tract_fips on diffusion_data_shared.tract_bldg_counts using btree(tract_fips);
create index tract_bldg_counts_tract_id_alias on diffusion_data_shared.tract_bldg_counts using btree(tract_id_alias);
create index tract_bldg_counts_county_fips on diffusion_data_shared.tract_bldg_counts using btree(county_fips);


------------------------------------------------
-- 1b. Get the distribution of Agents Per County
------------------------------------------------
-- NOTE -- THIS TAKES FOREVER. NO NEED TO RECREATE
drop table if exists diffusion_data_shared.cnty_bldg_counts;
create table diffusion_data_shared.cnty_bldg_counts as (
	select b.state_abbr, b.state_fips, b.county_fips,
		sum(c.bldg_count_res) as bldg_count_res, 
		sum(c.bldg_count_com) as bldg_count_com,
		sum(c.bldg_count_ind) as bldg_count_ind
	from diffusion_blocks.blocks_res a
	left join diffusion_blocks.block_geoms b
	on a.pgid = b.pgid
	left join diffusion_blocks.block_bldg_counts c
	on a.pgid = c.pgid
	left join diffusion_blocks.tract_geoms d
	on d.county_fips = b.county_fips and d.state_fips = b.state_fips
	group by b.state_abbr, b.state_fips, b.county_fips);

-- create indices
create index cnty_bldg_counts_state_fips on diffusion_data_shared.cnty_bldg_counts using btree(state_fips);
create index cnty_bldg_counts_cnty_fips on diffusion_data_shared.cnty_bldg_counts using btree(cnty_fips);
create index cnty_bldg_counts_cnty_id_alias on diffusion_data_shared.cnty_bldg_counts using btree(cnty_id_alias);
create index cnty_bldg_counts_county_fips on diffusion_data_shared.cnty_bldg_counts using btree(county_fips);


-----------------------------------------------------------------------
-- 2. For Each Sector, Get the Distribution of County Customers Counts
	   	-- based on Bldg Count County Distribution
-----------------------------------------------------------------------

-- **************
-- For CA:
-- **************
	-- we need to build the total counts per utility from the blocks up
	-- Do for only those that have sub regions (?)
	-- Not sure how to do this???
	-- TODO -- what if/ not sure I did this right??? CHECK************************************!!!!!!!!


-----------------------------------------------------------------------
-- 2. For Each Sector, Get the Distribution of County Customers Counts
	   	-- based on Bldg Count County Distribution
-----------------------------------------------------------------------
	---------------------------
	-- ** Residential **
	---------------------------
		drop table if exists diffusion_data_shared.tract_util_type_weight_res; --**
		create table diffusion_data_shared.tract_util_type_weight_res as --**
			(
			-- 1. Select the residential utilities
			with sector_utilities as 
				( -- join to get state fips
				select distinct
					a.util_reg_gid, 
					a.eia_id, 
					a.state_abbr, 
					b.state_fips,
					a.utility_type, 
					a.sector,
					a.cust_cnt
				from diffusion_data_shared.utils_with_customer_counts_20170103 a
				left join diffusion_blocks.county_geoms b
				on a.state_abbr = b.state_abbr
				where a.sector = 'R' -- **
				),
			-- 2. Identify which Utilies belong to which Tract
			utility_tracts as 
				(
				-- 2A. Identify tracts for non subregion utilities:
				with no_ca_utility_tracts as 
		 			(
	 				-- 2.A.1. identify the counties using the utility to county lkup table
	 				with cnty as 
	 					(
						select distinct
							b.util_reg_gid,
							a.eia_id,
							a.state_abbr,
							a.state_fips,
							a.county_fips,
							b.sector
						from urdb_rates.utility_county_geoms_20170103 a
						inner join sector_utilities b
						on a.eia_id = b.eia_id and a.state_fips = b.state_fips
						where utility_region is null
						),

					-- 2.A.2. knowing the counties, identify the tracts (for each utility)
					tracts as (
						select distinct
							a.util_reg_gid,
							a.eia_id,
							a.sector,
							a.state_abbr,
							a.state_fips,
							a.county_fips,
							b.tract_fips,
							b.tract_id_alias
						from cnty a
						left join diffusion_blocks.tract_geoms b
						on a.state_fips = b.state_fips and a.county_fips = b.county_fips
						)
					select * from tracts
					),
				-- 2.B. Identify tracts for subregion utilities (CA ONlY):
				ca_utility_tracts as 
					(
						-- 2.A.1. identify the counties using the CA sub region tracts to util tagging
						with main_join as 
							(
							select distinct
								a.util_reg_gid,
								b.eia_id,
								b.sector,
								b.state_abbr,
								b.state_fips,
								a.tract_id_alias
							from diffusion_data_shared.ca_subregion_tracts_to_util_reg a
							inner join sector_utilities b
							on a.util_reg_gid = b.util_reg_gid
							)

						-- 2.B.1. identify the county and tract fips
						select distinct
							a.util_reg_gid,
							a.eia_id,
							a.sector,
							a.state_abbr,
							a.state_fips,
							b.county_fips,
							b.tract_fips,
							a.tract_id_alias
						from main_join a
						left join diffusion_blocks.tract_geoms b
						on a.tract_id_alias = b.tract_id_alias
					)

				-- Merge CA and Non-CA together
				select * from ca_utility_tracts
				union all
				select * from no_ca_utility_tracts
				),

			-- Now we need to use these utility counties to find the agent distribution (tracts)
			agent_counts_by_tract_by_utility as 
				(
				select 
					a.util_reg_gid,
					a.eia_id,
					b.state_abbr,
					a.state_fips,
					a.county_fips,
					a.tract_fips,
					a.tract_id_alias,
					(case when b.bldg_count_res = 0 then null else b.bldg_count_res end) as bldg_count_res --**
				from utility_tracts a
				left join diffusion_data_shared.tract_bldg_counts b
				on 
					a.state_fips = b.state_fips 
					and 
					a.county_fips = b.county_fips
					and 
					a.tract_id_alias = b.tract_id_alias
				),
			-- use sector_utilities to find the total customer count per utility (sum)
			sum_agents_per_utility as 
				(
				select 
					util_reg_gid,
					sum(bldg_count_res) as sum_bldg_count_res
				from agent_counts_by_tract_by_utility
				group by
					util_reg_gid
				),
			pct_agents_per_utility as 
				(
				select 
					a.util_reg_gid,
					a.eia_id,
					a.state_abbr,
					a.state_fips,
					a.county_fips,
					a.tract_fips,
					a.tract_id_alias,
					(a.bldg_count_res/b.sum_bldg_count_res) as pct_bldg_counts_res
				from agent_counts_by_tract_by_utility a 
				left join sum_agents_per_utility b
				on a.util_reg_gid = b.util_reg_gid
				),
			-- Multiply the bldg % by the utility customer count to get a customer count weight
			util_cust_count_weight as 
				(
				select
				 	a.util_reg_gid,
					a.eia_id,
					a.state_abbr,
					a.state_fips,
					a.county_fips,
					a.tract_fips,
					a.tract_id_alias,
					round((b.cust_cnt/a.pct_bldg_counts_res), 0) as cust_cnt_weight
				from pct_agents_per_utility a 
				left join sector_utilities b
				on a.util_reg_gid = b.util_reg_gid
				),
			util_type_cust_count_weight as (
				select 
					a.state_fips,
					a.county_fips,
					a.tract_fips,
					a.tract_id_alias,
					b.utility_type,
					round(sum(a.cust_cnt_weight), 0) as util_type_weight
				from util_cust_count_weight a 
				left join sector_utilities b
				on a.util_reg_gid = b.util_reg_gid
				group by 
					a.state_fips,
					a.county_fips,
					a.tract_id_alias,
					a.tract_fips,
					b.utility_type
				)
			select * from util_type_cust_count_weight
			order by state_fips, county_fips, tract_fips
		);

	---------------------------
	-- ** Commercial **
	---------------------------
		drop table if exists diffusion_data_shared.tract_util_type_weight_com; --**
		create table diffusion_data_shared.tract_util_type_weight_com as --**
			(
			-- 1. Select the residential utilities
			with sector_utilities as 
				( -- join to get state fips
				select distinct
					a.util_reg_gid, 
					a.eia_id, 
					a.state_abbr, 
					b.state_fips,
					a.utility_type, 
					a.sector,
					a.cust_cnt
				from diffusion_data_shared.utils_with_customer_counts_20170103 a
				left join diffusion_blocks.county_geoms b
				on a.state_abbr = b.state_abbr
				where sector = 'C' -- **
				),
			-- 2. Identify which Utilies belong to which Tract
			utility_tracts as 
				(
				-- 2A. Identify tracts for non subregion utilities:
				with no_ca_utility_tracts as 
		 			(
	 				-- 2.A.1. identify the counties using the utility to county lkup table
	 				with cnty as 
	 					(
						select distinct
							b.util_reg_gid,
							a.eia_id,
							a.state_abbr,
							a.state_fips,
							a.county_fips,
							b.sector
						from urdb_rates.utility_county_geoms_20170103 a
						inner join sector_utilities b
						on a.eia_id = b.eia_id and a.state_fips = b.state_fips
						where utility_region is null
						),

					-- 2.A.2. knowing the counties, identify the tracts (for each utility)
					tracts as (
						select distinct
							a.util_reg_gid,
							a.eia_id,
							a.sector,
							a.state_abbr,
							a.state_fips,
							a.county_fips,
							b.tract_fips,
							b.tract_id_alias
						from cnty a
						left join diffusion_blocks.tract_geoms b
						on a.state_fips = b.state_fips and a.county_fips = b.county_fips
						)
					select * from tracts
					),
				-- 2.B. Identify tracts for subregion utilities:
				ca_utility_tracts as 
					(
						-- 2.A.1. identify the counties using the CA sub region tracts to util tagging
						with main_join as 
							(
							select distinct
								a.util_reg_gid,
								b.eia_id,
								b.sector,
								b.state_abbr,
								b.state_fips,
								a.tract_id_alias
							from diffusion_data_shared.ca_subregion_tracts_to_util_reg a
							inner join sector_utilities b
							on a.util_reg_gid = b.util_reg_gid
							)

						-- 2.B.1. identify the county and tract fips
						select distinct
							a.util_reg_gid,
							a.eia_id,
							a.sector,
							a.state_abbr,
							a.state_fips,
							b.county_fips,
							b.tract_fips,
							a.tract_id_alias
						from main_join a
						left join diffusion_blocks.tract_geoms b
						on a.tract_id_alias = b.tract_id_alias
					)

				-- Merge CA and Non-CA together
				select * from ca_utility_tracts
				union all
				select * from no_ca_utility_tracts
				),

			-- Now we need to use these utility counties to find the agent distribution (tracts)
			agent_counts_by_tract_by_utility as 
				(
				select 
					a.util_reg_gid,
					a.eia_id,
					b.state_abbr,
					a.state_fips,
					a.county_fips,
					a.tract_fips,
					a.tract_id_alias,
					(case when b.bldg_count_com = 0 then null else b.bldg_count_com end) as bldg_count_com
				from utility_tracts a
				left join diffusion_data_shared.tract_bldg_counts b
				on 
					a.state_fips = b.state_fips 
					and 
					a.county_fips = b.county_fips
					and 
					a.tract_id_alias = b.tract_id_alias
				),
			-- use sector_utilities to find the total customer count per utility (sum)
			sum_agents_per_utility as 
				(
				select 
					util_reg_gid,
					sum(bldg_count_com) as sum_bldg_count_com
				from agent_counts_by_tract_by_utility
				group by
					util_reg_gid
				),
			pct_agents_per_utility as 
				(
				select 
					a.util_reg_gid,
					a.eia_id,
					a.state_abbr,
					a.state_fips,
					a.county_fips,
					a.tract_fips,
					a.tract_id_alias,
					(a.bldg_count_com/b.sum_bldg_count_com) as pct_bldg_counts_com
				from agent_counts_by_tract_by_utility a 
				left join sum_agents_per_utility b
				on a.util_reg_gid = b.util_reg_gid
				),
			-- Multiply the bldg % by the utility customer count to get a customer count weight
			util_cust_count_weight as 
				(
				select
				 	a.util_reg_gid,
					a.eia_id,
					a.state_abbr,
					a.state_fips,
					a.county_fips,
					a.tract_fips,
					a.tract_id_alias,
					round((b.cust_cnt/a.pct_bldg_counts_com), 0) as cust_cnt_weight
				from pct_agents_per_utility a 
				left join sector_utilities b
				on a.util_reg_gid = b.util_reg_gid
				),
			util_type_cust_count_weight as (
				select 
					a.state_fips,
					a.county_fips,
					a.tract_fips,
					a.tract_id_alias,
					b.utility_type,
					round(sum(a.cust_cnt_weight), 0) as util_type_weight
				from util_cust_count_weight a 
				left join sector_utilities b
				on a.util_reg_gid = b.util_reg_gid
				group by 
					a.state_fips,
					a.county_fips,
					a.tract_id_alias,
					a.tract_fips,
					b.utility_type
				)
			select * from util_type_cust_count_weight
			order by state_fips, county_fips, tract_fips
		);

	---------------------------
	-- ** Industrial **
	---------------------------
		drop table if exists diffusion_data_shared.tract_util_type_weight_ind; --**
		create table diffusion_data_shared.tract_util_type_weight_ind as --**
			(
			-- 1. Select the residential utilities
			with sector_utilities as 
				( -- join to get state fips
				select distinct
					a.util_reg_gid, 
					a.eia_id, 
					a.state_abbr, 
					b.state_fips,
					a.utility_type, 
					a.sector,
					a.cust_cnt
				from diffusion_data_shared.utils_with_customer_counts_20170103 a
				left join diffusion_blocks.county_geoms b
				on a.state_abbr = b.state_abbr
				where sector = 'I' -- **
				),
			-- 2. Identify which Utilies belong to which Tract
			utility_tracts as 
				(
				-- 2A. Identify tracts for non subregion utilities:
				with no_ca_utility_tracts as 
		 			(
	 				-- 2.A.1. identify the counties using the utility to county lkup table
	 				with cnty as 
	 					(
						select distinct
							b.util_reg_gid,
							a.eia_id,
							a.state_abbr,
							a.state_fips,
							a.county_fips,
							b.sector
						from urdb_rates.utility_county_geoms_20170103 a
						inner join sector_utilities b
						on a.eia_id = b.eia_id and a.state_fips = b.state_fips
						where utility_region is null
						),

					-- 2.A.2. knowing the counties, identify the tracts (for each utility)
					tracts as (
						select distinct
							a.util_reg_gid,
							a.eia_id,
							a.sector,
							a.state_abbr,
							a.state_fips,
							a.county_fips,
							b.tract_fips,
							b.tract_id_alias
						from cnty a
						left join diffusion_blocks.tract_geoms b
						on a.state_fips = b.state_fips and a.county_fips = b.county_fips
						)
					select * from tracts
					),
				-- 2.B. Identify tracts for subregion utilities:
				ca_utility_tracts as 
					(
						-- 2.A.1. identify the counties using the CA sub region tracts to util tagging
						with main_join as 
							(
							select distinct
								a.util_reg_gid,
								b.eia_id,
								b.sector,
								b.state_abbr,
								b.state_fips,
								a.tract_id_alias
							from diffusion_data_shared.ca_subregion_tracts_to_util_reg a
							inner join sector_utilities b
							on a.util_reg_gid = b.util_reg_gid
							)

						-- 2.B.1. identify the county and tract fips
						select distinct
							a.util_reg_gid,
							a.eia_id,
							a.sector,
							a.state_abbr,
							a.state_fips,
							b.county_fips,
							b.tract_fips,
							a.tract_id_alias
						from main_join a
						left join diffusion_blocks.tract_geoms b
						on a.tract_id_alias = b.tract_id_alias
					)

				-- Merge CA and Non-CA together
				select * from ca_utility_tracts
				union all
				select * from no_ca_utility_tracts
				),

			-- Now we need to use these utility counties to find the agent distribution (tracts)
			agent_counts_by_tract_by_utility as 
				(
				select 
					a.util_reg_gid,
					a.eia_id,
					b.state_abbr,
					a.state_fips,
					a.county_fips,
					a.tract_fips,
					a.tract_id_alias,
					(case when b.bldg_count_ind = 0 then null else b.bldg_count_ind end) as bldg_count_ind
				from utility_tracts a
				left join diffusion_data_shared.tract_bldg_counts b
				on 
					a.state_fips = b.state_fips 
					and 
					a.county_fips = b.county_fips
					and 
					a.tract_id_alias = b.tract_id_alias
				),
			-- use sector_utilities to find the total customer count per utility (sum)
			sum_agents_per_utility as 
				(
				select 
					util_reg_gid,
					sum(bldg_count_ind) as sum_bldg_count_ind
				from agent_counts_by_tract_by_utility
				group by
					util_reg_gid
				),
			pct_agents_per_utility as 
				(
				select 
					a.util_reg_gid,
					a.eia_id,
					a.state_abbr,
					a.state_fips,
					a.county_fips,
					a.tract_fips,
					a.tract_id_alias,
					(a.bldg_count_ind/b.sum_bldg_count_ind) as pct_bldg_counts_ind
				from agent_counts_by_tract_by_utility a 
				left join sum_agents_per_utility b
				on a.util_reg_gid = b.util_reg_gid
				),
			-- Multiply the bldg % by the utility customer count to get a customer count weight
			util_cust_count_weight as 
				(
				select
				 	a.util_reg_gid,
					a.eia_id,
					a.state_abbr,
					a.state_fips,
					a.county_fips,
					a.tract_fips,
					a.tract_id_alias,
					round((b.cust_cnt/a.pct_bldg_counts_ind), 0) as cust_cnt_weight
				from pct_agents_per_utility a 
				left join sector_utilities b
				on a.util_reg_gid = b.util_reg_gid
				),
			util_type_cust_count_weight as (
				select 
					a.state_fips,
					a.county_fips,
					a.tract_fips,
					a.tract_id_alias,
					b.utility_type,
					round(sum(a.cust_cnt_weight), 0) as util_type_weight
				from util_cust_count_weight a 
				left join sector_utilities b
				on a.util_reg_gid = b.util_reg_gid
				group by 
					a.state_fips,
					a.county_fips,
					a.tract_id_alias,
					a.tract_fips,
					b.utility_type
				)
			select * from util_type_cust_count_weight
			order by state_fips, county_fips, tract_fips
		);

-- Alter Owner
	alter table diffusion_data_shared.tract_util_type_weight_com
	owner to "diffusion-writers";
	alter table diffusion_data_shared.tract_util_type_weight_res
	owner to "diffusion-writers";
	alter table diffusion_data_shared.tract_util_type_weight_ind
	owner to "diffusion-writers";

-- Drop Null Values
	delete from diffusion_data_shared.tract_util_type_weight_res
	where util_type_weight is null;
	delete from diffusion_data_shared.tract_util_type_weight_com
	where util_type_weight is null;
	delete from diffusion_data_shared.tract_util_type_weight_ind
	where util_type_weight is null;

-- Update Type utility names to short hand
	update diffusion_data_shared.tract_util_type_weight_res
	set utility_type = case 
		when utility_type = 'Investor Owned' then 'IOU'
		when utility_type = 'Other' then 'Other'
		when utility_type = 'Municipal' then 'Muni'
		when utility_type = 'Cooperative' then 'Coop'
		end;
	update diffusion_data_shared.tract_util_type_weight_com
	set utility_type = case 
		when utility_type = 'Investor Owned' then 'IOU'
		when utility_type = 'Other' then 'Other'
		when utility_type = 'Municipal' then 'Muni'
		when utility_type = 'Cooperative' then 'Coop'
		end;
	update diffusion_data_shared.tract_util_type_weight_ind
	set utility_type = case 
		when utility_type = 'Investor Owned' then 'IOU'
		when utility_type = 'Other' then 'Other'
		when utility_type = 'Municipal' then 'Muni'
		when utility_type = 'Cooperative' then 'Coop'
		end;


--------------------------------------------------------------------------------------------------------------------------------------
diffusion_shared.tract_util_type_weights_

--------------------------------------------------------------------------------------------------------------------------------------
---- QAQC
--	select count(*) from diffusion_data_shared.tract_util_type_weight_com
--	-- COM = 111,860

--	select count(*) from diffusion_data_shared.tract_util_type_weight_res
--	-- RES = 102,332

--	select count(*) from diffusion_data_shared.tract_util_type_weight_ind
--	-- IND = 75,098
--	--

--	-- Does it make sense that there are more commercial than residential?--

--	-- Create temporary table to examine in QGIS:
--	drop table diffusion_data_shared.temp_qaqc;
--	create table diffusion_data_shared.temp_qaqc as (
--		with i as (
--			select 
--				a.*, 
--				'I'::text as sector, 
--				b.the_geom_96703 
--			from diffusion_data_shared.tract_util_type_weight_ind a
--			left join diffusion_blocks.tract_geoms b
--			on a.tract_id_alias = b.tract_id_alias),
--		r as (
--			select 
--				a.*, 
--				'R'::text as sector, 
--				b.the_geom_96703 
--			from diffusion_data_shared.tract_util_type_weight_res a
--			left join diffusion_blocks.tract_geoms b
--			on a.tract_id_alias = b.tract_id_alias),
--		c as (
--			select 
--				a.*, 
--				'C'::text as sector, 
--				b.the_geom_96703 
--			from diffusion_data_shared.tract_util_type_weight_com a
--			left join diffusion_blocks.tract_geoms b
--			on a.tract_id_alias = b.tract_id_alias)
--		select * from i
--		union all
--		select * from r
--		union all
--		select * from c
--		);--

--	-- Check CA utilies
--		-- Check CA utility where utility = xyz--

--	-- Check the total number of tracts by utility type (there should only be 3 or less, for com/res/ind) 
--		with a as (select tract_id_alias, utility_type, count(*) as cnt from diffusion_data_shared.temp_qaqc
--		group by tract_id_alias, utility_type) select * from a where cnt > 3
--			-- results = 0 (Good)--

--	-- Check the total number of tracts by sector (there shouldnt be more than 4, for each utility type)
--		with a as (select tract_id_alias, sector, count(*) as cnt from diffusion_data_shared.temp_qaqc
--		group by tract_id_alias, sector) select * from a where cnt > 4


--------------------------------------------------------------------------------------------------------------------------------------
-- QAQC Part 2:

--	-- A.Count the number of tracts by Sector to see if we have the full coverage of tracts for all sectors
--			with com as (
--				with b as (
--					select a.pgid, b.tract_fips, b.state_fips, b.county_fips
--					from diffusion_blocks.blocks_com a
--					left join diffusion_blocks.block_geoms b
--					on a.pgid = b.pgid)
--				select count (distinct a.tract_id_alias) from 
--				diffusion_blocks.tract_geoms a
--				right join b
--				on a.state_fips = b.state_fips and a.county_fips = b.county_fips and a.tract_fips = b.tract_fips),
--			ind as (
--				with b as (
--					select a.pgid, b.tract_fips, b.state_fips, b.county_fips
--					from diffusion_blocks.blocks_ind a
--					left join diffusion_blocks.block_geoms b
--					on a.pgid = b.pgid)
--				select count (distinct a.tract_id_alias) from 
--				diffusion_blocks.tract_geoms a
--				right join b
--				on a.state_fips = b.state_fips and a.county_fips = b.county_fips and a.tract_fips = b.tract_fips),	
--			res as (
--				with b as (
--					select a.pgid, b.tract_fips, b.state_fips, b.county_fips
--					from diffusion_blocks.blocks_res a
--					left join diffusion_blocks.block_geoms b
--					on a.pgid = b.pgid)
--				select count (distinct a.tract_id_alias) from 
--				diffusion_blocks.tract_geoms a
--				right join b
--				on a.state_fips = b.state_fips and a.county_fips = b.county_fips and a.tract_fips = b.tract_fips)
--			select a.count as com, b.count as ind, c.count as res
--			from com a, ind b, res c
--		-- Result (total number of tracts)
--			--  com  |  ind  |  res  
--			-- -------+-------+-------
--			-- 72587 | 70796 | 72205--

--	-- B. Count the total number of tracts we got after disaggregating
--		with com as (
--			select count(distinct tract_id_alias) from diffusion_data_shared.tract_util_type_weight_com),
--		ind as (
--			select count(distinct tract_id_alias) from diffusion_data_shared.tract_util_type_weight_ind),
--		res as (
--			select count(distinct tract_id_alias) from diffusion_data_shared.tract_util_type_weight_res)
--		select a.count as com, b.count as ind, c.count as res
--		from com a, ind b, res c
--			--  com  |  ind  |  res  
--			-- -------+-------+-------
--			-- 69964 | 56226 | 69214



-----------------------------------------------------------------------
-- 2. For Each Sector, Get the Distribution of County Customers Counts
	   	-- based on Bldg Count County Distribution
-----------------------------------------------------------------------

-- **************
-- For CA:
-- **************
	-- we need to build the total counts per utility from the blocks up
	-- Do for only those that have sub regions (?)
	-- Not sure how to do this???
	-- TODO -- what if/ not sure I did this right??? CHECK************************************!!!!!!!!


-----------------------------------------------------------------------
-- 2b. COUNTY For Each Sector, Get the Distribution of County Customers Counts
	   	-- based on Bldg Count County Distribution
-----------------------------------------------------------------------
	---------------------------
	-- ** Residential **
	---------------------------
	drop table if exists diffusion_data_shared.cnty_util_type_weight_res;
	create table diffusion_data_shared.cnty_util_type_weight_res as (
		select state_fips, county_fips, utility_type, sum(util_type_weight) as util_type_weight
		from diffusion_data_shared.tract_util_type_weight_res
		group by  state_fips, county_fips, utility_type);

	---------------------------
	-- ** Commercial **
	---------------------------		
	drop table if exists diffusion_data_shared.cnty_util_type_weight_com;
	create table diffusion_data_shared.cnty_util_type_weight_com as (
		select state_fips, county_fips, utility_type, sum(util_type_weight) as util_type_weight
		from diffusion_data_shared.tract_util_type_weight_com
		group by  state_fips, county_fips, utility_type);
		--where utility_type is not null);

	---------------------------
	-- ** Industrial **
	---------------------------
	drop table if exists diffusion_data_shared.cnty_util_type_weight_ind;
	create table diffusion_data_shared.cnty_util_type_weight_ind as (
		select state_fips, county_fips, utility_type, sum(util_type_weight) as util_type_weight
		from diffusion_data_shared.tract_util_type_weight_ind
		group by  state_fips, county_fips, utility_type);


---------------------------	---------------------------
-- Alter Owner
	alter table diffusion_data_shared.cnty_util_type_weight_com
	owner to "diffusion-writers";
	alter table diffusion_data_shared.cnty_util_type_weight_res
	owner to "diffusion-writers";
	alter table diffusion_data_shared.cnty_util_type_weight_ind
	owner to "diffusion-writers";

-- Drop Null Values
	delete from diffusion_data_shared.cnty_util_type_weight_res
	where util_type_weight is null;
	delete from diffusion_data_shared.cnty_util_type_weight_com
	where util_type_weight is null;
	delete from diffusion_data_shared.cnty_util_type_weight_ind
	where util_type_weight is null;

-- Update Type utility names to short hand
