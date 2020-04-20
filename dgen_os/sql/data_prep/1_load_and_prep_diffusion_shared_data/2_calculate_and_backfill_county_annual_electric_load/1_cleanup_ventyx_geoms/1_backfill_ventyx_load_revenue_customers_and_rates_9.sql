-- NOTE: need to create a new version of the electric_service_territories_states_with_ids using the ventyx state and province boundaries
-- then proceed with the rest, subbing in the ventyx states and provincs when I get to the erase phase

------------------------------------------------------------------------------------------------
-- STEP 1: create an edited version of ventyx.electric_services_territories_ventyx_states where pge extends into northern san francisco 
------------------------------------------------------------------------------------------------
-- copy the table over
DROP TABLE IF EXISTS dg_wind.ventyx_elec_serv_territories_edit;
CREATE TABLE dg_wind.ventyx_elec_serv_territories_edit AS
SELECT *
FROM ventyx.electric_service_territories_states_split_multipart_20140224
where country = 'United States of America';

-- MANUAL FIXES TO GEOMETRIES --
-- 1 -- San Francisco needs to be merged into PGE
-- find gids for the two polygons using Q
-- check that i have the right gids
SELECT *
from dg_wind.ventyx_elec_serv_territories_edit
where (company_id = 1133 and state_abbr = 'CA') -- PGE
or (company_id = 61081 and state_abbr = 'CA') -- SF;

-- update the geometry for pge
with merged as (
	SELECT ST_Union(the_geom_4326) as the_geom_4326
	from dg_wind.ventyx_elec_serv_territories_edit
	where (company_id = 1133 and state_abbr = 'CA') or (company_id = 61081 and state_abbr = 'CA'))
UPDATE dg_wind.ventyx_elec_serv_territories_edit a
SET the_geom_4326 = b.the_geom_4326
FROM merged b
where (company_id = 1133 and state_abbr = 'CA');
-- review in Q

-- 2 - Savannah Needs to be Merged into Georgia Power
SELECT *
from dg_wind.ventyx_elec_serv_territories_edit
where (company_id = 1057 and state_abbr = 'GA') -- Georgia Power Co
or (company_id = 1156 and state_abbr = 'GA') -- Savannah Electric & Power Co;

-- update the geometry for pge
with merged as (
	SELECT ST_Union(the_geom_4326) as the_geom_4326
	from dg_wind.ventyx_elec_serv_territories_edit
	where (company_id = 1057 and state_abbr = 'GA') or (company_id = 1156 and state_abbr = 'GA'))
UPDATE dg_wind.ventyx_elec_serv_territories_edit a
SET the_geom_4326 = b.the_geom_4326
FROM merged b
where (company_id = 1057 and state_abbr = 'GA');
-- review in Q


-- add company type
ALTER TABLE dg_wind.ventyx_elec_serv_territories_edit
ADD COLUMN company_ty text;

	-- join from source data
UPDATE dg_wind.ventyx_elec_serv_territories_edit a
SET company_ty = b.company_ty
FROM ventyx.electric_service_territories_states_split_20140224 b
where a.company_id = b.company_id;

	-- generalize to 4 broad categories
ALTER TABLE dg_wind.ventyx_elec_serv_territories_edit
ADD COLUMN company_type_general text;

UPDATE dg_wind.ventyx_elec_serv_territories_edit
SET company_type_general =
	CASE WHEN company_ty in ('IOU','IO') THEN 'IOU'
	     when company_ty in ('G&TCoop','Coop','DistCoop') then 'Coop'
	     WHEN company_ty in ('Private','PSubdiv','Federal','Unknown') THEN 'All Other'
	     WHEN company_ty in ('Muni','State') THEN 'Muni'
	END;



-- housekeeping
ALTER TABLE dg_wind.ventyx_elec_serv_territories_edit ADD primary key (gid);

-- add indices
CREATE INDEX ventyx_elec_serv_territories_edit_company_id_btree
  ON dg_wind.ventyx_elec_serv_territories_edit
  USING btree
  (company_id);

CREATE INDEX ventyx_elec_serv_territories_edit_state_abbr_btree
  ON dg_wind.ventyx_elec_serv_territories_edit
  USING btree
  (state_abbr);

CREATE INDEX ventyx_elec_serv_territories_edit_the_geom_4326_gist
  ON dg_wind.ventyx_elec_serv_territories_edit
  USING gist
  (the_geom_4326);
  
ALTER TABLE dg_wind.ventyx_elec_serv_territories_edit CLUSTER ON ventyx_elec_serv_territories_edit_the_geom_4326_gist;

-- create a  dicedCT CC version
DROP TABLE IF EXISTS dg_wind.ventyx_elec_serv_territories_edit_diced;
CREATE TABLE dg_wind.ventyx_elec_serv_territories_edit_diced AS
SELECT a.company_id, a.company_name, a.state_abbr, a.country, 
       a.gid, a.company_ty, a.company_type_general, ST_Intersection(a.the_geom_4326, b.the_geom_4326) as the_geom_4326
FROM dg_wind.ventyx_elec_serv_territories_edit a
INNER JOIN dg_wind.us_fishnet_p5dd b
ON ST_Intersects(a.the_geom_4326, b.the_geom_4326);

CREATE INDEX ventyx_elec_serv_territories_edit_diced_the_geom_4326_gist ON dg_wind.ventyx_elec_serv_territories_edit_diced USING gist(the_geom_4326);
----------------------------------------------------------------------------------------------------------------


----------------------------------------------------------------------------------------------------------------
-- STEP 2: Join Ventyx sales data (for 2011) to the (slightly edited) Ventyx service territories
----------------------------------------------------------------------------------------------------------------
-- join electric service territories to 2011 data
DROP TABLE IF ExISTS dg_wind.ventyx_elec_serv_territories_w_2011_sales_data CASCADE;
CREATE TABLE dg_wind.ventyx_elec_serv_territories_w_2011_sales_data AS
SELECT a.*,

b.bundled_energy_only_delivery_only_residential_revenue_000s as total_residential_revenue_000s,
b.bundled_delivery_only_residential_sales_mwh as total_residential_sales_mwh,
b.bundled_delivery_only_residential_customers as total_residential_customers,

b.bundled_energy_only_delivery_only_commercial_revenue_000s as total_commercial_revenue_000s,
b.bundled_delivery_only_commercial_sales_mwh as total_commercial_sales_mwh,
b.bundled_delivery_only_commercial_customers as total_commercial_customers,

b.bundled_energy_only_delivery_only_industrial_revenue_000s as total_industrial_revenue_000s,
b.bundled_delivery_only_industrial_sales_mwh  as total_industrial_sales_mwh,
b.bundled_delivery_only_industrial_customers as total_industrial_customers,

b.year as data_year

FROM dg_wind.ventyx_elec_serv_territories_edit a
INNER join ventyx.retail_sales_2011 b -- use inner join to drop out the polygons that don't have matching sales data
ON a.state_abbr = b.customer_state
and a.company_id = b.company_id; 
-- 3065  rows (out of 3197 geoms and 3647 sales rows)

----------------------------------------------------------------------------------------------------------------
-- STEP 4: check for records that failed to join from the sales table to the polygons, and vice versa
----------------------------------------------------------------------------------------------------------------
	-- poly but no sales data
DROP TABLE IF EXISTS dg_wind.ventyx_polys_no_sales;
CREATE TABLE dg_wind.ventyx_polys_no_sales AS
SELECT a.*,

b.bundled_energy_only_delivery_only_residential_revenue_000s as total_residential_revenue_000s,
b.bundled_delivery_only_residential_sales_mwh as total_residential_sales_mwh,
b.bundled_delivery_only_residential_customers as total_residential_customers,

b.bundled_energy_only_delivery_only_commercial_revenue_000s as total_commercial_revenue_000s,
b.bundled_delivery_only_commercial_sales_mwh as total_commercial_sales_mwh,
b.bundled_delivery_only_commercial_customers as total_commercial_customers,

b.bundled_energy_only_delivery_only_industrial_revenue_000s as total_industrial_revenue_000s,
b.bundled_delivery_only_industrial_sales_mwh  as total_industrial_sales_mwh,
b.bundled_delivery_only_industrial_customers as total_industrial_customers,

b.year as data_year,

ST_Perimeter(the_geom_4326::geography)/ST_Area(the_geom_4326::geography) as peri2area

FROM dg_wind.ventyx_elec_serv_territories_edit a
LEFT join ventyx.retail_sales_2011 b
ON a.state_abbr = b.customer_state
and a.company_id = b.company_id
where b.company_id is null; -- 132 rows

	-- sales data but no poly
DROP TABLE IF EXISTS  dg_wind.ventyx_sales_no_polys;
CREATE TABLE dg_wind.ventyx_sales_no_polys AS
SELECT b.*

FROM ventyx.retail_sales_2011 b
LEFT join  dg_wind.ventyx_elec_serv_territories_edit a
ON b.customer_state = a.state_abbr
and b.company_id = a.company_id
where a.company_id is null
and b.country = 'United States of America'; -- 563 rows failed to match


	-- investigate these in Q:
		-- results suggest that several of the entries in the sales table do not have a corresponding polygon -- so there isn't a simple fix like manually correcting company ids
		-- this result also indicates that the polygon data may not be fully representative of all service territories

		-- proposed solution:
			--1- aggregate state level totals of the unjoined totals from sales table
			--2- join the state level remainders to state boundaries 

---------------------------------------------------------------------------------------------------------------------------------------------------
-- STEP 3: run some investigations to make sure proposed solution for backfilling is appropriate and will be represntative of 2011 sales, revenue, and customer totals
---------------------------------------------------------------------------------------------------------------------------------------------------

---------
-- investigation 1: compare national level load totals between 2011 ventyx retail sales table, 2011 eia tables 1-4, and joined ventyx data
---------
-- how much is in the ventyx sale data?
select sum(bundled_delivery_only_residential_sales_mwh)
FROM ventyx.retail_sales_2011
where country = 'United States of America'; -- 1,422,801,093

-- is this the same as what's in the eia totals?
select sum(res_sales_mwh)
FROM eia.tables_1_thru_4_2011; -- 1,422,802,000
-- pretty much, yes!

-- how much of the ventyx sales data got joined to the polygons?
select sum(total_residential_sales_mwh)
FROM dg_wind.ventyx_elec_serv_territories_w_2011_sales_data
where data_year = 2011;  ---1371323957

-- how much failed to join?
SELECT sum(bundled_delivery_only_residential_sales_mwh)
FROM dg_wind.ventyx_sales_no_polys; -- 51477136 -- unjoined to polys

-- do these add up to the original ventyx retail sales total?
select 1371323957+51477136; -- 1422801093
-- yes, exactly


-- repeat this check for commercial:
-- how much is in the ventyx sale data?
select sum(bundled_delivery_only_commercial_sales_mwh)
FROM ventyx.retail_sales_2011
where country = 'United States of America'; -- 1,328,035,748

-- is this the same as what's in the eia totals?
select sum(com_sales_mwh)
FROM eia.tables_1_thru_4_2011; -- 1,328,056,000
-- pretty much, yes!

-- how much of the ventyx sales data got joined to the polygons?
select sum(total_commercial_sales_mwh)
FROM dg_wind.ventyx_elec_serv_territories_w_2011_sales_data; -- 1232681917

-- how much failed to join?
SELECT sum(bundled_delivery_only_commercial_sales_mwh)
FROM dg_wind.ventyx_sales_no_polys; -- 95353831

-- do these add up to the original ventyx retail sales total?
select 1232681917+95353831; -- 1,328,035,748
-- yes, exactly


-- repeat this check for industrial:
-- how much is in the ventyx sale data?
select sum(bundled_delivery_only_industrial_sales_mwh)
FROM ventyx.retail_sales_2011
where country = 'United States of America'; -- 991,241,801

-- is this the same as what's in the eia totals?
select sum(ind_sales_mwh)
FROM eia.tables_1_thru_4_2011; -- 991,313,000
-- pretty much, yes!

-- how much of the ventyx sales data got joined to the polygons?
select sum(total_industrial_sales_mwh)
FROM dg_wind.ventyx_elec_serv_territories_w_2011_sales_data; -- 921736157

-- how much failed to join?
SELECT sum(bundled_delivery_only_industrial_sales_mwh)
FROM dg_wind.ventyx_sales_no_polys; -- 69505644

-- do these add up to the original ventyx retail sales total?
select 921736157+69505644; -- 991,241,801
-- yes, exactly

---------
-- investigation 2: compare national level customer totals between 2011 ventyx retail sales table, 2011 eia tables 1-4, and joined ventyx data
---------
-- check residential:
-- how many customers are in the ventyx sales data?
select sum(bundled_delivery_only_residential_customers)
FROM ventyx.retail_sales_2011
where country = 'United States of America'; -- 126,143,072

-- is this the same as what's in the eia totals?
select sum(res_consumers)
FROM eia.tables_1_thru_4_2011; -- 126,143,072 
-- yep, nailed it!

-- how many of the ventyx customers got joined to the polygons?
select sum(total_residential_customers)
FROM dg_wind.ventyx_elec_serv_territories_w_2011_sales_data;  --122380833

-- how many failed to join?
SELECT sum(bundled_delivery_only_residential_customers)
FROM dg_wind.ventyx_sales_no_polys; -- 3762239

-- do these add up to the original ventyx total?
select 122380833+3762239; -- 126,143,072
-- yes, exactly


-- repeat this check for commercial:
-- how many customers are in the ventyx sales data?
select sum(bundled_delivery_only_commercial_customers)
FROM ventyx.retail_sales_2011
where country = 'United States of America'; -- 17,638,050

-- is this the same as what's in the eia totals?
select sum(com_consumers)
FROM eia.tables_1_thru_4_2011; -- 17,638,062 
-- pretty much, yes!

-- how many of the ventyx customers got joined to the polygons?
select sum(total_commercial_customers)
FROM dg_wind.ventyx_elec_serv_territories_w_2011_sales_data;  --17021104

-- how many failed to join?
SELECT sum(bundled_delivery_only_commercial_customers)
FROM dg_wind.ventyx_sales_no_polys; -- 616946

-- do these add up to the original ventyx total?
select 17021104+616946; -- 17,638,050
-- yes, exactly


-- repeat this check for industrial:
-- how many customers are in the ventyx sales data?
select sum(bundled_delivery_only_industrial_customers)
FROM ventyx.retail_sales_2011
where country = 'United States of America'; -- 727,915

-- is this the same as what's in the eia totals?
select sum(ind_consumers)
FROM eia.tables_1_thru_4_2011; -- 727,920
-- pretty much, yes!

-- how many of the ventyx customers got joined to the polygons?
select sum(total_industrial_customers)
FROM dg_wind.ventyx_elec_serv_territories_w_2011_sales_data;  -- 721159

-- how many failed to join?
SELECT sum(bundled_delivery_only_industrial_customers)
FROM dg_wind.ventyx_sales_no_polys; -- 6756

-- do these add up to the original ventyx total?
select 721159+6756 -- 727,915
-- yes, exactly

---------
-- investigation 3: compare national level revenue totals between 2011 ventyx retail sales table, 2011 eia tables 1-4, and joined ventyx data
---------
-- check residential:
-- how much revenue is in the ventyx sales data?
select sum(bundled_energy_only_delivery_only_residential_revenue_000s)
FROM ventyx.retail_sales_2011
where country = 'United States of America'; -- 166,714,106.8

-- is this the same as what's in the eia totals?
select sum(res_revenue_000s)
FROM eia.tables_1_thru_4_2011; -- 166,714,106.8 -- nailed it!

-- how much of the ventyx revenue got joined to the polygons?
select sum(total_residential_revenue_000s)
FROM dg_wind.ventyx_elec_serv_territories_w_2011_sales_data;  -- 156667240.2

-- how much failed to join?
SELECT sum(bundled_energy_only_delivery_only_residential_revenue_000s)
FROM dg_wind.ventyx_sales_no_polys; -- 10046866.6

-- do these add up to the original ventyx total?
select 156667240.2+10046866.6; -- 166,714,106.8
-- yes, exactly


-- repeate for commercial:
-- how much revenue is in the ventyx sales data?
select sum(bundled_energy_only_delivery_only_commercial_revenue_000s)
FROM ventyx.retail_sales_2011
where country = 'United States of America'; -- 135,924,384.9

-- is this the same as what's in the eia totals?
select sum(com_revenue_000s)
FROM eia.tables_1_thru_4_2011; -- 135,926,483.9
-- pretty much, yes!

-- how much of the ventyx revenue got joined to the polygons?
select sum(total_commercial_revenue_000s)
FROM dg_wind.ventyx_elec_serv_territories_w_2011_sales_data;  -- 110872732.4

-- how much failed to join?
SELECT sum(bundled_energy_only_delivery_only_commercial_revenue_000s)
FROM dg_wind.ventyx_sales_no_polys; -- 25051652.5

-- do these add up to the original ventyx total?
select 110872732.4+25051652.5; -- 135,924,384.9
-- yes, exactly


-- repeate for industrial:
-- how much revenue is in the ventyx sales data?
select sum(bundled_energy_only_delivery_only_industrial_revenue_000s)
FROM ventyx.retail_sales_2011
where country = 'United States of America'; -- 67,598,492.7

-- is this the same as what's in the eia totals?
select sum(ind_revenue_000s)
FROM eia.tables_1_thru_4_2011; -- 67,605,747.7
-- pretty much, yes!

-- how much of the ventyx revenue got joined to the polygons?
select sum(total_industrial_revenue_000s)
FROM dg_wind.ventyx_elec_serv_territories_w_2011_sales_data;  -- 54594791.1

-- how much failed to join?
SELECT sum(bundled_energy_only_delivery_only_industrial_revenue_000s)
FROM dg_wind.ventyx_sales_no_polys; -- 13003701.6

-- do these add up to the original ventyx total?
select 54594791.1+13003701.6; -- 67,598,492.7
-- yes, exactly


-- *** -- Conclusions:
	-- the ventyx 2011 sales data is accurate at a national level,  in terms of sales, customers, and revenue, for all three market sectors when compared to the eia totals
		-- this means that I shouldn't add in any other data (e.g., from 2010 and 2009 ventyx sales data)
	-- the proposed solution should work

----------------------------------------------------------------------------------------------------------------------------------------
-- STEP 4: backfill the missing data as follows:
	--1- aggregate state level totals of the unjoined totals from sales table
	--2- join the state level remainders to state boundaries 
----------------------------------------------------------------------------------------------------------------------------------------

-- 1- aggregate state level totals of the unjoined totals from sales table
DROP TABLE IF EXISTS dg_wind.ventyx_sales_no_polys_state_aggregates;
CREATE TABLE dg_wind.ventyx_sales_no_polys_state_aggregates AS
SELECT customer_state as state_abbr, 

sum(bundled_energy_only_delivery_only_residential_revenue_000s) as total_residential_revenue_000s,
sum(bundled_delivery_only_residential_sales_mwh) as total_residential_sales_mwh,
sum(bundled_delivery_only_residential_customers) as total_residential_customers,

sum(bundled_energy_only_delivery_only_commercial_revenue_000s) as total_commercial_revenue_000s,
sum(bundled_delivery_only_commercial_sales_mwh) as total_commercial_sales_mwh,
sum(bundled_delivery_only_commercial_customers) as total_commercial_customers,

sum(bundled_energy_only_delivery_only_industrial_revenue_000s) as total_industrial_revenue_000s,
sum(bundled_delivery_only_industrial_sales_mwh)  as total_industrial_sales_mwh,
sum(bundled_delivery_only_industrial_customers) as total_industrial_customers,

2011::integer as data_year

FROM dg_wind.ventyx_sales_no_polys
group by customer_state; -- 43 rows (so these will only apply to 43 states)


-- 2- join the state level remainders to state boundaries 
	-- (decided to do this rather than try to isolate and combine unjoined service territories and portions of states without territories because it was too messy spatiall to do the latter)
-- load snapped state and province boundaries to: dg_wind.ventyx_states_and_provinces_snapped

-- test the join between the two
SELECT *
FROM dg_wind.ventyx_sales_no_polys_state_aggregates a
INNER JOIN dg_wind.ventyx_states_and_provinces_snapped b
ON a.state_abbr = b.abbrev;
	

--3- allocate values from step 1 to values from step 2	
	DROP TABLE IF EXISTS dg_wind.ventyx_elec_serv_territories_w_2011_sales_data_backfilled CASCADE;
	CREATE TABLE dg_wind.ventyx_elec_serv_territories_w_2011_sales_data_backfilled AS

	SELECT company_id, state_abbr, the_geom_4326, company_name, 
		       total_residential_revenue_000s, total_residential_sales_mwh, 
		       total_residential_customers, total_commercial_revenue_000s, total_commercial_sales_mwh, 
		       total_commercial_customers, total_industrial_revenue_000s, total_industrial_sales_mwh, 
		       total_industrial_customers, data_year,
		       'Ventyx Sales Data Join'::text as source
	FROM dg_wind.ventyx_elec_serv_territories_w_2011_sales_data

	UNION 
	
	SELECT -99999 as company_id, a.state_abbr, b.the_geom_4326, NULL::text as company_name,
		total_residential_revenue_000s, total_residential_sales_mwh, 
	       total_residential_customers, total_commercial_revenue_000s, total_commercial_sales_mwh, 
	       total_commercial_customers, total_industrial_revenue_000s, total_industrial_sales_mwh, 
	       total_industrial_customers, data_year,
       		'Backfilled with State-Aggregated Unjoined Ventyx Sales Data '::text as source
	FROM dg_wind.ventyx_sales_no_polys_state_aggregates a
	INNER JOIN dg_wind.ventyx_states_and_provinces_snapped b
	ON a.state_abbr = b.abbrev; -- make sure there are 43 of these -- and there are!

	-- add primary key
	ALTER TABLE dg_wind.ventyx_elec_serv_territories_w_2011_sales_data_backfilled ADD COLUMN gid serial;
	ALTER TABLE dg_wind.ventyx_elec_serv_territories_w_2011_sales_data_backfilled ADD primary key(gid);

	-- add spatial index
	CREATE INDEX ventyx_elec_serv_territories_w_2011_sales_data_backfilled_the_geom_4326_gist 
	ON  dg_wind.ventyx_elec_serv_territories_w_2011_sales_data_backfilled
	USING gist(the_geom_4326);

	VACUUM ANALYZE dg_wind.ventyx_elec_serv_territories_w_2011_sales_data_backfilled;
	



-- identify the census region and division for each ventyx service territory based on the state_abbr
-- (need this for MECS and CBECs processing)
ALTER TABLE dg_wind.ventyx_elec_serv_territories_w_2011_sales_data_backfilled 
ADD COLUMN census_region text, ADD COLUMN census_division text;

UPDATE dg_wind.ventyx_elec_serv_territories_w_2011_sales_data_backfilled a
SET (census_region, census_division) = (b.region,b.division)
FROM eia.census_regions b
WHERE a.state_abbr = b.state_abbr;
-- inspect results in Q

-- for later processing, we need this to be clipped down to the outer boundaries of diffusion_shared.county_geom
-- create a view of just the gids and geoms
CREATE OR REPLACE VIEW  dg_wind.ventyx_ests_backfilled_geoms AS
SELECT gid as est_gid, the_geom_4326
FROM dg_wind.ventyx_elec_serv_territories_w_2011_sales_data_backfilled;
-- export to shapefile 
	-- dg_wind.ventyx_ests_backfilled_geoms --> F:\data\mgleason\DG_Wind\Data\Analysis\county_boundaries\ventyx_ests_backfilled_geoms.shp
	-- diffusion_shared.county_geom --> F:\data\mgleason\DG_Wind\Data\Analysis\county_boundaries\county_geom.shp
-- dissolve county_geom.shp (allow multipart) -->F:\data\mgleason\DG_Wind\Data\Analysis\county_boundaries\county_geom_dissolved.shp
-- clip ventyx_ests_backfilled_geoms.shp using county_geom_dissolved.shp
	--> F:\data\mgleason\DG_Wind\Data\Analysis\county_boundaries\ventyx_ests_backfilled_geoms_clipped.shp
	--> make sure total count of features hasn't changed
-- reload the data to postgres
	--> dg_wind.ventyx_ests_backfilled_geoms_clipped
-- also create a single part version (Multipart to single part)
	--> F:\data\mgleason\DG_Wind\Data\Analysis\county_boundaries\ventyx_ests_backfilled_geoms_clipped_spart.shp
-- reload that to postgres too
	--> dg_wind.ventyx_ests_backfilled_geoms_clipped_spart
-- re-combine with the original data
DROP TABLE IF EXISTS dg_wind.ventyx_elec_serv_territories_w_2011_sales_data_backfilled_clip;
CREATE TABLE dg_wind.ventyx_elec_serv_territories_w_2011_sales_data_backfilled_clip AS
SELECT a.company_id, a.state_abbr, b.the_geom_4326, a.company_name, a.total_residential_revenue_000s, 
       a.total_residential_sales_mwh, a.total_residential_customers, a.total_commercial_revenue_000s, 
       a.total_commercial_sales_mwh, a.total_commercial_customers, a.total_industrial_revenue_000s, 
       a.total_industrial_sales_mwh, a.total_industrial_customers, a.data_year, 
       a.source, a.gid, a.census_region, a.census_division     
FROM dg_wind.ventyx_elec_serv_territories_w_2011_sales_data_backfilled a
LEFT JOIN dg_wind.ventyx_ests_backfilled_geoms_clipped b
ON a.gid = b.est_gid;
-- review in Q -- everything looks good

-- fix geoms
ALTER TABLE dg_wind.ventyx_elec_serv_territories_w_2011_sales_data_backfilled_clip
ALTER the_geom_4326 type geometry;

UPDATE dg_wind.ventyx_elec_serv_territories_w_2011_sales_data_backfilled_clip
SET the_geom_4326 = ST_Buffer(the_geom_4326,0.0)
where ST_IsValid(the_geom_4326) = false;

-- do some housekeeping
ALTER TABLE dg_wind.ventyx_elec_serv_territories_w_2011_sales_data_backfilled_clip ADD PRIMARY KEY (gid);

CREATE INDEX ventyx_elec_serv_territories_w_2011_sales_data_backfilled_clip_the_geom_4326_gist ON
dg_wind.ventyx_elec_serv_territories_w_2011_sales_data_backfilled_clip USING gist(the_geom_4326);

CREATE INDEX ventyx_ests_w_2011_sales_data_backfilled_clip_state_abbr_btree ON
dg_wind.ventyx_elec_serv_territories_w_2011_sales_data_backfilled_clip USING btree(state_abbr);

VACUUM ANALYZE dg_wind.ventyx_elec_serv_territories_w_2011_sales_data_backfilled_clip;


-- check that national level totals are consistent with ventyx and eia totals
select 	'backfilled'::text as source, sum(total_residential_revenue_000s) as res_revenue_000s, 
       sum(total_residential_sales_mwh) as res_sales_mwh, sum(total_residential_customers) as res_consumers, sum(total_commercial_revenue_000s) as com_revenue_000s, 
       sum(total_commercial_sales_mwh) as com_sales_mwh, sum(total_commercial_customers) as com_consumers, sum(total_industrial_revenue_000s) as ind_revenue_000s, 
       sum(total_industrial_sales_mwh) as ind_sales_mwh, sum(total_industrial_customers) as ind_consumers
FROM dg_wind.ventyx_elec_serv_territories_w_2011_sales_data_backfilled_clip

UNION

SELECT 'eia'::text as source, sum(res_revenue_000s), sum(res_sales_mwh), sum(res_consumers),
	sum(com_revenue_000s), sum(com_sales_mwh), sum(com_consumers),
	sum(ind_revenue_000s), sum(ind_sales_mwh), sum(ind_consumers)
FROM eia.tables_1_thru_4_2011

UNION 

SELECT  'ventyx sales'::text as source, sum(bundled_energy_only_delivery_only_residential_revenue_000s) as res_revenue_000s,
	sum(bundled_delivery_only_residential_sales_mwh) as res_sales_mwh,
	sum(bundled_delivery_only_residential_customers) as res_consumers,

	sum(bundled_energy_only_delivery_only_commercial_revenue_000s) as com_revenue_000s,
	sum(bundled_delivery_only_commercial_sales_mwh) as com_sales_mwh,
	sum(bundled_delivery_only_commercial_customers) as com_consumers,

	sum(bundled_energy_only_delivery_only_industrial_revenue_000s) as ind_revenue_000s,
	sum(bundled_delivery_only_industrial_sales_mwh ) as ind_sales_mwh,
	sum(bundled_delivery_only_industrial_customers) as ind_consumers

FROM ventyx.retail_sales_2011
where country = 'United States of America';


-- DONE!!!!!!!!!!!