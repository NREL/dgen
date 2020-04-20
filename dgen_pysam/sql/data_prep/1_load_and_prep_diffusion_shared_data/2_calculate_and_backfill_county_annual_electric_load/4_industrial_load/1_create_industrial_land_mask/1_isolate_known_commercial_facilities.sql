-- for commercial, we isolated points from navteq that mapped to cbecs primary building activities
-- we won't do this for industrial because the navteq factypes are primarily if not exclusively commercial


-- isolate commercial points from hsip 2012 based on 2-digit naics codes (42 and up)
CREATE OR REPLACE VIEW hsip_2012.all_hsip_industrial_facilities AS
SELECT *
FROM hsip_2012.all_points_with_naics a
WHERE substring(a.naicscode_3 for 2)::integer < 42; -- this is based on NAICS 2-digit lookup (http://www.census.gov/cgi-bin/sssd/naics/naicsrch?chart=2012)

-- check for any null geoms -- none foudn
SELECT count(*)
FROM hsip_2012.all_hsip_industrial_facilities
where ST_GEometryType(the_geom_4326) is null;


-- buffer the points 
DROP TABLE IF EXISTS dg_wind.hsip_industrial_facility_buffers CASCADE;
CREATE TABLE dg_wind.hsip_industrial_facility_buffers
(
  gid integer,
  the_geom_4326 geometry,
  table_name text,
  table_number integer
);

SELECT parsel_2('dav-gis','mgleason','mgleason','hsip_2012.all_hsip_industrial_facilities','gid',
	'SELECT a.gid,
		CASE WHEN ST_GeometryType(a.the_geom_4326) = ''ST_Point'' THEN ST_Buffer(a.the_geom_4326::geography, 90)::geometry
		else a.the_geom_4326
		END as the_geom_4326, 
		a.table_name, a.table_number
	FROM hsip_2012.all_hsip_industrial_facilities a;',
		'dg_wind.hsip_industrial_facility_buffers', 'a',16);

-- check count
select count(*)
FROM dg_wind.hsip_industrial_facility_buffers;
--2370335  rows

-- make sure all the data is polygon data now
SELECT distinct(ST_GeometryType(the_geom_4326))
FROM dg_wind.hsip_industrial_facility_buffers;

-- this is too big to export to shapefile all at once, so create three views that split the data into pieces:
SELECT table_number, count(*)
from dg_wind.hsip_industrial_facility_buffers
group by table_number
order by table_number;


CREATE OR REPLACE VIEW dg_wind.hsip_industrial_facility_buffers_part1 AS
SELECT *
FROM dg_wind.hsip_industrial_facility_buffers
where table_number < 52;

CREATE OR REPLACE VIEW dg_wind.hsip_industrial_facility_buffers_part2 AS
SELECT *
FROM dg_wind.hsip_industrial_facility_buffers
where gid >= 52 and gid <142;

CREATE OR REPLACE VIEW dg_wind.hsip_industrial_facility_buffers_part3 AS
SELECT *
FROM dg_wind.hsip_industrial_facility_buffers
where gid >= 142;




-- export to shapefiles --> F:\data\mgleason\DG_Wind\Data\Analysis\industrial_land_mask\revised_2014_02_05\industrial_facility_polygons
	-- hsip_industrial_facility_buffers_part1
	-- hsip_industrial_facility_buffers_part2
	-- hsip_industrial_facility_buffers_part3


-- in arc, merge into a single feature class in a geodatatabase 
	-->F:\data\mgleason\DG_Wind\Data\Analysis\industrial_land_mask\revised_2014_02_05\industrial_facility_polygons\industrial_facs.gdb\industrial_facilities_combined


-- convert the commercial facilities shapefile to raster snapped to aws 2014 gcf raster (presence of industrial = 1, all else = no data)

-- convert this grid to points, then load those points to postgres as commercial points
-- load this grid to postgres and use to resample load to county level

