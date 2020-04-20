set role 'diffusion-writers';

DROP TABLE IF EXISTS diffusion_shared.aeo_load_growth_projections_2015;
CREATE TABLE diffusion_shared.aeo_load_growth_projections_2015
(
  scenario text,
  year integer,
  sector_abbr text,
  census_division_abbr character varying(3),
  load_multiplier numeric
);

\COPY diffusion_shared.aeo_load_growth_projections_2015 FROM '/Volumes/Staff/mgleason/DG_Solar/Data/Source_Data/aeo_2015/aeo_load_growth_projections_2015.csv' with csv header;

select count(*)
FROM diffusion_shared.aeo_load_growth_projections_2015;
-- 5265

CREATE INDEX aeo_load_growth_projections_2015_census_division_abbr_btree
  ON diffusion_shared.aeo_load_growth_projections_2015
  USING btree
  (census_division_abbr COLLATE pg_catalog."default");

CREATE INDEX aeo_load_growth_projections_2015_scenario_btree
  ON diffusion_shared.aeo_load_growth_projections_2015
  USING btree
  (scenario COLLATE pg_catalog."default");

CREATE INDEX aeo_load_growth_projections_2015_sector_abbr_btree
  ON diffusion_shared.aeo_load_growth_projections_2015
  USING btree
  (sector_abbr COLLATE pg_catalog."default");

CREATE INDEX aeo_load_growth_projections_2015_year_btree
  ON diffusion_shared.aeo_load_growth_projections_2015
  USING btree
  (year);


-- confirm everything matches up with the aeo 2014 table
select *
from diffusion_shared.aeo_load_growth_projections_2015 a
LEFT join diffusion_shared.aeo_load_growth_projections_2014 b
	ON a.year = b.year
	and regexp_replace(a.scenario, '2015', '2014') = b.scenario
	and a.sector_abbr = b.sector_abbr
	and a.census_division_abbr = b.census_division_abbr
where b.year is null;
-- all set

