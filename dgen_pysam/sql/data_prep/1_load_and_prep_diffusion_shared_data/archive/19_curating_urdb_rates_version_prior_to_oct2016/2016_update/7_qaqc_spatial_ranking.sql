-- Create utility table that helps when visually inspecting the rankings
create table diffusion_data_shared.urdb_rates_geoms_20161005_qaqc as (
select a.*, b.utility_type from diffusion_data_shared.urdb_rates_geoms_20161005 a 
left join diffusion_data_shared.urdb_rates_attrs_lkup_20161005 b
on a.util_reg_gid = b.util_reg_gid);

-- QAQC Rankings

DROP TABLE IF EXISTS diffusion_data_shared.cnty_ranked_rates_lkup_20161005_3;
CREATE TABLE diffusion_data_shared.cnty_ranked_rates_lkup_20161005_3
(
	gid integer,
	rate_util_reg_gid integer,
	distance numeric,
	util_reg_gid_nearby text,
	type_rank numeric,
	rank integer
);

-- Begin Ranking
SELECT parsel_2('dav-gis','mmooney','mmooney', 'diffusion_data_shared.cnty_to_util_type_lkup', 'gid', 
	'with county as (
			select a.gid, a.utility_type, b.state_fips, b.the_geom_96703_5m 
			from diffusion_data_shared.cnty_to_util_type_lkup a
			left join diffusion_blocks.county_geoms b
			on a.cnty_geoid10 = b.geoid10
			where a.cnty_geoid10 = ''06037''),
	a as (
			SELECT a.gid, b.rate_util_reg_gid, b.util_reg_gid, c.util_reg_gid as util_reg_gid_nearby, -- delete
				(b.utility_type = a.utility_type) as utility_type_match,
				ST_Distance(a.the_geom_96703_5m, c.the_geom_96703) as distance_m
			FROM county a 
			INNER JOIN diffusion_data_shared.urdb_rates_attrs_lkup_20161005 b
			ON a.state_fips = b.state_fips
			INNER JOIN diffusion_data_shared.urdb_rates_geoms_20161005 c
			ON b.state_fips = c.state_fips and b.util_reg_gid = c.util_reg_gid), 
	b as (
			select gid, rate_util_reg_gid, utility_type_match,  util_reg_gid_nearby, min(distance_m) as distance_m
			FROM a
			GROUP BY gid, rate_util_reg_gid, utility_type_match, util_reg_gid_nearby), 
	within50_and_match as (
			with a as 
				(SELECT gid, rate_util_reg_gid, 
					(utility_type_match = true and distance_m <= 80467.2)::boolean as near_utility_type_match, util_reg_gid_nearby, 
					distance_m
				from b)
			select gid, rate_util_reg_gid, distance_m, 10::int as rank_a,  util_reg_gid_nearby 
			from a
			where near_utility_type_match = True),
	within50_and_no_match as (
			with a as (
					SELECT gid, rate_util_reg_gid,
					(utility_type_match = false and distance_m <= 80467.2)::boolean as near_utility_type_no_match, util_reg_gid_nearby ,
					distance_m
					from b)
			select gid, rate_util_reg_gid, distance_m, 20::int as rank_a,  util_reg_gid_nearby 
			from a
			where near_utility_type_no_match = True),
	beyond50_and_match as (
			with a as (
					SELECT gid, rate_util_reg_gid,
						(utility_type_match = true and distance_m > 80467.2)::boolean as far_utility_type_match, util_reg_gid_nearby, 
						distance_m
					from b)
			select gid, rate_util_reg_gid, distance_m, 30::int as rank_a,  util_reg_gid_nearby 
			from a
			where far_utility_type_match = True),
	beyond50_and_nomatch as (
			with a as (
					SELECT gid, rate_util_reg_gid,
						(utility_type_match = false and distance_m > 80467.2)::boolean as far_utility_type_nomatch, util_reg_gid_nearby, 
						distance_m
					from b)
			select gid, rate_util_reg_gid, distance_m, 40::int as rank_a,  util_reg_gid_nearby 
			from a
			where far_utility_type_nomatch = True),
	c as (
			select * from within50_and_match
			union all
			select * from within50_and_no_match
			union all
			select * from beyond50_and_match
			union all
			select * from beyond50_and_nomatch)

	SELECT gid, rate_util_reg_gid, util_reg_gid_nearby, distance_m, rank_a,
		rank() OVER (partition by gid ORDER BY rank_a asc, distance_m asc) as rank
	FROM c;',
	'diffusion_data_shared.cnty_ranked_rates_lkup_20161005_3', 'aa', 22);


-- Merge Ranks with Other Useful Info for Identifying and QAQCing
drop table if exists  diffusion_data_shared.cnty_ranked_rates_lkup_20161005_3_qaqc;
create table diffusion_data_shared.cnty_ranked_rates_lkup_20161005_3_qaqc as (
select left(b.cnty_geoid10, 2) as state_fips, b.cnty_geoid10, a.rate_util_reg_gid, b.utility_type as rank_utility_type, 
a.distance, a.type_rank,
a.rank
from diffusion_data_shared.cnty_ranked_rates_lkup_20161005_3 a
inner join diffusion_data_shared.cnty_to_util_type_lkup b
on a.gid = b.gid
order by a.gid, a.rank, a.rate_util_reg_gid asc);
select * from diffusion_data_shared.cnty_ranked_rates_lkup_20161005_3_qaqc limit 500



-- Delete QAQC Tables
drop table if exists diffusion_data_shared.cnty_ranked_rates_20161005_3;
drop table if exists diffusion_data_shared.cnty_ranked_rates_lkup_20161005_3;
			

-- Things to Look for:
	-- Check to make sure that the rank type is line with the rank
		-- Rank Type = 1 of the 4 pre-ranks (i.e. Within 50 miles AND utility type match)
		-- √ Rank type 1 has has higher ranks (lower numbers) than anything in ranktype 2


-- QAQC The ranking to make sure it worked:
	-- pick 5 random counties to investigate
	-- pick 5 random rates to investigate
	-- pick 5 random utility_eia_ids to investigate
	-- Check counties in CA that we know are divided by climate zone regions

	-- √ ALl Check outs!