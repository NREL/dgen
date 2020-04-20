
DROP FUNCTION IF EXISTS diffusion_shared.add_key(j json, k text, v integer[]);
SET ROLE 'server-superusers';
CREATE OR REPLACE FUNCTION diffusion_shared.add_key(j json, k text, v integer[])
  RETURNS json AS
  $BODY$

	import json
	d = json.loads(j)
	d[k] = v
	s = json.dumps(d)

	return s
	

  $BODY$
  LANGUAGE plpythonu stable
  COST 100;
RESET ROLE;




