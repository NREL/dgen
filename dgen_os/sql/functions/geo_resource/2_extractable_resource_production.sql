-- create function to calculate accessible resource base
SET ROLE 'server-superusers';
DROP FUNCTION IF EXISTS diffusion_geo.extractable_resource_joules_production_plan(numeric, numeric, numeric, numeric, numeric, numeric, numeric);
CREATE OR REPLACE FUNCTION diffusion_geo.extractable_resource_joules_production_plan(
				n_wells numeric, 
				res_temp_c numeric, 
				specific_heat_j_per_cm3_deg_c numeric default 4.1, 
				k numeric default 0.5,
				discharge_l_per_s numeric default 31.5, 
				production_duration_years numeric default 30,
				ref_temp_c numeric default 15)
RETURNS numeric AS 
$BODY$
	seconds_per_year = 3.154e+7
	cm3_per_l = 1000
	extractable_resource =  specific_heat_j_per_cm3_deg_c * cm3_per_l * k * n_wells * discharge_l_per_s * seconds_per_year * production_duration_years * (res_temp_c - ref_temp_c)
	return (extractable_resource) ;
$BODY$
LANGUAGE 'plr'
COST 100;


select diffusion_geo.extractable_resource_joules_production_plan(800/9.03, 57)/1e18;
-- should return .23 (Eastern Imperial Valley)
-- returns 0.22735205581395347200
