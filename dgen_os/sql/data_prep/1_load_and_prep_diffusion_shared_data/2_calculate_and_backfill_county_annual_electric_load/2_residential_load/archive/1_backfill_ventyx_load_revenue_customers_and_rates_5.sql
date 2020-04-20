-- NOTE: need to create a new version of the electric_service_territories_states_with_ids using the ventyx state and province boundaries
-- then proceed with the rest, subbing in the ventyx states and provincs when I get to the erase phase

------------------------------------------------------------------------------------------------
-- create an edited version of ventyx.electric_services_territories_ventyx_states where pge extends into northern san francisco 
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
-- join in the retail sales data from 2011, back filling with 2010 and 2009 (in order)
-- join electric service territories to 2011 data
DROP TABLE IF ExISTS dg_wind.electric_service_territories_states_with_rates CASCADE;
CREATE TABLE dg_wind.electric_service_territories_states_with_rates AS
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
and a.company_id = b.company_id;

-- back fill with 2010 data where possible
UPDATE dg_wind.electric_service_territories_states_with_rates a
SET	(total_residential_revenue_000s,total_residential_sales_mwh,total_residential_customers,
	 total_commercial_revenue_000s,total_commercial_sales_mwh,total_commercial_customers,
	 total_industrial_revenue_000s,total_industrial_sales_mwh,total_industrial_customers,
	 data_year, company_name) =
	(b.bundled_energy_only_delivery_only_residential_revenue_000s,
	b.bundled_delivery_only_residential_sales_mwh,
	b.bundled_delivery_only_residential_customers,

	b.bundled_energy_only_delivery_only_commercial_revenue_000s,
	b.bundled_delivery_only_commercial_sales_mwh,
	b.bundled_delivery_only_commercial_customers,

	b.bundled_energy_only_delivery_only_industrial_revenue_000s,
	b.bundled_delivery_only_industrial_sales_mwh,
	b.bundled_delivery_only_industrial_customers,
	b.year, b.company_name)

FROM ventyx.electric_utility_rates_2010 b
where a.state_abbr = b.customer_state
and a.company_id = b.company_id
-- only the ones that are missing data
and a.data_year is null; 
-- this back fills 11 rows

-- back fill with 2009 data where possible
UPDATE dg_wind.electric_service_territories_states_with_rates a
SET	(total_residential_revenue_000s,total_residential_sales_mwh,total_residential_customers,
	 total_commercial_revenue_000s,total_commercial_sales_mwh,total_commercial_customers,
	 total_industrial_revenue_000s,total_industrial_sales_mwh,total_industrial_customers,
	 data_year, company_name) =
	(b.bundled_energy_only_delivery_only_residential_revenue_000s,
	b.bundled_delivery_only_residential_sales_mwh,
	b.bundled_delivery_only_residential_customers,

	b.bundled_energy_only_delivery_only_commercial_revenue_000s,
	b.bundled_delivery_only_commercial_sales_mwh,
	b.bundled_delivery_only_commercial_customers,

	b.bundled_energy_only_delivery_only_industrial_revenue_000s,
	b.bundled_delivery_only_industrial_sales_mwh,
	b.bundled_delivery_only_industrial_customers,
	b.year, b.company_name)

FROM ventyx.electric_utility_rates_2009 b
where a.state_abbr = b.customer_state
and a.company_id = b.company_id
-- only the ones that are missing data
and a.data_year is null; 
-- this back fills 10 rows












----------------------------------------------------------------------------------------------

-- -- find out which of the territories still have no data
-- COPY 
-- (SELECT company_id, state_name, company_name, ST_Area(the_geom_4326::geography)
-- FROM dg_wind.electric_service_territories_states_with_rates 
-- where data_year is null
-- order by st_area desc,company_id,company_name,state_name) 
-- to '/srv/data/transfer/mgleason/dg_wind/missing_utilities.csv' with csv header;


----------------------------------------------------------------------------------------------
-- back fill any remaining type 2 data gaps with state level 2011 values minus ventyx service territory data aggregated by states

-- check difference between 2011 ventyx aggregates and 2011 eia state totals, both aggregated to the national level
select sum(bundled_delivery_only_residential_sales_mwh)
FROM ventyx.electric_utility_rates_2011
where country = 'United States of America'; -- 1422801093

select sum(res_sales_mwh)
FROM eia.tables_1_thru_4; -- 1422802000

select sum(total_residential_sales_mwh)
FROM dg_wind.electric_service_territories_states_with_rates; -- 1,397,053,986

-- so this is the problem: the 2011 ventyx sales totals (from ventyx.electric_utility_rates_2011) are essentially the same at the national level as the 2011 eia tables 1 - 4
-- however, the ventyx sales data that actually joins to ventyx service territories is noticeably smaller, even including the 2009 and 2010 backfilling.
-- so we need to backfill further using the state level totals

-- since 2011 ventyx sales totals (from ventyx.electric_utility_rates_2011) are essentially the same at the national level as the 2011 eia tables 1 - 4, it justifies only using datayear 2011 in the backfilling process

select sum(bundled_delivery_only_commercial_sales_mwh)
FROM ventyx.electric_utility_rates_2011
where country = 'United States of America'; -- 1,328,035,748

select sum(com_sales_mwh)
FROM eia.tables_1_thru_4_2011; -- 1,328,056,000

select sum(total_commercial_sales_mwh)
FROM dg_wind.electric_service_territories_states_with_rates; -- 1,258,415,424
-- same findings as above for residential


select sum(bundled_delivery_only_industrial_sales_mwh)
FROM ventyx.electric_utility_rates_2011
where country = 'United States of America'; -- 991,241,801

select sum(ind_sales_mwh)
FROM eia.tables_1_thru_4_2011; -- 991,313,000


select sum(total_industrial_sales_mwh)
FROM dg_wind.electric_service_territories_states_with_rates; -- 941,491,761
-- same findings as noted above for residential/commercial


-- create a view that sums up the eia data by state (only include 2011 data, per findings in the previous step)
DROP VIEW IF EXISTS dg_wind.est_sum_rates_by_state;
CREATE OR REPLACE VIEW dg_wind.est_sum_rates_by_state AS
SELECT state_name, state_abbr, 
	sum(total_residential_revenue_000s) as est_sum_res_revenue_000s, 
	sum(total_residential_sales_mwh) as est_sum_res_sales_mwh, 
	sum(total_residential_customers) as est_sum_res_consumers, 
	sum(total_commercial_revenue_000s) as est_sum_com_revenue_000s, 
	sum(total_commercial_sales_mwh) as est_sum_com_sales_mwh, 
	sum(total_commercial_customers) as est_sum_com_consumers,
	sum(total_industrial_revenue_000s) as est_sum_ind_revenue_000s, 
	sum(total_industrial_sales_mwh) as est_sum_ind_sales_mwh, 
	sum(total_industrial_customers) as est_sum_ind_consumers
FROM dg_wind.electric_service_territories_states_with_rates
where data_year = 2011
GROUP BY state_name, state_abbr;

-- compare state-aggregated est data to state-level data directly from EIA
DROP TABLE IF EXISTS dg_wind.rate_remainders_state_totals_minus_est_sums CASCADE;
CREATE TABLE dg_wind.rate_remainders_state_totals_minus_est_sums AS
SELECT 	a.state as state_name,
	a.res_consumers as state_res_consumers, 
	b.est_sum_res_consumers,
	a.res_consumers - b.est_sum_res_consumers as remainder_res_consumers,
	(a.res_consumers - b.est_sum_res_consumers)/a.res_consumers::float as pcent_remainder_res_consumers,

	a.com_consumers as state_com_consumers, 
	b.est_sum_com_consumers,
	a.com_consumers - b.est_sum_com_consumers as remainder_com_consumers,
	(a.com_consumers - b.est_sum_com_consumers)/a.com_consumers::float as pcent_remainder_com_consumers,
	
	a.ind_consumers as state_ind_consumers, 
	b.est_sum_ind_consumers,
	a.ind_consumers - b.est_sum_ind_consumers as remainder_ind_consumers,
	(a.ind_consumers - b.est_sum_ind_consumers)/a.ind_consumers::float as pcent_remainder_ind_consumers,

	a.res_sales_mwh as state_res_sales_mwh, 
	b.est_sum_res_sales_mwh,
	a.res_sales_mwh - b.est_sum_res_sales_mwh as remainder_res_sales_mwh,
	(a.res_sales_mwh - b.est_sum_res_sales_mwh)/a.res_sales_mwh::float as pcent_remainder_res_sales,
	
	a.com_sales_mwh as state_com_sales_mwh, 
	b.est_sum_com_sales_mwh, 
	a.com_sales_mwh - b.est_sum_com_sales_mwh as remainder_com_sales_mwh,
	(a.com_sales_mwh - b.est_sum_com_sales_mwh)/a.com_sales_mwh::float as pcent_remainder_com_sales,
	
	a.ind_sales_mwh as state_ind_sales_mwh,
	b.est_sum_ind_sales_mwh, 
	a.ind_sales_mwh - b.est_sum_ind_sales_mwh as remainder_ind_sales_mwh,
	(a.ind_sales_mwh - b.est_sum_ind_sales_mwh)/a.ind_sales_mwh::float as pcent_remainder_ind_sales,

	a.res_revenue_000s as state_res_revenue_000s, 
	b.est_sum_res_revenue_000s, 
	a.res_revenue_000s - b.est_sum_res_revenue_000s as remainder_res_revenue_000s,
	(a.res_revenue_000s - b.est_sum_res_revenue_000s)/a.res_revenue_000s::float as pcent_remainder_res_revenue,
		
	a.com_revenue_000s as state_com_revenue_000s, 
	b.est_sum_com_revenue_000s,
	a.com_revenue_000s - b.est_sum_com_revenue_000s as remainder_com_revenue_000s,
	(a.com_revenue_000s - b.est_sum_com_revenue_000s)/a.com_revenue_000s::float as pcent_remainder_com_revenue,
	
	a.ind_revenue_000s as state_ind_revenue_000s, 
	b.est_sum_ind_revenue_000s,
	a.ind_revenue_000s - b.est_sum_ind_revenue_000s as remainder_ind_revenue_000s,
	(a.ind_revenue_000s - b.est_sum_ind_revenue_000s)/a.ind_revenue_000s::float as pcent_remainder_ind_revenue,
	
	a.res_rate_cents_per_kwh as state_res_rate_cents_per_kwh, 
	a.com_rate_cents_per_kwh as state_com_rate_cents_per_kwh, 
	a.ind_rate_cents_per_kwh as state_rate_cents_per_kwh

FROM eia.tables_1_thru_4 a

LEFT JOIN dg_wind.est_sum_rates_by_state b
ON a.state = b.state_name;

-- back fill with state remainders
DROP TABLE IF EXISTS dg_wind.ests_missing_data_by_state;
CREATE TABLE dg_wind.ests_missing_data_by_state AS
WITH spatial as (
	SELECT a.state_name,a.state_abbr, ST_Union(a.the_geom_4326) as the_geom_4326
	FROM dg_wind.electric_service_territories_states_with_rates a
	where data_year is null -- isolate the territories that had no 2011 or 2010 retail sales data and union them to a single geometry
	group by a.state_abbr, a.state_name)
SELECT 
	a.state_name, a.state_abbr,
	b.remainder_res_consumers, 
	b.remainder_com_consumers, 
	b.remainder_ind_consumers, 
	b.remainder_res_sales_mwh, 
	b.remainder_com_sales_mwh, 
	b.remainder_ind_sales_mwh, 
	b.remainder_res_revenue_000s, 
	b.remainder_com_revenue_000s, 
	b.remainder_ind_revenue_000s, -- assign data from the rate_remainers analysis to the state-unioned type 2 data gaps
	a.the_geom_4326
FROM spatial a
LEFT JOIN dg_wind.rate_remainders_state_totals_minus_est_sums b
ON a.state_name = b.state_name;


-- combine these results with the non-gaps from the rates table
DROP TABLE IF EXISTS dg_wind.electric_service_territories_states_with_rates_backfilled CASCADE;
CREATE TABLE dg_wind.electric_service_territories_states_with_rates_backfilled AS
SELECT 	company_id, state_name, state_abbr, the_geom_4326, 
	total_residential_customers, total_commercial_customers, total_industrial_customers, 
	total_residential_revenue_000s, total_commercial_revenue_000s, total_industrial_revenue_000s, 
	total_residential_sales_mwh, total_commercial_sales_mwh, total_industrial_sales_mwh, 
	data_year, 'Ventyx' as source

FROM dg_wind.electric_service_territories_states_with_rates
where data_year is not null -- don't incude the areas we are backfilling with state data

UNION ALL 

SELECT -99999 as company_id, state_name, state_abbr, the_geom_4326,
	remainder_res_consumers as total_residential_customers, remainder_com_consumers as total_commercial_customers, remainder_ind_consumers as total_industrial_customers, 
	remainder_res_revenue_000s as total_residential_revenue_000s, remainder_com_revenue_000s as total_commercial_revenue_000s, remainder_ind_revenue_000s as total_industrial_revenue_000s, 
	remainder_res_sales_mwh as total_residential_sales_mwh, remainder_com_sales_mwh as total_commercial_sales_mwh, remainder_ind_sales_mwh as total_industrial_sales_mwh, 
       2011 as data_year,
       'State-level EIA 2011 minus aggregated Ventyx 2011' as source
FROM dg_wind.ests_missing_data_by_state;

----------------------------------------------------------------------------------------------------------------------

-- add primary key
ALTER TABLE dg_wind.electric_service_territories_states_with_rates_backfilled
ADD COLUMN gid serial;

ALTER TABLE dg_wind.electric_service_territories_states_with_rates_backfilled
ADD PRIMARY KEY (gid) ;

-- add spatial index
CREATE INDEX electric_service_territories_states_with_rates_backfilled_gist 
ON dg_wind.electric_service_territories_states_with_rates_backfilled
USING gist(the_geom_4326);

VACUUM ANALYZE dg_wind.electric_service_territories_states_with_rates_backfilled ;

------------------------------------------------------------------------------------------------------------
SELECT count(*)
FROM dg_wind.electric_service_territories_states_with_rates
where data_year is null;

-- assess the effects of backfilling:
SELECT sum(total_residential_sales_mwh)
FROM dg_wind.electric_service_territories_states_with_rates_backfilled;
--1446529896

SELECT sum(total_residential_sales_mwh)
FROM dg_wind.electric_service_territories_states_with_rates_backfilled
where data_year = 2010;
--12125024
select (12125024/1446529896.)*100; --.83 %

SELECT sum(total_residential_sales_mwh)
FROM dg_wind.electric_service_territories_states_with_rates_backfilled
where data_year = 2009;
--11603129
select (11603129/1446529896.)*100; --.80 %


SELECT sum(total_residential_sales_mwh)
FROM dg_wind.electric_service_territories_states_with_rates_backfilled
where source <> 'Ventyx'
and total_residential_sales_mwh >= 0;
--49479810
select (49479810/1446529896.)*100; --3.4 %


-- create view of results with no negatives to export to shapefile
CREATE OR REPLACE VIEW dg_wind.electric_service_territories_with_rates_backfilled_res_only AS
SELECT company_id, state_name, state_abbr, the_geom_4326, total_residential_customers as customers, 
       total_residential_revenue_000s as rev_kdlrs, total_residential_sales_mwh as sales_mwh
FROm dg_wind.electric_service_territories_states_with_rates_backfilled
where total_residential_sales_mwh >= 0;


-- identify the census region and division for each ventyx service territory based on the state_abbr
-- (need this for MECS and CBECs processing)
ALTER TABLE dg_wind.electric_service_territories_states_with_rates_backfilled 
ADD COLUMN census_region text, ADD COLUMN census_division text;

UPDATE dg_wind.electric_service_territories_states_with_rates_backfilled a
SET (census_region, census_division) = (b.region,b.division)
FROM eia.census_regions b
WHERE a.state_abbr = b.state_abbr;