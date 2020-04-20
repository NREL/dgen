-- DROP FUNCTION public.r_quantile(numeric[], numeric);
SET ROLE 'server-superusers';
CREATE OR REPLACE FUNCTION diffusion_shared.r_remove_nulls_from_array(x TExT[])
  RETURNS TEXT[] AS
$BODY$
	y = x[!is.na(x)]
	return(y)
$BODY$
  LANGUAGE plr VOLATILE
  COST 100;


--   select r_median(array[1,2,3,3,3,5])
