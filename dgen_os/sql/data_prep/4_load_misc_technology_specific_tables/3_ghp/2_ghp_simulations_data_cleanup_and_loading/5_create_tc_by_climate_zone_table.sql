set role 'diffusion-writers';

-- need to create a differetn version of the tc by cliamte zone summary because xiaobing
-- used different values in simulations than i did
-- the real table we SHOULD be using is diffusion_geo.thermal_conductivity_summary_by_climate_zone

DROP TABLE IF EXISTS diffusion_geo.thermal_conductivity_summary_by_climate_zone_ornl;
CREATE TABLE diffusion_geo.thermal_conductivity_summary_by_climate_zone_ornl AS
with a AS
(
	select distinct iecc_climate_zone, gtc_btu_per_hftf
	from diffusion_geo.ornl_ghp_simulations
),
b as
(
	select iecc_climate_zone, array_agg(gtc_btu_per_hftf) as gtc_vals
	from a
	group by iecc_climate_zone
)
select iecc_climate_zone, 
	gtc_vals[1] as q25, 
	gtc_vals[2] as q50, 
	gtc_vals[3] as q75
from b;
-- 13 rows

-- fill in other values from diffusion_geo.thermal_conductivity_summary_by_climate_zone
INSERT INTO diffusion_geo.thermal_conductivity_summary_by_climate_zone_ornl
select a.climate_zone as iecc_climate_zone,
	a.q25,
	a.q50,
	a.q75
from diffusion_geo.thermal_conductivity_summary_by_climate_zone a
lEFT JOIN diffusion_geo.thermal_conductivity_summary_by_climate_zone_ornl b
ON a.climate_zone = b.iecc_climate_zone
where b.iecc_climate_zone is null;
-- 3 rows added (1A, 7A, 7B) 
-- note: these don't really matter since we don't have GHP CRB simulations for  them
-- but they will ensure that all agents for all areas of CONUS can be populated with GTC