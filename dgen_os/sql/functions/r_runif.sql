SET ROLE 'server-superusers';
DROP FUNCTION IF EXISTS diffusion_shared.r_runif(numeric, numeric, integer, integer);
CREATE OR REPLACE FUNCTION diffusion_shared.r_runif(min numeric, max numeric, sample_size integer, seed integer default 1)
RETURNS numeric AS 
$BODY$
	set.seed(seed)
	x = runif(sample_size, min, max)
	return(x)
$BODY$
LANGUAGE 'plr'
COST 100;

DROP FUNCTION IF EXISTS diffusion_shared.r_runif(numeric, numeric, integer, BIGINT);
CREATE OR REPLACE FUNCTION diffusion_shared.r_runif(min numeric, max numeric, sample_size integer, seed BIGINT default 1)
RETURNS numeric AS 
$BODY$
	set.seed(seed)
	x = runif(sample_size, min, max)
	return(x)
$BODY$
LANGUAGE 'plr'
COST 100;

select diffusion_shared.r_runif(10, 20, 1, 2::BIGINT);