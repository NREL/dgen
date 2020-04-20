------------------------------------------------------------------------------------------
-- BLOCKS
------------------------------------------------------------------------------------------
-- add primary key to all block geom tables
ALTER TABLE hazus.hz_census_block ADD PRIMARY KEY (censusblock);
ALTER TABLE hazus.hz_census_block_ak ADD PRIMARY KEY (censusblock);
ALTER TABLE hazus.hz_census_block_al ADD PRIMARY KEY (censusblock);
ALTER TABLE hazus.hz_census_block_ar ADD PRIMARY KEY (censusblock);

ALTER TABLE hazus.hz_census_block_az ADD PRIMARY KEY (censusblock);
ALTER TABLE hazus.hz_census_block_ca ADD PRIMARY KEY (censusblock);
ALTER TABLE hazus.hz_census_block_co ADD PRIMARY KEY (censusblock);
ALTER TABLE hazus.hz_census_block_ct ADD PRIMARY KEY (censusblock);
ALTER TABLE hazus.hz_census_block_dc ADD PRIMARY KEY (censusblock);
ALTER TABLE hazus.hz_census_block_de ADD PRIMARY KEY (censusblock);
ALTER TABLE hazus.hz_census_block_fl ADD PRIMARY KEY (censusblock);
ALTER TABLE hazus.hz_census_block_ga ADD PRIMARY KEY (censusblock);
ALTER TABLE hazus.hz_census_block_hi ADD PRIMARY KEY (censusblock);
ALTER TABLE hazus.hz_census_block_ia ADD PRIMARY KEY (censusblock);
ALTER TABLE hazus.hz_census_block_id ADD PRIMARY KEY (censusblock);
ALTER TABLE hazus.hz_census_block_il ADD PRIMARY KEY (censusblock);
ALTER TABLE hazus.hz_census_block_in ADD PRIMARY KEY (censusblock);
ALTER TABLE hazus.hz_census_block_ks ADD PRIMARY KEY (censusblock);
ALTER TABLE hazus.hz_census_block_ky ADD PRIMARY KEY (censusblock);
ALTER TABLE hazus.hz_census_block_la ADD PRIMARY KEY (censusblock);
ALTER TABLE hazus.hz_census_block_ma ADD PRIMARY KEY (censusblock);
ALTER TABLE hazus.hz_census_block_md ADD PRIMARY KEY (censusblock);
ALTER TABLE hazus.hz_census_block_me ADD PRIMARY KEY (censusblock);
ALTER TABLE hazus.hz_census_block_mi ADD PRIMARY KEY (censusblock);
ALTER TABLE hazus.hz_census_block_mn ADD PRIMARY KEY (censusblock);
ALTER TABLE hazus.hz_census_block_mo ADD PRIMARY KEY (censusblock);
ALTER TABLE hazus.hz_census_block_ms ADD PRIMARY KEY (censusblock);
ALTER TABLE hazus.hz_census_block_mt ADD PRIMARY KEY (censusblock);
ALTER TABLE hazus.hz_census_block_nc ADD PRIMARY KEY (censusblock);
ALTER TABLE hazus.hz_census_block_nd ADD PRIMARY KEY (censusblock);
ALTER TABLE hazus.hz_census_block_ne ADD PRIMARY KEY (censusblock);
ALTER TABLE hazus.hz_census_block_nh ADD PRIMARY KEY (censusblock);
ALTER TABLE hazus.hz_census_block_nj ADD PRIMARY KEY (censusblock);
ALTER TABLE hazus.hz_census_block_nm ADD PRIMARY KEY (censusblock);
ALTER TABLE hazus.hz_census_block_nv ADD PRIMARY KEY (censusblock);
ALTER TABLE hazus.hz_census_block_ny ADD PRIMARY KEY (censusblock);
ALTER TABLE hazus.hz_census_block_oh ADD PRIMARY KEY (censusblock);
ALTER TABLE hazus.hz_census_block_ok ADD PRIMARY KEY (censusblock);
ALTER TABLE hazus.hz_census_block_or ADD PRIMARY KEY (censusblock);
ALTER TABLE hazus.hz_census_block_pa ADD PRIMARY KEY (censusblock);
ALTER TABLE hazus.hz_census_block_pr ADD PRIMARY KEY (censusblock);
ALTER TABLE hazus.hz_census_block_ri ADD PRIMARY KEY (censusblock);
ALTER TABLE hazus.hz_census_block_sc ADD PRIMARY KEY (censusblock);
ALTER TABLE hazus.hz_census_block_sd ADD PRIMARY KEY (censusblock);
ALTER TABLE hazus.hz_census_block_tn ADD PRIMARY KEY (censusblock);
ALTER TABLE hazus.hz_census_block_tx ADD PRIMARY KEY (censusblock);
ALTER TABLE hazus.hz_census_block_ut ADD PRIMARY KEY (censusblock);
ALTER TABLE hazus.hz_census_block_va ADD PRIMARY KEY (censusblock);
ALTER TABLE hazus.hz_census_block_vt ADD PRIMARY KEY (censusblock);
ALTER TABLE hazus.hz_census_block_wa ADD PRIMARY KEY (censusblock);
ALTER TABLE hazus.hz_census_block_wi ADD PRIMARY KEY (censusblock);
ALTER TABLE hazus.hz_census_block_wv ADD PRIMARY KEY (censusblock);
ALTER TABLE hazus.hz_census_block_wy ADD PRIMARY KEY (censusblock);
------------------------------------------------------------------------------------------

-- also add primary key to building count and square footage tables
ALTER TABLE hazus.hzbldgcountoccupb ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzbldgcountoccupb_ak ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzbldgcountoccupb_al ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzbldgcountoccupb_ar ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzbldgcountoccupb_az ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzbldgcountoccupb_ca ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzbldgcountoccupb_co ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzbldgcountoccupb_ct ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzbldgcountoccupb_dc ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzbldgcountoccupb_de ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzbldgcountoccupb_fl ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzbldgcountoccupb_ga ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzbldgcountoccupb_hi ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzbldgcountoccupb_ia ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzbldgcountoccupb_id ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzbldgcountoccupb_il ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzbldgcountoccupb_in ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzbldgcountoccupb_ks ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzbldgcountoccupb_ky ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzbldgcountoccupb_la ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzbldgcountoccupb_ma ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzbldgcountoccupb_md ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzbldgcountoccupb_me ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzbldgcountoccupb_mi ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzbldgcountoccupb_mn ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzbldgcountoccupb_mo ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzbldgcountoccupb_ms ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzbldgcountoccupb_mt ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzbldgcountoccupb_nc ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzbldgcountoccupb_nd ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzbldgcountoccupb_ne ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzbldgcountoccupb_nh ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzbldgcountoccupb_nj ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzbldgcountoccupb_nm ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzbldgcountoccupb_nv ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzbldgcountoccupb_ny ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzbldgcountoccupb_oh ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzbldgcountoccupb_ok ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzbldgcountoccupb_or ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzbldgcountoccupb_pa ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzbldgcountoccupb_pr ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzbldgcountoccupb_ri ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzbldgcountoccupb_sc ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzbldgcountoccupb_sd ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzbldgcountoccupb_tn ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzbldgcountoccupb_tx ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzbldgcountoccupb_ut ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzbldgcountoccupb_va ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzbldgcountoccupb_vt ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzbldgcountoccupb_wa ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzbldgcountoccupb_wi ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzbldgcountoccupb_wv ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzbldgcountoccupb_wy ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzsqfootageoccupb ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzsqfootageoccupb_ak ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzsqfootageoccupb_al ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzsqfootageoccupb_ar ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzsqfootageoccupb_az ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzsqfootageoccupb_ca ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzsqfootageoccupb_co ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzsqfootageoccupb_ct ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzsqfootageoccupb_dc ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzsqfootageoccupb_de ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzsqfootageoccupb_fl ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzsqfootageoccupb_ga ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzsqfootageoccupb_hi ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzsqfootageoccupb_ia ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzsqfootageoccupb_id ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzsqfootageoccupb_il ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzsqfootageoccupb_in ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzsqfootageoccupb_ks ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzsqfootageoccupb_ky ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzsqfootageoccupb_la ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzsqfootageoccupb_ma ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzsqfootageoccupb_md ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzsqfootageoccupb_me ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzsqfootageoccupb_mi ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzsqfootageoccupb_mn ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzsqfootageoccupb_mo ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzsqfootageoccupb_ms ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzsqfootageoccupb_mt ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzsqfootageoccupb_nc ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzsqfootageoccupb_nd ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzsqfootageoccupb_ne ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzsqfootageoccupb_nh ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzsqfootageoccupb_nj ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzsqfootageoccupb_nm ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzsqfootageoccupb_nv ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzsqfootageoccupb_ny ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzsqfootageoccupb_oh ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzsqfootageoccupb_ok ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzsqfootageoccupb_or ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzsqfootageoccupb_pa ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzsqfootageoccupb_pr ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzsqfootageoccupb_ri ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzsqfootageoccupb_sc ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzsqfootageoccupb_sd ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzsqfootageoccupb_tn ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzsqfootageoccupb_tx ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzsqfootageoccupb_ut ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzsqfootageoccupb_va ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzsqfootageoccupb_vt ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzsqfootageoccupb_wa ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzsqfootageoccupb_wi ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzsqfootageoccupb_wv ADD PRIMARY KEY(censusblock);
ALTER TABLE hazus.hzsqfootageoccupb_wy ADD PRIMARY KEY(censusblock);

------------------------------------------------------------------------------------------
-- TRACTS
------------------------------------------------------------------------------------------
-- add primary keys to tract tables
ALTER TABLE hazus.hzbldgcountoccupt ADD PRIMARY KEY (tract);
ALTER TABLE hazus.hzsqfootageoccupt ADD PRIMARY KEY (tract);
ALTER TABLE hazus.hz_tract ADD PRIMARY KEY (tract);

------------------------------------------------------------------------------------------

-- CHECK TABLE COMPLETENESS


-- check counts of all tables
SELECT COUNT(*) FROM hazus.hzbldgcountoccupb; -- 11098632
SELECT COUNT(*) FROM hazus.hzsqfootageoccupb; -- 11098632
SELECT COUNT(*) FROM hazus.hz_census_block; -- 11096649
-- something is screwy.. same issue occurs in tracts

-- look into what is happening
select count(*)
FROM hazus.hzbldgcountoccupb a
FULL OUTER join  hazus.hzsqfootageoccupb b
ON a.censusblock = b.censusblock
where a.censusblock is null
or b.censusblock is null;
-- 0 -- these two match perfectly

select count(*)
FROM hazus.hzsqfootageoccupb a
FULL OUTER join  hazus.hz_census_block b
ON a.censusblock = b.censusblock
where a.censusblock is null
or b.censusblock is null;
-- 35 tracts are missing from the tract table
-- which ones?
select *
FROM hazus.hzsqfootageoccupb a
FULL OUTER join  hazus.hz_census_block b
ON a.censusblock = b.censusblock
where a.censusblock is null
or b.censusblock is null;






-- make sure row counts match across tables
SELECT COUNT(*) FROM hazus.hzbldgcountoccupt; -- 73669
SELECT COUNT(*) FROM hazus.hzsqfootageoccupt; -- 73669
SELECT COUNT(*) FROM hazus.hz_tract; -- 73634

-- the count tables are identical
select count(*)
FROM hazus.hzsqfootageoccupt a
FULL OUTER join  hazus.hzbldgcountoccupt b
ON a.tract = b.tract
where a.tract is null
or b.tract is null;


select count(*)
FROM hazus.hzsqfootageoccupt a
FULL OUTER join  hazus.hz_tract b
ON a.tract = b.tract
where a.tract is null
or b.tract is null;
-- 35 tracts are missing from the tract table
-- which ones?

select a.*
FROM hazus.hzsqfootageoccupt a
FULL OUTER join  hazus.hz_tract b
ON a.tract = b.tract
where a.tract is null
or b.tract is null;
------------------------------------------------------------------------------------------
