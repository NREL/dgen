set role 'diffusion-writers';

------------------------------------------------------------------------------------------
-- create table
DROP TABLE IF EXISTS diffusion_blocks.block_bldg_counts;
CREATE TABLE diffusion_blocks.block_bldg_counts AS
SELECT a.pgid, 

	(b.agr1i + b.com1i + b.com10i + b.com2i + b.com3i + b.com4i + b.com5i + b.com6i + 
	b.com7i + b.com8i + b.com9i + b.edu1i + b.edu2i + b.gov1i + b.gov2i + 	b.ind1i + 
	b.ind2i + b.ind3i + b.ind4i + b.ind5i + b.ind6i + b.rel1i + b.res1i + b.res2i + 
	b.res3ai + b.res3bi + b.res3ci + b.res3di + b.res3ei + b.res3fi + b.res4i + 
	b.res5i + b.res6i)::INTEGER as bldg_count_all,

	(b.res1i + b.res2i + b.res3ai + b.res3bi + b.res3ci + b.res3di + b.res3ei + b.res3fi)::INTEGER as bldg_count_res,
	(b.res1i + b.res2i) as bldg_count_res_single_family,
	(b.res3ai + b.res3bi + b.res3ci + b.res3di + b.res3ei + b.res3fi) as bldg_count_res_multi_family,

	(b.res4i + b.res5i + b.res6i + b.com1i + b.com2i + b.com3i + b.com4i + b.com5i + b.com6i + 
	b.com7i + b.com8i + b.com9i + b.com10i + b.rel1i + b.gov1i + b.gov2i + b.edu1i + b.edu2i)::INTEGER as bldg_count_com,

	(b.ind1i + b.ind2i + b.ind3i + b.ind4i + b.ind5i + b.agr1i)::INTEGER  as bldg_count_ind,

	(b.ind1i + b.ind2i + b.ind3i + b.ind4i + b.ind5i)::INTEGER  as bldg_count_mfg,

	b.agr1i::INTEGER as bldg_count_ag
FROM diffusion_blocks.block_geoms a
LEFT JOIN hazus.hzbldgcountoccupb b
ON a.gisjoin = b.census_2010_gisjoin;
-- 10535171 rows

------------------------------------------------------------------------------------------
-- add primary key
ALTER TABLE diffusion_blocks.block_bldg_counts
ADD PRIMARY KEY (pgid);

------------------------------------------------------------------------------------------
-- QA/QC

-- check for nulls
select count(*)
FROM diffusion_blocks.block_bldg_counts
where bldg_count_all is null
OR bldg_count_res is null
or bldg_count_com is null
or bldg_count_ind is null
or bldg_count_mfg is null
or bldg_count_ag is null
OR bldg_count_res_multi_family is null
or bldg_count_res_single_family is null;
-- 0 -- all set