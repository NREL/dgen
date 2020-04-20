set role 'diffusion-writers';

DROP TABLE if exists diffusion_shared.aeo_new_building_multipliers_2015 CASCADE;
CREATE TABLE diffusion_shared.aeo_new_building_multipliers_2015 
(	
	  state_fips character varying(2),
	  state text,
	  state_abbr character varying(2) NOT NULL,
	  census_division text,
	  census_division_abbr text,
	  year integer NOT NULL,
	  scenario text NOT NULL,
	  res_single_family_growth numeric,
	  res_multi_family_growth numeric,
	  com_growth numeric
);

\COPY diffusion_shared.aeo_new_building_multipliers_2015  FROM '/Volumes/Staff/mgleason/dGeo/Data/Source_Data/EIA_NewBuilds_HousingStarts_ComFloospace/data_for_converting_to_scalars/output/new_building_growth_multipliers.csv' with csv header;

-- check results
select *
from diffusion_shared.aeo_new_building_multipliers_2015;

-- add primary key on state, year, scenario
ALTER TABLE diffusion_shared.aeo_new_building_multipliers_2015
ADD PRIMARY KEY (state_abbr, year, scenario);

-- add indices
create INDEX aeo_new_building_multipliers_2015_btree_state_abbr
on diffusion_shared.aeo_new_building_multipliers_2015
using btree(state_abbr);

create INDEX aeo_new_building_multipliers_2015_btree_year
on diffusion_shared.aeo_new_building_multipliers_2015
using btree(year);

create INDEX aeo_new_building_multipliers_2015_btree_scenario
on diffusion_shared.aeo_new_building_multipliers_2015
using btree(scenario);

-- change the names for the scenarios to our standard naming conventions
select distinct scenario
from diffusion_shared.aeo_new_building_multipliers_2015;
-- Reference --> AEO2015 Reference
-- High Growth --> AEO2015  High Growth
-- Low Growth --> AEO2015 Low Growth
-- Low Price --> AEO2015 Low Prices
-- High Price --> AEO2015 High Prices

UPDATE diffusion_shared.aeo_new_building_multipliers_2015
set scenario = 
	CASE
		WHEN scenario = 'Reference' THEN 'AEO2015 Reference'
		WHEN scenario = 'High Growth' THEN 'AEO2015 High Growth'
		WHEN scenario = 'Low Growth' THEN 'AEO2015 Low Growth'
		WHEN scenario = 'Low Price' THEN 'AEO2015 Low Prices'
		WHEN scenario = 'High Price' THEN 'AEO2015 High Prices'
	end;
-- 5100 rows

-- check results
select distinct scenario
from diffusion_shared.aeo_new_building_multipliers_2015;

-- check some data
select *
FROM diffusion_shared.aeo_new_building_multipliers_2015
limit 10;