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
COPY dg_wind.cbecs_elec_consumption_by_census_region_and_pba FROM '/srv/home/mgleason/data/dg_wind/cbecs/CBECS_PBA_by_Region_v3.csv' with csv header;
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
COPY dg_wind.navteq_fac_type_to_cbecs_pba FROM '/srv/home/mgleason/data/dg_wind/cbecs/FAC_TYPE_CROSSWALK_to_PBA_final.csv' with csv header;
RESET ROLE;

-- test join between the two
SELECT *
FROM  dg_wind.navteq_fac_type_to_cbecs_pba a
LEFT JOIN dg_wind.cbecs_elec_consumption_by_census_region_and_pba b
ON a.building_type = b.building_type;
