SET ROLE 'diffusion-writers';

-- duplicate com table as ind table
DROP VIEW IF EXISTS diffusion_load_profiles.energy_plus_normalized_load_ind;
CREATE VIEW diffusion_load_profiles.energy_plus_normalized_load_ind AS
SELECT *
FROM diffusion_load_profiles.energy_plus_normalized_load_com;