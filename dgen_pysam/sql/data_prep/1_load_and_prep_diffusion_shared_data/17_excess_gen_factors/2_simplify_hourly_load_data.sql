-- associate each i, j bin with a transmission zone using area weighted intersect
DROP TABLE IF EXISTS diffusion_wind.ij_tzone_lookup;
CREATE TABLE diffusion_wind.ij_tzone_lookup AS
WITH a AS (
	SELECT a.gid, a.i, a.j,
	b.zone_id, 
	case 	when b.zone_id is NOT null THEN ST_Area(ST_Intersection(a.the_geom_96703, b.the_geom_96703)) 
		else 0
		END as isect_area, 
	a.the_geom_96703
	FROM aws.tmy_grid a
	LEFT JOIN ventyx.transmission_zones_07232013 b
	ON ST_Intersects(a.the_geom_96703, b.the_geom_96703)
	where b.country <> 'Canada' or b.country is null
	)
SELECT DISTINCT ON (a.gid, a.i, a.j) a.gid as tmy_grid_gid, a.i, a.j, a.zone_id as transmission_zone_id, a.the_geom_96703
FROM a
ORDER BY a.gid, a.i, a.j, a.isect_area DESC;

-- check for nulls
select *
FROM diffusion_wind.ij_tzone_lookup
where transmission_zone_id is null;

-- fix the nulls by simply using the nearest neighbor
DROP TABLE IF EXISTS diffusion_wind_data.ij_no_transzone;
CREATE TABLE diffusion_wind_data.ij_no_transzone AS
with candidates as (

SELECT a.tmy_grid_gid, a.the_geom_96703, 
	unnest((select array(SELECT b.zone_id
	 FROM ventyx.transmission_zones_07232013 b
	 ORDER BY a.the_geom_96703 <#> b.the_geom_96703 LIMIT 3))) as zone_id
FROM diffusion_wind.ij_tzone_lookup a
where a.transmission_zone_id is null
 )

SELECT distinct ON (tmy_grid_gid) a.tmy_grid_gid, a.the_geom_96703, a.zone_id as transmission_zone_id
FROM candidates a
lEFT JOIN ventyx.transmission_zones_07232013 b
ON a.zone_id = b.zone_id
ORDER BY tmy_grid_gid, ST_Distance(a.the_geom_96703,b.the_geom_96703) asc;

-- 
UPDATE diffusion_wind.ij_tzone_lookup a
SET transmission_zone_id = b.transmission_zone_id
FROM diffusion_wind_data.ij_no_transzone b
WHERE a.transmission_zone_id is null
and a.tmy_grid_gid = b.tmy_grid_gid;



----------------------------------------------------------------------
-- simplify hourly load data down to 8760

-- first, make sure all zones have 8760
SELECT transmission_zone_id, count(*)
FROM ventyx.hourly_load_by_transmission_zone_20130723
GROUP BY transmission_zone_id
order by count;
-- three zones are missing 1 hour of the year
-- 615529, 1836089, 615603

-- this is because they lost an hour in spring DST, but didn't add it back in in fall DST
with a AS (
SELECT date,count(*)
FROM ventyx.hourly_load_by_transmission_zone_20130723
where transmission_zone_id = 615529
-- where transmission_zone_id = 1836089
-- where transmission_zone_id = 615603
GROUP BY date)

SELECT *
FROM a where count <> 24;

-- compare to:
with a AS (
SELECT date,count(*)
FROM ventyx.hourly_load_by_transmission_zone_20130723
where transmission_zone_id = 615285

GROUP BY date)

SELECT *
FROM a where count <> 24;

-- how to fix -- just use a simple linear interpolation off the preceding and additional values
--copy the data over to a new table
DROP TABLE IF EXISTS ventyx.hourly_load_8760_by_transmission_zone_20130723;
CREATE tABLE ventyx.hourly_load_8760_by_transmission_zone_20130723 AS
SELECT *, 'ventyx'::text as source
FROM ventyx.hourly_load_by_transmission_zone_20130723;

-- extra hour needs to go between 1 am and 2 am and be labeled as 1 am
SELECT *
FROM ventyx.hourly_load_8760_by_transmission_zone_20130723
-- where transmission_zone_id = 615529
-- where transmission_zone_id = 1836089
where transmission_zone_id = 615603
and date = '2010-11-07'
order by hour;

INSERT INTO ventyx.hourly_load_8760_by_transmission_zone_20130723 
(transmission_zone, local_datetime, year, date, hour, load_mw, transmission_zone_id, source)
VALUES 
('Grand River Dam Authority', '2010-11-07 01:00:00', 2010,  '2010-11-07', 1, 397, 615529, 'filled by averaging neighboring values');

INSERT INTO ventyx.hourly_load_8760_by_transmission_zone_20130723 
(transmission_zone, local_datetime, year, date, hour, load_mw, transmission_zone_id, source)
VALUES 
('Pacific Gas & Electric - Bay Area', '2010-11-07 01:00:00', 2010,  '2010-11-07', 1, (9333+4170)/2, 1836089, 'filled by averaging neighboring values');

INSERT INTO ventyx.hourly_load_8760_by_transmission_zone_20130723 
(transmission_zone, local_datetime, year, date, hour, load_mw, transmission_zone_id, source)
VALUES 
('Avista', '2010-11-07 01:00:00', 2010,  '2010-11-07', 1, (1076+1046)/2, 615603, 'filled by averaging neighboring values');

-- check that everything is fixed now
SELECT transmission_zone_id, count(*)
FROM ventyx.hourly_load_8760_by_transmission_zone_20130723
GROUP BY transmission_zone_id
order by count;

ALTER TABLE ventyx.hourly_load_8760_by_transmission_zone_20130723
ADD COLUMN hour_of_year integer;

with b as (
	SELECT transmission_zone_id, date, hour, source, row_number() OVER (PARTITION BY transmission_zone_id ORDER BY date asc, hour asc, source desc) as hour_of_year
	FROM ventyx.hourly_load_8760_by_transmission_zone_20130723)
UPDATE ventyx.hourly_load_8760_by_transmission_zone_20130723 a
SET hour_of_year = b.hour_of_year
FROM b
WHERE a.transmission_zone_id = b.transmission_zone_id
and a.date = b.date
and a.hour = b.hour
and a.source = b.source;

-- check ordering is correct for the filled values
SELECT *
FROM ventyx.hourly_load_8760_by_transmission_zone_20130723
where transmission_zone_id = 615529
-- where transmission_zone_id = 1836089
-- where transmission_zone_id = 615603
and date = '2010-11-07'
order by hour_of_year;
-- all looks good

-- do some more checking
SELECT transmission_zone_id, min(hour_of_year), max(hour_of_year)
FROM ventyx.hourly_load_8760_by_transmission_zone_20130723
GROUP BY transmission_zone_id;

-- looks good -- clean everything else up
-- drop columns
ALTER TABLE ventyx.hourly_load_8760_by_transmission_zone_20130723
DROP COLUMN local_datetime, 
DROP COLUMN time_zone,
DROP COLUMN time_zone_converted_to_dst;

-- add index on transmission_zone and hour of year
CREATE INDEX hourly_load_8760_by_transmission_zone_20130723_transmission_zone_id_btree ON ventyx.hourly_load_8760_by_transmission_zone_20130723
USING btree(transmission_zone_id);

CREATE INDEX hourly_load_8760_by_transmission_zone_20130723_hour_of_year_btree ON ventyx.hourly_load_8760_by_transmission_zone_20130723
USING btree(hour_of_year);

-- add comment
COMMENT ON TABLE ventyx.hourly_load_8760_by_transmission_zone_20130723
  IS 'Hourly Load by Transmission Zone (all sectors) from Ventyx, simplified to 8760 format. 
  One hour gaps were found in three transmission zones (615529, 1836089, 615603) due to DST; 
  these gaps were filled by averaging the two neighboring hourly load values. Derived from ventyx.hourly_load_by_transmission_zone_20130723.
  Created 2014.05.30.';
 

-- set owner
ALTER TABLE ventyx.hourly_load_8760_by_transmission_zone_20130723
  OWNER TO "ventyx-writers";