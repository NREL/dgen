-- set role
set role 'urdb_rates-writers';

------------------------------------------------------------------------------------
-- create a new version of the singular rates data table that excludes the old maine rates
DROP TABLE IF EXISTS urdb_rates.urdb3_verified_rates_sam_data_20151028;
CREATE TABLE urdb_rates.urdb3_verified_rates_sam_data_20151028 AS
select a.*
FROM urdb_rates.urdb3_verified_rates_sam_data_20141202 a
INNER JOIN urdb_rates.urdb3_verified_rates_lookup_20151028 b
ON a.rate_id_alias = b.rate_id_alias;
-- 1114 out of 1130 old rows
-- row count matches the new verified lookup table (excluding the new maine rates)

------------------------------------------------------------------------------------
-- repeate for singular rates data table: create new version that excludes the old maine rates
DROP TABLE IF EXISTS urdb_rates.urdb3_singular_rates_sam_data_20151028;
CREATE TABLE urdb_rates.urdb3_singular_rates_sam_data_20151028 AS
select a.*
FROM urdb_rates.urdb3_singular_rates_sam_data_20141202 a
INNER JOIN urdb_rates.urdb3_singular_rates_lookup_20151028 b
ON a.rate_id_alias = b.rate_id_alias;
-- 1274 out of 1277 old rows
-- row count matches the new singular lookup table (excluding the new maine rates)

------------------------------------------------------------------------------------
-- create indices on new tables
-- rate_id_alias
-- sub_territory_name
-- ur_name

-- singular
CREATE INDEX urdb3_singular_rates_sam_data_20151028_btree_rate_id_alias
ON urdb_rates.urdb3_singular_rates_sam_data_20151028
USING BTREE(rate_id_alias);

CREATE INDEX urdb3_singular_rates_sam_data_20151028_btree_sub_territory_name
ON urdb_rates.urdb3_singular_rates_sam_data_20151028
USING BTREE(sub_territory_name);

CREATE INDEX urdb3_singular_rates_sam_data_20151028_btree_ur_name
ON urdb_rates.urdb3_singular_rates_sam_data_20151028
USING BTREE(ur_name);


-- verified
CREATE INDEX urdb3_verified_rates_sam_data_20151028_btree_rate_id_alias
ON urdb_rates.urdb3_verified_rates_sam_data_20151028
USING BTREE(rate_id_alias);

CREATE INDEX urdb3_verified_rates_sam_data_20151028_btree_sub_territory_name
ON urdb_rates.urdb3_verified_rates_sam_data_20151028
USING BTREE(sub_territory_name);

CREATE INDEX urdb3_verified_rates_sam_data_20151028_btree_ur_name
ON urdb_rates.urdb3_verified_rates_sam_data_20151028
USING BTREE(ur_name);


