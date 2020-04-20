-- create function to calculate accessible resource base
SET ROLE 'server-superusers';
DROP FUNCTION IF EXISTS diffusion_geo.extractable_resource_joules_recovery_factor(numeric, numeric, numeric, numeric, numeric);
CREATE OR REPLACE FUNCTION diffusion_geo.extractable_resource_joules_recovery_factor(
				volume_km3 numeric, 
				res_temp_deg_c numeric, 
				recovery_factor numeric default 0.125,
				ref_temp_deg_c numeric DEFAULT 15, 
				specific_heat_j_per_cm3_deg_c numeric DEFAULT 2.6)
RETURNS numeric AS 
$BODY$
	cm3_per_km3 = 1e15
	acc_resource = specific_heat_j_per_cm3_deg_c * cm3_per_km3 * volume_km3 * (res_temp_deg_c - ref_temp_deg_c)
	extractable_resource = acc_resource * recovery_factor
	return (extractable_resource) ;
$BODY$
LANGUAGE 'plr'
COST 100;


select diffusion_geo.extractable_resource_joules_recovery_factor(1, 53, .25)/1e18;
-- should return .040 (Craig Hot Springs)
-- returns 0.04030000000000000000
-- all set


SET ROLE 'server-superusers';
DROP FUNCTION IF EXISTS diffusion_geo.extractable_resource_joules_recovery_factor(numeric, numeric);
CREATE OR REPLACE FUNCTION diffusion_geo.extractable_resource_joules_recovery_factor(
				acc_resource numeric, 
				recovery_factor numeric default 0.125)
RETURNS numeric AS 
$BODY$
	extractable_resource = acc_resource * recovery_factor
	return (extractable_resource) ;
$BODY$
LANGUAGE 'plr'
COST 100;