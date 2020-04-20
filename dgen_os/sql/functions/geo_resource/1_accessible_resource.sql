-- create function to calculate accessible resource base
SET ROLE 'server-superusers';
DROP FUNCTION IF EXISTS diffusion_geo.accessible_resource_joules(numeric, numeric, numeric, numeric);
CREATE OR REPLACE FUNCTION diffusion_geo.accessible_resource_joules(volume_km3 numeric, res_temp_deg_c numeric, ref_temp_deg_c numeric DEFAULT 15, specific_heat_j_per_cm3_deg_c numeric DEFAULT 2.6)
RETURNS numeric AS 
$BODY$
	cm3_per_km3 = 1e15
	acc_resource = specific_heat_j_per_cm3_deg_c * cm3_per_km3 * volume_km3 * (res_temp_deg_c - ref_temp_deg_c)
	return(acc_resource)
$BODY$
LANGUAGE 'plr'
COST 100;


select diffusion_geo.accessible_resource_joules(1170 *.152, 60)/1e18;
-- should return 21 (Moffat and Routt)
-- returns 20.8072800000000000
-- all set