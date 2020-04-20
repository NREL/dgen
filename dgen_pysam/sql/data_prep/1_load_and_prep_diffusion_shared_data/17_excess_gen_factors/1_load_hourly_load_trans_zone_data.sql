SET ROLE 'ventyx-writers';
DROP TABLE IF EXISTS ventyx.hourly_load_by_transmission_zone_20130723;
CREATE TABLE ventyx.hourly_load_by_transmission_zone_20130723 (
	transmission_zone text,
	local_datetime timestamp without time zone,
	time_zone character varying(3),
	time_zone_converted_to_dst character varying(3),
	year integer,
	date date,
	hour numeric,
	load_mw numeric,
	transmission_zone_id integer
);
RESET ROLE;

SET ROLE 'server-superusers';
COPY ventyx.hourly_load_by_transmission_zone_20130723 FROM '/home/mgleason/data/dg_wind/hourly_load_2010b.csv' with csv header;
RESET ROLE;

SET ROLE 'ventyx-writers';


-- convert load_mw to integer
ALTER TABLE ventyx.hourly_load_by_transmission_zone_20130723
ALTER load_mw TYPE integer;

-- add comment
COMMENT ON TABLE ventyx.hourly_load_by_transmission_zone_20130723
  IS 'Hourly Load by Transmission Zone (all sectors) from Ventyx; collected 2013.07.23; loaded 2014.05.29.';


-- add indices
CREATE INDEX hourly_load_by_transmission_zone_20130723_hour_btree
ON ventyx.hourly_load_by_transmission_zone_20130723 using btree(hour);

CREATE INDEX hourly_load_by_transmission_zone_20130723_transmission_zone_id_btree
ON ventyx.hourly_load_by_transmission_zone_20130723 using btree(transmission_zone_id);

CREATE INDEX hourly_load_by_transmission_zone_20130723_date_btree
ON ventyx.hourly_load_by_transmission_zone_20130723 using btree(date);


-- create a view
DROP VIEW IF EXISTS ventyx.hourly_load_by_transmission_zone;
CREATE OR REPLACE VIEW ventyx.hourly_load_by_transmission_zone AS
SELECT *
FROM ventyx.hourly_load_by_transmission_zone_20130723;

-- add spatial data
-- (loaded using shapfile loader plugin -- manually edited in QGIS to identify country canada from US)
ALTER TABLE ventyx.transmission_zones_07232013
ALTER zone_id TYPE integer;

COMMENT ON TABLE ventyx.transmission_zones_07232013
  IS 'Transmission Zone Boundaries from Ventyx; collected 2013.07.23; loaded 2014.05.29. Manually edited to identify country for each zone.';

-- create country index
CREATE INDEX transmission_zones_07232013_country_btree ON ventyx.transmission_zones_07232013 using btree(country);


-- add the_geom_96703
ALTER TABLE ventyx.transmission_zones_07232013
ADD COLUMN the_geom_96703 geometry;

UPDATE ventyx.transmission_zones_07232013
SET the_geom_96703 = ST_Transform(the_geom_4326,96703);

CREATE INDEX transmission_zones_07232013_the_geom_96703_gist ON ventyx.transmission_zones_07232013 using gist(the_geom_96703);


-- check for and fix invalid geometries
SELECT ST_IsValidReason(the_geom_96703)
FROM ventyx.transmission_zones_07232013
where ST_ISvalid(the_geom_96703) = False;

UPDATE ventyx.transmission_zones_07232013
SET the_geom_96703 = ST_MakeValid(the_geom_96703);

-- create view
DROP VIEW IF EXISTS ventyx.transmission_zones;
CREATE OR REPLACE VIEW ventyx.transmission_zones AS
SELECT *
FROM ventyx.transmission_zones_07232013;

-- add hdf index column
ALTER TABLE ventyx.transmission_zones_07232013
ADD COLUMN hdf_index integer;

UPDATE ventyx.transmission_zones_07232013
SET hdf_index = gid - 1

-- change pkey
ALTER TABLE ventyx.transmission_zones_07232013 DROP CONSTRAINT transmission_zones07232013_pkey;

ALTER TABLE ventyx.transmission_zones_07232013
  ADD CONSTRAINT transmission_zones07232013_pkey PRIMARY KEY(zone_id);