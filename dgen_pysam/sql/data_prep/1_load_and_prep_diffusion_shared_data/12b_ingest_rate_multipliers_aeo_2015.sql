set role 'diffusion-writers';

DROP TABLE IF EXISTS diffusion_shared.aeo_rate_escalations_2015_update;
CREATE TABLE diffusion_shared.aeo_rate_escalations_2015_update
(
  census_division_abbr text,
  sector text,
  year integer,
  escalation_factor numeric,
  source text,
  sector_abbr character varying(3),
  CONSTRAINT sector_abbr_check CHECK (sector_abbr::text = ANY (ARRAY['res'::character varying::text, 'com'::character varying::text, 'ind'::character varying::text])),
  CONSTRAINT sector_check CHECK (sector = ANY (ARRAY['Residential'::text, 'Commercial'::text, 'Industrial'::text])),
  CONSTRAINT census_division_abbr_check CHECK (census_division_abbr = ANY (ARRAY['MTN'::TEXT, 'WSC'::TEXT, 'NE'::TEXT, 'SA'::TEXT, 'ENC'::TEXT, 'MA'::TEXT, 'WNC'::TEXT, 'ESC'::TEXT, 'PAC'::TEXT]))
);

\COPY diffusion_shared.aeo_rate_escalations_2015_update (year, escalation_factor, source, census_division_abbr, sector_abbr) FROM '/Volumes/Staff/mgleason/DG_Solar/Data/Source_Data/aeo_2015/rate_escalation_added_scenarios.csv' with csv header;

-- make sure base year is 2014 (escalations should = 1)
select distinct escalation_factor
from diffusion_shared.aeo_rate_escalations_2015_update
where year = 2014;

-- fill in sectors based on sector_abbr
UPDATE diffusion_shared.aeo_rate_escalations_2015_update
set sector = CASE WHEN sector_abbr = 'res' then 'Residential'
		  WHEN sector_abbr = 'com' then 'Commercial'
		  WHEN sector_abbr = 'ind' then 'Industrial'
		END;

-- check counts of all scenarios/sector/region match
select source, sector, census_division_abbr, count(*)
FROM diffusion_shared.aeo_rate_escalations_2015_update
group by source, sector, census_division_abbr
order by count desc;
-- all have count of 67

-- compare that to the old data?
select source, sector, census_division_abbr, count(*)
FROM diffusion_shared.aeo_rate_escalations_2015
where year >= 2014
group by source, sector, census_division_abbr
order by count desc;
-- also all counts of 67, all set


-- check against old data
select *
from diffusion_shared.aeo_rate_escalations_2015 a
left join diffusion_shared.aeo_rate_escalations_2015_update b
ON a.year = b.year
and a.sector_abbr = b.sector_abbr
and b.source = 'AEO2015 Reference'
and a.census_division_abbr = b.census_division_abbr
where b.year is null;
-- only ones missing are aoe2015 extended years 2012 and 2013 (these are missing in the older data for some reason)

-- clear the old table
delete from diffusion_shared.aeo_rate_escalations_2015;
-- 3726 rows deleted

-- insert rows from the updated table
insert into diffusion_shared.aeo_rate_escalations_2015
select *
FROM diffusion_shared.aeo_rate_escalations_2015_update;
-- 10854 rows

-- drop the "update" table (no longer needed)
DROP TABLE IF EXISTS diffusion_shared.aeo_rate_escalations_2015_update;

-- update table stats
VACUUM ANALYZE diffusion_shared.aeo_rate_escalations_2015;

CREATE INDEX aeo_rate_escalations_2015_btree_census_division_abbr
  ON diffusion_shared.aeo_rate_escalations_2015
  USING btree
  (census_division_abbr COLLATE pg_catalog."default");

CREATE INDEX aeo_rate_escalations_2015_btree_sector
  ON diffusion_shared.aeo_rate_escalations_2015
  USING btree
  (sector COLLATE pg_catalog."default");

CREATE INDEX aeo_rate_escalations_2015_btree_sector_abbr
  ON diffusion_shared.aeo_rate_escalations_2015
  USING btree
  (sector_abbr COLLATE pg_catalog."default");

CREATE INDEX aeo_rate_escalations_2015_btree_source
  ON diffusion_shared.aeo_rate_escalations_2015
  USING btree
  (source COLLATE pg_catalog."default");

CREATE INDEX aeo_rate_escalations_2015_btree_year
  ON diffusion_shared.aeo_rate_escalations_2015
  USING btree
  (year);

---------------------------------------------------------------------------------------------------
-- -- additional, one time changes
-- -- drop the 'AEO2014 Extended' scenario from diffusion_shared.aeo_rate_escalations_2014
-- DELETE FROM diffusion_shared.aeo_rate_escalations_2014
-- where source = 'AEO2014 Extended';
-- -- 1809 rows
-- 
-- -- rename the remaining AEO2014 scenario to AEO2014 Reference
-- UPDATE diffusion_shared.aeo_rate_escalations_2014
-- set source = 'AEO2014 Reference'
-- where source = 'AEO2014';
-- -- 1890 rows
-- 
-- -- confirm changes
-- select distinct source
-- from diffusion_shared.aeo_rate_escalations_2014;
-- -- AEO2014 Reference -- all set
-- 
