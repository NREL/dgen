--------------------------------------------------------------------------------------------------------------------
-- us
--------------------------------------------------------------------------------------------------------------------

-- sum the total population in each electric service territory
-- create output table
DROP TABLE IF EXISTS dg_wind.electric_service_territories_res_pop_sums_us CASCADE;
CREATE TABLE dg_wind.electric_service_territories_res_pop_sums_us
(gid integer,
pop numeric,
num_tiles integer);

-- run parsel
select parsel_2('dav-gis','dg_wind.ventyx_ests_2011_sales_data_backfilled','gid',
'WITH tile_stats as (
	select a.gid,
		ST_SummaryStats(ST_Clip(b.rast, 1, a.the_geom_4326, true)) as stats
	FROM dg_wind.ventyx_ests_2011_sales_data_backfilled as a
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
select parsel_2('dav-gis','dg_wind.ventyx_ests_2011_sales_data_backfilled','gid',
'WITH clip as (
select a.gid, c.pop, b.rid,
	ST_Clip(b.rast, 1, a.the_geom_4326, true) as rast,
	''[rast]/'' || c.pop || ''*'' || a.total_residential_sales_mwh as map_alg_expr
FROM dg_wind.ventyx_ests_2011_sales_data_backfilled as a

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

-- create spatial index on this file
CREATE INDEX mosaic_load_residential_us_rast_gist
  ON dg_wind.mosaic_load_residential_us
  USING gist
  (st_convexhull(rast));

-- then sum to counties
-- create output table
DROP TABLE IF EXISTS dg_wind.load_by_county_us;
CREATE TABLE dg_wind.load_by_county_us
(county_id integer,
total_load_mwh_2011_residential numeric);

-- run parsel
select parsel_2('dav-gis','wind_ds.county_geom','county_id',
'WITH tile_stats as (
	select a.county_id,
		ST_SummaryStats(ST_Clip(b.rast, 1, a.the_geom_4326, true)) as stats
	FROM wind_ds.county_geom as a
	INNER JOIN dg_wind.mosaic_load_residential_us b
	ON ST_Intersects(a.the_geom_4326,b.rast)
)
	--aggregate the results from each tile
SELECT county_id, sum((stats).sum) as total_load_mwh_2011_residential
FROM tile_stats
GROUP by county_id;'
,'dg_wind.load_by_county_us','a',16);


-- -- compare to the OLD county level res load data
-- ALTER TABLE wind_ds.load_by_county_us SET SCHEMA wind_ds_data;
-- ALTER TABLE wind_ds_data.load_by_county_us RENAME TO load_by_county_us_old;
-- 
-- SELECT *
-- FROM dg_wind.load_by_county_us a
-- LEFT JOIN wind_ds_data.load_by_county_us_old b
-- ON a.county_id = b.county_id; -- pretty similar -- looks good to me


-- **
-- do some additional verification
SELECT sum(total_load_mwh_2011_residential)
FROM dg_wind.load_by_county_us; -- 1,415,496,286.3013808567986

select sum(total_residential_sales_mwh)
FROM dg_wind.ventyx_ests_2011_sales_data_backfilled
where state_abbr not in ('AK','HI'); -- 1,417,737,928

select 1417737928 - 1415496286.3013808567986; -- 2,241,641.6986191432014
select (1417737928 - 1415496286.3013808567986)/1415496286.3013808567986 * 100; -- .15 % load is missing nationally

-- but why?
-- the issue is because some territories apparently have no population
DROP TABLE IF EXISTS dg_wind.ests_w_no_pop;
CREATE TABLE dg_wind.ests_w_no_pop AS
	SELECT a.gid, 
		a.the_geom_4326, 
		a.total_residential_sales_mwh, c.pop
	FROM dg_wind.ventyx_ests_2011_sales_data_backfilled a
	left join dg_wind.electric_service_territories_res_pop_sums_us c
	ON a.gid = c.gid
	where (c.pop is null or c.pop = 0)
	and a.state_abbr not in ('AK','HI');
-- ** inspect these in Q?
-- these are all sliver polygons around state borders -- suggesting that we don't actually know where this extra load should go

-- does the sum of the res load = the missing amount of 2,241,641?
select sum(total_residential_sales_mwh)
FROM  dg_wind.ests_w_no_pop; -- 1,943,970
-- not quite
-- the remaining difference is likely due to the zonal stats analysis for the counties 
-- some portions of the night time res pop grid may extend slightly beyond county boundaries
-- check this -- compare total pop from the res pop grid to the total pop within the county boundaries


WITH a as (
	SELECT ST_SummaryStats(rast) as sumstats
	FROM dg_wind.ls2012_ntime_res_pop_us)

SELECT sum((sumstats).sum)
FROM a; -- 274,599,234


DROP TABLE IF EXISTS dg_wind.county_res_pop_sums_us;
CREATE TABLE dg_wind.county_res_pop_sums_us
(county_id integer,
pop numeric);

-- run parsel
select parsel_2('dav-gis','wind_ds.county_geom','county_id',
'WITH tile_stats as (
	select a.county_id,
		ST_SummaryStats(ST_Clip(b.rast, 1, a.the_geom_4326, true)) as stats
	FROM wind_ds.county_geom as a
	INNER JOIN dg_wind.ls2012_ntime_res_pop_us b
	ON ST_Intersects(a.the_geom_4326,b.rast)
)
	--aggregate the results from each tile
SELECT county_id, sum((stats).sum) as pop
FROM tile_stats
GROUP by county_id;'
,'dg_wind.county_res_pop_sums_us','a',16);

select sum(pop)
FROM dg_wind.county_res_pop_sums_us; -- 274,529,518 (smaller, so this hypothesis is still potentially true)
-- to fix this part of the problem, would need to clip ls2012_ntime_res_pop_us to union of county_geom before the first step here




-- do we need to find a way to get these data back in -- area weighted?





-- repeat for number of customers
-- do not need to re-do EST pop sums

-- perform map algebra to estimate the percent of each raster
DROP TABLE IF EXISTS dg_wind.disaggregated_customers_residential_us;
CREATE TABLE dg_wind.disaggregated_customers_residential_us (
	tile_id integer,
	rast raster);

--- run parsel
select parsel_2('dav-gis','dg_wind.ventyx_ests_2011_sales_data_backfilled','gid',
'WITH clip as (
select a.gid, c.pop, b.rid,
	ST_Clip(b.rast, 1, a.the_geom_4326, true) as rast,
	''[rast]/'' || c.pop || ''*'' || a.total_residential_sales_mwh as map_alg_expr
FROM dg_wind.ventyx_ests_2011_sales_data_backfilled as a

INNER JOIN dg_wind.ls2012_ntime_res_pop_us b
ON ST_Intersects(a.the_geom_4326,b.rast)

LEFT JOIN dg_wind.electric_service_territories_res_pop_sums_us c
ON a.gid = c.gid

where c.pop >0 and a.total_residential_sales_mwh >= 0) 
SELECT rid as tile_id, ST_MapAlgebraExpr(rast, ''32BF'', map_alg_expr) as rast
FROM clip;','dg_wind.disaggregated_customers_residential_us','a',16);
--  2286672.733 ms

-- add rid primary key column
ALTER TABLE dg_wind.disaggregated_customers_residential_us
ADD COLUMN rid serial;

ALTER TABLE dg_wind.disaggregated_customers_residential_us
ADD PRIMARY KEY (rid);

-- aggregate the results into tiles
DROP TABLE IF EXISTS dg_wind.mosaic_load_residential_us;
CREATE TABLE dg_wind.mosaic_load_residential_us 
	(rid integer,
	rast raster);

select parsel_2('dav-gis','dg_wind.disaggregated_customers_residential_us','tile_id',
'SELECT a.tile_id as rid, ST_Union(a.rast,''SUM'') as rast
FROM dg_wind.disaggregated_customers_residential_us a
GROUP BY a.tile_id;','dg_wind.mosaic_load_residential_us','a',16);
--1343822.576 ms

-- create spatial index on this file
CREATE INDEX mosaic_load_residential_us_rast_gist
  ON dg_wind.mosaic_load_residential_us
  USING gist
  (st_convexhull(rast));

-- then sum to counties
-- create output table
DROP TABLE IF EXISTS dg_wind.load_by_county_us;
CREATE TABLE dg_wind.load_by_county_us
(county_id integer,
total_load_mwh_2011_residential numeric);

-- run parsel
select parsel_2('dav-gis','wind_ds.county_geom','county_id',
'WITH tile_stats as (
	select a.county_id,
		ST_SummaryStats(ST_Clip(b.rast, 1, a.the_geom_4326, true)) as stats
	FROM wind_ds.county_geom as a
	INNER JOIN dg_wind.mosaic_load_residential_us b
	ON ST_Intersects(a.the_geom_4326,b.rast)
)
	--aggregate the results from each tile
SELECT county_id, sum((stats).sum) as total_load_mwh_2011_residential
FROM tile_stats
GROUP by county_id;'
,'dg_wind.load_by_county_us','a',16);








-- move this result over to wind_ds or maybe wait until total customers are complete too...


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






-- -- this is old code that needs to be updated
-- --------------------------------------------------------------------------------------------------------------------
-- -- HI
-- --------------------------------------------------------------------------------------------------------------------
-- -- sum the total population in each electric service territory
-- -- create output table
-- DROP TABLE IF EXISTS dg_wind.electric_service_territories_res_pop_sums_hi;
-- CREATE TABLE dg_wind.electric_service_territories_res_pop_sums_hi
-- (gid integer,
-- pop numeric,
-- num_tiles integer);
-- 
-- -- run parsel
-- select parsel_2('dav-gis','dg_wind.electric_service_territories_states_with_rates_backfilled','gid',
-- 'WITH tile_stats as (
-- 	select a.gid,
-- 		ST_SummaryStats(ST_Clip(b.rast, 1, a.the_geom_4326, true)) as stats
-- 	FROM dg_wind.electric_service_territories_states_with_rates_backfilled as a
-- 	INNER JOIN dg_wind.ls2012_ntime_res_pop_hi b
-- 	ON ST_Intersects(a.the_geom_4326,b.rast)
-- )
-- 	--aggregate the results from each tile
-- SELECT gid, sum((stats).sum) as pop, count(gid) as num_tiles
-- FROM tile_stats
-- GROUP by gid;'
-- ,'dg_wind.electric_service_territories_res_pop_sums_hi','a',16);
-- 
-- -- check results
-- CREATE OR REPLACE VIEW dg_wind.ests_w_res_pops_hi AS
-- SELECT a.*, b.pop, b.num_tiles
-- FROM dg_wind.electric_service_territories_states_with_rates_backfilled a
-- INNER join dg_wind.electric_service_territories_res_pop_sums_hi b
-- on a.gid = b.gid;
-- 
-- -- perform map algebra to estimate the percent of each raster
-- DROP TABLE IF EXISTS dg_wind.disaggregated_load_residential_hi;
-- CREATE TABLE dg_wind.disaggregated_load_residential_hi (
-- 	tile_id integer,
-- 	rast raster);
-- 
-- select parsel_2('dav-gis','dg_wind.electric_service_territories_states_with_rates_backfilled','gid',
-- 'WITH clip as (
-- select a.gid, c.pop, b.rid,
-- 	ST_Clip(b.rast, 1, a.the_geom_4326, true) as rast,
-- 	''[rast]/'' || c.pop || ''*'' || a.total_residential_sales_mwh as map_alg_expr
-- FROM dg_wind.electric_service_territories_states_with_rates_backfilled as a
-- 
-- INNER JOIN dg_wind.ls2012_ntime_res_pop_hi b
-- ON ST_Intersects(a.the_geom_4326,b.rast)
-- 
-- LEFT JOIN dg_wind.electric_service_territories_res_pop_sums_hi c
-- ON a.gid = c.gid
-- 
-- where c.pop >0 and a.total_residential_sales_mwh >= 0) 
-- SELECT rid as tile_id, ST_MapAlgebraExpr(rast, ''32BF'', map_alg_expr) as rast
-- FROM clip;','dg_wind.disaggregated_load_residential_hi','a',16);
-- 
-- -- add rid primary key column
-- ALTER TABLE dg_wind.disaggregated_load_residential_hi
-- ADD COLUMN rid serial;
-- 
-- ALTER TABLE dg_wind.disaggregated_load_residential_hi
-- ADD PRIMARY KEY (rid);
-- 
-- -- aggregate the results into tiles
-- DROP TABLE IF EXISTS dg_wind.mosaic_load_residential_hi;
-- CREATE TABLE dg_wind.mosaic_load_residential_hi 
-- 	(rid integer,
-- 	rast raster);
-- 	
-- select parsel_2('dav-gis','dg_wind.disaggregated_load_residential_hi','tile_id',
-- 'SELECT a.tile_id as rid, ST_Union(a.rast,''SUM'') as rast
-- FROM dg_wind.disaggregated_load_residential_hi a
-- GROUP BY a.tile_id;','dg_wind.mosaic_load_residential_hi','a',16);
-- 
-- -- write to tif to examine results
-- SELECT write_file(ST_AsTiff(ST_Union(rast)), '/srv/data/transfer/mgleason/dg_wind/res_load_hi/kwh_load_all.tif','777')
-- FROM dg_wind.mosaic_load_residential_hi;
-- 
-- -- compare state level total in raster to state level total from ventyx
-- select sum((ST_SummaryStats(rast)).sum)
-- from dg_wind.mosaic_load_residential_hi;
-- --2928742.99741745 mwh
-- 
-- SELECT sum(total_residential_sales_mwh)
-- FROM dg_wind.electric_service_territories_states_with_rates_backfilled
-- where state_abbr = 'HI'
-- and total_residential_sales_mwh > 0;
-- --2928743 mwh (looks good)
-- 
-- 
-- --------------------------------------------------------------------------------------------------------------------
-- -- AK
-- --------------------------------------------------------------------------------------------------------------------
-- -- sum the total population in each electric service territory
-- -- create output table
-- DROP TABLE IF EXISTS dg_wind.electric_service_territories_res_pop_sums_ak;
-- CREATE TABLE dg_wind.electric_service_territories_res_pop_sums_ak
-- (gid integer,
-- pop numeric,
-- num_tiles integer);
-- 
-- -- run parsel
-- select parsel_2('dav-gis','dg_wind.electric_service_territories_states_with_rates_backfilled','gid',
-- 'WITH tile_stats as (
-- 	select a.gid,
-- 		ST_SummaryStats(ST_Clip(b.rast, 1, a.the_geom_4326, true)) as stats
-- 	FROM dg_wind.electric_service_territories_states_with_rates_backfilled as a
-- 	INNER JOIN dg_wind.ls2012_ntime_res_pop_ak b
-- 	ON ST_Intersects(a.the_geom_4326,b.rast)
-- )
-- 	--aggregate the results from each tile
-- SELECT gid, sum((stats).sum) as pop, count(gid) as num_tiles
-- FROM tile_stats
-- GROUP by gid;'
-- ,'dg_wind.electric_service_territories_res_pop_sums_ak','a',16);
-- -- 160811.594 ms
-- 
-- -- check results
-- CREATE OR REPLACE VIEW dg_wind.ests_w_res_pops_ak AS
-- SELECT a.*, b.pop, b.num_tiles
-- FROM dg_wind.electric_service_territories_states_with_rates_backfilled a
-- INNER join dg_wind.electric_service_territories_res_pop_sums_ak b
-- on a.gid = b.gid;
-- 
-- -- perform map algebra to estimate the percent of each raster
-- DROP TABLE IF EXISTS dg_wind.disaggregated_load_residential_ak;
-- CREATE TABLE dg_wind.disaggregated_load_residential_ak (
-- 	tile_id integer,
-- 	rast raster);
-- 
-- select parsel_2('dav-gis','dg_wind.electric_service_territories_states_with_rates_backfilled','gid',
-- 'WITH clip as (
-- select a.gid, c.pop, b.rid,
-- 	ST_Clip(b.rast, 1, a.the_geom_4326, true) as rast,
-- 	''[rast]/'' || c.pop || ''*'' || a.total_residential_sales_mwh as map_alg_expr
-- FROM dg_wind.electric_service_territories_states_with_rates_backfilled as a
-- 
-- INNER JOIN dg_wind.ls2012_ntime_res_pop_ak b
-- ON ST_Intersects(a.the_geom_4326,b.rast)
-- 
-- LEFT JOIN dg_wind.electric_service_territories_res_pop_sums_ak c
-- ON a.gid = c.gid
-- 
-- where c.pop >0 and a.total_residential_sales_mwh >= 0) 
-- SELECT rid as tile_id, ST_MapAlgebraExpr(rast, ''32BF'', map_alg_expr) as rast
-- FROM clip;','dg_wind.disaggregated_load_residential_ak','a',16);
-- --904898.806 ms
-- 
-- -- add rid primary key column
-- ALTER TABLE dg_wind.disaggregated_load_residential_ak
-- ADD COLUMN rid serial;
-- 
-- ALTER TABLE dg_wind.disaggregated_load_residential_ak
-- ADD PRIMARY KEY (rid);
-- 
-- -- aggregate the results into tiles
-- DROP TABLE IF EXISTS dg_wind.mosaic_load_residential_ak;
-- CREATE TABLE dg_wind.mosaic_load_residential_ak 
-- 	(rid integer,
-- 	rast raster);
-- 	
-- select parsel_2('dav-gis','dg_wind.disaggregated_load_residential_ak','tile_id',
-- 'SELECT a.tile_id as rid, ST_Union(a.rast,''SUM'') as rast
-- FROM dg_wind.disaggregated_load_residential_ak a
-- GROUP BY a.tile_id;','dg_wind.mosaic_load_residential_ak','a',16);
-- 
-- -------------------------------------------------------------------------------------------
-- -- to review the data visually:
-- --  write tilest o disk
-- SELECT write_file(ST_AsTiff(rast), '/srv/data/transfer/mgleason/dg_wind/res_load_ak/ak_load_' || rid || '.tif','777')
-- FROM dg_wind.mosaic_load_residential_ak;
-- 
-- -- transfer data over to gissde
-- -- tar the files up in linux: tar -zcvf res_load_us.tar.gz res_load_us
-- -- scp the data to windows
-- -- untar using cygwin -- tar -xvzf res_load_us.tar.gz
-- -- remove the original tarballs from windows and linux, and folder for linux: rm -r on linux, delete on gissde for windows
-- 
-- -- mosaic the rasters using mosaic_rasters.py
-- -- review in arc or q
-- -------------------------------------------------------------------------------------------
-- 
-- -- compare state level total in raster to state level total from ventyx
-- select sum((ST_SummaryStats(rast)).sum)
-- from dg_wind.mosaic_load_residential_ak;
-- -- 2134407.99894651 mwh	
-- 	
-- SELECT sum(total_residential_sales_mwh)
-- FROM dg_wind.electric_service_territories_states_with_rates_backfilled
-- where state_abbr = 'AK'
-- and total_residential_sales_mwh > 0; -- ignore negative load values
-- --2134408 mwh (looks good)
