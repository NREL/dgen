SET ROLE 'server-superusers';
DROP FUNCTION IF EXISTS diffusion_shared.r_scale_array_precision(numarr numeric[], precision_val numeric);
CREATE OR REPLACE FUNCTION diffusion_shared.r_scale_array_precision(numarr numeric[], precision_val numeric)
  RETURNS NUMERIC[] AS
$BODY$
	scaled_array = numarr * precision_val
	return(scaled_array)
$BODY$
  LANGUAGE plr VOLATILE
  COST 100;





