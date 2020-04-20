set role 'server-superusers';

DROP FUNCTION IF EXISTS public.r_mean_array(numeric[], integer[]);

CREATE OR REPLACE FUNCTION public.r_mean_array(numarr numeric[], i integer[])
  RETURNS numeric AS
$BODY$
	result = mean(numarr[i])
	return(result)
$BODY$
  LANGUAGE plr STABLE
  COST 100;
