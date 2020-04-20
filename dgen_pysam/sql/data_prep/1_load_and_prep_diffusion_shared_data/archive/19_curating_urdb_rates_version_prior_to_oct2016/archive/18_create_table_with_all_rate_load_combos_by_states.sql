

------------------------------------------------------------------------
-- find all multiplicative combinations by state: 
-- rates (assume each rate could apply anywhere in the state)
-- hdf indices
-- eia regions
DROP TABLE if exists diffusion_shared.applicable_rate_load_combinations_com;
CREATE TABLE diffusion_shared.applicable_rate_load_combinations_com AS
with a as 
(
	-- find the unique combinations of:
	-- state, hdf_load_index (tmy station), and eia_region
	-- for commercial point locs
	SELECT b.state_abbr, a.hdf_load_index, b.census_division_abbr
	from diffusion_shared.pt_grid_us_com a
	left join diffusion_shared.county_geom b
	on a.county_id = b.county_id
	group by b.state_abbr, a.hdf_load_index, b.census_division_abbr	
),
b as 
(
	-- find all unique rates in each state
	SELECT a.state_abbr, a.urdb_rate_id,
	       a.urdb_utility_type, a.urdb_rate_type, 
	       a.urdb_demand_min, a.urdb_demand_max
	from diffusion_shared.curated_urdb_rates_lookup_pts_com a
	group by a.state_abbr, a.urdb_rate_id,
	       a.urdb_utility_type, a.urdb_rate_type, 
	       a.urdb_demand_min, a.urdb_demand_max
),
c as
(
	SELECT a.state_abbr, a.hdf_load_index, a.census_division_abbr,
		c.pubid8, c.max_demand_kw as eia_max_demand_kw,
		b.urdb_rate_id, 
		b.urdb_utility_type, b.urdb_rate_type, 
		b.urdb_demand_min, b.urdb_demand_max,
		(c.max_demand_kw >= b.urdb_demand_min  and c.max_demand_kw <= b.urdb_demand_max) as rate_applies_to_load
	FROM a
	LEFT JOIN b
	ON a.state_abbr = b.state_abbr
	LEFT JOIN diffusion_shared.cbecs_2003_max_demand_by_tmy_and_eia_region c
	ON a.hdf_load_index = c.hdf_load_index
	and a.census_division_abbr = c.census_division_abbr
)
SELECT state_abbr, hdf_load_index, census_division_abbr,
	pubid8, eia_max_demand_kw,
	urdb_rate_id,
	urdb_utility_type, urdb_rate_type, 
	urdb_demand_min, urdb_demand_max
FROM c
where rate_applies_to_load = true;
--- 13107071 rows

