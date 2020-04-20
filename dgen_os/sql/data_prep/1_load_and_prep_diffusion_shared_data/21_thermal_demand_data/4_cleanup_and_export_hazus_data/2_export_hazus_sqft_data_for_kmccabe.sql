set role 'dgeo-writers';

DROP VIEW IF EXISTS dgeo.hazus_sf_by_county_and_bldg_type_updated;
CREATE VIEW dgeo.hazus_sf_by_county_and_bldg_type_updated AS
select a.state, a.state_fips, a.county, a.county_fips, a.county_id,
	b.res1,
	b.res2,
	b.res3a,
	b.res3b,
	b.res3c,
	b.res3d,
	b.res3e,
	b.res3f,
	b.res4,
	b.res5,
	b.res6,
	b.com1,
	b.com2,
	b.com3,
	b.com4,
	b.com5,
	b.com6,
	b.com7,
	b.com8,
	b.com9,
	b.com10,
	b.ind1,
	b.ind2,
	b.ind3,
	b.ind4,
	b.ind5,
	b.ind6,
	b.agr1,
	b.rel1,
	b.gov1,
	b.gov2,
	b.edu1,
	b.edu2
from diffusion_blocks.county_geoms a
LEFT JOIN diffusion_blocks.county_bldg_sqft_by_type b
ON a.county_fips = b.county_fips
and a.state_fips = b.state_fips;

\COPY (SELECT * FROM dgeo.hazus_sf_by_county_and_bldg_type_updated) TO '/Volumes/Staff/mgleason/dGeo/Data/Output/hazus_data_for_kmccabe/cdms_building_sf_by_county_and_bldg_type_2016_04_05.csv' with csv header;

-- drop the view
DROP VIEW IF EXISTS dgeo.hazus_sf_by_county_and_bldg_type_updated;