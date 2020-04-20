set role 'diffusion-writers';

------------------------------------------------------------------------------------------------
-- create the table
DROP TABLE IF EXISTS diffusion_blocks.county_primary_electric_utilities;
CREATE TABLE diffusion_blocks.county_primary_electric_utilities AS
with a as
(
	select statefp as state_fips, countyfp as county_fips, 
		a.utility_num, a.utility_type_general,
		row_number() OVER (PARTITION BY statefp, countyfp ORDER BY a.res_customers desc) as rank_res,
		row_number() OVER (PARTITION BY statefp, countyfp ORDER BY a.com_customers desc) as rank_com,
		row_number() OVER (PARTITION BY statefp, countyfp ORDER BY a.ind_customers desc) as rank_ind,
		row_number() OVER (PARTITION BY statefp, countyfp ORDER BY a.tot_customers desc) as rank_tot
	from diffusion_blocks.electric_utilities_lkup a
	INNER JOIN eia.eia_861_2013_county_utility_rates b
	ON a.utility_num = b.utility_num
	and a.state_fips = b.statefp
),
res as
(
	select state_fips, county_fips, utility_num, utility_type_general
	from a
	where rank_res = 1
),
com as
(
	select distinct on (state_fips, county_fips)
		state_fips, county_fips, utility_num, utility_type_general
	from a
	where rank_com = 1
),
ind as
(
	select distinct on (state_fips, county_fips)
		state_fips, county_fips, utility_num, utility_type_general
	from a
	where rank_ind = 1
),
tot as
(
	select distinct on (state_fips, county_fips)
		state_fips, county_fips, utility_num, utility_type_general
	from a
	WHERE rank_tot = 1
)
select res.state_fips, res.county_fips,
	res.utility_num as utility_num_res,
	res.utility_type_general as utility_type_res,
	com.utility_num as utility_num_com,
	com.utility_type_general as utility_type_com,
	ind.utility_num as utility_num_ind,
	ind.utility_type_general as utility_type_ind,
	tot.utility_num as utility_num_tot,
	tot.utility_type_general as utility_type_tot
from res
left join com
	on res.state_fips = com.state_fips
	and res.county_fips = com.county_fips
left join ind
	on res.state_fips = ind.state_fips
	and res.county_fips = ind.county_fips
left join tot
	on res.state_fips = tot.state_fips
	and res.county_fips = tot.county_fips;
-- 3132 rows


-------------------------------------------------------------------------------------------------
-- QA/QC

-- add primary key
ALTER TABLE diffusion_blocks.county_primary_electric_utilities
ADD PRIMARY KEY (state_fips, county_fips);

-- check for nulls
select *
FROM diffusion_blocks.county_primary_electric_utilities
where utility_num_res is null
or utility_num_com is null
or utility_num_ind is null
or utility_num_tot is null;
-- 0 -- all set

