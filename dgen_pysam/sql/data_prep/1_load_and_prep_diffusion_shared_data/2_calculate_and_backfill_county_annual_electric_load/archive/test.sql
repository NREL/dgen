ALTER TABLE dg_wind.ventyx_states_and_provinces_snap
ADD COLUMn the_polyline_4326;

UPDATE dg_wind.ventyx_states_and_provinces_snap
SET the_polyline_4326 = ST_Boundary(the_geom_4326);

DROP TABLE IF EXISTS dg_wind.ventyx_state_vertices;
CREATE TABLE dg_wind.ventyx_state_vertices AS
WITH a AS (
SELECT ST_DumpPoints(the_polyline_4326) as dump
FROM dg_wind.ventyx_states_and_provinces_snap)
SELECT (dump).geom as the_geom_4326
FROM a;


CREATE TABLE dg_wind.ventyx_state_boundaries_union AS
SELECT ST_Union(the_polyline_4326) as the_geom_4326
FROM dg_wind.ventyx_states_and_provinces_snap;

DROP TABLE IF EXISTS dg_wind.ventyx_state_nodes;
CREATE TABLE dg_wind.ventyx_state_nodes AS
SELECT ST_Node(the_polyline_4326) as the_geom_4326
FROM dg_wind.ventyx_states_and_provinces_snap;


DROP TABLE IF EXISTS dg_wind.ventyx_state_vertices2;
CREATE TABLE dg_wind.ventyx_state_vertices2 AS
WITH a AS (
SELECT ST_DumpPoints(the_geom_4326) as dump
FROM dg_wind.ventyx_state_nodes)
SELECT (dump).geom as the_geom_4326
FROM a;
