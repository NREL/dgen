-- calculate rates
-- use the ventyx/eia service territory data, where available
CREATE TABLE dg_wind.electricity_rates_2011_backfilled AS
SELECT company_id, state_name, the_geom_4326,
	CASE WHEN total_residential_revenue_000s = 0 and total_residential_sales_mwh = 0 THEN NULL
	   ElSE (total_residential_revenue_000s*1000*100)/(total_residential_sales_mwh*1000)
	 end as res_cents_per_kwh,

	CASE WHEN total_commercial_revenue_000s = 0 and total_commercial_sales_mwh = 0 THEN NULL
	   ElSE (total_commercial_revenue_000s*1000*100)/(total_commercial_sales_mwh*1000)
	 end as comm_cents_per_kwh,

	CASE WHEN total_industrial_revenue_000s = 0 and total_industrial_sales_mwh = 0 THEN NULL
	   ElSE (total_industrial_revenue_000s*1000*100)/(total_industrial_sales_mwh*1000)
	 end as ind_cents_per_kwh,
	 data_year,
	 'Ventyx'::text as source 
	 
FROM dg_wind.electric_service_territories_states_with_rates

UNION
-- backfill all other areas with state averages
SELECT -99999 as company_id, a.state_name, a.the_geom_4326,
	b.res as res_cents_per_kwh,
	b.com as com_cents_per_kwh,
	b.ind as ind_cents_per_kwh,
       2011 as data_year,
       'EIA Table 4 Rates by State 2011'::text as source
FROM dg_wind.ests_missing_data_by_state a
LEFT JOIN eia.table_4_rates_by_state_2011 b
ON a.state_name = b.state;

CREATE INDEX electricity_rates_2011_backfilled_the_geom_4326_gist ON dg_wind.electricity_rates_2011_backfilled using gist(the_geom_4326);


ALTER TABLE dg_wind.electricity_rates_2011_backfilled ADD COLUMN the_geom_900914 geometry;
UPDATE dg_wind.electricity_rates_2011_backfilled  
SET the_geom_900914 = ST_Transform(the_geom_4326,900914);
CREATE INDEX electricity_rates_2011_backfilled_the_geom_900914_gist ON dg_wind.electricity_rates_2011_backfilled using gist(the_geom_900914);

ALTER TABLE dg_wind.electricity_rates_2011_backfilled ADD COLUMN gid serial;

-- export to shapefile
-- in ArcGIS, convert to a coverage, then back to a shapefile
-- delete all columns from the shapefile -- we only care about the geometry
-- reload the shapefile as dg_wind.est_rate_geoms_no_overlaps
-- add spatial indices on st centroid and st point on surface
CREATE INDEX est_rate_geoms_no_overlaps_the_geom_4326_centroid_gist ON dg_wind.est_rate_geoms_no_overlaps USING gist(ST_CEntroid(the_geom_4326));
CREATE INDEX est_rate_geoms_no_overlaps_the_geom_4326_pointonsurface_gist ON dg_wind.est_rate_geoms_no_overlaps USING gist(ST_PointOnSurface (the_geom_4326));

-- then intersect the centroid/point on surface against the original data, 
-- and populate the rates based on averages of all intersections
-- DROP TABLE IF EXISTS dg_wind.electricity_rates_2011_backfilled_no_overlaps;
CREATE TABLE dg_wind.electricity_rates_2011_backfilled_no_overlaps AS
WITH ix AS (
SELECT a.gid, a.the_geom_4326, 
	b.company_id, b.state_name, b.res_cents_per_kwh, b.comm_cents_per_kwh, 
       b.ind_cents_per_kwh, b.data_year, b.source
FROM dg_wind.est_rate_geoms_no_overlaps a
INNER JOIN dg_wind.electricity_rates_2011_backfilled b
ON ST_Intersects(ST_PointOnSurface(a.the_geom_4326),b.the_geom_4326))

SELECT gid, the_geom_4326, array_agg(company_id) as company_id, first(state_name) as state_name,
	avg(res_cents_per_kwh) as res_cents_per_kwh,
	avg(comm_cents_per_kwh) as comm_cents_per_kwh,
	avg(ind_cents_per_kwh) as ind_cents_per_kwh,
	array_agg(data_year) as data_year, array_agg(source) as source
FROM ix
GROUP BY gid, the_geom_4326;


-- export to shapefile again, and in arc, create comm, ind, and res rates rasters for conus, ak, and hi



-----------------------------
-- convert to raster
------------------------------

--------
-- CONUS
--------
-- first:
-- convert to a grid with a separate raster for each polygon, with the entire raster having the value of the polygon
DROP TABLE IF EXISTS dg_wind.electricity_rates_2011_grid_res_us;
CREATE TABLE dg_wind.electricity_rates_2011_grid_res_us (
	tile_id integer,
	rast raster);

		select b.rid,ST_MapAlgebraExpr(rast, ''32BF'', a.res_cents_per_kwh::text) as rast
		FROM dg_wind.electricity_rates_2011_backfilled as a
		INNER JOIN dg_wind.iiijjjicf_200m AS b
		ON ST_Intersects(a.the_geom_900914, b.rast))
		SELECT rid as tile_id, ST_MapAlgebraExpr(rast, ''32BF'', map_alg_expr) as rast
		FROM clip;



--- run parsel
select parsel_2('dav-gis','dg_wind.electricity_rates_2011_backfilled','gid',
		'WITH clip as (
		select b.rid,
			ST_Clip(b.rast, 1, a.the_geom_900914, true) as rast,
			a.res_cents_per_kwh::text AS  map_alg_expr
		FROM dg_wind.electricity_rates_2011_backfilled as a
		INNER JOIN dg_wind.iiijjjicf_200m AS b
		ON ST_Intersects(a.the_geom_900914, b.rast))
		SELECT rid as tile_id, ST_MapAlgebraExpr(rast, ''32BF'', map_alg_expr) as rast
		FROM clip;'
,'dg_wind.electricity_rates_2011_grid_res_us','a',16);

-- CREATE TABLE dg_wind.electricity_rates_2011_grid_res_us AS
-- WITH clip as (
-- select b.rid,
-- 	ST_Clip(b.rast, 1, a.the_geom_900914, true) as rast,
-- 	a.res_cents_per_kwh::text AS  map_alg_expr
-- FROM dg_wind.electricity_rates_2011_backfilled as a
-- INNER JOIN dg_wind.iiijjjicf_200m AS b
-- ON ST_Intersects(a.the_geom_900914, b.rast))
-- SELECT rid as tile_id, ST_MapAlgebraExpr(rast, '32BF', map_alg_expr) as rast
-- FROM clip;


-- aggregate the results into tiles, averaging where ncessary
DROP TABLE IF EXISTS dg_wind.electricity_rates_2011_mosaic_res_us;
CREATE TABLE dg_wind.electricity_rates_2011_mosaic_res_us 
	(rid integer,
	rast raster);

select parsel_2('dav-gis','dg_wind.electricity_rates_2011_grid_res_us','tile_id',
'SELECT a.tile_id as rid, ST_Union(a.rast,''MEAN'') as rast
FROM dg_wind.electricity_rates_2011_grid_res_us a
GROUP BY a.tile_id;','dg_wind.melectricity_rates_2011_mosaic_res_us','a',16);


-- need to repeate for AK and HI: