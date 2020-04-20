set role 'diffusion-writers';


-- add geom 102003 for intersecting with climate zones
ALTER TABLE  diffusion_geo.smu_thermal_conductivity_cores
ADD COLUMN the_geom_102003 geometry;

UPDATE diffusion_geo.smu_thermal_conductivity_cores
SET the_geom_102003 = ST_Transform(the_geom_4326, 102003);
-- 52254 rows

-- add index
CREATE INDEX smu_thermal_conductivity_cores_the_geom_102003_gist
ON diffusion_geo.smu_thermal_conductivity_cores
USING GIST(the_geom_102003);

--
DROP TABLE IF EXISTS diffusion_geo.smu_thermal_conductivity_cores_climate_zones_lkup;
CREATE TABLE diffusion_geo.smu_thermal_conductivity_cores_climate_zones_lkup AS
select a.gid, b.climate_zone as temperature_zone, b.moisture_regime, climate_zone::text || moisture_regime as climate_zone
from diffusion_geo.smu_thermal_conductivity_cores a
INNER JOIN ashrae.county_to_iecc_building_climate_zones_lkup b
ON ST_Intersects(a.the_geom_102003, b.the_geom_102003)
WHERE b.state_abbr is not null;
-- 50391 rows

-- add the values back to the main table
ALTER TABLE diffusion_geo.smu_thermal_conductivity_cores
ADD COLUMN temperature_zone integer,
ADD COLUMN moisture_regime varchar(1),
add column climate_zone varchar(2);

UPDATE diffusion_geo.smu_thermal_conductivity_cores a
SET (temperature_zone, moisture_regime, climate_zone) = (b.temperature_zone, b.moisture_regime, b.climate_zone)
from diffusion_geo.smu_thermal_conductivity_cores_climate_zones_lkup b
where a.gid = b.gid;
-- 50391 rows

-- drop the lookup table
DROP TABLE IF EXISTS diffusion_geo.smu_thermal_conductivity_cores_climate_zones_lkup;

-- check the count of nulls
select count(*)
FROM diffusion_geo.smu_thermal_conductivity_cores
where climate_zone is null
and state_abbr is not null;
-- 233

-- view the data



