set role 'diffusion-writers';

------------------------------------------------------------------------------------------
-- create table
DROP TABLE IF EXISTS diffusion_blocks.block_housing_units;
CREATE TABLE diffusion_blocks.block_housing_units AS
SELECT a.pgid, b.housing_units
FROM diffusion_blocks.block_geoms a
LEFT JOIN diffusion_data_wind.census_2010_block_housing_units b
ON a.gisjoin = b.gisjoin;
-- 10535171 rows

------------------------------------------------------------------------------------------
-- add primary key
ALTER TABLE diffusion_blocks.block_housing_units
ADD PRIMARY KEY (pgid);

------------------------------------------------------------------------------------------
-- QA/QC

-- make sure no nulls
select count(*)
FROM diffusion_blocks.block_housing_units
where housing_units is null;
-- 0 -- all set