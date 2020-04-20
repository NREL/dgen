set role 'diffusion-writers';

-- check that the bldg types represented in HAZUS can be reproduced in CBECS
DROP TABLE IF EXISTS diffusion_data_shared.com_bldg_type_representation_check;
CREATE TABLE diffusion_data_shared.com_bldg_type_representation_check AS
with a as
(
	select b.division_abbr as census_division_abbr, 
		sum(a.com1i::INTEGER) as com1,
		sum(a.com2i::INTEGER) as com2,
		sum(a.com3i::INTEGER) as com3,
		sum(a.com4i::INTEGER) as com4,
		sum(a.com5i::INTEGER) as com5,
		sum(a.com6i::INTEGER) as com6,
		sum(a.com7i::INTEGER) as com7,
		sum(a.com8i::INTEGER) as com8,
		sum(a.com9i::INTEGER) as com9,
		sum(a.com10i::INTEGER) as com10,
		sum(a.edu1i::INTEGER) as edu1,
		sum(a.edu2i::INTEGER) as edu2,
		sum(a.gov1i::INTEGER) as gov1,
		sum(a.gov2i::INTEGER) as gov2,
		sum(a.rel1i::INTEGER) as rel1,
		sum(a.res4i::INTEGER) as res4,
		sum(a.res5i::INTEGER) as res5,
		sum(a.res6i::INTEGER) as res6,
		sum(a.com1i::INTEGER + a.com2i::INTEGER + a.com3i::INTEGER + a.com4i::INTEGER + a.com5i::INTEGER +  
			a.com6i::INTEGER + a.com7i::INTEGER + a.com8i::INTEGER + a.com9i::INTEGER + a.com10i::INTEGER +  
			a.edu1i::INTEGER + a.edu2i::INTEGER + a.gov1i::INTEGER + a.gov2i::INTEGER +  a.rel1i::INTEGER +  
			a.res4i::INTEGER + a.res5i::INTEGER + a.res6i::INTEGER) as bldgs
	from hazus.hzbldgcountoccupb a
	left join eia.census_regions_20140123 b
	ON substring(a.census_2010_gisjoin, 2, 2) = b.statefp
	GROUP by b.division_abbr
),
b as
(
	select census_division_abbr, 
		sum((b.cdms = 'com1')::INTEGER) as com1,
		sum((b.cdms = 'com2')::INTEGER) as com2,
		sum((b.cdms = 'com3')::INTEGER) as com3,
		sum((b.cdms = 'com4')::INTEGER) as com4,
		sum((b.cdms = 'com5')::INTEGER) as com5,
		sum((b.cdms = 'com6')::INTEGER) as com6,
		sum((b.cdms = 'com7')::INTEGER) as com7,
		sum((b.cdms = 'com8')::INTEGER) as com8,
		sum((b.cdms = 'com9')::INTEGER) as com9,
		sum((b.cdms = 'com10')::INTEGER) as com10,
		sum((b.cdms = 'edu1')::INTEGER) as edu1,
		sum((b.cdms = 'edu2')::INTEGER) as edu2,
		sum((b.cdms = 'gov1')::INTEGER) as gov1,
		sum((b.cdms = 'gov2')::INTEGER) as gov2,
		sum((b.cdms = 'rel1')::INTEGER) as rel1,
		sum((b.cdms = 'res4')::INTEGER) as res4,
		sum((b.cdms = 'res5')::INTEGER) as res5,
		sum((b.cdms = 'res6')::INTEGER) as res6
	from diffusion_shared.eia_microdata_cbecs_2003_expanded a
	LEFT JOIN diffusion_shared.cdms_bldg_types_to_pba_plus_lkup b
	ON a.pbaplus = b.pbaplus
	group by census_division_abbr
)
select a.census_division_abbr,
	(a.com1 > 0 and b.com1 = 0) as com1_not_represented,
	(a.com2 > 0 and b.com2 = 0) as com2_not_represented,
	(a.com3 > 0 and b.com3 = 0) as com3_not_represented,
	(a.com4 > 0 and b.com4 = 0) as com4_not_represented,
	(a.com5 > 0 and b.com5 = 0) as com5_not_represented,
	(a.com6 > 0 and b.com6 = 0) as com6_not_represented,
	(a.com7 > 0 and b.com7 = 0) as com7_not_represented,
	(a.com8 > 0 and b.com8 = 0) as com8_not_represented,
	(a.com9 > 0 and b.com9 = 0) as com9_not_represented,
	(a.com10 > 0 and b.com10 = 0) as com10_not_represented,
	(a.edu1 > 0 and b.edu1 = 0) as edu1_not_represented,
	(a.edu2 > 0 and b.edu2 = 0) as edu2_not_represented,
	(a.gov1 > 0 and b.gov1 = 0) as gov1_not_represented,
	(a.gov2 > 0 and b.gov2 = 0) as gov2_not_represented,
	(a.rel1 > 0 and b.rel1 = 0) as rel1_not_represented,
	(a.res4 > 0 and b.res4 = 0) as res4_not_represented,
	(a.res5 > 0 and b.res5 = 0) as res5_not_represented,
	(a.res6 > 0 and b.res6 = 0) as res6_not_represented,
	a.com1 as hazus_com1, b.com1 as cbecs_com1,
	a.com2 as hazus_com2, b.com2 as cbecs_com2,
	a.com3 as hazus_com3, b.com3 as cbecs_com3,
	a.com4 as hazus_com4, b.com4 as cbecs_com4,
	a.com5 as hazus_com5, b.com5 as cbecs_com5,
	a.com6 as hazus_com6, b.com6 as cbecs_com6,
	a.com7 as hazus_com7, b.com7 as cbecs_com7,
	a.com8 as hazus_com8, b.com8 as cbecs_com8,
	a.com9 as hazus_com9, b.com9 as cbecs_com9,
	a.com10 as hazus_com10, b.com10 as cbecs_com10,
	a.edu1 as hazus_edu1, b.edu1 as cbecs_edu1,
	a.edu2 as hazus_edu2, b.edu2 as cbecs_edu2,
	a.gov1 as hazus_gov1, b.gov1 as cbecs_gov1,
	a.gov2 as hazus_gov2, b.gov2 as cbecs_gov2,
	a.rel1 as hazus_rel1, b.rel1 as cbecs_rel1,
	a.res4 as hazus_res4, b.res4 as cbecs_res4,
	a.res5 as hazus_res5, b.res5 as cbecs_res5,
	a.res6 as hazus_res6, b.res6 as cbecs_res6,
	a.bldgs
from a
left join b
ON a.census_division_abbr = b.census_division_abbr
where a.census_division_abbr is not null;
-- 9 rows

-- check results
select *
FROM diffusion_data_shared.com_bldg_type_representation_check;

-- check for problematic bldg types
SELECT count(*) 
FROM diffusion_data_shared.com_bldg_type_representation_check 
WHERE com1_not_represented = TRUE;

SELECT count(*) 
FROM diffusion_data_shared.com_bldg_type_representation_check 
WHERE com2_not_represented = TRUE;

SELECT count(*) 
FROM diffusion_data_shared.com_bldg_type_representation_check 
WHERE com3_not_represented = TRUE;

SELECT count(*) 
FROM diffusion_data_shared.com_bldg_type_representation_check 
WHERE com4_not_represented = TRUE;

SELECT count(*) 
FROM diffusion_data_shared.com_bldg_type_representation_check 
WHERE com5_not_represented = TRUE;

SELECT count(*) 
FROM diffusion_data_shared.com_bldg_type_representation_check 
WHERE com6_not_represented = TRUE;

SELECT count(*) 
FROM diffusion_data_shared.com_bldg_type_representation_check 
WHERE com7_not_represented = TRUE;

SELECT count(*) 
FROM diffusion_data_shared.com_bldg_type_representation_check 
WHERE com8_not_represented = TRUE;

SELECT count(*) 
FROM diffusion_data_shared.com_bldg_type_representation_check 
WHERE com9_not_represented = TRUE;

SELECT count(*) 
FROM diffusion_data_shared.com_bldg_type_representation_check 
WHERE com10_not_represented = TRUE;

SELECT count(*) 
FROM diffusion_data_shared.com_bldg_type_representation_check 
WHERE edu1_not_represented = TRUE;

SELECT count(*) 
FROM diffusion_data_shared.com_bldg_type_representation_check 
WHERE edu2_not_represented = TRUE;

SELECT count(*) 
FROM diffusion_data_shared.com_bldg_type_representation_check 
WHERE gov1_not_represented = TRUE;

SELECT count(*) 
FROM diffusion_data_shared.com_bldg_type_representation_check 
WHERE gov2_not_represented = TRUE;

SELECT count(*) 
FROM diffusion_data_shared.com_bldg_type_representation_check 
WHERE rel1_not_represented = TRUE;

SELECT count(*) 
FROM diffusion_data_shared.com_bldg_type_representation_check 
WHERE res4_not_represented = TRUE;

SELECT count(*) 
FROM diffusion_data_shared.com_bldg_type_representation_check 
WHERE res5_not_represented = TRUE;

SELECT count(*) 
FROM diffusion_data_shared.com_bldg_type_representation_check 
WHERE res6_not_represented = TRUE;

-- 0 across ALL -- perfect
-- this means we are all set to attribute the com pts
-- with the hazus bldg type frequencies without any necessary modifications

