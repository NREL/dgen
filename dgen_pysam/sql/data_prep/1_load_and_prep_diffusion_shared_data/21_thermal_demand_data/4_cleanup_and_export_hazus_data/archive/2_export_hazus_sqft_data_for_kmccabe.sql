set role 'dgeo-writers';

DROP VIEW IF EXISTS dgeo.hazus_sf_by_county_and_bldg_type;
CREATE VIEW dgeo.hazus_sf_by_county_and_bldg_type AS
select  state, state_fips, county, county_fips, county_id, 
		res1f as res1,
		res2f as res2,
		res3af as res3a,
		res3bf as res3b,
		res3cf as res3c,
		res3df as res3d,
		res3ef as res3e,
		res3ff as res3f,
		res4f as res4,
		res5f as res5,
		res6f as res6,
		com1f as com1,
		com2f as com2,
		com3f as com3,
		com4f as com4,
		com5f as com5,
		com6f as com6,
		com7f as com7,
		com8f as com8,
		com9f as com9,
		com10f as com10,
		ind1f as ind1,
		ind2f as ind2,
		ind3f as ind3,
		ind4f as ind4,
		ind5f as ind5,
		ind6f as ind6,
		agr1f as agr1,
		rel1f as rel1,
		gov1f as gov1,
		gov2f as gov2,
		edu1f as edu1,
		edu2f as edu2
from hazus.sum_stats_sqfootage_block_county;

\COPY (SELECT * FROM dgeo.hazus_sf_by_county_and_bldg_type) TO '/Volumes/Staff/mgleason/dGeo/Data/Output/cdms_building_sf_by_county_and_bldg_type_2016_03_21.csv' with csv header;

-- drop the view
DROP VIEW IF EXISTS dgeo.hazus_sf_by_county_and_bldg_type;