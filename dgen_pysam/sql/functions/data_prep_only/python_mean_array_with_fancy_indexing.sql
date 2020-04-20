set role 'server-superusers';

DROP FUNCTION IF EXISTS public.py_mean_array(numeric[], integer[]);

CREATE OR REPLACE FUNCTION public.py_mean_array(l numeric[], i integer[] default array[]::integer[])
  RETURNS numeric AS
$BODY$

    import numpy as np

    a = np.array(l)

    if len(i) > 0:
	result = np.mean(a[i])
    else:
	result = np.mean(a)
	
    return result
    
$BODY$
  LANGUAGE plpythonu STABLE
  COST 100;



select py_mean_array(array[1,2,3,4,5,6,7], array[0,6]);