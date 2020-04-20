-- calculate and load the max normalized demand for each building type
-- and TMY station to  diffusion_shared.energy_plus_max_normalized_demand_res
-- and diffusion_shared.energy_plus_max_normalized_demand_com
-- using python/load/extract_max_normalized_demand_from_eplus.py

---------------------------------------------------------------------------
-- check that the outputs make sense

-- first check that # of stations and building types is correct
-- there are 936 stations with 3 missing for com and 5 missing for res
-- there are 3 reference building for res -- expect 3*(936-5) = 2793 rows
-- there are 16 reference buildings for com -- expect 16*(936-3) = 14928 rows
select count(*)
FROM diffusion_shared.energy_plus_max_normalized_demand_res;
-- 2793

select count(*)
FROM diffusion_shared.energy_plus_max_normalized_demand_com;
-- 14928 rows
-- row counts match

-- how about building types?
SELECT distinct(crb_model)
FROM diffusion_shared.energy_plus_max_normalized_demand_res;
-- 3 types
SELECT distinct(crb_model)
FROM diffusion_shared.energy_plus_max_normalized_demand_com;
-- 16 types
-- NOTE: need to fix 'super_market' to 'supermarket' for consistency with 
-- diffusion_shared.cbecs_2003_pba_to_eplus_crbs
-- and
-- diffusion_shared.cbecs_2003_crb_lookup 
UPDATE diffusion_shared.energy_plus_max_normalized_demand_com
set crb_model = 'supermarket'
where crb_model = 'super_market';

-- check that hte values are reasonable
-- residential
with a as
(
	select normalized_max_demand_kw_per_kw*annual_sum_kwh as max_demand_kw
	FROM diffusion_shared.energy_plus_max_normalized_demand_res
	where crb_model = 'reference'
)
SELECT min(max_demand_kw), avg(max_demand_kw), max(max_demand_kw)
FROM a;
-- seems within range of what we'd expect

-- commercial
with a as
(
	select normalized_max_demand_kw_per_kw*annual_sum_kwh as max_demand_kw
	FROM diffusion_shared.energy_plus_max_normalized_demand_com
)
SELECT min(max_demand_kw), avg(max_demand_kw), max(max_demand_kw)
FROM a;
-- also seems reasonable
---------------------------------------------------------------------------


