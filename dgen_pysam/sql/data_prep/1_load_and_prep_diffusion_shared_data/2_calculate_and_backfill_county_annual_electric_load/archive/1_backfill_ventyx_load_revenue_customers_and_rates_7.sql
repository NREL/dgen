-- NOTE: need to create a new version of the electric_service_territories_states_with_ids using the ventyx state and province boundaries
-- then proceed with the rest, subbing in the ventyx states and provincs when I get to the erase phase

------------------------------------------------------------------------------------------------
-- STEP 1: create an edited version of ventyx.electric_services_territories_ventyx_states where pge extends into northern san francisco 
------------------------------------------------------------------------------------------------
-- copy the table over
CREATE TABLE dg_wind.electric_services_territories_ventyx_states_edit AS
SELECT *
FROM ventyx.electric_services_territories_ventyx_states;

-- check that i have the right gids
SELECT *
from dg_wind.electric_services_territories_ventyx_states_edit
where gid in (2780,3379)

-- update the geometry for pge
with merged as (
	SELECT ST_Union(the_geom_4326) as the_geom_4326
	from dg_wind.electric_services_territories_ventyx_states_edit
	where gid in (2780,3379))
UPDATE dg_wind.electric_services_territories_ventyx_states_edit a
SET the_geom_4326 = b.the_geom_4326
FROM merged b
where a.gid = 2780
----------------------------------------------------------------------------------------------------------------

---------------------
-- There are 3 types of data gaps that can occur in the Ventyx data:
	-- 1) A polygon doesn't exist for a given area of the US -- treat these as valid gaps, indicating areas with no utility coverage (e.g. northern maine, central Nevada)
	-- 2) A polygon exists but the company is not listed in the retail sales data (try backfilling with 2010, 2009, and then state level 2011 data)
	-- 3) A polygon exists and the company is listed in the retail sales data, but retail sales are zero (for a given market sector)
			-- investigate manually in arc or Q: due to overalps of polygons, set drawing order to draw such areas on the bottom
			-- look into areas of high population that have no load shown at all -- these may be fixed by redrawing the boundaries of utility areas (see pge and city of san francisco above)
----------------------


----------------------------------------------------------------------------------------------------------------
-- STEP 2: Join Ventyx sales data (for 2011) to the (slightly edited) Ventyx service territories
----------------------------------------------------------------------------------------------------------------
-- join in the retail sales data from 2011, back filling with 2010 and 2009 (in order)
-- join electric service territories to 2011 data
DROP TABLE IF ExISTS dg_wind.ventyx_electric_service_territories_states_with_2011_sales_data CASCADE;
CREATE TABLE dg_wind.ventyx_electric_service_territories_states_with_2011_sales_data AS
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

FROM dg_wind.electric_services_territories_ventyx_states_edit a
INNER join ventyx.electric_utility_rates_2011 b -- use inner join to drop out the polygons that don't have matching sales data
ON a.state_abbr = b.customer_state
and a.company_id = b.company_id;

----------------------------------------------------------------------------------------------------------------
-- STEP 4: check for records that failed to join from the sales table to the polygons, and vice versa
----------------------------------------------------------------------------------------------------------------
	-- poly but no sales data
DROP TABLE IF EXISTS dg_wind.ventyx_polys_no_ventyx_sales;
CREATE TABLE dg_wind.ventyx_polys_no_ventyx_sales AS
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

FROM dg_wind.electric_services_territories_ventyx_states_edit a
LEFT join ventyx.electric_utility_rates_2011 b
ON a.state_abbr = b.customer_state
and a.company_id = b.company_id
where b.company_id is null; -- 733 rows

	-- sales data but no poly
DROP TABLE IF EXISTS  dg_wind.ventyx_sales_no_ventyx_polys;
CREATE TABLE dg_wind.ventyx_sales_no_ventyx_polys AS
SELECT b.*

FROM ventyx.electric_utility_rates_2011 b
LEFT join  dg_wind.electric_services_territories_ventyx_states_edit a
ON b.customer_state = a.state_abbr
and b.company_id = a.company_id
where a.company_id is null
and b.country = 'United States of America'; -- 555 rows failed to match

	-- investigate these in Q:
		-- results suggest that several of the entries in the sales table do not have a corresponding polygon -- so there isn't a simple fix like manually correcting company ids
		-- this result also indicates that the polygon data may not be fully representative of all service territories

		-- proposed solution:
			--1- aggregate state level totals of the unjoined totals from sales table
			--2- for each state, combine unjoined polygons from ventyx as well as portions of states without polygons into a single state level remainder polygon
			--3- allocate values from step 1 to values from step 2

---------------------------------------------------------------------------------------------------------------------------------------------------
-- STEP 3: run some investigations to make sure proposed solution for backfilling is appropriate and will be represntative of 2011 sales, revenue, and customer totals
---------------------------------------------------------------------------------------------------------------------------------------------------

---------
-- investigation 1: compare national level load totals between 2011 ventyx retail sales table, 2011 eia tables 1-4, and joined ventyx data
---------
-- how much is in the ventyx sale data?
select sum(bundled_delivery_only_residential_sales_mwh)
FROM ventyx.electric_utility_rates_2011
where country = 'United States of America'; -- 1,422,801,093

-- is this the same as what's in the eia totals?
select sum(res_sales_mwh)
FROM eia.tables_1_thru_4_2011; -- 1,422,802,000
-- pretty much, yes!

-- how much of the ventyx sales data got joined to the polygons?
select sum(total_residential_sales_mwh)
FROM dg_wind.ventyx_electric_service_territories_states_with_2011_sales_data
where data_year = 2011;  ---1,373,325,833

-- how much failed to join?
SELECT sum(bundled_delivery_only_residential_sales_mwh)
FROM dg_wind.ventyx_sales_no_ventyx_polys; -- 49,475,260 -- unjoined to polys

-- do these add up to the original ventyx retail sales total?
select 1373325833+49475260; -- 1422801093
-- yes, exactly


-- repeat this check for commercial:
-- how much is in the ventyx sale data?
select sum(bundled_delivery_only_commercial_sales_mwh)
FROM ventyx.electric_utility_rates_2011
where country = 'United States of America'; -- 1,328,035,748

-- is this the same as what's in the eia totals?
select sum(com_sales_mwh)
FROM eia.tables_1_thru_4_2011; -- 1,328,056,000
-- pretty much, yes!

-- how much of the ventyx sales data got joined to the polygons?
select sum(total_commercial_sales_mwh)
FROM dg_wind.ventyx_electric_service_territories_states_with_2011_sales_data
where data_year = 2011; -- 1,233,590,994

-- how much failed to join?
SELECT sum(bundled_delivery_only_commercial_sales_mwh)
FROM dg_wind.ventyx_sales_no_ventyx_polys; -- 94,444,754

-- do these add up to the original ventyx retail sales total?
select 1233590994+94444754; -- 1,328,035,748
-- yes, exactly


-- repeat this check for industrial:
-- how much is in the ventyx sale data?
select sum(bundled_delivery_only_industrial_sales_mwh)
FROM ventyx.electric_utility_rates_2011
where country = 'United States of America'; -- 991,241,801

-- is this the same as what's in the eia totals?
select sum(ind_sales_mwh)
FROM eia.tables_1_thru_4_2011; -- 991,313,000
-- pretty much, yes!

-- how much of the ventyx sales data got joined to the polygons?
select sum(total_industrial_sales_mwh)
FROM dg_wind.ventyx_electric_service_territories_states_with_2011_sales_data
where data_year = 2011; -- 922,566,890

-- how much failed to join?
SELECT sum(bundled_delivery_only_industrial_sales_mwh)
FROM dg_wind.ventyx_sales_no_ventyx_polys; -- 68,674,911

-- do these add up to the original ventyx retail sales total?
select 922566890+68674911; -- 991,241,801
-- yes, exactly

---------
-- investigation 2: compare national level customer totals between 2011 ventyx retail sales table, 2011 eia tables 1-4, and joined ventyx data
---------
-- check residential:
-- how many customers are in the ventyx sales data?
select sum(bundled_delivery_only_residential_customers)
FROM ventyx.electric_utility_rates_2011
where country = 'United States of America'; -- 126,143,072

-- is this the same as what's in the eia totals?
select sum(res_consumers)
FROM eia.tables_1_thru_4_2011; -- 126,143,072 
-- yep, nailed it!

-- how many of the ventyx customers got joined to the polygons?
select sum(total_residential_customers)
FROM dg_wind.ventyx_electric_service_territories_states_with_2011_sales_data
where data_year = 2011;  -- 122,514,645

-- how many failed to join?
SELECT sum(bundled_delivery_only_residential_customers)
FROM dg_wind.ventyx_sales_no_ventyx_polys; -- 3,628,427

-- do these add up to the original ventyx total?
select 122514645+3628427; -- 126,143,072
-- yes, exactly


-- repeat this check for commercial:
-- how many customers are in the ventyx sales data?
select sum(bundled_delivery_only_commercial_customers)
FROM ventyx.electric_utility_rates_2011
where country = 'United States of America'; -- 17,638,050

-- is this the same as what's in the eia totals?
select sum(com_consumers)
FROM eia.tables_1_thru_4_2011; -- 17,638,062 
-- pretty much, yes!

-- how many of the ventyx customers got joined to the polygons?
select sum(total_commercial_customers)
FROM dg_wind.ventyx_electric_service_territories_states_with_2011_sales_data
where data_year = 2011;  -- 17,042,049

-- how many failed to join?
SELECT sum(bundled_delivery_only_commercial_customers)
FROM dg_wind.ventyx_sales_no_ventyx_polys; -- 596,001

-- do these add up to the original ventyx total?
select 17042049+596001; -- 17,638,050
-- yes, exactly


-- repeat this check for industrial:
-- how many customers are in the ventyx sales data?
select sum(bundled_delivery_only_industrial_customers)
FROM ventyx.electric_utility_rates_2011
where country = 'United States of America'; -- 727,915

-- is this the same as what's in the eia totals?
select sum(ind_consumers)
FROM eia.tables_1_thru_4_2011; -- 727,920
-- pretty much, yes!

-- how many of the ventyx customers got joined to the polygons?
select sum(total_industrial_customers)
FROM dg_wind.ventyx_electric_service_territories_states_with_2011_sales_data
where data_year = 2011;  -- 723,260

-- how many failed to join?
SELECT sum(bundled_delivery_only_industrial_customers)
FROM dg_wind.ventyx_sales_no_ventyx_polys; -- 4655

-- do these add up to the original ventyx total?
select 723260+4655; -- 727,915
-- yes, exactly

---------
-- investigation 3: compare national level revenue totals between 2011 ventyx retail sales table, 2011 eia tables 1-4, and joined ventyx data
---------
-- check residential:
-- how much revenue is in the ventyx sales data?
select sum(bundled_energy_only_delivery_only_residential_revenue_000s)
FROM ventyx.electric_utility_rates_2011
where country = 'United States of America'; -- 166,714,106.8

-- is this the same as what's in the eia totals?
select sum(res_revenue_000s)
FROM eia.tables_1_thru_4_2011; -- 166,714,106.8 -- nailed it!

-- how much of the ventyx revenue got joined to the polygons?
select sum(total_residential_revenue_000s)
FROM dg_wind.ventyx_electric_service_territories_states_with_2011_sales_data
where data_year = 2011;  -- 156,856,121.8

-- how much failed to join?
SELECT sum(bundled_energy_only_delivery_only_residential_revenue_000s)
FROM dg_wind.ventyx_sales_no_ventyx_polys; -- 9,857,985.0

-- do these add up to the original ventyx total?
select 156856121.8+9857985.0; -- 166,714,106.8
-- yes, exactly


-- repeate for commercial:
-- how much revenue is in the ventyx sales data?
select sum(bundled_energy_only_delivery_only_commercial_revenue_000s)
FROM ventyx.electric_utility_rates_2011
where country = 'United States of America'; -- 135,924,384.9

-- is this the same as what's in the eia totals?
select sum(com_revenue_000s)
FROM eia.tables_1_thru_4_2011; -- 135,926,483.9
-- pretty much, yes!

-- how much of the ventyx revenue got joined to the polygons?
select sum(total_commercial_revenue_000s)
FROM dg_wind.ventyx_electric_service_territories_states_with_2011_sales_data
where data_year = 2011;  -- 110,949,954.4

-- how much failed to join?
SELECT sum(bundled_energy_only_delivery_only_commercial_revenue_000s)
FROM dg_wind.ventyx_sales_no_ventyx_polys; -- 24,974,430.5

-- do these add up to the original ventyx total?
select 110949954.4+24974430.5; -- 135,924,384.9
-- yes, exactly


-- repeate for industrial:
-- how much revenue is in the ventyx sales data?
select sum(bundled_energy_only_delivery_only_industrial_revenue_000s)
FROM ventyx.electric_utility_rates_2011
where country = 'United States of America'; -- 67,598,492.7

-- is this the same as what's in the eia totals?
select sum(ind_revenue_000s)
FROM eia.tables_1_thru_4_2011; -- 67,605,747.7
-- pretty much, yes!

-- how much of the ventyx revenue got joined to the polygons?
select sum(total_industrial_revenue_000s)
FROM dg_wind.ventyx_electric_service_territories_states_with_2011_sales_data
where data_year = 2011;  -- 54,649,249.5

-- how much failed to join?
SELECT sum(bundled_energy_only_delivery_only_industrial_revenue_000s)
FROM dg_wind.ventyx_sales_no_ventyx_polys; -- 12,949,243.2

-- do these add up to the original ventyx total?
select 54649249.5+12949243.2; -- 67,598,492.7
-- yes, exactly


-- *** -- Conclusions:
	-- the ventyx 2011 sales data is accurate at a national level,  in terms of sales, customers, and revenue, for all three market sectors when compared to the eia totals
		-- this means that I shouldn't add in any other data (e.g., from 2010 and 2009 ventyx sales data)
	-- the proposed solution should work

----------------------------------------------------------------------------------------------------------------------------------------
-- STEP 4: backfill the missing data as follows:
	--1- aggregate state level totals of the unjoined totals from sales table
	--2- for each state, combine unjoined polygons from ventyx as well as portions of states without polygons into a single state level remainder polygon
	--3- allocate values from step 1 to values from step 2
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

FROM dg_wind.ventyx_sales_no_ventyx_polys
group by customer_state; -- 40 rows (so these will only apply to 40 states)


-- 2- for each state, combine unjoined polygons from ventyx as well as portions of states without polygons into a single state level remainder polygon
	-- export the following to shapefile:
		-- ventyx polys withOUT sales data: dg_wind.ventyx_polys_no_ventyx_sales
		-- ventyx state data: ventyx.states_only
		-- ventyx polys with sales data: dg_wind.ventyx_electric_service_territories_states_with_2011_sales_data
	-- in arcgis:
		-- erase ventyx polys with sales data from ventyx states
			-->F:\data\mgleason\DG_Wind\Data\Analysis\ventyx_2011_retail_sales_backfilling\states_erase_ventyx_with_sales.shp
		-- merge the erase result with  ventyx polys withOUT sales data
			-->F:\data\mgleason\DG_Wind\Data\Analysis\ventyx_2011_retail_sales_backfilling\merged_no_sales_data.shp
		-- dissolve the merged result by state
			-- first make sure that there is a fully populated state field in merged_no_sales_data.shp (if not, populate it)
			--> F:\data\mgleason\DG_Wind\Data\Analysis\ventyx_2011_retail_sales_backfilling\merged_no_sales_data_state_dissolved.shp
	-- reload shapefile to postgres
		--> dg_wind.ventyx_missing_sales_data_polygons

--3- allocate values from step 1 to values from step 2	
	DROP TABLE IF EXISTS dg_wind.ventyx_ests_2011_sales_data_backfilled;
	CREATE TABLE dg_wind.ventyx_ests_2011_sales_data_backfilled AS

	SELECT company_id, state_name, state_abbr, the_geom_4326, company_name, 
		       total_residential_revenue_000s, total_residential_sales_mwh, 
		       total_residential_customers, total_commercial_revenue_000s, total_commercial_sales_mwh, 
		       total_commercial_customers, total_industrial_revenue_000s, total_industrial_sales_mwh, 
		       total_industrial_customers, data_year,
		       'Ventyx Sales Data Join'::text as source
	FROM dg_wind.ventyx_electric_service_territories_states_with_2011_sales_data

	UNION 
	
	SELECT -99999 as company_id, c.state_name as state_name, a.state_abbr, b.the_geom_4326, NULL::text as company_name,
		total_residential_revenue_000s, total_residential_sales_mwh, 
	       total_residential_customers, total_commercial_revenue_000s, total_commercial_sales_mwh, 
	       total_commercial_customers, total_industrial_revenue_000s, total_industrial_sales_mwh, 
	       total_industrial_customers, data_year,
       		'Backfilled with State-Aggregated Unjoined Ventyx Sales Data '::text as source
	FROM dg_wind.ventyx_sales_no_polys_state_aggregates a
	INNER JOIN dg_wind.ventyx_missing_sales_data_polygons b
	ON a.state_abbr = b.state_abbr
	INNER JOIN esri.dtl_state c
	ON a.state_abbr = c.state_abbr; -- make sure there are 40 of these -- and there are!

	-- add primary key
	ALTER TABLE dg_wind.ventyx_ests_2011_sales_data_backfilled ADD COLUMN gid serial;
	ALTER TABLE dg_wind.ventyx_ests_2011_sales_data_backfilled ADD primary key(gid);

	-- add spatial index
	CREATE INDEX ventyx_ests_2011_sales_data_backfilled_the_geom_4326_gist 
	ON  dg_wind.ventyx_ests_2011_sales_data_backfilled
	USING gist(the_geom_4326);

	VACUUM ANALYZE dg_wind.ventyx_ests_2011_sales_data_backfilled;
	





-- identify the census region and division for each ventyx service territory based on the state_abbr
-- (need this for MECS and CBECs processing)
ALTER TABLE dg_wind.ventyx_ests_2011_sales_data_backfilled 
ADD COLUMN census_region text, ADD COLUMN census_division text;

UPDATE dg_wind.ventyx_ests_2011_sales_data_backfilled a
SET (census_region, census_division) = (b.region,b.division)
FROM eia.census_regions b
WHERE a.state_abbr = b.state_abbr;


-- export to shapefile and inspect in Arc to make sure nothing looks too crazy