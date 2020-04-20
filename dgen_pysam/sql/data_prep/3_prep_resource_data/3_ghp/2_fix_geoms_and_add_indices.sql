-- add a primary key
ALTER TABLE diffusion_geo.smu_thermal_conductivity_cores
ADD COLUMN gid serial primary key;

-- also add unique constraint on observationuri
ALTER TABLE diffusion_geo.smu_thermal_conductivity_cores
ADD constraint observationuri unique (observationuri);

------------------------------------------------------------------
-- Geometry and location info (state) cleanup

-- check for distinct srs
select distinct srs 
from diffusion_geo.smu_thermal_conductivity_cores;
-- wgs84

-- fix geom column type
ALTER TABLE diffusion_geo.smu_thermal_conductivity_cores
ALTER column shape TYPE geometry using shape::geometry;

-- check srid
select distinct ST_SRID(shape)
FROM diffusion_geo.smu_thermal_conductivity_cores;
-- 4326 and null

-- check type
select distinct geometrytype(shape)
FROM diffusion_geo.smu_thermal_conductivity_cores;
-- point and null

-- check whether there are any null lat and long fields
select count(*)
FROM diffusion_geo.smu_thermal_conductivity_cores
where latdegreewgs84 is null;
-- 38

select count(*)
FROM diffusion_geo.smu_thermal_conductivity_cores
where longdegreewgs84 is null;
-- 38

-- does this match the nulls for the srid and geom?
select count(*)
FROM diffusion_geo.smu_thermal_conductivity_cores
where ST_SRID(shape) is null
or geometrytype(shape) is null;
-- 38 -- yes

-- do we have state info for those rows?
select distinct state 
from diffusion_geo.smu_thermal_conductivity_cores
where geometrytype(shape) is null;
-- null -- nope...

-- look at the rows
select *
from diffusion_geo.smu_thermal_conductivity_cores
where geometrytype(shape) is null;
-- state info looks like it can be pulled from the sitelocationame

-- review the geometry data in Q -- does it look reasonable?
-- yep, looks fine

-- check that geoms match lat / lng
SELECT ST_X(shape), longdegreewgs84
from diffusion_geo.smu_thermal_conductivity_cores
where shape is not null
AND ST_X(shape) <> longdegreewgs84;
-- 0 rows -- all set!

select ST_Y(shape), latdegreewgs84
from diffusion_geo.smu_thermal_conductivity_cores
where shape is not null
AND ST_Y(shape) <> latdegreewgs84; 
-- 0 rows -- all set!

-- change the shape column name
ALTER TABLE diffusion_geo.smu_thermal_conductivity_cores
RENAME COLUMN shape TO the_geom_4326;

-- add index
CREATE INDEX smu_thermal_conductivity_cores_the_geom_4326_gist
ON diffusion_geo.smu_thermal_conductivity_cores
USING GIST(the_geom_4326);


------------------------------------------------------------------------------
-- update the state_abbr column for all points
ALTER TABLE diffusion_geo.smu_thermal_conductivity_cores
ADD COLUMN state_abbr varchar(2);

-- for the points with no geoms, use the sitelocationname to get the state_abbr
UPDATE diffusion_geo.smu_thermal_conductivity_cores
SET state_abbr = substring(sitelocationname, 1, 2)
where geometrytype(the_geom_4326) is null;
-- 38 rows

-- check results
select distinct state_abbr
from diffusion_geo.smu_thermal_conductivity_cores;
-- all values are actual state_abbbrs, so this is fine

-- now update the rest using the state field
UPDATE diffusion_geo.smu_thermal_conductivity_cores a
set state_abbr = b.state_abbr
from diffusion_shared.state_abbr_lkup b
where a.state = b.state
and a.state_abbr is null;
-- 50417 rows

-- check new values
select distinct state_abbr
from diffusion_geo.smu_thermal_conductivity_cores;
-- still some nulls, why?

select *
from diffusion_geo.smu_thermal_conductivity_cores
where state_abbr is null;
-- 1799 rows
-- these all do have lats and longs, but weren't tagged with state info

--  so fix with an intersect
UPDATE diffusion_geo.smu_thermal_conductivity_cores a
SET state_abbr = b.state_abbr
FROM diffusion_shared.county_geom b
WHERE a.state_abbr is null
AND ST_Intersects(a.the_geom_4326, b.the_geom_4326);
-- fixed 36

-- what's going on with the rest?
-- in Q, they are mostly offshore, or just barely offshore/along US boundary

ALTER TABLE  diffusion_geo.smu_thermal_conductivity_cores
ADD COLUMN the_geom_96703 geometry;

UPDATE diffusion_geo.smu_thermal_conductivity_cores
SET the_geom_96703 = ST_Transform(the_geom_4326, 96703);
-- 52254 rows

-- add index
CREATE INDEX smu_thermal_conductivity_cores_the_geom_96703_gist
ON diffusion_geo.smu_thermal_conductivity_cores
USING GIST(the_geom_96703);

-- fix the close ones using a buffer -- for the rest, forget it
UPDATE diffusion_geo.smu_thermal_conductivity_cores a
SET state_abbr = b.state_abbr
FROM diffusion_shared.county_geom b
WHERE a.state_abbr is null
AND ST_DWIthin(a.the_geom_96703, b.the_geom_96703, 1000);
-- fixed 60

-- check for remaining nulls in state column
select count(*)
from diffusion_geo.smu_thermal_conductivity_cores
where state_abbr is null;
-- 1703 nulls remain

-- update state field to sync with state_abbr field
UPDATE diffusion_geo.smu_thermal_conductivity_cores a
set state = b.state
from diffusion_shared.state_abbr_lkup b
where a.state_abbr = b.state_abbr
and a.state is null;

-- check combos
select distinct state, state_abbr
from diffusion_geo.smu_thermal_conductivity_cores
order by 1;
-- 50 results, looks reasonable

-- check results in Q
-- also looks reasonable

-- which states are missing?
with a as
(
	select distinct state_abbr
	from diffusion_geo.smu_thermal_conductivity_cores
)
select *
from diffusion_shared.state_abbr_lkup b
left join a
on a.state_abbr = b.state_abbr
where a.state_abbr is null;
-- CT and PR are hte only ones missing
---------------------------------------------------------------------------------

-- check distinct units for thermal conductivity
select distinct unitstc
from diffusion_geo.smu_thermal_conductivity_cores;
-- all units are: Watt per meter per Kelvin
-- perfect

-- add a column for the thermal conductivity in BTU/hr-ft-F
ALTER TABLE diffusion_geo.smu_thermal_conductivity_cores
ADD COLUMN tc_btuhftf numeric;

UPDATE diffusion_geo.smu_thermal_conductivity_cores
set tc_btuhftf = sitethermalconductivity/1.7307;
-- 52254 rows

---------------------------------------------------------------------------------
