-- Run some checks before dissaggregating

--  The utilmate goal is to Develop tracts to utility + utility type probabilities
	-- Disagregate known utility customer counts to tracts
		-- County to utility (not utility type) weighting schemes
		-- based on number customers/ bldg count and known population

	-- Known utility customer counts:
		-- from Galen's county to eia_id mapping table (eia.eia_861_2013_county_utility_rates)
		-- first check to make sure that all eia_ids are accounted for
--------------------------------------------------------------------------------------------------------------------------------------

-----------------------------------------------------
-- Check to make sure all eia_ids are accounted for:
-----------------------------------------------------
	with b as (select distinct eia_id from diffusion_data_shared.urdb_rates_attrs_lkup_20170103)
	select a.utility_num, b.eia_id 
	from eia.eia_861_2013_county_utility_rates a
	right join b
	on cast(a.utility_num as text) = b.eia_id
	order by a.utility_num desc

	-- 13 eia_ids not accounted for in eia.eia_861_2013_county_utility_rates
		-- "19174"
		-- "2268"
		-- "40300"
		-- "4062"
		-- "5553"
		-- "9026"
		-- "5729"
		-- "11235"
		-- "No eia id given"
		-- "14272"
		-- "3292"
		-- "26751"
		-- "25251"

		-- how many rates are affected by this?
			select * from diffusion_data_shared.urdb_rates_attrs_lkup_20170103 where eia_id in ('19174','2268','40300','4062','5553','9026','5729','11235','No eia id given','14272','3292','26751','25251')
			-- between the 13 missing records, there are 115 rates
	
-- Check to make sure that all utility ids have a customer count
	select distinct (utility_num) from eia.eia_861_2013_county_utility_rates 
	where res_customers is null and comm_customers is null and ind_customers is null
	-- 1145 records are null/ have no customer counts
		
-- Check to see if any of our eia_ids fall within these null customer cnts
			with b as (
				select distinct eia_id 
				from diffusion_data_shared.urdb_rates_attrs_lkup_20170103),
			a as (
				select distinct (utility_num) 
				from eia.eia_861_2013_county_utility_rates 
				where res_customers is null and comm_customers is null and ind_customers is null)
			select a.utility_num, b.eia_id 
			from a
			right join b
			on cast(a.utility_num as text) = b.eia_id
			where eia_id not in ('19174','2268','40300','4062','5553','9026','5729','11235','No eia id given','14272','3292','26751','25251')
			and utility_num is null
			order by a.utility_num desc
		-- 804 utilities do not have customer counts

	-- how many of our utilities DO HAVE customer counts?
		--1123 - 804 = * only 306 (out of 1123 utilities) have customer counts (from 2013 data)


---------------------------------------------------------
-- ALL Eia ids not accounted for; Check with 2014 data
--------------------------------------------------------
-- Try to upload 2014 cust cnt data and perform the join to see how many utilies match up and how many do not have counts
-- Check 2014 utility data:
drop table if exists eia.eia_861_2014_util_sales_cust;
create table eia.eia_861_2014_util_sales_cust (
	data_year	int,
	utility_number	int,
	utility_name	text,
	part	text,
	service_type	text,
	data_type	text,
	state	text,
	ownership	text,
	ba_code	text,
	res_revenues_thousands_dlrs	text,
	res_sales_mwh	text,
	res_customers	text,
	com_revenues_thousands_dlrs	text,
	com_sales_mwh	text,
	com_customers	text,
	ind_revenues_thousands_dlrs	text,
	ind_sales_mwh	text,
	ind_customers	text,
	trans_revenues_thousands_dlrs	text,
	trans_sales_mwh	text,
	trans_customers	text,
	total_revenues_thousands_dlrs	text,
	total_sales_mwh	text,
	total_customers text
);

\COPY eia.eia_861_2014_util_sales_cust from '/Users/mmooney/Dropbox (NREL GIS Team)/Projects/2016_10_03_dStorage/data/source/eia/eia_Sales_Ult_Cust_2014.csv' with csv header;

-- Perform updates
update eia.eia_861_2014_util_sales_cust
	set res_customers = null where res_customers = '.';
update eia.eia_861_2014_util_sales_cust
	set res_customers = replace (res_customers, ',', ''),
	ind_customers = replace(ind_customers, ',', ''),
	com_customers = replace(com_customers, ',', '');
update eia.eia_861_2014_util_sales_cust
	set res_customers = case when res_customers is null then 0 else res_customers end,
		ind_customers = case when ind_customers is null then 0 else ind_customers end,
		com_customers = case when com_customers is null then 0 else com_customers end;

-- Make sure all eia_ids are accounted for
	with b as (select distinct eia_id from diffusion_data_shared.urdb_rates_attrs_lkup_20170103)
	select a.utility_number, b.eia_id 
	from eia.eia_861_2014_util_sales_cust a
	right join b
	on cast(a.utility_number as text) = b.eia_id
	order by a.utility_number desc
	-- 310 utilities do not have matches

-- Of the utilities NOT missing matches, how many have customer counts?
	with distinct_eia_id as (
		select distinct eia_id 
		from diffusion_data_shared.urdb_rates_attrs_lkup_20170103),
	joins as (
		select a.utility_number, b.eia_id, cast(a.res_customers as int), cast(a.com_customers as int), cast(a.ind_customers as int)
		from eia.eia_861_2014_util_sales_cust a
		right join distinct_eia_id b
		on cast(a.utility_number as text) = b.eia_id
	order by a.utility_number desc)
	select * from a
	where (res_customers is null or res_customers = 0)
	and (com_customers is null or com_customers = 0)
	and (ind_customers is null or ind_customers = 0)
	--and utility_number is null
		-- 312 total missing matches
		-- only 2 utilies with matches have NO customer count data ("40437", and "27000")
		-- OF the utilities NOT missing matches, All except 2 have customer counts


	-- 312 distinct utility ids is better tha 810, but lets see if we can use both to refine the results and lower the number...

---------------------------------------------------------
-- Try Use 2014 and 2013 Combo
---------------------------------------------------------
-- Merge both the old table with the new 2014 table to see if we can lower the 310 number
	with distinct_eia_id as (
		select distinct eia_id, state_abbr 
		from diffusion_data_shared.urdb_rates_attrs_lkup_20170103
		),
	joins as (
		select a.utility_number, b.eia_id, cast(a.res_customers as int), cast(a.com_customers as int), cast(a.ind_customers as int)
		from eia.eia_861_2014_util_sales_cust a
		right join distinct_eia_id b
		on cast(a.utility_number as text) = b.eia_id --and a.state = b.state_abbr
		order by a.utility_number desc
		),
	number_of_sectors as (
		select *, 
		(case when (res_customers is null or res_customers = 0) then 0 else 1 end) as cnt_res,
		(case when (ind_customers is null or ind_customers = 0) then 0 else 1 end) as cnt_ind,
		(case when (com_customers is null or com_customers = 0) then 0 else 1 end) as cnt_com
		from joins)
	select distinct * from number_of_sectors where cnt_res = 0 and cnt_ind= 0 and cnt_com = 0
	--312 rows returned

-- Merge both the old table with the new 2014 table to see if we can lower the 310 number
	with distinct_eia_id as (
		select distinct eia_id, state_abbr 
		from diffusion_data_shared.urdb_rates_attrs_lkup_20170103
		),
	joins as (
		select a.utility_number, b.eia_id, cast(a.res_customers as int), cast(a.com_customers as int), cast(a.ind_customers as int)
		from eia.eia_861_2014_util_sales_cust a
		right join distinct_eia_id b
		on cast(a.utility_number as text) = b.eia_id --and a.state = b.state_abbr
		order by a.utility_number desc
		),
	number_of_sectors as (
		select *, 
		(case when (res_customers is null or res_customers = 0) then 0 else 1 end) as cnt_res,
		(case when (ind_customers is null or ind_customers = 0) then 0 else 1 end) as cnt_ind,
		(case when (com_customers is null or com_customers = 0) then 0 else 1 end) as cnt_com
		from joins),
	missing_eia_id as (
		select distinct * from number_of_sectors where cnt_res = 0 and cnt_ind= 0 and cnt_com = 0) --312 missing
	-- join the missing ones to the 2013 data
	select distinct a.eia_id, b.utility_num
	from missing_eia_id a
	left join eia.eia_861_2013_county_utility_rates b
	on cast(b.utility_num as text) = a.eia_id
	where b.res_customers is null and b.comm_customers is null and b.ind_customers is null
	order by utility_num desc
	-- Results:
		-- We brought the number down from 312 to 308 by joining the two tables (2013 & 2014)
		-- Not a big gain by combining the two, but a gain none the less
		-- because these numbers are slightly different in the 2013
			-- (they are for the ENTIRE utility across state lines), 
			-- AND because it isn't a big gain, we aren't going to include them

-- 312 utilities do not have matches