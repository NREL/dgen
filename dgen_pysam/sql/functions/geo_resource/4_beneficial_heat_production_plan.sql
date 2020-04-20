-- create function to calculate accessible resource base
SET ROLE 'server-superusers';
DROP FUNCTION IF EXISTS diffusion_geo.beneficial_heat_joules_production_plan(numeric, numeric, numeric, numeric, numeric, numeric, numeric, numeric);
CREATE OR REPLACE FUNCTION diffusion_geo.beneficial_heat_joules_production_plan(
				n_wells numeric, 
				res_temp_c numeric, 
				efficiency_factor numeric default 0.6,
				ref_temp_c numeric default 25,
				specific_heat_j_per_cm3_deg_c numeric default 4.1, 
				k numeric default 0.5, 
				discharge_l_per_s numeric default 31.5, 
				production_duration_years numeric default 30
				)

				
RETURNS numeric AS 
$BODY$
	seconds_per_year = 3.154e+7
	cm3_per_l = 1000
	ben_heat =  specific_heat_j_per_cm3_deg_c * cm3_per_l * k * n_wells * discharge_l_per_s * seconds_per_year * production_duration_years * efficiency_factor * (res_temp_c - ref_temp_c)
	return (ben_heat) ;
$BODY$
LANGUAGE 'plr'
COST 100;


select diffusion_geo.beneficial_heat_joules_production_plan(280/5.7, 30)/3600000000/(30*8760);
-- should return 9,7 (Ephrata)
-- returns 9.5175228310502283
-- all set
