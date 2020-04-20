set role 'diffusion-writers';

DROP TABLE IF EXISTS diffusion_geo.crb_building_names_and_sizes;
CREATE TABLE diffusion_geo.crb_building_names_and_sizes
(
	baseline_type integer primary key,
	ornl_building_type text,
	crb_model text,
	crb_totsqft numeric
);

\COPY diffusion_geo.crb_building_names_and_sizes FROM '/Users/kmccabe/dGeo/Data/ORNL_GHP_CRB_Simulations/ghp_simulation_results/helper/crb_bldg_names_and_sizes.csv' with csv header;


-- add this info to the main table
ALTER TABLE diffusion_geo.ornl_ghp_simulations
ADD COLUMN crb_totsqft numeric,
add column crb_model text;

UPDATE diffusion_geo.ornl_ghp_simulations a 
set (crb_totsqft, crb_model) = (b.crb_totsqft, b.crb_model)
from diffusion_geo.crb_building_names_and_sizes b
where a.baseline_type = b.baseline_type;
-- 156 rows affected

-- check result
select distinct baseline_type, crb_model, crb_totsqft
from diffusion_geo.ornl_ghp_simulations
order by baseline_type;
-- looks good
