-- DROP FUNCTION public.r_quantile(numeric[], numeric);

CREATE OR REPLACE FUNCTION diffusion_shared.r_quantile(numarr numeric[], prob numeric)
  RETURNS double precision AS
$BODY$
	q = quantile(numarr,prob, na.rm =T)
	return(q)
$BODY$
  LANGUAGE plr VOLATILE
  COST 100;
