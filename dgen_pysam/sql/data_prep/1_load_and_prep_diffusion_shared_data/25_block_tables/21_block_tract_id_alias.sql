set role 'diffusion-writers';

-- create tract id alias (integer) and assign to block geoms
DROP TABLE IF EXISTS diffusion_blocks.tract_ids;
CREATE TABLE diffusion_blocks.tract_ids AS
SELECT distinct state_fips, county_fips, tract_fips
FROM diffusion_blocks.block_geoms;
-- 72739 rows

-- add the new id field
ALTER TABLE diffusion_blocks.tract_ids
ADD COLUMN tract_id_alias SERIAL PRIMARY key;

------------------------------------------------------------
-- create a new lookup table for block to tract id alias
DROP TABLE IF EXISTS diffusion_blocks.block_tract_id_alias;
CREATE TABLE  diffusion_blocks.block_tract_id_alias AS
SELECT a.pgid, b.tract_id_alias
FROM diffusion_blocks.block_geoms a
LEFT JOIN diffusion_blocks.tract_ids b
	ON a.state_fips = b.state_fips
	and a.county_fips = b.county_fips
	AND a.tract_fips = b.tract_fips;
-- 10535171 rows

-- add primary key
ALTER TABLE diffusion_blocks.block_tract_id_alias
ADD PRIMARY KEY (pgid);

-- add an index
CREATE INDEX block_tract_id_alias_btree_tract_id_alias
ON diffusion_blocks.block_tract_id_alias
USING BTREE(tract_id_alias);

-- QA/QC
-- check for nulls
select count(*)
FROM diffusion_blocks.block_tract_id_alias
where tract_id_alias is null;
-- 0 -- allset