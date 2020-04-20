ALTER TABLE diffusion_shared.pt_grid_us_res_new
RENAME TO pt_grid_us_res_new_bad;
------------------------------------------------------------------------------------------------------------
-- INGEST PTS AND SIMPLE CLEANUP
------------------------------------------------------------------------------------------------------------
set role 'diffusion-writers';
-- DROP TABLE IF EXISTS  diffusion_shared.pt_grid_us_res_new;
CREATE TABLE diffusion_shared.pt_grid_us_res_new (
	x numeric,
	y numeric,
	temp_col integer,
	the_geom_4326 geometry,
	county_id integer,
	utility_type character varying(9),
	iiijjjicf_id integer,
	wind_incentive_array_id integer,
	solar_incentive_array_id integer,
	pca_reg integer,
	reeds_reg integer,
	solar_re_9809_gid integer,
	hdf_load_index integer,
	the_geom_96703 geometry,
	canopy_pct integer,
	canopy_ht_m integer,
	hi_dev_pct integer,
	acres_per_hu numeric,
	hu_portion numeric,
	blkgrp_ownocc_sf_hu_portion numeric
	);

SET ROLE "server-superusers";
COPY diffusion_shared.pt_grid_us_res_new (x, y, temp_col)
FROM '/srv/home/mgleason/data/dg_wind/land_masks_20140219/res_mask.csv' with csv header;
set role 'diffusion-writers';

-- drop this column -- it means nothing
ALTER TABLE diffusion_shared.pt_grid_us_res_new
DROP COLUMN temp_col;

-- set fill factor
ALTER TABLE diffusion_shared.pt_grid_us_res_new
SET (fillfactor = 50);
------------------------------------------------------------------------------------------------------------


------------------------------------------------------------------------------------------------------------
-- GEOM (4326)
------------------------------------------------------------------------------------------------------------
UPDATE diffusion_shared.pt_grid_us_res_new
SET the_geom_4326= ST_SetSRID(ST_MakePoint(x,y),4326);

CREATE INDEX pt_grid_us_res_new_the_geom_4326_gist 
ON diffusion_shared.pt_grid_us_res_new 
USING gist(the_geom_4326);

CLUSTER diffusion_shared.pt_grid_us_res_new 
USING pt_grid_us_res_new_the_geom_4326_gist;

VACUUM FULL diffusion_shared.pt_grid_us_res_new;
------------------------------------------------------------------------------------------------------------


------------------------------------------------------------------------------------------------------------
-- GEOM (96703)
------------------------------------------------------------------------------------------------------------
UPDATE diffusion_shared.pt_grid_us_res_new
SET the_geom_96703= ST_Transform(the_geom_4326, 96703);

CREATE INDEX pt_grid_us_res_new_the_geom_96703_gist 
ON diffusion_shared.pt_grid_us_res_new 
USING gist(the_geom_96703);
------------------------------------------------------------------------------------------------------------


------------------------------------------------------------------------------------------------------------
-- GID (PRIMARY KEY)
------------------------------------------------------------------------------------------------------------
ALTER TABLE diffusion_shared.pt_grid_us_res_new 
ADD COLUMN gid serial;

ALTER TABLE diffusion_shared.pt_grid_us_res_new 
ADD PRIMARY KEY (gid);
------------------------------------------------------------------------------------------------------------


------------------------------------------------------------------------------------------------------------
-- COUNTY ID
------------------------------------------------------------------------------------------------------------
DROP TABLE IF EXISTS diffusion_wind_data.pt_grid_us_res_new_county_lkup;
CREATE TABLE diffusion_wind_data.pt_grid_us_res_new_county_lkup
(
	gid integer,
	county_id integer
);


select parsel_2('dav-gis','mgleason', 'mgleason',
		'diffusion_shared.pt_grid_us_res_new','gid',
		'SELECT DISTINCT ON (a.gid) a.gid, b.county_id
		FROM diffusion_shared.pt_grid_us_res_new a
		INNER JOIN diffusion_shared.county_geom b
		ON ST_Intersects(a.the_geom_4326, b.the_geom_4326)
		ORDER by a.gid, b.county_id;', -- distinct on ensures that there are no dupes along county borders
		'diffusion_wind_data.pt_grid_us_res_new_county_lkup', 
		'a', 16);

-- add primary key to the lkup table
ALTER TABLE diffusion_wind_data.pt_grid_us_res_new_county_lkup
ADD PRIMARY KEY (gid);

-- add the results to the main table
UPDATE diffusion_shared.pt_grid_us_res_new a
SET county_id = b.county_id
FROM diffusion_wind_data.pt_grid_us_res_new_county_lkup b
WHERE a.gid = b.gid;

-- add an index to the main table
CREATE INDEX pt_grid_us_res_new_county_id_btree 
ON diffusion_shared.pt_grid_us_res_new 
using btree(county_id);

-- check why there are nulls
DROP TABLE IF EXISTS diffusion_wind_data.no_county_pts_res;
CREATE TABLE diffusion_wind_data.no_county_pts_res AS
SELECT gid, the_geom_4326
FROM diffusion_shared.pt_grid_us_res_new
where county_id is null;
-- 1497  rows
-- inspect in Q - all along edges of the country

-- pick county based on nearest
DROP TABLE IF EXIStS diffusion_wind_data.no_county_pts_res_closest;
CREATE TABLE diffusion_wind_data.no_county_pts_res_closest AS
with candidates as 
(
		SELECT a.gid, a.the_geom_4326, 
		unnest((select array(SELECT b.county_id
			 FROM diffusion_shared.county_geom b
			 ORDER BY a.the_geom_4326 <#> b.the_geom_4326 LIMIT 5))) as county_id
			FROM diffusion_shared.pt_grid_us_res_new a
			where a.county_id is null
 )
SELECT distinct ON (gid) a.gid, a.county_id
FROM candidates a
lEFT JOIN diffusion_shared.county_geom b
ON a.county_id = b.county_id
ORDER BY gid, ST_Distance(a.the_geom_4326,b.the_geom_4326) asc;

-- update the main table
UPDATE diffusion_shared.pt_grid_us_res_new a
SET county_id = b.county_id
FROM diffusion_wind_data.no_county_pts_res_closest b
WHERE a.county_id is null
and a.gid = b.gid;

-- make sure no more nulls remain
SELECT count(*)
FROM diffusion_shared.pt_grid_us_res_new
where county_id is null;
-- 0

-- drop the other tables
DROP TABLE IF EXISTS diffusion_wind_data.no_county_pts_res;
DROP TABLE IF EXISTS diffusion_wind_data.no_county_pts_res_closest;
------------------------------------------------------------------------------------------------------------


------------------------------------------------------------------------------------------------------------
-- UTILITY TYPE
------------------------------------------------------------------------------------------------------------
DROP TABLE IF EXISTS  diffusion_wind_data.pt_grid_us_res_new_utiltype_lookup;
CREATE TABLE  diffusion_wind_data.pt_grid_us_res_new_utiltype_lookup 
(
	gid integer,
	utility_type character varying(9)
);

select parsel_2('dav-gis','mgleason','mgleason',
		'diffusion_shared.pt_grid_us_res_new','gid',
		'WITH ut_ranks as (
			SELECT unnest(array[''IOU'',''Muni'',''Coop'',''All Other'']) as utility_type, generate_series(1,4) as rank
		),
		isect as (
			SELECT a.gid, b.company_type_general as utility_type, c.rank
			FROM diffusion_shared.pt_grid_us_res_new a
			INNER JOIN dg_wind.ventyx_elec_serv_territories_edit_diced b
			ON ST_Intersects(a.the_geom_4326, b.the_geom_4326)
			LEFT JOIN ut_ranks c
			ON b.company_type_general = c.utility_type)
		SELECT DISTINCT ON (a.gid) a.gid, a.utility_type 
		FROM isect a
		ORDER BY a.gid, a.rank ASC;',
		' diffusion_wind_data.pt_grid_us_res_new_utiltype_lookup', 
		'a', 16);

-- add a primary key to the lkup table
ALTER TABLE diffusion_wind_data.pt_grid_us_res_new_utiltype_lookup
ADD PRIMARY KEY(gid);

-- join the info back in
UPDATE diffusion_shared.pt_grid_us_res_new a
SET utility_type = b.utility_type
FROM  diffusion_wind_data.pt_grid_us_res_new_utiltype_lookup b
where a.gid = b.gid;

CREATE INDEX pt_grid_us_res_new_utility_type_btree 
ON diffusion_shared.pt_grid_us_res_new 
USING btree(utility_type);

-- are there any nulls?
SELECT count(*) 
FROM diffusion_shared.pt_grid_us_res_new
where utility_type is null;
-- 24537 rows

-- isolate the unjoined points
-- and fix them by assigning value from their nearest neighbor that is not null
set enable_seqscan = off;
VACUUM ANALYZE diffusion_shared.pt_grid_us_res_new
DROP TABLE IF EXISTS  diffusion_wind_data.pt_grid_us_res_new_utiltype_missing;
CREATE TABLE  diffusion_wind_data.pt_grid_us_res_new_utiltype_missing AS
with a AS(
	select gid, the_geom_4326
	FROM diffusion_shared.pt_grid_us_res_new
	where utility_type is null)
SELECT a.gid, a.the_geom_4326, 
	(SELECT b.utility_type 
	 FROM diffusion_shared.pt_grid_us_res_new b
	 where b.utility_type is not null
	 ORDER BY a.the_geom_4326 <#> b.the_geom_4326
	 LIMIT 1) as utility_type
FROM a;

--update the points table
UPDATE diffusion_shared.pt_grid_us_res_new a
SET utility_type = b.utility_type
FROM  diffusion_wind_data.pt_grid_us_res_new_utiltype_missing b
where a.gid = b.gid
and a.utility_type is null;

-- any nulls left?
SELECT count(*) 
FROM diffusion_shared.pt_grid_us_res_new
where utility_type is null;
-- 0 rows
------------------------------------------------------------------------------------------------------------


------------------------------------------------------------------------------------------------------------
-- WIND RESOURCE IDS (III, JJJ, ICF)
------------------------------------------------------------------------------------------------------------
DROP TABLE IF EXISTS  diffusion_wind_data.pt_grid_us_res_new_iiijjjicf_id_lookup;
CREATE TABLE  diffusion_wind_data.pt_grid_us_res_new_iiijjjicf_id_lookup (
	gid integer,
	iiijjjicf_id integer);

--run in parallel for speed (100x100 tiles are necessary for it ti finishin in about 7 mins -- 1000x1000 tiles would take several hours even in parallel)
SELECT parsel_2('dav-gis','mgleason','mgleason','diffusion_shared.pt_grid_us_res_new','gid',
		'SELECT a.gid, ST_Value(b.rast,a.the_geom_4326) as iiijjjicf_id
		FROM  diffusion_shared.pt_grid_us_res_new a
		INNER JOIN  aws_2014.iiijjjicf_200m_raster_100x100 b
		ON ST_Intersects(b.rast,a.the_geom_4326);',
			' diffusion_wind_data.pt_grid_us_res_new_iiijjjicf_id_lookup', 'a',16);

-- add a primary key on the lookup table
ALTER TABLE diffusion_wind_data.pt_grid_us_res_new_iiijjjicf_id_lookup
ADD PRIMARY KEY (gid);

-- join the info back in
UPDATE diffusion_shared.pt_grid_us_res_new a
SET iiijjjicf_id = b.iiijjjicf_id
FROM  diffusion_wind_data.pt_grid_us_res_new_iiijjjicf_id_lookup b
where a.gid = b.gid;

CREATE INDEX pt_grid_us_res_new_iiijjjicf_id_btree 
ON diffusion_shared.pt_grid_us_res_new 
USING btree(iiijjjicf_id);

-- check for points with no iiijjjicf -- there shouldnt be any since the land mask is clipped to the raster
SELECT count(*) 
FROM diffusion_shared.pt_grid_us_res_new
where iiijjjicf_id is null;
-- 0
------------------------------------------------------------------------------------------------------------


------------------------------------------------------------------------------------------------------------
-- DSIRE INCENTIVES (PREP)
------------------------------------------------------------------------------------------------------------
--create a copy of the incentives_geoms table so i can index the geom
CREATE TABLE dg_wind.incentives_geoms_copy AS
sELECT gid, the_geom
FROM geo_incentives.incentives_geoms;

CREATE INDEX incentives_geoms_the_geom_gist ON dg_wind.incentives_geoms_copy USING gist(the_geom);

VACUUM ANALYZE dg_wind.incentives_geoms_copy;

-- dice it up to allow for faster intersects
CREATE TABLE dg_wind.incentives_geoms_copy_diced AS
SELECT a.gid, ST_Intersection(a.the_geom, b.the_geom_4326) as the_geom
FROM dg_wind.incentives_geoms_copy a
INNER JOIN mgleason.conus_fishnet_2dd b
ON ST_Intersects(a.the_geom, b.the_geom_4326);

CREATE INDEX incentives_geoms_copy_diced_the_geom_gist ON dg_wind.incentives_geoms_copy_diced USING gist(the_geom);

VACUUM ANALYZE dg_wind.incentives_geoms_copy_diced;
------------------------------------------------------------------------------------------------------------


------------------------------------------------------------------------------------------------------------
-- DSIRE INCENTIVES (WIND)
------------------------------------------------------------------------------------------------------------
--create the lookup table		
DROP TABLE IF EXISTS diffusion_wind_data.dsire_incentives_lookup_res;
CREATE TABLE diffusion_wind_data.dsire_incentives_lookup_res AS
with a as 
(
	SELECT b.gid, b.the_geom, d.uid as wind_incentives_uid
	FROM dg_wind.incentives_geoms_copy_diced b
	inner JOIN geo_incentives.incentives c
	ON b.gid = c.geom_id
	INNER JOIN geo_incentives.wind_incentives d
	ON c.gid = d.incentive_id
)
SELECT e.gid as pt_gid, a.wind_incentives_uid
FROM a
INNER JOIN diffusion_shared.pt_grid_us_res_new e
ON ST_Intersects(a.the_geom,e.the_geom_4326);

CREATE INDEX dsire_incentives_lookup_res_pt_gid_btree 
ON diffusion_wind_data.dsire_incentives_lookup_res 
using btree(pt_gid);

-- group the incentives into arrays so that there is just one row for each pt_gid
DROP TABLE IF EXISTS diffusion_wind_data.dsire_incentives_combos_lookup_res;
CREATE TABLE diffusion_wind_data.dsire_incentives_combos_lookup_res AS
SELECT pt_gid, array_agg(wind_incentives_uid order by wind_incentives_uid) as wind_incentives_uid_array
FROM diffusion_wind_data.dsire_incentives_lookup_res
group by pt_gid;

-- find the unique set of incentive arrays
DROP TABLE IF EXISTS diffusion_wind_data.dsire_incentives_unique_combos_res;
CREATE TABLE diffusion_wind_data.dsire_incentives_unique_combos_res AS
SELECT distinct(wind_incentives_uid_array) as wind_incentives_uid_array
FROM diffusion_wind_data.dsire_incentives_combos_lookup_res;

-- add a primary key to the table of incentive arrays
ALTER TABLE diffusion_wind_data.dsire_incentives_unique_combos_res
ADD column incentive_array_id serial primary key;

-- join the incentive array primary key back into the combos_lookup_table
ALTER TABLE diffusion_wind_data.dsire_incentives_combos_lookup_res
ADD column incentive_array_id integer;

UPDATE diffusion_wind_data.dsire_incentives_combos_lookup_res a
SET incentive_array_id = b.incentive_array_id
FROM diffusion_wind_data.dsire_incentives_unique_combos_res b
where a.wind_incentives_uid_array = b.wind_incentives_uid_array;

-- join this info back into the main points table
UPDATE diffusion_shared.pt_grid_us_res_new a
SET wind_incentive_array_id = b.incentive_array_id
FROM diffusion_wind_data.dsire_incentives_combos_lookup_res b
WHere a.gid = b.pt_gid;

-- add an index
CREATE INDEX pt_grid_us_res_new_wind_incentive_btree 
ON diffusion_shared.pt_grid_us_res_new
USING btree(wind_incentive_array_id);

--unnest the data from the unique combos table
DROP TABLE IF EXISTS diffusion_wind.dsire_incentives_simplified_lkup_res;
CREATE TABLE diffusion_wind.dsire_incentives_simplified_lkup_res AS
SELECT incentive_array_id as incentive_array_id, 
	unnest(wind_incentives_uid_array) as incentives_uid
FROM diffusion_wind_data.dsire_incentives_unique_combos_res;

-- create index
CREATE INDEX dsire_incentives_simplified_lkup_res_inc_id_btree
ON diffusion_wind.dsire_incentives_simplified_lkup_res
USING btree(incentive_array_id);
------------------------------------------------------------------------------------------------------------


------------------------------------------------------------------------------------------------------------
-- DSIRE INCENTIVES (SOLAR)
------------------------------------------------------------------------------------------------------------
--create the lookup table		
DROP TABLE IF EXISTS diffusion_solar_data.dsire_incentives_lookup_res;
CREATE TABLE diffusion_solar_data.dsire_incentives_lookup_res AS
with a as 
(
	SELECT b.gid, b.the_geom, d.uid as solar_incentives_uid
	FROM dg_wind.incentives_geoms_copy_diced b
	inner JOIN geo_incentives.incentives c
	ON b.gid = c.geom_id
	INNER JOIN geo_incentives.pv_incentives d
	ON c.gid = d.incentive_id
)
SELECT e.gid as pt_gid, a.solar_incentives_uid
FROM a
INNER JOIN diffusion_shared.pt_grid_us_res_new e
ON ST_Intersects(a.the_geom,e.the_geom_4326);

CREATE INDEX dsire_incentives_lookup_res_pt_gid_btree 
ON diffusion_solar_data.dsire_incentives_lookup_res 
using btree(pt_gid);

-- group the incentives into arrays so that there is just one row for each pt_gid
DROP TABLE IF EXISTS diffusion_solar_data.dsire_incentives_combos_lookup_res;
CREATE TABLE diffusion_solar_data.dsire_incentives_combos_lookup_res AS
SELECT pt_gid, array_agg(solar_incentives_uid order by solar_incentives_uid) as solar_incentives_uid_array
FROM diffusion_solar_data.dsire_incentives_lookup_res
group by pt_gid;

-- find the unique set of incentive arrays
DROP TABLE IF EXISTS diffusion_solar_data.dsire_incentives_unique_combos_res;
CREATE TABLE diffusion_solar_data.dsire_incentives_unique_combos_res AS
SELECT distinct(solar_incentives_uid_array) as solar_incentives_uid_array
FROM diffusion_solar_data.dsire_incentives_combos_lookup_res;

-- add a primary key to the table of incentive arrays
ALTER TABLE diffusion_solar_data.dsire_incentives_unique_combos_res
ADD column incentive_array_id serial primary key;

-- join the incentive array primary key back into the combos_lookup_table
ALTER TABLE diffusion_solar_data.dsire_incentives_combos_lookup_res
ADD column incentive_array_id integer;

UPDATE diffusion_solar_data.dsire_incentives_combos_lookup_res a
SET incentive_array_id = b.incentive_array_id
FROM diffusion_solar_data.dsire_incentives_unique_combos_res b
where a.solar_incentives_uid_array = b.solar_incentives_uid_array;

-- join this info back into the main points table
UPDATE diffusion_shared.pt_grid_us_res_new a
SET solar_incentive_array_id = b.incentive_array_id
FROM diffusion_solar_data.dsire_incentives_combos_lookup_res b
WHere a.gid = b.pt_gid;

-- add an index
CREATE INDEX pt_grid_us_res_new_solar_incentive_btree 
ON diffusion_shared.pt_grid_us_res_new
USING btree(solar_incentive_array_id);

-- check that we got tem all
SELECT count(*)
FROM diffusion_shared.pt_grid_us_res_new
where solar_incentive_array_id is not null;
--7953816

SELECT count(*)
FROM diffusion_solar_data.dsire_incentives_combos_lookup_res
where incentive_array_id is not null;
--7953816

--unnest the data from the unique combos table
DROP TABLE IF EXISTS diffusion_solar.dsire_incentives_simplified_lkup_res;
CREATE TABLE diffusion_solar.dsire_incentives_simplified_lkup_res AS
SELECT incentive_array_id as incentive_array_id, 
	unnest(solar_incentives_uid_array) as incentives_uid
FROM diffusion_solar_data.dsire_incentives_unique_combos_res;

-- create index
CREATE INDEX dsire_incentives_simplified_lkup_res_inc_id_btree
ON diffusion_solar.dsire_incentives_simplified_lkup_res
USING btree(incentive_array_id);	
------------------------------------------------------------------------------------------------------------


------------------------------------------------------------------------------------------------------------
-- REEDS REGIONS AND PCAS
------------------------------------------------------------------------------------------------------------	
DROP TABLE IF EXISTS  diffusion_wind_data.pt_grid_us_res_new_pca_reg_lookup;
CREATE TABLE  diffusion_wind_data.pt_grid_us_res_new_pca_reg_lookup 
(
	gid integer,
	pca_reg integer,
	reeds_reg integer
);

SELECT parsel_2('dav-gis','mgleason','mgleason','diffusion_shared.pt_grid_us_res_new','gid',
		'SELECT a.gid, b.pca_reg, b.demreg as reeds_reg
		FROM  diffusion_shared.pt_grid_us_res_new a
		INNER JOIN reeds.reeds_regions b
		ON ST_Intersects(a.the_geom_4326,b.the_geom)
		WHERE b.pca_reg NOT IN (135,136);',
	' diffusion_wind_data.pt_grid_us_res_new_pca_reg_lookup', 'a',16);

-- add primary key to the lookup table
ALTER TABLE diffusion_wind_data.pt_grid_us_res_new_pca_reg_lookup
ADD PRIMARY KEY (gid);

-- join the info back in
UPDATE diffusion_shared.pt_grid_us_res_new a
SET (pca_reg,reeds_reg) = (b.pca_reg,b.reeds_reg)
FROM  diffusion_wind_data.pt_grid_us_res_new_pca_reg_lookup b
where a.gid = b.gid;

-- how many are null?
CREATE INDEX pt_grid_us_res_new_pca_reg_btree 
ON diffusion_shared.pt_grid_us_res_new 
USING btree(pca_reg);

CREATE INDEX pt_grid_us_res_new_reeds_reg_btree 
ON diffusion_shared.pt_grid_us_res_new 
USING btree(reeds_reg);

-- any missing?
select count(*)
FROM diffusion_shared.pt_grid_us_res_new 
where pca_reg is null or reeds_reg is null;
--2549

select count(*)
FROM diffusion_shared.pt_grid_us_res_new 
where pca_reg is null;
-- 2549

select count(*)
FROM diffusion_shared.pt_grid_us_res_new 
where reeds_reg is null;
-- 2549

-- fix the missing based on the closest
VACUUM ANALYZE diffusion_shared.pt_grid_us_res_new ;
DROP TABLE IF EXISTS  diffusion_wind_data.pt_grid_us_res_new_pca_reg_missing_lookup;
CREATE TABLE  diffusion_wind_data.pt_grid_us_res_new_pca_reg_missing_lookup AS
with a AS
(
	select gid, the_geom_4326
	FROM diffusion_shared.pt_grid_us_res_new
	where pca_reg is null
),
b as 
(
	SELECT a.gid, a.the_geom_4326, 
		(SELECT b.gid
		 FROM diffusion_shared.pt_grid_us_res_new b
		 where b.pca_reg is not null
		 ORDER BY a.the_geom_4326 <#> b.the_geom_4326
		 LIMIT 1) as nn_gid
	FROM a
	)
SELECT b.gid, b.the_geom_4326, b.nn_gid, c.pca_reg, c.reeds_reg
from b
LEFT JOIN diffusion_shared.pt_grid_us_res_new c
ON b.nn_gid = c.gid;
  
--update the points table
UPDATE diffusion_shared.pt_grid_us_res_new a
SET (pca_reg,reeds_reg) = (b.pca_reg,b.reeds_reg)
FROM  diffusion_wind_data.pt_grid_us_res_new_pca_reg_missing_lookup b
where a.gid = b.gid
and a.pca_reg is null;
 
-- check for any remaining nulls?
select count(*)
FROM diffusion_shared.pt_grid_us_res_new 
where pca_reg is null or reeds_reg is null;
------------------------------------------------------------------------------------------------------------


------------------------------------------------------------------------------------------------------------
-- NSRDB GRID GIDs
------------------------------------------------------------------------------------------------------------	
DROP TABLE IF EXISTS  diffusion_solar_data.pt_grid_us_res_new_solar_re_9809_lookup;
CREATE TABLE  diffusion_solar_data.pt_grid_us_res_new_solar_re_9809_lookup 
(
	gid integer,
	solar_re_9809_gid integer
);


SELECT parsel_2('dav-gis','mgleason','mgleason','diffusion_shared.pt_grid_us_res_new','gid',
		'SELECT a.gid, b.gid as solar_re_9809_gid
		FROM  diffusion_shared.pt_grid_us_res_new a
		INNER JOIN solar.solar_re_9809 b
		ON ST_Intersects(a.the_geom_4326,b.the_geom_4326);',
	'diffusion_solar_data.pt_grid_us_res_new_solar_re_9809_lookup', 'a',16);

-- add primary key on the lookup table
ALTER TABLE diffusion_solar_data.pt_grid_us_res_new_solar_re_9809_lookup
ADD PRIMARY KEY (gid);

-- join the info back in
UPDATE diffusion_shared.pt_grid_us_res_new a
SET solar_re_9809_gid = b.solar_re_9809_gid
FROM  diffusion_solar_data.pt_grid_us_res_new_solar_re_9809_lookup  b
where a.gid = b.gid;

-- how many are null?
CREATE INDEX pt_grid_us_res_new_solar_re_9809_gid_btree 
ON diffusion_shared.pt_grid_us_res_new 
USING btree(solar_re_9809_gid);

-- any missing?
select count(*)
FROM diffusion_shared.pt_grid_us_res_new 
where solar_re_9809_gid is null;
-- 361

-- fix the missing based on the closest
VACUUM ANALYZE diffusion_shared.pt_grid_us_res_new;
DROP TABLE IF EXISTS  diffusion_solar_data.pt_grid_us_solar_re_9809_gid_missing_lookup;
CREATE TABLE  diffusion_solar_data.pt_grid_us_solar_re_9809_gid_missing_lookup AS
with a AS
(
	select gid, the_geom_4326
	FROM diffusion_shared.pt_grid_us_res_new
	where solar_re_9809_gid is null
)
SELECT a.gid, a.the_geom_4326, 
	(SELECT b.solar_re_9809_gid
	 FROM diffusion_shared.pt_grid_us_res_new b
	 where b.solar_re_9809_gid is not null
	 ORDER BY a.the_geom_4326 <#> b.the_geom_4326
	 LIMIT 1) as solar_re_9809_gid
	FROM a;
  
--update the points table
UPDATE diffusion_shared.pt_grid_us_res_new a
SET solar_re_9809_gid = b.solar_re_9809_gid
FROM  diffusion_solar_data.pt_grid_us_solar_re_9809_gid_missing_lookup b
where a.gid = b.gid
and a.solar_re_9809_gid is null;
 
-- check for any remaining nulls?
select count(*)
FROM diffusion_shared.pt_grid_us_res_new 
where solar_re_9809_gid is null;
------------------------------------------------------------------------------------------------------------


------------------------------------------------------------------------------------------------------------
-- ENERGY PLUS HDF INDEX
------------------------------------------------------------------------------------------------------------
-- load in the energy plus hdf index associated with each point
-- the energy plus simulations are based on TMY3 stations
-- for each nsrdb grid, we know the "best match" TMY3 station, so we can just link
-- to that off of the nsrdb_gid
-- there will be gaps due to missing stations, which will fix with a nearest neighbor search
UPDATE diffusion_shared.pt_grid_us_res_new a
SET hdf_load_index = b.hdf_index
FROM diffusion_shared.solar_re_9809_to_eplus_load_res b
where a.solar_re_9809_gid = b.solar_re_9809_gid;

-- create index on the hdf_load_index
CREATE INDEX pt_grid_us_res_new_hdf_load_index
ON diffusion_shared.pt_grid_us_res_new
using btree(hdf_load_index);

-- check for nulls
SELECT count(*)
FROM diffusion_shared.pt_grid_us_res_new
where hdf_load_index is null;
-- 14024 rows

-- find the value of the nearest neighbor
VACUUM ANALYZE diffusion_shared.pt_grid_us_res_new;
DROP TABLE IF EXISTS  diffusion_solar_data.pt_grid_us_res_new_missing_hdf_load_lookup;
CREATE TABLE  diffusion_solar_data.pt_grid_us_res_new_missing_hdf_load_lookup AS
with a AS
(
	select gid, the_geom_4326
	FROM diffusion_shared.pt_grid_us_res_new
	where hdf_load_index is null
)
SELECT a.gid, a.the_geom_4326, 
	(
		SELECT b.hdf_load_index
		 FROM diffusion_shared.pt_grid_us_res_new b
		 where b.hdf_load_index is not null
		 ORDER BY a.the_geom_4326 <#> b.the_geom_4326
		 LIMIT 1
	 ) as hdf_load_index
	FROM a;

UPDATE diffusion_shared.pt_grid_us_res_new a
SET hdf_load_index = b.hdf_load_index
FROM  diffusion_solar_data.pt_grid_us_res_new_missing_hdf_load_lookup b
where a.gid = b.gid
and a.hdf_load_index is null;

-- check for nulls again
SELECT count(*)
FROM diffusion_shared.pt_grid_us_res_new
where hdf_load_index is null;
--
------------------------------------------------------------------------------------------------------------


------------------------------------------------------------------------------------------------------------
-- PERCENT HIGH INTENSITY DEVELOPED LAND (NLCD Class 24)
------------------------------------------------------------------------------------------------------------
DROP TABLE IF EXISTS diffusion_wind_data.pt_grid_us_res_new_hi_dev_pct_lookup;
CREATE TABLE diffusion_wind_data.pt_grid_us_res_new_hi_dev_pct_lookup (
	gid integer,
	hi_dev_pct integer);

--run in parallel for speed
SELECT parsel_2('dav-gis','mgleason','mgleason','diffusion_shared.pt_grid_us_res_new','gid',
		'SELECT a.gid, ST_Value(b.rast,a.the_geom_4326) as hi_dev
		FROM  diffusion_shared.pt_grid_us_res_new a
		INNER JOIN diffusion_wind_data.nlcd_2011_cl24_pct_100x100 b
		ON ST_Intersects(b.rast,a.the_geom_4326);',
			'diffusion_wind_data.pt_grid_us_res_new_hi_dev_pct_lookup', 'a',16);

-- add a primary key on the lookup table
ALTER TABLE diffusion_wind_data.pt_grid_us_res_new_hi_dev_pct_lookup
ADD PRIMARY KEY (gid);

-- join the info back in
UPDATE diffusion_shared.pt_grid_us_res_new a
SET hi_dev_pct = b.hi_dev_pct
FROM diffusion_wind_data.pt_grid_us_res_new_hi_dev_pct_lookup b
where a.gid = b.gid;

-- set the remainders to values of zero
UPDATE diffusion_shared.pt_grid_us_res_new
set hi_dev_pct = 0
where hi_dev_pct is null;

-- create an index
CREATE INDEX pt_grid_us_res_new_hi_dev_pct_btree 
ON diffusion_shared.pt_grid_us_res_new 
USING btree(hi_dev_pct);

-- make sure no nulls
SELECT count(*)
FROM diffusion_shared.pt_grid_us_res_new
where hi_dev_pct is null;
-- 0

-- check how many pts are excluded
with a as
(
	SELECT case 	when hi_dev_pct > 96 then 0 
			when hi_dev_pct > 91 and hi_dev_pct <= 96 then 20
			when hi_dev_pct > 84 and hi_dev_pct <= 91 then 30
			when hi_dev_pct > 75 and hi_dev_pct <= 84 then 40
			when hi_dev_pct > 26 and hi_dev_pct <= 75 then 50
			when hi_dev_pct <= 26 then 80
		end as max_turbine_height
        from diffusion_shared.pt_grid_us_res_new
)
select max_turbine_height, count(*)
FROM a
group by max_turbine_height
order by 1;
------------------------------------------------------------------------------------------------------------


------------------------------------------------------------------------------------------------------------
-- PERCENT CANOPY COVER
------------------------------------------------------------------------------------------------------------
DROP TABLE IF EXISTS diffusion_wind_data.pt_grid_us_res_new_canopy_pct_lookup;
CREATE TABLE diffusion_wind_data.pt_grid_us_res_new_canopy_pct_lookup (
	gid integer,
	canopy_pct integer);

--run in parallel for speed
SELECT parsel_2('dav-gis','mgleason','mgleason','diffusion_shared.pt_grid_us_res_new','gid',
		'SELECT a.gid, ST_Value(b.rast,a.the_geom_4326) as canopy_pct
		FROM  diffusion_shared.pt_grid_us_res_new a
		INNER JOIN diffusion_wind_data.canopy_pct_100x100 b
		ON ST_Intersects(b.rast,a.the_geom_4326);',
			'diffusion_wind_data.pt_grid_us_res_new_canopy_pct_lookup', 'a',16);

-- add a primary key on the lookup table
ALTER TABLE diffusion_wind_data.pt_grid_us_res_new_canopy_pct_lookup
ADD PRIMARY KEY (gid);

-- join the info back in
UPDATE diffusion_shared.pt_grid_us_res_new a
SET canopy_pct = b.canopy_pct
FROM diffusion_wind_data.pt_grid_us_res_new_canopy_pct_lookup b
where a.gid = b.gid;

-- create an index
CREATE INDEX pt_grid_us_res_new_canopy_pct_btree 
ON diffusion_shared.pt_grid_us_res_new 
USING btree(canopy_pct);

-- check for nulls
SELECT count(*)
FROM diffusion_shared.pt_grid_us_res_new
where canopy_pct is null;
-- 0

-- check how many pts are >= 25% can cover
SELECT count(*)
FROM diffusion_shared.pt_grid_us_res_new
where canopy_pct >= 25;
-- 2,472,185 (out of ~6 mil)
------------------------------------------------------------------------------------------------------------


------------------------------------------------------------------------------------------------------------
-- CANOPY HEIGHT
------------------------------------------------------------------------------------------------------------
DROP TABLE IF EXISTS diffusion_wind_data.pt_grid_us_res_new_canopy_height_lookup;
CREATE TABLE diffusion_wind_data.pt_grid_us_res_new_canopy_height_lookup (
	gid integer,
	canopy_ht_m integer);

--run in parallel for speed
SELECT parsel_2('dav-gis','mgleason','mgleason','diffusion_shared.pt_grid_us_res_new','gid',
		'SELECT a.gid, ST_Value(b.rast,a.the_geom_4326)/10. as canopy_ht_m
		FROM  diffusion_shared.pt_grid_us_res_new a
		INNER JOIN diffusion_wind_data.canopy_height_100x100 b
		ON ST_Intersects(b.rast,a.the_geom_4326);',
			'diffusion_wind_data.pt_grid_us_res_new_canopy_height_lookup', 'a',16);

-- add a primary key on the lookup table
ALTER TABLE diffusion_wind_data.pt_grid_us_res_new_canopy_height_lookup
ADD PRIMARY KEY (gid);

-- join the info back in
UPDATE diffusion_shared.pt_grid_us_res_new a
SET canopy_ht_m = b.canopy_ht_m
FROM diffusion_wind_data.pt_grid_us_res_new_canopy_height_lookup b
where a.gid = b.gid;

-- create an index
CREATE INDEX pt_grid_us_res_new_canopy_ht_m_btree 
ON diffusion_shared.pt_grid_us_res_new 
USING btree(canopy_ht_m);

-- check how many have a null canopy ht where canopy pct is > 0
DROP TABLE IF EXISTS diffusion_wind_data.pt_grid_us_res_new_missing_canopy_height;
CREATE TABLE diffusion_wind_data.pt_grid_us_res_new_missing_canopy_height AS
SElect gid, the_geom_4326, canopy_ht_m, canopy_pct
FROM diffusion_shared.pt_grid_us_res_new
where canopy_ht_m is null
and canopy_pct > 0;
-- 903523 rows

-- fix by buffering points by 600 and running a zonal statistics on them (this will be second order queens contiguity search)
-- create buffered geometry
ALTER TABLE diffusion_wind_data.pt_grid_us_res_new_missing_canopy_height
ADD COLUMN the_buffer_600m_4326 geometry;

UPDATE diffusion_wind_data.pt_grid_us_res_new_missing_canopy_height
set the_buffer_600m_4326 = ST_Buffer(the_geom_4326::geography, 600)::geometry;

-- create an index
CREATE INDEX pt_grid_us_res_new_missing_canopy_height_the_buffer_gist
ON diffusion_wind_data.pt_grid_us_res_new_missing_canopy_height
using btree(the_buffer_600m_4326);

-- add primary key
ALTER TABLE diffusion_wind_data.pt_grid_us_res_new_missing_canopy_height
ADD PRIMARY KEY (gid);

-- now fix using zonal statistics of the 9 surrounding cells (mean)
DROP TABLE IF EXISTS diffusion_wind_data.pt_grid_us_res_new_missing_canopy_height_fixed;
CREATE TABLE diffusion_wind_data.pt_grid_us_res_new_missing_canopy_height_fixed 
(
	gid integer,
	avg_canopy_ht numeric
);

select parsel_2('dav-gis','mgleason', 'mgleason',
		'diffusion_wind_data.pt_grid_us_res_new_missing_canopy_height',
		'gid',
		'WITH tile_stats as 
		(
			select a.gid,
				ST_SummaryStats(ST_Clip(b.rast, 1, a.the_buffer_600m_4326, true)) as stats
			FROM diffusion_wind_data.pt_grid_us_res_new_missing_canopy_height as a
			INNER JOIN diffusion_wind_data.canopy_height_100x100 b
				ON ST_Intersects(b.rast, the_buffer_600m_4326)
		)
			--aggregate the results from each tile
		SELECT gid, sum((stats).sum)/sum((stats).count)/10. as avg_canopy_ht
		FROM tile_stats
		GROUP by gid',
		'diffusion_wind_data.pt_grid_us_res_new_missing_canopy_height_fixed ',
		'a',16);

-- add primary key
ALTER TABLE diffusion_wind_data.pt_grid_us_res_new_missing_canopy_height_fixed
ADD PRIMARY KEY (gid);

-- how many were fixed?
SELECT count(*)
FROM diffusion_wind_data.pt_grid_us_res_new_missing_canopy_height_fixed
where avg_canopy_ht is not null;
-- 835342

-- add these to the main table
UPDATE diffusion_shared.pt_grid_us_res_new a
SET canopy_ht_m = b.avg_canopy_ht
FROM  diffusion_wind_data.pt_grid_us_res_new_missing_canopy_height_fixed b
where a.gid = b.gid
AND a.canopy_ht_m is null
and a.canopy_pct > 0
and b.avg_canopy_ht is not null;
-- 835342 rows

-- for remaining ones that weren't fixed, set the canopy height to 5 m
-- This is the minimum height for tree canopy cover in the NLCD pct canopy cover raster
-- Remaining areas are those that likely had no trees in 2000 (vintage of canopy height raster)
-- and 2011 (vintage of canopy cover raster), so I am going to assume that they are small trees. 
UPDATE diffusion_shared.pt_grid_us_res_new a
SET canopy_ht_m = 5
where a.canopy_ht_m is null
and a.canopy_pct > 0;
-- 68181 rows

-- set everything that remains (all nulls) to height of zero
UPDATE diffusion_shared.pt_grid_us_res_new a
SET canopy_ht_m = 0
where a.canopy_ht_m is null
and a.canopy_pct = 0;
-- 662751 rows

-- check for nulls
SELECT count(*)
FROM diffusion_shared.pt_grid_us_res_new
where canopy_ht_m is null;
--  0 rows

-- make sure no heights of zero where canopy pct >0
SELECT min(canopy_ht_m)
FROM diffusion_shared.pt_grid_us_res_new
where canopy_pct > 0;
-- 3
------------------------------------------------------------------------------------------------------------


------------------------------------------------------------------------------------------------------------
-- CENSUS 2010 BLOCK ID
------------------------------------------------------------------------------------------------------------
-- create block id lookup table
DROP TABLE IF EXISTS  diffusion_wind_data.pt_grid_us_res_new_census_2010_block_lkup;
CREATE TABLE  diffusion_wind_data.pt_grid_us_res_new_census_2010_block_lkup 
(
	gid integer,
	the_geom_96703 geometry,
	block_gisjoin character varying(18),
	aland10 numeric
);

SELECT parsel_2('dav-gis','mgleason','mgleason',
		'diffusion_shared.pt_grid_us_res_new',
		'gid',
		'SELECT a.gid, a.the_geom_96703, c.gisjoin as block_gisjoin, c.aland10
		FROM diffusion_shared.pt_grid_us_res_new a
		LEFT JOIN diffusion_shared.county_geom b
			ON a.county_id = b.county_id
		LEFT JOIN census_2010.block_geom_parent c
			ON b.state_abbr = c.state_abbr
			AND ST_Intersects(a.the_geom_4326, c.the_geom_4326)',
		'diffusion_wind_data.pt_grid_us_res_new_census_2010_block_lkup', 
		'a',16);

-- create a primary key on the lookup table
ALTER tABLE diffusion_wind_data.pt_grid_us_res_new_census_2010_block_lkup
ADD PRIMARY KEY (gid);

-- create index on the block_gisjoin col
CREATE iNDEX pt_grid_us_res_new_census_2010_block_lkup_gisjoin_btree
ON diffusion_wind_data.pt_grid_us_res_new_census_2010_block_lkup
using btree(block_gisjoin);

-- create index on geometry too
CREATE iNDEX pt_grid_us_res_new_census_2010_block_lkup_the_geom_4326_gist
ON diffusion_wind_data.pt_grid_us_res_new_census_2010_block_lkup
using btree(the_geom_96703);

CLUSTER diffusion_wind_data.pt_grid_us_res_new_census_2010_block_lkup
USING pt_grid_us_res_new_census_2010_block_lkup_the_geom_4326_gist;

VACUUM ANALYZE diffusion_wind_data.pt_grid_us_res_new_census_2010_block_lkup;

-- check for nulls
select count(*)
FROM diffusion_wind_data.pt_grid_us_res_new_census_2010_block_lkup
where block_gisjoin is null;
-- 2411

-- fix with nearest neighbor
DROP TABLE IF EXISTS diffusion_wind_data.pt_grid_us_res_new_census_2010_block_lkup_missing_lkup;
CREATE TABLE diffusion_wind_data.pt_grid_us_res_new_census_2010_block_lkup_missing_lkup AS
with a as
(
	SELECT gid, the_geom_96703
	FROM diffusion_wind_data.pt_grid_us_res_new_census_2010_block_lkup
	where block_gisjoin is null
),
b AS
(
	SELECT gid, the_geom_96703, array[block_gisjoin, aland10::text] as nn
	FROM diffusion_wind_data.pt_grid_us_res_new_census_2010_block_lkup
	where block_gisjoin is NOT null

),
c as 
(
	
	SELECT a.gid,
	(
		SELECT b.nn
		 FROM b
		 ORDER BY a.the_geom_96703 <-> b.the_geom_96703
		 LIMIT 1
	 ) as nn
	FROM a
)
SELECT gid, nn[1] as block_gisjoin, nn[2]::numeric as aland10
from c;

UPDATE diffusion_wind_data.pt_grid_us_res_new_census_2010_block_lkup a
SET (block_gisjoin, aland10) = (b.block_gisjoin, b.aland10)
FROM  diffusion_wind_data.pt_grid_us_res_new_census_2010_block_lkup_missing_lkup b
where a.gid = b.gid
and a.block_gisjoin is null;

-- check for nulls again
select count(*)
FROM diffusion_wind_data.pt_grid_us_res_new_census_2010_block_lkup
where block_gisjoin is null;
------------------------------------------------------------------------------------------------------------


------------------------------------------------------------------------------------------------------------
-- CENSUS 2010 ACRES PER HOUSING UNIT (BLOCKS)
------------------------------------------------------------------------------------------------------------
ALTER TABLE diffusion_wind_data.pt_grid_us_res_new_census_2010_block_lkup set (fillfactor = 50);
VACUUM FULL diffusion_wind_data.pt_grid_us_res_new_census_2010_block_lkup;

ALTER TABLE diffusion_wind_data.pt_grid_us_res_new_census_2010_block_lkup
ADD COLUMN housing_units INTEGER,
ADD COLUMN acres_per_hu numeric;

UPDATE diffusion_wind_data.pt_grid_us_res_new_census_2010_block_lkup a
SET (housing_units, 
	acres_per_hu) = (b.housing_units,
			CASE WHEN b.housing_units > 0 THEN (a.aland10/4046.86)::numeric/b.housing_units
				   else 100
				   end)		
FROM diffusion_wind_data.census_2010_block_housing_units b
where a.block_gisjoin = b.gisjoin;

-- check for nulls
select count(*)
FROM diffusion_wind_data.pt_grid_us_res_new_census_2010_block_lkup
where acres_per_hu is null
or housing_units is null;
-- 0

-- calculate the hu portion
ALTER TABLE diffusion_wind_data.pt_grid_us_res_new_census_2010_block_lkup
ADD COLUMN hu_portion numeric;

with b as
(
	SELEct block_gisjoin, count(gid)
	from diffusion_wind_data.pt_grid_us_res_new_census_2010_block_lkup
	group by block_gisjoin
)
UPDATE diffusion_wind_data.pt_grid_us_res_new_census_2010_block_lkup a
set hu_portion = housing_units::numeric/b.count
from b
where a.block_gisjoin = b.block_gisjoin;

-- add this info back to the main table
UPDATE diffusion_shared.pt_grid_us_res_new a
SET (hu_portion, acres_per_hu) = (b.hu_portion, b.acres_per_hu)
from diffusion_wind_data.pt_grid_us_res_new_census_2010_block_lkup b
where a.gid = b.gid;

-- ensure no nulls
select count(*)
FROM diffusion_shared.pt_grid_us_res_new
where acres_per_hu is null
and hu_portion is null;

-- how many with restrictions of various amounts?
select count(*)
FROM diffusion_shared.pt_grid_us_res_new
-- where acres_per_hu < 3 -- 891588
-- where acres_per_hu < 1 -- 663482
where acres_per_hu < .5 -- 464167

-- remove points in blocks with zero housing units (archive first, then delete)
DROP TABLE IF EXISTS diffusion_shared.pt_grid_us_res_new_no_hu;
CREATE TABLE diffusion_shared.pt_grid_us_res_new_no_hu AS
SELECT *
FROM diffusion_shared.pt_grid_us_res_new
where hu_portion = 0;
-- 204821

DELETE FROM diffusion_shared.pt_grid_us_res_new
where hu_portion = 0;
------------------------------------------------------------------------------------------------------------


------------------------------------------------------------------------------------------------------------
-- ACS 2012 BLOCKGROUP ID
------------------------------------------------------------------------------------------------------------
-- create block id lookup table
DROP TABLE IF EXISTS  diffusion_wind_data.pt_grid_us_res_new_acs_2012_blockgroup_lkup;
CREATE TABLE  diffusion_wind_data.pt_grid_us_res_new_acs_2012_blockgroup_lkup 
(
	gid integer,
	the_geom_96703 geometry,
	blockgroup_gisjoin character varying(18),
	aland numeric
);

SELECT parsel_2('dav-gis','mgleason','mgleason',
		'diffusion_shared.pt_grid_us_res_new',
		'gid',
		'SELECT a.gid, a.the_geom_96703,
			c.gisjoin as blockgroup_gisjoin,
			c.aland
		FROM diffusion_shared.pt_grid_us_res_new a
		LEFT JOIN diffusion_shared.county_geom b
			ON a.county_id = b.county_id
		LEFT JOIN acs_2012.blockgroup_geom_parent c
			ON b.state_abbr = c.state_abbr
			AND ST_Intersects(a.the_geom_4326, c.the_geom_4326)',
		'diffusion_wind_data.pt_grid_us_res_new_acs_2012_blockgroup_lkup', 
		'a',16);

-- create a primary key on the lookup table
ALTER tABLE diffusion_wind_data.pt_grid_us_res_new_acs_2012_blockgroup_lkup
ADD PRIMARY KEY (gid);

-- create index on the block_gisjoin col
CREATE iNDEX pt_grid_us_res_new_acs_2012_blockgroup_lkup_gisjoin_btree
ON diffusion_wind_data.pt_grid_us_res_new_acs_2012_blockgroup_lkup
using btree(blockgroup_gisjoin);

-- create index on geometry too
CREATE iNDEX pt_grid_us_res_new_acs_2012_blockgroup_lkup_the_geom_96703_gist
ON diffusion_wind_data.pt_grid_us_res_new_acs_2012_blockgroup_lkup
using btree(the_geom_96703);

CLUSTER diffusion_wind_data.pt_grid_us_res_new_acs_2012_blockgroup_lkup
USING pt_grid_us_res_new_acs_2012_blockgroup_lkup_the_geom_96703_gist;

VACUUM ANALYZE diffusion_wind_data.pt_grid_us_res_new_acs_2012_blockgroup_lkup;

-- check for nulls
select count(*)
FROM diffusion_wind_data.pt_grid_us_res_new_acs_2012_blockgroup_lkup
where blockgroup_gisjoin is null;
-- 2318

-- fix with nearest neighbor
DROP TABLE IF EXISTS diffusion_wind_data.pt_grid_us_res_new_acs_2012_blockgroup_lkup_missing_lkup;
explain
CREATE TABLE diffusion_wind_data.pt_grid_us_res_new_acs_2012_blockgroup_lkup_missing_lkup AS
with a as
(
	SELECT gid, the_geom_96703
	FROM diffusion_wind_data.pt_grid_us_res_new_acs_2012_blockgroup_lkup
	where blockgroup_gisjoin is null
),
c as 
(
	SELECT a.gid,
	(
		SELECT array[b.blockgroup_gisjoin, b.aland::text] as nn
		 FROM diffusion_wind_data.pt_grid_us_res_new_acs_2012_blockgroup_lkup b
		 where b.blockgroup_gisjoin is NOT null
		 ORDER BY a.the_geom_96703 <-> b.the_geom_96703
		 LIMIT 1
	 ) as nn
	 from a
)
SELECT gid, nn[1] as blockgroup_gisjoin, nn[2]::numeric as aland
from c;

UPDATE diffusion_wind_data.pt_grid_us_res_new_acs_2012_blockgroup_lkup a
SET (blockgroup_gisjoin, aland) = (b.blockgroup_gisjoin, b.aland)
FROM  diffusion_wind_data.pt_grid_us_res_new_acs_2012_blockgroup_lkup_missing_lkup b
where a.gid = b.gid
and a.blockgroup_gisjoin is null;

-- check for nulls again
select count(*)
FROM diffusion_wind_data.pt_grid_us_res_new_acs_2012_blockgroup_lkup
where blockgroup_gisjoin is null
or aland is null;
------------------------------------------------------------------------------------------------------------


------------------------------------------------------------------------------------------------------------
-- ACS 2012 OWNER-OCCUPIED SINGLE FAMILY HOUSING UNITS
------------------------------------------------------------------------------------------------------------
ALTER TABLE diffusion_wind_data.pt_grid_us_res_new_acs_2012_blockgroup_lkup 
set (fillfactor = 50);
VACUUM FULL diffusion_wind_data.pt_grid_us_res_new_acs_2012_blockgroup_lkup;

ALTER TABLE diffusion_wind_data.pt_grid_us_res_new_acs_2012_blockgroup_lkup
ADD COLUMN blkgrp_ownocc_sf_hu integer,
add column blkgrp_ownocc_sf_hu_portion numeric;

UPDATE diffusion_wind_data.pt_grid_us_res_new_acs_2012_blockgroup_lkup a
SET blkgrp_ownocc_sf_hu = b.total_own_occ_1str_and_mobile
FROM diffusion_wind_data.acs_2012_blockgroup_tenure_by_units_in_structure b
where a.blockgroup_gisjoin = b.gisjoin;

-- add sf_hu_portion
with b as
(
	SELEct blockgroup_gisjoin, count(gid)
	from diffusion_wind_data.pt_grid_us_res_new_acs_2012_blockgroup_lkup
	group by blockgroup_gisjoin
)
UPDATE diffusion_wind_data.pt_grid_us_res_new_acs_2012_blockgroup_lkup a
set blkgrp_ownocc_sf_hu_portion = blkgrp_ownocc_sf_hu::numeric/b.count
from b
where a.blockgroup_gisjoin = b.blockgroup_gisjoin;

-- check for nulls
select count(*)
FROM diffusion_wind_data.pt_grid_us_res_new_acs_2012_blockgroup_lkup
where blkgrp_ownocc_sf_hu is null
or blkgrp_ownocc_sf_hu_portion is null;
-- 0


ALTER TABLE diffusion_wind_data.pt_grid_us_res_new_acs_2012_blockgroup_lkup 
set (fillfactor = 100);
VACUUM FULL diffusion_wind_data.pt_grid_us_res_new_acs_2012_blockgroup_lkup;

-- add this info back to the main table
UPDATE diffusion_shared.pt_grid_us_res_new a
SET blkgrp_ownocc_sf_hu_portion = b.blkgrp_ownocc_sf_hu_portion
from diffusion_wind_data.pt_grid_us_res_new_acs_2012_blockgroup_lkup b
where a.gid = b.gid;

-- ensure no nulls
select count(*)
FROM diffusion_shared.pt_grid_us_res_new
where blkgrp_ownocc_sf_hu_portion is null;
-- 0

-- add an index
CREATE INDEX pt_grid_us_res_new_blkgrp_ownocc_sf_hu_portion_btree
ON diffusion_shared.pt_grid_us_res_new
using btree(blkgrp_ownocc_sf_hu_portion);
------------------------------------------------------------------------------------------------------------


------------------------------------------------------------------------------------------------------------
-- RANKED RATE ARRAY ID
------------------------------------------------------------------------------------------------------------
-- this is added later as part of ./19_curating_urdb_rates/21_find_unique_rate_rank_arrays.sql
------------------------------------------------------------------------------------------------------------


------------------------------------------------------------------------------------------------------------
-- ULOCALE
------------------------------------------------------------------------------------------------------------
DROP TABLE IF EXISTS  diffusion_data_wind.pt_grid_us_res_ulocale_lkup;
CREATE TABLE  diffusion_data_wind.pt_grid_us_res_ulocale_lkup 
(
	gid integer,
	ulocale integer
);

SELECT parsel_2('dav-gis','mgleason','mgleason',
		'diffusion_shared.pt_grid_us_res',
		'gid',
		'SELECT a.gid, CASE WHEN b.ulocale IS NULL THEN -999::INTEGER -- change nulls to -999
				    WHEN b.ulocale = 0 THEN -999::INTEGER -- use -999 instead of zero for unknown
				    WHEN b.ulocale IN (43, 42) THEN 41::INTEGER -- lump rural into one code
				    WHEN b.ulocale in (33, 32) THEN 31::INTEGER -- lump town into one code
				    ELSE b.ulocale::INTEGER
                           END as ulocale
		FROM diffusion_shared.pt_grid_us_res a
		LEFT JOIN  pv_rooftop.locale b
			ON ST_Intersects(a.the_geom_96703, b.the_geom_96703)',
		'diffusion_data_wind.pt_grid_us_res_ulocale_lkup', 
		'a',16);

-- create a primary key on the lookup table
ALTER tABLE diffusion_data_wind.pt_grid_us_res_ulocale_lkup
ADD PRIMARY KEY (gid);

-- check for nulls (there shouldn't be any -- they should be -999 instead)
select count(*)
FROM diffusion_data_wind.pt_grid_us_res_ulocale_lkup
where ulocale is null;
-- 

-- add back to the main table
ALTER TABLE diffusion_shared.pt_grid_us_res
ADD COLUMN ulocale integer;

UPDATE diffusion_shared.pt_grid_us_res a
SET ulocale = b.ulocale
FROM diffusion_data_wind.pt_grid_us_res_ulocale_lkup b
WHERe a.gid = b.gid;

-- add index
CREATE INDEX pt_grid_us_res_ulocale_btree
ON diffusion_shared.pt_grid_us_res
USING BTREE(ulocale);

-- make sure no nulls
select count(*)
FROM diffusion_shared.pt_grid_us_res
where ulocale is null;
------------------------------------------------------------------------------------------------------------



------------------------------------------------------------------------------------------------------------
-- RESET THE FILL FACTOR
------------------------------------------------------------------------------------------------------------
ALTER TABLE diffusion_shared.pt_grid_us_res_new
SET (fillfactor = 100);

VACUUM FULL diffusion_shared.pt_grid_us_res_new;
------------------------------------------------------------------------------------------------------------


------------------------------------------------------------------------------------------------------------
-- CLEANUP (ADD/REMOVE) INDICES
------------------------------------------------------------------------------------------------------------
-- indices are geared towards facilitating creation of pt microdata tables
-- following indices should be kept:
  -- county_id: diffusion_shared.pt_grid_us_res_new_county_id_btree
  -- pca_reg: diffusion_shared.pt_grid_us_res_new_pca_reg_btree
  -- reeds_reg: diffusion_shared.pt_grid_us_res_new_reeds_reg_btree
  -- hdf_load_index: diffusion_shared.pt_grid_us_res_new_hdf_load_index
  -- utility_type: diffusion_shared.pt_grid_us_res_new_utility_type_btree
  -- iiijjjicf_id: diffusion_shared.pt_grid_us_res_new_iiijjjicf_id_btree
  -- solar_re_9809_gid: diffusion_shared.pt_grid_us_res_new_solar_re_9809_gid_btree
  -- solar_incentive_array_id: diffusion_shared.pt_grid_us_res_new_solar_incentive_btree
  -- wind_incentive_array_id: diffusion_shared.pt_grid_us_res_new_wind_incentive_btree
  -- hi_dev_pct: diffusion_shared.pt_grid_us_res_new_hi_dev_pct_btree
  -- canopy_ht_m: diffusion_shared.pt_grid_us_res_new_canopy_ht_m_btree
  -- canopy_pct: diffusion_shared.pt_grid_us_res_new_canopy_pct_btree
  -- acres_per_hu: diffusion_shared.pt_grid_us_res_new_acres_per_hu_btree
  -- housing_units: diffusion_shared.pt_grid_us_res_new_housing_units_btree
  -- blkgrp_ownocc_sf_hu: pt_grid_us_res_new_blkgrp_ownocc_sf_hu_btree
  -- ranked_rate_array_id: pt_grid_us_res_new_ranked_rate_array_id_btree
------------------------------------------------------------------------------------------------------------


------------------------------------------------------------------------------------------------------------
-- REPLACE THE OLD VERSION OF THE TABLE
------------------------------------------------------------------------------------------------------------
DROP TABLE diffusion_shared.pt_grid_us_res CASCADE;

ALTER TABLE diffusion_shared.pt_grid_us_res_new
RENAME TO pt_grid_us_res;
------------------------------------------------------------------------------------------------------------



