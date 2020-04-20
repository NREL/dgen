
DROP FUNCTION IF EXISTS diffusion_shared.find_ec_tier_errors(j json, max_ub numeric);
SET ROLE 'server-superusers';
CREATE OR REPLACE FUNCTION diffusion_shared.find_ec_tier_errors(j json, max_ub numeric)
  RETURNS boolean AS
  $BODY$

	import json
	d = json.loads(j)
	ec_ub_keys = [k for k in d.keys() if k.startswith('ur_ec') and k.endswith('_ub')] 

	vals = []
	for k in ec_ub_keys:
	    val = d[k]
	    if val <> 1e+38:
		vals.append(val)
	if len(vals) == 0:
		err = False
	else:
		if max(vals) < max_ub:
			err = True
		else:
			err = False
	return err

  $BODY$
  LANGUAGE plpythonu stable
  COST 100;
RESET ROLE;




