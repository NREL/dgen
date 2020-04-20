set role 'diffusion-writers';

------------------------------------------------------------------------------------------
-- create table
DROP TABLE IF EXISTS diffusion_blocks.block_bldg_types;
CREATE TABLE diffusion_blocks.block_bldg_types AS
SELECT a.pgid, 

	ARRAY[
		b.agr1i::INTEGER, b.com1i::INTEGER, b.com10i::INTEGER, b.com2i::INTEGER, b.com3i::INTEGER, 
		b.com4i::INTEGER, b.com5i::INTEGER, b.com6i::INTEGER, b.com7i::INTEGER, b.com8i::INTEGER, 
		b.com9i::INTEGER, b.edu1i::INTEGER, b.edu2i::INTEGER, b.gov1i::INTEGER, b.gov2i::INTEGER, 
		b.ind1i::INTEGER, b.ind2i::INTEGER, b.ind3i::INTEGER, b.ind4i::INTEGER, b.ind5i::INTEGER, 
		b.ind6i::INTEGER, b.rel1i::INTEGER, b.res1i::INTEGER, b.res2i::INTEGER, b.res3ai::INTEGER, 
		b.res3bi::INTEGER, b.res3ci::INTEGER, b.res3di::INTEGER, b.res3ei::INTEGER, b.res3fi::INTEGER,
		b.res4i::INTEGER, b.res5i::INTEGER, b.res6i::INTEGER
	     ]  as bldg_probs_all,

	ARRAY[
		b.res1i::INTEGER, b.res2i::INTEGER, b.res3ai::INTEGER, b.res3bi::INTEGER, b.res3ci::INTEGER, 
		b.res3di::INTEGER, b.res3ei::INTEGER, b.res3fi::INTEGER
	     ] as bldg_probs_res,

	array[
		b.res4i::INTEGER, b.res5i::INTEGER, b.res6i::INTEGER, b.com1i::INTEGER, b.com2i::INTEGER, 
		b.com3i::INTEGER, b.com4i::INTEGER, b.com5i::INTEGER, b.com6i::INTEGER, b.com7i::INTEGER, 
		b.com8i::INTEGER, b.com9i::INTEGER, b.com10i::INTEGER, b.rel1i::INTEGER, b.gov1i::INTEGER, 
		b.gov2i::INTEGER, b.edu1i::INTEGER, b.edu2i::INTEGER
	     ] bldg_probs_com,

	ARRAY[
		b.ind1i::INTEGER, b.ind2i::INTEGER, b.ind3i::INTEGER, b.ind4i::INTEGER, b.ind5i::INTEGER, 
		b.agr1i::INTEGER
	     ]  as bldg_probs_ind,

	ARRAY[
		b.ind1i::INTEGER, b.ind2i::INTEGER, b.ind3i::INTEGER, b.ind4i::INTEGER, b.ind5i::INTEGER
	     ]  as bldg_probs_mfg,

	array[
		b.agr1i::INTEGER
	     ] as bldg_probs_ag
FROM diffusion_blocks.block_geoms a
LEFT JOIN hazus.hzbldgcountoccupb b
ON a.gisjoin = b.census_2010_gisjoin;
-- 10535171 rows

------------------------------------------------------------------------------------------
-- add primary key
ALTER TABLE diffusion_blocks.block_bldg_types
ADD PRIMARY KEY (pgid);

------------------------------------------------------------------------------------------
-- QA/QC

-- check for nulls
select count(*)
FROM diffusion_blocks.block_bldg_types
where bldg_probs_all is null
OR bldg_probs_res is null
or bldg_probs_com is null
or bldg_probs_ind is null
or bldg_probs_mfg is null
or bldg_probs_ag is null;
-- 0 -- all set