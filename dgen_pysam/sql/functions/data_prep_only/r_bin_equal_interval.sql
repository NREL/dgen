SET ROLE 'server-superusers';
DROP FUNCTION IF EXISTS public.bin_equal_interval(x numeric[], int_size numeric, incl_right boolean);
CREATE OR REPLACE FUNCTION public.bin_equal_interval(x numeric[], int_size numeric, incl_right boolean default false) 
RETURNS text[] AS 
$BODY$
	  #.libPaths("/srv/home/mgleason/R/x86_64-redhat-linux-gnu-library/3.0") # for gispgdb
	  .libPaths("/home/mgleason/R/x86_64-redhat-linux-gnu-library/3.1") # for dnpdb001
	  library(plyr)
	  breaks = seq(0, round_any(max(x, na.rm = T), int_size, f = ceiling), int_size)
	  break_limits = cbind(start = breaks[1:length(breaks)-1],end = breaks[2:length(breaks)])
	  break_labels = paste(break_limits[,1],break_limits[,2], sep = ' - ')
	  bins = cut(x,breaks, labels=break_labels, right = incl_right)
	  return(bins)

$BODY$
LANGUAGE 'plr'
COST 100;


SET ROLE 'server-superusers';
DROP FUNCTION IF EXISTS public.bin_manual_breaks(x numeric, breaks numeric, incl_right boolean);
CREATE OR REPLACE FUNCTION public.bin_manual_breaks(x numeric, breaks numeric[], incl_right boolean default false) 
RETURNS text AS 
$BODY$
	  #.libPaths("/srv/home/mgleason/R/x86_64-redhat-linux-gnu-library/3.0") # for gispgdb
	  .libPaths("/home/mgleason/R/x86_64-redhat-linux-gnu-library/3.1") # for dnpdb001
	  library(plyr)
	  break_limits = cbind(start = breaks[1:length(breaks)-1],end = breaks[2:length(breaks)])
	  break_labels = paste(break_limits[,1],break_limits[,2], sep = ' - ')
	  bins = as.character(cut(x,breaks, labels=break_labels, right = incl_right))
	  return(bins)

$BODY$
LANGUAGE 'plr'
COST 100;


-- SELECT unnest(bin_equal_interval(array_agg(system_size_kw), 10))
-- FROM diffusion_solar.outputs_all
-- 
-- SELECT system_size_kw, bin_manual_breaks(system_size_kw, array[0,5,10,15,20,30,40,50,100,150,round(max(system_size_kw) OVER (PARTITION BY sector),0)])
-- FROM diffusion_solar.outputs_all



