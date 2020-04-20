
DROP FUNCTION IF EXISTS diffusion_shared.remove_key(j json, k text);
SET ROLE 'server-superusers';
CREATE OR REPLACE FUNCTION diffusion_shared.remove_key(j json, k text)
  RETURNS json AS
  $BODY$

	import json
	d = json.loads(j)
	if k in d.keys():
		del d[k]
	else:
		plpy.warning("KeyError: Key '%s' does not exist in json" % k) 
	s = json.dumps(d)

	return s
	

  $BODY$
  LANGUAGE plpythonu stable
  COST 100;
RESET ROLE;
