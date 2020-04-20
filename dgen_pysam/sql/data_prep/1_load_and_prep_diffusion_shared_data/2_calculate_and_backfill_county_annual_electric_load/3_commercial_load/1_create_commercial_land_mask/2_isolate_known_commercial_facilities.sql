-- isolate commercial points from navteq based on fac_types that map to cbecs
CREATE OR REPLACE VIEW dg_wind.navteq_commercial_facilities AS
SELECT a.feature, b.*
FROM dg_wind.navteq_fac_type_to_cbecs_pba a
LEFT JOIN hsip_2012.all_navteq_pts b
ON a.fac_type = b.fac_type
WHERE a.building_type is not null;

-- isolate commercial points from hsip 2012 based on 2-digit naics codes (42 and up)
CREATE OR REPLACE VIEW hsip_2012.all_hsip_commercial_facilities AS
SELECT *
FROM hsip_2012.all_points_with_naics a
WHERE substring(a.naicscode_3 for 2)::integer >= 42 -- this is based on NAICS 2-digit lookup (http://www.census.gov/cgi-bin/sssd/naics/naicsrch?chart=2012)
and table_name <> 'enrg_gas_prod'; -- ensures that gas fields don't get included

-- merge the two sets of commercial points
DROP TABLE IF EXISTS dg_wind.hsip_and_navteq_commercial_facilities;
CREATE TABLE dg_wind.hsip_and_navteq_commercial_facilities AS
SELECT the_geom_4326, 'HSIP2012'::text as source, table_name, table_number
FROM hsip_2012.all_hsip_commercial_facilities

UNION

SELECT the_geom_4326, 'NAVTEQ2012'::text as source, table_name, table_number
FROM dg_wind.navteq_commercial_facilities;
-- 4,835,920 rows

DELETE FROM dg_wind.hsip_and_navteq_commercial_facilities
where ST_GEometryType(the_geom_4326) is  null; -- delete one null geom row

-- create gid column and gist index
ALTER TABLE dg_wind.hsip_and_navteq_commercial_facilities ADD COLUMN gid serial;
CREATE INDEX hsip_and_navteq_commercial_facilities_the_geom_4326_gist ON dg_wind.hsip_and_navteq_commercial_facilities USING gist(the_geom_4326);
VACUUM ANALYZE dg_wind.hsip_and_navteq_commercial_facilities;

-- buffer the points 
DROP TABLE IF EXISTS dg_wind.hsip_and_navteq_commercial_facility_buffers CASCADE;
CREATE TABLE dg_wind.hsip_and_navteq_commercial_facility_buffers
(
  gid integer,
  the_geom_4326 geometry,
  source text,
  table_name text,
  table_number integer
);

SELECT parsel_2('dav-gis','mgleason','mgleason','dg_wind.hsip_and_navteq_commercial_facilities','gid',
	'SELECT a.gid,
		CASE WHEN ST_GeometryType(a.the_geom_4326) = ''ST_Point'' THEN ST_Buffer(a.the_geom_4326::geography, 90)::geometry
		else a.the_geom_4326
		END as the_geom_4326, 
		a.source, a.table_name, a.table_number
	FROM dg_wind.hsip_and_navteq_commercial_facilities a;',
		'dg_wind.hsip_and_navteq_commercial_facility_buffers', 'a',16);

-- check count
select count(*)
FROM dg_wind.hsip_and_navteq_commercial_facility_buffers;
-- 4835919

select count(*)
from dg_wind.hsip_and_navteq_commercial_facilities;
-- 4835919 (all set)
		
-- make sure all the data is polygon or multipolygon data now
SELECT distinct(ST_GeometryType(the_geom_4326))
FROM dg_wind.hsip_and_navteq_commercial_facility_buffers;

-- this is too big to export to shapefile all at once, so create three views that split the data into pieces:
SELECT min(gid),max(gid) from dg_wind.hsip_and_navteq_commercial_facility_buffers;
select 4835919/3, 4835919/3*2;


CREATE OR REPLACE VIEW dg_wind.hsip_and_navteq_commercial_facility_buffers_part1 AS
SELECT *
FROM dg_wind.hsip_and_navteq_commercial_facility_buffers
where gid < 1611973;

CREATE OR REPLACE VIEW dg_wind.hsip_and_navteq_commercial_facility_buffers_part2 AS
SELECT *
FROM dg_wind.hsip_and_navteq_commercial_facility_buffers
where gid >= 1611973 and gid <3223946;

CREATE OR REPLACE VIEW dg_wind.hsip_and_navteq_commercial_facility_buffers_part3 AS
SELECT *
FROM dg_wind.hsip_and_navteq_commercial_facility_buffers
where gid >= 3223946;

-- export to shapefiles --> F:\data\mgleason\DG_Wind\Data\Analysis\commercial_land_mask\revised_2014_02_05\commercial_facility_polygons
	-- hsip_and_navteq_commercial_facility_buffers_part1.shp
	-- hsip_and_navteq_commercial_facility_buffers_part2.shp
	-- hsip_and_navteq_commercial_facility_buffers_part3.shp

-- in arc, merge into a single feature class in a geodatatabase 
	-->F:\data\mgleason\DG_Wind\Data\Analysis\commercial_land_mask\revised_2014_02_05\commercial_facility_polygons\commercial_facs.gdb\commercial_facilities_combined

-- convert the commercial facilities shapefile to raster snapped to aws 2014 gcf raster (presence of industrial = 1, all else = no data)

-- convert this grid to points, then load those points to postgres as commercial points
-- load this grid to postgres and use to resample load to county level

