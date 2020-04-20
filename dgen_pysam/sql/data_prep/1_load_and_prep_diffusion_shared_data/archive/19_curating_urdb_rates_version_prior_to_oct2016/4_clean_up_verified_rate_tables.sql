------------------------------------------------------------------------
-- CLEANUP ON THE LOOKUP TABLE

-- rename the min_app and max_app
alter table urdb_rates.urdb3_verified_rates_lookup_20141202
RENAME column min_app TO demand_min;

alter table urdb_rates.urdb3_verified_rates_lookup_20141202
RENAME column max_app TO demand_max;

-- are there any duplicate ids?
with a AS
(
	select urdb_rate_id, count(*) as count
	from urdb_rates.urdb3_verified_rates_lookup_20141202
	group by urdb_rate_id
	order by count desc
)
SELECT *
FROM urdb_rates.urdb3_verified_rates_lookup_20141202 b
inner join a
on a.urdb_rate_id = b.urdb_rate_id
where a.count >= 2
order by a.urdb_rate_id;
-- yes (8 are duplicated)


-- manually determine what's going on with each of these
-- do this by first pulling the information returned by the urdb
-- and then opening up the rateurl if necessary to review online


-- 539f6af9ec4f024411ec96c3
-- same rate can be used by commercial and residential
-- fix: leave as-is


-- 539f6dccec4f024411ecba6f
-- listed incorrectly as applying to both 0-20 and 20-100 kw (should only be 0-20)
-- fix: delete incorrect row
delete from urdb_rates.urdb3_verified_rates_lookup_20141202
where urdb_rate_id = '539f6dccec4f024411ecba6f'
and min_app = '20';


-- 539f6e2bec4f024411ecbf27
-- not entirely sure, but appears to apply better to one of the two records based on demamd minimum of 50
-- fix: keep min app = 50
delete from urdb_rates.urdb3_verified_rates_lookup_20141202
where urdb_rate_id = '539f6e2bec4f024411ecbf27'
and min_app = '0';


-- 539f7429ec4f024411ed0541
-- both entries seem applicable -- they just artificially break up the demand ranges
-- fix: delete one and update the other
delete from urdb_rates.urdb3_verified_rates_lookup_20141202
where urdb_rate_id = '539f7429ec4f024411ed0541'
and min_app = 49;

UPDATE urdb_rates.urdb3_verified_rates_lookup_20141202
SET min_app = 49
where urdb_rate_id = '539f7429ec4f024411ed0541'


-- 539fb503ec4f024bc1dbefcd
-- both entries seem applicable -- they just artificially break up the demand ranges
-- fix: delete one and update the other
delete from urdb_rates.urdb3_verified_rates_lookup_20141202
where urdb_rate_id = '539fb503ec4f024bc1dbefcd'
and min_app = 700;

UPDATE urdb_rates.urdb3_verified_rates_lookup_20141202
SET min_app = 699
where urdb_rate_id = '539fb503ec4f024bc1dbefcd'


-- 539fc7dfec4f024d2f53e0ea
-- same rate can be used by commercial and residential(?)
-- fix: leave as-is
 

-- 539fca28ec4f024d2f53f918
-- totally identical except for rate_type (rate is tiered not tou)
-- delete tou rate
delete from urdb_rates.urdb3_verified_rates_lookup_20141202
where urdb_rate_id = '539fca28ec4f024d2f53f918'
and rate_type = 'TOU';


-- 53ad70965257a3d57ddcddbd
-- demand range is incorrect for one
-- delete the one that is incorrect
delete from urdb_rates.urdb3_verified_rates_lookup_20141202
where urdb_rate_id = '53ad70965257a3d57ddcddbd'
and min_app = 50;


-- the only ones remaining should be rates that can apply to both commercial and industrial
-- add primary key on urdb_rate_id and res_com
ALTER TABLE urdb_rates.urdb3_verified_rates_lookup_20141202
ADD PRIMARY KEY (urdb_rate_id, res_com);


-- add some other indices that will be useful later
-- lookup table
CREATE INDEX rate_lkup_urdb_rate_id_btree
ON urdb_rates.urdb3_verified_rates_lookup_20141202
using btree(urdb_rate_id);

CREATE INDEX rate_lkup_urdb_res_com_btree
ON urdb_rates.urdb3_verified_rates_lookup_20141202
using btree(res_com);

ALTER tABLE urdb_rates.urdb3_verified_rates_lookup_20141202
ADD CONSTRAINT res_com_check CHECK (res_com in ('R','C'));

CREATE INDEX rate_lkup_urdb_utility_name_btree
ON urdb_rates.urdb3_verified_rates_lookup_20141202
using btree(utility_name);

CREATE INDEX rate_lkup_urdb_utility_id_btree
ON urdb_rates.urdb3_verified_rates_lookup_20141202
using btree(utility_id);





------------------------------------------------------------------------
-- CLEANUP ON THE DATA TABLE
-- are there any duplicates?
SELECT urdb_rate_id, count(*)
FROM urdb_rates.urdb3_verified_rates_sam_data_20141202
group by urdb_rate_id
order by count desc;
-- 
-- 
-- -- drop duplicates from the sam data table 
-- -- (this won't be necessary in the future because it was fixed in the python script that downloads the data)
-- -- add a temporary serial id
-- ALTER TABLE urdb_rates.urdb3_verified_rates_sam_data_20141202
-- ADD COLUMN temp_id serial;
-- 
-- -- use the temp id to figure out which rows to delete
-- with all_rows AS
-- (
-- 	SELECT urdb_rate_id, temp_id, row_number() OVER (partition by urdb_rate_id ORDEr by temp_id) as row_number
-- 	FROM urdb_rates.urdb3_verified_rates_sam_data_20141202
-- ),
-- dupes as
-- (
-- 	SELECT *
-- 	FROM all_rows
-- 	where row_number = 2
-- )
-- DELETE FROM urdb_rates.urdb3_verified_rates_sam_data_20141202 a
-- USING dupes b
-- where a.urdb_rate_id = b.urdb_rate_id
-- and a.temp_id = b.temp_id;
-- -- 8 rows deleted
-- 
-- -- drop the temp_id
-- ALTER TABLE urdb_rates.urdb3_verified_rates_sam_data_20141202
-- DROP COLUMN temp_id; 

-- add primary key
ALTER TABLE urdb_rates.urdb3_verified_rates_sam_data_20141202
ADD PRIMARY KEY (urdb_rate_id);

