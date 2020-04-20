set role mgleason;

ALTER TABLE diffusion_data_shared.block_county_ranked_lidar_city_lkup_res OWNER TO "diffusion-writers";
ALTER TABLE diffusion_data_shared.block_county_ranked_lidar_city_lkup_com OWNER TO "diffusion-writers";
ALTER TABLE diffusion_data_shared.block_county_ranked_lidar_city_lkup_ind OWNER TO "diffusion-writers";

set role 'diffusion-writers';

------------------------------------------------------------------------------------------
-- percent of buildings that are developable
------------------------------------------------------------------------------------------
------------------------------------
-- by city, sector, and size class
DROP TABLE IF EXISTS diffusion_solar.rooftop_percent_developable_buildings_by_city;
CREATE TABLE diffusion_solar.rooftop_percent_developable_buildings_by_city AS
SELECT city_id, zone, size_class, pct_developable
FROM pv_rooftop_dsolar_integration.percent_developable_buildings;

-- create indices
-- city id
CREATE INDEX rooftop_percent_developable_buildings_by_city_btree_city_id
ON diffusion_solar.rooftop_percent_developable_buildings_by_city
using BTREE(city_id);

-- zone
CREATE INDEX rooftop_percent_developable_buildings_by_city_btree_zone
ON diffusion_solar.rooftop_percent_developable_buildings_by_city
using BTREE(zone);

-- size class
CREATE INDEX rooftop_percent_developable_buildings_by_city_btree_size_class
ON diffusion_solar.rooftop_percent_developable_buildings_by_city
using BTREE(size_class);

------------------------------------
-- by state (from work by Caleb Phillips, Pieter Gagnon, and Jenny Melius)
DROP TABLE IF EXISTS diffusion_solar.rooftop_percent_developable_buildings_by_state;
CREATE TABLE diffusion_solar.rooftop_percent_developable_buildings_by_state 
(
	state_abbr character varying(2),
	size_class character varying(6),
	pct_developable numeric
);

\COPY diffusion_solar.rooftop_percent_developable_buildings_by_state (state_abbr, pct_developable, size_class) FROM '/Volumes/Staff/mgleason/DG_Solar/Data/Source_Data/pv_rooftop_tech_potential/from_pgagnon_20150928/pct_suitable_by_state_simplified.csv' with csv header;

-- add primary key
ALTER TABLE diffusion_solar.rooftop_percent_developable_buildings_by_state 
ADD PRIMARY KEY (state_abbr, size_class);

-- round pct developable to 2 digits
UPDATE diffusion_solar.rooftop_percent_developable_buildings_by_state 
set pct_developable = round(pct_developable, 2);

-- check which states are missing
with a as
(
	select distinct state_abbr
	from diffusion_shared.county_geom
),
b as
(
	select distinct state_abbr
	from diffusion_solar.rooftop_percent_developable_buildings_by_state 
)
select *
FROM  a
left join b
on a.state_abbr = b.state_abbr
where b.state_abbr is null;
-- only alaska and hawaii are missing, which is fine for now

select count(*)
FROM diffusion_solar.rooftop_percent_developable_buildings_by_state 
group by state_abbr
order by count asc;
-- make sure there are three entries for each state
-- all set

-- make sure medium and large buildigns only have percents of 1
select distinct pct_developable
from diffusion_solar.rooftop_percent_developable_buildings_by_state 
where size_class in ('medium', 'large');
-- 1.00 -- all set!
------------------------------------------------------------------------------------------
-- discrete distributions of optimal plane orientations
------------------------------------------------------------------------------------------
-- OPTIMAL ONLY
DROP TABLE IF EXISTS diffusion_solar.rooftop_orientation_frequencies_optimal_only;
CREATE TABLE diffusion_solar.rooftop_orientation_frequencies_optimal_only AS
SELECT *
FROM pv_rooftop_dsolar_integration.rooftop_orientation_frequencies_optimal_only;

-- add integer primary key
ALTER TABLE diffusion_solar.rooftop_orientation_frequencies_optimal_only
ADD COLUMN pid serial primary key;

-- for consistency with tech report:
	-- change tilt of -1 to 15 degrees
	-- but flag as "flat" (to allow for correct Groudn Cover Ratio)
-- optimal only
ALTER TABLE diffusion_solar.rooftop_orientation_frequencies_optimal_only
ADD COLUMN flat_roof boolean default false;

UPDATE diffusion_solar.rooftop_orientation_frequencies_optimal_only
SET flat_roof = TRUE
where tilt = -1;
-- 58727 rows

UPDATE diffusion_solar.rooftop_orientation_frequencies_optimal_only a
set tilt = 15
where flat_roof = True;
-- 58727 rows
-- optimal blended
ALTER TABLE diffusion_solar.rooftop_orientation_frequencies_optimal_blended
ADD COLUMN flat_roof boolean default false;

UPDATE diffusion_solar.rooftop_orientation_frequencies_optimal_blended
SET flat_roof = TRUE
where tilt = -1;
-- 58795 rows

UPDATE diffusion_solar.rooftop_orientation_frequencies_optimal_blended a
set tilt = 15
where flat_roof = True;
-- 58795 rows

-- create indices
CReATE INDEX rooftop_orientation_frequencies_optimal_only_zone_btree
ON diffusion_solar.rooftop_orientation_frequencies_optimal_only
USING BTREE (zone);

CReATE INDEX rooftop_orientation_frequencies_optimal_only_size_class_btree
ON diffusion_solar.rooftop_orientation_frequencies_optimal_only
USING BTREE (size_class);

CReATE INDEX rooftop_orientation_frequencies_optimal_only_ulocale_btree
ON diffusion_solar.rooftop_orientation_frequencies_optimal_only
USING BTREE (ulocale);

CReATE INDEX rooftop_orientation_frequencies_optimal_only_city_id_btree
ON diffusion_solar.rooftop_orientation_frequencies_optimal_only
USING BTREE (city_id);


-- OPTIMAL BLENDED
DROP TABLE IF EXISTS diffusion_solar.rooftop_orientation_frequencies_optimal_blended;
CREATE TABLE diffusion_solar.rooftop_orientation_frequencies_optimal_blended AS
SELECT *
FROM pv_rooftop_dsolar_integration.rooftop_orientation_frequencies_optimal_blended;

-- add integer primary key
ALTER TABLE diffusion_solar.rooftop_orientation_frequencies_optimal_blended
ADD COLUMN pid serial primary key;

-- create indices
CReATE INDEX rooftop_orientation_frequencies_optimal_blended_zone_btree
ON diffusion_solar.rooftop_orientation_frequencies_optimal_blended
USING BTREE (zone);

CReATE INDEX rooftop_orientation_frequencies_optimal_blended_size_class_btree
ON diffusion_solar.rooftop_orientation_frequencies_optimal_blended
USING BTREE (size_class);

CReATE INDEX rooftop_orientation_frequencies_optimal_blended_ulocale_btree
ON diffusion_solar.rooftop_orientation_frequencies_optimal_blended
USING BTREE (ulocale);

CReATE INDEX rooftop_orientation_frequencies_optimal_blended_city_id_btree
ON diffusion_solar.rooftop_orientation_frequencies_optimal_blended
USING BTREE (city_id);

------------------------------------------------------------------------------------------
-- lookup for ulocale, zone, and size class by City
------------------------------------------------------------------------------------------
CREATE TABLE diffusion_solar.rooftop_city_ulocale_zone_size_class_lkup AS
SELECT *
FROM pv_rooftop_dsolar_integration.lidar_city_ulocale_zone_size_class_lkup;

-- create indices
CREATE INDEX lidar_city_ulocale_zone_size_class_lkup_city_id_btree
ON diffusion_solar.rooftop_city_ulocale_zone_size_class_lkup
USING BTREE(city_id);

CREATE INDEX lidar_city_ulocale_zone_size_class_lkup_zone_btree
ON diffusion_solar.rooftop_city_ulocale_zone_size_class_lkup
USING BTREE(zone);

CREATE INDEX lidar_city_ulocale_zone_size_class_lkup_ulocale_btree
ON diffusion_solar.rooftop_city_ulocale_zone_size_class_lkup
USING BTREE(ulocale);

CREATE INDEX lidar_city_ulocale_zone_size_class_lkup_size_class_btree
ON diffusion_solar.rooftop_city_ulocale_zone_size_class_lkup
USING BTREE(size_class);

------------------------------------------------------------------------------------------
-- Ranks for Cities for each County/Ulocale cross-section
-- (ranks are based on shortest distance first, then most recent year)
------------------------------------------------------------------------------------------

-- res
ALTER TABLE diffusion_data_shared.block_county_ranked_lidar_city_lkup_res
RENAME TO rooftop_city_ranks_by_county_and_ulocale_res_blocks;

ALTER TABLE diffusion_data_shared.rooftop_city_ranks_by_county_and_ulocale_res_blocks
SET SCHEMA diffusion_solar;

-- com
ALTER TABLE diffusion_data_shared.block_county_ranked_lidar_city_lkup_com
RENAME TO rooftop_city_ranks_by_county_and_ulocale_com_blocks;

ALTER TABLE diffusion_data_shared.rooftop_city_ranks_by_county_and_ulocale_com_blocks
SET SCHEMA diffusion_solar;

-- ind
ALTER TABLE diffusion_data_shared.block_county_ranked_lidar_city_lkup_ind
RENAME TO rooftop_city_ranks_by_county_and_ulocale_ind_blocks;

ALTER TABLE diffusion_data_shared.rooftop_city_ranks_by_county_and_ulocale_ind_blocks
SET SCHEMA diffusion_solar;
------------------------------------------------------------------------------------------


------------------------------------------------------------------------------------------
-- CReate lookup table for ground cover ratio
------------------------------------------------------------------------------------------
DROP TABLE IF EXISTS diffusion_solar.rooftop_ground_cover_ratios;
CREATE TABLE diffusion_solar.rooftop_ground_cover_ratios AS
SELECT unnest(array[True, False]) as flat_roof,
	unnest(array[0.7, 0.98]) as gcr;

-- add primary key
ALTER TABLE diffusion_solar.rooftop_ground_cover_ratios
ADD PRIMARY KEY (flat_roof);

------------------------------------------------------------------------------------------
-- Tech Potential Limits by State (from Pieter, Caleb, and Jenny)
------------------------------------------------------------------------------------------
DROP TABLE IF EXISTS diffusion_solar.rooftop_tech_potential_limits_by_state;
CREATE TABLE diffusion_solar.rooftop_tech_potential_limits_by_state
(
	state_abbr character varying(2),
	size_class character varying(6),
	area_m2 numeric,
	cap_gw numeric,
	gen_gwh numeric
);

\COPY diffusion_solar.rooftop_tech_potential_limits_by_state FROM '/Volumes/Staff/mgleason/DG_Solar/Data/Source_Data/pv_rooftop_tech_potential/from_pgagnon_20151007/State_results_simplified_reformatted.csv' with csv header;

-- add a primary key
ALTER TABLE diffusion_solar.rooftop_tech_potential_limits_by_state
ADD PRIMARY KEY (state_abbr, size_class);

-- look at the results
select *
from diffusion_solar.rooftop_tech_potential_limits_by_state 

-- check three entries for each state
select  state_abbr, count(*)
from diffusion_solar.rooftop_tech_potential_limits_by_state
group by state_abbr
order by count desc;
-- all set

-- which states are missing?
with a as
(
	select distinct state_abbr
	from diffusion_shared.county_geom
),
b as
(
	select distinct state_abbr
	from diffusion_solar.rooftop_tech_potential_limits_by_state 
)
select *
FROM  a
left join b
on a.state_abbr = b.state_abbr
where b.state_abbr is null;
-- only alaska and hawaii are missing, which is fine for now
