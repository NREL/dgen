set role 'server-superusers';

SELECT add_schema('diffusion_load_profiles', 'diffusion');

ALTER TABLE diffusion_shared.energy_plus_normalized_load_com
set schema diffusion_load_profiles;

ALTER TABLE diffusion_shared.energy_plus_normalized_load_res
set schema diffusion_load_profiles;

ALTER TABLE diffusion_shared.energy_plus_max_normalized_demand_com
set schema diffusion_load_profiles;

ALTER TABLE diffusion_shared.energy_plus_max_normalized_demand_res
set schema diffusion_load_profiles;

ALTER VIEW diffusion_shared.energy_plus_max_normalized_demand
set schema diffusion_load_profiles;