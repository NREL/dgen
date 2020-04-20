----------------------------------------------------------------------------------------------------
-- load service territory lookup table (utility to county)
-- acquired from EIA 2012 detailed data archive 
SET ROLE 'eia-writers';
DROP TABLE IF EXISTS eia.utility_to_county_lkup_2012;
CREATE TABLE eia.utility_to_county_lkup_2012
(
       data_year integer,
       eia_utility_id integer,
       utility_name text,
       state_abbr character varying(2),
       county text
);

set role 'server-superusers';
COPY eia.utility_to_county_lkup_2012
FROM '/home/mgleason/data/dg_wind/eia_service_territory_2012.csv'
with csv header;
set role 'eia-writers';

-- add state and county fips codes
ALTER TABLE eia.utility_to_county_lkup_2012
ADD column state_fips character varying(2),
ADD column county_fips character varying(3);

-- fix one county name for consistency with esri names
UPDATE eia.utility_to_county_lkup_2012 a
set county = 'Prince of Wales-Outer Ketchikan'
where county = 'Prince of Wales Ketchikan';

-- set state and county fips using regex to deal with weird naming conventions
UPDATE eia.utility_to_county_lkup_2012 a
set (state_fips, county_fips) = (lpad(b.state_fips::text,2,'0'), b.county_fips)
FROM diffusion_shared.county_geom b
where replace(regexp_replace(lower(a.county), '[.'' -]+', '', 'g'),'city','') = replace(regexp_replace(lower(b.county), '[.'' -]+', '', 'g'),'city','')
and a.state_abbr = b.state_abbr;

-- check for nulls
select *
FROM eia.utility_to_county_lkup_2012
where county_fips is null
and state_abbr not in ('AS','VI','PR','GU')
order by state_abbr, county;
-- 0 rows

----------------------------------------------------------------------------------------------------


----------------------------------------------------------------------------------------------------
-- load the utility annual average rate data
-- RESIDENTIAL
set role 'eia-writers';
DROP TABLE IF EXISTS eia.t6_sales_residential;
CREATE TABLE eia.t6_sales_residential
(
	utility_name text, 
	state_abbr character varying(2),
	utility_type text,
	customers_count TEXT, -- should be integer
	sales_mw TEXT, --should be integer
	revenue_kdlrs TEXT, -- should be numeric
	avg_price_cents_per_kwh numeric
);

set role 'server-superusers';
COPY eia.t6_sales_residential
FROM '/home/mgleason/data/dg_wind/table6_res.csv'
with csv header;
set role 'eia-writers';

-- add primary key on utility name and state abbr
ALTER TABLE eia.t6_sales_residential
ADD PRIMARY KEY (utility_name, state_abbr);

-- cast text fields to numeric
ALTER TABLE eia.t6_sales_residential
ALTER COLUMN customers_count TYPE integer
using replace(customers_count,',','')::integer;

ALTER TABLE eia.t6_sales_residential
ALTER COLUMN sales_mw TYPE integer
using replace(sales_mw,',','')::integer;

ALTER TABLE eia.t6_sales_residential
ALTER COLUMN revenue_kdlrs TYPE numeric
using replace(revenue_kdlrs,',','')::numeric;

-- add metadata info
COMMENT ON TABLE eia.t6_sales_residential IS 
'2012 Consumer, Sales, Revenue, and Average Retail Price Data from EIA. 
Source: http://www.eia.gov/electricity/sales_revenue_price/. 
Acquired and loaded: 1/2/2015';

-- COMMERCIAL
set role 'eia-writers';
DROP TABLE IF EXISTS eia.t7_sales_commercial;
CREATE TABLE eia.t7_sales_commercial
(
	utility_name text,
	state_abbr character varying(2),
	utility_type text,
	customers_count TEXT, -- should be integer
	sales_mw TEXT, --should be integer
	revenue_kdlrs TEXT, -- should be numeric
	avg_price_cents_per_kwh numeric
);

set role 'server-superusers';
COPY eia.t7_sales_commercial
FROM '/home/mgleason/data/dg_wind/table7_com.csv'
with csv header;
set role 'eia-writers';

-- cast text fields to numeric
ALTER TABLE eia.t7_sales_commercial
ALTER COLUMN customers_count TYPE integer
using replace(customers_count,',','')::integer;

ALTER TABLE eia.t7_sales_commercial
ALTER COLUMN sales_mw TYPE integer
using replace(sales_mw,',','')::integer;

ALTER TABLE eia.t7_sales_commercial
ALTER COLUMN revenue_kdlrs TYPE numeric
using replace(revenue_kdlrs,',','')::numeric;

-- add metadata info
COMMENT ON TABLE eia.t7_sales_commercial IS 
'2012 Consumer, Sales, Revenue, and Average Retail Price Data from EIA. 
Source: http://www.eia.gov/electricity/sales_revenue_price/. 
Acquired and loaded: 1/2/2015';

-- INDUSTRIAL
set role 'eia-writers';
DROP TABLE IF EXISTS eia.t8_sales_industrial;
CREATE TABLE eia.t8_sales_industrial
(
	utility_name text,
	state_abbr character varying(2),
	utility_type text,
	customers_count TEXT, -- should be integer
	sales_mw TEXT, --should be integer
	revenue_kdlrs TEXT, -- should be numeric
	avg_price_cents_per_kwh numeric
);

set role 'server-superusers';
COPY eia.t8_sales_industrial
FROM '/home/mgleason/data/dg_wind/table8_ind.csv'
with csv header;
set role 'eia-writers';

-- cast text fields to numeric
ALTER TABLE eia.t8_sales_industrial
ALTER COLUMN customers_count TYPE integer
using replace(customers_count,',','')::integer;

ALTER TABLE eia.t8_sales_industrial
ALTER COLUMN sales_mw TYPE integer
using replace(sales_mw,',','')::integer;

ALTER TABLE eia.t8_sales_industrial
ALTER COLUMN revenue_kdlrs TYPE numeric
using replace(revenue_kdlrs,',','')::numeric;

-- add metadata info
COMMENT ON TABLE eia.t8_sales_industrial IS 
'2012 Consumer, Sales, Revenue, and Average Retail Price Data from EIA. 
Source: http://www.eia.gov/electricity/sales_revenue_price/. 
Acquired and loaded: 1/2/2015';

----------------------------------------------------------------------------------------------------
-- merge data

-- first determine what the unique identifiers are in each table 
-- should be utility_name and state_abbr
select utility_name, state_abbr, count(*)
FROM eia.t6_sales_residential
group by utility_name, state_abbr
order by count desc;

select utility_name, state_abbr, count(*)
FROM eia.t7_sales_commercial
group by utility_name, state_abbr
order by count desc;

select utility_name, state_abbr, count(*)
FROM eia.t8_sales_industrial
group by utility_name, state_abbr
order by count desc;

-- there is only one utility/state_abbr that has two duplicates:
-- Tri-County Electric Coop, Inc, TX
-- so it is safe to assume that utility/state_abbr is the unique identifier

-- create table with annual rates by utility
set role 'diffusion-writers';
DROP TABLE if exists diffusion_shared_data.ann_ave_elec_rates_by_utility_2012;
CREATE TABLE diffusion_shared_data.ann_ave_elec_rates_by_utility_2012 AS
with a as
(
	-- find all unique utility/state combos
	SELECT utility_name, state_abbr
	FROM eia.t6_sales_residential
	GROUP BY utility_name, state_abbr
	UNION
	SELECT utility_name, state_abbr
	FROM eia.t7_sales_commercial
	GROUP BY utility_name, state_abbr
	UNION
	SELECT utility_name, state_abbr
	FROM eia.t8_sales_industrial
	GROUP BY utility_name, state_abbr
)
select a.utility_name, a.state_abbr,
	round(avg(b.avg_price_cents_per_kwh),2) as res_rate_cents_per_kwh,
	round(avg(c.avg_price_cents_per_kwh),2) as com_rate_cents_per_kwh,
	round(avg(d.avg_price_cents_per_kwh),2) as ind_rate_cents_per_kwh
	
FROM a
LEFT JOIN eia.t6_sales_residential b
ON a.utility_name = b.utility_name
and a.state_abbr = b.state_abbr
LEFT JOIN eia.t7_sales_commercial c
ON a.utility_name = c.utility_name
and a.state_abbr = c.state_abbr
LEFT JOIN eia.t8_sales_industrial d
ON a.utility_name = d.utility_name
and a.state_abbr = d.state_abbr
group by a.utility_name, a.state_abbr; -- have to groupby and avg to deal with duplicates for Tri County Electric Coop, Tx
-- should produce 2069 rows (same as the count of rows in the subquery a)

-- primary key
ALTER TABLE diffusion_shared_data.ann_ave_elec_rates_by_utility_2012
ADD PRIMARY KEY (utility_name, state_abbr);


----------------------------------------------------------------------------------------------------
-- load annual average rates by state (needed for backfilling)
set role 'eia-writers';
DROP TABLE IF EXISTS eia.ann_avg_elec_price_by_state_by_provider_1990_to_2012;
CREATE TABLE eia.ann_avg_elec_price_by_state_by_provider_1990_to_2012
(
	Year integer,
	state_abbr character varying(2),
	provider text,
	res_rate_cents_per_kwh numeric,	
	com_rate_cents_per_kwh numeric,
	ind_rate_cents_per_kwh numeric,
	trans_rate_cents_per_kwh numeric,
	other_rate_cents_per_kwh numeric,
	total_rate_cents_per_kwh numeric
);

set role 'server-superusers';
COPY eia.ann_avg_elec_price_by_state_by_provider_1990_to_2012
FROM '/home/mgleason/data/dg_wind/avgprice_annual.csv'
with csv header;
set role 'eia-writers';

-- add metadata info
COMMENT ON TABLE eia.ann_avg_elec_price_by_state_by_provider_1990_to_2012 IS 
'Average Price by State by Provider (EIA-861) from 1990 through 2012. 
Source: http://www.eia.gov/electricity/data/state/. 
Acquired and loaded: 1/2/2015';
----------------------------------------------------------------------------------------------------

-- extract the overall state avg rates for 2012
set role 'diffusion-writers';
DROP TABLE if exists diffusion_shared_data.ann_ave_elec_rates_by_state_2012;
CREATE TABLE diffusion_shared_data.ann_ave_elec_rates_by_state_2012 AS
SELECT state_abbr, res_rate_cents_per_kwh, com_rate_cents_per_kwh, ind_rate_cents_per_kwh
FROM  eia.ann_avg_elec_price_by_state_by_provider_1990_to_2012
where year = 2012
and provider = 'Total Electric Industry'
and state_abbr <> 'US';

-- add primary key on state_abbr
ALTER TABLE diffusion_shared_data.ann_ave_elec_rates_by_state_2012
ADD PRIMARY KEY (state_abbr);
----------------------------------------------------------------------------------------------------


-- combine utility level and state level data to create county level rate data

-- link all the utility level data to counties, where possible
set role 'diffusion-writers';
DROP TABLE IF EXISTS diffusion_shared.ann_ave_elec_rates_by_county_2012;
CREATE TABLE diffusion_shared.ann_ave_elec_rates_by_county_2012 AS
with b AS
(
	SELECT b.state_fips, b.county_fips, 
		round(avg(a.res_rate_cents_per_kwh),2) as res_rate_cents_per_kwh,
		round(avg(a.com_rate_cents_per_kwh),2) as com_rate_cents_per_kwh,
		round(avg(a.ind_rate_cents_per_kwh),2) as ind_rate_cents_per_kwh
	FROM  diffusion_shared_data.ann_ave_elec_rates_by_utility_2012 a
	INNER JOIN eia.utility_to_county_lkup_2012 b -- this will drop utilities that can't be found in the lkup table
	ON a.utility_name = b.utility_name
	and a.state_abbr = b.state_abbr
	where a.utility_name <> 'Block Island Power Co' -- ignore this or else it will skew washington county ri rates
							 -- (block island has pop of ~1000 and very high rates, washington county has total pop of 125,000 and normal rates
							 -- better to skew block island down than all of the county up
	GROUP BY b.state_fips, b.county_fips
	order by state_fips, county_fips
	-- 3109 out of 3141 counties have data at the utility level
)
SELECT a.county_id, a.state_fips, a.county_fips, a.state_abbr,
	COALESCE(b.res_rate_cents_per_kwh,c.res_rate_cents_per_kwh) as res_rate_cents_per_kwh, -- this backfills w state level data where utility level is null
	COALESCE(b.com_rate_cents_per_kwh,c.com_rate_cents_per_kwh) as com_rate_cents_per_kwh, -- this backfills w state level data where utility level is null
	COALESCE(b.ind_rate_cents_per_kwh,c.ind_rate_cents_per_kwh) as ind_rate_cents_per_kwh, -- this backfills w state level data where utility level is null
	cASE WHEN b.res_rate_cents_per_kwh is not null then 'Utility'
	else 'State Average'
	END as res_rate_source,
	cASE WHEN b.com_rate_cents_per_kwh is not null then 'Utility'
	else 'State Average'
	END as com_rate_source,
	cASE WHEN b.ind_rate_cents_per_kwh is not null then 'Utility'
	else 'State Average'
	END as ind_rate_source
FROM diffusion_shared.county_geom a
LEFT JOIN b
ON a.state_fips = b.state_fips::integer
and a.county_fips = b.county_fips
LEFT JOIN diffusion_shared_data.ann_ave_elec_rates_by_state_2012 c
on a.state_abbr = c.state_abbr;

-- add a primary key
ALTER TABLE diffusion_shared.ann_ave_elec_rates_by_county_2012
ADD PRIMARY KEY (county_id);

-- check for nulls
SELECT count(*)
FROM diffusion_shared.ann_ave_elec_rates_by_county_2012
where res_rate_cents_per_kwh is null
or com_rate_cents_per_kwh is null
or ind_rate_cents_per_kwh is null;

-- how many are state_level data?
SELECT count(*)
FROM diffusion_shared.ann_ave_elec_rates_by_county_2012
where res_rate_source = 'State Average';
-- 32
SELECT count(*)
FROM diffusion_shared.ann_ave_elec_rates_by_county_2012
where com_rate_source = 'State Average';
-- 32
SELECT count(*)
FROM diffusion_shared.ann_ave_elec_rates_by_county_2012
where ind_rate_source = 'State Average';
-- 65

-- check for weird values
SELECT max(res_rate_cents_per_kwh),
       max(com_rate_cents_per_kwh),
       max(ind_rate_cents_per_kwh),
       min(res_rate_cents_per_kwh),
       min(com_rate_cents_per_kwh),
       min(ind_rate_cents_per_kwh)
FROM diffusion_shared.ann_ave_elec_rates_by_county_2012;
-- mins are all above 2c/kwh, so they are probably ok
-- but some very high maxes

select *
FROM diffusion_shared.ann_ave_elec_rates_by_county_2012
where res_rate_cents_per_kwh > 35; -- 10 counties all in AK or HI -- probably accurate

select *
FROM diffusion_shared.ann_ave_elec_rates_by_county_2012
where com_rate_cents_per_kwh > 35; -- 8 counties, all in AK or HI -- probably accurate

select *
FROM diffusion_shared.ann_ave_elec_rates_by_county_2012
where ind_rate_cents_per_kwh > 35; -- 5 counties, all in AK or HI -- probably accurate