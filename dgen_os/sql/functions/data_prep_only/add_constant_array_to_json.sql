SET ROLE 'server-superusers';
DROP FUNCTION IF EXISTS diffusion_shared.add_constant_array(j json, k text, c integer, rows integer, cols integer);
CREATE OR REPLACE FUNCTION diffusion_shared.add_constant_array(j json, k text, c integer, rows integer, cols integer)
  RETURNS json AS
  $BODY$

	import json
	d = json.loads(j)
	a = [[c]*cols]*rows
	d[k] = a
	s = json.dumps(d)

	return s
	

  $BODY$
  LANGUAGE plpythonu stable
  COST 100;
RESET ROLE;




select add_constant_array('{}'::json, 'val', 1, 12, 24)
