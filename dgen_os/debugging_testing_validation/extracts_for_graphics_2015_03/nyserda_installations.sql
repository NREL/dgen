set role 'dg_wind-writers';
DROP TABLE IF EXISTS dg_wind.nyserda_dwind_installations;
CREATE TABLE dg_wind.nyserda_dwind_installations
(
	application_no text not null unique,
	customer text,
	street_address text,
	city text,
	county text,
	zipcode character varying(5),
	township text,
	utility_name text,
	sector text,
	turbine_model text,
	tower_ht_ft integer,
	tower_type text,
	avg_windspeed_ms numeric,
	inverter_model text,
	kw numeric,
	customer_load_kwh numeric,
	turbine_generation_kwh numeric,
	total_cost_dlrs numeric,
	incentive_dlrs numeric,
	date_installed date
);

set role 'server-superusers';
COPY dg_wind.nyserda_dwind_installations
FROM '/srv/home/mgleason/data/dg_wind/nyserda/nyserda_dwind_projects_2012.csv'
with csv header;

COPY dg_wind.nyserda_dwind_installations
FROM '/srv/home/mgleason/data/dg_wind/nyserda/nyserda_dwind_projects_2013.csv'
with csv header;

COPY dg_wind.nyserda_dwind_installations
FROM '/srv/home/mgleason/data/dg_wind/nyserda/nyserda_dwind_projects_2014.csv'
with csv header;
set role 'dg_wind-writers';

-- add uid as primary key
ALTER tABLE dg_wind.nyserda_dwind_installations
ADD uid serial primary key;

-- check system sizing targets and incentive levels
select sector, avg(turbine_generation_kwh/customer_load_kwh), count(*)
FROM dg_wind.nyserda_dwind_installations
group by sector

select sector, avg(incentive_dlrs/total_cost_dlrs), count(*)
FROM dg_wind.nyserda_dwind_installations
group by sector;

-- geocode
DROP TABLE IF EXIStS dg_wind.nyserda_dwind_installations_geocoded;
CREATE TABLE dg_wind.nyserda_dwind_installations_geocoded AS
with a as
(
	SELECT uid, street_address || ', ' || city || ', NY ' || zipcode as full_address
	FROM dg_wind.nyserda_dwind_installations
),
b as
(
	SELECT uid, full_address, ST_Geocode(full_address, 'de8995c98838ef31716cf4abb9ff520af6059850', true) as gc
	FROM a
)
SELECT uid, full_address, (gc).*
FROM b;

-- review the results
select * 
from dg_wind.nyserda_dwind_installations--_geocoded
where uid = 49
-- these look like potential errors -- review in google maps:
-- 31;7591 Route 23 East Windham, NY 12349;7591 New York 23, Acra, NY 12405, USA;42.336234;-74.152985;ROOFTOP;address;8				--> this looks approximately ok
-- 33;16481 West Lake Road Sterling, NY 13156;16481 Lake Street, Sterling, NY 13156, USA;43.3270206;-76.7033133;RANGE_INTERPOLATED;address;8	--> also looks approximately ok
-- 42;7495 Maple Street Road Bascom, NY 14031;Clarence, NY 14031, USA;42.9813122;-78.6001482;APPROXIMATE;postal_code;5				--> city name is "Basom" not bascom -- regeocode
-- 49;2376 County Route 4 Oswego, NY 13126;2376 County Route 1, Oswego, NY 13126, USA;43.4736765;-76.4728185;RANGE_INTERPOLATED;address;8		--> i think this one should be geocoded to dunsmoor farms, new york 104, oswego ny
-- 62;347 Dugan Hill Road Gallupville, NY 12073;347 Dugan Hill Road, Schoharie, NY 12157, USA;42.685758;-74.244486;ROOFTOP;address;8		--> this looks ok

-- fix #42 and 49
DELETE FROM dg_wind.nyserda_dwind_installations_geocoded
where uid in (42, 49);

-- 42
with a as
(
	SELECT uid, '7495 Maple Road Basom, NY 14013'::text as full_address
	FROM dg_wind.nyserda_dwind_installations
	where uid = 42
),
b as
(
	SELECT uid, full_address, ST_Geocode(full_address, 'de8995c98838ef31716cf4abb9ff520af6059850', true) as gc
	FROM a
)
insert into dg_wind.nyserda_dwind_installations_geocoded
SELECT uid, full_address, (gc).*
FROM b;

select *
FROM dg_wind.nyserda_dwind_installations_geocoded
where uid = 42;

-- 49
with a as
(
	SELECT uid, '7965 New York 104, Oswego, NY 13126'::text as full_address
	FROM dg_wind.nyserda_dwind_installations
	where uid = 49
),
b as
(
	SELECT uid, full_address, ST_Geocode(full_address, 'de8995c98838ef31716cf4abb9ff520af6059850', true) as gc
	FROM a
)
insert into dg_wind.nyserda_dwind_installations_geocoded
SELECT uid, full_address, (gc).*
FROM b;

select *
FROM dg_wind.nyserda_dwind_installations_geocoded
where uid = 49;

-- add the geometries back to the main table
ALTER TABLE dg_wind.nyserda_dwind_installations
ADD column the_geom_4326 geometry;

UPDATE dg_wind.nyserda_dwind_installations a
set the_geom_4326 = ST_SetSRID(ST_Point(b.lng, b.lat), 4326)
FROM dg_wind.nyserda_dwind_installations_geocoded b
WHERE a.uid = b.uid;

