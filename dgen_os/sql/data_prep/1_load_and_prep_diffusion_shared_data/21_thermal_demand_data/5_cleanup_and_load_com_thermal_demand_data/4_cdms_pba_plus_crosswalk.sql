set role 'diffusion-writers';

DROP TABLE IF EXISTS diffusion_shared.cdms_bldg_types_to_pba_plus_lkup;
CREATE TABLE diffusion_shared.cdms_bldg_types_to_pba_plus_lkup
(
	cdms varchar(5),
	cdms_description text,
	pbaplus integer,
	pbaplus_description text
);

\COPY diffusion_shared.cdms_bldg_types_to_pba_plus_lkup FROM '/Volumes/Staff/mgleason/dGeo/Data/Source_Data/Thermal_Demand_kmccabe/simplified/pba_cdms_crosswalk_kmccabe_2016_03_09.csv' with csv header;

-- check data
select *
FROM diffusion_shared.cdms_bldg_types_to_pba_plus_lkup;

-- make sure all cdms types are covered
select distinct cdms, cdms_description
from diffusion_shared.cdms_bldg_types_to_pba_plus_lkup
order by 1;

-- these are the types from the cdms data dictinoary (https://www.fema.gov/media-library-data/20130726-1819-25045-8574/hzmh2_1_cdms_data_dictionary.pdf)
-- that overlap the loookup table
-- COM10I COM10 - Parking
-- COM1I COM1 - Retail Trade
-- COM2I COM2 - Wholesale Trade
-- COM3I COM3 - Personal and Repair
-- COM4I COM4 - Professional/Technical
-- COM5I COM5 - Banks
-- COM6I COM6 - Hospital
-- COM7I COM7 - Medical Office/Clinic
-- COM8I COM8 - Entertainment &
-- COM9I COM9 - Theaters
-- EDU1I EDU1 - Grade Schools
-- EDU2I EDU2 - Colleges/Universities
-- GOV1I GOV1 - General Services
-- GOV2I GOV2 - Emergency Response
-- REL1I REL1 - Churches and Other Non-
-- RES4I RES4 - Temporary Lodging
-- RES5I RES5 - Institutional Dormitory
-- RES6I RES6 - Nursing Home

-- types not included in lookup table are:
-- AGR1I AGR1 - Agriculture
-- RES1I RES1 - Single Family Dwelling
-- RES2I RES2 - Manuf Housing
-- RES3AI RES3A - Duplex
-- RES3BI RES3B - Triplex / Quads
-- RES3CI RES3C - Multi-dwellings (5 to 9
-- RES3DI RES3D - Multi-dwellings (10 to 19
-- RES3EI RES3E - Multi-dwellings (20 to 49
-- RES3FI RES3F - Multi-dwellings (50+ units)
-- IND1I IND1 - Heavy
-- IND2I IND2 - Light
-- IND3I IND3 - Food/Drugs/Chemicals
-- IND4I IND4 - Metals/Minerals Processing
-- IND5I IND5 - High Technology
-- IND6I IND6 - Construction
-- this makes total sense -- these are industrial, ag, and true residential

-- CREATE INDICES
CREATE INDEX cdms_bldg_types_to_pba_plus_lkup_btree_cdms
ON diffusion_shared.cdms_bldg_types_to_pba_plus_lkup
USING BTREE(cdms);

CREATE INDEX cdms_bldg_types_to_pba_plus_lkup_btree_pbaplus
ON diffusion_shared.cdms_bldg_types_to_pba_plus_lkup
USING BTREE(pbaplus);

-- convert cdms to lower case
UPDATE diffusion_shared.cdms_bldg_types_to_pba_plus_lkup
set cdms = lower(cdms);
-- 57 rows