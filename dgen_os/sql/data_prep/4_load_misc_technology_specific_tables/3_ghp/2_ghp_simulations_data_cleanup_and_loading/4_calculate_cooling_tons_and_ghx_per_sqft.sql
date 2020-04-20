set role 'diffusion-writers';

-- add cooling_ton_per_sqft and ghx_length_ft_per_cooling_ton cols
ALTER TABLE  diffusion_geo.ornl_ghp_simulations
ADD COLUMN cooling_ton_per_sqft numeric,
ADD COLUMN ghx_length_ft_per_cooling_ton numeric;

UPDATE diffusion_geo.ornl_ghp_simulations
set cooling_ton_per_sqft = crb_cooling_capacity_ton/crb_totsqft;
-- 156 rows

UPDATE diffusion_geo.ornl_ghp_simulations
set ghx_length_ft_per_cooling_ton = crb_ghx_length_ft/crb_cooling_capacity_ton;
-- 156 rows

-- check for nulls
select *
FROM diffusion_geo.ornl_ghp_simulations
where ghx_length_ft_per_cooling_ton is null
or cooling_ton_per_sqft is null;