-- EXTRACT THE INITIAL SET OF POLYGONS FROM VENTYX FOR THE UTILITIES PULLED FROM URDB
set role 'urdb_rates-writers';
DROP tABLE IF EXISTS urdb_rates.ventyx_electric_service_territories_w_vs_rates_20141202;
CREATE TABLE urdb_rates.ventyx_electric_service_territories_w_vs_rates_20141202 as
with b AS
(
	select distinct(ventyx_company_id_2014) as company_id
	FROM urdb_rates.urdb3_verified_and_singular_ur_names_20141202
)
SELECT a.*
FROM ventyx.electric_service_territories_20130422 a
INNER JOIN b
ON b.company_id = a.company_id::text;

-- fix one known error in the data: city of san francisco should be part of PGE
INSERT INTO urdb_rates.ventyx_electric_service_territories_w_vs_rates_20141202
with a as
(
	SELECT a.gid, a.company_na, a.company_ty, a.hold_co_na, a.state, a.city, 
	a.website, a.plan_ar_na, a.ctrl_ar_na, a.member_nam, a.overlap, 
	a.area_sq_mi, a.location_c, a.source, a.company_id, a.hold_co_id, 
	a.plan_ar_id, a.ctrl_ar_id, a.member_id, a.pop_2000, a.number_of_,
	a.median_hou, a.household_, a.per_capita, a.layer_id, a.rec_id, 
	a.tot_res_cu, a.tot_ind_cu, a.tot_comm_c, a.tot_cust, a.tot_cust_r, a.color_code
	from ventyx.electric_service_territories_20130422 a
	where (a.company_na = 'Pacific Gas & Electric Co')
	limit 1
),
b as 
(
	SELECT the_geom_4326, the_geom_96703
	from ventyx.electric_service_territories_20130422
	where (company_na = 'City & County of San Francisco')
)
select *
FROM a
cross join b;
-- check results in Q
------------------------------------------------------------------------


------------------------------------------------------------------------
-- LOAD CA CLIMATE ZONES TO POSTGES USING shp2pgsql
-- from S:\mgleason\DG_Wind\Data\Source_Data\California_Energy\ca_climate_zones.shp
ALTER TABLE urdb_rates.ca_climate_zones_20141202
ADD COLUMN climate_zone character varying(2);

UPDATE urdb_rates.ca_climate_zones_20141202
SET climate_zone  = substr(name,strpos(name,'zn')+2,2);

-- drop the rest of the columnms (they dont contain anything useful)
ALTER TABLE urdb_rates.ca_climate_zones_20141202
drop column gid,
DROP COLUMN name,
DROP COLUMN descriptio,
DROP COLUMN "timestamp",
DROP COLUMN begin,
DROP COLUMN "end",
DROP COLUMN altitudemo,
DROP COLUMN tessellate,
DROP COLUMN extrude,
DROP COLUMN visibility,
DROP COLUMN draworder,
DROP COLUMN icon;

-- check out the final table
select *
FROM urdb_rates.ca_climate_zones_20141202;

-- add primary key
ALTER TABLE urdb_rates.ca_climate_zones_20141202
add primary key (climate_zone);
------------------------------------------------------------------------


------------------------------------------------------------------------
-- now update the major service territories in CA to account for these subdivision
-- step 1:  check the verified rates for which utility names this applies to
with a as
(
	select utility_name, state_code, urdb_rate_id
	FROM urdb_rates.urdb3_verified_rates_lookup_20141202
	where state_code like '%CA%'
	and state_code <> 'CA'
)
select a.*, b.rateurl
FROM urdb_rates.urdb3_verified_rates_sam_data_20141202 b
INNER JOIN a
ON a.urdb_rate_id = b.urdb_rate_id
order by utility_name;

-- only applies to 
-- Pacific Gas & Electric Co
-- Southern California Edison Co
-- and San Diego Gas & Electric Co

-- for SDGE: 
-- see http://www.sdge.com/baseline-allowance-calculator
-- CA_Coastal = intersection of SDGE with zones 06, 07, and 08
-- CA_Inland = intersection of SDGE with zone 10
-- CA_Mountain = intersection of SDGE with zone 14
-- CA_Desert = intersection of SDGE with zone 15
DROP TABLE IF EXISTS urdb_rates.ventyx_climate_zones_sdge;
CREATE TABLE urdb_rates.ventyx_climate_zones_sdge AS
SELECT a.gid, a.company_na, a.company_ty, a.hold_co_na, a.state, a.city, a.website, 
	a.plan_ar_na, a.ctrl_ar_na, a.member_nam, a.overlap, a.area_sq_mi, a.location_c, 
	a.source, a.company_id, a.hold_co_id, a.plan_ar_id, a.ctrl_ar_id, a.member_id, a.pop_2000, 
	a.number_of_, a.median_hou, a.household_, a.per_capita, a.layer_id, a.rec_id, a.tot_res_cu, 
	a.tot_ind_cu, a.tot_comm_c, a.tot_cust, a.tot_cust_r, a.color_code, 
	ST_Intersection(a.the_geom_4326, b.the_geom_4326) as the_geom_4326,
	case when b.climate_zone in ('06','07','08') THEN 'Coastal'
		when b.climate_zone = '10' THEN 'Inland'
		when b.climate_zone = '14' THEN 'Mountain'
		when b.climate_zone ='15' THEN 'Desert'
	end as sub_territory_name
FROM urdb_rates.ventyx_electric_service_territories_w_vs_rates_20141202 a
INNER JOIN urdb_rates.ca_climate_zones_20141202 b
ON ST_Intersects(a.the_geom_4326, b.the_geom_4326)
where company_na = 'San Diego Gas & Electric Co';

-- check that all areas ahve a sub territory name
select count(*)
FROM urdb_rates.ventyx_climate_zones_sdge
where sub_territory_name is null;
-- look at results in Q and check against source map

-- for SCE:
-- see: http://www.cpuc.ca.gov/maps/scebaseline1009.jpg
-- the codes used and boundaries seem to line up nearly exactly with the official cliamte zones
-- one exception is that a Northern portion of the official climate zones 14 is coded as climate zone 15 by SCE
-- I think we can ignore this consering the map from SCE is out of date, this is not a high pop density area,
-- and the climate is probalby pretty similar to 14 (so rates shouldn't vary a ton)
DROP TABLE IF EXISTS urdb_rates.ventyx_climate_zones_sce;
CREATE TABLE urdb_rates.ventyx_climate_zones_sce AS
SELECT a.gid, a.company_na, a.company_ty, a.hold_co_na, a.state, a.city, a.website, 
	a.plan_ar_na, a.ctrl_ar_na, a.member_nam, a.overlap, a.area_sq_mi, a.location_c, 
	a.source, a.company_id, a.hold_co_id, a.plan_ar_id, a.ctrl_ar_id, a.member_id, a.pop_2000, 
	a.number_of_, a.median_hou, a.household_, a.per_capita, a.layer_id, a.rec_id, a.tot_res_cu, 
	a.tot_ind_cu, a.tot_comm_c, a.tot_cust, a.tot_cust_r, a.color_code, 
	ST_Intersection(a.the_geom_4326, b.the_geom_4326) as the_geom_4326,
	b.climate_zone::integer as sub_territory_name
FROM urdb_rates.ventyx_electric_service_territories_w_vs_rates_20141202 a
INNER JOIN urdb_rates.ca_climate_zones_20141202 b
ON ST_Intersects(a.the_geom_4326, b.the_geom_4326)
where company_na = 'Southern California Edison Co';

-- check that all areas ahve a sub territory name
select count(*)
FROM urdb_rates.ventyx_climate_zones_sce
where sub_territory_name is null;
-- look at results in Q


-- for PGE:
-- see http://www.pge.com/baseline/#
-- http://www.pge.com/nots/rates/PGECZ_90Rev.pdf
-- this one is really wonky and doesnt line up very well
-- but PGE publishes a zipcode to baselien territory lookup table that we can use instead:
-- http://www.pge.com/tariffs/RESZIPS.XLS

-- load the zip to baseline lookup table
DROP TABLE IF EXISTS urdb_rates.pge_zip_to_baseline;
CREATE TABLE urdb_rates.pge_zip_to_baseline 
(
	zipcode character varying(5),
	baseline_territory text,
	service_agreement_count integer,
	percentage numeric,
	notes text
);

set role 'server-superusers';
COPY urdb_rates.pge_zip_to_baseline FROM '/srv/home/mgleason/data/dg_wind/pge_zip_to_baseline_territory.csv' 
with csv header;
SEt role 'urdb_rates-writers';

-- manually add a few more to ensure full coverage of the pge territory
-- note: these are based on visual inspection and best guesses at the correct territory for each of the added zips
INSErT INTO urdb_rates.pge_zip_to_baseline (baseline_territory, zipcode)
VALUES 
('Y','96130'),
('Y','96119'),
('Y','96122'),
('Y','96103'),
('Y','96124'),
('Y','96126'),
('Z','96161'),
('P','96146'),
('P','96141'),
('P','96142'),
('Z','96150'),
('Z','96155'),
('Y','96120'),
('Y','95646'),
('Y','95373'),
('R','93271'),
('R','93262'),
('R','93271'),
('W','93222'),
('W','93225'),
('W','93536'),
('W','93518'),
('W','93215'),
('X','94128'),
('X','94592');

-- dissolve the zipcodes into single polygons for each territory
DROP TABLE IF EXISTS urdb_rates.pge_zip_to_baseline_geoms;
CREATE TABLE urdb_rates.pge_zip_to_baseline_geoms as
with a as
(
	-- the lookup table indicates some zipcodes cross territories
	-- for our purposes, it will be good enough to simply pick the 
	-- majority territory for each zipcode
	select distinct on (zipcode) zipcode, baseline_territory
	FROM urdb_rates.pge_zip_to_baseline a
	order by zipcode, percentage desc
)
	SELECT a.baseline_territory, (ST_Dump(ST_Union(b.the_geom_4326))).geom as the_geom_4326
	FROM a
	inner JOIN shapes.zip_polys_20141005 b
	ON a.zipcode = b.zip
	GROUP BY a.baseline_territory;

-- intersect these with the PGE boundaries from ventyx
DROP TABLE IF EXISTS urdb_rates.ventyx_climate_zones_pge;
CREATE TABLE urdb_rates.ventyx_climate_zones_pge AS
SELECT a.gid, a.company_na, a.company_ty, a.hold_co_na, a.state, a.city, a.website, 
	a.plan_ar_na, a.ctrl_ar_na, a.member_nam, a.overlap, a.area_sq_mi, a.location_c, 
	a.source, a.company_id, a.hold_co_id, a.plan_ar_id, a.ctrl_ar_id, a.member_id, a.pop_2000, 
	a.number_of_, a.median_hou, a.household_, a.per_capita, a.layer_id, a.rec_id, a.tot_res_cu, 
	a.tot_ind_cu, a.tot_comm_c, a.tot_cust, a.tot_cust_r, a.color_code, 
	ST_Intersection(ST_MakeValid(a.the_geom_4326), ST_MakeValid(b.the_geom_4326), 'POLYGON') as the_geom_4326,
	b.baseline_territory as sub_territory_name
FROM urdb_rates.ventyx_electric_service_territories_w_vs_rates_20141202 a
INNER JOIN urdb_rates.pge_zip_to_baseline_geoms b
ON ST_Intersects(a.the_geom_4326, b.the_geom_4326)
where a.company_na = 'Pacific Gas & Electric Co';

-- check that all areas ahve a sub territory name
select count(*)
FROM urdb_rates.ventyx_climate_zones_pge
where sub_territory_name is null;
-- look at results in Q and compare to source map

-- add the 96703 geoms to each of these
ALTER TABLE  urdb_rates.ventyx_climate_zones_sce
ADD column the_geom_96703 geometry;

UPDATE urdb_rates.ventyx_climate_zones_sce
SET the_geom_96703 = ST_Transform(the_geom_4326, 96703);
--
ALTER TABLE  urdb_rates.ventyx_climate_zones_sdge
ADD column the_geom_96703 geometry;

UPDATE urdb_rates.ventyx_climate_zones_sdge
SET the_geom_96703 = ST_Transform(the_geom_4326, 96703);
--
ALTER TABLE  urdb_rates.ventyx_climate_zones_pge
ADD column the_geom_96703 geometry;

UPDATE urdb_rates.ventyx_climate_zones_pge
SET the_geom_96703 = ST_Transform(the_geom_4326, 96703);

-- add the subterritories for the three utility districts back to the main table
-- (leave the original polygons too because some rates for these territories are not broken down by climate zone)
ALTER TABLE urdb_rates.ventyx_electric_service_territories_w_vs_rates_20141202
ADD column sub_territory_name text;

INSERT INTO urdb_rates.ventyx_electric_service_territories_w_vs_rates_20141202
(gid, company_na, company_ty, hold_co_na, state, city, website, 
       plan_ar_na, ctrl_ar_na, member_nam, overlap, area_sq_mi, location_c, 
       source, company_id, hold_co_id, plan_ar_id, ctrl_ar_id, member_id, 
       pop_2000, number_of_, median_hou, household_, per_capita, layer_id, 
       rec_id, tot_res_cu, tot_ind_cu, tot_comm_c, tot_cust, tot_cust_r, 
       color_code, the_geom_4326, the_geom_96703, sub_territory_name)
SELECT gid, company_na, company_ty, hold_co_na, state, city, website, 
       plan_ar_na, ctrl_ar_na, member_nam, overlap, area_sq_mi, location_c, 
       source, company_id, hold_co_id, plan_ar_id, ctrl_ar_id, member_id, 
       pop_2000, number_of_, median_hou, household_, per_capita, layer_id, 
       rec_id, tot_res_cu, tot_ind_cu, tot_comm_c, tot_cust, tot_cust_r, 
       color_code, the_geom_4326, the_geom_96703, sub_territory_name
FROM urdb_rates.ventyx_climate_zones_sdge;

INSERT INTO urdb_rates.ventyx_electric_service_territories_w_vs_rates_20141202
(gid, company_na, company_ty, hold_co_na, state, city, website, 
       plan_ar_na, ctrl_ar_na, member_nam, overlap, area_sq_mi, location_c, 
       source, company_id, hold_co_id, plan_ar_id, ctrl_ar_id, member_id, 
       pop_2000, number_of_, median_hou, household_, per_capita, layer_id, 
       rec_id, tot_res_cu, tot_ind_cu, tot_comm_c, tot_cust, tot_cust_r, 
       color_code, the_geom_4326, the_geom_96703, sub_territory_name)
SELECT gid, company_na, company_ty, hold_co_na, state, city, website, 
       plan_ar_na, ctrl_ar_na, member_nam, overlap, area_sq_mi, location_c, 
       source, company_id, hold_co_id, plan_ar_id, ctrl_ar_id, member_id, 
       pop_2000, number_of_, median_hou, household_, per_capita, layer_id, 
       rec_id, tot_res_cu, tot_ind_cu, tot_comm_c, tot_cust, tot_cust_r, 
       color_code, the_geom_4326, the_geom_96703, sub_territory_name
FROM urdb_rates.ventyx_climate_zones_pge;

INSERT INTO urdb_rates.ventyx_electric_service_territories_w_vs_rates_20141202
(gid, company_na, company_ty, hold_co_na, state, city, website, 
       plan_ar_na, ctrl_ar_na, member_nam, overlap, area_sq_mi, location_c, 
       source, company_id, hold_co_id, plan_ar_id, ctrl_ar_id, member_id, 
       pop_2000, number_of_, median_hou, household_, per_capita, layer_id, 
       rec_id, tot_res_cu, tot_ind_cu, tot_comm_c, tot_cust, tot_cust_r, 
       color_code, the_geom_4326, the_geom_96703, sub_territory_name)
SELECT gid, company_na, company_ty, hold_co_na, state, city, website, 
       plan_ar_na, ctrl_ar_na, member_nam, overlap, area_sq_mi, location_c, 
       source, company_id, hold_co_id, plan_ar_id, ctrl_ar_id, member_id, 
       pop_2000, number_of_, median_hou, household_, per_capita, layer_id, 
       rec_id, tot_res_cu, tot_ind_cu, tot_comm_c, tot_cust, tot_cust_r, 
       color_code, the_geom_4326, the_geom_96703, sub_territory_name::text
FROM urdb_rates.ventyx_climate_zones_sce;

-- add a sub territory name of "Not Applicable" for the rest (need to do this to enable joins)
UPDATE urdb_rates.ventyx_electric_service_territories_w_vs_rates_20141202
SET sub_territory_name = 'Not Applicable'
where sub_territory_name is null;

-- add indices to the company id and sub territory name columns
CREATE INDEX ventyx_electric_service_territories_w_vs_rates_20141202_company_id_btree 
ON urdb_rates.ventyx_electric_service_territories_w_vs_rates_20141202
using btree(company_id);

CREATE INDEX ventyx_electric_service_territories_w_vs_rates_20141202_sub_btree 
ON urdb_rates.ventyx_electric_service_territories_w_vs_rates_20141202
using btree(sub_territory_name);
-- manual edits to the geoms should now be complete


------------------------------------------------------------------------
-- next step is to update the verified lookup table to give the utility sub territory
ALTER TABLE urdb_rates.urdb3_verified_rates_lookup_20141202
ADD COLUMN sub_territory_name text;

UPDATE urdb_rates.urdb3_verified_rates_lookup_20141202
SET sub_territory_name = substr(state_code,4,length(state_code)-3)
where state_code like '%CA%'
and state_code <> 'CA';
-- affected 31 rows

-- add a sub territory name of "Not Applicable" for the rest (need to do this to enable joins)
UPDATE urdb_rates.urdb3_verified_rates_lookup_20141202
SET sub_territory_name = 'Not Applicable'
where sub_territory_name is null;

SELECT distinct(sub_territory_name)
FROM urdb_rates.urdb3_verified_rates_lookup_20141202;

-- create an index on the sub terri tory name
CREATE INDEX urdb3_verified_rates_lookup_20141202_sub_btree 
ON urdb_rates.urdb3_verified_rates_lookup_20141202
using btree(sub_territory_name);

------------------------------------------------------------------------
-- transfer this information over to the verified sam_data table
ALTER TABLE urdb_rates.urdb3_verified_rates_sam_data_20141202
ADD COLUMN sub_territory_name text;

UPDATE  urdb_rates.urdb3_verified_rates_sam_data_20141202 a
SET sub_territory_name = b.sub_territory_name
FROM urdb_rates.urdb3_verified_rates_lookup_20141202 b
where a.urdb_rate_id = b.urdb_rate_id;

select distinct(sub_territory_name)
FROM urdb_rates.urdb3_verified_rates_sam_data_20141202;

-- add indices
CREATE INDEX urdb3_verified_rates_sam_data_20141202_ur_name_btree 
ON urdb_rates.urdb3_verified_rates_sam_data_20141202
using btree(ur_name);

CREATE INDEX urdb3_verified_rates_sam_data_20141202_sub_btree 
ON urdb_rates.urdb3_verified_rates_sam_data_20141202
using btree(sub_territory_name);
------------------------------------------------------------------------
-- also need to add sub territory name to singular rates lookup table (all will be Not Applicable) -- need to do this to simplify joins later
ALTER TABLE urdb_rates.urdb3_singular_rates_lookup_20141202
ADD COLUMN sub_territory_name text;

UPDATE urdb_rates.urdb3_singular_rates_lookup_20141202
SET sub_territory_name = 'Not Applicable';

-- create an index on the sub terri tory name
CREATE INDEX urdb3_singular_rates_lookup_20141202_sub_tree
ON urdb_rates.urdb3_singular_rates_lookup_20141202
using btree(sub_territory_name);

------------------------------------------------------------------------
-- transfer this information over to the singular sam_data table
ALTER TABLE urdb_rates.urdb3_singular_rates_sam_data_20141202
ADD COLUMN sub_territory_name text;

UPDATE  urdb_rates.urdb3_singular_rates_sam_data_20141202 a
SET sub_territory_name = 'Not Applicable';

select distinct(sub_territory_name)
FROM urdb_rates.urdb3_singular_rates_sam_data_20141202;

-- add indices
CREATE INDEX urdb3_singular_rates_sam_data_20141202_ur_name_btree 
ON urdb_rates.urdb3_singular_rates_sam_data_20141202
using btree(ur_name);

CREATE INDEX urdb3_singular_rates_sam_data_20141202_sub_btree 
ON urdb_rates.urdb3_singular_rates_sam_data_20141202
using btree(sub_territory_name);

------------------------------------------------------------------------
-- test a join from the ratesto the geoms
-- verified
SELECT a.*, b.ventyx_company_id_2014, c.*
FROM urdb_rates.urdb3_verified_rates_sam_data_20141202 a
LEFT JOIN urdb_rates.urdb3_verified_and_singular_ur_names_20141202 b
ON a.ur_name = b.ur_name
left join urdb_rates.ventyx_electric_service_territories_w_vs_rates_20141202 c
ON b.ventyx_company_id_2014 = c.company_id::text
and a.sub_territory_name = c.sub_territory_name
where c.sub_territory_name is null;
-- none are missing

--singular
SELECT a.*, b.ventyx_company_id_2014, c.*
FROM urdb_rates.urdb3_singular_rates_sam_data_20141202 a
LEFT JOIN urdb_rates.urdb3_verified_and_singular_ur_names_20141202 b
ON a.ur_name = b.ur_name
left join urdb_rates.ventyx_electric_service_territories_w_vs_rates_20141202 c
ON b.ventyx_company_id_2014 = c.company_id::text
and a.sub_territory_name = c.sub_territory_name
where c.sub_territory_name is null;
-- none are missing

------------------------------------------------------------------------
-- add company type general for consistency with the way in which customer locations are attributed
ALTER TABLE urdb_rates.ventyx_electric_service_territories_w_vs_rates_20141202
ADD COLUMN company_type_general text;

UPDATE urdb_rates.ventyx_electric_service_territories_w_vs_rates_20141202
SET company_type_general =
	CASE WHEN company_ty in ('IOU','IO') THEN 'IOU'
	     when company_ty in ('G&TCoop','Coop','DistCoop') then 'Coop'
	     WHEN company_ty in ('Private','PSubdiv','Federal','Unknown') THEN 'All Other'
	     WHEN company_ty in ('Muni','State') THEN 'Muni'
	END;

-- add an index
CREATE INDEX ventyx_electric_service_territories_w_vs_rates_20141202_ct_btree
ON urdb_rates.ventyx_electric_service_territories_w_vs_rates_20141202
using btree(company_type_general);

select distinct(company_type_general)
FROM urdb_rates.ventyx_electric_service_territories_w_vs_rates_20141202;


-- add a new gid column as the primary key
ALTER TABLE urdb_rates.ventyx_electric_service_territories_w_vs_rates_20141202
DROP COLUMN gid;

ALTER TABLE urdb_rates.ventyx_electric_service_territories_w_vs_rates_20141202
ADD COLUMN gid serial primary key;
