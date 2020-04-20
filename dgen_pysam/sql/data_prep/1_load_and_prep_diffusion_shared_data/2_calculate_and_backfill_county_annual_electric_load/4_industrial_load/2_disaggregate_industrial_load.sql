--------------------------------------------------------------------------------------------------------------------
-- us
--------------------------------------------------------------------------------------------------------------------

-- sum the total population in each electric service territory
-- create output table
ALTER TABLE dg_wind.ventyx_ind_cell_counts_us
RENAME TO ventyx_ind_cell_counts_us_archive;

DROP TABLE IF EXISTS dg_wind.ventyx_ind_cell_counts_us CASCADE;
CREATE TABLE dg_wind.ventyx_ind_cell_counts_us
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
		INNER JOIN diffusion_shared.pt_grid_us_ind_new b
		ON ST_Intersects(a.the_geom_4326,b.the_geom_4326)
		GROUP BY a.est_gid;',
		'dg_wind.ventyx_ind_cell_counts_us',
		'a',16);

-- check for service territories that do not have any points
ALTER TABLE dg_wind.ests_w_no_industrial 
RENAME TO ests_w_no_industrial_archive;

DROP TABLE IF EXISTS dg_wind.ests_w_no_industrial;
CREATE TABLE dg_wind.ests_w_no_industrial AS
SELECT a.gid, a.state_abbr,
	a.the_geom_4326, 
	a.total_industrial_sales_mwh, 
	a.total_industrial_customers, 
	c.cell_count
FROM dg_wind.ventyx_elec_serv_territories_w_2011_sales_data_backfilled_clip a
left join dg_wind.ventyx_ind_cell_counts_us c
ON a.gid = c.gid
where (c.cell_count is null or c.cell_count = 0)
and a.state_abbr not in ('AK','HI')
and (a.total_industrial_sales_mwh > 0 or a.total_industrial_customers > 0);
-- 24 total
-- review in Q
-- these are all just slivers or small territories with no ind land
-- in these cases, just spread the data around evenly between intersecting counties

-- how much load is in these areas?
SELECT *
FROM dg_wind.ests_w_no_industrial;

-- intersect with counties

-- disaggregate the load to pts
ALTER TABLE dg_wind.disaggregated_load_industrial_us
RENAME TO disaggregated_load_industrial_us_archive;

DROP TABLE IF EXISTS dg_wind.disaggregated_load_industrial_us;
CREATE TABLE dg_wind.disaggregated_load_industrial_us
(
	pt_gid integer,
	county_id integer,
	est_gid integer,
	industrial_sales_mwh numeric,
	industrial_customers numeric
);

select parsel_2('dav-gis','mgleason','mgleason',
		'diffusion_shared.pt_grid_us_ind_new','gid',
		'select a.gid as pt_gid, a.county_id,
			b.est_gid as est_gid,
			(1::numeric/d.cell_count) * c.total_industrial_sales_mwh as industrial_sales_mwh,
			(1::numeric/d.cell_count) * c.total_industrial_customers as industrial_customers
		FROM diffusion_shared.pt_grid_us_ind_new a
		INNER JOIN dg_wind.ventyx_backfilled_ests_diced b
			ON ST_Intersects(a.the_geom_4326, b.the_geom_4326)
		LEFT JOIN dg_wind.ventyx_elec_serv_territories_w_2011_sales_data_backfilled_clip c
			ON b.est_gid = c.gid
		LEFT JOIN dg_wind.ventyx_ind_cell_counts_us d
			on b.est_gid = d.gid',
			'dg_wind.disaggregated_load_industrial_us',
			'a',16);

-- add index on the county id column
CREATE INDEX disaggregated_load_industrial_us_county_id_btree
ON  dg_wind.disaggregated_load_industrial_us
USING btree(county_id);

-- aggregate the results to counties
DROP TABLE IF EXISTS dg_wind.ind_load_by_county_us_incomplete;
CREATE TABLE dg_wind.ind_load_by_county_us_incomplete
(
	county_id integer,
	total_load_mwh_2011_industrial numeric,
	total_customers_2011_industrial numeric
);

select parsel_2('dav-gis','mgleason','mgleason',
		'dg_wind.disaggregated_load_industrial_us','county_id',
		'select a.county_id,
			sum(industrial_sales_mwh) as total_load_mwh_2011_industrial,
			sum(industrial_customers) as total_customers_2011_industrial
		FROM dg_wind.disaggregated_load_industrial_us a
		GROUP BY a.county_id',
			'dg_wind.ind_load_by_county_us_incomplete',
			'a',16);

-- need to add in the portions of Ventyx territories with no industrial pts
-- add indices
CREATE INDEX ests_w_no_industrial_the_geom_4326_gist
ON  dg_wind.ests_w_no_industrial
using gist(the_geom_4326);

CREATE INDEX ests_w_no_industrial_state_abbr_btree
ON  dg_wind.ests_w_no_industrial
using btree(state_abbr);

DROP TABLE IF EXISTS dg_wind.ests_w_no_industrial_disaggregated;
CREATE TABLE dg_wind.ests_w_no_industrial_disaggregated AS
with a as
(
	select a.gid as est_gid,
		b.county_id,
		a.total_industrial_sales_mwh, 
		a.total_industrial_customers,
		ST_Area(ST_Transform(ST_Intersection(a.the_geom_4326, b.the_geom_4326),96703))/ST_Area(ST_Transform(a.the_geom_4326, 96703)) as ratio
	FROM dg_wind.ests_w_no_industrial a
	INNER JOIN diffusion_shared.county_geom b
	ON ST_Intersects(a.the_geom_4326, b.the_geom_4326)
	and a.state_abbr = b.state_abbr
)
select a.est_gid,
	county_id,
	total_industrial_sales_mwh * ratio as total_load_mwh_2011_industrial,
	total_industrial_customers * ratio as total_customers_2011_industrial
from a;

-- combine with the data from points to form the final county load table
ALTER TABLE dg_wind.ind_load_by_county_us 
RENAME TO ind_load_by_county_us_archive;

DROP TABLE IF EXISTS dg_wind.ind_load_by_county_us;
CREATE TABLE dg_wind.ind_load_by_county_us AS
with a as
(
	SELECT county_id, total_load_mwh_2011_industrial, total_customers_2011_industrial
	FROM dg_wind.ind_load_by_county_us_incomplete 
	UNION ALL
	SELECT county_id, total_load_mwh_2011_industrial, total_customers_2011_industrial
	FROM dg_wind.ests_w_no_industrial_disaggregated
)
SELECT county_id, 
	sum(total_load_mwh_2011_industrial) as total_load_mwh_2011_industrial, 
	sum(total_customers_2011_industrial) as total_customers_2011_industrial
FROM a
group by county_id;
-- 3108 rows

-- add a primary key on county_id
ALTER TABLE dg_wind.ind_load_by_county_us
ADD PRIMARY KEY (county_id);

---------------------------------------------------------------------------------------------------
-- PERFORM SOME VERIFICATION OF THE RESULTS

-- how many rows were returned?
select count(*)
FROM dg_wind.ind_load_by_county_us; --3108

-- how many are there total?
select count(*)
FROM diffusion_shared.county_geom
where state_abbr not in ('AK','HI'); -- 3109

-- what is missing
SELECT a.*
FROM diffusion_shared.county_geom a
LEFT JOIN dg_wind.ind_load_by_county_us b
on a.county_id = b.county_id
where b.county_id is null
and a.state_abbr not in ('AK', 'HI'); -- just grand isle vermont
-- only missing county is a small island in lake champlain (VT) -- this doesnt seem too unreasonable

-- add this county in with a value of zero for load and customers
INSERT INTO dg_wind.ind_load_by_county_us
 (county_id, total_load_mwh_2011_industrial, total_customers_2011_industrial)  VALUES (2988, 0, 0);


-- check load values
SELECT sum(total_load_mwh_2011_industrial)
FROM dg_wind.ind_load_by_county_us; -- 986,246,281.703006

select sum(total_industrial_sales_mwh)
FROM dg_wind.ventyx_elec_serv_territories_w_2011_sales_data_backfilled_clip
where state_abbr not in ('AK','HI'); -- 986,246,314

select 986246314 - 986246281.703006; -- 32.296994 (difference possibly/likely(?) due to rounding)
select (986246314 - 986246281.703006)/986246314  * 100; -- 0.000003274739133777893100 % load is missing nationally

-- cehck on state level
with a as 
(
	select state_abbr, sum(total_industrial_sales_mwh)
	FROM dg_wind.ventyx_elec_serv_territories_w_2011_sales_data_backfilled_clip
	where state_abbr not in ('AK','HI')
	GROUP BY state_abbr
),
b as 
(
	SELECT k.state_abbr, sum(total_load_mwh_2011_industrial)
	FROM dg_wind.ind_load_by_county_us j
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
FROM dg_wind.ind_load_by_county_us_archive
where total_load_mwh_2011_industrial = 0; -- 13 of them 
-- reviewed in Q
-- the vast majority of these are in a single cluster in NW South Dakota
-- there is no flaw in the processing of the load, but it seems like these utilities (which are rural coops)
-- don't account for industrial load. they must count whatevr industrial users they have as commercial
-- likely this is just agricultural users. there is no good way to separate out their commercial load into industrial
-- so this will mean that any ag users in these counties are represented in commercial sector, not industrial
-- other counties with zero load include a rural county in western West Virginia, and a county in MD along the
-- Chesepeake. Overall, all of these counties appear to have very little industrial land (based on land masks),
-- so it is not a huge concern that a single county will have zero industrail load

-- check values for customers
SELECT sum(total_customers_2011_industrial)
FROM dg_wind.ind_load_by_county_us; -- 725,966.744431214

select sum(total_industrial_customers)
FROM dg_wind.ventyx_elec_serv_territories_w_2011_sales_data_backfilled_clip
where state_abbr not in ('AK','HI'); -- 725,967

select 725967 - 725966.744431214; -- 0.255568786 (difference likely due to rounding)
select (725967 - 725966.744431214)/17529504  * 100; -- 0.000001457935067643670900 % load is missing nationally

-- cehck on state level
with a as 
(
	select state_abbr, sum(total_industrial_customers)
	FROM dg_wind.ventyx_elec_serv_territories_w_2011_sales_data_backfilled_clip
	where state_abbr not in ('AK','HI')
	GROUP BY state_abbr
),
b as 
(
	SELECT k.state_abbr, sum(total_customers_2011_industrial)
	FROM dg_wind.ind_load_by_county_us j
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
FROM dg_wind.ind_load_by_county_us
where total_customers_2011_industrial = 0; 
-- 13 of these check in q

