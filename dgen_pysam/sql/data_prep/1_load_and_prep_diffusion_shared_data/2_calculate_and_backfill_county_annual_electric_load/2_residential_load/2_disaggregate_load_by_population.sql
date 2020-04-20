--------------------------------------------------------------------------------------------------------------------
-- us
--------------------------------------------------------------------------------------------------------------------

-- sum the total population in each electric service territory
-- create output table
DROP TABLE IF EXISTS dg_wind.ventyx_res_hu_sums_us CASCADE;
CREATE TABLE dg_wind.ventyx_res_hu_sums_us
(
	gid integer,
	hu_sum numeric
);

-- use dg_wind.ventyx_ests_backfilled_geoms_clipped
-- run parsel

-- if its still too slow, need to try to split up on something other than gid

select parsel_2('dav-gis','mgleason','mgleason','dg_wind.ventyx_backfilled_ests_diced','state_id',
		'select a.est_gid as gid, 
			sum(hu_portion) as hu_sum
		FROM dg_wind.ventyx_backfilled_ests_diced as a
		INNER JOIN diffusion_shared.pt_grid_us_res_new b
		ON ST_Intersects(a.the_geom_4326,b.the_geom_4326)
		GROUP BY a.est_gid;',
		'dg_wind.ventyx_res_hu_sums_us',
		'a',16);

-- check for service territories that do not have any points
DROP TABLE IF EXISTS dg_wind.ests_w_no_residential;
CREATE TABLE dg_wind.ests_w_no_residential AS
SELECT a.gid, a.state_abbr,
	a.the_geom_4326, 
	a.total_residential_sales_mwh, 
	a.total_residential_customers, 
	c.hu_sum
FROM dg_wind.ventyx_elec_serv_territories_w_2011_sales_data_backfilled_clip a
left join dg_wind.ventyx_res_hu_sums_us c
ON a.gid = c.gid
where (c.hu_sum is null or c.hu_sum = 0)
and a.state_abbr not in ('AK','HI')
and (a.total_residential_sales_mwh > 0 or a.total_residential_customers > 0);
-- 25 total
-- review in Q
-- these are all just slivers or small territories with no ind land
-- in these cases, just spread the data around evenly between intersecting counties

-- how much load is in these areas?
SELECT *
FROM dg_wind.ests_w_no_residential;

-- intersect with counties

-- disaggregate the load to pts
ALTER TABLE dg_wind.disaggregated_load_residential_us
RENAME TO disaggregated_load_residential_us_archive;

DROP TABLE IF EXISTS dg_wind.disaggregated_load_residential_us;
CREATE TABLE dg_wind.disaggregated_load_residential_us
(
	pt_gid integer,
	county_id integer,
	est_gid integer,
	residential_sales_mwh numeric,
	residential_customers numeric
);

select parsel_2('dav-gis','mgleason','mgleason',
		'diffusion_shared.pt_grid_us_res_new','gid',
		'select a.gid as pt_gid, a.county_id,
			b.est_gid as est_gid,
			(hu_portion/d.hu_sum) * c.total_residential_sales_mwh as residential_sales_mwh,
			(hu_portion/d.hu_sum) * c.total_residential_customers as residential_customers
		FROM diffusion_shared.pt_grid_us_res_new a
		INNER JOIN dg_wind.ventyx_backfilled_ests_diced b
			ON ST_Intersects(a.the_geom_4326, b.the_geom_4326)
		LEFT JOIN dg_wind.ventyx_elec_serv_territories_w_2011_sales_data_backfilled_clip c
			ON b.est_gid = c.gid
		LEFT JOIN dg_wind.ventyx_res_hu_sums_us d
			on b.est_gid = d.gid',
			'dg_wind.disaggregated_load_residential_us',
			'a',16);

-- add index on the county id column
CREATE INDEX disaggregated_load_residential_us_county_id_btree
ON  dg_wind.disaggregated_load_residential_us
USING btree(county_id);

-- aggregate the results to counties
DROP TABLE IF EXISTS dg_wind.res_load_by_county_us_incomplete;
CREATE TABLE dg_wind.res_load_by_county_us_incomplete
(
	county_id integer,
	total_load_mwh_2011_residential numeric,
	total_customers_2011_residential numeric
);

select parsel_2('dav-gis','mgleason','mgleason',
		'dg_wind.disaggregated_load_residential_us','county_id',
		'select a.county_id,
			sum(residential_sales_mwh) as total_load_mwh_2011_residential,
			sum(residential_customers) as total_customers_2011_residential
		FROM dg_wind.disaggregated_load_residential_us a
		GROUP BY a.county_id',
			'dg_wind.res_load_by_county_us_incomplete',
			'a',16);

-- need to add in the portions of Ventyx territories with no residential pts
-- add indices
CREATE INDEX ests_w_no_residential_the_geom_4326_gist
ON  dg_wind.ests_w_no_residential
using gist(the_geom_4326);

CREATE INDEX ests_w_no_residential_state_abbr_btree
ON  dg_wind.ests_w_no_residential
using btree(state_abbr);

DROP TABLE IF EXISTS dg_wind.ests_w_no_residential_disaggregated;
CREATE TABLE dg_wind.ests_w_no_residential_disaggregated AS
with a as
(
	select a.gid as est_gid,
		b.county_id,
		a.total_residential_sales_mwh, 
		a.total_residential_customers,
		ST_Area(ST_Transform(ST_Intersection(a.the_geom_4326, b.the_geom_4326),96703))/ST_Area(ST_Transform(a.the_geom_4326, 96703)) as ratio
	FROM dg_wind.ests_w_no_residential a
	INNER JOIN diffusion_shared.county_geom b
	ON ST_Intersects(a.the_geom_4326, b.the_geom_4326)
	and a.state_abbr = b.state_abbr
)
select a.est_gid,
	county_id,
	total_residential_sales_mwh * ratio as total_load_mwh_2011_residential,
	total_residential_customers * ratio as total_customers_2011_residential
from a;

-- combine with the data from points to form the final county load table
ALTER TABLE dg_wind.res_load_by_county_us 
RENAME TO res_load_by_county_us_archive;

DROP TABLE IF EXISTS dg_wind.res_load_by_county_us;
CREATE TABLE dg_wind.res_load_by_county_us AS
with a as
(
	SELECT county_id, total_load_mwh_2011_residential, total_customers_2011_residential
	FROM dg_wind.res_load_by_county_us_incomplete 
	UNION ALL
	SELECT county_id, total_load_mwh_2011_residential, total_customers_2011_residential
	FROM dg_wind.ests_w_no_residential_disaggregated
)
SELECT county_id, 
	sum(total_load_mwh_2011_residential) as total_load_mwh_2011_residential, 
	sum(total_customers_2011_residential) as total_customers_2011_residential
FROM a
group by county_id;
-- 3108 rows

-- add a primary key on county_id
ALTER TABLE dg_wind.res_load_by_county_us
ADD PRIMARY KEY (county_id);

---------------------------------------------------------------------------------------------------
-- PERFORM SOME VERIFICATION OF THE RESULTS

-- how many rows were returned?
select count(*)
FROM dg_wind.res_load_by_county_us; --3108

-- how many are there total?
select count(*)
FROM diffusion_shared.county_geom
where state_abbr not in ('AK','HI'); -- 3109

-- what is missing
SELECT a.*
FROM diffusion_shared.county_geom a
LEFT JOIN dg_wind.res_load_by_county_us b
on a.county_id = b.county_id
where b.county_id is null
and a.state_abbr not in ('AK', 'HI'); -- just grand isle vermont
-- only missing county is a small island in lake champlain (VT) -- this doesnt seem too unreasonable

-- add this county in with a value of zero for load and customers
INSERT INTO dg_wind.res_load_by_county_us
 (county_id, total_load_mwh_2011_residential, total_customers_2011_residential)  VALUES (2988, 0, 0);


-- check load values
SELECT sum(total_load_mwh_2011_residential)
FROM dg_wind.res_load_by_county_us; -- 1,417,737,535.26282

select sum(total_residential_sales_mwh)
FROM dg_wind.ventyx_elec_serv_territories_w_2011_sales_data_backfilled_clip
where state_abbr not in ('AK','HI'); -- 1,417,737,928

select 1417737928 - 1417737535.26282; -- 392.73718 (difference possibly/likely(?) due to rounding)
select (1417737928 - 1417737535.26282)/1417737928  * 100; --0.000027701676892712713000 % load is missing nationally

-- cehck on state level
with a as 
(
	select state_abbr, sum(total_residential_sales_mwh)
	FROM dg_wind.ventyx_elec_serv_territories_w_2011_sales_data_backfilled_clip
	where state_abbr not in ('AK','HI')
	GROUP BY state_abbr
),
b as 
(
	SELECT k.state_abbr, sum(total_load_mwh_2011_residential)
	FROM dg_wind.res_load_by_county_us j
	LEFT join diffusion_shared.county_geom k
	ON j.county_id = k.county_id
	GROUP BY k.state_abbr
)
SELECT a.state_abbr, a.sum as est_total, b.sum as county_total, b.sum-a.sum as diff, (b.sum-a.sum)/a.sum * 100 as perc_diff
FROM a
LEFT JOIN b
on a.state_abbr = b.state_abbr
order by perc_diff; --
-- looks good -- these differcnces are probably due to incongruencies between county_geoms and the ventyx state boundaries

-- any counties w/out ind load (other than Grand Isle)
select *
FROM dg_wind.res_load_by_county_us_archive
where total_load_mwh_2011_residential = 0; -- 1 - nope
-- reviewed in Q

-- check values for customers
SELECT sum(total_customers_2011_residential)
FROM dg_wind.res_load_by_county_us; -- 125451654.679706

select sum(total_residential_customers)
FROM dg_wind.ventyx_elec_serv_territories_w_2011_sales_data_backfilled_clip
where state_abbr not in ('AK','HI'); -- 125451686

select 125451686 - 125451654.679706; -- 31.320294 (difference likely due to rounding)
select (125451686 - 125451654.679706)/125451686  * 100; -- 0.000024966020783491104300 % load is missing nationally

-- cehck on state level
with a as 
(
	select state_abbr, sum(total_residential_customers)
	FROM dg_wind.ventyx_elec_serv_territories_w_2011_sales_data_backfilled_clip
	where state_abbr not in ('AK','HI')
	GROUP BY state_abbr
),
b as 
(
	SELECT k.state_abbr, sum(total_customers_2011_residential)
	FROM dg_wind.res_load_by_county_us j
	LEFT join diffusion_shared.county_geom k
	ON j.county_id = k.county_id
	GROUP BY k.state_abbr
)
SELECT a.state_abbr, a.sum as est_total, b.sum as county_total, b.sum-a.sum as diff, (b.sum-a.sum)/a.sum * 100 as perc_diff
FROM a
LEFT JOIN b
on a.state_abbr = b.state_abbr
order by perc_diff; --

select *
FROM dg_wind.res_load_by_county_us
where total_customers_2011_residential = 0; 
-- 1 -- grand isle

