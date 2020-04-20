-- Regional Capital Cost Multipliers by County

-- export county geoms to shapefile
pgsql2shp -g the_geom_96703_20m -f /Volumes/Staff/mgleason/dGeo/Data/Analysis/reg_cap_cost_zonal_stats_bycnty/cnty/cnty_20m.shp -h gispgdb -u mmooney -P mmooney dav-gis "select state_fips, county_fips, geoid10, the_geom_96703_20m from diffusion_blocks.county_geoms"

-- import dual and binary csvs into temporary tables
set role 'diffusion-writers';
drop table if exists diffusion_geo.temp_gtdual;
create table diffusion_geo.temp_gtdual 
	(
	objectid numeric,
	geoid character varying(5),
	zone_code numeric,
	count numeric,
	area numeric,
	mean numeric
	);
set role 'diffusion-writers';
drop table if exists diffusion_geo.temp_gtbinary;
create table diffusion_geo.temp_gtbinary
	(
	objectid numeric,
	geoid character varying(5),
	zone_code numeric,
	count numeric,
	area numeric,
	mean numeric
	);

\COPY diffusion_geo.temp_gtbinary FROM '/Volumes/Staff/mgleason/dGeo/Data/Analysis/reg_cap_cost_zonal_stats_bycnty/avg_gitbinary_per_cnty.csv' with csv header;
\COPY diffusion_geo.temp_gtdual FROM '/Volumes/Staff/mgleason/dGeo/Data/Analysis/reg_cap_cost_zonal_stats_bycnty/avg_gitdual_per_cnty.csv' with csv header;

-- Create final table
set role 'diffusion-writers';
drop table if exists diffusion_geo.regional_cap_cost_multipliers;
create table diffusion_geo.regional_cap_cost_multipliers  as
(
	select a.geoid10 as county_id,
	b.mean as cap_cost_multiplier_gt_binary,
	c.mean as cap_cost_multiplier_gt_dual
	from diffusion_blocks.county_geoms a
	left join diffusion_geo.temp_gtbinary b
	on a.geoid10 = b.geoid
	left join diffusion_geo.temp_gtdual c
	on a.geoid10 = c.geoid);

-- Add primary key
alter table diffusion_geo.regional_cap_cost_multipliers
add constraint regional_cap_cost_multipliers_county_county_id_pkey
primary key (county_id);

-- delete temp tables
drop table if exists diffusion_geo.temp_gtdual;
drop table if exists diffusion_geo.temp_gtbinary;


-- Transform Null Values into "Nearest Neighbor"

	-- Part A. BINARY
			-- Select Values that Are not Null
			with binary_vals as (
				select a.*, b.the_geom_96703_20m 
				from diffusion_geo.regional_cap_cost_multipliers a
				left join diffusion_blocks.county_geoms b
				on a.county_id = b.geoid10
				where a.cap_cost_multiplier_gt_binary is not Null),
			-- Select Values that are null
			binary_null_vals as (
				select a.*, b.the_geom_96703_20m 
				from diffusion_geo.regional_cap_cost_multipliers a
				left join diffusion_blocks.county_geoms b
				on a.county_id = b.geoid10
				where a.cap_cost_multiplier_gt_binary is Null),
			-- Calculate distance between null_geoms and non-null_geoms
			binary_distance as (
				select a.county_id as county_id_null, b.county_id as county_id_notnull, a.the_geom_96703_20m as the_geom_96703_20m_null,
				b.the_geom_96703_20m as the_geom_96703_20m_notnull,
				ST_Distance(a.the_geom_96703_20m, b.the_geom_96703_20m) as distance,
				b.cap_cost_multiplier_gt_binary
				from binary_null_vals a, binary_vals b
				where a.county_id <> b.county_id
				order by ST_Distance(a.the_geom_96703_20m, b.the_geom_96703_20m)
				),
			-- Find the closest value
			binary_closest as (
					-- find min distance for county's with null values
					with min as (
					select distinct on (county_id_null)
					county_id_null,
					min(distance) as min_distance
					from binary_distance a
					group by county_id_null
					),
				--select * from min) select count(*) from binary_closest; --**
				join_source_geom as (
					-- append the source county geom	
					select distinct on (a.county_id_null, a.min_distance) a.county_id_null, a.min_distance,
					b.the_geom_96703_20m_null as source_geom
					from min a
					left join binary_distance b
					on a.county_id_null = b.county_id_null and a.min_distance = b.distance)
				--append closest county geom
				select distinct on (a.*) a.*, b.the_geom_96703_20m_notnull as closest_geom, b.cap_cost_multiplier_gt_binary
				from join_source_geom a
				left join binary_distance b
				on a.county_id_null = b.county_id_null and a.min_distance = b.distance
				)

			update diffusion_geo.regional_cap_cost_multipliers a
			set cap_cost_multiplier_gt_binary = (select b.cap_cost_multiplier_gt_binary from binary_closest b where b.county_id_null = a.county_id)
			where cap_cost_multiplier_gt_binary is null;
			-- QAQC = 47 rows affected (good!)


	-- Part B.DUAL
			-- Select Values that Are not Null
			with dual_vals as (
				select a.*, b.the_geom_96703_20m 
				from diffusion_geo.regional_cap_cost_multipliers a
				left join diffusion_blocks.county_geoms b
				on a.county_id = b.geoid10
				where a.cap_cost_multiplier_gt_dual is not Null),
			-- Select Values that are null
			dual_null_vals as (
				select a.*, b.the_geom_96703_20m 
				from diffusion_geo.regional_cap_cost_multipliers a
				left join diffusion_blocks.county_geoms b
				on a.county_id = b.geoid10
				where a.cap_cost_multiplier_gt_dual is Null),
			-- Calculate distance between null_geoms and non-null_geoms
			dual_distance as (
				select a.county_id as county_id_null, b.county_id as county_id_notnull, a.the_geom_96703_20m as the_geom_96703_20m_null,
				b.the_geom_96703_20m as the_geom_96703_20m_notnull,
				ST_Distance(a.the_geom_96703_20m, b.the_geom_96703_20m) as distance,
				b.cap_cost_multiplier_gt_dual
				from dual_null_vals a, dual_vals b
				where a.county_id <> b.county_id
				order by ST_Distance(a.the_geom_96703_20m, b.the_geom_96703_20m)
				),
			-- Find the closest value
			dual_closest as (
					-- find min distance for county's with null values
					with min as (
					select distinct on (county_id_null)
					county_id_null,
					min(distance) as min_distance
					from dual_distance a
					group by county_id_null
					),
				--select * from min) select count(*) from dual_closest; --**
				join_source_geom as (
					-- append the source county geom	
					select distinct on (a.county_id_null, a.min_distance) a.county_id_null, a.min_distance,
					b.the_geom_96703_20m_null as source_geom
					from min a
					left join dual_distance b
					on a.county_id_null = b.county_id_null and a.min_distance = b.distance)
				--append closest county geom
				select distinct on (a.*) a.*, b.the_geom_96703_20m_notnull as closest_geom, b.cap_cost_multiplier_gt_dual
				from join_source_geom a
				left join dual_distance b
				on a.county_id_null = b.county_id_null and a.min_distance = b.distance
				)

			update diffusion_geo.regional_cap_cost_multipliers a
			set cap_cost_multiplier_gt_dual = (select b.cap_cost_multiplier_gt_dual from dual_closest b where b.county_id_null = a.county_id)
			where cap_cost_multiplier_gt_dual is null;
			-- QAQC = 47 rows affected (good!)



---------------------------------------
-- Run Checks
---------------------------------------
-- 1. Check to see if there are null values. How many tracts?
	--binary
	select count(a.*)
	from diffusion_geo.regional_cap_cost_multipliers a
	left join diffusion_blocks.county_geoms b
	on a.county_id = b.geoid10
	where a.cap_cost_multiplier_gt_binary is Null;
		-- total null (originally) should be 47 
		-- after Nearest neighbor = 0


-- 2. Check to make sure nearest neighbor is acutally the nearest neighbor (look in QGIS)
		drop table if exists mmooney.binary_closest_vals_temp;
		create table mmooney.binary_closest_vals_temp as (
		-- Select Values that Are not Null
		with binary_vals as (
			select a.*, b.the_geom_96703_20m 
			from diffusion_geo.regional_cap_cost_multipliers a
			left join diffusion_blocks.county_geoms b
			on a.county_id = b.geoid10
			where a.cap_cost_multiplier_gt_binary is not Null),
		-- Select Values that are null
		binary_null_vals as (
			select a.*, b.the_geom_96703_20m 
			from diffusion_geo.regional_cap_cost_multipliers a
			left join diffusion_blocks.county_geoms b
			on a.county_id = b.geoid10
			where a.cap_cost_multiplier_gt_binary is Null),
		-- Calculate distance between null_geoms and non-null_geoms
		binary_distance as (
			select a.county_id as county_id_null, b.county_id as county_id_notnull, a.the_geom_96703_20m as the_geom_96703_20m_null,
			b.the_geom_96703_20m as the_geom_96703_20m_notnull,
			ST_Distance(a.the_geom_96703_20m, b.the_geom_96703_20m) as distance
			from binary_null_vals a, binary_vals b
			where a.county_id <> b.county_id
			order by ST_Distance(a.the_geom_96703_20m, b.the_geom_96703_20m)
			),
		-- Find the closest value
		binary_closest as (
				-- find min distance for county's with null values
				with min as (
				select distinct on (county_id_null, the_geom_96703_20m_null)
				county_id_null, the_geom_96703_20m_null,
				min(distance) as min_distance
				from binary_distance a
				group by county_id_null, the_geom_96703_20m_null 
				),
			--select * from min) select count(*) from binary_closest; --**
			join_source_geom as (
				-- append the source county geom	
				select distinct on (a.county_id_null, a.min_distance) a.county_id_null, a.min_distance,
				b.the_geom_96703_20m_null as source_geom
				from min a
				left join binary_distance b
				on a.county_id_null = b.county_id_null and a.min_distance = b.distance)
			--append closest county geom
			select distinct on (a.*) a.*, b.the_geom_96703_20m_notnull as closest_geom
			from join_source_geom a
			left join binary_distance b
			on a.county_id_null = b.county_id_null and a.min_distance = b.distance
			)
		select * from binary_closest
		);

	-- QAQC Results :
		-- A. 47 "source_geoms" which is the total number of original null values
		-- B. All null counties ("source_geoms") are located in AK or Hi which is what we expect; 
					-- Except for "independent cities" in VA (e.g. Harrisonburg which is part of Rockingham cnty). 
					-- These are null because of the way arc treats the zones in zonal stats since the city is encapsulated within the larger county zone.
		-- C. closest_geoms for HI are in southern CA and closest values for AK are the eastern parts of AK that touch Canada. 
				--- This is good/ what we would expect.
			  -- closest values for incorporated cities are their larger counties (VA only)

		-- D. Count # of counties in gt_binary and gt_dual temp tables
			select count(*) from diffusion_geo.temp_gtbinary; -- = 3096 
			select count(*) from diffusion_geo.temp_gtdual; -- = 3096
			select count(*) from diffusion_blocks.county_geoms; -- = 3143 (difference of 47)
			-- count # of counties in new table
			select count(*)
			from diffusion_geo.regional_cap_cost_multipliers
		-- E. Check for null county ids
			select * from diffusion_geo.regional_cap_cost_multipliers where county_id is null;;
			-- 0 nulls (good)
		-- F. Check to make sure there are 3143 total records in final table
			select count(*) from diffusion_geo.regional_cap_cost_multipliers; --3143 (good!)
		-- G. Compare dual and binary
			select abs(cap_cost_multiplier_gt_binary - cap_cost_multiplier_gt_dual) as abs_diff from diffusion_geo.regional_cap_cost_multipliers
			order by  abs(cap_cost_multiplier_gt_binary - cap_cost_multiplier_gt_dual);
				-- difference is quite small (ranging from 0-0.0169).

-- drop temp table
drop table if exists mmooney.binary_closest_vals_temp;
drop table if exists diffusion_geo.temp_gtbinary; -- = 3096 
drop table if exists diffusion_geo.temp_gtdual; 

------------------------------------------------------------------------------------
-- create a "blended multiplier" that is the average of the two technologies
-- this is justified because max abs difference is only:
select @(max(cap_cost_multiplier_gt_binary-cap_cost_multiplier_gt_dual))
from diffusion_geo.regional_cap_cost_multipliers
-- 0.0169492

ALTER TABLE diffusion_geo.regional_cap_cost_multipliers
ADD COLUMN cap_cost_multiplier_geo_blended numeric;

UPDATE diffusion_geo.regional_cap_cost_multipliers
SET cap_cost_multiplier_geo_blended = (cap_cost_multiplier_gt_binary + cap_cost_multiplier_gt_dual)/2.;
-- 3143 rows updated

-- check for nulls
select *
FROM diffusion_geo.regional_cap_cost_multipliers
where cap_cost_multiplier_geo_blended is null;
-- 0 all set

-- rename the county_id field to geoid
ALTER TABLE diffusion_geo.regional_cap_cost_multipliers
RENAME COLUMN county_id to geoid;

-- add the real county_id
ALTER TABLE diffusion_geo.regional_cap_cost_multipliers
ADD COLUMN county_id integer;

-- set it
UPDATE diffusion_geo.regional_cap_cost_multipliers a
SET county_id = b.county_id
from diffusion_blocks.county_geoms b
where a.geoid = b.geoid10;
-- 3143 rows

-- remove old primary key on geoid
ALTER TABLE diffusion_geo.regional_cap_cost_multipliers 
DROP CONSTRAINT regional_cap_cost_multipliers_county_county_id_pkey;

-- add the new one
ALTER TABLE diffusion_geo.regional_cap_cost_multipliers
ADD primary key (county_id);




