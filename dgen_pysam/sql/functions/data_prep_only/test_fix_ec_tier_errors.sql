
DROP FUNCTION IF EXISTS diffusion_shared.test_fix_ec_tier_errors(j json);
-- SET ROLE 'server-superusers';
CREATE OR REPLACE FUNCTION diffusion_shared.test_fix_ec_tier_errors(j json)
  RETURNS json AS
  $BODY$

	import json
	d = json.loads(j)
	ec_ub_keys = [k for k in d.keys() if k.startswith('ur_ec') and k.endswith('_ub')] 

	d2 = {}
	for k in ec_ub_keys:
		val = d[k]
		if val <> 1e+38:
		    d2[k] = val*30
		else:
		    d2[k] = val

	j2 = json.dumps(d2)
	return j2

  $BODY$
  LANGUAGE plpythonu stable
  COST 100;
RESET ROLE;





