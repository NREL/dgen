set role 'diffusion-writers';

DROP TABLE IF EXISTS diffusion_shared.state_fips_lkup;
CREATE TABLE diffusion_shared.state_fips_lkup AS
select state_abbr, state_fips::integer
from esri.dtl_state_20110101;

-- add primary key
ALTER TABLE diffusion_shared.state_fips_lkup
ADD primary key (state_abbr);

-- add unique constraint
ALTER TABLE diffusion_shared.state_fips_lkup 
ADD CONSTRAINT state_fips_unique UNIQUE (state_fips);

-- check results
select *
FROM diffusion_shared.state_fips_lkup 
order by state_fips;

-- add state fips code to the county geom table
ALTER TABLE diffusion_shared.county_geom
ADD COLUMN state_fips integer;

UPDATE diffusion_shared.county_geom a
set state_fips = b.state_fips
FROM diffusion_shared.state_fips_lkup b
where a.state_abbr = b.state_abbr;

-- check for any nulls
select count(*)
FROM diffusion_shared.county_geom
where state_fips is null;