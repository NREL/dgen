--------------------------------------------------------------------------------------------------------------------
-- us
--------------------------------------------------------------------------------------------------------------------

-- sum the total population in each electric service territory
-- create output table
ALTER TABLE dg_wind.ventyx_comm_cell_counts_us
RENAME TO ventyx_comm_cell_counts_us_archive;

DROP TABLE IF EXISTS dg_wind.ventyx_comm_cell_counts_us CASCADE;
CREATE TABLE dg_wind.ventyx_comm_cell_counts_us
(
	gid integer,
	cell_count numeric
);

-- use dg_wind.ventyx_ests_backfilled_geoms_clipped
-- run parsel

-- if its still too slow, need to try to split up on something other than gid

select parsel_2('dav-gis','mgleason','mgleason','dg_wind.ventyx_backfilled_ests_diced','state_id',
		'select a.est_gid as gid, 
			count(b.gid) as cell_count
		FROM dg_wind.ventyx_backfilled_ests_diced as a
		INNER JOIN diffusion_shared.pt_grid_us_com_new b
		ON ST_Intersects(a.the_geom_4326,b.the_geom_4326)
		GROUP BY a.est_gid;',
		'dg_wind.ventyx_comm_cell_counts_us',
		'a',16);
-- run time = 728645.530 ms

-- check for service territories that do not have any commercial points
ALTER TABLE dg_wind.ests_w_no_commercial 
RENAME TO ests_w_no_commercial_archive;

DROP TABLE IF EXISTS dg_wind.ests_w_no_commercial;
CREATE TABLE dg_wind.ests_w_no_commercial AS
SELECT a.gid, a.state_abbr,
	a.the_geom_4326, 
	a.total_commercial_sales_mwh, 
	a.total_commercial_customers, 
	c.cell_count
FROM dg_wind.ventyx_elec_serv_territories_w_2011_sales_data_backfilled_clip a
left join dg_wind.ventyx_comm_cell_counts_us c
ON a.gid = c.gid
where (c.cell_count is null or c.cell_count = 0)
and a.state_abbr not in ('AK','HI')
and (a.total_commercial_sales_mwh > 0 or a.total_commercial_customers > 0);
-- 28 total
-- review in Q
-- these are all just slivers or small territories with no comm land
-- in these cases, just spread the data around evenly between intersecting counties

-- how much load is in these areas?
SELECT *
FROM dg_wind.ests_w_no_commercial;

-- intersect with counties

-- disaggregate the load to pts
ALTER TABLE dg_wind.disaggregated_load_commercial_us
RENAME TO disaggregated_load_commercial_us_archive;

DROP TABLE IF EXISTS dg_wind.disaggregated_load_commercial_us;
CREATE TABLE dg_wind.disaggregated_load_commercial_us
(
	pt_gid integer,
	county_id integer,
	est_gid integer,
	commercial_sales_mwh numeric,
	commercial_customers numeric
);

select parsel_2('dav-gis','mgleason','mgleason',
		'diffusion_shared.pt_grid_us_com_new','gid',
		'select a.gid as pt_gid, a.county_id,
			b.est_gid as est_gid,
			(1::numeric/d.cell_count) * c.total_commercial_sales_mwh as commercial_sales_mwh,
			(1::numeric/d.cell_count) * c.total_commercial_customers as commercial_customers
		FROM diffusion_shared.pt_grid_us_com_new a
		INNER JOIN dg_wind.ventyx_backfilled_ests_diced b
			ON ST_Intersects(a.the_geom_4326, b.the_geom_4326)
		LEFT JOIN dg_wind.ventyx_elec_serv_territories_w_2011_sales_data_backfilled_clip c
			ON b.est_gid = c.gid
		LEFT JOIN dg_wind.ventyx_comm_cell_counts_us d
			on b.est_gid = d.gid',
			'dg_wind.disaggregated_load_commercial_us',
			'a',16);

-- add index on the county id column
CREATE INDEX disaggregated_load_commercial_us_county_id_btree
ON  dg_wind.disaggregated_load_commercial_us
USING btree(county_id);

-- aggregate the results to counties


DROP TABLE IF EXISTS dg_wind.com_load_by_county_us_incomplete;
CREATE TABLE dg_wind.com_load_by_county_us_incomplete
(
	county_id integer,
	total_load_mwh_2011_commercial numeric,
	total_customers_2011_commercial numeric
);

select parsel_2('dav-gis','mgleason','mgleason',
		'dg_wind.disaggregated_load_commercial_us','county_id',
		'select a.county_id,
			sum(commercial_sales_mwh) as total_load_mwh_2011_commercial,
			sum(commercial_customers) as total_customers_2011_commercial
		FROM dg_wind.disaggregated_load_commercial_us a
		GROUP BY a.county_id',
			'dg_wind.com_load_by_county_us_incomplete',
			'a',16);

-- need to add in the portions of Ventyx territories with no commercial pts
-- add indices
CREATE INDEX ests_w_no_commercial_the_geom_4326_gist
ON  dg_wind.ests_w_no_commercial
using gist(the_geom_4326);

CREATE INDEX ests_w_no_commercial_state_abbr_btree
ON  dg_wind.ests_w_no_commercial
using btree(state_abbr);

DROP TABLE IF EXISTS dg_wind.ests_w_no_commercial_disaggregated;
CREATE TABLE dg_wind.ests_w_no_commercial_disaggregated AS
with a as
(
	select a.gid as est_gid,
		b.county_id,
		a.total_commercial_sales_mwh, 
		a.total_commercial_customers,
		ST_Area(ST_Transform(ST_Intersection(a.the_geom_4326, b.the_geom_4326),96703))/ST_Area(ST_Transform(a.the_geom_4326, 96703)) as ratio
	FROM dg_wind.ests_w_no_commercial a
	INNER JOIN diffusion_shared.county_geom b
	ON ST_Intersects(a.the_geom_4326, b.the_geom_4326)
	and a.state_abbr = b.state_abbr
)
select a.est_gid,
	county_id,
	total_commercial_sales_mwh * ratio as total_load_mwh_2011_commercial,
	total_commercial_customers * ratio as total_customers_2011_commercial
from a;

-- combine with the data from points to form the final county load table
ALTER TABLE dg_wind.com_load_by_county_us 
RENAME TO com_load_by_county_us_archive;

DROP TABLE IF EXISTS dg_wind.com_load_by_county_us;
CREATE TABLE dg_wind.com_load_by_county_us AS
with a as
(
	SELECT county_id, total_load_mwh_2011_commercial, total_customers_2011_commercial
	FROM dg_wind.com_load_by_county_us_incomplete 
	UNION ALL
	SELECT county_id, total_load_mwh_2011_commercial, total_customers_2011_commercial
	FROM dg_wind.ests_w_no_commercial_disaggregated
)
SELECT county_id, 
	sum(total_load_mwh_2011_commercial) as total_load_mwh_2011_commercial, 
	sum(total_customers_2011_commercial) as total_customers_2011_commercial
FROM a
group by county_id;
-- 3108 rows

-- add a primary key on county_id
ALTER TABLE dg_wind.com_load_by_county_us
ADD PRIMARY KEY (county_id);

---------------------------------------------------------------------------------------------------
-- PERFORM SOME VERIFICATION OF THE RESULTS

-- how many rows were returned?
select count(*)
FROM dg_wind.com_load_by_county_us; --3108

-- how many are there total?
select count(*)
FROM diffusion_shared.county_geom
where state_abbr not in ('AK','HI'); -- 3109

-- what is missing
SELECT a.*
FROM diffusion_shared.county_geom a
LEFT JOIN dg_wind.com_load_by_county_us b
on a.county_id = b.county_id
where b.county_id is null
and a.state_abbr not in ('AK', 'HI');
-- only missing county is a small island in lake champlain (VT) -- this doesnt seem too unreasonable

-- add this county in with a value of zero for load and customers
INSERT INTO dg_wind.com_load_by_county_us
 (county_id, total_load_mwh_2011_commercial, total_customers_2011_commercial)  VALUES (2988, 0, 0);


-- check load values
SELECT sum(total_load_mwh_2011_commercial)
FROM dg_wind.com_load_by_county_us; -- 1,321,813,102.12185

select sum(total_commercial_sales_mwh)
FROM dg_wind.ventyx_elec_serv_territories_w_2011_sales_data_backfilled_clip
where state_abbr not in ('AK','HI'); -- 1,321,813,207

select 1321813207 - 1321813102.12185; -- 104.87815 (difference possibly/likely(?) due to rounding)
select (1321813207 - 1321813102.12185)/1321813207  * 100; -- 0.000007934415350413426500 % load is missing nationally

-- cehck on state level
with a as 
(
	select state_abbr, sum(total_commercial_sales_mwh)
	FROM dg_wind.ventyx_elec_serv_territories_w_2011_sales_data_backfilled_clip
	where state_abbr not in ('AK','HI')
	GROUP BY state_abbr
),
b as 
(
	SELECT k.state_abbr, sum(total_load_mwh_2011_commercial)
	FROM dg_wind.com_load_by_county_us j
	LEFT join diffusion_shared.county_geom k
	ON j.county_id = k.county_id
	GROUP BY k.state_abbr
)
SELECT a.state_abbr, a.sum as est_total, b.sum as county_total, b.sum-a.sum as diff, (b.sum-a.sum)/a.sum * 100 as perc_diff
FROM a
LEFT JOIN b
on a.state_abbr = b.state_abbr
order by a.state_abbr; --
-- looks good -- these differcnces are probably due to incongruencies between county_geoms and the ventyx state boundaries

-- any counties w/out comm load (other than Grand Isle)
select *
FROM dg_wind.com_load_by_county_us
where total_load_mwh_2011_commercial = 0; -- nope

-- check values for customers
SELECT sum(total_customers_2011_commercial)
FROM dg_wind.com_load_by_county_us; -- 17,529,501.0606915

select sum(total_commercial_customers)
FROM dg_wind.ventyx_elec_serv_territories_w_2011_sales_data_backfilled_clip
where state_abbr not in ('AK','HI'); -- 17,529,504

select 17529504 - 17529501.0606915; -- 2.9393085 (difference likely due to rounding)
select (17529504 - 17529501.0606915)/17529504  * 100; -- 0.000016767779054102158300 % load is missing nationally

-- cehck on state level
with a as 
(
	select state_abbr, sum(total_commercial_customers)
	FROM dg_wind.ventyx_elec_serv_territories_w_2011_sales_data_backfilled_clip
	where state_abbr not in ('AK','HI')
	GROUP BY state_abbr
),
b as 
(
	SELECT k.state_abbr, sum(total_customers_2011_commercial)
	FROM dg_wind.com_load_by_county_us j
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
FROM dg_wind.com_load_by_county_us
where total_customers_2011_commercial = 0; -- just grand isle
-- looks good -- these differcnces are probably due to incongruencies between county_geoms and the ventyx state boundaries
