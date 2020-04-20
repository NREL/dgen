-- flag the rates in the lookup table that couldn't be downloaded from URDB (for various reasons)
-- (see /Users/mgleason/NREL_Projects/git_repos/diffusion/sql/data_prep/1_load_and_prep_diffusion_shared_data/curating_urdb_rates/batch_load_urdb_to_postgres_20141202_162008.log
-- for details on why the failed)

ALTER TABLE urdb_rates.urdb3_verified_rates_lookup_20141202
DROP COLUMN if exists missing_from_urdb;

ALTER TABLE urdb_rates.urdb3_verified_rates_lookup_20141202
ADD COLUMN missing_from_urdb boolean default false;

with missing AS
(
	SELECT a.urdb_rate_id
	FROM urdb_rates.urdb3_verified_rates_lookup_20141202 a
	LEFT JOIN urdb_rates.urdb3_verified_rates_sam_data_20141202 b
	ON a.urdb_rate_id = b.urdb_rate_id
	where b.urdb_rate_id is null
)
UPDATE urdb_rates.urdb3_verified_rates_lookup_20141202 a
SET missing_from_urdb = true
FROM missing b
WHERE a.urdb_rate_id = b.urdb_rate_id;
-- 10 rows are missing

-- delete the missing rows for easier interpretation
DELETE FROM urdb_rates.urdb3_verified_rates_lookup_20141202
where missing_from_urdb = true;

-- counts should now match
SELECT count(*)
FROM urdb_rates.urdb3_verified_rates_lookup_20141202;
--1135
SELECT count(*)
FROM urdb_rates.urdb3_verified_rates_sam_data_20141202;
--1133

-- they don't match exactly because urdb_rates.urdb3_verified_rates_lookup_20141202 
-- has two dupes for rates that apply to res and com
Select urdb_Rate_id, count(*)
FROM urdb_rates.urdb3_verified_rates_lookup_20141202
group by urdb_Rate_id
order by count desc;