-- urdb_rate_id is too long (too many characters), making building indices and performining
-- joins on it very slow. we need to create an alias id that is just a simple integer

-- to do so, first task is to find all of the unique urdb_rate_ids in the data we've collected

SET ROLE 'urdb_rates-writers';

------------------------------------------------------------------------------------------
-- before doing that, check that the lookup and sam_data tables for both singular and verified contain the same ids
select count(*)
from urdb_rates.urdb3_singular_rates_lookup_20141202 a
full outer join urdb_rates.urdb3_singular_rates_sam_data_20141202 b
on a.urdb_rate_id = b.urdb_rate_id
where b.urdb_rate_id is null
or a.urdb_rate_id is null;
-- 0

select count(*)
from urdb_rates.urdb3_verified_rates_lookup_20141202 a
full outer join urdb_rates.urdb3_verified_rates_sam_data_20141202 b
on a.urdb_rate_id = b.urdb_rate_id
where b.urdb_rate_id is null
or a.urdb_rate_id is null;
-- 0

-- there is complete match between the lookup and data tables
-- we are good to proceed.

------------------------------------------------------------------------------------------

-- extract all unique urdb_rate_ids
DROP TABLE IF EXISTS urdb_rates.urdb3_rate_id_aliases_20141202;
CREATE TABLE urdb_rates.urdb3_rate_id_aliases_20141202 AS
with a AS
(
	SELECT distinct(urdb_rate_id) as urdb_rate_id
	FROM urdb_rates.urdb3_singular_rates_lookup_20141202
	UNION
	SELECT distinct(urdb_rate_id) as urdb_rate_id
	FROM urdb_rates.urdb3_verified_rates_lookup_20141202
)
SELECT *
FROM a
order by urdb_rate_id;
-- 2377 rows

-- add a new alias id 
ALTER TABLE urdb_rates.urdb3_rate_id_aliases_20141202
add COLUMN rate_id_alias serial unique not null;

-- add primary key on urdb_rate_id
ALTER TABLE urdb_rates.urdb3_rate_id_aliases_20141202
ADD primary key (urdb_rate_id);

-- add index on the alias id
CREATE INDEX urdb3_rate_id_aliases_20141202_rate_id_alias_btree
on urdb_rates.urdb3_rate_id_aliases_20141202
using btree(rate_id_alias);

------------------------------------------------------------------------------------------

-- update all tables to reflect these aliases

-- singular lookup
-- add column
ALTER TABLE urdb_rates.urdb3_singular_rates_lookup_20141202
DROP COLUMN IF EXISTS rate_id_alias;
ALTER TABLE urdb_rates.urdb3_singular_rates_lookup_20141202
ADD column rate_id_alias integer;
-- update column
UPDATE urdb_rates.urdb3_singular_rates_lookup_20141202 a
SET rate_id_alias = b.rate_id_alias
from urdb_rates.urdb3_rate_id_aliases_20141202 b
where a.urdb_rate_id = b.urdb_rate_id;
-- add index
CREATE INDEX urdb3_singular_rates_lookup_20141202_rate_id_alias_btree
on urdb_rates.urdb3_singular_rates_lookup_20141202
using btree(rate_id_alias);
-- check for nulls
SELECT *
FROM urdb_rates.urdb3_singular_rates_lookup_20141202
where rate_id_alias is null;

-- singular sam data
-- add column
ALTER TABLE urdb_rates.urdb3_singular_rates_sam_data_20141202
DROP COLUMN IF EXISTS rate_id_alias;
ALTER TABLE urdb_rates.urdb3_singular_rates_sam_data_20141202
ADD column rate_id_alias integer;
-- update column
UPDATE urdb_rates.urdb3_singular_rates_sam_data_20141202 a
SET rate_id_alias = b.rate_id_alias
from urdb_rates.urdb3_rate_id_aliases_20141202 b
where a.urdb_rate_id = b.urdb_rate_id;
-- add index
CREATE INDEX urdb3_singular_rates_sam_data_20141202_rate_id_alias_btree
on urdb_rates.urdb3_singular_rates_sam_data_20141202
using btree(rate_id_alias);
-- check for nulls
SELECT *
FROM urdb_rates.urdb3_singular_rates_sam_data_20141202
where rate_id_alias is null;

-- verified lookup
-- add column
ALTER TABLE urdb_rates.urdb3_verified_rates_lookup_20141202
DROP COLUMN IF EXISTS rate_id_alias;
ALTER TABLE urdb_rates.urdb3_verified_rates_lookup_20141202
ADD column rate_id_alias integer;
-- update column
UPDATE urdb_rates.urdb3_verified_rates_lookup_20141202 a
SET rate_id_alias = b.rate_id_alias
from urdb_rates.urdb3_rate_id_aliases_20141202 b
where a.urdb_rate_id = b.urdb_rate_id;
-- add index
CREATE INDEX urdb3_verified_rates_lookup_20141202_rate_id_alias_btree
on urdb_rates.urdb3_verified_rates_lookup_20141202
using btree(rate_id_alias);
-- check for nulls
SELECT *
FROM urdb_rates.urdb3_verified_rates_lookup_20141202
where rate_id_alias is null;

-- verified sam data
-- add column
ALTER TABLE urdb_rates.urdb3_verified_rates_sam_data_20141202
DROP COLUMN IF EXISTS rate_id_alias;
ALTER TABLE urdb_rates.urdb3_verified_rates_sam_data_20141202
ADD column rate_id_alias integer;
-- update column
UPDATE urdb_rates.urdb3_verified_rates_sam_data_20141202 a
SET rate_id_alias = b.rate_id_alias
from urdb_rates.urdb3_rate_id_aliases_20141202 b
where a.urdb_rate_id = b.urdb_rate_id;
-- add index
CREATE INDEX urdb3_verified_rates_sam_data_20141202_rate_id_alias_btree
on urdb_rates.urdb3_verified_rates_sam_data_20141202
using btree(rate_id_alias);
-- check for nulls
SELECT *
FROM urdb_rates.urdb3_verified_rates_sam_data_20141202
where rate_id_alias is null;