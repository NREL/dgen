set role 'diffusion-writers';

drop table if exists diffusion_shared.aeo_new_building_projections_2015;
CREATE TABLE diffusion_shared.aeo_new_building_projections_2015
(
	state_fips varchar(2),
	state text,
	census_division text,
	year integer,
	scenario text,
	housing_starts_single_family_millions numeric,
	housing_starts_multi_family_millions numeric,
	commercial_sq_ft_billions numeric
);

\COPY  diffusion_shared.aeo_new_building_projections_2015 FROM '/Volumes/Staff/mgleason/dGeo/Data/Source_Data/EIA_NewBuilds_HousingStarts_ComFloospace/dissag_newbuilds_from_region_to_state_popprojections.csv' with csv header;

------------------------------------------------------------------------------------------------------------
-- check all combos of state + year + scenario are present?
select distinct state_fips
from  diffusion_shared.aeo_new_building_projections_2015;
-- 51 rows
select distinct year
from  diffusion_shared.aeo_new_building_projections_2015;
-- 29 rows
select distinct scenario
from  diffusion_shared.aeo_new_building_projections_2015;
-- 5 rows
-- should be5*29*51 = 7395
select count(*)
FROM  diffusion_shared.aeo_new_building_projections_2015;
-- 7395, all set!

------------------------------------------------------------------------------------------------------------
-- spot check some national total values against the AEO site
select sum(commercial_sq_ft_billions) --* 1000/1e9
from diffusion_shared.aeo_new_building_projections_2015
where year = 2021
and scenario = 'Reference';
-- 90.1 + 90.1--  good to go

select sum(housing_starts_single_family_millions + housing_starts_multi_family_millions)
from diffusion_shared.aeo_new_building_projections_2015
where year = 2021
and scenario = 'Reference';
-- 1.68, should be 1.64

------------------------------------------------------------------------------------------------------------
-- convert fips to lpadded
UPDATE  diffusion_shared.aeo_new_building_projections_2015
set state_fips = lpad(state_fips, 2, '0');
-- 7395 rows
------------------------------------------------------------------------------------------------------------

-- add state abbr
ALTER TABLE diffusion_shared.aeo_new_building_projections_2015
ADD COLUMN state_abbr varchar(2);

UPDATE diffusion_shared.aeo_new_building_projections_2015 a
set state_abbr = b.state_abbr
from diffusion_shared.state_fips_lkup b
where a.state_fips = lpad(b.state_fips::TEXT, 2, '0');
-- 7395 rows

-- any nulls?
select count(*)
FROM diffusion_shared.aeo_new_building_projections_2015
where state_abbr is null;
-- 0, all set!

-- check distinct values
select distinct state_abbr
from diffusion_shared.aeo_new_building_projections_2015
order by 1;
-- looks good - no PR, but DC, HI, and AK are all included
------------------------------------------------------------------------------------------------------------
-- add primary key
ALTER TABLE diffusion_shared.aeo_new_building_projections_2015
ADD PRIMARY KEY (state_abbr, scenario, year);
------------------------------------------------------------------------------------------------------------

-- add census division abbr
ALTER TABLE diffusion_shared.aeo_new_building_projections_2015
ADD COLUMN census_division_abbr text;

UPDATE diffusion_shared.aeo_new_building_projections_2015 a
set census_division_abbr = b.division_abbr
from eia.census_regions_20140123 b
where a.state_abbr = b.state_abbr;
-- 7395 rows

-- check distinct combos of division name and division abbr?
select distinct census_division, census_division_abbr
from diffusion_shared.aeo_new_building_projections_2015;
-- 9 rows, no nulls, all look good

------------------------------------------------------------------------------------------------------------
-- chec kfor nulls in numeric projection fields?
select count(*)
FROM diffusion_shared.aeo_new_building_projections_2015
where housing_starts_single_family_millions is null
or housing_starts_multi_family_millions is null
or commercial_sq_ft_billions is null;
-- 0 -- all set!


--Load TS Data (projected out to 2050) into Table (after running 4_timeseries_project_to_2050.R)
\COPY  diffusion_shared.aeo_new_building_projections_2015 FROM '/Volumes/Staff/mgleason/dGeo/Data/Source_Data/EIA_NewBuilds_HousingStarts_ComFloospace/ts_project_to_2050.csv' with csv header;


