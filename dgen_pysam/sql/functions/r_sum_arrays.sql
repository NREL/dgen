SET ROLE 'server-superusers';
DROP FUNCTION IF EXISTS diffusion_shared.r_sum_arrays(numarr numeric[][]);
CREATE OR REPLACE FUNCTION diffusion_shared.r_sum_arrays(numarr numeric[][])
  RETURNS NUMERIC[] AS
$BODY$
	sums = colSums(numarr)
	return(sums)
$BODY$
  LANGUAGE plr VOLATILE
  COST 100;

DROP AGGREGATE IF EXISTS diffusion_shared.array_agg_mult(anyarray);
CREATE AGGREGATE diffusion_shared.array_agg_mult (anyarray)  (
    SFUNC     = array_cat
   ,STYPE     = anyarray
   ,INITCOND  = '{}'
);

select diffusion_shared.r_sum_arrays(array[array[1,2,3], array[4,5,6]]);