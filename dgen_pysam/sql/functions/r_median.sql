-- DROP FUNCTION public.r_quantile(numeric[], numeric);
SET ROLE 'server-superusers';
CREATE OR REPLACE FUNCTION diffusion_shared.r_median(numarr numeric[])
  RETURNS double precision AS
$BODY$
	m = median(numarr, na.rm =T)
	return(m)
$BODY$
  LANGUAGE plr VOLATILE
  COST 100;


--   select r_median(array[1,2,3,3,3,5])
