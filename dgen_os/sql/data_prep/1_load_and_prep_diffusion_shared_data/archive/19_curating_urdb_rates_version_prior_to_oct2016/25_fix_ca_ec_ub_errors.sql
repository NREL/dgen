-- find the rate with weird EC tier upper bounds
-- try 80 as a threshold
with a as
(
	select rate_id_alias, diffusion_shared.find_ec_tier_errors(sam_json, 80) as ec_tier_error
	from diffusion_shared.urdb3_rate_sam_jsons
)
select *
FROM a
where ec_tier_error = True
order by rate_id_alias;
-- 46 rates

-- try 100 as a threshold
with a as
(
	select rate_id_alias, diffusion_shared.find_ec_tier_errors(sam_json, 100) as ec_tier_error
	from diffusion_shared.urdb3_rate_sam_jsons
)
select *
FROM a
where ec_tier_error = True
order by rate_id_alias;
-- 47 rows

-- try 200 as a threshold
with a as
(
	select rate_id_alias, diffusion_shared.find_ec_tier_errors(sam_json, 200) as ec_tier_error
	from diffusion_shared.urdb3_rate_sam_jsons
)
select *
FROM a
where ec_tier_error = True
order by rate_id_alias;
-- 79 rows

-- 100 seeems like a good threshold, but do some more investigation before deciding
------------------------------------------------------------------------------

-- how do these compare to the rates CG identified as problmatic?
with a as
(
	select rate_id_alias, diffusion_shared.find_ec_tier_errors(sam_json, 100) as ec_tier_error
	from diffusion_shared.urdb3_rate_sam_jsons
),
b as
(
	select unnest(array[1054, 1647, 1797, 2099, 2353, 2354, 2355, 2356, 2357, 2358, 2359, 2360, 2361, 2362, 2363, 2364, 2365, 2366, 2367, 2373, 2374, 2375, 2376, 496, 599, 608, 848, 9])
	as cg_id
),
c as
(
	select *
	FROM a
	where ec_tier_error = True
	order by rate_id_alias
),
d as
(
	select unnest(array[9, 157, 168, 264, 345, 464, 469, 496, 588, 599, 608, 848, 947, 972, 1054, 1187, 1530, 1647, 1688, 1729, 1785, 1789, 1797, 1835, 2099, 2166, 2347, 2353, 2354, 2355, 2356, 2357, 2358, 2359, 2360, 2361, 2362, 2363, 2364, 2365, 2366, 2367, 2372, 2373, 2374, 2375, 2376])
	as eia_id
),
e as
(
	select d.eia_id, c.rate_id_alias, b.cg_id
	from d
	full outer join c
	on d.eia_id = c.rate_id_alias
	FULL OUTER JOIN b
	on d.eia_id = b.cg_id
)
select *
FROM e
where eia_id is null
and rate_id_alias is not null;

-- check the set of eia_ids that don't overlap the ones used in the EIA CA modeling
select *
from urdb_rates.combined_singular_verified_rates_lookup
where rate_id_alias in (47, 189, 273, 434, 579, 1225, 1332, 1383, 1727, 1777, 1829, 1873, 1901, 2005, 2019, 2108, 2109, 2206);
-- these rates are mostly small munis, with a few obvious CA exceptions

select *
FROM urdb_rates.urdb3_singular_rates_sam_data_20141202
where rate_id_alias in (47, 189, 273, 434, 579, 1225, 1332, 1383, 1727, 1777, 1829, 1873, 1901, 2005, 2019, 2108, 2109, 2206);
-- for the small munis outside CA, the rates appear tobe legit (if a bit strange)

select *
from urdb_rates.urdb3_verified_rates_sam_data_20141202
where rate_id_alias in (47, 189, 273, 434, 579, 1225, 1332, 1383, 1727, 1777, 1829, 1873, 1901, 2005, 2019, 2108, 2109, 2206);
-- for the rates in CA, they appear to wrong
-- so, conclusion is that this is an issue isolated to CA

------------------------------------------------------------------------------------

-- re-idenfity errors, this time filtering to CA
with a as
(
	select rate_id_alias
	from diffusion_shared.urdb_rates_by_state_res
	where state_abbr = 'CA'
	UNION
	select rate_id_alias
	from diffusion_shared.urdb_rates_by_state_com
	where state_abbr = 'CA'
	UNION
	select rate_id_alias
	from diffusion_shared.urdb_rates_by_state_ind
	where state_abbr = 'CA'
), -- 100 rates in CA
b as
(
	select b.rate_id_alias, 
-- 		diffusion_shared.find_ec_tier_errors(b.sam_json, 80) as ec_tier_error
-- 		diffusion_shared.find_ec_tier_errors(b.sam_json, 100) as ec_tier_error
		diffusion_shared.find_ec_tier_errors(b.sam_json, 200) as ec_tier_error
	from diffusion_shared.urdb3_rate_sam_jsons b
	inner join a
	on a.rate_id_alias = b.rate_id_alias
)
select *
FROM b
where ec_tier_error = True
order by rate_id_alias;
-- thresholds:
	-- 80 = 30 bad rates in CA
	-- 100 = 30 bad rates in CA;
	-- 200 = 30 bad rates in CA
-- so the specific threshold doesn't really matter for CA only;


----------------------------------------------------------------------------------------------------
-- start testing how to fix
with a as
(
	select rate_id_alias
	from diffusion_shared.urdb_rates_by_state_res
	where state_abbr = 'CA'
	UNION
	select rate_id_alias
	from diffusion_shared.urdb_rates_by_state_com
	where state_abbr = 'CA'
	UNION
	select rate_id_alias
	from diffusion_shared.urdb_rates_by_state_ind
	where state_abbr = 'CA'
), -- 100 rates in CA
b as
(
	select b.rate_id_alias, diffusion_shared.find_ec_tier_errors(b.sam_json, 100) as ec_tier_error
	from diffusion_shared.urdb3_rate_sam_jsons b
	inner join a
	on a.rate_id_alias = b.rate_id_alias
)
select c.rate_id_alias, sam_json, extract_orig_ec_tier_values(c.sam_json) as json_orig,
			 test_diffusion_shared.fix_ec_tier_errors(c.sam_json) as json_fix
FROM diffusion_shared.urdb3_rate_sam_jsons c
inner join b
ON c.rate_id_alias = b.rate_id_alias
where b.ec_tier_error = True
order by rate_id_alias;
-- reviewed a few of these manually and hte corrections look good
----------------------------------------------------------------------------------------------------
-- actually fix the data
-- create an archive of the table
SET ROLE 'diffusion-writers';
DROP TABLE IF EXISTS diffusion_data_shared.urdb3_rate_sam_jsons_archive;
CREATE TABLE diffusion_data_shared.urdb3_rate_sam_jsons_archive AS
SELECT *
FROM diffusion_shared.urdb3_rate_sam_jsons;

-- fix the data
with a as
(
	select rate_id_alias
	from diffusion_shared.urdb_rates_by_state_res
	where state_abbr = 'CA'
	UNION
	select rate_id_alias
	from diffusion_shared.urdb_rates_by_state_com
	where state_abbr = 'CA'
	UNION
	select rate_id_alias
	from diffusion_shared.urdb_rates_by_state_ind
	where state_abbr = 'CA'
), -- 100 rates in CA
b as
(
	select b.rate_id_alias, diffusion_shared.find_ec_tier_errors(b.sam_json, 100) as ec_tier_error
	from diffusion_shared.urdb3_rate_sam_jsons b
	inner join a
	on a.rate_id_alias = b.rate_id_alias
),
c as
(

	select c.rate_id_alias, diffusion_shared.fix_ec_tier_errors(c.sam_json) as json_fix
	FROM diffusion_shared.urdb3_rate_sam_jsons c
	inner join b
	ON c.rate_id_alias = b.rate_id_alias
	where b.ec_tier_error = True
)
UPDATE diffusion_shared.urdb3_rate_sam_jsons d
set sam_json = c.json_fix
from c
where d.rate_id_alias = c.rate_id_alias;
--- 30 rows affected

-- for archival purposes, which 30 rates were fixed?
with a as
(
	select rate_id_alias
	from diffusion_shared.urdb_rates_by_state_res
	where state_abbr = 'CA'
	UNION
	select rate_id_alias
	from diffusion_shared.urdb_rates_by_state_com
	where state_abbr = 'CA'
	UNION
	select rate_id_alias
	from diffusion_shared.urdb_rates_by_state_ind
	where state_abbr = 'CA'
), -- 100 rates in CA
b as
(
	select b.rate_id_alias, diffusion_shared.find_ec_tier_errors(b.sam_json, 100) as ec_tier_error
	from diffusion_data_shared.urdb3_rate_sam_jsons_archive b
	inner join a
	on a.rate_id_alias = b.rate_id_alias
)
select c.rate_id_alias
FROM diffusion_data_shared.urdb3_rate_sam_jsons_archive c
inner join b
ON c.rate_id_alias = b.rate_id_alias
where b.ec_tier_error = True
order by rate_id_alias;
-- 9
-- 47
-- 496
-- 599
-- 608
-- 848
-- 1054
-- 1647
-- 1777
-- 1797
-- 2099
-- 2353
-- 2354
-- 2355
-- 2356
-- 2357
-- 2358
-- 2359
-- 2360
-- 2361
-- 2362
-- 2363
-- 2364
-- 2365
-- 2366
-- 2367
-- 2373
-- 2374
-- 2375
-- 2376
