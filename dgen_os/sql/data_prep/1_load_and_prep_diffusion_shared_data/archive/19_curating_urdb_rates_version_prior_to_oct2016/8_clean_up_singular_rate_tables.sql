-- add a primary key
ALTER TABLE urdb_rates.urdb3_singular_rates_sam_data_20141202
ADD PRIMARY KEY (urdb_rate_id);

-- add columns for applicability to lookup table
ALTER TABLE urdb_rates.urdb3_singular_rates_lookup_20141202
add column demand_min numeric,
ADD column demand_max numeric;


-- extract demand min, where available
-- update the demand min
with a as
(
	select urdb_rate_id, 
		regexp_matches(regexp_matches(applicability::text,'ur_demand_min": [0-9]*,')::text,'[0-9][0-9][0-9]*') as ur_demand_min
	FROM urdb_rates.urdb3_singular_rates_sam_data_20141202 
),
b as
(
	Select urdb_rate_id, ur_demand_min[1]::numeric as ur_demand_min
	From a
)
UPDATE urdb_rates.urdb3_singular_rates_lookup_20141202 a
SET demand_min = b.ur_demand_min
from b
where a.urdb_rate_id = b.urdb_rate_id;
-- only available from 6

-- update demand max
with a as
(
	select urdb_rate_id, 
		regexp_matches(regexp_matches(applicability::text,'ur_demand_max": [0-9]*,')::text,'[0-9][0-9][0-9]*') as ur_demand_max
	FROM urdb_rates.urdb3_singular_rates_sam_data_20141202 
),
b as
(
	Select urdb_rate_id, ur_demand_max[1]::numeric as ur_demand_max
	From a
)
UPDATE urdb_rates.urdb3_singular_rates_lookup_20141202 a
SET demand_max = b.ur_demand_max
from b
where a.urdb_rate_id = b.urdb_rate_id;
-- 19 rows updated

-- check to see whether any residential rates have min/max demand ranges
select *
FROM  urdb_rates.urdb3_singular_rates_lookup_20141202
where (demand_min is not null
or demand_max is not null)
and res_com = 'R';
-- most of these have demand maxes, which likely won't be hit for res customers, so we can leave them
-- only two have demand mins -- these don't make a lot of sense, so let's just just drop them

-- delete the residential rates with demand mins
select *
FROM  urdb_rates.urdb3_singular_rates_lookup_20141202
where demand_min is not null
and res_com = 'R';
-- to delete:
-- 'Butler Rural Electric Coop Inc';'539fc1efec4f024c27d8ac47'
-- 'City of Marietta, Georgia (Utility Company)';'53b300f35257a3dd75050f9a'

-- check whether there are any othe rates that apply to these utilities
select *
FROM urdb_rates.urdb3_singular_rates_lookup_20141202
where utility_name in ('Butler Rural Electric Coop Inc','City of Marietta, Georgia (Utility Company)');
-- there is only the one rate in butler, but there is a second rate in marietta

select *
FROM urdb_rates.urdb3_verified_rates_lookup_20141202
where utility_name in ('Butler Rural Electric Coop Inc','City of Marietta, Georgia (Utility Company)');
-- none in verified rates

-- so, delete butler from the name lookup table
delete from urdb_rates.urdb3_verified_and_singular_ur_names_20141202
where ur_name = 'Butler Rural Electric Coop Inc';
-- one row deleted

-- now delete the rates from the singular tables
DELETE FROM urdb_rates.urdb3_singular_rates_lookup_20141202
where urdb_rate_id in ('539fc1efec4f024c27d8ac47','53b300f35257a3dd75050f9a');
-- 2 rows deleted

DELETE FROM urdb_rates.urdb3_singular_rates_sam_data_20141202
where urdb_rate_id in ('539fc1efec4f024c27d8ac47','53b300f35257a3dd75050f9a');


-- for the remainders of residential, simply set the the demand min and max very high
UPDATE urdb_rates.urdb3_singular_rates_lookup_20141202
SET demand_min = 0
where demand_min is null
and res_com = 'R';

UPDATE urdb_rates.urdb3_singular_rates_lookup_20141202
SET demand_max = 1e10
where demand_max is null
and res_com = 'R';

-- check results look right
select a.*, b.applicability
FRom urdb_rates.urdb3_singular_rates_lookup_20141202 a
left join urdb_rates.urdb3_singular_rates_sam_data_20141202 b
on a.urdb_rate_id = b.urdb_rate_id
where res_com = 'R';
-- they do


-- inspect the commercial rates with mins and maxes
select *
FROM  urdb_rates.urdb3_singular_rates_lookup_20141202
where (demand_min is not null
or demand_max is not null)
and res_com = 'C'
-- only 11

-- for the remainders, just set the demand mins and maxes
UPDATE urdb_rates.urdb3_singular_rates_lookup_20141202
SET demand_min = 0
where demand_min is null
and res_com = 'C';

UPDATE urdb_rates.urdb3_singular_rates_lookup_20141202
SET demand_max = 1e10
where demand_max is null
and res_com = 'C';
