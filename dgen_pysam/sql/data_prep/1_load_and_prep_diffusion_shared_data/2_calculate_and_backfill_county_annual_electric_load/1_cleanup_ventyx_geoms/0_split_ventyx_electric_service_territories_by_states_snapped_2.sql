-- see notes in "Intersecting Ventyx Service Territories and States.docx
-- on creating ventyx. electric_service_territories_states_split_20140224

-- change company id to be an integer field
ALTER TABLE ventyx.electric_service_territories_states_split_20140224 ALTER company_id type integer;


-- check that there are no company_id/states with multiple gems
SELECT company_id, st_abbr, count(*)
FROM ventyx.electric_service_territories_states_split_20140224
GRoUP BY company_id, st_abbr
order by count desc; -- all 1s, s we are gd

-- create multipart version
DROP TABLE IF EXISTS ventyx.electric_service_territories_states_split_multipart_20140224;
CREATE TABLE ventyx.electric_service_territories_states_split_multipart_20140224 AS
SELECT company_id, company_na as company_name, st_abbr as state_abbr, country, ST_Union(the_geom_4326) as the_geom_4326
FROM ventyx.electric_service_territories_states_split_20140224
GROUP BY company_Id, company_name, state_abbr, country;

-- add gid primary key
ALTER TABLE ventyx.electric_service_territories_states_split_multipart_20140224 ADD CoLUMN gid serial;

ALTER TABLE ventyx.electric_service_territories_states_split_multipart_20140224 ADD primary key (gid);

-- add indices
CREATE INDEX electric_service_territories_states_split_multipart_20140224_company_id_btree
  ON ventyx.electric_service_territories_states_split_multipart_20140224
  USING btree(company_id);

CREATE INDEX electric_service_territories_states_split_multipart_20140224_state_abbr_btree
  ON ventyx.electric_service_territories_states_split_multipart_20140224
  USING btree(state_abbr);

CREATE INDEX electric_service_territories_states_split_multipart_20140224_the_geom_4326_gist
  ON ventyx.electric_service_territories_states_split_multipart_20140224
  using gist (the_geom_4326);
  
ALTER TABLE ventyx.electric_service_territories_states_split_multipart_20140224 CLUSTER on electric_service_territories_states_split_multipart_20140224_the_geom_4326_gist;


