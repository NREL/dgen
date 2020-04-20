-- DROP FUNCTION public.r_array_multiply(numeric[], numeric);
set role 'server-superusers';
DROP FUNCTION IF EXISTS public.pc_interp_r(t0 numeric, t1 numeric, tx numeric, v0 numeric[], v1 numeric[]);
CREATE OR REPLACE FUNCTION public.pc_interp_r(t0 numeric, t1 numeric, tx numeric, v0 numeric[], v1 numeric[])
  RETURNS numeric[] AS
$BODY$
	  interp_factor = (tx - t0)/(t1 - t0)
	  vx = interp_factor * (v1-v0) + v0
	  return(vx)
$BODY$
  LANGUAGE plr STABLE
  COST 100;


set role 'server-superusers';
DROP FUNCTION IF EXISTS public.pc_interp_py(t0 numeric, t1 numeric, tx numeric, v0 numeric[], v1 numeric[]);
CREATE OR REPLACE FUNCTION public.pc_interp_py(t0 numeric, t1 numeric, tx numeric, v0 numeric[], v1 numeric[])
  RETURNS numeric[] AS
$BODY$
	import numpy as np
	a0 = np.array(v0, dtype = 'float32')
	a1 = np.array(v1, dtype = 'float32')
	interp_factor = (tx - t0)/(t1 - t0)
	vx = interp_factor * (a1-a0) + a0
	return vx
$BODY$
  LANGUAGE plpythonu STABLE
  COST 100;


set role 'server-superusers';
DROP FUNCTION IF EXISTS public.pc_interp_r(t0 numeric, t1 numeric, tx numeric, v0 numeric, v1 numeric);
CREATE OR REPLACE FUNCTION public.pc_interp_r(t0 numeric, t1 numeric, tx numeric, v0 numeric, v1 numeric)
  RETURNS numeric AS
$BODY$
	  interp_factor = (tx - t0)/(t1 - t0)
	  vx = interp_factor * (v1-v0) + v0
	  return(vx)
$BODY$
  LANGUAGE plr STABLE
  COST 100;


DROP FUNCTION IF EXISTS public.pc_interp_py(t0 numeric, t1 numeric, tx numeric, v0 numeric, v1 numeric);
CREATE OR REPLACE FUNCTION public.pc_interp_py(t0 numeric, t1 numeric, tx numeric, v0 numeric, v1 numeric)
  RETURNS numeric AS
$BODY$
	interp_factor = (tx - t0)/(t1 - t0)
	vx = interp_factor * (v1-v0) + v0
	return vx
$BODY$
  LANGUAGE plpythonu STABLE
  COST 100;


select  pc_interp_py(2014, 2018, 2016, 271, 495);
select  pc_interp_r(2014, 2018, 2016, 271, 495);

with a as
(
	select generate_series(1,100)
)
select pc_interp_py(2014, 2018, 2016, array[ 0.,  1.,  2.,  3.,  4.,  5.,  6.,  7.,  8.,  9.], array[ 10.,  11.,  12.,  13.,  14.,  15.,  16.,  17.,  18.,  19.])
from a;


with a as
(
	select generate_series(1,100)
)
select pc_interp_r(2014, 2018, 2016, array[ 0.,  1.,  2.,  3.,  4.,  5.,  6.,  7.,  8.,  9.], array[ 10.,  11.,  12.,  13.,  14.,  15.,  16.,  17.,  18.,  19.])
from a;

with a as
(
	select a.cf as acf, b.cf as bcf
	FROM diffusion_wind.wind_resource_hourly_current_residential_turbine a
	lEFT JOIN diffusion_wind.wind_resource_hourly_residential_near_future_turbine b
	ON a.i = b.i
	and a.j = b.j
	and a.cf_bin = b.cf_bin
	and a.height = b.height
	 limit 1000
)
select --pc_interp_r(2014, 2018, 2016, acf, bcf)::SMALLINT[]--, 
	acf--, bcf
from a;



with a as
(
	select a.cf as acf, b.cf as bcf
	FROM diffusion_wind.wind_resource_hourly_current_residential_turbine a
	lEFT JOIN diffusion_wind.wind_resource_hourly_residential_near_future_turbine b
	ON a.i = b.i
	and a.j = b.j
	and a.cf_bin = b.cf_bin
	and a.height = b.height
	limit 1000
)
select pc_interp_py(2014, 2018, 2016, acf, bcf)
from a;