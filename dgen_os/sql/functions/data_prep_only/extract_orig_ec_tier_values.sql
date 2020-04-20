
DROP FUNCTION IF EXISTS diffusion_shared.extract_orig_ec_tier_values(j json);
SET ROLE 'server-superusers';
CREATE OR REPLACE FUNCTION diffusion_shared.extract_orig_ec_tier_values(j json)
  RETURNS json AS
  $BODY$

	import json
	d = json.loads(j)
	ec_ub_keys = [k for k in d.keys() if k.startswith('ur_ec') and k.endswith('_ub')] 

	d2 = {}
	for k in ec_ub_keys:
		val = d[k]
		d2[k] = val

	j2 = json.dumps(d2)
	return j2

  $BODY$
  LANGUAGE plpythonu stable
  COST 100;
RESET ROLE;





