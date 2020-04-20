SET ROLE 'diffusion-writers';
DROP TABLE IF EXISTS diffusion_shared.eia_microdata_cbecs_2003 CASCADE;
CREATE TABLE diffusion_shared.eia_microdata_cbecs_2003 AS
select a.pubid8, a.region8, a.cendiv8, a.climate8,
	a.pba8,
	b.pbaplus8,
	a.ownocc8,
	a.nocc8,
	a.sqft8,
	a.nfloor8,
	a.rfcns8,
	a.adjwt8::NUMERIC,
	c.elcns8
from eia.cbecs_2003_microdata_file_01 a
left join eia.cbecs_2003_microdata_file_02 b
on a.pubid8 = b.pubid8
left join eia.cbecs_2003_microdata_file_15 c
on a.pubid8 = c.pubid8;
-- 5215 rows

-- drop any records where elcns8 is null
delete from diffusion_shared.eia_microdata_cbecs_2003
where elcns8 is null;
-- 108 rows deleted

-- add primary key
ALTER TABLE diffusion_shared.eia_microdata_cbecs_2003
ADD PRIMARY KEY (pubid8);

COMMENT ON COLUMN diffusion_shared.eia_microdata_cbecs_2003.pubid8 IS 'building identifier';
COMMENT ON COLUMN diffusion_shared.eia_microdata_cbecs_2003.region8 IS 'Census region ';
COMMENT ON COLUMN diffusion_shared.eia_microdata_cbecs_2003.cendiv8 IS 'Census division';
COMMENT ON COLUMN diffusion_shared.eia_microdata_cbecs_2003.climate8 IS 'Climate Zone';
COMMENT ON COLUMN diffusion_shared.eia_microdata_cbecs_2003.pba8 IS 'principal building activity';
COMMENT ON COLUMN diffusion_shared.eia_microdata_cbecs_2003.pbaplus8 IS 'More specific building activity';
COMMENT ON COLUMN diffusion_shared.eia_microdata_cbecs_2003.ownocc8 IS 'Owner occupies space';
COMMENT ON COLUMN diffusion_shared.eia_microdata_cbecs_2003.nocc8 IS 'Number of businesses';
COMMENT ON COLUMN diffusion_shared.eia_microdata_cbecs_2003.sqft8 IS 'Square footage';
COMMENT ON COLUMN diffusion_shared.eia_microdata_cbecs_2003.nfloor8 IS 'Number of floors';
COMMENT ON COLUMN diffusion_shared.eia_microdata_cbecs_2003.rfcns8 IS 'Roof construction material';
COMMENT ON COLUMN diffusion_shared.eia_microdata_cbecs_2003.adjwt8 IS 'Final full sample building weight';
COMMENT ON COLUMN diffusion_shared.eia_microdata_cbecs_2003.elcns8 IS 'Annual electricity consumption (kWh)';

-- check for nocc8 values that are not meaningful
select max(nocc8)
FROM diffusion_shared.eia_microdata_cbecs_2003;
-- 2100 -- all set -- no values above 99996

-- add indices on ownocc8, pba, pbaplus, and climate8
CREATE INDEX eia_microdata_cbecs_2003_ownocc8_btree
ON diffusion_shared.eia_microdata_cbecs_2003
using btree(ownocc8);

CREATE INDEX eia_microdata_cbecs_2003_pba8_btree
ON diffusion_shared.eia_microdata_cbecs_2003
using btree(pba8);

CREATE INDEX eia_microdata_cbecs_2003_pbaplus8_btree
ON diffusion_shared.eia_microdata_cbecs_2003
using btree(pbaplus8);

CREATE INDEX eia_microdata_cbecs_2003_climate8_btree
ON diffusion_shared.eia_microdata_cbecs_2003
using btree(climate8);

-- add lookup table for pba8
DROP TABLE IF EXISTS diffusion_shared_data.eia_microdata_cbecs_2003_pba_lookup;
CREATE TABLE  diffusion_shared_data.eia_microdata_cbecs_2003_pba_lookup (
	pba8	integer primary key,
	description text
);
SET ROLE 'server-superusers';
COPY diffusion_shared_data.eia_microdata_cbecs_2003_pba_lookup 
FROM '/srv/home/mgleason/data/dg_wind/pba8_lookup.csv' with csv header QUOTE '''';
SET ROLE 'diffusion-writers';

-- add lookup table for pbaplus8
DROP TABLE IF EXISTS diffusion_shared_data.eia_microdata_cbecs_2003_pbaplus8_lookup;
CREATE TABLE  diffusion_shared_data.eia_microdata_cbecs_2003_pbaplus8_lookup (
	pbaplus8	integer primary key,
	description text
);
SET ROLE 'server-superusers';
COPY diffusion_shared_data.eia_microdata_cbecs_2003_pbaplus8_lookup 
FROM '/srv/home/mgleason/data/dg_wind/pbaplus8_lookup.csv' with csv header QUOTE '''';
SET ROLE 'diffusion-writers';

-- extract all of the disctinct pba/pbaplus8 building uses
SET ROLE 'server-superusers';
COPY 
(
	with a as
	(
		SELECT pba8, pbaplus8
		from diffusion_shared.eia_microdata_cbecs_2003
		group by pba8, pbaplus8
	)
	SELECT a.pba8, b.description as pba8_desc,
	       a.pbaplus8, c.description as pbaplus8_desc
	FROM a
	left join diffusion_shared_data.eia_microdata_cbecs_2003_pba_lookup b
	ON a.pba8 = b.pba8
	LEFT JOIN diffusion_shared_data.eia_microdata_cbecs_2003_pbaplus8_lookup c
	on a.pbaplus8 = c.pbaplus8
	order by a.pba8, a.pbaplus8
) TO '/srv/home/mgleason/data/dg_wind/cbecs_to_eplus_commercial_building_types.csv' with csv header;
SET ROLE 'diffusion-writers';

-- manually edit this table to identify the DOE Commercial Building Type (there 16)
-- associated with each pba8/pbaplus8 combination
-- use http://www.nrel.gov/docs/fy11osti/46861.pdf as a starting point
-- then reload the resulting lookup table to diffusion_shared.cbecs_pba8_pbaplus8_to_eplus_bldg_types

-- add descriptions for census region
ALTER TABLE diffusion_shared.eia_microdata_cbecs_2003
ADD COLUMN census_region text;

UPDATE diffusion_shared.eia_microdata_cbecs_2003
SET census_region = 
	CASE WHEN region8 = 1 THEN 'Northeast'
	     WHEN region8 = 2 THEN 'Midwest'
	     WHEN region8 = 3 then 'South'
	     WHEN region8 = 4 then 'West'
	END;


ALTER TABLE diffusion_shared.eia_microdata_cbecs_2003
ADD COLUMN census_division_abbr text;

UPDATE diffusion_shared.eia_microdata_cbecs_2003
SET census_division_abbr = 
	CASE WHEN cendiv8 = 1 THEN 'NE'
		WHEN cendiv8 = 2 THEN 'MA'
		WHEN cendiv8 = 3 THEN 'ENC'
		WHEN cendiv8 = 4 THEN 'WNC'
		WHEN cendiv8 = 5 THEN 'SA'
		WHEN cendiv8 = 6 THEN 'ESC'
		WHEN cendiv8 = 7 THEN 'WSC'
		WHEN cendiv8 = 8 THEN 'MTN'
		WHEN cendiv8 = 9 THEN 'PAC'
	END;


-- add indices
CREATE INDEX eia_microdata_cbecs_2003_census_region_btree 
ON diffusion_shared.eia_microdata_cbecs_2003
USING btree(census_region);

CREATE INDEX eia_microdata_cbecs_2003_census_division_abbr_btree 
ON diffusion_shared.eia_microdata_cbecs_2003
USING btree(census_division_abbr);

-- load cbecs pba/pbaplus to Energy Plus Commercial Reference Buildings
-- lookup table
SET role 'diffusion-writers';
DROP TABLE IF EXISTS diffusion_shared_data.cbecs_2003_pba_to_eplus_crbs;
CREATE TABLE diffusion_shared_data.cbecs_2003_pba_to_eplus_crbs
(
	pba8 integer,
	pba8_desc text,
	pbaplus8 integer,
	pbaplus8_desc text,
	sqft_min numeric,
	sqft_max numeric,
	crb_model text,
	defined_by text,
	notes text
);

SET ROLE 'server-superusers';
COPY diffusion_shared_data.cbecs_2003_pba_to_eplus_crbs 
FROM '/srv/home/mgleason/data/dg_wind/cbecs_to_eplus_commercial_building_types.csv' 
with csv header;
SET ROLE 'diffusion-writers';

-- create indices on pba8 and pbaplus 8
CREATE INDEX cbecs_2003_pba_to_eplus_crbs_pba8_btree
ON diffusion_shared_data.cbecs_2003_pba_to_eplus_crbs 
using btree(pba8);

CREATE INDEX cbecs_2003_pba_to_eplus_crbs_pbaplus8_btree
ON diffusion_shared_data.cbecs_2003_pba_to_eplus_crbs 
using btree(pbaplus8);

-- create a simple lookup table for all non-vacant
-- cbecs buildings that gives the commercial reference building model
DROP TABLE IF EXISTS diffusion_shared.cbecs_2003_crb_lookup;
CREATE TABLE diffusion_shared.cbecs_2003_crb_lookup AS
with a AS
(
	SELECT a.pubid8, a.sqft8, b.*
	FROM diffusion_shared.eia_microdata_cbecs_2003 a
	LEFT JOIN diffusion_data_shared.cbecs_2003_pba_to_eplus_crbs b
	ON a.pba8 = b.pba8
	and a.pbaplus8 = b.pbaplus8
	where a.pba8 <> 1 -- ignore vacant buildings
)
select pubid8, crb_model
FROM a
where (sqft_min is null and sqft_max is null)
or (sqft8 >= sqft_min and sqft8 < sqft_max);
-- 5019 rows


-- does that match the count of nonvacant buldings?
select count(*)
FROM diffusion_shared.eia_microdata_cbecs_2003
where pba8 <> 1;
-- yes-- 5019

-- do all buildings have a crb?
SELECT count(*)
FROM diffusion_shared.cbecs_2003_crb_lookup
where crb_model is null;
-- 0 -- yes

-- add this information back into the main table
ALTER TABLE diffusion_shared.eia_microdata_cbecs_2003
ADD COLUMN crb_model text;

UPDATE diffusion_shared.eia_microdata_cbecs_2003 a
SET crb_model = b.crb_model
FROM diffusion_shared.cbecs_2003_crb_lookup b
where a.pubid8 = b.pubid8;
-- 5019 updated

-- add an index
CREATE INDEX eia_microdata_cbecs_2003_crb_model_btree
ON diffusion_shared.eia_microdata_cbecs_2003 
using btree(crb_model);

-- drop the lookup table
DROP TABLE IF EXIStS diffusion_shared.cbecs_2003_crb_lookup;

SELECT count(*)
FROM diffusion_shared.eia_microdata_cbecs_2003
where crb_model is null
and pba8 <> 1;

-----------------------------------------------------------------
-- Residential Energy Consumption Survey
DROP TABLE IF EXISTS diffusion_shared.eia_microdata_recs_2009;
CREATE TABLE diffusion_shared.eia_microdata_recs_2009 AS
SELECT doeid, regionc, division, reportable_domain, climate_region_pub,
	typehuq,
	nweight::NUMERIC,
	kownrent,
	kwh,
	rooftype,
	stories,
	totsqft
FROM eia.recs_2009_microdata;

-- add primary key
ALTER TABLE diffusion_shared.eia_microdata_recs_2009
ADD PRIMARY KEY (doeid);

COMMENT ON COLUMN diffusion_shared.eia_microdata_recs_2009.doeid IS 'Unique identifier for each respondent';
COMMENT ON COLUMN diffusion_shared.eia_microdata_recs_2009.regionc IS 'Census Region';
COMMENT ON COLUMN diffusion_shared.eia_microdata_recs_2009.division IS 'Census Division';
COMMENT ON COLUMN diffusion_shared.eia_microdata_recs_2009.climate_region_pub IS 'Climate Zone (Building America)';
COMMENT ON COLUMN diffusion_shared.eia_microdata_recs_2009.reportable_domain IS 'Reportable states and groups of states';
COMMENT ON COLUMN diffusion_shared.eia_microdata_recs_2009.typehuq IS 'Type of housing unit';
COMMENT ON COLUMN diffusion_shared.eia_microdata_recs_2009.nweight IS 'Final sample weight';
COMMENT ON COLUMN diffusion_shared.eia_microdata_recs_2009.kownrent IS 'Housing unit is owned, rented, or occupied without payment of rent';
COMMENT ON COLUMN diffusion_shared.eia_microdata_recs_2009.kwh IS 'Total Site Electricity usage, in kilowatt-hours, 2009';
COMMENT ON COLUMN diffusion_shared.eia_microdata_recs_2009.rooftype IS 'Major roofing material';
COMMENT ON COLUMN diffusion_shared.eia_microdata_recs_2009.stories IS 'Number of stories in a single-family home';
COMMENT ON COLUMN diffusion_shared.eia_microdata_recs_2009.totsqft IS 'Total square footage (includes all attached garages, all basements, and finished/heated/cooled attics)';


-- add indices on kownrent,typehuq, and climate_region_pub
CREATE INDEX eia_microdata_recs_2009_typehuq_btree
ON diffusion_shared.eia_microdata_recs_2009
using btree(typehuq)
where typehuq in (1,2,3);

CREATE INDEX eia_microdata_recs_2009_kownrent_btree
ON diffusion_shared.eia_microdata_recs_2009
using btree(kownrent)
where kownrent = 1;

CREATE INDEX eia_microdata_recs_2009_climate_region_pub_btree
ON diffusion_shared.eia_microdata_recs_2009
using btree(climate_region_pub);


ALTER TABLE diffusion_shared.eia_microdata_recs_2009
ADD COLUMN census_region text;

UPDATE diffusion_shared.eia_microdata_recs_2009
SET census_region = 
	CASE WHEN regionc = 1 THEN 'Northeast'
	     WHEN regionc = 2 THEN 'Midwest'
	     WHEN regionc = 3 then 'South'
	     WHEN regionc = 4 then 'West'
	END;


ALTER TABLE diffusion_shared.eia_microdata_recs_2009
ADD COLUMN census_division_abbr text;

UPDATE diffusion_shared.eia_microdata_recs_2009
SET census_division_abbr = 
	CASE WHEN division = 1 THEN 'NE'
		WHEN division = 2 THEN 'MA'
		WHEN division = 3 THEN 'ENC'
		WHEN division = 4 THEN 'WNC'
		WHEN division = 5 THEN 'SA'
		WHEN division = 6 THEN 'ESC'
		WHEN division = 7 THEN 'WSC'
		WHEN division = 8 THEN 'MTN' -- NOTE: RECS breaks the MTN into N and S subdivision, but for consistency w CbECS, we will stick with one
		WHEN division = 9 THEN 'MTN' -- (see above)
		WHEN division = 10 THEN 'PAC'
	END;


-- add index
CREATE INDEX eia_microdata_recs_2009_census_region_btree 
ON diffusion_shared.eia_microdata_recs_2009
USING btree(census_region);

CREATE INDEX eia_microdata_recs_2009_census_division_abbr_btree 
ON diffusion_shared.eia_microdata_recs_2009
USING btree(census_division_abbr);

SELECT distinct(census_region)
fROM diffusion_shared.eia_microdata_recs_2009;

SELECT distinct(census_division_abbr)
fROM diffusion_shared.eia_microdata_recs_2009;

-- add the "crb_model" to this table (should be "reference" for all single family, owner occ homes)
ALTER TABLE diffusion_shared.eia_microdata_recs_2009
ADD COLUMN crb_model text;

UPDATE diffusion_shared.eia_microdata_recs_2009 a
SET crb_model = 'reference'
where typehuq in (1,2,3) AND kownrent = 1;
-- 7772 updated

-- ingest lookup table to translate recs reportable domain to states
set role 'diffusion-writers';
DrOP TABLE IF EXISTS diffusion_shared_data.eia_reportable_domain_to_state_recs_2009;
CREATE TABLE diffusion_shared_data.eia_reportable_domain_to_state_recs_2009
(
	reportable_domain integer,
	state_name text primary key
);

SET ROLE 'server-superusers';
COPY  diffusion_shared_data.eia_reportable_domain_to_state_recs_2009
FROM '/srv/home/mgleason/data/dg_wind/recs_reportable_dominain_to_state.csv' with csv header;
set role 'diffusion-writers';

-- create index for reportable domai column in this table and the recs table
CREATE INDEX eia_reportable_domain_to_state_recs_2009_reportable_domain_btree 
ON diffusion_shared_data.eia_reportable_domain_to_state_recs_2009
USING btree(reportable_domain);

CREATE INDEX eia_microdata_recs_2009_reportable_domain_btree 
ON diffusion_shared.eia_microdata_recs_2009
USING btree(reportable_domain);


