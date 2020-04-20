DROP FUNCTION IF EXISTS diffusion_shared.drop_results_schemas(TEXT[]);
CREATE OR REPLACE FUNCTION diffusion_shared.drop_results_schemas(exception_array text[] DEFAULT ARRAY[]::TEXT[])
  RETURNS SETOF text AS
$BODY$
DECLARE 
	results_schema text;
  BEGIN

  FOR results_schema in 
	select schema_name::TEXT
	from information_schema.schemata
	where schema_name like 'diffusion_results_%'
	and NOT(array[schema_name::text] <@ exception_array)
	order by schema_name asc
  LOOP
	RETURN NEXT 'DROP SCHEMA IF EXISTS ' || results_schema || ' CASCADE;';
  END loop;
  RETURn;
  
END
$BODY$
  LANGUAGE plpgsql STABLE
  COST 100
  ROWS 1000;



select diffusion_shared.drop_results_schemas();