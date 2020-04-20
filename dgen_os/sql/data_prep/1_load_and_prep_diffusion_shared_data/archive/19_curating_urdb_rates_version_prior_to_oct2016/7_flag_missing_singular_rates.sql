-- flag the rates in the singular rates lookup table that couldn't be downloaded from URDB (for various reasons)
-- (see missing_singular_rates.log for details on why they failed)

ALTER TABLE urdb_rates.urdb3_singular_rates_lookup_20141202
ADD COLUMN missing_from_urdb boolean default false;

with missing AS
(
	SELECT a.urdb_rate_id
	FROM urdb_rates.urdb3_singular_rates_lookup_20141202 a
	LEFT JOIN urdb_rates.urdb3_singular_rates_sam_data_20141202 b
	ON a.urdb_rate_id = b.urdb_rate_id
	where b.urdb_rate_id is null
)
UPDATE urdb_rates.urdb3_singular_rates_lookup_20141202 a
SET missing_from_urdb = true
FROM missing b
WHERE a.urdb_rate_id = b.urdb_rate_id;
-- 10 rows are missing

-- delete the missing ones for easier interpretation
DELETE FROM urdb_rates.urdb3_singular_rates_lookup_20141202 a
where missing_from_urdb = true;

-- counts should now match
SELECT count(*)
FROM urdb_rates.urdb3_singular_rates_lookup_20141202;
--1280
SELECT count(*)
FROM urdb_rates.urdb3_singular_rates_sam_data_20141202;
--1280
-- they do