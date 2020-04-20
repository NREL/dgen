set role 'diffusion-writers';

------------------------------------------------------------------------------------------
-- combine aeo 2014 and 2015 tables
DROP TABLE IF EXISTS diffusion_shared.aeo_load_growth_projections;
CREATE TABLE diffusion_shared.aeo_load_growth_projections AS
select *
FROM  diffusion_shared.aeo_load_growth_projections_2014 a
UNION ALL
SELECT *
FROM diffusion_shared.aeo_load_growth_projections_2015;

-- create indices

CREATE INDEX aeo_load_growth_projections_btree_census_division_abbr
  ON diffusion_shared.aeo_load_growth_projections
  USING btree(census_division_abbr);

CREATE INDEX aeo_load_growth_projections_btree_scenario
  ON diffusion_shared.aeo_load_growth_projections
  USING btree(scenario);

CREATE INDEX aeo_load_growth_projections_btree_sector_abbr
  ON diffusion_shared.aeo_load_growth_projections
  USING btree(sector_abbr);

CREATE INDEX aeo_load_growth_projections_btree_year
  ON diffusion_shared.aeo_load_growth_projections
  USING btree(year);

VACUUM ANALYZE diffusion_shared.aeo_load_growth_projections;