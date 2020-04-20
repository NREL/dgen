-- *****************************************************
-- Important Notes on Spatial Ranking
-- *****************************************************
-- 1. State (filter)
-- 2. 50 mile buffer (boolean)
-- 3. Utility Type (boolean)
-- 4. Distance (ordered)


-- For each cnty (within each state), we identify the rate rankings (agnostic of agent type) according to the utility type being queried.
-- 	- ranks are weighted based on 1) whether the utility rate is within 50 miles of the county of interest, 2) weather the utility type matches the input utility type being queried  
-- 		- 1. True (within 50 Miles) and True (utility type match)
-- 		- 2. True (within 50 Miles) and False (utility type match)
-- 		- 3. False (within 50 Miles) and True (utility type match)
-- 		- 4. False (within 50 Miles) and False (utility type match)
-- 	- ** within each of these sub categories, the ranks are then ranked based on distance

-- 	location/ proximity has a heigher weight than the utility match; however, within a certain range, 
-- 	utilities that are too far away (more than 50 miles) rank lower than those that are closer but have a different utility type

-- NOTE -- the rankings are based off of the cnty geometry, not the utility's geometry

--------------------------------------------------------------------------------------------------------------------------------------
-- Create Agnostic Lkup table with all of the potential combinations of cntys and utility types
drop table if exists diffusion_data_shared.cnty_util_type_all_potential_combos_20170103;
create table diffusion_data_shared.cnty_util_type_all_potential_combos_20170103 as (
	with a as (
		select state_fips, county_fips, (state_fips || county_fips) as geoid, 'Investor Owned'::text as utility_type
		from diffusion_blocks.county_geoms
		union all
		select state_fips, county_fips, (state_fips || county_fips) as geoid, 'Municipal'::text as utility_type
		from diffusion_blocks.county_geoms
		union all
		select state_fips, county_fips, (state_fips || county_fips) as geoid, 'Cooperative'::text as utility_type
		from diffusion_blocks.county_geoms
		union all
		select state_fips, county_fips, (state_fips || county_fips) as geoid, 'Other'::text as utility_type
		from diffusion_blocks.county_geoms
	)
	select row_number() over() as gid, a.*
	from a
);


-- Create table to store ranks
DROP TABLE IF EXISTS diffusion_data_shared.cntys_ranked_rates_lkup_20170103;
CREATE TABLE diffusion_data_shared.cntys_ranked_rates_lkup_20170103
(
	gid integer,
	rate_util_reg_gid integer,
	rank integer
);


update diffusion_data_shared.urdb_rates_attrs_lkup_20170103
set utility_type = 'Investor Owned'
where eia_id = '15270';

-- Begin Ranking
SELECT parsel_2('dav-gis','mmooney','mmooney', 'diffusion_data_shared.cnty_util_type_all_potential_combos_20170103', 'gid', 
	'with county as (
			select a.gid, a.utility_type, b.state_fips, b.county_fips, b.the_geom_96703_5m as the_geom_96703
			from diffusion_data_shared.cnty_util_type_all_potential_combos_20170103 a
			left join diffusion_blocks.county_geoms b
			on a.state_fips = b.state_fips and a.county_fips = b.county_fips),
	a as (
			SELECT a.gid, a.state_fips, a.county_fips, b.rate_util_reg_gid, b.util_reg_gid, 
				(b.utility_type = a.utility_type) as utility_type_match,
				ST_Distance(a.the_geom_96703, c.the_geom_96703) as distance_m
			FROM county a 
			INNER JOIN diffusion_data_shared.urdb_rates_attrs_lkup_20170103 b
			ON a.state_fips = b.state_fips
			INNER JOIN diffusion_data_shared.urdb_rates_geoms_20170103 c
			ON b.state_fips = c.state_fips and b.util_reg_gid = c.util_reg_gid),
	b as (
			select gid, rate_util_reg_gid, utility_type_match, min(distance_m) as distance_m
			FROM a
			GROUP BY gid, rate_util_reg_gid, utility_type_match), 
	within50_and_match as (
			with a as 
				(SELECT gid, rate_util_reg_gid, 
					(utility_type_match = true and distance_m <= 80467.2)::integer as near_utility_type_match,
					distance_m
				from b)
			select gid, rate_util_reg_gid, distance_m, 10::int as rank_a
			from a
			where near_utility_type_match = 1),
	within50_and_no_match as (
			with a as (
					SELECT gid, rate_util_reg_gid,
					(utility_type_match = False and distance_m <= 80467.2)::integer as near_utility_type_no_match,
					distance_m
					from b)
			select gid, rate_util_reg_gid, distance_m, 20::int as rank_a
			from a
			where near_utility_type_no_match = 1),
	beyond50_and_match as (
			with a as (
					SELECT gid, rate_util_reg_gid,
						(utility_type_match = true and distance_m > 80467.2)::integer as far_utility_type_match,
						distance_m
					from b)
			select gid, rate_util_reg_gid, distance_m, 30::int as rank_a
			from a
			where far_utility_type_match = 1),
	beyond50_and_nomatch as (
			with a as (
					SELECT gid, rate_util_reg_gid,
						(utility_type_match = true and distance_m > 80467.2)::integer as far_utility_type_nomatch,
						distance_m
					from b)
			select gid, rate_util_reg_gid, distance_m, 40::int as rank_a
			from a
			where far_utility_type_nomatch = 1),
	c as (
			select * from within50_and_match
			union all
			select * from within50_and_no_match
			union all
			select * from beyond50_and_match
			union all
			select * from beyond50_and_nomatch)

	SELECT gid, rate_util_reg_gid, 
		rank() OVER (partition by gid ORDER BY rank_a asc, distance_m asc) as rank
	FROM c;',
	'diffusion_data_shared.cntys_ranked_rates_lkup_20170103', 'aa', 30);
			
-- Add Indices
select count(*) from diffusion_data_shared.cntys_ranked_rates_lkup_20170103;
-- total = 32560530


-- then I can join on gid to get the rank_utility_type and the cnty_id_alias from the cnty_to_util_lkup
-- then I can join on rate_util_reg_gid to get rate or utility related information 



-- Next step move this to diffusion_shared (along with other critical tables)
-- Change ownership to diffusion-writers for all tables (search to make sure there arent any tables that do not have this ownerhsip)


-- Make a crosswalk/ data dictionary for all the tables I created and what the fields represent

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------