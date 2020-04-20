-- *****************************************************
-- Important Notes on Tagging Rates to Counties
-- *****************************************************
-- All Rates are associated with a Utility (EIA ID) which can be tagged to a county using EIA's Utility to County Mapping
-- Not all Utilities can be tagged this way, however most can.

-- We are using Counties are the utility territory boundary
	-- Pros/Cons: Lose precision but gain accuracy
	-- Ventyx boundaries often have many errors (e.g. entire metropolitan areas were not covered)
	-- Ventyx IDs do not match up with the EIA IDS, so it saves us a lot of headache with trying to match them up

-- This process is cannot necessarily be streamlined. For those that do not match up with the EIA-to-county-mapping, we will need to use 
-- the ventyx boundaries (using a levenstein fuzzy join on the utility name) to pair the rates to specific ventyx geoms and then from ventyx
-- geoms to intersecting counties.

-- Before running this code, you need to run the tariff_generator.py to populate the table with urdb rates
	-- note, the py code with generate the rate_id_alias

--------------------------------------------------------------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- 1. Join eia_id to counties (using the eia to county mapping table)
--------------------------------------------------------------------------------
	DROP TABLE IF EXISTS urdb_rates.urdb_utility_eia_and_county_ids_lkup_20161005_temp;
	CREATE TABLE urdb_rates.urdb_utility_eia_and_county_ids_lkup_20161005_temp as (
	select 
	a.rate_id_alias,
	a.eia_id,
	b.statefp as state_fips,
	b.countyfp as cnty_fips
	from urdb_rates.urdb3_verified_rates_sam_data_20161005 a
	left join eia.eia_861_2013_county_utility_rates b
	on a.eia_id = cast(b.utility_num as text)
	);

	alter table urdb_rates.urdb_utility_eia_and_county_ids_lkup_20161005_temp
	owner to "urdb_rates-writers";

	-- 5404 distinct rate_ids in lkup; 1123 distinct eia_ids

-- 1b. QAQC- check to make sure that all utilities have a match
	-- select distinct(eia_id) from urdb_rates.urdb_utility_eia_and_county_ids_lkup_20161005_temp where cnty_fips is null;
	-- 12 utilities do not have a match
		-- where eia_id = '2268' OR eia_id = '5729' OR eia_id = '11235' OR eia_id = '4062' OR eia_id = '19174' OR eia_id = '25251' OR eia_id = '14272' OR eia_id = '26751' OR eia_id = '40300' OR eia_id = '3292' OR eia_id = '9026' OR eia_id = 'No eia id given' OR eia_id = '5553')
	-- 1 distinct record of "no eia_id given"

------------------------------------------------------------------------------------------------------------
-- 2. Join EIA IDs with Missing Counties to their Correct County - Methods are Unique to each Utility Name
------------------------------------------------------------------------------------------------------------
	set role 'urdb_rates-writers';
	drop table if exists urdb_rates.urdb_utility_eia_and_county_ids_lkup_20161005;
	create table urdb_rates.urdb_utility_eia_and_county_ids_lkup_20161005 as (

	-- 2A. Solution Part 1 -- Identify Ventyx Boundary using Billy's Ventyx Shapefile with EIA ids (Govt ID)
		-- Only a few matched up in the shapefile (2013_07_16_Ventyx_Utilities_withEIAID.shp)
		-- Apply this method to only those that are in the shapefile
		with solution1 as (
			with id_2268 as (
				with x as (select '2268'::text as eia_id, company_id, the_geom_4326 from ventyx.electric_service_territories_20150701 where company_id = 62705)
				select x.eia_id, state_fips, cnty_fips from esri.dtl_cnty_all_multi_20110101 a, x where st_intersects(a.the_geom_4326, x.the_geom_4326)),
			id_4062 as (
				with x as (select '4062'::text as eia_id, company_id, the_geom_4326 from ventyx.electric_service_territories_20150701 where company_id = 1031) -- check
				select x.eia_id, state_fips, cnty_fips from esri.dtl_cnty_all_multi_20110101 a, x where st_intersects(a.the_geom_4326, x.the_geom_4326)),
			id_9026 as (
				with x as (select '9026'::text as eia_id, company_id, the_geom_4326 from ventyx.electric_service_territories_20150701 where company_id = 61865)
				select x.eia_id, state_fips, cnty_fips from esri.dtl_cnty_all_multi_20110101 a, x where st_intersects(a.the_geom_4326, x.the_geom_4326)),
			id_14272 as (
				with x as (select '14272'::text as eia_id, company_id, the_geom_4326 from ventyx.electric_service_territories_20150701 where company_id = 62516)
				select x.eia_id, state_fips, cnty_fips from esri.dtl_cnty_all_multi_20110101 a, x where st_intersects(a.the_geom_4326, x.the_geom_4326))
			select * from id_2268
			union all
			select * from id_4062
			union all
			select * from id_9026
			union all
			select * from id_14272),

	-- 2B. Solution Part 2 -- Identify Ventyx Region Based on Similar Name and Then Use Ventyx Region to Identify COunties
		solution2 as (
			with id_25251 as (
				with x as (select '25251'::text as eia_id, the_geom_4326 from ventyx.electric_service_territories_20150701 where planning_a = 'Entergy Services Inc')
				select x.eia_id, state_fips, cnty_fips from esri.dtl_cnty_all_multi_20110101 a, x where st_intersects(a.the_geom_4326, x.the_geom_4326)),
			id_none as (
				with x as (select 'No eia id given'::text as eia_id, the_geom_4326 from ventyx.electric_service_territories_20150701 where planning_a = 'Old Dominion Electric Coop Inc')
				select x.eia_id, state_fips, cnty_fips from esri.dtl_cnty_all_multi_20110101 a, x where st_intersects(a.the_geom_4326, x.the_geom_4326)),
			id_11235 as (
				with x as (select '11235'::text as eia_id, the_geom_4326 from ventyx.electric_service_territories_20150701 where planning_a = 'Lafayette Utilities System')
				select x.eia_id, state_fips, cnty_fips from esri.dtl_cnty_all_multi_20110101 a, x where st_intersects(a.the_geom_4326, x.the_geom_4326)),
			id_26751 as (
				with x as (select '26751'::text as eia_id, the_geom_4326 from ventyx.electric_service_territories_20150701 where holding_co = 'National Grid Plc')
				select x.eia_id, state_fips, cnty_fips from esri.dtl_cnty_all_multi_20110101 a, x where st_intersects(a.the_geom_4326, x.the_geom_4326)),
			id_14272 as (
				with x as (select '14272'::text as eia_id, the_geom_4326 from ventyx.electric_service_territories_20150701 where company_na = 'Owensville Municipal Utilities')
				select x.eia_id, state_fips, cnty_fips from esri.dtl_cnty_all_multi_20110101 a, x where st_intersects(a.the_geom_4326, x.the_geom_4326)),
			id_3292 as (
				with x as (select '3292'::text as eia_id, the_geom_4326 from ventyx.electric_service_territories_20150701 where company_na = 'Green Mountain Power Corp')
				select x.eia_id, state_fips, cnty_fips from esri.dtl_cnty_all_multi_20110101 a, x where st_intersects(a.the_geom_4326, x.the_geom_4326)), --****
			id_40300 as (
				with x as (select '40300'::text as eia_id, the_geom_4326 from ventyx.electric_service_territories_20150701 where membership = 'Nebraska Electric G & T Coop Inc')
				select x.eia_id, state_fips, cnty_fips from esri.dtl_cnty_all_multi_20110101 a, x where st_intersects(a.the_geom_4326, x.the_geom_4326)),
			id_5553 as (
				with x as (select '5553'::text as eia_id, the_geom_4326 from ventyx.electric_service_territories_20150701 where company_na = 'Egegik (City of)') -- check**
				select x.eia_id, state_fips, cnty_fips from esri.dtl_cnty_all_multi_20110101 a, x where st_intersects(a.the_geom_4326, x.the_geom_4326))
			select * from id_25251 union all
			select * from id_none union all
			select * from id_11235 union all
			select * from id_26751 union all
			select * from id_14272 union all
			select * from id_3292 union all
			select * from id_40300 union all
			select * from id_5553
			),
		-- NOTE id # 3292 = 'Central Vermont Public Power' which merged with Green Mountain POwer (http://www.greenmountainpower.com/merger-info/), so we are using the boundary of Green Mountain POwer
		-- Note 1 of the ids = "No eia id given"


	-- 2C. Solution Part 3 -- Identify County Based on Utility Company Name
		solution3 as (
			-- Maricopa County AZ
			with id_5729 as (select '5729'::text as eia_id, state_fips, cnty_fips from esri.dtl_cnty_all_multi_20110101 where state_name = 'Arizona' and name like '%Maricopa%'),
			-- Tuolumne County, CA
			id_19174 as (select '19174'::text as eia_id, state_fips, cnty_fips from esri.dtl_cnty_all_multi_20110101 where state_name = 'California' and name like '%Tuolumne%')
			select * from id_5729 union all 
			select * from id_19174)
		
	-- 2D. -- MERGE ALL TOGETHER
		select * from urdb_rates.urdb_utility_eia_and_county_ids_lkup_20161005_temp where cnty_fips is not null union all
		select b.rate_id_alias, a.* from solution1 a left join urdb_rates.urdb_utility_eia_and_county_ids_lkup_20161005_temp b on a.eia_id = b.eia_id union all
		select b.rate_id_alias, a.* from solution2 a left join urdb_rates.urdb_utility_eia_and_county_ids_lkup_20161005_temp b on a.eia_id = b.eia_id union all
		select b.rate_id_alias, a.* from solution3 a left join urdb_rates.urdb_utility_eia_and_county_ids_lkup_20161005_temp b on a.eia_id = b.eia_id);

	-- QAQC -- Check
		--select count (distinct rate_id_alias) from urdb_rates.urdb_utility_eia_and_county_ids_lkup_20161005;
		--5405 unique (goot to go)
		--select count (distinct eia_id) from urdb_rates.urdb_utility_eia_and_county_ids_lkup_20161005;
		-- 1123 (good to go)
	
	drop table if exists urdb_rates.urdb_utility_eia_and_county_ids_lkup_20161005_temp;

	alter table urdb_rates.urdb_utility_eia_and_county_ids_lkup_20161005
	owner to "urdb_rates-writers";

	-- Alter json field - change type to json
	alter table urdb_rates.urdb3_verified_rates_sam_data_20161005
	alter column json type json using json::json;

-----------------------------------
-- 3. Make BTREES
-----------------------------------
create index urdb_utility_eia_and_county_ids_lkup_20161005_rate_id_alias 
	on urdb_rates.urdb_utility_eia_and_county_ids_lkup_20161005
	using btree(rate_id_alias);
create index urdb_utility_eia_and_county_ids_lkup_20161005_eia_id
	on urdb_rates.urdb_utility_eia_and_county_ids_lkup_20161005
	using btree(eia_id);
create index urdb_utility_eia_and_county_ids_lkup_20161005_state_fips 
	on urdb_rates.urdb_utility_eia_and_county_ids_lkup_20161005
	using btree(state_fips);
create index urdb_utility_eia_and_county_ids_lkup_20161005_county_fips
	on urdb_rates.urdb_utility_eia_and_county_ids_lkup_20161005
	using btree(cnty_fips);
create index urdb3_verified_rates_sam_data_20161005_eia_id
	on urdb_rates.urdb3_verified_rates_sam_data_20161005 using btree(eia_id);
create index urdb3_verified_rates_sam_data_20161005_rate_id_alias
	on urdb_rates.urdb3_verified_rates_sam_data_20161005 using btree(rate_id_alias);