set role 'diffusion-writers';

DROP TABLE IF EXISTS diffusion_shared.cdms_bldg_types_to_typehuq_lkup CASCADE;
CREATE TABLE diffusion_shared.cdms_bldg_types_to_typehuq_lkup
(
	cdms varchar(5),
	cdms_description text,
	typehuq integer,
	typehuq_description text,
	min_tenants integer,
	max_tenants integer
);

\COPY diffusion_shared.cdms_bldg_types_to_typehuq_lkup FROM '/Volumes/Staff/mgleason/dGeo/Data/Source_Data/Thermal_Demand_kmccabe/simplified/cdms_to_typehuq.csv' with csv header;

-- check data
select *
FROM diffusion_shared.cdms_bldg_types_to_typehuq_lkup;



-- these are the types from the cdms data dictinoary (https://www.fema.gov/media-library-data/20130726-1819-25045-8574/hzmh2_1_cdms_data_dictionary.pdf)
-- that overlap the loookup table
-- RES1I RES1 - Single Family Dwelling
-- RES2I RES2 - Manuf Housing
-- RES3AI RES3A - Duplex
-- RES3BI RES3B - Triplex / Quads
-- RES3CI RES3C - Multi-dwellings (5 to 9
-- RES3DI RES3D - Multi-dwellings (10 to 19
-- RES3EI RES3E - Multi-dwellings (20 to 49
-- RES3FI RES3F - Multi-dwellings (50+ units)


-- CREATE INDICES
CREATE INDEX cdms_bldg_types_to_typehuq_lkup_btree_cdms
ON diffusion_shared.cdms_bldg_types_to_typehuq_lkup
USING BTREE(cdms);

CREATE INDEX cdms_bldg_types_to_typehuq_lkup_btree_pbaplus
ON diffusion_shared.cdms_bldg_types_to_typehuq_lkup
USING BTREE(typehuq);

CREATE INDEX cdms_bldg_types_to_typehuq_lkup_btree_min_tenants
ON diffusion_shared.cdms_bldg_types_to_typehuq_lkup
USING BTREE(min_tenants);

CREATE INDEX cdms_bldg_types_to_typehuq_lkup_btree_max_tenants
ON diffusion_shared.cdms_bldg_types_to_typehuq_lkup
USING BTREE(max_tenants);

-- convert cdms to lower case
UPDATE diffusion_shared.cdms_bldg_types_to_typehuq_lkup
set cdms = lower(cdms);
-- 9 rows