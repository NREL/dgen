-- merge all of the geometries from hotels/motels (navteq and hsip), industrial complexes, college boundaries, and prison areas
DROP TABLE IF EXISTS dg_wind.nonres_facilities;
CREATE TABLE dg_wind.nonres_facilities AS

SELECT ST_Buffer(the_geom_4326::geography, 90)::geometry as the_geom_4326, 'hsip_2012.navteq_travdest (hotel)'::text as source
FROM hsip_2012.navteq_travdest
where fac_type = 7011

UNION all

SELECT ST_Buffer(the_geom_4326::geography, 90)::geometry as the_geom_4326, 'hsip_2012.comm_hotelmotel'::text as source
FROM hsip_2012.comm_hotelmotel

UNION all

SELECT the_geom_4326,'hsip_2012.mnfg_industrial_complexes'::text as source
FROM hsip_2012.mnfg_industrial_complexes

UNION all

SELECT the_geom_4326,'hsip_2012.educ_college_boundaries'::text as source
FROM hsip_2012.educ_college_boundaries

UNION all

SELECT the_geom_4326,'hsip_2012.lawe_prison_areas'::text as source
FROM hsip_2012.lawe_prison_areas;

-- add a gid
ALTER TABLE dg_wind.nonres_facilities
ADD COLUMN gid serial;

-- add a spatial index
CREATE INDEX nonres_facilities_the_geom_4326_gist 
on dg_wind.nonres_facilities uSING gist(the_geom_4326);


-- convert to rasters
CREATE TABLE dg_wind.nonres_facilities_rast_hi AS
SELECT b.rid, ST_Union(ST_AsRaster(a.the_geom_4326,b.rast,'2BUI')) as rast
FROM dg_wind.nonres_facilities a
INNER JOIN landscan.hsip_2012_hi_night b
ON ST_Intersects(a.the_geom_4326,b.rast)
GROUP BY b.rid;

CREATE TABLE dg_wind.nonres_facilities_rast_ak AS
SELECT b.rid, ST_Union(ST_AsRaster(a.the_geom_4326,b.rast,'2BUI')) as rast
FROM dg_wind.nonres_facilities a
INNER JOIN landscan.hsip_2012_ak_night b
ON ST_Intersects(a.the_geom_4326,b.rast)
GROUP BY b.rid;

CREATE TABLE dg_wind.nonres_facilities_rast_us AS
SELECT b.rid, ST_Union(ST_AsRaster(a.the_geom_4326,b.rast,'2BUI')) as rast
FROM dg_wind.nonres_facilities a
INNER JOIN landscan.hsip_2012_conus_night b
ON ST_Intersects(a.the_geom_4326,b.rast)
GROUP BY b.rid;

-- create indices for the raster data
CREATE INDEX nonres_facilities_rast_us_rast_gist
  ON dg_wind.nonres_facilities_rast_us
  USING gist
  (st_convexhull(rast));
  VACUUM ANALYZE dg_wind.nonres_facilities_rast_us;

CREATE INDEX nonres_facilities_rast_hi_rast_gist
  ON dg_wind.nonres_facilities_rast_hi
  USING gist
  (st_convexhull(rast));
  VACUUM ANALYZE dg_wind.nonres_facilities_rast_hi;

CREATE INDEX nonres_facilities_rast_ak_rast_gist
  ON dg_wind.nonres_facilities_rast_ak
  USING gist
  (st_convexhull(rast));
  VACUUM ANALYZE dg_wind.nonres_facilities_rast_ak;

-- write to tiff
SELECT write_file(ST_AsTIFF(ST_Union(rast)), '/srv/data/transfer/mgleason/dg_wind/non_res_facilities/non_res_hi.tif','777')
FROM dg_wind.nonres_facilities_rast_hi;

SELECT write_file(ST_AsTIFF(ST_Union(rast)), '/srv/data/transfer/mgleason/dg_wind/non_res_facilities/non_res_ak.tif','777')
FROM dg_wind.nonres_facilities_rast_ak;

-- this one causes a memory error -- see below
SELECT write_file(ST_AsTIFF(ST_Union(rast)), '/srv/data/transfer/mgleason/dg_wind/non_res_facilities/non_res_us.tif','777')
FROM dg_wind.nonres_facilities_rast_us;


-- retile the data to consist of 4 big tiles
-- max tile size: 65535x65535
-- full raster size for nominal 90 m grid for conus: 69900, 30300

CREATE TABLE dg_wind.nonres_facilities_rast_us_quads as
WITH quads as (
	WITH a as (
	SELECT rid,ST_Envelope(rast) as extent
	FROM dg_wind.nonres_facilities_rast_us
	order by rid),
	b as (
	SELECT 1 as gid, ST_SetSrid(ST_Extent(extent),4326) as the_geom_4326
	from a),
	c as (
	SELECT ST_XMax(the_geom_4326) as xmax, ST_XMin(the_geom_4326) as xmin, ST_YMax(the_geom_4326) as ymax, ST_YMin(the_geom_4326) as ymin
	FROM b),
	d as (
	SELECT unnest(array[1,2,3,4]) as gid,unnest(array[xmin,xmin+(xmax-xmin)/2.,xmin,xmin+(xmax-xmin)/2.]) as xmin,unnest(array[ymin,ymin,ymin+(ymax-ymin)/2.,ymin+(ymax-ymin)/2.]) as ymin,unnest(array[xmin+(xmax-xmin)/2.,xmax,xmin+(xmax-xmin)/2.,xmax]) as xmax,unnest(array[ymin+(ymax-ymin)/2.,ymin+(ymax-ymin)/2.,ymax,ymax]) as ymax,unnest(array[4326,4326,4326,4326]) as srid
	FROM c)
	SELECT gid, ST_MakeEnvelope(xmin, ymin, xmax, ymax, srid) as the_geom_4326
	FROM d)
select a.gid as rid, ST_Union(ST_Clip(b.rast,a.the_geom_4326)) as the_rast
from quads a
INNER JOIN dg_wind.nonres_facilities_rast_us b
ON ST_Intersects(a.the_geom_4326, b.rast)
GROUP by a.gid;


SELECT 


CREATE FUNCTION 

-- export to shapefile 
-- in Arc:
-- set snap raster, extent, etc. to convert to raster
-- then combine with the night/day ratio rasters to create a final mask of non residential