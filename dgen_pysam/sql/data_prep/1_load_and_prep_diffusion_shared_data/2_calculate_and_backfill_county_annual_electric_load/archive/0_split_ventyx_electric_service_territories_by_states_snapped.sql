-- process: need to instersect states with electric service territories to split them at state boundaries
-- however, doing so on the raw spatial data from Ventyx will produce a lot of slivers
-- to fix this, first do the following in ArcGIS:

-- Run the Data Management --> Feature Class --> Integrate tool with the following Ventyx shapefiles:
	-- electric_service_territories.shp (F:\data\mgleason\DG_Wind\Data\Analysis\Ventyx\0p0005_integrate\electric_service_territories.shp)
	-- states_and_provinces.shp (F:\data\mgleason\DG_Wind\Data\Analysis\Ventyx\0p0005_integrate\states_and_provinces.shp)
	-- use a tolerance of 0.0005 Decimal Degrees 

-- load those two files back into postgres as:
	-- dg_wind.ventyx_elec_serv_territories_snap
	-- dg_wind.ventyx_states_and_provinces_snap

-- to avoid slivers

DROP TABLE IF EXISTS dg_wind.ventyx_elec_serv_territories_states_snap CASCADE;
CREATE TABLE dg_wind.ventyx_elec_serv_territories_states_snap AS
SELECT a.company_id,
	a.company_na as company_name,
	b.name as state_name,
	b.abbrev as state_abbr,
	ST_Intersection(ST_Buffer(a.the_geom_4326,0), ST_Buffer(b.the_geom_4326,0), 'POLYGON') AS the_geom_4326
FROM
	 dg_wind.ventyx_elec_serv_territories_snap a,
	 dg_wind.ventyx_states_and_provinces_snap b
WHERE
	b.country = 'United States of America'
and
	ST_Intersects(a.the_geom_4326, b.the_geom_4326)
ORDER BY
	1,2;

-- check whether multiple geometry types found
SELECT distinct(geometrytype(the_geom_4326))
FROM dg_wind.ventyx_elec_serv_territories_states_snap;

-- lots of nulls that need to be deleted
DELETE FROM dg_wind.ventyx_elec_serv_territories_states_snap
where the_geom_4326 is null; -- 1070 rows

-- union up geoms that are for the same state and company to make sure there is only one polygon per company/state
DROP TABLE IF EXISTS dg_wind.ventyx_elec_serv_territories_states_snap_multipart;
CREATE TABLE dg_wind.ventyx_elec_serv_territories_states_snap_multipart AS
SELECT company_id, company_name, state_name, state_abbr, ST_Union(the_geom_4326) as the_geom_4326
FROM dg_wind.ventyx_elec_serv_territories_states_snap
GROUP BY company_id, company_name, state_name, state_abbr;

-- change company id to be an integer field
ALTER TABLE dg_wind.ventyx_elec_serv_territories_states_snap_multipart ALTER company_id type integer;

-- check that there are no company_id/states with multiple geoms
SELECT company_id, state_abbr, count(*)
FROM dg_wind.ventyx_elec_serv_territories_states_snap_multipart
GROUP BY company_id, state_abbr
order by count desc; -- all 1s, so we are good

-- add gid primary key
ALTER TABLE dg_wind.ventyx_elec_serv_territories_states_snap_multipart ADD COLUMN gid serial;

ALTER TABLE dg_wind.ventyx_elec_serv_territories_states_snap_multipart ADD primary key (gid);




-- add indices
CREATE INDEX ventyx_elec_serv_territories_states_snap_multipart_company_id_btree
  ON dg_wind.ventyx_elec_serv_territories_states_snap_multipart
  USING btree
  (company_id);

CREATE INDEX ventyx_elec_serv_territories_states_snap_multipart_name_btree
  ON dg_wind.ventyx_elec_serv_territories_states_snap_multipart
  USING btree
  (state_name COLLATE pg_catalog."default");

CREATE INDEX ventyx_elec_serv_territories_states_snap_multipart_the_geom_4326_gist
  ON dg_wind.ventyx_elec_serv_territories_states_snap_multipart
  USING gist
  (the_geom_4326);
  
ALTER TABLE dg_wind.ventyx_elec_serv_territories_states_snap_multipart CLUSTER ON ventyx_elec_serv_territories_states_snap_multipart_the_geom_4326_gist;

-- CREATE TRIGGER sync_last_mod
--   AFTER INSERT OR UPDATE OR DELETE OR TRUNCATE
--   ON dg_wind.ventyx_elec_serv_territories_states_snap
--   FOR EACH STATEMENT
--   EXECUTE PROCEDURE public.sync_last_mod();
