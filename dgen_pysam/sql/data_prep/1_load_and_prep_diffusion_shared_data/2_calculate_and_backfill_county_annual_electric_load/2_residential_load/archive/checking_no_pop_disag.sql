SELECT a.rid
FROM dg_wind.mosaic_load_residential_us a
INNER JOIN dg_wind.ests_w_no_pop b
ON ST_Intersects(a.rast, b.the_geom_4326)
where b.state_abbr = 'OR';


SELECT a.rid
FROM dg_wind.disaggregated_load_residential_us a
INNER JOIN dg_wind.ests_w_no_pop b
ON ST_Intersects(a.rast, b.the_geom_4326)
where b.state_abbr = 'OR';

-- export
SELECT write_file(ST_AsTiff(rast), '/srv/home/mgleason/data/dg_wind/res_load_or/res_load_mwh_' || rid || '.tif','777')
FROM dg_wind.mosaic_load_residential_us
where rid in (29446,
30145,
30144,
29444,
29443,
29445,
30143);
-- FROM dg_wind.mosaic_load_residential_ak;


DROP TABLE IF EXISTS dg_wind.test;
CREATE TABLE dg_wind.test AS 
WITH clip as (
select a.gid, c.pop, c.cell_count, b.rid,
	ST_Clip(b.rast, 1, x.the_geom_4326, true) as rast,
	CASE WHEN c.pop is null or c.pop = 0 THEN '([rast]+1.)/' || c.cell_count || '*' || a.total_residential_sales_mwh
	ELSE '[rast]/' || c.pop || '*' || a.total_residential_sales_mwh 
	END as map_alg_expr

FROM dg_wind.ventyx_backfilled_ests_diced x

LEFT JOIN dg_wind.ventyx_elec_serv_territories_w_2011_sales_data_backfilled_clip as a
ON x.est_gid = a.gid

INNER JOIN dg_wind.ls2012_ntime_res_pop_us_100x100 b
ON ST_Intersects(x.the_geom_4326,b.rast)

LEFT JOIN dg_wind.ventyx_res_pop_sums_us c
ON x.est_gid = c.gid

where c.cell_count > 0 and a.total_residential_sales_mwh >= 0
AND x.est_gid = 1991) 
SELECT rid as tile_id, ST_MapAlgebraExpr(rast, '32BF', map_alg_expr) as rast
FROM clip;

ALTER TABLE dg_wind.test ADD COLUMN rid serial;

-- CREATE TABLE dg_wind.test_mos AS
-- SELECT a.tile_id as rid, ST_Union(a.rast,'SUM') as rast
-- FROM dg_wind.test a
-- GROUP BY a.tile_id;


SELECT write_file(ST_AsTiff(rast), '/srv/home/mgleason/data/dg_wind/res_load_or/res_load_mwh_' || rid || '.tif','777')
FROM dg_wind.test