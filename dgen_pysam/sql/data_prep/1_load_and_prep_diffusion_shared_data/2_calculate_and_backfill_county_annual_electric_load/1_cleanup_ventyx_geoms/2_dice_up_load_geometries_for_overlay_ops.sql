-- create fishnet (2 decimal degrees)
DROP TABLE IF EXISTS dg_wind.us_fishnet_p5dd;
CREATE TABLE dg_wind.us_fishnet_p5dd AS
SELECT ST_SetSrid(ST_Fishnet('dg_wind.ventyx_elec_serv_territories_w_2011_sales_data_backfilled_clip','the_geom_4326',0.5),4326) as the_geom_4326;

CREATE INDEX us_fishnet_p5dd_the_geom_4326_gist ON dg_wind.us_fishnet_p5dd using gist(the_geom_4326);

-- dice up the backfilled geoms
DROP TABLE IF EXISTS dg_wind.ventyx_backfilled_ests_diced;
CREATE TABLE dg_wind.ventyx_backfilled_ests_diced 
(
	est_gid integer,
	state_abbr character varying(2),
	the_geom_4326 geometry
);

select parsel_2('dav-gis','mgleason','mgleason',
		'dg_wind.ventyx_elec_serv_territories_w_2011_sales_data_backfilled_clip','gid',
		'SELECT a.gid as est_gid, a.state_abbr, ST_Intersection(a.the_geom_4326, b.the_geom_4326) as the_geom_4326
			FROM dg_wind.ventyx_elec_serv_territories_w_2011_sales_data_backfilled_clip a
			INNER JOIN dg_wind.us_fishnet_p5dd b
			ON ST_Intersects(a.the_geom_4326, b.the_geom_4326);',
			'dg_wind.ventyx_backfilled_ests_diced',
		'a', 16);

-- add a new id, called the state_id, which will allow me to parsel the data up more efficiently
ALTER TABLE dg_wind.ventyx_backfilled_ests_diced ADD COLUMN state_id integer;

with b as (
	SELECT distinct(state_abbr)
	FROM dg_wind.ventyx_backfilled_ests_diced),
c as (
	 SELECT state_abbr, row_number() over () as state_id 
	 from b)
UPDATE dg_wind.ventyx_backfilled_ests_diced a
SET state_id = c.state_id
FROM c
WHERe a.state_abbr = c.state_abbr;

CREATE INDEX  ventyx_backfilled_ests_diced_state_id_btree 
ON dg_wind.ventyx_backfilled_ests_diced
USING btree(state_id);

CREATE INDEX ventyx_backfilled_ests_diced_the_geom_4326_gist2 ON dg_wind.ventyx_backfilled_ests_diced USING gist(the_geom_4326);

CLUSTER dg_wind.ventyx_backfilled_ests_diced USING ventyx_backfilled_ests_diced_state_id_btree;

CREATE INDEX ventyx_backfilled_ests_diced2_est_gid_btree ON dg_wind.ventyx_backfilled_ests_diced USING btree(est_gid);

VACUUM ANALYZE dg_wind.ventyx_backfilled_ests_diced;

-- make sure that each gid is only tied to a single state_id
select est_gid, count(distinct(state_id))
FROM dg_wind.ventyx_backfilled_ests_diced
group by est_gid
order by count desc;

-- add 900914 geom
ALTER TABLE dg_wind.ventyx_backfilled_ests_diced ADD COLUMN the_geom_900914 geometry;
UPDATE dg_wind.ventyx_backfilled_ests_diced
SET the_geom_900914 = ST_Transform(the_geom_4326,900914);

-- check for invalid geoms
select est_gid, ST_IsValidReason(the_geom_900914)
FROM dg_wind.ventyx_backfilled_ests_diced
where ST_Isvalid(the_geom_900914) = false;
-- 583
-- 2987

-- fix invalid geoms
UPDATE dg_wind.ventyx_backfilled_ests_diced
SET the_geom_900914 = ST_BUffer(the_geom_900914,0.0)
where ST_Isvalid(the_geom_900914) = false;
-- check in q to make sure nothing got removed (compare to the_geom_4326 for selected est_gids)
-- all is ok!

-- create index
CREATE INDEX ventyx_backfilled_ests_diced_the_geom_900914_gist on dg_wind.ventyx_backfilled_ests_diced using gist(the_geom_900914);