--------------------------------------------------------------------------------------------------------------------
-- us
--------------------------------------------------------------------------------------------------------------------

-- sum the total population in each electric service territory
-- create output table
DROP TABLE IF EXISTS dg_wind.ventyx_comm_cell_counts_us CASCADE;
CREATE TABLE dg_wind.ventyx_comm_cell_counts_us
(gid integer,
comm_count numeric,
cell_count numeric);

-- use dg_wind.ventyx_ests_backfilled_geoms_clipped
-- run parsel

-- if its still too slow, need to try to split up on something other than gid

select parsel_2('dav-gis','dg_wind.ventyx_backfilled_ests_diced','state_id',
'WITH tile_stats as (
	select a.est_gid as gid,
		ST_SummaryStats(ST_Clip(b.rast, 1, a.the_geom_4326, true)) as stats
	FROM dg_wind.ventyx_backfilled_ests_diced as a
	INNER JOIN dg_wind.commercial_land_mask_100x100 b
	ON ST_Intersects(a.the_geom_4326,b.rast)
)
	--aggregate the results from each tile
SELECT gid, sum((stats).sum) as comm_count, sum((stats).count) as cell_count
FROM tile_stats
GROUP by gid;'
,'dg_wind.ventyx_comm_cell_counts_us','a',16);
-- run time = 728645.530 ms

select *
FROM dg_wind.ventyx_comm_cell_counts_us
where comm_count <> cell_count;

-- check for service territories that do not have population
DROP TABLE IF EXISTS dg_wind.ests_w_no_commercial;
CREATE TABLE dg_wind.ests_w_no_commercial AS
	SELECT a.gid, a.state_abbr,
		a.the_geom_4326, 
		a.total_commercial_sales_mwh, c.cell_count, c.comm_count
	FROM dg_wind.ventyx_elec_serv_territories_w_2011_sales_data_backfilled_clip a
	left join dg_wind.ventyx_comm_cell_counts_us c
	ON a.gid = c.gid
	where (c.comm_count is null or c.comm_count = 0)
	and a.state_abbr not in ('AK','HI');
-- review in Q
-- these are all just slivers or small territories with no comm land
-- in these cases, just spread the data around evenly


-- perform map algebra to estimate the percent of each raster
DROP TABLE IF EXISTS dg_wind.disaggregated_load_commercial_us;
CREATE TABLE dg_wind.disaggregated_load_commercial_us (
	tile_id integer,
	rast raster);

-- need to add something in here to use the diced geoms with state_id

--- run parsel
select parsel_2('dav-gis',' dg_wind.ventyx_backfilled_ests_diced','state_id',
'WITH clip as (
select a.gid, c.comm_count, b.rid,
	ST_Clip(b.rast, 1, x.the_geom_4326, true) as rast,
	CASE WHEN c.comm_count is null or c.comm_count = 0 THEN ''([rast]+1.)/'' || c.cell_count || ''*'' || a.total_commercial_sales_mwh
	ELSE ''[rast]/'' || c.comm_count || ''*'' || a.total_commercial_sales_mwh 
	END as map_alg_expr

FROM dg_wind.ventyx_backfilled_ests_diced x

LEFT JOIN dg_wind.ventyx_elec_serv_territories_w_2011_sales_data_backfilled_clip as a
ON x.est_gid = a.gid

INNER JOIN dg_wind.commercial_land_mask_100x100 b
ON ST_Intersects(x.the_geom_4326,b.rast)

LEFT JOIN dg_wind.ventyx_comm_cell_counts_us c
ON x.est_gid = c.gid

where c.cell_count > 0 and a.total_commercial_sales_mwh >= 0) 
SELECT rid as tile_id, ST_MapAlgebraExpr(rast, ''32BF'', map_alg_expr) as rast
FROM clip;','dg_wind.disaggregated_load_commercial_us','x',16);
--  runtime =  3225846.647 ms

-- add rid primary key column
ALTER TABLE dg_wind.disaggregated_load_commercial_us
ADD COLUMN rid serial;

ALTER TABLE dg_wind.disaggregated_load_commercial_us
ADD PRIMARY KEY (rid);

-- aggregate the results into tiles
DROP TABLE IF EXISTS dg_wind.mosaic_load_commercial_us;
CREATE TABLE dg_wind.mosaic_load_commercial_us 
	(rid integer,
	rast raster);

select parsel_2('dav-gis','dg_wind.disaggregated_load_commercial_us','tile_id',
'SELECT a.tile_id as rid, ST_Union(a.rast,''SUM'') as rast
FROM dg_wind.disaggregated_load_commercial_us a
GROUP BY a.tile_id;','dg_wind.mosaic_load_commercial_us','a',16);
-- run time = 830647.564 ms (14 mins)

-- create spatial index on this file
CREATE INDEX mosaic_load_commercial_us_rast_gist
  ON dg_wind.mosaic_load_commercial_us
  USING gist
  (st_convexhull(rast));

-- then sum to counties
-- create output table
DROP TABLE IF EXISTS dg_wind.com_load_by_county_us;
CREATE TABLE dg_wind.com_load_by_county_us
(county_id integer,
total_load_mwh_2011_commercial numeric);

-- run parsel
select parsel_2('dav-gis','diffusion_shared.county_geom','county_id',
'WITH tile_stats as (
	select a.county_id,
		ST_SummaryStats(ST_Clip(b.rast, 1, a.the_geom_4326, true)) as stats
	FROM diffusion_shared.county_geom as a
	INNER JOIN dg_wind.mosaic_load_commercial_us b
	ON ST_Intersects(a.the_geom_4326,b.rast)
)
	--aggregate the results from each tile
SELECT county_id, sum((stats).sum) as total_load_mwh_2011_commercial
FROM tile_stats
GROUP by county_id;'
,'dg_wind.com_load_by_county_us','a',16);
-- 629988.529 ms

-- do some additional verification
SELECT sum(total_load_mwh_2011_commercial)
FROM dg_wind.com_load_by_county_us; -- 1,321,813,204.5154683796833

select sum(total_commercial_sales_mwh)
FROM dg_wind.ventyx_elec_serv_territories_w_2011_sales_data_backfilled_clip
where state_abbr not in ('AK','HI'); -- 1,321,813,207

select 1321813207 - 1321813204.5154683796833; -- 2.4845316203167 (difference likely due to rounding)
select (1321813207 - 1321813204.5154683796833)/1321813207  * 100; -- 0.0000001879638974069276340600 % load is missing nationally

-- cehck on state level
with a as (
select state_abbr, sum(total_commercial_sales_mwh)
FROM dg_wind.ventyx_elec_serv_territories_w_2011_sales_data_backfilled_clip
where state_abbr not in ('AK','HI')
GROUP BY state_abbr),

b as (

SELECT k.state_abbr, sum(total_load_mwh_2011_commercial)
FROM dg_wind.com_load_by_county_us j
LEFT join diffusion_shared.county_geom k
ON j.county_id = k.county_id
GROUP BY k.state_abbr)

SELECT a.state_abbr, a.sum as est_total, b.sum as county_total, b.sum-a.sum as diff, (b.sum-a.sum)/a.sum * 100 as perc_diff
FROM a
LEFT JOIN b
on a.state_abbr = b.state_abbr
order by a.state_abbr; --
-- looks good -- these differcnces are probably due to incongruencies between county_geoms and the ventyx state boundaries

-- any counties w/out comm load?
select *
FROM dg_wind.com_load_by_county_us
where total_load_mwh_2011_commercial = 0; -- nope


----------------------------------------------------------------------------------------------------
-- repeat for number of customers
----------------------------------------------------------------------------------------------------
-- check that there aren't any territories with residential customers but zero load
SELECT count(*)
FROM dg_wind.ventyx_elec_serv_territories_w_2011_sales_data_backfilled_clip
where total_commercial_customers > 0 and (total_commercial_sales_mwh <= 0 or total_commercial_sales_mwh is null)

-- 1 - create the disag raster table
DROP TABLE IF EXISTS dg_wind.disaggregated_customers_commercial_us;
CREATE TABLE dg_wind.disaggregated_customers_commercial_us (
	tile_id integer,
	rast raster);

--- run parsel
select parsel_2('dav-gis',' dg_wind.ventyx_backfilled_ests_diced','state_id',
'WITH clip as (
select a.gid, c.cell_count, b.rid,
	ST_Clip(b.rast, 1, x.the_geom_4326, true) as rast,
	CASE WHEN c.comm_count is null or c.comm_count = 0 THEN ''([rast]+1.)/'' || c.cell_count || ''*'' || a.total_commercial_customers
	ELSE ''[rast]/'' || c.comm_count || ''*'' || a.total_commercial_customers 
	END as map_alg_expr

FROM dg_wind.ventyx_backfilled_ests_diced x

LEFT JOIN dg_wind.ventyx_elec_serv_territories_w_2011_sales_data_backfilled_clip as a
ON x.est_gid = a.gid

INNER JOIN dg_wind.commercial_land_mask_100x100 b
ON ST_Intersects(x.the_geom_4326,b.rast)

LEFT JOIN dg_wind.ventyx_comm_cell_counts_us c
ON x.est_gid = c.gid

where c.cell_count > 0 and a.total_commercial_customers >= 0) 
SELECT rid as tile_id, ST_MapAlgebraExpr(rast, ''32BF'', map_alg_expr) as rast
FROM clip;','dg_wind.disaggregated_customers_commercial_us','x',16);
--  runtime = ~74 minutes (3950668.635 ms)

-- add rid primary key column
ALTER TABLE dg_wind.disaggregated_customers_commercial_us
ADD COLUMN rid serial;

ALTER TABLE dg_wind.disaggregated_customers_commercial_us
ADD PRIMARY KEY (rid);

-- 2 - aggregate the results into tiles
DROP TABLE IF EXISTS dg_wind.mosaic_customers_commercial_us;
CREATE TABLE dg_wind.mosaic_customers_commercial_us 
	(rid integer,
	rast raster);

select parsel_2('dav-gis','dg_wind.disaggregated_customers_commercial_us','tile_id',
'SELECT a.tile_id as rid, ST_Union(a.rast,''SUM'') as rast
FROM dg_wind.disaggregated_customers_commercial_us a
GROUP BY a.tile_id;','dg_wind.mosaic_customers_commercial_us','a',16);
-- run time =  839042.650 ms

-- create spatial index on this file
CREATE INDEX mosaic_customers_commercial_us_rast_gist
  ON dg_wind.mosaic_customers_commercial_us
  USING gist
  (st_convexhull(rast));

-- 3- then sum to counties
-- create output table
DROP TABLE IF EXISTS dg_wind.com_customers_by_county_us;
CREATE TABLE dg_wind.com_customers_by_county_us
(county_id integer,
total_customers_2011_commercial numeric);

-- run parsel
select parsel_2('dav-gis','diffusion_shared.county_geom','county_id',
'WITH tile_stats as (
	select a.county_id,
		ST_SummaryStats(ST_Clip(b.rast, 1, a.the_geom_4326, true)) as stats
	FROM diffusion_shared.county_geom as a
	INNER JOIN dg_wind.mosaic_customers_commercial_us b
	ON ST_Intersects(a.the_geom_4326,b.rast)
)
	--aggregate the results from each tile
SELECT county_id, sum((stats).sum) as total_customers_2011_commercial
FROM tile_stats
GROUP by county_id;'
,'dg_wind.com_customers_by_county_us','a',16);
-- run time =  624568.142 ms

-- 4 - do some verification
SELECT sum(total_customers_2011_commercial)
FROM dg_wind.com_customers_by_county_us; -- 17,529,503.97530562476658

select sum(total_commercial_customers)
FROM dg_wind.ventyx_elec_serv_territories_w_2011_sales_data_backfilled_clip
where state_abbr not in ('AK','HI'); -- 17,529,504

select 17529504 - 17529503.97530562476658; -- 0.02469437523342 (difference likely due to rounding)
select (17529504 - 17529503.97530562476658)/17529504  * 100; -- 0.0000001408732114349613086600 % load is missing nationally

-- cehck on state level
with a as (
select state_abbr, sum(total_commercial_customers)
FROM dg_wind.ventyx_elec_serv_territories_w_2011_sales_data_backfilled_clip
where state_abbr not in ('AK','HI')
GROUP BY state_abbr),

b as (

SELECT k.state_abbr, sum(total_customers_2011_commercial)
FROM dg_wind.com_customers_by_county_us j
LEFT join diffusion_shared.county_geom k
ON j.county_id = k.county_id
GROUP BY k.state_abbr)

SELECT a.state_abbr, a.sum as est_total, b.sum as county_total, b.sum-a.sum as diff, (b.sum-a.sum)/a.sum * 100 as perc_diff
FROM a
LEFT JOIN b
on a.state_abbr = b.state_abbr
order by perc_diff; --

select *
FROM dg_wind.com_customers_by_county_us
where total_customers_2011_commercial = 0;
-- looks good -- these differcnces are probably due to incongruencies between county_geoms and the ventyx state boundaries
