-- create parent table
DROP TABLE IF EXISTS diffusion_solar.solar_resource_annual_new;
CREATE TABLE diffusion_solar.solar_resource_annual_new
(
	solar_re_9809_gid integer,
	tilt integer,
	azimuth character varying(2),
	naep numeric,
	cf_avg numeric
);




-- alter type of the tilt column
-- inherit individual turbine tables to the parent table
-- add check constraint on azimuth
-- add primary keys (use combo of solar_re_9809_gid, tilt) 
-- add indices on solar_re_9809_gid and tilt

-- EAST
ALTER TABLE diffusion_solar.solar_resource_annual_e
ALTER COLUMN tilt TYPE integer using tilt::integer;

ALTER TABLE diffusion_solar.solar_resource_annual_e
INHERIT diffusion_solar.solar_resource_annual_new;

ALTER TABLE diffusion_solar.solar_resource_annual_e
ADD CONSTRAINT solar_resource_annual_e_azimuth_check CHECK (azimuth = 'E');

ALTER TABLE diffusion_solar.solar_resource_annual_e
ADD PRIMARY KEY (solar_re_9809_gid, tilt);

CREATE INDEX solar_resource_annual_e_solar_re_9809_gid_btree
ON diffusion_solar.solar_resource_annual_e
USING btree(solar_re_9809_gid);

CREATE INDEX solar_resource_annual_e_tilt_btree
ON diffusion_solar.solar_resource_annual_e
USING btree(tilt);

-- WEST
ALTER TABLE diffusion_solar.solar_resource_annual_w
ALTER COLUMN tilt TYPE integer using tilt::integer;

ALTER TABLE diffusion_solar.solar_resource_annual_w
INHERIT diffusion_solar.solar_resource_annual_new;

ALTER TABLE diffusion_solar.solar_resource_annual_w
ADD CONSTRAINT solar_resource_annual_w_azimuth_check CHECK (azimuth = 'W');

ALTER TABLE diffusion_solar.solar_resource_annual_w
ADD PRIMARY KEY (solar_re_9809_gid, tilt);

CREATE INDEX solar_resource_annual_w_solar_re_9809_gid_btree
ON diffusion_solar.solar_resource_annual_w
USING btree(solar_re_9809_gid);

CREATE INDEX solar_resource_annual_w_tilt_btree
ON diffusion_solar.solar_resource_annual_w
USING btree(tilt);

-- SOUTH
ALTER TABLE diffusion_solar.solar_resource_annual_s
ALTER COLUMN tilt TYPE integer using tilt::integer;

ALTER TABLE diffusion_solar.solar_resource_annual_s
INHERIT diffusion_solar.solar_resource_annual_new;

ALTER TABLE diffusion_solar.solar_resource_annual_s
ADD CONSTRAINT solar_resource_annual_s_azimuth_check CHECK (azimuth = 'S');

ALTER TABLE diffusion_solar.solar_resource_annual_s
ADD PRIMARY KEY (solar_re_9809_gid, tilt);

CREATE INDEX solar_resource_annual_s_solar_re_9809_gid_btree
ON diffusion_solar.solar_resource_annual_s
USING btree(solar_re_9809_gid);

CREATE INDEX solar_resource_annual_s_tilt_btree
ON diffusion_solar.solar_resource_annual_s
USING btree(tilt);

-- SOUTHEAST
ALTER TABLE diffusion_solar.solar_resource_annual_se
ALTER COLUMN tilt TYPE integer using tilt::integer;

ALTER TABLE diffusion_solar.solar_resource_annual_se
INHERIT diffusion_solar.solar_resource_annual_new;

ALTER TABLE diffusion_solar.solar_resource_annual_se
ADD CONSTRAINT solar_resource_annual_se_azimuth_check CHECK (azimuth = 'SE');

ALTER TABLE diffusion_solar.solar_resource_annual_se
ADD PRIMARY KEY (solar_re_9809_gid, tilt);

CREATE INDEX solar_resource_annual_se_solar_re_9809_gid_btree
ON diffusion_solar.solar_resource_annual_se
USING btree(solar_re_9809_gid);

CREATE INDEX solar_resource_annual_se_tilt_btree
ON diffusion_solar.solar_resource_annual_se
USING btree(tilt);

-- SOUTHWEST
ALTER TABLE diffusion_solar.solar_resource_annual_sw
ALTER COLUMN tilt TYPE integer using tilt::integer;

ALTER TABLE diffusion_solar.solar_resource_annual_sw
INHERIT diffusion_solar.solar_resource_annual_new;

ALTER TABLE diffusion_solar.solar_resource_annual_sw
ADD CONSTRAINT solar_resource_annual_sw_azimuth_check CHECK (azimuth = 'SW');

ALTER TABLE diffusion_solar.solar_resource_annual_sw
ADD PRIMARY KEY (solar_re_9809_gid, tilt);

CREATE INDEX solar_resource_annual_sw_solar_re_9809_gid_btree
ON diffusion_solar.solar_resource_annual_sw
USING btree(solar_re_9809_gid);

CREATE INDEX solar_resource_annual_sw_tilt_btree
ON diffusion_solar.solar_resource_annual_sw
USING btree(tilt);


-- check that it worked
select  count(*)
FROM diffusion_solar.solar_resource_annual_new;
-- 2834547

select count(*)
FROM diffusion_solar.solar_resource_annual_e;
-- 548622

select count(*)
FROM diffusion_solar.solar_resource_annual_w;
-- 548622

select count(*)
FROM diffusion_solar.solar_resource_annual_se;
-- 548622

select count(*)
FROM diffusion_solar.solar_resource_annual_sw;
-- 548622

select count(*)
FROM diffusion_solar.solar_resource_annual_s;
-- 640059

select 640059 + 548622*4; 
-- 2834547
--- count matches


-------------------------------------------------------------------
-- review the parent table for issues

-- check for nulls
select *
from diffusion_solar.solar_resource_annual_new
where naep is null
or cf_avg is null;
-- 0 returned

-- check stats seem legit (also map these, if possible)
select min(cf_avg), avg(cf_avg), max(cf_avg)
from diffusion_solar.solar_resource_annual_new;
-- 0.09290945315678734;0.15625503130210912850;0.2317494581510797

-- check gid 3101 (which has a bad tm2 file)
select count(*)
FROM diffusion_solar.solar_resource_annual_new
where solar_re_9809_gid = 3101;
-- not included in the outputs

-- to fix, simply replce with the corresponding values from one of its neighbors
-- in this case, the cell to the south (3451) appears to be the best optoin

insert into diffusion_solar.solar_resource_annual_e
select 3101 as solar_re_9808_gid, tilt, azimuth, naep, cf_avg
FROM diffusion_solar.solar_resource_annual_e
where solar_re_9809_gid = 3451;

insert into diffusion_solar.solar_resource_annual_w
select 3101 as solar_re_9808_gid, tilt, azimuth, naep, cf_avg
FROM diffusion_solar.solar_resource_annual_w
where solar_re_9809_gid = 3451;

insert into diffusion_solar.solar_resource_annual_s
select 3101 as solar_re_9808_gid, tilt, azimuth, naep, cf_avg
FROM diffusion_solar.solar_resource_annual_s
where solar_re_9809_gid = 3451;

insert into diffusion_solar.solar_resource_annual_se
select 3101 as solar_re_9808_gid, tilt, azimuth, naep, cf_avg
FROM diffusion_solar.solar_resource_annual_se
where solar_re_9809_gid = 3451;

insert into diffusion_solar.solar_resource_annual_sw
select 3101 as solar_re_9808_gid, tilt, azimuth, naep, cf_avg
FROM diffusion_solar.solar_resource_annual_sw
where solar_re_9809_gid = 3451;

-- check that results were produced correctly
select *
from diffusion_solar.solar_resource_annual_new
where solar_re_9809_gid in (3101,3451)
order by tilt, azimuth;

-- check count of 3101 vs 3451
select solar_re_9809_gid, count(*)
from diffusion_solar.solar_resource_annual_new
where solar_re_9809_gid in (3101,3451)
group by solar_re_9809_gid;
-- counts match




vacuum analyze diffusion_solar.solar_resource_annual_new;
vacuum analyze diffusion_solar.solar_resource_annual_e;
vacuum analyze diffusion_solar.solar_resource_annual_w;
vacuum analyze diffusion_solar.solar_resource_annual_s;
vacuum analyze diffusion_solar.solar_resource_annual_se;
vacuum analyze diffusion_solar.solar_resource_annual_sw;

