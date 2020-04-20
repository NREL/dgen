ALTER TABLE dgeo.physio
RENAME TO usgs_physiographic_divisions;

ALTER TABLE dgeo.usgs_physiographic_divisions RENAME COLUMN "AREA" TO area;
ALTER TABLE dgeo.usgs_physiographic_divisions RENAME COLUMN "PERIMETER" TO perimeter;
ALTER TABLE dgeo.usgs_physiographic_divisions RENAME COLUMN "PHYSIODD_" TO physiodd_;
ALTER TABLE dgeo.usgs_physiographic_divisions RENAME COLUMN "PHYSIODD_I" TO physiodd_i;
ALTER TABLE dgeo.usgs_physiographic_divisions RENAME COLUMN "FCODE" TO fcode;
ALTER TABLE dgeo.usgs_physiographic_divisions RENAME COLUMN "FENCODE" TO fencode;
ALTER TABLE dgeo.usgs_physiographic_divisions RENAME COLUMN "DIVISION" TO division;
ALTER TABLE dgeo.usgs_physiographic_divisions RENAME COLUMN "PROVINCE" TO province;
ALTER TABLE dgeo.usgs_physiographic_divisions RENAME COLUMN "SECTION" TO section;
ALTER TABLE dgeo.usgs_physiographic_divisions RENAME COLUMN "PROVCODE" TO provcode;

-- add index on the geom
CREATE INDEX usgs_physiographic_divisions_the_geom_4269_gist
ON dgeo.usgs_physiographic_divisions
USING GIST(the_geom_4269);

-- add the_geom_96703 column
ALTER TABLE dgeo.usgs_physiographic_divisions
ADD COLUMN the_geom_96703 geometry;

UPDATE dgeo.usgs_physiographic_divisions
SET the_geom_96703 = ST_Transform(the_geom_4269, 96703);

-- add index on the geom
CREATE INDEX usgs_physiographic_divisions_the_geom_96703_gist
ON dgeo.usgs_physiographic_divisions
USING GIST(the_geom_96703);

-- create a new lookup table
DROP TABLE IF EXISTS diffusion_geo.smu_thermal_conductivity_cores_physio_divisions_lkup;
CREATE TABLE diffusion_geo.smu_thermal_conductivity_cores_physio_divisions_lkup AS
select a.gid, b.division as physio_division, b.province as physio_province, b.section as physio_section
from diffusion_geo.smu_thermal_conductivity_cores a
INNER JOIN dgeo.usgs_physiographic_divisions b
ON ST_Intersects(a.the_geom_96703, b.the_geom_96703)
WHERE a.state_abbr is not null;
-- 50277 rows

-- add the values back to the main table
ALTER TABLE diffusion_geo.smu_thermal_conductivity_cores
ADD COLUMN physio_division text,
ADD COLUMN physio_province text,
add column physio_section text;

UPDATE diffusion_geo.smu_thermal_conductivity_cores a
SET (physio_division, physio_province, physio_section) = (b.physio_division, b.physio_province, b.physio_section)
from diffusion_geo.smu_thermal_conductivity_cores_physio_divisions_lkup b
where a.gid = b.gid;
-- 50277 rows

-- drop the lookup table
DROP TABLE IF EXISTS diffusion_geo.smu_thermal_conductivity_cores_physio_divisions_lkup;

-- check the count of nulls
select count(*)
FROM diffusion_geo.smu_thermal_conductivity_cores
where physio_division is null
and state_abbr is not null;
-- 275