-- DROP FUNCTION public.r_boxplot_stats(numeric[], character varying(2));
set role 'server-superusers';
CREATE OR REPLACE FUNCTION diffusion_shared.r_boxplot_stats(numarr numeric[], stat character varying(2))
  RETURNS double precision AS
$BODY$
	
	b = boxplot(numarr, plot = F)
	stats = as.numeric(b$stats)
	names(stats) = c('lw', 'lq', 'm', 'uq', 'uw')
	return(stats[stat])

$BODY$
  LANGUAGE plr VOLATILE
  COST 100;
