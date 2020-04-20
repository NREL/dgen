CREATE TABLE dg_wind.conus_tiles AS
SELECT rid, ST_Envelope(rast) as the_geom_4326
FROM dg_wind.mosaic_load_conus_residential;

CREATE INDEX conus_tiles_the_geom_4326_gist on dg_wind.conus_tiles uSING gist(the_geom_4326);
CREATE INDEX conus_tiles_the_geom_4326_centroid_gist on dg_wind.conus_tiles uSING gist(ST_Centroid(the_geom_4326));

ALTER TABLE dg_wind.conus_tiles ADD COLUMN state_abbr text;

UPDATE dg_wind.conus_tiles a
SET state_abbr = b.abbrev
FROM ventyx.states_and_provinces b
where ST_Intersects(st_centroid(a.the_geom_4326),b.the_geom_4326)


CREATE TABLE dg_wind.mosaic_load_conus_residential_by_state AS
SELECT ST_Union(rast) as rast
FROM dg_wind.mosaic_load_conus_residential a
left join dg_wind.conus_tiles b
on a.rid = b.rid
where b.state_abbr = 'MA'
group by b.state_abbr;