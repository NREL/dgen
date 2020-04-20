-- FAC_TYPE to PBA Crosswalk -- created by M Gleason and B Sigrin
DROP TABLE IF EXISTS dg_wind.navteq_fac_type_to_cbecs_pba;
CREATE TABLE dg_wind.navteq_fac_type_to_cbecs_pba (
	feature text,
	query_filter text,
	fac_type numeric,
	naics_code character varying(6),
	building_type text);
	
SET ROLE 'server-superusers';
COPY dg_wind.navteq_fac_type_to_cbecs_pba FROM '/srv/home/mgleason/data/dg_wind/cbecs/FAC_TYPE_CROSSWALK_to_PBA_final.csv' with csv header;
RESET ROLE;

-- NAICS to PBA Crosswalk -- created by B Sigrin
DROP TABLE IF EXISTS hsip_2012.naics_2_digit_lookup;
cREATE TABLE hsip_2012.naics_2_digit_lookup (
	naicscode_2 character varying(2),
	sector_description text);

SET ROLE 'server-superusers';
COPY hsip_2012.naics_2_digit_lookup FROM '/srv/home/mgleason/data/dg_wind/cbecs/2012_naics_2digit_lookup.csv' with csv header;
RESET ROLE;

