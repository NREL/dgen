-- DROP FUNCTION public.r_cut(numeric, numeric[])
SET ROLE 'server-superusers';
CREATE OR REPLACE FUNCTION diffusion_shared.r_cut(val numeric, breaks numeric[])
  RETURNS text AS
$BODY$
	cls = as.vector(cut(val, breaks))
	return(cls)
$BODY$
  LANGUAGE plr VOLATILE
  COST 100;

-- select r_cut(10, array[0,5,50,77,100]);
