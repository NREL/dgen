-- create function to calculate accessible resource base
SET ROLE 'server-superusers';
DROP FUNCTION IF EXISTS diffusion_geo.beneficial_heat_joules_recovery_factor(numeric, numeric, numeric, numeric, numeric, numeric);
CREATE OR REPLACE FUNCTION diffusion_geo.beneficial_heat_joules_recovery_factor(
				volume_km3 numeric, 
				res_temp_deg_c numeric, 
				recovery_factor numeric default 0.125,
				ref_temp_deg_c numeric DEFAULT 25, 
				efficiency_factor numeric default 0.6,
				specific_heat_j_per_cm3_deg_c numeric DEFAULT 2.6)

				
RETURNS numeric AS 
$BODY$
	cm3_per_km3 = 1e15
	acc_resource = specific_heat_j_per_cm3_deg_c * cm3_per_km3 * volume_km3 * (res_temp_deg_c - ref_temp_deg_c)
	ben_heat = acc_resource * recovery_factor * efficiency_factor
	return (ben_heat) ;
$BODY$
LANGUAGE 'plr'
COST 100;


select diffusion_geo.beneficial_heat_joules_recovery_factor(1, 87, .25)/3600000000/(30*8760);
-- should return 25.77 (Battleship Mountain Spring)
-- returns 25.5580923389142567
-- all set
