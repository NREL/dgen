-- This code is an extension of 1_tag_rates_to_county_geoms.sql

--------------------------------------------------------------------------------------------------------------------------------------


--------------------------------------------------------
-- 1. QAQC Counties and Rates
--------------------------------------------------------
	-- Check to make sure that utility rates are appropriately tagged to each county

	-- 1. Make sure that a region specific rate for a multipart utility (with 1 eia_id) 
			-- is not tagged to all of the utility's parts
			-- e.g. make sure PacifiCorp (Oregon) rate is not tagged to a CA county
			-- many state specific rates are identified in the utility_name as: ~ (State Name)
			-- Step 1: Identify which rates are identified in the wrong states
			with rates_with_states_in_name as (
				select a.rate_id_alias, a.utility_name, b.name as state_name, b.fips as state_fips 
				from urdb_rates.urdb3_verified_rates_sam_data_20161005 a
				inner join mmooney.us_states b 
				on utility_name like '%(' || initcap(b.name) || ')%'),
			b as (
				select a.*, b.state_fips as state_fips2 
				from rates_with_states_in_name a
				left join urdb_rates.urdb_utility_eia_and_county_ids_lkup_20161005 b
				on a.rate_id_alias = b.rate_id_alias)
			-- Step 2: remove these rate, eia_id, county and state records from lkup table
			delete from urdb_rates.urdb_utility_eia_and_county_ids_lkup_20161005 a using b 
			where a.rate_id_alias = b.rate_id_alias and a.state_fips = b.state_fips2;

	-- 2. Check to see if other rates have the state name in the utility_name. -- Are these suspect?
			-- Check to make sure these are suspect or not: 
					-- ASK: Are they neighboring states? 
					-- Is there an obvious seperation between the state name and the utility name? e.g. is there a "-" or ":"
					-- Does the utility name start with "City of..." or "County of..."?
			with rates_with_states_in_name as (
				select a.rate_id_alias, a.utility_name, b.name as state_name, b.fips as state_fips 
				from urdb_rates.urdb3_verified_rates_sam_data_20161005 a
				inner join mmooney.us_states b 
				on utility_name like '%' || initcap(b.name) || '%'),
			b as (
				select a.*, b.state_fips as state_fips2 
				from rates_with_states_in_name a
				left join urdb_rates.urdb_utility_eia_and_county_ids_lkup_20161005 b
				on a.rate_id_alias = b.rate_id_alias)
			select * from b;

			with rates_with_states_in_name as (
				select a.rate_id_alias, a.utility_name, b.name as state_name, b.fips as state_fips 
				from urdb_rates.urdb3_verified_rates_sam_data_20161005 a
				inner join mmooney.us_states b 
				on utility_name like '%' || initcap(b.name) || '%'),
			b as (
				select a.*, b.state_fips as state_fips2 
				from rates_with_states_in_name a
				left join urdb_rates.urdb_utility_eia_and_county_ids_lkup_20161005 b
				on a.rate_id_alias = b.rate_id_alias),
			x as (select distinct utility_name, state_name, state_fips, state_fips2 as wrong_state_fips 
			 from b where state_fips != state_fips2)

			select x.*, y.name as state_name_of_wrong_fips from x
			left join mmooney.us_states y
			on x.wrong_state_fips = y.fips;

			-- 32 potential errors. * = the most suspect
				-- fields = utility_name, state_name, state_fips, wrong_state_fips, state_name_of_wrong_fips
				-- "Oklahoma Gas & Electric Co";"OKLAHOMA";"40";"05";"ARKANSAS"
				-- "Idaho Power Co";"IDAHO";"16";"41";"OREGON"
				-- "Southwest Arkansas E C C";"ARKANSAS";"05";"40";"OKLAHOMA"
				-- "Kentucky Utilities Co";"KENTUCKY";"21";"47";"TENNESSEE"
				-- ** "City of Siloam Springs, Arkansas (Utility Company)";"ARKANSAS";"05";"40";"OKLAHOMA"
				-- "Southwest Arkansas E C C";"ARKANSAS";"05";"48";"TEXAS"
				-- ** "Northern States Power Co - Wisconsin";"WISCONSIN";"55";"26";"MICHIGAN"
				-- "Mississippi County Electric Coop";"MISSISSIPPI";"28";"05";"ARKANSAS"
				-- "Wisconsin Public Service Corp";"WISCONSIN";"55";"26";"MICHIGAN"
				-- ** "City of Columbus, Mississippi (Utility Company)";"MISSISSIPPI";"28";"21";"KENTUCKY"
				-- "Northwestern Wisconsin Elec Co";"WISCONSIN";"55";"27";"MINNESOTA"
				-- ** "City of Chattanooga, Georgia (Utility Company)";"GEORGIA";"13";"47";"TENNESSEE"
				-- ** "City of Columbus, Mississippi (Utility Company)";"MISSISSIPPI";"28";"54";"WEST VIRGINIA"
				-- "Wisconsin Electric Power Co";"WISCONSIN";"55";"26";"MICHIGAN"
				-- "Nebraska Public Power District";"NEBRASKA";"31";"46";"SOUTH DAKOTA"
				-- "Kentucky Utilities Co";"KENTUCKY";"21";"51";"VIRGINIA"
				-- "Nebraska Electric G&T Coop Inc";"NEBRASKA";"31";"08";"COLORADO"
				-- "Central Vermont Pub Serv Corp";"VERMONT";"50";"25";"MASSACHUSETTS"
				-- "Nebraska Electric G&T Coop Inc";"NEBRASKA";"31";"46";"SOUTH DAKOTA"
				-- "Virginia Electric & Power Co";"VIRGINIA";"51";"37";"NORTH CAROLINA"
				-- "Texas-New Mexico Power Co";"NEW MEXICO";"35";"48";"TEXAS"
				-- ** "City of Jellico, Tennessee (Utility Company)";"TENNESSEE";"47";"21";"KENTUCKY"
				-- ** "City of Rockport, Missouri (Utility Company)";"MISSOURI";"29";"31";"NEBRASKA"
				-- "Central Vermont Pub Serv Corp";"VERMONT";"50";"33";"NEW HAMPSHIRE"
				-- "Nebraska Electric G&T Coop Inc";"NEBRASKA";"31";"19";"IOWA"
				-- ** "Northern States Power Co - Minnesota";"MINNESOTA";"27";"38";"NORTH DAKOTA"
				-- ** "Northern States Power Co - Minnesota";"MINNESOTA";"27";"46";"SOUTH DAKOTA"
				-- "Nebraska Electric G&T Coop Inc";"NEBRASKA";"31";"20";"KANSAS"
				-- ** "City of Owensboro, Kentucky (Utility Company)";"KENTUCKY";"21";"18";"INDIANA"
				-- "Central Vermont Pub Serv Corp";"VERMONT";"50";"36";"NEW YORK"
				-- "Kansas City Power & Light Co";"KANSAS";"20";"29";"MISSOURI"
				-- ** "City of Columbus, Mississippi (Utility Company)";"MISSISSIPPI";"28";"39";"OHIO"

			-- In total, out of the 32 above, there are 11 that we need to investigate further:
				-- √ "City of Siloam Springs, Arkansas (Utility Company)";"ARKANSAS";"05";"40";"OKLAHOMA"
					-- city on the state line and looks like its MPA crosses to OK
				-- √ "City of Chattanooga, Georgia (Utility Company)";"GEORGIA";"13";"47";"TENNESSEE"
					-- this one check out. Chattanooga MPA is in TN and GA
				-- √ "City of Owensboro, Kentucky (Utility Company)";"KENTUCKY";"21";"18";"INDIANA"
					-- this is also on the stateline
				-- √ "City of Jellico, Tennessee (Utility Company)";"TENNESSEE";"47";"21";"KENTUCKY"
					-- this is also on the stateline
				-- √ "Northern States Power Co - Minnesota";"MINNESOTA";"27";"38";"NORTH DAKOTA"
					-- this check out: http://image.slidesharecdn.com/1155190/95/xel0605print-5-728.jpg?cb=1237250345
				-- √ "Northern States Power Co - Minnesota";"MINNESOTA";"27";"46";"SOUTH DAKOTA"
					-- this checks out: http://image.slidesharecdn.com/1155190/95/xel0605print-5-728.jpg?cb=1237250345
				-- √ "Northern States Power Co - Wisconsin";"WISCONSIN";"55";"26";"MICHIGAN"
					-- checks out: http://image.slidesharecdn.com/1155190/95/xel0605print-5-728.jpg?cb=1237250345
				-- ** "City of Rockport, Missouri (Utility Company)";"MISSOURI";"29";"31";"NEBRASKA"
					-- this one is close to the stateline


			-- These are SUPER Suspect And I do Not know what to do about them; 
				-- ** "City of Columbus, Mississippi (Utility Company)";"MISSISSIPPI";"28";"21";"KENTUCKY"
				-- ** "City of Columbus, Mississippi (Utility Company)";"MISSISSIPPI";"28";"54";"WEST VIRGINIA"
				-- ** "City of Columbus, Mississippi (Utility Company)";"MISSISSIPPI";"28";"39";"OHIO"


--------------------------------------------------------
-- 2. Make County Geoms Table
--------------------------------------------------------
	-- Do this once we are confident that all utility rates are assigned to its corresponding county
	drop table if exists urdb_rates.utility_county_geoms_20161005;
	create table urdb_rates.utility_county_geoms_20161005 as (
	select b.rate_id_alias, b.eia_id, a.state_fips, a.county_fips, a.county, a.state, a.state_abbr,  a.geoid10, a.the_geom_96703_5m as the_geom_96703
	from diffusion_blocks.county_geoms a
	inner join urdb_rates.urdb_utility_eia_and_county_ids_lkup_20161005 b
	on a.state_fips = b.state_fips and a.county_fips = b.cnty_fips);

	-- Add Gist
	create index utility_county_geoms_20161005_gist on urdb_rates.utility_county_geoms_20161005 using gist(the_geom_96703);

	-- Check #s
	select count( distinct (rate_id_alias) ) from urdb_rates.utility_county_geoms_20161005;
		--5405 (good to go)

--------------------------------------------------------
-- 3. Tag Utility Type to the sam data table of rates
--------------------------------------------------------
	alter table urdb_rates.urdb3_verified_rates_sam_data_20161005
	add column utility_type text;

	alter table urdb_rates.urdb3_verified_rates_sam_data_20161005
	owner to 'urdb_rates-writers';

	with matched_to_utype as (
		with utility_type as (
			select utility_id, (case when ownership in ('Municipal', 'Cooperative', 'Investor Owned')
			 then ownership else 'Other' end)::TEXT as utility_type
			from eia.eia_861_file_1_2011),
		distinct_eia_id as (select distinct eia_id from urdb_rates.urdb3_verified_rates_sam_data_20161005)
		select a.*, b.utility_type
		from distinct_eia_id a
		left join utility_type b
		on a.eia_id = cast(b.utility_id as text)
	--where utility_type is null
	)
	update urdb_rates.urdb3_verified_rates_sam_data_20161005 as a
		set utility_type = (select b.utility_type from matched_to_utype b where a.eia_id = b.eia_id limit 1)

		-- QAQC -- check null utility types:
			-- select * from urdb_rates.urdb3_verified_rates_sam_data_20161005 where utility_type is null
				-- Null utility types = 4062, 5553, 'No eia_id_given'
				-- "Columbus Southern Power Co" (4062)
					-- IOU https://en.wikipedia.org/wiki/American_Electric_Power
				-- √ "Egegik Light & Power Co" (5553) 
					-- select * from ventyx.electric_service_territories_20150701 where company_na = 'Egegik (City of)'
					-- type = municipal
				-- √ "Old Dominion Power Co" (no eia id given)
					-- select * from ventyx.electric_service_territories_20150701 where planning_a = 'Old Dominion Electric Coop Inc'
					-- type = "DistCoop"
			update urdb_rates.urdb3_verified_rates_sam_data_20161005
				set utility_type = case when eia_id = '4062' then 'Investor Owned'
					when eia_id = '5553' then 'Municipal'
					when eia_id = 'No eia id given' then 'Cooperative'
					else utility_type end;
