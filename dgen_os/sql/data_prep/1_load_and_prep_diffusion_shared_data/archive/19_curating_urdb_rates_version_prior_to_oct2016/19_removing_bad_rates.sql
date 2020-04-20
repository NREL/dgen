-- ben identified the following rates as potential issues 
-- because they return negative or zero costs of electiricty without system
-- in the model

-- look into what's going on
select *
FROM urdb_rates.urdb3_verified_rates_sam_data_20141202 a
where a.rate_id_alias in (842, 896, 1747, 637, 64, 24);

select *
FROM urdb_rates.urdb3_singular_rates_sam_data_20141202 a
where a.rate_id_alias in (842, 896, 1747, 637, 64, 24);

-- open the rateurl and review
-- 539f759eec4f024411ed164b -- 0 charges
-- 539f74f3ec4f024411ed0dfb -- 0 charges
-- 539fc1deec4f024c27d8abd9 -- low fixed charge w/ negative energy charge
-- 24 -- 539f6a46ec4f024411ec8da7 -- 0 charges
-- 637 -- 539f720aec4f024411ececb7 -- 0 charges
-- 64 -- 539f6acdec4f024411ec94a9 -- 0 charges

------------------------------------------------------------------------------------------------------------
-- remove these rates from the relevant tables urdb_rates schema
DELETE FROM  urdb_rates.urdb3_singular_rates_sam_data_20141202
where urdb_rate_id in ('539f759eec4f024411ed164b', '539f74f3ec4f024411ed0dfb', '539fc1deec4f024c27d8abd9', '539f6a46ec4f024411ec8da7', '539f720aec4f024411ececb7', '539f6acdec4f024411ec94a9');

DELETE FROM urdb_rates.urdb3_verified_rates_sam_data_20141202
where urdb_rate_id in ('539f759eec4f024411ed164b', '539f74f3ec4f024411ed0dfb', '539fc1deec4f024c27d8abd9', '539f6a46ec4f024411ec8da7', '539f720aec4f024411ececb7', '539f6acdec4f024411ec94a9');

DELETE FROM  urdb_rates.urdb3_singular_rates_lookup_20141202
where urdb_rate_id in ('539f759eec4f024411ed164b', '539f74f3ec4f024411ed0dfb', '539fc1deec4f024c27d8abd9', '539f6a46ec4f024411ec8da7', '539f720aec4f024411ececb7', '539f6acdec4f024411ec94a9');

DELETE FROM urdb_rates.urdb3_verified_rates_lookup_20141202
where urdb_rate_id in ('539f759eec4f024411ed164b', '539f74f3ec4f024411ed0dfb', '539fc1deec4f024c27d8abd9', '539f6a46ec4f024411ec8da7', '539f720aec4f024411ececb7', '539f6acdec4f024411ec94a9');

DELETE FROM urdb_rates.urdb3_rate_id_aliases_20141202
where urdb_rate_id in ('539f759eec4f024411ed164b', '539f74f3ec4f024411ed0dfb', '539fc1deec4f024c27d8abd9', '539f6a46ec4f024411ec8da7', '539f720aec4f024411ececb7', '539f6acdec4f024411ec94a9');

-- check that they were removed from the lookup view too
select *
FROM urdb_rates.combined_singular_verified_rates_lookup
where rate_id_alias in (842, 896, 1747, 637, 64, 24);
-- good
------------------------------------------------------------------------------------------------------------


------------------------------------------------------------------------------------------------------------
-- remove these rates from relevant tables in diffusion_shared
DELETE FROM diffusion_shared.urdb3_rate_sam_jsons
where rate_id_alias in (842, 896, 1747, 637, 64, 24);


DELETE FROM diffusion_shared.urdb_rates_geoms_com 
WHERE rate_id_alias in (842, 896, 1747, 637, 64, 24);

DELETE FROM diffusion_shared.urdb_rates_geoms_res 
WHERE rate_id_alias in (842, 896, 1747, 637, 64, 24);


DELETE FROM diffusion_shared.urdb_rates_by_state_com 
WHERE rate_id_alias in (842, 896, 1747, 637, 64, 24);

DELETE FROM diffusion_shared.urdb_rates_by_state_ind 
WHERE rate_id_alias in (842, 896, 1747, 637, 64, 24);

DELETE FROM diffusion_shared.urdb_rates_by_state_res 
WHERE rate_id_alias in (842, 896, 1747, 637, 64, 24);


DELETE FROM diffusion_shared.pt_rate_isect_lkup_com 
WHERE rate_id_alias in (842, 896, 1747, 637, 64, 24);

DELETE FROM diffusion_shared.pt_rate_isect_lkup_ind 
WHERE rate_id_alias in (842, 896, 1747, 637, 64, 24);

DELETE FROM diffusion_shared.pt_rate_isect_lkup_res 
WHERE rate_id_alias in (842, 896, 1747, 637, 64, 24);


