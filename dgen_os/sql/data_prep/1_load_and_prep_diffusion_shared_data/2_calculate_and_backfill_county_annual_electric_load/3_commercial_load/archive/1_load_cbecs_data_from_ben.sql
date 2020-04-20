-- load fac_type to naics crosswalk table (this is for hsip 2012 navteq points) 
-- DROP TABLE IF EXISTS dg_wind.fac_type_naics_crosswalk;
-- CREATE TABLE dg_wind.fac_type_naics_crosswalk (
-- 	feature text,
-- 	query text,
-- 	fac_type character varying(4),
-- 	naics_6 character varying(6));
-- 
-- SET ROLE 'server-superusers';
-- SET client_encoding = 'LATIN1';
-- COPY dg_wind.fac_type_naics_crosswalk FROM '/srv/home/mgleason/data/dg_wind/cbecs/FAC_TYPE_CROSSWALK.csv' with csv header;
-- SET client_encoding = 'UNICODE';
-- RESET ROLE;

-- load naics to pba crosswalk (pba = primary building activity)
-- DROP TABLE IF EXISTS dg_wind.naics_pba_crosswalk;
-- CREATE TABLE dg_wind.naics_pba_crosswalk (
-- 	naics_3 character varying(3),
-- 	naics_desc text,
-- 	pba_code integer,
-- 	pba_desc text);
-- 
-- SET ROLE 'server-superusers';
-- COPY dg_wind.naics_pba_crosswalk FROM '/srv/home/mgleason/data/dg_wind/cbecs/NAICStoPBA Crosswalk.csv' with csv header;
-- RESET ROLE;

-- CBECs consumption data by census region and pba
-- built using the  http://www.eia.gov/consumption/commercial/data/2003/csv/FILE15.csv B. Sigrin
DROP TABLE IF EXISTS dg_wind.cbecs_elec_consumption_by_census_region_and_pba;
CREATE TABLE dg_wind.cbecs_elec_consumption_by_census_region_and_pba (
	building_type text,
	northeast_elec_load_billion_kwh numeric,
	midwest_elec_load_billion_kwh numeric,
	south_elec_load_billion_kwh numeric,
	west_elec_load_billion_kwh numeric);
	
SET ROLE 'server-superusers';
COPY dg_wind.cbecs_elec_consumption_by_census_region_and_pba FROM '/srv/home/mgleason/data/dg_wind/cbecs/CBECS_PBA_by_Region_v2.csv' with csv header;
RESET ROLE;


-- FAC_TYPE to PBA Crosswalk -- created by M Gleason and B Sigrin
DROP TABLE IF EXISTS dg_wind.navteq_fac_type_to_cbecs_pba;
CREATE TABLE dg_wind.navteq_fac_type_to_cbecs_pba (
	feature text,
	query_filter text,
	fac_type numeric,
	naics_code character varying(6),
	building_type text);
	
SET ROLE 'server-superusers';
COPY dg_wind.navteq_fac_type_to_cbecs_pba FROM '/srv/home/mgleason/data/dg_wind/cbecs/FAC_TYPE_CROSSWALK_to_PBA_mg.csv' with csv header;
RESET ROLE;

