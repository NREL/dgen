SET ROLE 'server-superusers';
DROP FUNCTION IF EXISTS diffusion_shared.r_rnorm_rlnorm(numeric, numeric, text, integer);
CREATE OR REPLACE FUNCTION diffusion_shared.r_rnorm_rlnorm(mean numeric, std numeric, dist_type text, seed integer default 1)
RETURNS numeric AS 
$BODY$
	# Returns randomly generated lifetime age
	set.seed(seed)
	if (dist_type == 'normal'){
		p = rnorm(1, mean, std)
	} else if (dist_type == 'lognormal'){
		p = rlnorm(1, mean, std)
	}
	return(p)
$BODY$
LANGUAGE 'plr'
COST 100;


DROP FUNCTION IF EXISTS diffusion_shared.r_rnorm_rlnorm(numeric, numeric, text, BIGINT);
CREATE OR REPLACE FUNCTION diffusion_shared.r_rnorm_rlnorm(mean numeric, std numeric, dist_type text, seed BIGINT default 1)
RETURNS numeric AS 
$BODY$
	# Returns randomly generated lifetime age
	set.seed(seed)
	if (dist_type == 'normal'){
		p = rnorm(1, mean, std)
	} else if (dist_type == 'lognormal'){
		p = rlnorm(1, mean, std)
	}
	return(p)
$BODY$
LANGUAGE 'plr'
COST 100;


select diffusion_shared.r_rnorm_rlnorm(2.43, 0.17, 'lognormal', 1);