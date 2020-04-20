set role 'diffusion-writers';

DROP TABLE IF EXISTS diffusion_shared.state_census_division_abbr_lkup;
CREATE TABLE diffusion_shared.state_census_division_abbr_lkup AS
select distinct state_abbr, census_division_abbr
from diffusion_blocks.county_geoms;

-- add primary key
ALTER TABLE diffusion_shared.state_census_division_abbr_lkup
ADD PRIMARY KEY (state_abbr);

-- QAQC
select *
FROM diffusion_shared.state_census_division_abbr_lkup;
-- 51 rows -- looks good

-- create index on census_division_abbr
CREATE INDEX state_census_division_abbr_lkup_cda_btree
ON diffusion_shared.state_census_division_abbr_lkup
USING BTREE(census_division_abbr);