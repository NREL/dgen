-- set role
set role 'urdb_rates-writers';

------------------------------------------------------------------------------------
-- create a new version of the singular rates lookup table that excludes the old maine rates
DROP TABLE IF EXISTS urdb_rates.urdb3_singular_rates_lookup_20151028;
CREATE TABLE urdb_rates.urdb3_singular_rates_lookup_20151028 AS
WITH c AS
(
	select distinct company_id, state
	FROM urdb_rates.ventyx_electric_service_territories_w_vs_rates_20141202
)
SELECT a.*
FROM urdb_rates.urdb3_singular_rates_lookup_20141202 a
lEFT JOIN urdb_rates.urdb3_verified_and_singular_ur_names_20141202 b
ON a.utility_name = b.ur_name
LEFT JOIN c
ON b.ventyx_company_id_2014 = c.company_id::text
where c.state <> 'ME';
-- 1274 rows out of 1277 in the old table

------------------------------------------------------------------------------------
-- do the same for verified rates lookup table: create a new version that excludes the old maine rates
DROP TABLE IF EXISTS urdb_rates.urdb3_verified_rates_lookup_20151028;
CREATE TABLE urdb_rates.urdb3_verified_rates_lookup_20151028 AS
SELECT *
FROM urdb_rates.urdb3_verified_rates_lookup_20141202
where state_code <> 'ME';
-- 1114 rows out of 1132 in the old table

------------------------------------------------------------------------------------
-- load the new maine rates from pieter gagnon

-- add a new column to the verified table that gives the popularity of each rate
-- as a percent of the total in the state, by sector
ALTER TABLE urdb_rates.urdb3_verified_rates_lookup_20151028
ADD COLUMN pct_of_state_sector_cust numeric;

\COPY urdb_rates.urdb3_verified_rates_lookup_20151028 (utility_name, state_code, rate_name, demand_min, demand_max, res_com, urdb_rate_id, pct_of_state_sector_cust) FROM '/Volumes/Staff/mgleason/DG_Wind/Data/Source_Data/URDB_Rates/maine_updates_2015_10_28/new_rates_maine_pgagnon.csv' with csv header;

-- check the data loaded correctly
select *
FROM urdb_rates.urdb3_verified_rates_lookup_20151028
where state_code = 'ME';
-- all looks good

-- fill in additional generic info, if possible:
UPDATE urdb_rates.urdb3_verified_rates_lookup_20151028
SET missing_from_urdb = false
where state_code = 'ME';

UPDATE urdb_rates.urdb3_verified_rates_lookup_20151028
SET sub_territory_name = 'Not Applicable'
where state_code = 'ME';

-- add new rate_id_aliases
select max(rate_id_alias)
FROM urdb_rates.combined_singular_verified_rates_lookup;
-- existing max rate id alias is 2377
-- this also lines up with the existing state of urdb_rates.urdb3_rate_id_aliases_20141202_rate_id_alias_seq

-- use the sequence to update the rate id alias for the new records
UPDATE urdb_rates.urdb3_verified_rates_lookup_20151028
SET rate_id_alias = nextval('urdb_rates.urdb3_rate_id_aliases_20141202_rate_id_alias_seq')
where state_code = 'ME';

-- check the results
select *
FROM urdb_rates.urdb3_verified_rates_lookup_20151028
where state_code = 'ME';
-- new ids are 2378 through 2390 -- all set!
------------------------------------------------------------------------------------

------------------------------------------------------------------------------------
-- create indices on both of the new singular and verified lookup tables:
-- res_com
-- urdb_rate_id
-- rate_id_alias
-- utility_name
-- utility_id
-- sub_territory_name

-- verified
CREATE INDEX urdb3_verified_rates_lookup_20151028_btree_res_com
ON urdb_rates.urdb3_verified_rates_lookup_20151028
USING BTREE(res_com);

CREATE INDEX urdb3_verified_rates_lookup_20151028_btree_urdb_rate_id
ON urdb_rates.urdb3_verified_rates_lookup_20151028
USING BTREE(urdb_rate_id);

CREATE INDEX urdb3_verified_rates_lookup_20151028_btree_rate_id_alias
ON urdb_rates.urdb3_verified_rates_lookup_20151028
USING BTREE(rate_id_alias);

CREATE INDEX urdb3_verified_rates_lookup_20151028_btree_utility_name
ON urdb_rates.urdb3_verified_rates_lookup_20151028
USING BTREE(utility_name);

CREATE INDEX urdb3_verified_rates_lookup_20151028_btree_utility_id
ON urdb_rates.urdb3_verified_rates_lookup_20151028
USING BTREE(utility_id);

CREATE INDEX urdb3_verified_rates_lookup_20151028_btree_sub_territory_name
ON urdb_rates.urdb3_verified_rates_lookup_20151028
USING BTREE(sub_territory_name);

-- singular
CREATE INDEX urdb3_singular_rates_lookup_20151028_btree_res_com
ON urdb_rates.urdb3_singular_rates_lookup_20151028
USING BTREE(res_com);

CREATE INDEX urdb3_singular_rates_lookup_20151028_btree_urdb_rate_id
ON urdb_rates.urdb3_singular_rates_lookup_20151028
USING BTREE(urdb_rate_id);

CREATE INDEX urdb3_singular_rates_lookup_20151028_btree_rate_id_alias
ON urdb_rates.urdb3_singular_rates_lookup_20151028
USING BTREE(rate_id_alias);

CREATE INDEX urdb3_singular_rates_lookup_20151028_btree_utility_name
ON urdb_rates.urdb3_singular_rates_lookup_20151028
USING BTREE(utility_name);

CREATE INDEX urdb3_singular_rates_lookup_20151028_btree_sub_territory_name
ON urdb_rates.urdb3_singular_rates_lookup_20151028
USING BTREE(sub_territory_name);


