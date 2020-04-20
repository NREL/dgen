---------------------------------------------------------------------------------------------------
-- for normalized max demand commercial tables, change "super_market" to "supermarket"
UPDATE diffusion_load_profiles.energy_plus_max_normalized_demand_space_cooling_com
set crb_model = 'supermarket'
where  crb_model = 'super_market';
-- 935

UPDATE diffusion_load_profiles.energy_plus_max_normalized_demand_space_heating_com
set crb_model = 'supermarket'
where  crb_model = 'super_market';
-- 935

UPDATE diffusion_load_profiles.energy_plus_max_normalized_demand_water_heating_com
set crb_model = 'supermarket'
where  crb_model = 'super_market';
-- 935

UPDATE diffusion_load_profiles.energy_plus_max_normalized_demand_water_and_space_heating_com
set crb_model = 'supermarket'
where  crb_model = 'super_market';
-- 935

---------------------------------------------------------------------------------------------------
-- check that # of stations and building types is correct
-- there are 936 stations with 3 missing for com and 5 missing for res
-- there are 3 reference building for res -- expect 3*(936-5) = 2793 rows
-- there are 16 reference buildings for com -- expect 16*(936-3) = 14928 rows

-- RES -- expect 2793 for all
select count(*)
FROM diffusion_load_profiles.energy_plus_max_normalized_demand_space_cooling_res
UNION
select count(*)
FROM diffusion_load_profiles.energy_plus_max_normalized_demand_space_heating_res
UNION
select count(*)
FROM diffusion_load_profiles.energy_plus_max_normalized_demand_water_heating_res
UNION
select count(*)
FROM diffusion_load_profiles.energy_plus_max_normalized_demand_water_and_space_heating_res
UNION
select count(*)
FROM diffusion_load_profiles.energy_plus_normalized_space_cooling_res
UNION
select count(*)
FROM diffusion_load_profiles.energy_plus_normalized_space_heating_res
UNION
select count(*)
FROM diffusion_load_profiles.energy_plus_normalized_water_heating_res
UNION
select count(*)
FROM diffusion_load_profiles.energy_plus_normalized_water_and_space_heating_res;
-- 2793 -- all set!

-- COM -- expect 14928 for all
select count(*)
FROM diffusion_load_profiles.energy_plus_max_normalized_demand_space_cooling_com
UNION
select count(*)
FROM diffusion_load_profiles.energy_plus_max_normalized_demand_space_heating_com
UNION
select count(*)
FROM diffusion_load_profiles.energy_plus_max_normalized_demand_water_heating_com
UNION
select count(*)
FROM diffusion_load_profiles.energy_plus_max_normalized_demand_water_and_space_heating_com
UNION
select count(*)
FROM diffusion_load_profiles.energy_plus_normalized_space_cooling_com
UNION
select count(*)
FROM diffusion_load_profiles.energy_plus_normalized_space_heating_com
UNION
select count(*)
FROM diffusion_load_profiles.energy_plus_normalized_water_heating_com
UNION
select count(*)
FROM diffusion_load_profiles.energy_plus_normalized_water_and_space_heating_com;
-- 14960 -- what gives? = 16*(936-1) instead of the expected 16*(936-3)

-- apparently two of the ids have data that are absent from the electric load data
select *
from diffusion_load_profiles.energy_plus_max_normalized_demand_water_and_space_heating_com a
left join diffusion_load_profiles.energy_plus_max_normalized_demand_com b -- electricity
ON a.hdf_index = b.hdf_index
and a.crb_model = b.crb_model
where b.crb_model is null; 
-- hdf_index 189 and 190 -- so I think this should be all set
---------------------------------------------------------------------------------------------------


-- how about building types?
-- res -- should be 3
select array_agg(distinct(crb_model))
FROM diffusion_load_profiles.energy_plus_max_normalized_demand_space_cooling_res
UNION
select array_agg(distinct(crb_model))
FROM diffusion_load_profiles.energy_plus_max_normalized_demand_space_heating_res
UNION
select array_agg(distinct(crb_model))
FROM diffusion_load_profiles.energy_plus_max_normalized_demand_water_heating_res
UNION
select array_agg(distinct(crb_model))
FROM diffusion_load_profiles.energy_plus_max_normalized_demand_water_and_space_heating_res
UNION
select array_agg(distinct(crb_model))
FROM diffusion_load_profiles.energy_plus_normalized_space_cooling_res
UNION
select array_agg(distinct(crb_model))
FROM diffusion_load_profiles.energy_plus_normalized_space_heating_res
UNION
select array_agg(distinct(crb_model))
FROM diffusion_load_profiles.energy_plus_normalized_water_heating_res
UNION
select array_agg(distinct(crb_model))
FROM diffusion_load_profiles.energy_plus_normalized_water_and_space_heating_res;
-- 3 - all set

-- com -- should be 16
select array_agg(distinct(crb_model))
FROM diffusion_load_profiles.energy_plus_max_normalized_demand_space_cooling_com
UNION
select array_agg(distinct(crb_model))
FROM diffusion_load_profiles.energy_plus_max_normalized_demand_space_heating_com
UNION
select array_agg(distinct(crb_model))
FROM diffusion_load_profiles.energy_plus_max_normalized_demand_water_heating_com
UNION
select array_agg(distinct(crb_model))
FROM diffusion_load_profiles.energy_plus_max_normalized_demand_water_and_space_heating_com
UNION
select array_agg(distinct(crb_model))
FROM diffusion_load_profiles.energy_plus_normalized_space_cooling_com
UNION
select array_agg(distinct(crb_model))
FROM diffusion_load_profiles.energy_plus_normalized_space_heating_com
UNION
select array_agg(distinct(crb_model))
FROM diffusion_load_profiles.energy_plus_normalized_water_heating_com
UNION
select array_agg(distinct(crb_model))
FROM diffusion_load_profiles.energy_plus_normalized_water_and_space_heating_com;
-- 16 -- all set
------------------------------------------------------------------------------------------
-- add primary keys
ALTER TABLE diffusion_load_profiles.energy_plus_max_normalized_demand_space_cooling_res
ADD PRIMARY KEY (hdf_index, crb_model);

ALTER TABLE diffusion_load_profiles.energy_plus_max_normalized_demand_space_heating_res
ADD PRIMARY KEY (hdf_index, crb_model);

ALTER TABLE diffusion_load_profiles.energy_plus_max_normalized_demand_water_heating_res
ADD PRIMARY KEY (hdf_index, crb_model);

ALTER TABLE diffusion_load_profiles.energy_plus_max_normalized_demand_water_and_space_heating_res
ADD PRIMARY KEY (hdf_index, crb_model);

ALTER TABLE diffusion_load_profiles.energy_plus_normalized_space_cooling_res
ADD PRIMARY KEY (hdf_index, crb_model);

ALTER TABLE diffusion_load_profiles.energy_plus_normalized_space_heating_res
ADD PRIMARY KEY (hdf_index, crb_model);

ALTER TABLE diffusion_load_profiles.energy_plus_normalized_water_heating_res
ADD PRIMARY KEY (hdf_index, crb_model);

ALTER TABLE diffusion_load_profiles.energy_plus_normalized_water_and_space_heating_res
ADD PRIMARY KEY (hdf_index, crb_model);

ALTER TABLE diffusion_load_profiles.energy_plus_max_normalized_demand_space_cooling_com
ADD PRIMARY KEY (hdf_index, crb_model);

ALTER TABLE diffusion_load_profiles.energy_plus_max_normalized_demand_space_heating_com
ADD PRIMARY KEY (hdf_index, crb_model);

ALTER TABLE diffusion_load_profiles.energy_plus_max_normalized_demand_water_heating_com
ADD PRIMARY KEY (hdf_index, crb_model);

ALTER TABLE diffusion_load_profiles.energy_plus_max_normalized_demand_water_and_space_heating_com
ADD PRIMARY KEY (hdf_index, crb_model);

ALTER TABLE diffusion_load_profiles.energy_plus_normalized_space_cooling_com
ADD PRIMARY KEY (hdf_index, crb_model);

ALTER TABLE diffusion_load_profiles.energy_plus_normalized_space_heating_com
ADD PRIMARY KEY (hdf_index, crb_model);

ALTER TABLE diffusion_load_profiles.energy_plus_normalized_water_heating_com
ADD PRIMARY KEY (hdf_index, crb_model);

ALTER TABLE diffusion_load_profiles.energy_plus_normalized_water_and_space_heating_com
ADD PRIMARY KEY (hdf_index, crb_model);
------------------------------------------------------------------------------------------
-- add indices
CREATE INDEX eplus_max_normalized_demand_space_cooling_res_btree_hdf_index
ON diffusion_load_profiles.energy_plus_max_normalized_demand_space_cooling_res
USING BTREE(hdf_index);

CREATE INDEX eplus_max_normalized_demand_space_heating_res_btree_hdf_index
ON diffusion_load_profiles.energy_plus_max_normalized_demand_space_heating_res
USING BTREE(hdf_index);

CREATE INDEX eplus_max_normalized_demand_water_heating_res_btree_hdf_index
ON diffusion_load_profiles.energy_plus_max_normalized_demand_water_heating_res
USING BTREE(hdf_index);

CREATE INDEX eplus_max_normalized_demand_water_and_space_heating_res_btree_hdf_index
ON diffusion_load_profiles.energy_plus_max_normalized_demand_water_and_space_heating_res
USING BTREE(hdf_index);

CREATE INDEX eplus_normalized_space_cooling_res_btree_hdf_index
ON diffusion_load_profiles.energy_plus_normalized_space_cooling_res
USING BTREE(hdf_index);

CREATE INDEX eplus_normalized_space_heating_res_btree_hdf_index
ON diffusion_load_profiles.energy_plus_normalized_space_heating_res
USING BTREE(hdf_index);

CREATE INDEX eplus_normalized_water_heating_res_btree_hdf_index
ON diffusion_load_profiles.energy_plus_normalized_water_heating_res
USING BTREE(hdf_index);

CREATE INDEX eplus_normalized_water_and_space_heating_res_btree_hdf_index
ON diffusion_load_profiles.energy_plus_normalized_water_and_space_heating_res
USING BTREE(hdf_index);

CREATE INDEX eplus_max_normalized_demand_space_cooling_com_btree_hdf_index
ON diffusion_load_profiles.energy_plus_max_normalized_demand_space_cooling_com
USING BTREE(hdf_index);

CREATE INDEX eplus_max_normalized_demand_space_heating_com_btree_hdf_index
ON diffusion_load_profiles.energy_plus_max_normalized_demand_space_heating_com
USING BTREE(hdf_index);

CREATE INDEX eplus_max_normalized_demand_water_heating_com_btree_hdf_index
ON diffusion_load_profiles.energy_plus_max_normalized_demand_water_heating_com
USING BTREE(hdf_index);

CREATE INDEX eplus_max_normalized_demand_water_and_space_heating_com_btree_hdf_index
ON diffusion_load_profiles.energy_plus_max_normalized_demand_water_and_space_heating_com
USING BTREE(hdf_index);

CREATE INDEX eplus_normalized_space_cooling_com_btree_hdf_index
ON diffusion_load_profiles.energy_plus_normalized_space_cooling_com
USING BTREE(hdf_index);

CREATE INDEX eplus_normalized_space_heating_com_btree_hdf_index
ON diffusion_load_profiles.energy_plus_normalized_space_heating_com
USING BTREE(hdf_index);

CREATE INDEX eplus_normalized_water_heating_com_btree_hdf_index
ON diffusion_load_profiles.energy_plus_normalized_water_heating_com
USING BTREE(hdf_index);

CREATE INDEX eplus_normalized_water_and_space_heating_com_btree_hdf_index
ON diffusion_load_profiles.energy_plus_normalized_water_and_space_heating_com
USING BTREE(hdf_index);

CREATE INDEX eplus_max_normalized_demand_space_cooling_res_btree_crb_model
ON diffusion_load_profiles.energy_plus_max_normalized_demand_space_cooling_res
USING BTREE(crb_model);

CREATE INDEX eplus_max_normalized_demand_space_heating_res_btree_crb_model
ON diffusion_load_profiles.energy_plus_max_normalized_demand_space_heating_res
USING BTREE(crb_model);

CREATE INDEX eplus_max_normalized_demand_water_heating_res_btree_crb_model
ON diffusion_load_profiles.energy_plus_max_normalized_demand_water_heating_res
USING BTREE(crb_model);

CREATE INDEX eplus_max_normalized_demand_water_and_space_heating_res_btree_crb_model
ON diffusion_load_profiles.energy_plus_max_normalized_demand_water_and_space_heating_res
USING BTREE(crb_model);

CREATE INDEX eplus_normalized_space_cooling_res_btree_crb_model
ON diffusion_load_profiles.energy_plus_normalized_space_cooling_res
USING BTREE(crb_model);

CREATE INDEX eplus_normalized_space_heating_res_btree_crb_model
ON diffusion_load_profiles.energy_plus_normalized_space_heating_res
USING BTREE(crb_model);

CREATE INDEX eplus_normalized_water_heating_res_btree_crb_model
ON diffusion_load_profiles.energy_plus_normalized_water_heating_res
USING BTREE(crb_model);

CREATE INDEX eplus_normalized_water_and_space_heating_res_btree_crb_model
ON diffusion_load_profiles.energy_plus_normalized_water_and_space_heating_res
USING BTREE(crb_model);

CREATE INDEX eplus_max_normalized_demand_space_cooling_com_btree_crb_model
ON diffusion_load_profiles.energy_plus_max_normalized_demand_space_cooling_com
USING BTREE(crb_model);

CREATE INDEX eplus_max_normalized_demand_space_heating_com_btree_crb_model
ON diffusion_load_profiles.energy_plus_max_normalized_demand_space_heating_com
USING BTREE(crb_model);

CREATE INDEX eplus_max_normalized_demand_water_heating_com_btree_crb_model
ON diffusion_load_profiles.energy_plus_max_normalized_demand_water_heating_com
USING BTREE(crb_model);

CREATE INDEX eplus_max_normalized_demand_water_and_space_heating_com_btree_crb_model
ON diffusion_load_profiles.energy_plus_max_normalized_demand_water_and_space_heating_com
USING BTREE(crb_model);

CREATE INDEX eplus_normalized_space_cooling_com_btree_crb_model
ON diffusion_load_profiles.energy_plus_normalized_space_cooling_com
USING BTREE(crb_model);

CREATE INDEX eplus_normalized_space_heating_com_btree_crb_model
ON diffusion_load_profiles.energy_plus_normalized_space_heating_com
USING BTREE(crb_model);

CREATE INDEX eplus_normalized_water_heating_com_btree_crb_model
ON diffusion_load_profiles.energy_plus_normalized_water_heating_com
USING BTREE(crb_model);

CREATE INDEX eplus_normalized_water_and_space_heating_com_btree_crb_model
ON diffusion_load_profiles.energy_plus_normalized_water_and_space_heating_com
USING BTREE(crb_model);

------------------------------------------------------------------------------------------
-- check for zeros in cooling and combined heating datsets
select *
FROM diffusion_load_profiles.energy_plus_max_normalized_demand_space_cooling_com
WHERE normalized_max_demand_kw_per_kw = 0;
-- 1
-- 68,warehouse

select *
FROM diffusion_load_profiles.energy_plus_max_normalized_demand_space_cooling_res
WHERE normalized_max_demand_kw_per_kw = 0
AND crb_model = 'reference';
-- 4
-- 0,reference
-- 144,reference
-- 593,reference
-- 891,reference

select *
FROM diffusion_load_profiles.energy_plus_max_normalized_demand_water_and_space_heating_com
WHERE normalized_max_demand_kw_per_kw = 0;
-- 8
-- 221,stand_alone_retail
-- 222,stand_alone_retail
-- 223,stand_alone_retail
-- 224,stand_alone_retail
-- 225,stand_alone_retail
-- 226,stand_alone_retail
-- 228,stand_alone_retail
-- 225,strip_mall

select *
FROM diffusion_load_profiles.energy_plus_max_normalized_demand_water_and_space_heating_res
WHERE normalized_max_demand_kw_per_kw = 0;
-- 0 -- all set

-- look into each of these 3 cases
------------------------------------
-- COM, space cooling
select *
FROM diffusion_data_shared.energy_plus_load_meta
where hdf_index = 68;
-- this is a station in cresecent city CA

-- how many blocks have this id
select *
from diffusion_blocks.block_load_profile_id_com a
LEFT JOIN diffusion_blocks.block_geoms b
ON a.pgid = b.pgid
where a.hdf_load_index = 68;
-- several -- 3669 -- solution should be to replace with data from another nearby station

set role 'diffusion-writers';
DROP TABLE if exists diffusion_data_shared.hdf_index_geoms;
CREATE TABLE diffusion_data_shared.hdf_index_geoms as
SELECT a.*, b.gid as nsrdb_gid, b.the_geom_4326
FROM diffusion_data_shared.energy_plus_load_meta a
LEFT JOIN solar.solar_re_9809 b
ON a.usaf = b.usaf;
-- looking at the data in Q, it looks like there are a few options from nearest neighbors
-- select 53 as the best since it surrounds 68 on two sides

DELETE
FROM diffusion_load_profiles.energy_plus_max_normalized_demand_space_cooling_com
where hdf_index = 68
and crb_model = 'warehouse';
-- 1 row deleted

-- insrt the data from 53
INSERT INTO diffusion_load_profiles.energy_plus_max_normalized_demand_space_cooling_com
SELECT 68, crb_model, normalized_max_demand_kw_per_kw, annual_sum_kwh
from diffusion_load_profiles.energy_plus_max_normalized_demand_space_cooling_com
where hdf_index = 53
and crb_model = 'warehouse';
-- 1 row added

-- do the same for the laod profiles
DELETE
FROM diffusion_load_profiles.energy_plus_normalized_space_cooling_com
where hdf_index = 68
and crb_model = 'warehouse';
-- 1 row deleted

-- insert the data from 53
INSERT INTO diffusion_load_profiles.energy_plus_normalized_space_cooling_com
SELECT 68, crb_model, nkwh
from diffusion_load_profiles.energy_plus_normalized_space_cooling_com
where hdf_index = 53
and crb_model = 'warehouse';
-- 1 row added


------------------------------------
-- COM, water and space heating
select *
FROM diffusion_data_shared.energy_plus_load_meta
where hdf_index between 221 and 228;
-- these are all in hawaii, which we arent currently modeling -- so all set


------------------------------------
-- RES, space cooling

select *
FROM diffusion_data_shared.energy_plus_load_meta
where hdf_index in (0, 144, 593, 891, 386);
--  0 = anchorage -- safe to ignore
-- the rest of these are also very cold areas (leadville co, mt washington nh, but we probably need to fill them
-- because the microdata won't be resolved to this level)

-- using Q, find reasonable nearest neighbor proxies for each of these:
-- 144,reference -- use 127
-- 593,reference -- use 588
-- 891,reference -- use 864

-- fix these (for all residential crb types)

-- 144,reference -- use 127
DELETE
FROM diffusion_load_profiles.energy_plus_max_normalized_demand_space_cooling_res
where hdf_index = 144;
-- 3 rows deleted

-- insrt the data from 53
INSERT INTO diffusion_load_profiles.energy_plus_max_normalized_demand_space_cooling_res
SELECT 144, crb_model, normalized_max_demand_kw_per_kw, annual_sum_kwh
from diffusion_load_profiles.energy_plus_max_normalized_demand_space_cooling_res
where hdf_index = 127;
-- 3 rows added

-- do the same for the laod profiles
DELETE
FROM diffusion_load_profiles.energy_plus_normalized_space_cooling_res
where hdf_index = 144;
-- 3 rows deleted

-- insert the data from 53
INSERT INTO diffusion_load_profiles.energy_plus_normalized_space_cooling_res
SELECT 144, crb_model, nkwh
from diffusion_load_profiles.energy_plus_normalized_space_cooling_res
where hdf_index = 127;
-- 3 rows added



-- 593,reference -- use 588
DELETE
FROM diffusion_load_profiles.energy_plus_max_normalized_demand_space_cooling_res
where hdf_index = 593;
-- 3 rows deleted

-- insrt the data from 53
INSERT INTO diffusion_load_profiles.energy_plus_max_normalized_demand_space_cooling_res
SELECT 593, crb_model, normalized_max_demand_kw_per_kw, annual_sum_kwh
from diffusion_load_profiles.energy_plus_max_normalized_demand_space_cooling_res
where hdf_index = 588;
-- 3 rows added

-- do the same for the laod profiles
DELETE
FROM diffusion_load_profiles.energy_plus_normalized_space_cooling_res
where hdf_index = 593;
-- 3 rows deleted

-- insert the data from 53
INSERT INTO diffusion_load_profiles.energy_plus_normalized_space_cooling_res
SELECT 593, crb_model, nkwh
from diffusion_load_profiles.energy_plus_normalized_space_cooling_res
where hdf_index = 588;
-- 3 rows added


-- 891,reference -- use 864
DELETE
FROM diffusion_load_profiles.energy_plus_max_normalized_demand_space_cooling_res
where hdf_index = 891;
-- 3 rows deleted

-- insrt the data from 53
INSERT INTO diffusion_load_profiles.energy_plus_max_normalized_demand_space_cooling_res
SELECT 891, crb_model, normalized_max_demand_kw_per_kw, annual_sum_kwh
from diffusion_load_profiles.energy_plus_max_normalized_demand_space_cooling_res
where hdf_index = 864;
-- 3 rows added

-- do the same for the laod profiles
DELETE
FROM diffusion_load_profiles.energy_plus_normalized_space_cooling_res
where hdf_index = 891;
-- 3 rows deleted

-- insert the data from 53
INSERT INTO diffusion_load_profiles.energy_plus_normalized_space_cooling_res
SELECT 891, crb_model, nkwh
from diffusion_load_profiles.energy_plus_normalized_space_cooling_res
where hdf_index = 864;
-- 3 rows added

-- recheck everything
select *
FROM diffusion_load_profiles.energy_plus_max_normalized_demand_space_cooling_com
WHERE normalized_max_demand_kw_per_kw = 0;
-- 0 - all set

select *
FROM diffusion_load_profiles.energy_plus_max_normalized_demand_space_cooling_res
WHERE normalized_max_demand_kw_per_kw = 0
AND crb_model = 'reference';
-- 0,reference -- this is AK and ok to be missing (for now, since we don't model AK)


select *
FROM diffusion_load_profiles.energy_plus_max_normalized_demand_water_and_space_heating_com
WHERE normalized_max_demand_kw_per_kw = 0;
-- 8 -- these are all AK and are okay t obe missing

select *
FROM diffusion_load_profiles.energy_plus_max_normalized_demand_water_and_space_heating_res
WHERE normalized_max_demand_kw_per_kw = 0;
-- 0 -- all set

------------------------------------------------------------