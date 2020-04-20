SET ROLE 'server-superusers';
DROP FUNCTION IF EXISTS diffusion_shared.r_array_max(numarr numeric[]);
CREATE OR REPLACE FUNCTION diffusion_shared.r_array_max(numarr numeric[])
  RETURNS NUMERIC AS
$BODY$
	m = max(numarr, na.rm = T)
	return(m)
$BODY$
  LANGUAGE plr VOLATILE
  COST 100;





