-- copy the rate sam_json data over to diffusion_shared with the rate alias id
set role 'diffusion-writers';

DROP TABLE IF EXISTS diffusion_shared.urdb3_rate_sam_jsons CASCADE;
CREATE TABLE diffusion_shared.urdb3_rate_sam_jsons AS
with a AS
(
	SELECT distinct(rate_id_alias)
	FROM urdb_rates.combined_singular_verified_rates_lookup
)
SELECT b.rate_id_alias, b.sam_json
FROM  urdb_rates.urdb3_singular_rates_sam_data_20141202 b
inner join urdb_rates.urdb3_singular_rates_lookup_20141202 c
ON b.rate_id_alias = c.rate_id_alias
and c.verified = False
INNER JOIN a
on a.rate_id_alias = b.rate_id_alias
UNION ALL -- union all is ok as long as the count of output rows matches the counnt of rows in a
SELECT b.rate_id_alias, b.sam_json
FROM  urdb_rates.urdb3_verified_rates_sam_data_20141202 b
INNER JOIN a
on a.rate_id_alias = b.rate_id_alias;

-- add primary key on rate_id_alias
ALTER TABLE diffusion_shared.urdb3_rate_sam_jsons
add primary key(rate_id_alias);

------------------------------------------------------------------
-- cleanup keys in the json field
-- DROP ur_enable_net_metering
SELECT get_key(sam_json, 'ur_enable_net_metering')
FROM diffusion_shared.urdb3_rate_sam_jsons
order by 1;
-- True everywhere
-- run the query to remove it
UPDATE diffusion_shared.urdb3_rate_sam_jsons
set sam_json = remove_key(sam_json, 'ur_enable_net_metering');
-- check that it worked
SELECT get_key(sam_json, 'ur_enable_net_metering')
FROM diffusion_shared.urdb3_rate_sam_jsons
order by 1;
-- all fixed

-- DROP ur_flat_sell_rate
SELECT get_key(sam_json, 'ur_flat_sell_rate')
FROM diffusion_shared.urdb3_rate_sam_jsons
order by 1;
-- 0 everywhere
-- run the query to remove it
UPDATE diffusion_shared.urdb3_rate_sam_jsons
set sam_json = remove_key(sam_json, 'ur_flat_sell_rate');
-- check that it worked
SELECT get_key(sam_json, 'ur_flat_sell_rate')
FROM diffusion_shared.urdb3_rate_sam_jsons
order by 1;
-- fixed

-- DROP ur_nm_yearend_sell_rate
SELECT get_key(sam_json, 'ur_nm_yearend_sell_rate')
FROM diffusion_shared.urdb3_rate_sam_jsons
order by 1;
-- not necesary -- it doesn't exist in any of the rates anyway

-- add a constant ur_dc_sched_weekday and ur_dc_sched_weekdend where ur_dc_enable = 1
-- (added value should be a 12x24 array of all 1s)
-- where does this occur?
with a as
(
	select rate_id_alias
	FROM diffusion_shared.urdb3_rate_sam_jsons
	where get_key(sam_json, 'ur_dc_enable')::integer = 1
	and (get_key(sam_json, 'ur_dc_sched_weekday') is null
		or 
	     get_key(sam_json, 'ur_dc_sched_weekend') is null)
)
select b.*
FROM a
INNER JOIN urdb_rates.urdb3_verified_rates_sam_data_20141202 b
ON a.rate_id_alias = b.rate_id_alias
UNION ALL
select c.*
FROM a
INNER JOIN urdb_rates.urdb3_singular_rates_sam_data_20141202 c
ON a.rate_id_alias = c.rate_id_alias;
-- 471 rows (this actually returns 474 but there are duplicates in the verified rates table that results in 474 rows being returned)
-- I spot checked the urdb webpage for 50 of these and they all have
-- a constant schedule of all 1s for both weekday and weekend

-- These rates somehow run fine in SAM UI, so I took 3 of these rates and put them into SAM, 
-- ran the pvwatts calcs, and then used shift+f5 to export the SAM lk scripts (to my home directory).
-- the lk scripts confirm that these cases default to a flat dc weekday and weekend schedule of all 1s.
-- I also exported these and sent them to Jay Huggins and Steve Janzou to see if they can fix in either URDB or SAM.

-- fix these by adding in the constant value array
UPDATE diffusion_shared.urdb3_rate_sam_jsons
set sam_json = mgleason.add_constant_array(sam_json, 'ur_dc_sched_weekday', 1, 12, 24)
where get_key(sam_json, 'ur_dc_enable')::integer = 1
and get_key(sam_json, 'ur_dc_sched_weekday') is null;

UPDATE diffusion_shared.urdb3_rate_sam_jsons
set sam_json = mgleason.add_constant_array(sam_json, 'ur_dc_sched_weekend', 1, 12, 24)
where get_key(sam_json, 'ur_dc_enable')::integer = 1
and get_key(sam_json, 'ur_dc_sched_weekend') is null;


-- make sure all are fixed
select count(*)
FROM diffusion_shared.urdb3_rate_sam_jsons
where get_key(sam_json, 'ur_dc_enable')::integer = 1
and (get_key(sam_json, 'ur_dc_sched_weekday') is null
	or 
     get_key(sam_json, 'ur_dc_sched_weekend') is null);
-- 0 rows returned