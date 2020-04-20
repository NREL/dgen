-- to do:
-- restore hourly data to : diffusion_1 (in progress right now)



----------------
-- hourly Tables
----------------

-- Disinherit tables
ALTER TABLE diffusion_wind.wind_resource_hourly_near_future_residential_turbine NO INHERIT diffusion_wind.wind_resource_hourly;

ALTER TABLE diffusion_wind.wind_resource_hourly_far_future_small_turbine NO INHERIT diffusion_wind.wind_resource_hourly;

ALTER TABLE diffusion_wind.wind_resource_hourly_near_future_mid_size_turbine NO INHERIT diffusion_wind.wind_resource_hourly;

ALTER TABLE diffusion_wind.wind_resource_hourly_far_future_mid_size_and_large_turbine NO INHERIT diffusion_wind.wind_resource_hourly;

-- Archive & delete tables
CREATE TABLE diffusion_wind.archive_wind_resource_hourly_near_future_residential_turbine_8_31_15
AS SELECT * FROM diffusion_wind.wind_resource_hourly_near_future_residential_turbine;
DROP TABLE diffusion_wind.wind_resource_hourly_near_future_residential_turbine;

CREATE TABLE diffusion_wind.archive_wind_resource_hourly_far_future_small_turbine_8_31_15
AS SELECT * FROM diffusion_wind.wind_resource_hourly_far_future_small_turbine;
DROP TABLE diffusion_wind.wind_resource_hourly_far_future_small_turbine;

CREATE TABLE diffusion_wind.archive_wind_resource_hourly_near_future_mid_size_turbine_8_31_15
AS SELECT * FROM diffusion_wind.wind_resource_hourly_near_future_mid_size_turbine;
DROP TABLE diffusion_wind.wind_resource_hourly_near_future_mid_size_turbine;

CREATE TABLE diffusion_wind.archive_wind_resource_hourly_far_future_mid_size_and_large_turbine_8_31_15
AS SELECT * FROM diffusion_wind.wind_resource_hourly_far_future_mid_size_and_large_turbine;
DROP TABLE diffusion_wind.wind_resource_hourly_far_future_mid_size_and_large_turbine;

-- drop table diffusion_wind.wind_resource_hourly_residential_near_future_turbine;
-- drop table diffusion_wind.wind_resource_hourly_residential_far_future_turbine;
-- drop table diffusion_wind.wind_resource_hourly_sm_mid_lg_far_future_turbine;
-- drop table diffusion_wind.wind_resource_hourly_sm_mid_lg_near_future_turbine;

-- dump the data to sql file:
-- /usr/pgsql-9.2/bin/pg_dump -h dnpdb001.bigde.nrel.gov -v -p 5433 -U mgleason_su -t diffusion_wind.wind_resource_hourly_residential_near_future_turbine -t diffusion_wind.wind_resource_hourly_residential_far_future_turbine -t diffusion_wind.wind_resource_hourly_sm_mid_lg_near_future_turbine -t diffusion_wind.wind_resource_hourly_sm_mid_lg_far_future_turbine diffusion_3 | gzip -6 > ~/pcurves_update/hourly.sql.gz

-- restore from sql file:
-- gunzip -c ~/pcurves_update/hourly.sql | /usr/pgsql-9.2/bin/psql -e -h dnpdb001.bigde.nrel.gov -p 5433 -U mgleason_su diffusion_4
-- gunzip -c ~/pcurves_update/hourly.sql | /usr/pgsql-9.2/bin/psql -e -h dnpdb001.bigde.nrel.gov -p 5433 -U mgleason_su diffusion_1



----------------
-- Annual Tables
----------------

-- Disinherit tables
ALTER TABLE diffusion_wind.wind_resource_near_future_residential_turbine NO INHERIT diffusion_wind.wind_resource_annual;

ALTER TABLE diffusion_wind.wind_resource_far_future_small_turbine NO INHERIT diffusion_wind.wind_resource_annual;

ALTER TABLE diffusion_wind.wind_resource_near_future_mid_size_turbine NO INHERIT diffusion_wind.wind_resource_annual;

ALTER TABLE diffusion_wind.wind_resource_far_future_mid_size_and_large_turbine NO INHERIT diffusion_wind.wind_resource_annual;

-- Archive & delete tables
CREATE TABLE diffusion_wind.archive_wind_resource_near_future_residential_turbine_8_31_15
AS SELECT * FROM diffusion_wind.wind_resource_near_future_residential_turbine;
DROP TABLE diffusion_wind.wind_resource_near_future_residential_turbine;

CREATE TABLE diffusion_wind.archive_wind_resource_far_future_small_turbine_8_31_15
AS SELECT * FROM diffusion_wind.wind_resource_far_future_small_turbine;
DROP TABLE diffusion_wind.wind_resource_far_future_small_turbine;

CREATE TABLE diffusion_wind.archive_wind_resource_near_future_mid_size_turbine_8_31_15
AS SELECT * FROM diffusion_wind.wind_resource_near_future_mid_size_turbine;
DROP TABLE diffusion_wind.wind_resource_near_future_mid_size_turbine;

CREATE TABLE diffusion_wind.archive_wind_resource_far_future_mid_size_and_large_turbine_8_31_15
AS SELECT * FROM diffusion_wind.wind_resource_far_future_mid_size_and_large_turbine;
DROP TABLE diffusion_wind.wind_resource_far_future_mid_size_and_large_turbine;


-- drop table diffusion_wind.wind_resource_residential_near_future_turbine;
-- drop table diffusion_wind.wind_resource_residential_far_future_turbine;
-- drop table diffusion_wind.wind_resource_sm_mid_lg_far_future_turbine;
-- drop table diffusion_wind.wind_resource_sm_mid_lg_near_future_turbine;

-- dump the data to sql file:
-- /usr/pgsql-9.2/bin/pg_dump -h dnpdb001.bigde.nrel.gov -v -p 5433 -U mgleason_su -t diffusion_wind.wind_resource_residential_near_future_turbine -t diffusion_wind.wind_resource_residential_far_future_turbine -t diffusion_wind.wind_resource_sm_mid_lg_far_future_turbine -t diffusion_wind.wind_resource_sm_mid_lg_near_future_turbine diffusion_3 > ~/pcurves_update/annual.sql

-- restore from sql file:
--/usr/pgsql-9.2/bin/psql -h dnpdb001.bigde.nrel.gov -p 5433 -U mgleason_su -f ~/pcurves_update/annual.sql diffusion_4
--/usr/pgsql-9.2/bin/psql -h dnpdb001.bigde.nrel.gov -p 5433 -U mgleason_su -f ~/pcurves_update/annual.sql diffusion_1

-- scp to gispgdb:
-- gzip file
-- scp -r mgleason@dnpdb001.bigde.nrel.gov:/home/mgleason/pcurves_update .
-- run restore commands on gispgdb:
-- 	psql -U mgleason dav-gis -f annual.sql
-- 	gunzip -c ./hourly.sql.gz | psql -e -U mgleason dav-gis


