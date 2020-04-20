
DROP FUNCTION IF EXISTS diffusion_shared.get_key(j json, k text);
SET ROLE 'server-superusers';
CREATE OR REPLACE FUNCTION diffusion_shared.get_key(j json, k text)
  RETURNS text AS
  $BODY$

	import json
	d = json.loads(j)
	if k in d.keys():
		v = d[k]
	else:
		plpy.warning("KeyError: Key '%s' does not exist in json" % k) 
		v = None

	return v
	

  $BODY$
  LANGUAGE plpythonu stable
  COST 100;
