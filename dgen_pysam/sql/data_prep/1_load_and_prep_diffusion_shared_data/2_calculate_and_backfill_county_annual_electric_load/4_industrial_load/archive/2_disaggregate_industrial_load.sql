--------------------------------------------------------------------------------------------------------------------
-- us
--------------------------------------------------------------------------------------------------------------------

-- sum the total population in each electric service territory
-- create output table
DROP TABLE IF EXISTS dg_wind.ventyx_ind_cell_counts_us CASCADE;
CREATE TABLE dg_wind.ventyx_ind_cell_counts_us
(gid integer,
ind_count numeric,
cell_count numeric);

-- use dg_wind.ventyx_ests_backfilled_geoms_clipped
-- run parsel

-- if its still too slow, need to try to split up on something other than gid

select parsel_2('dav-gis','dg_wind.ventyx_backfilled_ests_diced','state_id',
'WITH tile_stats as (
	select a.est_gid as gid,
		ST_SummaryStats(ST_Clip(b.rast, 1, a.the_geom_900914, true)) as stats
	FROM dg_wind.ventyx_backfilled_ests_diced as a
	INNER JOIN dg_wind.industrial_land_mask_us_100x100 b
	ON ST_Intersects(a.the_geom_900914,b.rast)
)
	--aggregate the results from each tile
SELECT gid, sum((stats).sum) as ind_count, sum((stats).count) as cell_count
FROM tile_stats
GROUP by gid;'
,'dg_wind.ventyx_ind_cell_counts_us','a',16);
-- run time = 728645.530 ms

select *
FROM dg_wind.ventyx_ind_cell_counts_us
where ind_count <> cell_count;

-- check for service territories that do not have population
DROP TABLE IF EXISTS dg_wind.ests_w_no_industrial;
CREATE TABLE dg_wind.ests_w_no_industrial AS
	SELECT a.gid, a.state_abbr,
		a.the_geom_4326, 
		a.total_industrial_sales_mwh, c.cell_count, c.ind_count
	FROM dg_wind.ventyx_elec_serv_territories_w_2011_sales_data_backfilled_clip a
	left join dg_wind.ventyx_ind_cell_counts_us c
	ON a.gid = c.gid
	where (c.ind_count is null or c.ind_count = 0)
	and a.state_abbr not in ('AK','HI');
-- review in Q
-- these are mostly just slivers or small territories with no ind land. some larger areas that look like winderness
-- in these cases, just spread the data around evenly


-- perform map algebra to estimate the percent of each raster
DROP TABLE IF EXISTS dg_wind.disaggregated_load_industrial_us;
CREATE TABLE dg_wind.disaggregated_load_industrial_us (
	tile_id integer,
	rast raster);

-- need to add something in here to use the diced geoms with state_id

--- run parsel
select parsel_2('dav-gis',' dg_wind.ventyx_backfilled_ests_diced','state_id',
'WITH clip as (
select a.gid, c.ind_count, b.rid,
	ST_Clip(b.rast, 1, x.the_geom_900914, true) as rast,
	CASE WHEN c.ind_count is null or c.ind_count = 0 THEN ''([rast]+1.)/'' || c.cell_count || ''*'' || a.total_industrial_sales_mwh
	ELSE ''[rast]/'' || c.ind_count || ''*'' || a.total_industrial_sales_mwh 
	END as map_alg_expr

FROM dg_wind.ventyx_backfilled_ests_diced x

LEFT JOIN dg_wind.ventyx_elec_serv_territories_w_2011_sales_data_backfilled_clip as a
ON x.est_gid = a.gid

INNER JOIN dg_wind.industrial_land_mask_us_100x100 b
ON ST_Intersects(x.the_geom_900914,b.rast)

LEFT JOIN dg_wind.ventyx_ind_cell_counts_us c
ON x.est_gid = c.gid

where c.cell_count > 0 and a.total_industrial_sales_mwh >= 0) 
SELECT rid as tile_id, ST_MapAlgebraExpr(rast, ''32BF'', map_alg_expr) as rast
FROM clip;','dg_wind.disaggregated_load_industrial_us','x',16);
--  runtime =  732595.576 ms

-- add rid primary key column
ALTER TABLE dg_wind.disaggregated_load_industrial_us
ADD COLUMN rid serial;

ALTER TABLE dg_wind.disaggregated_load_industrial_us
ADD PRIMARY KEY (rid);

-- aggregate the results into tiles
DROP TABLE IF EXISTS dg_wind.mosaic_load_industrial_us;
CREATE TABLE dg_wind.mosaic_load_industrial_us 
	(rid integer,
	rast raster);

select parsel_2('dav-gis','dg_wind.disaggregated_load_industrial_us','tile_id',
'SELECT a.tile_id as rid, ST_Union(a.rast,''SUM'') as rast
FROM dg_wind.disaggregated_load_industrial_us a
GROUP BY a.tile_id;','dg_wind.mosaic_load_industrial_us','a',16);
-- run time =  199647.292 (4 mins)
-- ** this is running on screen now

-- create spatial index on this file
CREATE INDEX mosaic_load_industrial_us_rast_gist
  ON dg_wind.mosaic_load_industrial_us
  USING gist
  (st_convexhull(rast));

-- then sum to counties
-- create output table
DROP TABLE IF EXISTS dg_wind.ind_load_by_county_us;
CREATE TABLE dg_wind.ind_load_by_county_us
(county_id integer,
total_load_mwh_2011_industrial numeric);

-- run parsel
select parsel_2('dav-gis','diffusion_shared.county_geom','county_id',
'WITH tile_stats as (
	select a.county_id,
		ST_SummaryStats(ST_Clip(b.rast, 1, a.the_geom_900914, true)) as stats
	FROM diffusion_shared.county_geom as a
	INNER JOIN dg_wind.mosaic_load_industrial_us b
	ON ST_Intersects(a.the_geom_900914,b.rast)
)
	--aggregate the results from each tile
SELECT county_id, sum((stats).sum) as total_load_mwh_2011_industrial
FROM tile_stats
GROUP by county_id;'
,'dg_wind.ind_load_by_county_us','a',16);
--  110006.178 ms (1+ mins)

-- do some additional verification
SELECT sum(total_load_mwh_2011_industrial)
FROM dg_wind.ind_load_by_county_us; -- 986246311.3601828027684

select sum(total_industrial_sales_mwh)
FROM dg_wind.ventyx_elec_serv_territories_w_2011_sales_data_backfilled_clip
where state_abbr not in ('AK','HI'); -- 986246314

select  986246314 - 986246311.3601828027684; -- 2.6398171972316 (difference likely due to rounding)
select (986246314 - 986246311.3601828027684)/986246314  * 100; -- 0.0000002676630735911272566700 % load is missing nationally

-- cehck on state level
with a as (
select state_abbr, sum(total_industrial_sales_mwh)
FROM dg_wind.ventyx_elec_serv_territories_w_2011_sales_data_backfilled_clip
where state_abbr not in ('AK','HI')
GROUP BY state_abbr),

b as (

SELECT k.state_abbr, sum(total_load_mwh_2011_industrial)
FROM dg_wind.ind_load_by_county_us j
LEFT join diffusion_shared.county_geom k
ON j.county_id = k.county_id
GROUP BY k.state_abbr)

SELECT a.state_abbr, a.sum as est_total, b.sum as county_total, b.sum-a.sum as diff, (b.sum-a.sum)/a.sum * 100 as perc_diff
FROM a
LEFT JOIN b
on a.state_abbr = b.state_abbr
order by perc_diff; --
-- looks good -- these differcnces are probably due to incongruencies between county_geoms and the ventyx state boundaries

-- any counties w/out ind load?
select *
FROM dg_wind.ind_load_by_county_us
where total_load_mwh_2011_industrial = 0; -- yup -- 9 of them!

-- check them out
CREATE TABLE diffusion_wind_data.counties_without_load_ind AS
SELECT b.*
FROM dg_wind.ind_load_by_county_us a
LEFT join diffusion_shared.county_geom b
ON a.county_id = b.county_id
where a.total_load_mwh_2011_industrial = 0;
-- these are all seemingly legit zero load areas -- the original service territories show no industrial load

----------------------------------------------------------------------------------------------------
-- repeat for number of customers
----------------------------------------------------------------------------------------------------
-- check that there aren't any territories with residential customers but zero load
SELECT count(*)
FROM dg_wind.ventyx_elec_serv_territories_w_2011_sales_data_backfilled_clip
where total_industrial_customers > 0 and (total_industrial_sales_mwh <= 0 or total_industrial_sales_mwh is null)

-- 1 - create the disag raster table
DROP TABLE IF EXISTS dg_wind.disaggregated_customers_industrial_us;
CREATE TABLE dg_wind.disaggregated_customers_industrial_us (
	tile_id integer,
	rast raster);

--- run parsel
select parsel_2('dav-gis',' dg_wind.ventyx_backfilled_ests_diced','state_id',
'WITH clip as (
select a.gid, c.cell_count, b.rid,
	ST_Clip(b.rast, 1, x.the_geom_900914, true) as rast,
	CASE WHEN c.ind_count is null or c.ind_count = 0 THEN ''([rast]+1.)/'' || c.cell_count || ''*'' || a.total_industrial_customers
	ELSE ''[rast]/'' || c.ind_count || ''*'' || a.total_industrial_customers 
	END as map_alg_expr

FROM dg_wind.ventyx_backfilled_ests_diced x

LEFT JOIN dg_wind.ventyx_elec_serv_territories_w_2011_sales_data_backfilled_clip as a
ON x.est_gid = a.gid

INNER JOIN dg_wind.industrial_land_mask_us_100x100 b
ON ST_Intersects(x.the_geom_900914,b.rast)

LEFT JOIN dg_wind.ventyx_ind_cell_counts_us c
ON x.est_gid = c.gid

where c.cell_count > 0 and a.total_industrial_customers >= 0) 
SELECT rid as tile_id, ST_MapAlgebraExpr(rast, ''32BF'', map_alg_expr) as rast
FROM clip;','dg_wind.disaggregated_customers_industrial_us','x',16);
--  runtime = ~13.2 minutes ( 794439.710 ms)

-- add rid primary key column
ALTER TABLE dg_wind.disaggregated_customers_industrial_us
ADD COLUMN rid serial;

ALTER TABLE dg_wind.disaggregated_customers_industrial_us
ADD PRIMARY KEY (rid);

-- 2 - aggregate the results into tiles
DROP TABLE IF EXISTS dg_wind.mosaic_customers_industrial_us;
CREATE TABLE dg_wind.mosaic_customers_industrial_us 
	(rid integer,
	rast raster);

select parsel_2('dav-gis','dg_wind.disaggregated_customers_industrial_us','tile_id',
'SELECT a.tile_id as rid, ST_Union(a.rast,''SUM'') as rast
FROM dg_wind.disaggregated_customers_industrial_us a
GROUP BY a.tile_id;','dg_wind.mosaic_customers_industrial_us','a',16);
-- run time =  200468.907  ms (3.3 mins)

-- create spatial index on this file
CREATE INDEX mosaic_customers_industrial_us_rast_gist
  ON dg_wind.mosaic_customers_industrial_us
  USING gist
  (st_convexhull(rast));

-- 3- then sum to counties
-- create output table
DROP TABLE IF EXISTS dg_wind.ind_customers_by_county_us;
CREATE TABLE dg_wind.ind_customers_by_county_us
(county_id integer,
total_customers_2011_industrial numeric);

-- run parsel
select parsel_2('dav-gis','diffusion_shared.county_geom','county_id',
'WITH tile_stats as (
	select a.county_id,
		ST_SummaryStats(ST_Clip(b.rast, 1, a.the_geom_900914, true)) as stats
	FROM diffusion_shared.county_geom as a
	INNER JOIN dg_wind.mosaic_customers_industrial_us b
	ON ST_Intersects(a.the_geom_900914,b.rast)
)
	--aggregate the results from each tile
SELECT county_id, sum((stats).sum) as total_customers_2011_industrial
FROM tile_stats
GROUP by county_id;'
,'dg_wind.ind_customers_by_county_us','a',16);
-- run time =   113142.556 ms (1.8 mins)

-- 4 - do some verification
SELECT sum(total_customers_2011_industrial)
FROM dg_wind.ind_customers_by_county_us; -- 725967.00115045437643869

select sum(total_industrial_customers)
FROM dg_wind.ventyx_elec_serv_territories_w_2011_sales_data_backfilled_clip
where state_abbr not in ('AK','HI'); -- 725967

select 725967 - 725967.00115045437643869; -- -0.00115045437643869 (difference likely due to rounding)
select (725967 - 725967.00115045437643869)/725967  * 100; -- -0.0000001584719934154982251300 % load is missing nationally

-- cehck on state level
with a as (
select state_abbr, sum(total_industrial_customers)
FROM dg_wind.ventyx_elec_serv_territories_w_2011_sales_data_backfilled_clip
where state_abbr not in ('AK','HI')
GROUP BY state_abbr),

b as (

SELECT k.state_abbr, sum(total_customers_2011_industrial)
FROM dg_wind.ind_customers_by_county_us j
LEFT join diffusion_shared.county_geom k
ON j.county_id = k.county_id
GROUP BY k.state_abbr)

SELECT a.state_abbr, a.sum as est_total, b.sum as county_total, b.sum-a.sum as diff, (b.sum-a.sum)/a.sum * 100 as perc_diff
FROM a
LEFT JOIN b
on a.state_abbr = b.state_abbr
order by perc_diff; --

select *
FROM dg_wind.ind_customers_by_county_us
where total_customers_2011_industrial = 0;
-- yes - 9 - same as for load

