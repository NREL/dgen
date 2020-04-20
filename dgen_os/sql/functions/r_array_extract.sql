SET ROLE 'server-superusers';
DROP FUNCTION IF EXISTS diffusion_shared.r_array_extract(integer[], text[]);
CREATE OR REPLACE FUNCTION diffusion_shared.r_array_extract(probs integer[], vals text[]) 
RETURNS text[] AS 
$BODY$
	to_extract = probs > 0
	extracted_vals = vals[to_extract]
	return(extracted_vals)
$BODY$
LANGUAGE 'plr'
COST 100;

select diffusion_shared.r_array_extract(array[1,0,5,0], array['book', 'dog', 'dinosaur', 'tree']);

------------------------------------------------------------------------------------------

DROP FUNCTION IF EXISTS diffusion_shared.r_array_extract(INTEGER[], INTEGER[]);
CREATE OR REPLACE FUNCTION diffusion_shared.r_array_extract(probs INTEGER[], vals INTEGER[]) 
RETURNS INTEGER[] AS 
$BODY$
	to_extract = probs > 0
	extracted_vals = vals[to_extract]
	return(extracted_vals)
$BODY$
LANGUAGE 'plr'
COST 100;

select diffusion_shared.r_array_extract(array[1,0,5,0], array[1,0,5,0]);