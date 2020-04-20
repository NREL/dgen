-- load the OPENEI table "Utility Companies and Aliases with EIA Utility ID"
-- acquired from http://en.openei.org/wiki/List_of_United_States_Utility_Companies_and_Aliases on 12/5/2014
set role 'urdb_rates-writers';
DROP TABLE IF EXISTS urdb_rates.urdb_utility_aliases_and_eia_id_lookup_20151202;
CREATE TABLE urdb_rates.urdb_utility_aliases_and_eia_id_lookup_20151202
(
	ur_name text,
	eia_id text
);

SET ROLE 'server-superusers';
COPY urdb_rates.urdb_utility_aliases_and_eia_id_lookup_20151202
FROM '/srv/home/mgleason/data/urdb/utilities_with_aliases_and_eia_idcsv.csv' with csv header;
set role 'urdb_rates-writers';

-- drop rows with null eia_id
DELETE FROM urdb_rates.urdb_utility_aliases_and_eia_id_lookup_20151202
where eia_id is null;
-- 3 rows dropped

-- are there any duplicates
SELECT ur_name, eia_id, count(*)
FROM urdb_rates.urdb_utility_aliases_and_eia_id_lookup_20151202
group by ur_name, eia_id
order by count desc;
-- yes -- many

-- drop the duplicates
aLTER TABLE urdb_rates.urdb_utility_aliases_and_eia_id_lookup_20151202
ADD temp_id serial;
with a As
(
	SELECT ur_name, eia_id, temp_id, row_number() over (Partition by ur_name, eia_id order by temp_id) as row_number
	FROM urdb_rates.urdb_utility_aliases_and_eia_id_lookup_20151202
),
b AS
(
	sELECT ur_name, eia_id, temp_id
	FROM a
	where row_number = 2
)
DELETE FROM urdb_rates.urdb_utility_aliases_and_eia_id_lookup_20151202 a
using b
where a.ur_name = b.ur_name
and a.eia_id = b.eia_id
and a.temp_id = b.temp_id;
-- dropped 896 duplicates

-- add primary key
ALTER TABLe urdb_rates.urdb_utility_aliases_and_eia_id_lookup_20151202
ADD PRIMARY KEY (ur_name, eia_id);



----------------------------------------------------------------
-- extract the utility district names from the urdb data we collected
DROP TABLE IF EXISTS urdb_rates.urdb3_verified_and_singular_ur_names_20141202;
CREATE TABLE urdb_rates.urdb3_verified_and_singular_ur_names_20141202 AS
SELECT distinct(ur_name) as ur_name
FROM urdb_rates.urdb3_verified_rates_sam_data_20141202 
UNION  
SELECT distinct(ur_name) as ur_name
FROM urdb_rates.urdb3_singular_rates_sam_data_20141202;
-- there are 1258 unique utility district names


-- are there different utility names in the lookup tables?
-- for singular rates, there shouldn't be any since both tables come from the same source
SELECT a.ur_name, b.utility_name
FROM urdb_rates.urdb3_singular_rates_sam_data_20141202  a
LEFT JOIN urdb_rates.urdb3_singular_rates_lookup_20141202 b
on a.urdb_rate_id = b.urdb_rate_id
where a.ur_name <> b.utility_name
GROUP BY a.ur_name, b.utility_name;
-- none returned

-- for verified -- yes, there are some
SELECT a.ur_name, b.utility_name
FROM urdb_rates.urdb3_verified_rates_sam_data_20141202  a
LEFT JOIN urdb_rates.urdb3_verified_rates_lookup_20141202 b
on a.urdb_rate_id = b.urdb_rate_id
where a.ur_name <> b.utility_name
GROUP BY a.ur_name, b.utility_name
order by a.ur_name;
-- yes, there are 110 different ones

-- update the lookup table to reflect the names from the urdb
UPDATE urdb_rates.urdb3_verified_rates_lookup_20141202 a
SET utility_name = b.ur_name
FROM urdb_rates.urdb3_verified_rates_sam_data_20141202 b
where a.urdb_rate_id = b.urdb_rate_id
and a.utility_name <> b.ur_name;


-- try to link the distinct urdb names to the lookup table
-- how many don't have a match?
SELECT *
FROM urdb_rates.urdb3_verified_and_singular_ur_names_20141202 a
LEFT JOIN urdb_rates.urdb_utility_aliases_and_eia_id_lookup_20151202 b
ON a.ur_name = b.ur_name
where b.eia_id is null;
-- 6

-- how many have multiple matches?
with a as 
(
	SELECT a.ur_name, b.eia_id, count(*)
	FROM urdb_rates.urdb3_verified_and_singular_ur_names_20141202 a
	LEFT JOIN urdb_rates.urdb_utility_aliases_and_eia_id_lookup_20151202 b
	ON a.ur_name = b.ur_name
	where b.eia_id is NOT null
	group by a.ur_name, b.eia_id
)
select *
FROM a
where a.count > 1;
--  zero

-- double ceck this
SELECT count(*)
FROM urdb_rates.urdb3_verified_and_singular_ur_names_20141202 a
LEFT JOIN urdb_rates.urdb_utility_aliases_and_eia_id_lookup_20151202 b
ON a.ur_name = b.ur_name
where b.eia_id is NOT null;
-- 1252 matches

-- 1252 matches plus 6 non-matches is 1258 total utilities -- does this match the count in:
SELECT count(*)
FROM urdb_rates.urdb3_verified_and_singular_ur_names_20141202;
-- 1258 -- yes it does


-- cross walk these to the ventyx tables
ALTER TABLE urdb_rates.urdb3_verified_and_singular_ur_names_20141202
ADD COLUMN eia_id_2011 text,
add column ventyx_company_id_2014 text;


with cw as
(
	SELECT a.ur_name, b.eia_id as eia_id_2011, c.company_id as ventyx_company_id_2014
	FROM urdb_rates.urdb3_verified_and_singular_ur_names_20141202 a
	-- link our names to urdb lookup names to find eia id
	LEFT JOIN urdb_rates.urdb_utility_aliases_and_eia_id_lookup_20151202 b
	ON a.ur_name = b.ur_name
	-- link eia id from urdb lookup to ventyx table with eia ids for various years
	LEFT JOIN ventyx.electric_service_territories_states_with_ids c
	ON b.eia_id = c.eiaid_2011
)
UPDATE urdb_rates.urdb3_verified_and_singular_ur_names_20141202 a
set (eia_id_2011, ventyx_company_id_2014) = (b.eia_id_2011, b.ventyx_company_id_2014)
FROM cw b
where a.ur_name = b.ur_name;

-- how many have unknown company_ids
SELECT *
FROM urdb_rates.urdb3_verified_and_singular_ur_names_20141202
where ventyx_company_id_2014 is null;
-- 24

-- these need to be fixed manually:
---------------------------------------------------------------
-- Shenandoah Valley Elec Coop (West Virgina)
select state_name, company_name, company_id, eiaid_2011
FROM ventyx.electric_service_territories_states_with_ids
where company_name like '%Shenandoah%'
-- company: 62961, eia: 17066

UPDATE urdb_rates.urdb3_verified_and_singular_ur_names_20141202
SET (ventyx_company_id_2014, eia_id_2011) = ('62961', '17066')
where ur_name = 'Shenandoah Valley Elec Coop (West Virgina)';
---------------------------------------------------------------
-- 'Arrowhead Electric Cooperative'
select state_name, company_name, company_id, eiaid_2011
FROM ventyx.electric_service_territories_states_with_ids
where company_name like '%Arrowhead%'
-- company: 60577, eia: '887'

UPDATE urdb_rates.urdb3_verified_and_singular_ur_names_20141202
SET (ventyx_company_id_2014, eia_id_2011) = ('60577', '887')
where ur_name = 'Arrowhead Electric Cooperative';
---------------------------------------------------------------
-- 'Orange & Rockland Utils Inc (New York)'
select state_name, company_name, company_id, eiaid_2011
FROM ventyx.electric_service_territories_states_with_ids
where company_name like '%Orange%'
-- company: 1131, eia: '14154'

UPDATE urdb_rates.urdb3_verified_and_singular_ur_names_20141202
SET (ventyx_company_id_2014, eia_id_2011) = ('1131', '14154')
where ur_name = 'Orange & Rockland Utils Inc (New York)';
---------------------------------------------------------------
-- City of Murray, Utah (Utility Company)
select state_name, company_name, company_id, eiaid_2011
FROM ventyx.electric_service_territories_states_with_ids
where company_name like '%Murray%'
-- company: 62376, eia: '13137'

UPDATE urdb_rates.urdb3_verified_and_singular_ur_names_20141202
SET (ventyx_company_id_2014, eia_id_2011) = ('62376', '13137')
where ur_name = 'City of Murray, Utah (Utility Company)';
---------------------------------------------------------------
-- NorthWestern Energy
select state_name, company_name, company_id, eiaid_2011
FROM ventyx.electric_service_territories_states_with_ids
where state_name = 'South Dakota'
-- company: 1122, eia: '12825'

UPDATE urdb_rates.urdb3_verified_and_singular_ur_names_20141202
SET (ventyx_company_id_2014, eia_id_2011) = ('1122', '12825')
where ur_name = 'NorthWestern Energy';
---------------------------------------------------------------
-- Ameren Illinois Company
select state_name, company_name, company_id, eiaid_2011
FROM ventyx.electric_service_territories_states_with_ids
where company_name like '%Ameren%'
-- company: 1177, eia: '19436'

UPDATE urdb_rates.urdb3_verified_and_singular_ur_names_20141202
SET (ventyx_company_id_2014, eia_id_2011) = ('1177', '19436')
where ur_name = 'Ameren Illinois Company';
---------------------------------------------------------------
-- Unitil Energy Systems
select state_name, company_name, company_id, eiaid_2011
FROM ventyx.electric_service_territories_states_with_ids
where company_name like '%Unitil%'
-- company: 404726, eia: '24590'

UPDATE urdb_rates.urdb3_verified_and_singular_ur_names_20141202
SET (ventyx_company_id_2014, eia_id_2011) = ('404726', '24590')
where ur_name = 'Unitil Energy Systems';
---------------------------------------------------------------
-- PPL EnergyPlus LLC
select state_name, company_name, company_id, eiaid_2011
FROM ventyx.electric_service_territories_states_with_ids
where company_name like '%PPL%'
-- company: 1138, eia: '14715'

UPDATE urdb_rates.urdb3_verified_and_singular_ur_names_20141202
SET (ventyx_company_id_2014, eia_id_2011) = ('1138', '14715')
where ur_name = 'PPL EnergyPlus LLC';
---------------------------------------------------------------
-- Vinton Public Power Auth
select state_name, company_name, company_id, eiaid_2011
FROM ventyx.electric_service_territories_states_with_ids
where company_name like '%Vinton%'
-- company: 63288, eia: 19866

UPDATE urdb_rates.urdb3_verified_and_singular_ur_names_20141202
SET (ventyx_company_id_2014, eia_id_2011) = ('63288', '19866')
where ur_name = 'Vinton Public Power Auth';
---------------------------------------------------------------
-- Black Hills/Colorado Elec.Utility Co. LP
select state_name, company_name, company_id, eiaid_2011
FROM ventyx.electric_service_territories_states_with_ids
where company_name like '%Black%'
-- company: 1012, eia: 19545

UPDATE urdb_rates.urdb3_verified_and_singular_ur_names_20141202
SET (ventyx_company_id_2014, eia_id_2011) = ('1012', '19545')
where ur_name = 'Black Hills/Colorado Elec.Utility Co. LP';
---------------------------------------------------------------
-- ''APS Energy Services''  == Arizona Public Service Co
select state_name, company_name, company_id, eiaid_2011
FROM ventyx.electric_service_territories_states_with_ids
where company_name like '%Arizona%'
-- company: 1007, eia: 803

UPDATE urdb_rates.urdb3_verified_and_singular_ur_names_20141202
SET (ventyx_company_id_2014, eia_id_2011) = ('1007', '803')
where ur_name = 'APS Energy Services';
---------------------------------------------------------------
-- Knoxville Utilities Board
-- get this one from the most up to date ventyx geoms
select company_na, company_id
FROM ventyx.electric_service_territories_20130422
where company_na like '%nox%'
-- company: 60913, eia: ?

UPDATE urdb_rates.urdb3_verified_and_singular_ur_names_20141202
SET (ventyx_company_id_2014) = (60913)
where ur_name = 'Knoxville Utilities Board';
---------------------------------------------------------------
-- Maricopa County M W C Dist and Electrical Dist No7 Maricopa
-- get this one from the most up to date ventyx geoms
select company_na, company_id
FROM ventyx.electric_service_territories_20130422
where company_na like '%Maricopa%'
-- company: 60559, eia: ?

UPDATE urdb_rates.urdb3_verified_and_singular_ur_names_20141202
SET (ventyx_company_id_2014) = (60559)
where ur_name in ('Maricopa County M W C Dist', 'Electrical Dist No7 Maricopa');
---------------------------------------------------------------
-- Central Vermont Pub Serv Corp
-- get this one from the most up to date ventyx geoms
select company_na, company_id
FROM ventyx.electric_service_territories_20130422
where company_na like '%Vermont%'
-- company: 1025, eia: ?

UPDATE urdb_rates.urdb3_verified_and_singular_ur_names_20141202
SET (ventyx_company_id_2014) = (1025)
where ur_name = 'Central Vermont Pub Serv Corp';
---------------------------------------------------------------
-- 'Illinois Power Co'
-- i think this one is just part of ameren illinois
-- to fix:
-- drop it from the ur_name lookup table
DELETE FROM urdb_rates.urdb3_verified_and_singular_ur_names_20141202
where ur_name = 'Illinois Power Co';

-- update the names in the other tables
UPDATE urdb_rates.urdb3_verified_rates_lookup_20141202
SET utility_name = 'Ameren Illinois Company'
where utility_name = 'Illinois Power Co';

UPDATE urdb_rates.urdb3_singular_rates_lookup_20141202
SET utility_name = 'Ameren Illinois Company'
where utility_name = 'Illinois Power Co';

UPDATE urdb_rates.urdb3_verified_rates_sam_data_20141202
SET ur_name = 'Ameren Illinois Company'
where ur_name = 'Illinois Power Co';

UPDATE urdb_rates.urdb3_singular_rates_sam_data_20141202
SET ur_name = 'Ameren Illinois Company'
where ur_name = 'Illinois Power Co';
---------------------------------------------------------------
-- able to fix 16 of 24


---------------------------------------------------------------
-- ***** UNSOLVED *****
-- CenterPoint Energy 
-- this one appears to be a distribution/transmission company only -- no obvious fix -- just ignore
---------------------------------------------------------------
-- Egegik Light & Power Co
-- can't find this one - ignore
---------------------------------------------------------------
-- Matinicus Plantation Elec Co
-- also a distribution/transmission company - no obvious fix - just ignore
---------------------------------------------------------------
-- Aguila Irrigation District
-- can't find a match -- ignore
---------------------------------------------------------------
-- Oncor Electric Delivery Company LLC
-- this one appears to be a distribution/transmission company only -- no obvious fix -- just ignore 
---------------------------------------------------------------
-- Gold Country Energy
-- can't find a match -- ignore
---------------------------------------------------------------
-- AEP Texas North Company
-- can't find a match -- ignore
---------------------------------------------------------------
-- Grand River Dam Authority
-- can't find a match -- ignore
---------------------------------------------------------------

-- drop rates associated with the unsolved territories
DELETE FROM urdb_rates.urdb3_singular_rates_sam_data_20141202 a
USING urdb_rates.urdb3_verified_and_singular_ur_names_20141202 b
where a.ur_name = b.ur_name
and b.ventyx_company_id_2014 is null;
-- drop 9 rows

DELETE FROM urdb_rates.urdb3_verified_rates_sam_data_20141202 a
USING urdb_rates.urdb3_verified_and_singular_ur_names_20141202 b
where a.ur_name = b.ur_name
and b.ventyx_company_id_2014 is null;
-- drop 1 row

DELETE FROM urdb_rates.urdb3_singular_rates_lookup_20141202 a
USING urdb_rates.urdb3_verified_and_singular_ur_names_20141202 b
where a.utility_name = b.ur_name
and b.ventyx_company_id_2014 is null;
-- drop 9 rows

DELETE FROM urdb_rates.urdb3_verified_rates_lookup_20141202 a
USING urdb_rates.urdb3_verified_and_singular_ur_names_20141202 b
where a.utility_name = b.ur_name
and b.ventyx_company_id_2014 is null;
-- drop 0 rows
---------------------------------------------------------------

-- drop the ur_names from the table if they have no company id
DELETE FROM  urdb_rates.urdb3_verified_and_singular_ur_names_20141202
where ventyx_company_id_2014 is null;
-- 8 rows dropped

-- make sure all company_ids have a match in the actual ventyx table
SELECT *
FROM urdb_rates.urdb3_verified_and_singular_ur_names_20141202 a
LEFT JOIN ventyx.electric_service_territories_20130422 b
ON a.ventyx_company_id_2014 = b.company_id::text
where b.company_id is null;
-- NONE!!!!!


-- check to see whether there are any duplicate company ids
-- this would occur if there were utilities with multiple aliases
SELECT ventyx_company_id_2014, count(*)
FROM urdb_rates.urdb3_verified_and_singular_ur_names_20141202
group by ventyx_company_id_2014
order by count desc;

-- there are, so we need to inspect them
with a AS
(
	SELECT ur_name, ventyx_company_id_2014, count(*) OVER (partition by ventyx_company_id_2014) as count
	FROM urdb_rates.urdb3_verified_and_singular_ur_names_20141202
)
SELECT *
FROM a
where count > 1;
-- do we need to unalias them, or is it okay because we can just associate each urdb rate with a company id?

-- add a primary key to the utility name field
ALTER TABLE urdb_rates.urdb3_verified_and_singular_ur_names_20141202
ADD PRIMARY KEY (ur_name);


