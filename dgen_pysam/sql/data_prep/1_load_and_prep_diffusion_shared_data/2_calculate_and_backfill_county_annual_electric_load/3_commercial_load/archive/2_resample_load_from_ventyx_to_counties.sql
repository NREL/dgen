--------------------------------------------------------------------------------------------------------------------
-- us
--------------------------------------------------------------------------------------------------------------------

-- sum the total population in each electric service territory
-- create output table
DROP TABLE IF EXISTS dg_wind.electric_service_territories_res_pop_sums_us;
CREATE TABLE dg_wind.electric_service_territories_res_pop_sums_us
(gid integer,
pop numeric,
num_tiles integer);

-- run parsel
select parsel_2('dav-gis','dg_wind.electric_service_territories_states_with_rates_backfilled','gid',
'WITH tile_stats as (
	select a.gid,
		ST_SummaryStats(ST_Clip(b.rast, 1, a.the_geom_4326, true)) as stats
	FROM dg_wind.electric_service_territories_states_with_rates_backfilled as a
	INNER JOIN dg_wind.ls2012_ntime_res_pop_us b
	ON ST_Intersects(a.the_geom_4326,b.rast)
)
	--aggregate the results from each tile
SELECT gid, sum((stats).sum) as pop, count(gid) as num_tiles
FROM tile_stats
GROUP by gid;'
,'dg_wind.electric_service_territories_res_pop_sums_us','a',16);
-- 426240.450 ms

-- check results
CREATE OR REPLACE VIEW dg_wind.ests_w_res_pops_us AS
SELECT a.*, b.pop, b.num_tiles
FROM dg_wind.electric_service_territories_states_with_rates_backfilled a
inner join dg_wind.electric_service_territories_res_pop_sums_us b
on a.gid = b.gid;

-- perform map algebra to estimate the percent of each raster
DROP TABLE IF EXISTS dg_wind.disaggregated_load_residential_us;
CREATE TABLE dg_wind.disaggregated_load_residential_us (
	tile_id integer,
	rast raster);

--- run parsel
select parsel_2('dav-gis','dg_wind.electric_service_territories_states_with_rates_backfilled','gid',
'WITH clip as (
select a.gid, c.pop, b.rid,
	ST_Clip(b.rast, 1, a.the_geom_4326, true) as rast,
	''[rast]/'' || c.pop || ''*'' || a.total_residential_sales_mwh as map_alg_expr
FROM dg_wind.electric_service_territories_states_with_rates_backfilled as a

INNER JOIN dg_wind.ls2012_ntime_res_pop_us b
ON ST_Intersects(a.the_geom_4326,b.rast)

LEFT JOIN dg_wind.electric_service_territories_res_pop_sums_us c
ON a.gid = c.gid

where c.pop >0 and a.total_residential_sales_mwh >= 0) 
SELECT rid as tile_id, ST_MapAlgebraExpr(rast, ''32BF'', map_alg_expr) as rast
FROM clip;','dg_wind.disaggregated_load_residential_us','a',16);
--  2286672.733 ms

-- add rid primary key column
ALTER TABLE dg_wind.disaggregated_load_residential_us
ADD COLUMN rid serial;

ALTER TABLE dg_wind.disaggregated_load_residential_us
ADD PRIMARY KEY (rid);

-- aggregate the results into tiles
DROP TABLE IF EXISTS dg_wind.mosaic_load_residential_us;
CREATE TABLE dg_wind.mosaic_load_residential_us 
	(rid integer,
	rast raster);

select parsel_2('dav-gis','dg_wind.disaggregated_load_residential_us','tile_id',
'SELECT a.tile_id as rid, ST_Union(a.rast,''SUM'') as rast
FROM dg_wind.disaggregated_load_residential_us a
GROUP BY a.tile_id;','dg_wind.mosaic_load_residential_us','a',16);
--1343822.576 ms

-------------------------------------------------------------------------------------------
-- to review the data visually:
-- cannot union, so export tiles to geotiffs
SELECT write_file(ST_AsTiff(rast), '/srv/data/transfer/mgleason/dg_wind/res_load_us/us_load_' || rid || '.tif','777')
FROM dg_wind.mosaic_load_residential_us;

-- transfer data over to gissde
-- tar the files up in linux: tar -zcvf res_load_us.tar.gz res_load_us
-- scp the data to windows
-- untar using cygwin -- tar -xvzf res_load_us.tar.gz
-- remove the original tarballs from windows and linux, and folder for linux: rm -r on linux, delete on gissde for windows
-- ********* pick up here tomorrow:
-- mosaic the rasters using mosaic_rasters_us.py
-- review data in arc or q
-------------------------------------------------------------------------------------------


-- compare national level total in raster to state level total from ventyx
With a as (
	SELECT ST_SummaryStats(rast) as stats
	from dg_wind.mosaic_load_residential_us
)
SELECT sum((a.stats).sum)
FROM a;
--1437981257.0278 mwh	

With a as (
	SELECT ST_SummaryStats(rast) as stats
	from dg_wind.disaggregated_load_residential_us
)
SELECT sum((a.stats).sum)
FROM a;
--1437981256.55201 mwh
	
SELECT sum(total_residential_sales_mwh)
FROM dg_wind.electric_service_territories_states_with_rates_backfilled
where state_abbr not in ('AK','HI')
and total_residential_sales_mwh > 0; -- ignore negative load values
-- 1441470645.000000000000 (why are they different?)

-- the total count matches based on intersection
with d as (
	SELECT distinct ON (a.gid) a.total_residential_sales_mwh
	FROM dg_wind.electric_service_territories_states_with_rates_backfilled a, dg_wind.ls2012_ntime_res_pop_us b
	where ST_Intersects(a.the_geom_4326,b.rast))
select sum(total_residential_sales_mwh)
FROm d
where total_residential_sales_mwh > 0;
-- 1441470645.000000000000

-- the issue is because some territories apparently have no population
with d as (
	SELECT distinct ON (a.gid) a.total_residential_sales_mwh
	FROM dg_wind.electric_service_territories_states_with_rates_backfilled a
	inner join dg_wind.ls2012_ntime_res_pop_us b
	ON ST_Intersects(a.the_geom_4326,b.rast)
	left join dg_wind.electric_service_territories_res_pop_sums_us c
	ON a.gid = c.gid
	where c.pop > 0)
select sum(total_residential_sales_mwh)
FROm d
where total_residential_sales_mwh > 0;
--1437981257.000000000000

-- but which ones?
with d as (
	SELECT distinct ON (a.gid) a.gid, a.total_residential_sales_mwh, c.pop
	FROM dg_wind.electric_service_territories_states_with_rates_backfilled a
	inner join dg_wind.ls2012_ntime_res_pop_us b
	ON ST_Intersects(a.the_geom_4326,b.rast)
	left join dg_wind.electric_service_territories_res_pop_sums_us c
	ON a.gid = c.gid)
select gid, total_residential_sales_mwh, pop
FROm d
where pop <= 0;

Select 1441470645-1437981257;

-- these are all slivers around state borders based on backfilling with EIA state totals -- the biggest ones are around CA (919598.000000000000 mwh)
-- and around southern MD/northern WV (1810007 mwh)


