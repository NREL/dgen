-- create parent table
DROP TABLE IF EXISTS diffusion_solar.solar_resource_hourly_new;
CREATE TABLE diffusion_solar.solar_resource_hourly_new
(
  solar_re_9809_gid integer,
  tilt integer,
  azimuth character varying(2),
  cf integer[] -- scale_offset = 1e6
);

COMMENT ON COLUMN diffusion_solar.solar_resource_hourly_new.cf 
IS 'scale_offset = 1e6';



-- alter type of the tilt column
-- inherit individual turbine tables to the parent table
-- add check constraint on azimuth
-- add primary keys (use combo of solar_re_9809_gid, tilt) 
-- add indices on solar_re_9809_gid and tilt

-- EAST
ALTER TABLE diffusion_solar.solar_resource_hourly_e
ALTER COLUMN tilt TYPE integer using tilt::integer;

ALTER TABLE diffusion_solar.solar_resource_hourly_e
INHERIT diffusion_solar.solar_resource_hourly_new;

ALTER TABLE diffusion_solar.solar_resource_hourly_e
ADD CONSTRAINT solar_resource_hourly_e_azimuth_check CHECK (azimuth = 'E');

ALTER TABLE diffusion_solar.solar_resource_hourly_e
ADD PRIMARY KEY (solar_re_9809_gid, tilt);

CREATE INDEX solar_resource_hourly_e_solar_re_9809_gid_btree
ON diffusion_solar.solar_resource_hourly_e
USING btree(solar_re_9809_gid);

CREATE INDEX solar_resource_hourly_e_tilt_btree
ON diffusion_solar.solar_resource_hourly_e
USING btree(tilt);

-- WEST
ALTER TABLE diffusion_solar.solar_resource_hourly_w
ALTER COLUMN tilt TYPE integer using tilt::integer;

ALTER TABLE diffusion_solar.solar_resource_hourly_w
INHERIT diffusion_solar.solar_resource_hourly_new;

ALTER TABLE diffusion_solar.solar_resource_hourly_w
ADD CONSTRAINT solar_resource_hourly_w_azimuth_check CHECK (azimuth = 'W');

ALTER TABLE diffusion_solar.solar_resource_hourly_w
ADD PRIMARY KEY (solar_re_9809_gid, tilt);

CREATE INDEX solar_resource_hourly_w_solar_re_9809_gid_btree
ON diffusion_solar.solar_resource_hourly_w
USING btree(solar_re_9809_gid);

CREATE INDEX solar_resource_hourly_w_tilt_btree
ON diffusion_solar.solar_resource_hourly_w
USING btree(tilt);

-- SOUTH
ALTER TABLE diffusion_solar.solar_resource_hourly_s
ALTER COLUMN tilt TYPE integer using tilt::integer;

ALTER TABLE diffusion_solar.solar_resource_hourly_s
INHERIT diffusion_solar.solar_resource_hourly_new;

ALTER TABLE diffusion_solar.solar_resource_hourly_s
ADD CONSTRAINT solar_resource_hourly_s_azimuth_check CHECK (azimuth = 'S');

ALTER TABLE diffusion_solar.solar_resource_hourly_s
ADD PRIMARY KEY (solar_re_9809_gid, tilt);

CREATE INDEX solar_resource_hourly_s_solar_re_9809_gid_btree
ON diffusion_solar.solar_resource_hourly_s
USING btree(solar_re_9809_gid);

CREATE INDEX solar_resource_hourly_s_tilt_btree
ON diffusion_solar.solar_resource_hourly_s
USING btree(tilt);

-- SOUTHEAST
ALTER TABLE diffusion_solar.solar_resource_hourly_se
ALTER COLUMN tilt TYPE integer using tilt::integer;

ALTER TABLE diffusion_solar.solar_resource_hourly_se
INHERIT diffusion_solar.solar_resource_hourly_new;

ALTER TABLE diffusion_solar.solar_resource_hourly_se
ADD CONSTRAINT solar_resource_hourly_se_azimuth_check CHECK (azimuth = 'SE');

ALTER TABLE diffusion_solar.solar_resource_hourly_se
ADD PRIMARY KEY (solar_re_9809_gid, tilt);

CREATE INDEX solar_resource_hourly_se_solar_re_9809_gid_btree
ON diffusion_solar.solar_resource_hourly_se
USING btree(solar_re_9809_gid);

CREATE INDEX solar_resource_hourly_se_tilt_btree
ON diffusion_solar.solar_resource_hourly_se
USING btree(tilt);

-- SOUTHWEST
ALTER TABLE diffusion_solar.solar_resource_hourly_sw
ALTER COLUMN tilt TYPE integer using tilt::integer;

ALTER TABLE diffusion_solar.solar_resource_hourly_sw
INHERIT diffusion_solar.solar_resource_hourly_new;

ALTER TABLE diffusion_solar.solar_resource_hourly_sw
ADD CONSTRAINT solar_resource_hourly_sw_azimuth_check CHECK (azimuth = 'SW');

ALTER TABLE diffusion_solar.solar_resource_hourly_sw
ADD PRIMARY KEY (solar_re_9809_gid, tilt);

CREATE INDEX solar_resource_hourly_sw_solar_re_9809_gid_btree
ON diffusion_solar.solar_resource_hourly_sw
USING btree(solar_re_9809_gid);

CREATE INDEX solar_resource_hourly_sw_tilt_btree
ON diffusion_solar.solar_resource_hourly_sw
USING btree(tilt);


-- check that it worked
select  count(*)
FROM diffusion_solar.solar_resource_hourly_new;
-- 2834547

select count(*)
FROM diffusion_solar.solar_resource_hourly_e;
-- 548622

select count(*)
FROM diffusion_solar.solar_resource_hourly_w;
-- 548622

select count(*)
FROM diffusion_solar.solar_resource_hourly_se;
-- 548622

select count(*)
FROM diffusion_solar.solar_resource_hourly_sw;
-- 548622

select count(*)
FROM diffusion_solar.solar_resource_hourly_s;
-- 640059

select 640059 + 548622*4; 
-- 2834547
--- count matches


-------------------------------------------------------------------
-- review the parent table for issues

-- check for nulls
select *
from diffusion_solar.solar_resource_hourly_new
where cf is null;
-- 0 returned

-- check gid 3101 (which has a bad tm2 file)
select count(*)
FROM diffusion_solar.solar_resource_hourly_new
where solar_re_9809_gid = 3101;
-- not included in the outputs

-- to fix, simply replce with the corresponding values from one of its neighbors
-- in this case, the cell to the south (3451) appears to be the best optoin

insert into diffusion_solar.solar_resource_hourly_e
select 3101 as solar_re_9808_gid, tilt, azimuth, cf
FROM diffusion_solar.solar_resource_hourly_e
where solar_re_9809_gid = 3451;

insert into diffusion_solar.solar_resource_hourly_w
select 3101 as solar_re_9808_gid, tilt, azimuth, cf
FROM diffusion_solar.solar_resource_hourly_w
where solar_re_9809_gid = 3451;

insert into diffusion_solar.solar_resource_hourly_s
select 3101 as solar_re_9808_gid, tilt, azimuth, cf
FROM diffusion_solar.solar_resource_hourly_s
where solar_re_9809_gid = 3451;

insert into diffusion_solar.solar_resource_hourly_se
select 3101 as solar_re_9808_gid, tilt, azimuth, cf
FROM diffusion_solar.solar_resource_hourly_se
where solar_re_9809_gid = 3451;

insert into diffusion_solar.solar_resource_hourly_sw
select 3101 as solar_re_9808_gid, tilt, azimuth, cf
FROM diffusion_solar.solar_resource_hourly_sw
where solar_re_9809_gid = 3451;

-- check that results were produced correctly
select *
from diffusion_solar.solar_resource_hourly_new
where solar_re_9809_gid in (3101,3451)
order by tilt, azimuth;

-- check count of 3101 vs 3451
select solar_re_9809_gid, count(*)
from diffusion_solar.solar_resource_hourly_new
where solar_re_9809_gid in (3101,3451)
group by solar_re_9809_gid;
-- counts match




-- check stats seem legit (also map these, if possible)
with a as 
(
	Select r_array_sum(cf) as aep
	from diffusion_solar.solar_resource_hourly_new
)
select min(aep), max(aep), avg(aep)
from a;
-- 813886828;0
-- 2030125245;
-- 1368792282.79741323

select min(naep), max(naep), avg(naep)
from diffusion_solar.solar_resource_hourly_new;
-- 813.886809653457; --min
-- 2030.1252534034581; --max
-- 1368.7922945785332869 --avg



	

vacuum analyze diffusion_solar.solar_resource_hourly_new;
vacuum analyze diffusion_solar.solar_resource_hourly_e;
vacuum analyze diffusion_solar.solar_resource_hourly_w;
vacuum analyze diffusion_solar.solar_resource_hourly_s;
vacuum analyze diffusion_solar.solar_resource_hourly_se;
vacuum analyze diffusion_solar.solar_resource_hourly_sw;