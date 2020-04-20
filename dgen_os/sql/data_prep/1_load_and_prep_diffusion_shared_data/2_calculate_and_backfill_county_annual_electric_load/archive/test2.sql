-- to deal with sliver intersections in ventyx:

-- Export the following to shapefile:
	-- ventyx.electric_service_territories_20130422
	-- ventyx.states_and_provinces_20131030
-- In ArcGIS:
	-- Run the Integrate tool on both:
		-- To a tolerance of 0.0005 (can do both at the same time, or each separately)
	-- Extract outer borders from states and provinces:
		-- Run Intersect tool on states_and_provinces (only), with output type set to "POINT"
			-- Produces points at nodes where state borders intersect each other
		-- Run Polygon to Line to convert states_and_provinces to lines
		-- Split Lines at Point on output from previous step, using nodes from Intersect as points
		-- Dissolve the output from previous (no multipart)
		--> these are the borders 
	-- For both the Integrated service territories and states/provinces, run:
		-- Snap (to states_and_provinces_borders with EDGE and distance = 0.005 decimal degrees) (can snap farther than integrate because integrate affects
			-- all vertices, whereas snap only affects edges
	-- Then run Intersect tool between the two (with an XY tolerance of 0.0005 decimal degrees) (same as integrate above)
	-- CHeck results by calculating perimeter to area ratio -- ratios are all below 100, which is in the range of legitimate triangular polygons
	
	-- Load borders, and integrated service territories and states into Postgres (change option to import as simple geometries, not multis)
-- In Postgres:

-- fix geometries on the input data
ALTER TABLE dg_wind.ventyx_states_and_provinces_snap_p0005 ALTER the_geom_4326 type geometry;
ALTER TABLE dg_wind.ventyx_elec_serv_territories_snap_p0005 ALTER the_geom_4326 type geometry;

UPDATE dg_wind.ventyx_states_and_provinces_snap_p0005
SET the_geom_4326 = ST_Buffer(the_geom_4326,0)
where ST_Isvalid(the_geom_4326) = False;

UPDATE dg_wind.ventyx_elec_serv_territories_snap_p0005
SET the_geom_4326 = ST_Buffer(the_geom_4326,0)
where ST_Isvalid(the_geom_4326) = False;


-- try snapping
-- 
-- WITH j as (
-- 	SELECT a.gid, b.gid
-- 	FROM dg_wind.ventyx_states_and_provinces_snap_p0005 a
-- 	LEFT JOIN dg_wind.ventyx_states_and_provinces_borders_simple b
-- 	ON ST_DWithin(a.the_geom_4326,b.the_geom_4326,0.005)
-- 	

DROP TABLE IF EXISTS dg_wind.states_fixed2;
CREATE TABLE dg_wind.states_fixed2 AS
SELECT a.gid, 
	CASE WHEN count(b.gid) > 0  THEN ST_Snap(a.the_geom_4326, ST_Union(b.the_geom_4326), 0.005)
	else  a.the_geom_4326
	END  as the_geom_4326
FROM dg_wind.ventyx_states_and_provinces_snap_p0005 a
LEFT JOIN dg_wind.ventyx_states_and_provinces_borders b
ON ST_DWithin(a.the_geom_4326,b.the_geom_4326,0.005)
GROUP BY a.gid, a.the_geom_4326;

--  fix any messed up geoms
UPDATE dg_wind.states_fixed2
SET the_geom_4326 = ST_Buffer(the_geom_4326,0)
where ST_Isvalid(the_geom_4326) = False;

-- add spatial index
CREATE INDEX states_fixed2_the_geom_4326_gist on dg_wind.states_fixed2 using gist(the_geom_4326);

-- do the same for ests
DROP TABLE IF EXISTS dg_wind.ests_fixed4;
CREATE TABLE dg_wind.ests_fixed4 AS
SELECT a.gid, 
	CASE WHEN count(b.gid) > 0  THEN ST_Snap(a.the_geom_4326, ST_Union(b.the_geom_4326), 0.005)
	else  a.the_geom_4326
	END  as the_geom_4326
FROM dg_wind.ventyx_elec_serv_territories_snap_p0005 a
LEFT JOIN dg_wind.ventyx_states_and_provinces_borders b
ON ST_DWithin(a.the_geom_4326,b.the_geom_4326,0.005)
GROUP BY a.gid, a.the_geom_4326;

--  fix any messed up geoms
UPDATE dg_wind.ests_fixed4
SET the_geom_4326 = ST_Buffer(the_geom_4326,0)
where ST_Isvalid(the_geom_4326) = False;

-- add spatial index
CREATE INDEX ests_fixed4_the_geom_4326_gist on dg_wind.ests_fixed4 using gist(the_geom_4326);



-- intersect with state bounda-- ries
-- DROP TABLE IF EXISTS  dg_wind.ests_fixed2_state_split3;
-- CREATE TABLE dg_wind.ests_fixed2_state_split3 AS
-- SELECT a.gid as agid,
-- 	b.gid as bgid,
-- 	ST_Intersection(a.the_geom_4326, b.the_geom_4326) AS the_geom_4326
-- FROM
-- 	 dg_wind.ests_fixed4 a,
-- 	 dg_wind.states_fixed2 b
-- WHERE
-- -- 	b.country = 'United States of America'
-- -- and
-- 	ST_Intersects(a.the_geom_4326, b.the_geom_4326)
-- ORDER BY
-- 	1,2;


-- these are the versions that were snapped in arcgis
ALTER TABLE dg_wind.snapped_electric_service_territories ALTER the_geom_4326 type geometry;
ALTER TABLE dg_wind.snapped_states_and_provinces ALTER the_geom_4326 type geometry;


UPDATE dg_wind.snapped_electric_service_territories
SET the_geom_4326 = ST_Buffer(the_geom_4326,0)
where ST_Isvalid(the_geom_4326) = False;

UPDATE dg_wind.snapped_states_and_provinces
SET the_geom_4326 = ST_Buffer(the_geom_4326,0)
where ST_Isvalid(the_geom_4326) = False;

DROP TABLE IF EXISTS  dg_wind.ests_fixed2_state_split3;
CREATE TABLE dg_wind.ests_fixed2_state_split3 AS
SELECT a.gid as agid,
	b.gid as bgid,
	ST_Intersection(a.the_geom_4326, b.the_geom_4326, 'POLYGON') AS the_geom_4326
FROM
	 dg_wind.snapped_electric_service_territories a,
	 dg_wind.snapped_states_and_provinces b
WHERE
	b.country = 'United States of America'
and
	ST_Intersects(a.the_geom_4326, b.the_geom_4326)
ORDER BY
	1,2;




-- check geom tyeps
SELECT distinct(ST_GeometryTYpe(the_geom_4326))
FROM dg_wind.ests_fixed2_state_split3;

-- delete any null geoms
DELETE FROM dg_wind.ests_fixed2_state_split3
WHERE the_geom_4326 is null;

UPDATE dg_wind.ests_fixed2_state_split3
SET the_geom_4326 = ST_Buffer(the_geom_4326,0)
where ST_Isvalid(the_geom_4326) = False;


-- check for any remaining slivers
ALTER TABLE dg_wind.ests_fixed2_state_split3
ADD column perimeter2area numeric;

-- calc perimeter to area ratio
UPDATE dg_wind.ests_fixed2_state_split3
SET perimeter2area = 
	CASE WHEN ST_Area(the_geom_4326::geography) = 0 then 9999999999
	else ST_Perimeter(the_geom_4326::geography)/ST_Area(the_geom_4326::geography)
	end;

-- investigate in Q