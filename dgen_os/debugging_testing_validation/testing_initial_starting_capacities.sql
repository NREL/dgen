-- wind
select sum(installed_capacity_last_year)/1000
from diffusion_wind.outputs_all
where sector = 'residential'
and year = 2014
-- 8.846304754948281854

select sum(a.capacity_mw_residential)
from diffusion_wind.starting_capacities_mw_2014_us a
where a.state_abbr = 'CA';
-- 10.21745882999999999972052184862301



with a as
(
	select county_id, capacity_mw_residential
	from diffusion_wind.starting_capacities_mw_2014_us
	where state_abbr = 'CA'
), 
b as
(
	SELECT county_id, sum(initial_capacity_mw) AS installed_capacity_last_year
	FROM diffusion_wind.pt_res_initial_market_shares
	group by county_id
)
SELECT a.county_id, a.capacity_mw_residential, b.installed_capacity_last_year, installed_capacity_last_year/capacity_mw_residential
from a
LEFT JOIN b
ON a.county_id = b.county_id;
-- starting capacity matches for all counties that have at least one valid customer bin


-- solar
select round(sum(installed_capacity_last_year)/1000,3)
from diffusion_solar.outputs_all
where sector = 'residential'
and year = 2014
-- 673.6

select round(sum(a.capacity_mw_residential),3)
from diffusion_solar.starting_capacities_mw_2012_q4_us a
where a.state_abbr = 'CA'



with a as
(
	select county_id, capacity_mw_residential
	from diffusion_solar.starting_capacities_mw_2012_q4_us
	where state_abbr = 'CA'
), 
b as
(
	SELECT county_id, sum(initial_capacity_mw) AS installed_capacity_last_year
	FROM diffusion_solar.pt_res_initial_market_shares
	group by county_id
)
SELECT a.county_id, a.capacity_mw_residential, b.installed_capacity_last_year, installed_capacity_last_year/capacity_mw_residential
from a
LEFT JOIN b
ON a.county_id = b.county_id

-- these match, so solar looks ok -- need to double check logic though... 