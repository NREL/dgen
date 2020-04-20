SET ROLE 'server-superusers';
DROP FUNCTION IF EXISTS diffusion_shared.r_scale_array_sum(numarr numeric[], sum_val numeric);
CREATE OR REPLACE FUNCTION diffusion_shared.r_scale_array_sum(numarr numeric[], sum_val numeric)
  RETURNS NUMERIC[] AS
$BODY$
	if (sum_val != 0){
		scaled_array = numarr * sum_val
		unscaled_array = scaled_array/sum(scaled_array)
		rescaled_array = unscaled_array * sum_val
	} else {
		rescaled_array = numarr * 0
	}

	return(rescaled_array)
$BODY$
  LANGUAGE plr VOLATILE
  COST 100;
