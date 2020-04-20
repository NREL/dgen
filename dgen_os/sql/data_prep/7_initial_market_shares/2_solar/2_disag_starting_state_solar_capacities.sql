SET role 'diffusion-writers';

-- DROP TABLE IF EXISTS diffusion_solar.starting_capacities_mw_2012_q4_us;
-- CREATE TABLE diffusion_solar.starting_capacities_mw_2012_q4_us AS
-- SELECT *
-- FROM diffusion_solar.starting_capacities_mw_2012_q4_us_backup;


DROP TABLE IF EXISTS diffusion_solar.starting_capacities_mw_2012_q4_us;
CREAtE TABLE diffusion_solar.starting_capacities_mw_2012_q4_us AS
WITH customers_sums_by_sector AS
(
	SELECT a.state_abbr, 
		sum(b.total_customers_2011_residential) as state_customers_residential, 
		sum(b.total_customers_2011_commercial) as state_customers_commercial, 
		sum(b.total_customers_2011_industrial) as state_customers_industrial
	FROM diffusion_shared.county_geom a
	LEFT JOIN diffusion_shared.load_and_customers_by_county_us b
	ON a.county_id = b.county_id
	where a.state_abbr not in ('AK','HI')
	GROUP BY a.state_abbr
),
sector_alloc_factors AS
(
	SELECT state_abbr, 
		1::integer as res_alloc_factor,
		state_customers_commercial::numeric/(state_customers_commercial+state_customers_industrial) as com_alloc_factor,
		state_customers_industrial::numeric/(state_customers_commercial+state_customers_industrial) as ind_alloc_factor
	FROM customers_sums_by_sector
)
SELECT  a.state_abbr,
	a.res_cap_mw as capacity_mw_residential,
	round(a.nonres_cap_mw*com_alloc_factor,1) as capacity_mw_commercial,
	round(a.nonres_cap_mw*ind_alloc_factor,1) as capacity_mw_industrial,
	a.res_systems_count as systems_count_residential,
	round(a.nonres_systems_count*com_alloc_factor,0)as systems_count_commercial,
	round(a.nonres_systems_count*ind_alloc_factor,0) as systems_count_industrial
FROM seia.cumulative_pv_capacity_by_state_2012_Q4 a
LEFT JOIN sector_alloc_factors b
ON a.state_abbr = b.state_abbr
where a.state_abbr not in ('AK', 'HI', 'NA');
-- 26 rows

-- any nulls
select count(*)
FROM diffusion_solar.starting_capacities_mw_2012_q4_us
where capacity_mw_residential is null
or capacity_mw_commercial is null
or capacity_mw_industrial is null
or systems_count_residential is null
or systems_count_commercial is null
or systems_count_industrial is null;
-- nope

-- create primary key
ALTER TABLE diffusion_solar.starting_capacities_mw_2012_q4_us
  ADD CONSTRAINT starting_capacities_mw_2012_q4_us_pkey PRIMARY KEY(state_abbr);


------------------------------------------------------------------------------------------------
-- manual addition of MAINE, based on data provided by state of Maine to Ben
-- 10/19/2015
INSERT INTO diffusion_solar.starting_capacities_mw_2012_q4_us
(
	state_abbr,
	capacity_mw_residential,
	capacity_mw_commercial,
	capacity_mw_industrial,
	systems_count_residential,
	systems_count_commercial,
	systems_count_industrial
) 

VALUES
(
	'ME', 
	3.27262678,
	1.729382611,
	0.072057609,
	845.5202738,
	74.38053712,
	3.099189047
);

select *
FROM diffusion_solar.starting_capacities_mw_2012_q4_us
where state_abbr = 'ME';
