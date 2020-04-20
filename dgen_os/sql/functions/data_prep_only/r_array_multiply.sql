-- DROP FUNCTION public.r_array_multiply(numeric[], numeric);

CREATE OR REPLACE FUNCTION public.r_array_multiply(numarr numeric[], scalar numeric)
  RETURNS numeric[] AS
$BODY$
	scaled = numarr * scalar
	return(scaled)
$BODY$
  LANGUAGE plr STABLE
  COST 100;
