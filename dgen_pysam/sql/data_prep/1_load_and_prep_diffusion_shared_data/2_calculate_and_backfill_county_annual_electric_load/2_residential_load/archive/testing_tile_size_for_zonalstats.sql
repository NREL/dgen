-- create output table
DROP TABLE IF EXISTS dg_wind.electric_service_territories_res_pop_sums_ak;
CREATE TABLE dg_wind.electric_service_territories_res_pop_sums_ak
(gid integer,
pop numeric,
num_tiles integer);

-- run parsel
select parsel_2('dav-gis','dg_wind.electric_service_territories_states_with_rates_backfilled','gid',
'WITH tile_stats as (
	select a.gid,
		ST_SummaryStats(ST_Clip(b.rast, 1, a.the_geom_4326, true)) as stats
	FROM dg_wind.electric_service_territories_states_with_rates_backfilled as a
	INNER JOIN dg_wind.ls2012_ntime_res_pop_ak b
	ON ST_Intersects(a.the_geom_4326,b.rast)
)
	--aggregate the results from each tile
SELECT gid, sum((stats).sum) as pop, count(gid) as num_tiles
FROM tile_stats
GROUP by gid;'
,'dg_wind.electric_service_territories_res_pop_sums_ak','a',16);

-- 160693.039 ms

-- test 500x500
DROP TABLE IF EXISTS dg_wind.electric_service_territories_res_pop_sums_ak_500x500;
CREATE TABLE dg_wind.electric_service_territories_res_pop_sums_ak_500x500
(gid integer,
pop numeric,
num_tiles integer);

-- run parsel
select parsel_2('dav-gis','dg_wind.electric_service_territories_states_with_rates_backfilled','gid',
'WITH tile_stats as (
	select a.gid,
		ST_SummaryStats(ST_Clip(b.rast, 1, a.the_geom_4326, true)) as stats
	FROM dg_wind.electric_service_territories_states_with_rates_backfilled as a
	INNER JOIN dg_wind.ls2012_ntime_res_pop_ak_500x500 b
	ON ST_Intersects(a.the_geom_4326,b.rast)
)
	--aggregate the results from each tile
SELECT gid, sum((stats).sum) as pop, count(gid) as num_tiles
FROM tile_stats
GROUP by gid;'
,'dg_wind.electric_service_territories_res_pop_sums_ak_500x500','a',16);
--  160766.603 ms (SAME!)

-- test 1000x1000
DROP TABLE IF EXISTS dg_wind.electric_service_territories_res_pop_sums_ak_1000x1000;
CREATE TABLE dg_wind.electric_service_territories_res_pop_sums_ak_1000x1000
(gid integer,
pop numeric,
num_tiles integer);

-- run parsel
select parsel_2('dav-gis','dg_wind.electric_service_territories_states_with_rates_backfilled','gid',
'WITH tile_stats as (
	select a.gid,
		ST_SummaryStats(ST_Clip(b.rast, 1, a.the_geom_4326, true)) as stats
	FROM dg_wind.electric_service_territories_states_with_rates_backfilled as a
	INNER JOIN dg_wind.ls2012_ntime_res_pop_ak_1000x1000 b
	ON ST_Intersects(a.the_geom_4326,b.rast)
)
	--aggregate the results from each tile
SELECT gid, sum((stats).sum) as pop, count(gid) as num_tiles
FROM tile_stats
GROUP by gid;'
,'dg_wind.electric_service_territories_res_pop_sums_ak_1000x1000','a',16);
-- 160811.594 (SAME!)


-- test 2000x2000
DROP TABLE IF EXISTS dg_wind.electric_service_territories_res_pop_sums_ak_2000x2000;
CREATE TABLE dg_wind.electric_service_territories_res_pop_sums_ak_2000x2000
(gid integer,
pop numeric,
num_tiles integer);

-- run parsel
select parsel_2('dav-gis','dg_wind.electric_service_territories_states_with_rates_backfilled','gid',
'WITH tile_stats as (
	select a.gid,
		ST_SummaryStats(ST_Clip(b.rast, 1, a.the_geom_4326, true)) as stats
	FROM dg_wind.electric_service_territories_states_with_rates_backfilled as a
	INNER JOIN dg_wind.ls2012_ntime_res_pop_ak_2000x2000 b
	ON ST_Intersects(a.the_geom_4326,b.rast)
)
	--aggregate the results from each tile
SELECT gid, sum((stats).sum) as pop, count(gid) as num_tiles
FROM tile_stats
GROUP by gid;'
,'dg_wind.electric_service_territories_res_pop_sums_ak_2000x2000','a',16);
--  173214.050 (SLOWER)


-- are they all the same? -- yup
SELECT *
FROM dg_wind.electric_service_territories_res_pop_sums_ak a
LEFT JOIN dg_wind.electric_service_territories_res_pop_sums_ak_500x500 b
ON a.gid = b.gid
LEFT JOIN dg_wind.electric_service_territories_res_pop_sums_ak_1000x1000 c
ON a.gid = c.gid
LEFT JOIN dg_wind.electric_service_territories_res_pop_sums_ak_2000x2000 d
ON a.gid = d.gid
where a.pop <> b.pop
or a.pop <> c.pop
or a.pop <> d.pop