-- Create County Utilty Type Lookup Table
drop table if exists diffusion_data_shared.cnty_to_util_type_lkup;
create table diffusion_data_shared.cnty_to_util_type_lkup as (
	with a as (
		select geoid10 as cnty_geoid10, 'Investor Owned'::text as utility_type
		from diffusion_blocks.county_geoms
		union all
		select geoid10 as cnty_geoid10, 'Municipal'::text as utility_type
		from diffusion_blocks.county_geoms
		union all
		select geoid10 as cnty_geoid10, 'Cooperative'::text as utility_type
		from diffusion_blocks.county_geoms
		union all
		select geoid10 as cnty_geoid10, 'Other'::text as utility_type
		from diffusion_blocks.county_geoms
	)
	select row_number() over() as gid, a.*
	from a
);

-- Note: the gid field is the most important field.
-- 		We use this in the ranked table and joining based on gid to this lkup table will allow us to find 
-- 		the county geoid10 and then "rank_utility_type" which is the utility type the ranking was based off of