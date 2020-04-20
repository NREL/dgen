set role 'diffusion-writers';
-- fix the scenario_options tables
-- solar
ALTER TABLE diffusion_solar.scenario_options DROP CONSTRAINT scenario_options_load_growth_scenario_fkey;

UPDATE diffusion_solar_config.sceninp_load_growth_scenario
SET load_growth_scenario = regexp_replace(load_growth_scenario, '2013', '2014');

DELETE FROM diffusion_solar.scenario_options;

ALTER TABLE diffusion_solar.scenario_options
  ADD CONSTRAINT scenario_options_load_growth_scenario_fkey FOREIGN KEY (load_growth_scenario)
      REFERENCES diffusion_solar_config.sceninp_load_growth_scenario (load_growth_scenario) MATCH SIMPLE
      ON UPDATE RESTRICT ON DELETE RESTRICT;
-- wind
ALTER TABLE diffusion_wind.scenario_options DROP CONSTRAINT scenario_options_load_growth_scenario_fkey;

UPDATE diffusion_wind_config.sceninp_load_growth_scenario
SET load_growth_scenario = regexp_replace(load_growth_scenario, '2013', '2014');

DELETE FROM diffusion_wind.scenario_options;

ALTER TABLE diffusion_wind.scenario_options
  ADD CONSTRAINT scenario_options_load_growth_scenario_fkey FOREIGN KEY (load_growth_scenario)
      REFERENCES diffusion_wind_config.sceninp_load_growth_scenario (load_growth_scenario) MATCH SIMPLE
      ON UPDATE RESTRICT ON DELETE RESTRICT;


ALTER TABLE diffusion_shared.aeo_load_growth_projections
RENAME TO aeo_load_growth_projections_2013;


DROP TABLE IF EXISTS diffusion_shared.aeo_load_growth_projections_2014;
CREATE TABLE diffusion_shared.aeo_load_growth_projections_2014
(
  scenario text,
  year integer,
  sector_abbr text,
  census_division_abbr character varying(3),
  load_multiplier numeric
);

-- SET ROLE 'server-superusers';
set role 'mgleason_su';
COPY diffusion_shared.aeo_load_growth_projections_2014 
-- FROM '/srv/home/mgleason/data/dg_wind/AEO2014LoadFourScena_v2.csv' 
FROM '/home/mgleason/data/AEO2014LoadFourScena_v2.csv'
WITH CSV HEADER;
-- RESET ROLE;
set role 'diffusion-writers';

-- changre the sector abbr from full sector name to lower-case, 3-letter sector abbr only
UPDATE diffusion_shared.aeo_load_growth_projections_2014 a
SET sector_abbr =  substring(lower(sector_abbr) from 1 for 3);

-- drop "total" sector
DELETE FROM diffusion_shared.aeo_load_growth_projections_2014
where sector_abbr = 'tot';

CREATE INDEX aeo_load_growth_projections_2014_year_btree ON diffusion_shared.aeo_load_growth_projections_2014 USING btree(year);
CREATE INDEX aeo_load_growth_projections_2014_census_division_abbr_btree ON diffusion_shared.aeo_load_growth_projections_2014 USING btree(census_division_abbr);
CREATE INDEX aeo_load_growth_projections_2014_scenario_btree ON diffusion_shared.aeo_load_growth_projections_2014 USING btree(scenario);
CREATE INDEX aeo_load_growth_projections_2014_sector_abbr_btree ON diffusion_shared.aeo_load_growth_projections_2014 USING btree(sector_abbr);

-- compare to the old table
select count(*)*3
FROM diffusion_shared.aeo_load_growth_projections_2013
where year <> 2010;

select count(*)
FROM diffusion_shared.aeo_load_growth_projections_2014;
-- count doesn't match, why????
-- code below eventually revealed that the count doesn't match becasue the new data is missing 
-- one of the scenarios: "AEO 2013 2x Growth Rate of Reference Case"

-- add this scenario by multiplying each load multiplier in aeo 2014 x 2
INSERt INTO diffusion_shared.aeo_load_growth_projections_2014
(scenario, year, sector_abbr, census_division_abbr, load_multiplier)
select 'AEO 2014 2x Growth Rate of Reference Case'::text as scenario, 
	year, sector_abbr, census_division_abbr, 1+(load_multiplier-1)*2 as load_multiplier
from diffusion_shared.aeo_load_growth_projections_2014
where scenario =  'AEO 2014 Reference Case';

-- compare counts again
-- both have 5400 rows

-- change scenario name to lower case
UPDATE diffusion_shared.aeo_load_growth_projections_2014
set scenario = lower(scenario);

VACUUM ANALYZE diffusion_shared.aeo_load_growth_projections_2014;







------------------------------------------------------------------------------------------------------------
-- data validation work
-- compare census_division_abbr
with a as
(
	select distinct(census_division_abbr) as census_division_abbr
	FROM diffusion_shared.aeo_load_growth_projections_2013
),
b as
(
	select distinct(census_division_abbr) as census_division_abbr
	FROM diffusion_shared.aeo_load_growth_projections_2014
)
select a.*, b.*
from a
full outer join b
ON a.census_division_abbr = b.census_division_abbr
order by 1, 2;
-- full match

-- compare year
with a as
(
	select distinct(year) as year
	FROM diffusion_shared.aeo_load_growth_projections_2013
),
b as
(
	select distinct(year) as year
	FROM diffusion_shared.aeo_load_growth_projections_2014
)
select a.*, b.*
from a
full outer join b
ON a.year = b.year
order by 1, 2;

-- compare scenario
with a as
(
	select distinct(scenario) as scenario
	FROM diffusion_shared.aeo_load_growth_projections_2013
),
b as
(
	select distinct(scenario) as scenario
	FROM diffusion_shared.aeo_load_growth_projections_2014
)
select a.*, b.*
from a
full outer join b
ON a.scenario = b.scenario
order by 1, 2;
-- this is the discrepancy


select count(*)
FROM diffusion_shared.aeo_load_growth_projections_2014
group by scenario


-- 
select sector_abbr, year, census_division_abbr, scenario, count(*)
from diffusion_shared.aeo_load_growth_projections_2014
group by sector_abbr, year, census_division_abbr, scenario
order by count;



with a as
(
	SELECT substring(lower(a.scenario) from 9) as scenario, year, unnest(array['res', 'ind', 'com']) as sector_abbr,
		census_division_abbr, load_multiplier, 
		'2013'::text as data_year
	from diffusion_shared.aeo_load_growth_projections_2013 a
),
b as
(
	select substring(b.scenario from 9), year, sector_abbr,
		census_division_abbr, load_multiplier,
		'2014'::text as data_year
	from diffusion_shared.aeo_load_growth_projections_2014 b
)
select *
FROM a
UNION all
select  *
FROM b;

select scenario, census_division_abbr, load_multiplier
from diffusion_shared.aeo_load_growth_projections_2013
where year = 2050
and scenario in ('AEO 2013 Reference Case', 'AEO 2013 2x Growth Rate of Reference Case')