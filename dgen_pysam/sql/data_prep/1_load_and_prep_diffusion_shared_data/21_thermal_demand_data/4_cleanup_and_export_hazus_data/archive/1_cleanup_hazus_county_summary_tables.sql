------------------------------------------------------------------------------------------------
-- BLOCK -- SQUARE FOOTAGE
select count(*)
from hazus.sum_stats_sqfootage_block_county
-- 3138 rows

select a.state, a.county, a.county_id, a.state_fips, a.county_fips, b.*
from diffusion_shared.county_geom a
FULL OUTER JOIN hazus.sum_stats_sqfootage_block_county b
ON a.county_id = b.county_id
where a.county_id is null 
or b.county_id is null;
-- only three missing are the three usual suspects from county_geom in ALaska
-- (usual suspects):
-- Skagway-Hoonah-Angoon -- 201 -- needs to map to 198 from hazus
-- Wrangell-Petersburg -- 280 -- needs to map to 275 and 195 from hazus
-- Prince of Wales-Outer Ketchikan -- needs to map to 105 and 230 from hazus
-- (determined the above based on inspection of hazus tracts and county_geom in Q)

-- check that none of them are included in county_geom
select *
FROM diffusion_shared.county_geom
where state_fips = '02'
and county_fips in ('198', '275', '195', '105', '230');
-- 0 rows -- all set

-- check that none of these hazus fips codes were included in the hazus county summary table
select *
FROM hazus.sum_stats_sqfootage_block_county
where state_fips = '02'
and county_fips in ('198', '275', '195', '105', '230');
-- 0 rows -- all set
-- why were these left out? probably julian used an inner join
-- we will fix them manually below

-- fix these manually:
-- Skagway-Hoonah-Angoon -- 201 -- needs to map to 198 from hazus
INSERT INTO hazus.sum_stats_sqfootage_block_county
SELECT  'AK' as state, '02' as state_fips, 'Skagway-Hoonah-Angoon' as county, 
	'232' as county_fips, 9 as county_id, 
	1000 * sum(res1f) as res1f,
	1000 * sum(res2f) as res2f,
	1000 * sum(res3af) as res3af,
	1000 * sum(res3bf) as res3bf,
	1000 * sum(res3cf) as res3cf,
	1000 * sum(res3df) as res3df,
	1000 * sum(res3ef) as res3ef,
	1000 * sum(res3ff) as res3ff,
	1000 * sum(res4f) as res4f,
	1000 * sum(res5f) as res5f,
	1000 * sum(res6f) as res6f,
	1000 * sum(com1f) as com1f,
	1000 * sum(com2f) as com2f,
	1000 * sum(com3f) as com3f,
	1000 * sum(com4f) as com4f,
	1000 * sum(com5f) as com5f,
	1000 * sum(com6f) as com6f,
	1000 * sum(com7f) as com7f,
	1000 * sum(com8f) as com8f,
	1000 * sum(com9f) as com9f,
	1000 * sum(com10f) as com10f,
	1000 * sum(ind1f) as ind1f,
	1000 * sum(ind2f) as ind2f,
	1000 * sum(ind3f) as ind3f,
	1000 * sum(ind4f) as ind4f,
	1000 * sum(ind5f) as ind5f,
	1000 * sum(ind6f) as ind6f,
	1000 * sum(agr1f) as agr1f,
	1000 * sum(rel1f) as rel1f,
	1000 * sum(gov1f) as gov1f,
	1000 * sum(gov2f) as gov2f,
	1000 * sum(edu1f) as edu1f,
	1000 * sum(edu2f) as edu2f
FROM hazus.hzsqfootageoccupb_ak
where substring(censusblock, 1, 5) in ('02198');
-- one row affected 

-- Wrangell-Petersburg -- 280 -- needs to map to 275 and 195 from hazus
INSERT INTO hazus.sum_stats_sqfootage_block_county
SELECT  'AK' as state, '02' as state_fips, 'Wrangell-Petersburg' as county, 
	'280'county_fips, 4 as county_id, 
	1000 * sum(res1f) as res1f,
	1000 * sum(res2f) as res2f,
	1000 * sum(res3af) as res3af,
	1000 * sum(res3bf) as res3bf,
	1000 * sum(res3cf) as res3cf,
	1000 * sum(res3df) as res3df,
	1000 * sum(res3ef) as res3ef,
	1000 * sum(res3ff) as res3ff,
	1000 * sum(res4f) as res4f,
	1000 * sum(res5f) as res5f,
	1000 * sum(res6f) as res6f,
	1000 * sum(com1f) as com1f,
	1000 * sum(com2f) as com2f,
	1000 * sum(com3f) as com3f,
	1000 * sum(com4f) as com4f,
	1000 * sum(com5f) as com5f,
	1000 * sum(com6f) as com6f,
	1000 * sum(com7f) as com7f,
	1000 * sum(com8f) as com8f,
	1000 * sum(com9f) as com9f,
	1000 * sum(com10f) as com10f,
	1000 * sum(ind1f) as ind1f,
	1000 * sum(ind2f) as ind2f,
	1000 * sum(ind3f) as ind3f,
	1000 * sum(ind4f) as ind4f,
	1000 * sum(ind5f) as ind5f,
	1000 * sum(ind6f) as ind6f,
	1000 * sum(agr1f) as agr1f,
	1000 * sum(rel1f) as rel1f,
	1000 * sum(gov1f) as gov1f,
	1000 * sum(gov2f) as gov2f,
	1000 * sum(edu1f) as edu1f,
	1000 * sum(edu2f) as edu2f
FROM hazus.hzsqfootageoccupb_ak
where substring(censusblock, 1, 5) in ('02275', '02195');
-- one row affected

-- Prince of Wales-Outer Ketchikan -- needs to map to 105 and 230 from hazus
INSERT INTO hazus.sum_stats_sqfootage_block_county
SELECT  'AK' as state, '02' as state_fips, 'Prince of Wales-Outer Ketchikan' as county, 
	'201'county_fips, 3 as county_id, 
	1000 * sum(res1f) as res1f,
	1000 * sum(res2f) as res2f,
	1000 * sum(res3af) as res3af,
	1000 * sum(res3bf) as res3bf,
	1000 * sum(res3cf) as res3cf,
	1000 * sum(res3df) as res3df,
	1000 * sum(res3ef) as res3ef,
	1000 * sum(res3ff) as res3ff,
	1000 * sum(res4f) as res4f,
	1000 * sum(res5f) as res5f,
	1000 * sum(res6f) as res6f,
	1000 * sum(com1f) as com1f,
	1000 * sum(com2f) as com2f,
	1000 * sum(com3f) as com3f,
	1000 * sum(com4f) as com4f,
	1000 * sum(com5f) as com5f,
	1000 * sum(com6f) as com6f,
	1000 * sum(com7f) as com7f,
	1000 * sum(com8f) as com8f,
	1000 * sum(com9f) as com9f,
	1000 * sum(com10f) as com10f,
	1000 * sum(ind1f) as ind1f,
	1000 * sum(ind2f) as ind2f,
	1000 * sum(ind3f) as ind3f,
	1000 * sum(ind4f) as ind4f,
	1000 * sum(ind5f) as ind5f,
	1000 * sum(ind6f) as ind6f,
	1000 * sum(agr1f) as agr1f,
	1000 * sum(rel1f) as rel1f,
	1000 * sum(gov1f) as gov1f,
	1000 * sum(gov2f) as gov2f,
	1000 * sum(edu1f) as edu1f,
	1000 * sum(edu2f) as edu2f
FROM hazus.hzsqfootageoccupb_ak
where substring(censusblock, 1, 5) in ('02105', '02230');

-- recheck for complete match to county geom table
select count(*)
from hazus.sum_stats_sqfootage_block_county
-- 3141 rows -- good

select count(*)
from diffusion_shared.county_geom a
FULL OUTER JOIN hazus.sum_stats_sqfootage_block_county b
ON a.county_id = b.county_id
where a.county_id is null 
or b.county_id is null;
-- 0 rows returned -- perfect!
----------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------
-- BLOCK -- BLDG COUNTS
select count(*)
from hazus.sum_stats_bldg_count_block_county
-- 3138 rows

select a.state, a.county, a.county_id, a.state_fips, a.county_fips, b.*
from diffusion_shared.county_geom a
FULL OUTER JOIN hazus.sum_stats_bldg_count_block_county b
ON a.county_id = b.county_id
where a.county_id is null 
or b.county_id is null;
-- same three missing counties as above

-- check that none of these hazus fips codes were included in the hazus county summary table
select *
FROM hazus.sum_stats_bldg_count_block_county
where state_fips = '02'
and county_fips in ('198', '275', '195', '105', '230');


-- fix these manually:
-- Skagway-Hoonah-Angoon -- 201 -- needs to map to 198 from hazus
INSERT INTO hazus.sum_stats_bldg_count_block_county
SELECT  'AK' as state, '02' as state_fips, 'Skagway-Hoonah-Angoon' as county, 
	'232' as county_fips, 9 as county_id, 
	sum(res1i) as res1i, 
	sum(res2i) as res2i, 
	sum(res3ai) as res3ai, 
	sum(res3bi) as res3bi, 
	sum(res3ci) as res3ci, 
	sum(res3di) as res3di, 
	sum(res3ei) as res3ei, 
	sum(res3fi) as res3fi, 
	sum(res4i) as res4i, 
	sum(res5i) as res5i, 
	sum(res6i) as res6i, 
	sum(com1i) as com1i, 
	sum(com2i) as com2i, 
	sum(com3i) as com3i, 
	sum(com4i) as com4i, 
	sum(com5i) as com5i, 
	sum(com6i) as com6i, 
	sum(com7i) as com7i, 
	sum(com8i) as com8i, 
	sum(com9i) as com9i, 
	sum(com10i) as com10i, 
	sum(ind1i) as ind1i, 
	sum(ind2i) as ind2i, 
	sum(ind3i) as ind3i, 
	sum(ind4i) as ind4i, 
	sum(ind5i) as ind5i, 
	sum(ind6i) as ind6i, 
	sum(agr1i) as agr1i, 
	sum(rel1i) as rel1i, 
	sum(gov1i) as gov1i, 
	sum(gov2i) as gov2i, 
	sum(edu1i) as edu1i, 
	sum(edu2i) as edu2i
FROM hazus.hzbldgcountoccupb_ak
where substring(censusblock, 1, 5) in ('02198');
-- one row affected 

-- Wrangell-Petersburg -- 280 -- needs to map to 275 and 195 from hazus
INSERT INTO hazus.sum_stats_bldg_count_block_county
SELECT  'AK' as state, '02' as state_fips, 'Wrangell-Petersburg' as county, 
	'280'county_fips, 4 as county_id, 
	sum(res1i) as res1i, 
	sum(res2i) as res2i, 
	sum(res3ai) as res3ai, 
	sum(res3bi) as res3bi, 
	sum(res3ci) as res3ci, 
	sum(res3di) as res3di, 
	sum(res3ei) as res3ei, 
	sum(res3fi) as res3fi, 
	sum(res4i) as res4i, 
	sum(res5i) as res5i, 
	sum(res6i) as res6i, 
	sum(com1i) as com1i, 
	sum(com2i) as com2i, 
	sum(com3i) as com3i, 
	sum(com4i) as com4i, 
	sum(com5i) as com5i, 
	sum(com6i) as com6i, 
	sum(com7i) as com7i, 
	sum(com8i) as com8i, 
	sum(com9i) as com9i, 
	sum(com10i) as com10i, 
	sum(ind1i) as ind1i, 
	sum(ind2i) as ind2i, 
	sum(ind3i) as ind3i, 
	sum(ind4i) as ind4i, 
	sum(ind5i) as ind5i, 
	sum(ind6i) as ind6i, 
	sum(agr1i) as agr1i, 
	sum(rel1i) as rel1i, 
	sum(gov1i) as gov1i, 
	sum(gov2i) as gov2i, 
	sum(edu1i) as edu1i, 
	sum(edu2i) as edu2i
FROM hazus.hzbldgcountoccupb_ak
where substring(censusblock, 1, 5) in ('02275', '02195');
-- one row affected

-- Prince of Wales-Outer Ketchikan -- needs to map to 105 and 230 from hazus
INSERT INTO hazus.sum_stats_bldg_count_block_county
SELECT  'AK' as state, '02' as state_fips, 'Prince of Wales-Outer Ketchikan' as county, 
	'201'county_fips, 3 as county_id, 
	sum(res1i) as res1i, 
	sum(res2i) as res2i, 
	sum(res3ai) as res3ai, 
	sum(res3bi) as res3bi, 
	sum(res3ci) as res3ci, 
	sum(res3di) as res3di, 
	sum(res3ei) as res3ei, 
	sum(res3fi) as res3fi, 
	sum(res4i) as res4i, 
	sum(res5i) as res5i, 
	sum(res6i) as res6i, 
	sum(com1i) as com1i, 
	sum(com2i) as com2i, 
	sum(com3i) as com3i, 
	sum(com4i) as com4i, 
	sum(com5i) as com5i, 
	sum(com6i) as com6i, 
	sum(com7i) as com7i, 
	sum(com8i) as com8i, 
	sum(com9i) as com9i, 
	sum(com10i) as com10i, 
	sum(ind1i) as ind1i, 
	sum(ind2i) as ind2i, 
	sum(ind3i) as ind3i, 
	sum(ind4i) as ind4i, 
	sum(ind5i) as ind5i, 
	sum(ind6i) as ind6i, 
	sum(agr1i) as agr1i, 
	sum(rel1i) as rel1i, 
	sum(gov1i) as gov1i, 
	sum(gov2i) as gov2i, 
	sum(edu1i) as edu1i, 
	sum(edu2i) as edu2i
FROM hazus.hzbldgcountoccupb_ak
where substring(censusblock, 1, 5) in ('02105', '02230');

-- recheck for complete match to county geom table
select count(*)
from hazus.sum_stats_bldg_count_block_county
-- 3141 rows -- good

select count(*)
from diffusion_shared.county_geom a
FULL OUTER JOIN hazus.sum_stats_bldg_count_block_county b
ON a.county_id = b.county_id
where a.county_id is null 
or b.county_id is null;
-- 0 rows returned -- perfect!

------------------------------------------------------------------------------------------------
-- TRACT -- SQUARE FOOTAGE
select count(*)
from hazus.sum_stats_sqfootage_tract_county
-- 3138 rows

select a.state, a.county, a.county_id, a.state_fips, a.county_fips, b.*
from diffusion_shared.county_geom a
FULL OUTER JOIN hazus.sum_stats_sqfootage_tract_county b
ON a.county_id = b.county_id
where a.county_id is null 
or b.county_id is null;
-- same three as above

-- check that none of these hazus fips codes were included in the hazus county summary table
select *
FROM hazus.sum_stats_sqfootage_tract_county
where state_fips = '02'
and county_fips in ('198', '275', '195', '105', '230');
-- 0 rows -- all set
-- we will fix them manually below

-- fix these manually:
-- Skagway-Hoonah-Angoon -- 201 -- needs to map to 198 from hazus
INSERT INTO hazus.sum_stats_sqfootage_tract_county
SELECT  'AK' as state, '02' as state_fips, 'Skagway-Hoonah-Angoon' as county, 
	'232' as county_fips, 9 as county_id, 
	1000 * sum(res1f) as res1f,
	1000 * sum(res2f) as res2f,
	1000 * sum(res3af) as res3af,
	1000 * sum(res3bf) as res3bf,
	1000 * sum(res3cf) as res3cf,
	1000 * sum(res3df) as res3df,
	1000 * sum(res3ef) as res3ef,
	1000 * sum(res3ff) as res3ff,
	1000 * sum(res4f) as res4f,
	1000 * sum(res5f) as res5f,
	1000 * sum(res6f) as res6f,
	1000 * sum(com1f) as com1f,
	1000 * sum(com2f) as com2f,
	1000 * sum(com3f) as com3f,
	1000 * sum(com4f) as com4f,
	1000 * sum(com5f) as com5f,
	1000 * sum(com6f) as com6f,
	1000 * sum(com7f) as com7f,
	1000 * sum(com8f) as com8f,
	1000 * sum(com9f) as com9f,
	1000 * sum(com10f) as com10f,
	1000 * sum(ind1f) as ind1f,
	1000 * sum(ind2f) as ind2f,
	1000 * sum(ind3f) as ind3f,
	1000 * sum(ind4f) as ind4f,
	1000 * sum(ind5f) as ind5f,
	1000 * sum(ind6f) as ind6f,
	1000 * sum(agr1f) as agr1f,
	1000 * sum(rel1f) as rel1f,
	1000 * sum(gov1f) as gov1f,
	1000 * sum(gov2f) as gov2f,
	1000 * sum(edu1f) as edu1f,
	1000 * sum(edu2f) as edu2f
FROM hazus.hzsqfootageoccupt
where substring(tract, 1, 5) in ('02198');
-- one row affected 

-- Wrangell-Petersburg -- 280 -- needs to map to 275 and 195 from hazus
INSERT INTO hazus.sum_stats_sqfootage_tract_county
SELECT  'AK' as state, '02' as state_fips, 'Wrangell-Petersburg' as county, 
	'280'county_fips, 4 as county_id, 
	1000 * sum(res1f) as res1f,
	1000 * sum(res2f) as res2f,
	1000 * sum(res3af) as res3af,
	1000 * sum(res3bf) as res3bf,
	1000 * sum(res3cf) as res3cf,
	1000 * sum(res3df) as res3df,
	1000 * sum(res3ef) as res3ef,
	1000 * sum(res3ff) as res3ff,
	1000 * sum(res4f) as res4f,
	1000 * sum(res5f) as res5f,
	1000 * sum(res6f) as res6f,
	1000 * sum(com1f) as com1f,
	1000 * sum(com2f) as com2f,
	1000 * sum(com3f) as com3f,
	1000 * sum(com4f) as com4f,
	1000 * sum(com5f) as com5f,
	1000 * sum(com6f) as com6f,
	1000 * sum(com7f) as com7f,
	1000 * sum(com8f) as com8f,
	1000 * sum(com9f) as com9f,
	1000 * sum(com10f) as com10f,
	1000 * sum(ind1f) as ind1f,
	1000 * sum(ind2f) as ind2f,
	1000 * sum(ind3f) as ind3f,
	1000 * sum(ind4f) as ind4f,
	1000 * sum(ind5f) as ind5f,
	1000 * sum(ind6f) as ind6f,
	1000 * sum(agr1f) as agr1f,
	1000 * sum(rel1f) as rel1f,
	1000 * sum(gov1f) as gov1f,
	1000 * sum(gov2f) as gov2f,
	1000 * sum(edu1f) as edu1f,
	1000 * sum(edu2f) as edu2f
FROM hazus.hzsqfootageoccupt
where substring(tract, 1, 5) in ('02275', '02195');
-- one row affected

-- Prince of Wales-Outer Ketchikan -- needs to map to 105 and 230 from hazus
INSERT INTO hazus.sum_stats_sqfootage_tract_county
SELECT  'AK' as state, '02' as state_fips, 'Prince of Wales-Outer Ketchikan' as county, 
	'201'county_fips, 3 as county_id, 
	1000 * sum(res1f) as res1f,
	1000 * sum(res2f) as res2f,
	1000 * sum(res3af) as res3af,
	1000 * sum(res3bf) as res3bf,
	1000 * sum(res3cf) as res3cf,
	1000 * sum(res3df) as res3df,
	1000 * sum(res3ef) as res3ef,
	1000 * sum(res3ff) as res3ff,
	1000 * sum(res4f) as res4f,
	1000 * sum(res5f) as res5f,
	1000 * sum(res6f) as res6f,
	1000 * sum(com1f) as com1f,
	1000 * sum(com2f) as com2f,
	1000 * sum(com3f) as com3f,
	1000 * sum(com4f) as com4f,
	1000 * sum(com5f) as com5f,
	1000 * sum(com6f) as com6f,
	1000 * sum(com7f) as com7f,
	1000 * sum(com8f) as com8f,
	1000 * sum(com9f) as com9f,
	1000 * sum(com10f) as com10f,
	1000 * sum(ind1f) as ind1f,
	1000 * sum(ind2f) as ind2f,
	1000 * sum(ind3f) as ind3f,
	1000 * sum(ind4f) as ind4f,
	1000 * sum(ind5f) as ind5f,
	1000 * sum(ind6f) as ind6f,
	1000 * sum(agr1f) as agr1f,
	1000 * sum(rel1f) as rel1f,
	1000 * sum(gov1f) as gov1f,
	1000 * sum(gov2f) as gov2f,
	1000 * sum(edu1f) as edu1f,
	1000 * sum(edu2f) as edu2f
FROM hazus.hzsqfootageoccupt
where substring(tract, 1, 5) in ('02105', '02230');

-- recheck for complete match to county geom table
select count(*)
from hazus.sum_stats_sqfootage_tract_county
-- 3141 rows -- good

select count(*)
from diffusion_shared.county_geom a
FULL OUTER JOIN hazus.sum_stats_sqfootage_tract_county b
ON a.county_id = b.county_id
where a.county_id is null 
or b.county_id is null;
-- 0 rows returned -- perfect!
----------------------------------------------------------------------------------------------------


------------------------------------------------------------------------------------------------
-- TRACT -- BLDG COUNTS
select count(*)
from hazus.sum_stats_bldg_count_tract_county
-- 3138 rows

select a.state, a.county, a.county_id, a.state_fips, a.county_fips, b.*
from diffusion_shared.county_geom a
FULL OUTER JOIN hazus.sum_stats_bldg_count_tract_county b
ON a.county_id = b.county_id
where a.county_id is null 
or b.county_id is null;
-- same three missing counties as above

-- check that none of these hazus fips codes were included in the hazus county summary table
select *
FROM hazus.sum_stats_bldg_count_tract_county
where state_fips = '02'
and county_fips in ('198', '275', '195', '105', '230');


-- fix these manually:
-- Skagway-Hoonah-Angoon -- 201 -- needs to map to 198 from hazus
INSERT INTO hazus.sum_stats_bldg_count_tract_county
SELECT  'AK' as state, '02' as state_fips, 'Skagway-Hoonah-Angoon' as county, 
	'232' as county_fips, 9 as county_id, 
	sum(res1i) as res1i, 
	sum(res2i) as res2i, 
	sum(res3ai) as res3ai, 
	sum(res3bi) as res3bi, 
	sum(res3ci) as res3ci, 
	sum(res3di) as res3di, 
	sum(res3ei) as res3ei, 
	sum(res3fi) as res3fi, 
	sum(res4i) as res4i, 
	sum(res5i) as res5i, 
	sum(res6i) as res6i, 
	sum(com1i) as com1i, 
	sum(com2i) as com2i, 
	sum(com3i) as com3i, 
	sum(com4i) as com4i, 
	sum(com5i) as com5i, 
	sum(com6i) as com6i, 
	sum(com7i) as com7i, 
	sum(com8i) as com8i, 
	sum(com9i) as com9i, 
	sum(com10i) as com10i, 
	sum(ind1i) as ind1i, 
	sum(ind2i) as ind2i, 
	sum(ind3i) as ind3i, 
	sum(ind4i) as ind4i, 
	sum(ind5i) as ind5i, 
	sum(ind6i) as ind6i, 
	sum(agr1i) as agr1i, 
	sum(rel1i) as rel1i, 
	sum(gov1i) as gov1i, 
	sum(gov2i) as gov2i, 
	sum(edu1i) as edu1i, 
	sum(edu2i) as edu2i
FROM hazus.hzbldgcountoccupt
where substring(tract, 1, 5) in ('02198');
-- one row affected 

-- Wrangell-Petersburg -- 280 -- needs to map to 275 and 195 from hazus
INSERT INTO hazus.sum_stats_bldg_count_tract_county
SELECT  'AK' as state, '02' as state_fips, 'Wrangell-Petersburg' as county, 
	'280'county_fips, 4 as county_id, 
	sum(res1i) as res1i, 
	sum(res2i) as res2i, 
	sum(res3ai) as res3ai, 
	sum(res3bi) as res3bi, 
	sum(res3ci) as res3ci, 
	sum(res3di) as res3di, 
	sum(res3ei) as res3ei, 
	sum(res3fi) as res3fi, 
	sum(res4i) as res4i, 
	sum(res5i) as res5i, 
	sum(res6i) as res6i, 
	sum(com1i) as com1i, 
	sum(com2i) as com2i, 
	sum(com3i) as com3i, 
	sum(com4i) as com4i, 
	sum(com5i) as com5i, 
	sum(com6i) as com6i, 
	sum(com7i) as com7i, 
	sum(com8i) as com8i, 
	sum(com9i) as com9i, 
	sum(com10i) as com10i, 
	sum(ind1i) as ind1i, 
	sum(ind2i) as ind2i, 
	sum(ind3i) as ind3i, 
	sum(ind4i) as ind4i, 
	sum(ind5i) as ind5i, 
	sum(ind6i) as ind6i, 
	sum(agr1i) as agr1i, 
	sum(rel1i) as rel1i, 
	sum(gov1i) as gov1i, 
	sum(gov2i) as gov2i, 
	sum(edu1i) as edu1i, 
	sum(edu2i) as edu2i
FROM hazus.hzbldgcountoccupt
where substring(tract, 1, 5) in ('02275', '02195');
-- one row affected

-- Prince of Wales-Outer Ketchikan -- needs to map to 105 and 230 from hazus
INSERT INTO hazus.sum_stats_bldg_count_tract_county
SELECT  'AK' as state, '02' as state_fips, 'Prince of Wales-Outer Ketchikan' as county, 
	'201'county_fips, 3 as county_id, 
	sum(res1i) as res1i, 
	sum(res2i) as res2i, 
	sum(res3ai) as res3ai, 
	sum(res3bi) as res3bi, 
	sum(res3ci) as res3ci, 
	sum(res3di) as res3di, 
	sum(res3ei) as res3ei, 
	sum(res3fi) as res3fi, 
	sum(res4i) as res4i, 
	sum(res5i) as res5i, 
	sum(res6i) as res6i, 
	sum(com1i) as com1i, 
	sum(com2i) as com2i, 
	sum(com3i) as com3i, 
	sum(com4i) as com4i, 
	sum(com5i) as com5i, 
	sum(com6i) as com6i, 
	sum(com7i) as com7i, 
	sum(com8i) as com8i, 
	sum(com9i) as com9i, 
	sum(com10i) as com10i, 
	sum(ind1i) as ind1i, 
	sum(ind2i) as ind2i, 
	sum(ind3i) as ind3i, 
	sum(ind4i) as ind4i, 
	sum(ind5i) as ind5i, 
	sum(ind6i) as ind6i, 
	sum(agr1i) as agr1i, 
	sum(rel1i) as rel1i, 
	sum(gov1i) as gov1i, 
	sum(gov2i) as gov2i, 
	sum(edu1i) as edu1i, 
	sum(edu2i) as edu2i
FROM hazus.hzbldgcountoccupt
where substring(tract, 1, 5) in ('02105', '02230');

-- recheck for complete match to county geom table
select count(*)
from hazus.sum_stats_bldg_count_tract_county
-- 3141 rows -- good

select count(*)
from diffusion_shared.county_geom a
FULL OUTER JOIN hazus.sum_stats_bldg_count_tract_county b
ON a.county_id = b.county_id
where a.county_id is null 
or b.county_id is null;
-- 0 rows returned -- perfect!


------------------------------------------------------------------------------------------------------------
-- double check data matches across block/tract tables
-- county ids 3,4, 9
select round(a.res1i-b.res1i, 4),
	round(a.res2i-b.res2i, 4),
	round(a.res3ai-b.res3ai, 4),
	round(a.res3bi-b.res3bi, 4),
	round(a.res3ci-b.res3ci, 4),
	round(a.res3di-b.res3di, 4),
	round(a.res3ei-b.res3ei, 4),
	round(a.res3fi-b.res3fi, 4),
	round(a.res4i-b.res4i, 4),
	round(a.res5i-b.res5i, 4),
	round(a.res6i-b.res6i, 4),
	round(a.com1i-b.com1i, 4),
	round(a.com2i-b.com2i, 4),
	round(a.com3i-b.com3i, 4),
	round(a.com4i-b.com4i, 4),
	round(a.com5i-b.com5i, 4),
	round(a.com6i-b.com6i, 4),
	round(a.com7i-b.com7i, 4),
	round(a.com8i-b.com8i, 4),
	round(a.com9i-b.com9i, 4),
	round(a.com10i-b.com10i, 4),
	round(a.ind1i-b.ind1i, 4),
	round(a.ind2i-b.ind2i, 4),
	round(a.ind3i-b.ind3i, 4),
	round(a.ind4i-b.ind4i, 4),
	round(a.ind5i-b.ind5i, 4),
	round(a.ind6i-b.ind6i, 4),
	round(a.agr1i-b.agr1i, 4),
	round(a.rel1i-b.rel1i, 4),
	round(a.gov1i-b.gov1i, 4),
	round(a.gov2i-b.gov2i, 4),
	round(a.edu1i-b.edu1i, 4),
	round(a.edu2i-b.edu2i, 4)
from hazus.sum_stats_bldg_count_tract_county a
INNER JOIN hazus.sum_stats_bldg_count_block_county b
ON a.county_id = b.county_id
where a.county_id in (3, 4, 9);
-- all zeros -- all set for counts

select round(a.res1f-b.res1f, 4),
	round(a.res2f-b.res2f, 4),
	round(a.res3af-b.res3af, 4),
	round(a.res3bf-b.res3bf, 4),
	round(a.res3cf-b.res3cf, 4),
	round(a.res3df-b.res3df, 4),
	round(a.res3ef-b.res3ef, 4),
	round(a.res3ff-b.res3ff, 4),
	round(a.res4f-b.res4f, 4),
	round(a.res5f-b.res5f, 4),
	round(a.res6f-b.res6f, 4),
	round(a.com1f-b.com1f, 4),
	round(a.com2f-b.com2f, 4),
	round(a.com3f-b.com3f, 4),
	round(a.com4f-b.com4f, 4),
	round(a.com5f-b.com5f, 4),
	round(a.com6f-b.com6f, 4),
	round(a.com7f-b.com7f, 4),
	round(a.com8f-b.com8f, 4),
	round(a.com9f-b.com9f, 4),
	round(a.com10f-b.com10f, 4),
	round(a.ind1f-b.ind1f, 4),
	round(a.ind2f-b.ind2f, 4),
	round(a.ind3f-b.ind3f, 4),
	round(a.ind4f-b.ind4f, 4),
	round(a.ind5f-b.ind5f, 4),
	round(a.ind6f-b.ind6f, 4),
	round(a.agr1f-b.agr1f, 4),
	round(a.rel1f-b.rel1f, 4),
	round(a.gov1f-b.gov1f, 4),
	round(a.gov2f-b.gov2f, 4),
	round(a.edu1f-b.edu1f, 4),
	round(a.edu2f-b.edu2f, 4)
from hazus.sum_stats_sqfootage_tract_county a
INNER JOIN hazus.sum_stats_sqfootage_block_county b
ON a.county_id = b.county_id
where a.county_id in (3, 4, 9);
-- some very small differences at hundredths/thousandths place -- negligible for our purposes
