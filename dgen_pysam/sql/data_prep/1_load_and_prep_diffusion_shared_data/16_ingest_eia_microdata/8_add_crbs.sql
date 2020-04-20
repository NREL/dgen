-- RECS
-- add the "crb_model" to this table (should be "reference" for all single family, owner occ homes and "midrise_apartment" for all others)
ALTER TABLE diffusion_shared.eia_microdata_recs_2009_expanded_bldgs
ADD COLUMN crb_model text;

-- check unique combos of typehuq and single_family_res
select distinct single_family_res, typehuq
from diffusion_shared.eia_microdata_recs_2009_expanded_bldgs;
-- typehuq 4 and 5 are the only multifamily types -- this makes sense given they represent:
-- 4: Apartment in Building with 2 - 4 Units
-- 5: Apartment in Building with 5+ Units

UPDATE diffusion_shared.eia_microdata_recs_2009_expanded_bldgs a
SET crb_model = CASE WHEN typehuq in (1, 2, 3) THEN 'reference' -- mobile home, single family detached, single family attached
		     WHEN typehuq in (4, 5) THEN 'midrise_apartment'-- apartment in bldg with 2-4 units, apt in bldg with 5+ units
		END;
-- 12083
-- check for nulls
select count(*)
FROM diffusion_shared.eia_microdata_recs_2009_expanded_bldgs
where crb_model is null;
-- 0 all set
------------------------------------------------------------------------------------------

-- CBECS
-- create a simple lookup table for all non-vacant
-- cbecs buildings that gives the commercial reference building model
DROP TABLE IF EXISTS diffusion_data_shared.cbecs_expanded_2003_crb_lookup;
CREATE TABLE diffusion_data_shared.cbecs_expanded_2003_crb_lookup AS
with a AS
(
	SELECT a.building_id, a.totsqft, b.*
	FROM diffusion_shared.eia_microdata_cbecs_2003_expanded a
	LEFT JOIN diffusion_data_shared.cbecs_2003_pba_to_eplus_crbs b
	ON a.pba = b.pba8
	and a.pbaplus = b.pbaplus8
)
select building_id, crb_model
FROM a
where (sqft_min is null and sqft_max is null)
or (totsqft >= sqft_min and totsqft < sqft_max);
-- 5081 rows


-- does that match the count of buldings?
select count(*)
FROM diffusion_shared.eia_microdata_cbecs_2003_expanded;
-- yes-- 5081

-- do all buildings have a crb?
SELECT count(*)
FROM diffusion_data_shared.cbecs_expanded_2003_crb_lookup
where crb_model is null;
-- 0 -- yes

-- add this information back into the main table
ALTER TABLE diffusion_shared.eia_microdata_cbecs_2003_expanded
ADD COLUMN crb_model text;

UPDATE diffusion_shared.eia_microdata_cbecs_2003_expanded a
SET crb_model = b.crb_model
FROM diffusion_data_shared.cbecs_expanded_2003_crb_lookup b
where a.building_id = b.building_id;
-- 5081 rows

-- add an index
CREATE INDEX eia_microdata_cbecs_2003_expanded_crb_model_btree
ON diffusion_shared.eia_microdata_cbecs_2003_expanded 
using btree(crb_model);

-- drop the lookup table
DROP TABLE IF EXIStS diffusion_data_shared.cbecs_expanded_2003_crb_lookup;

SELECT count(*)
FROM diffusion_shared.eia_microdata_cbecs_2003_expanded
where crb_model is null;
