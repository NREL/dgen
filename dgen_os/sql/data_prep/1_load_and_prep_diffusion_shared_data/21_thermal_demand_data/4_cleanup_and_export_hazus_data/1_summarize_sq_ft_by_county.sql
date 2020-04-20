set role 'diffusion-writers';

DROP TABLE IF EXISTS diffusion_blocks.county_bldg_sqft_by_type;
CREATE TABLE diffusion_blocks.county_bldg_sqft_by_type AS
select substring(tract, 1, 2)  as state_fips,
	substring(tract,3,3) as county_fips,
	sum(res1f)*1000 as res1,
	sum(res2f)*1000 as res2,
	sum(res3af)*1000 as res3a,
	sum(res3bf)*1000 as res3b,
	sum(res3cf)*1000 as res3c,
	sum(res3df)*1000 as res3d,
	sum(res3ef)*1000 as res3e,
	sum(res3ff)*1000 as res3f,
	sum(res4f)*1000 as res4,
	sum(res5f)*1000 as res5,
	sum(res6f)*1000 as res6,
	sum(com1f)*1000 as com1,
	sum(com2f)*1000 as com2,
	sum(com3f)*1000 as com3,
	sum(com4f)*1000 as com4,
	sum(com5f)*1000 as com5,
	sum(com6f)*1000 as com6,
	sum(com7f)*1000 as com7,
	sum(com8f)*1000 as com8,
	sum(com9f)*1000 as com9,
	sum(com10f)*1000 as com10,
	sum(ind1f)*1000 as ind1,
	sum(ind2f)*1000 as ind2,
	sum(ind3f)*1000 as ind3,
	sum(ind4f)*1000 as ind4,
	sum(ind5f)*1000 as ind5,
	sum(ind6f)*1000 as ind6,
	sum(agr1f)*1000 as agr1,
	sum(rel1f)*1000 as rel1,
	sum(gov1f)*1000 as gov1,
	sum(gov2f)*1000 as gov2,
	sum(edu1f)*1000 as edu1,
	sum(edu2f)*1000 as edu2
FROM hazus.hzsqfootageoccupt
group by substring(tract, 1, 2), substring(tract,3,3);
-- 3221 rows

------------------------------------------------------------------------------------------
-- QAQC
-- add primary key
ALTER TABLE diffusion_blocks.county_bldg_sqft_by_type
ADD PRIMARY KEY (state_fips, county_fips);

-- how does row count compare to county geoms?
select count(*)
FROM diffusion_blocks.county_geoms;
-- 3143 rows
-- so more rows than we need

-- are any counties from county geoms missing?
select count(*)
from diffusion_blocks.county_geoms a
LEFT JOIN diffusion_blocks.county_bldg_sqft_by_type b
ON a.county_fips = b.county_fips
and a.state_fips = b.state_fips
where b.state_fips is null;
-- 0 -- all set

-- any counties with zero buildings?
with a as
(
	select res1 + res2 + res3a + res3b + res3c + res3d + res3e + res3f + 
		res4 + res5 + res6 + com1 + com2 + com3 + com4 + com5 + com6 + 
		com7 + com8 + com9 + com10 + ind1 + ind2 + ind3 + ind4 + ind5 + 
		ind6 + agr1 + rel1 + gov1 + gov2 + edu1 + edu2 as tot_count
	from diffusion_blocks.county_bldg_sqft_by_type
)
select count(*)
FROM a
where tot_count = 0 or
	tot_count is null;
-- 0 all set!

-- how does this compare to the old table sent to kevin?
with a as
(
	select state_fips, county_fips, res1 + res2 + res3a + res3b + res3c + res3d + res3e + res3f + 
		res4 + res5 + res6 + com1 + com2 + com3 + com4 + com5 + com6 + 
		com7 + com8 + com9 + com10 + ind1 + ind2 + ind3 + ind4 + ind5 + 
		ind6 + agr1 + rel1 + gov1 + gov2 + edu1 + edu2 as tot_count
	from diffusion_blocks.county_bldg_sqft_by_type
),
b as
(
	select state_fips, county_fips, res1 + res2 + res3a + res3b + res3c + res3d + res3e + res3f + 
		res4 + res5 + res6 + com1 + com2 + com3 + com4 + com5 + com6 + 
		com7 + com8 + com9 + com10 + ind1 + ind2 + ind3 + ind4 + ind5 + 
		ind6 + agr1 + rel1 + gov1 + gov2 + edu1 + edu2 as tot_count
	FROM dgeo.hazus_sf_by_county_and_bldg_type
)
select a.*, b.tot_count
FROM a
left join b
on a.state_fips = b.state_fips
and a.county_fips = b.county_fips
where a.tot_count/b.tot_count not between 0.99 and 1.01;
-- all values are within +/- 1%;

