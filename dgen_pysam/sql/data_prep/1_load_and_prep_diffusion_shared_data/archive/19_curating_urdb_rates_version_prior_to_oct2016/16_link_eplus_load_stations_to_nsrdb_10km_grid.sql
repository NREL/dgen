-- ingest the metadata that identify the TMY stations associated with the energy plus load simulations
-- using /Volumes/Staff/mgleason/DG_Wind/Python/load_eplus_meta_to_pg.py to 
-- table is loaded in as diffusion_shared_data.energy_plus_load_meta
-- do some minor cleanup on this table to flag missing data more clearly
set role 'diffusion-writers';
ALTER TABLE diffusion_shared_data.energy_plus_load_meta
ADD COLUMN missing_res boolean default false,
ADD COLUMN missing_com boolean default false;

UPDATE diffusion_shared_data.energy_plus_load_meta
SET missing_res = True
where missing_data = 'res';

UPDATE diffusion_shared_data.energy_plus_load_meta
SET missing_com = True
where missing_data = 'com';

-- create an index on the usaf column
CREATE INDEX energy_plus_load_meta_usaf_btree
ON diffusion_shared_data.energy_plus_load_meta
using btree(usaf);

-- test that these stations can 
-- link to nsrdb 10 km grid cells (solar.solar_re_9809) using usaf field
-- do this separately for res and com because each has missing data
DROP TABLE if exists diffusion_shared.temp;
CREATE TABLE diffusion_shared.temp as
SELECT a.*, b.gid as nsrdb_gid, b.the_geom_4326
FROM diffusion_shared_data.energy_plus_load_meta a
LEFT JOIN solar.solar_re_9809 b
ON a.usaf = b.usaf 
where a.missing_res = false;
-- inspect in Q

DROP TABLE if exists diffusion_shared.temp;
CREATE TABLE diffusion_shared.temp as
SELECT a.*, b.gid as nsrdb_gid, b.the_geom_4326
FROM diffusion_shared_data.energy_plus_load_meta a
LEFT JOIN solar.solar_re_9809 b
ON a.usaf = b.usaf 
where a.missing_com = false;
-- inspect in Q
DROP TABLE if exists diffusion_shared.temp;
-- these both look fine -- there are small gaps for the missing stations,
-- but we should be able to fill them using nearest neighbors


-- create lookup tables from solar_re_9809_gid to load hdf_index
--residential
DROP TABLE if exists diffusion_shared_data.solar_re_9809_to_eplus_load_res;
CREATE TABLE diffusion_shared_data.solar_re_9809_to_eplus_load_res as
SELECT a.hdf_index, b.gid as solar_re_9809_gid
FROM diffusion_shared_data.energy_plus_load_meta a
LEFT JOIN solar.solar_re_9809 b
ON a.usaf = b.usaf 
where a.missing_res = false;

-- create index
CREATE INDEX solar_re_9809_to_eplus_load_res_solar_re_9809_gid_btree
ON diffusion_shared_data.solar_re_9809_to_eplus_load_res
using btree(solar_re_9809_gid);

-- commercial
DROP TABLE if exists diffusion_shared_data.solar_re_9809_to_eplus_load_com;
CREATE TABLE diffusion_shared_data.solar_re_9809_to_eplus_load_com as
SELECT a.hdf_index, b.gid as solar_re_9809_gid
FROM diffusion_shared_data.energy_plus_load_meta a
LEFT JOIN solar.solar_re_9809 b
ON a.usaf = b.usaf 
where a.missing_com = false;

-- create index
CREATE INDEX solar_re_9809_to_eplus_load_com_solar_re_9809_gid_btree
ON diffusion_shared_data.solar_re_9809_to_eplus_load_com
using btree(solar_re_9809_gid);