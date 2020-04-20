-- find the unique combinations of ranked rates (some points will have identical rankings)
------------------------------------------------------------------------------------------------------------
-- COMMERCIAL
------------------------------------------------------------------------------------------------------------
-- group the ranked urdb rates into arrays for each individual point 
DROP TABLE IF EXISTS diffusion_data_shared.pt_ranked_rate_arrays_com_maine;
CREATE TABLE diffusion_data_shared.pt_ranked_rate_arrays_com_maine AS
SELECT a.pt_gid, 
	array_agg(a.rate_id_alias order by a.rank asc, a.rate_id_alias asc) as rate_id_alias_array,
	array_agg(a.rank order by a.rank asc, a.rate_id_alias asc) as rank_array
FROM diffusion_data_shared.pt_ranked_rates_lkup_com_maine a
GROUP BY pt_gid;
-- 10530 rows

-- check that the row count matches the row count of diffusion_shared.pt_grid_us_com_new
SELECT count(*)
FROM diffusion_shared.pt_grid_us_com a
LEFT JOIN diffusion_shared.county_geom b
ON a.county_id = b.county_id
where b.state_abbr = 'ME';
-- 10530

-- make sure there are no emtpy arrays
select count(*)
FROM diffusion_data_shared.pt_ranked_rate_arrays_com_maine
where rate_id_alias_array is null;
-- 0
select count(*)
FROM diffusion_data_shared.pt_ranked_rate_arrays_com_maine
where rate_id_alias_array = '{}';
-- 0
-- all set

-- create indices
CREATE INDEX pt_ranked_rate_arrays_com_maine_rate_id_btree 
ON diffusion_data_shared.pt_ranked_rate_arrays_com_maine
using btree(rate_id_alias_array);

CREATE INDEX pt_ranked_rate_arrays_com_maine_rank_btree 
ON diffusion_data_shared.pt_ranked_rate_arrays_com_maine
using btree(rank_array);

CREATE INDEX pt_ranked_rate_arrays_com_maine_gid_btree 
ON diffusion_data_shared.pt_ranked_rate_arrays_com_maine
using btree(pt_gid);

------------------------------------------------------------------------------------------------------------
-- find the distinct ranked rate arrays across all points
DROP TABLE IF EXISTS diffusion_data_shared.unique_ranked_rate_arrays_com_maine;
CREATE TABLE diffusion_data_shared.unique_ranked_rate_arrays_com_maine AS
SELECT rate_id_alias_array, rank_array
FROM diffusion_data_shared.pt_ranked_rate_arrays_com_maine
GROUP BY rate_id_alias_array, rank_array;
-- 5 rows

-- add a unique id for each unique ranked rate array
ALTER TABLE diffusion_data_shared.unique_ranked_rate_arrays_com_maine
ADD ranked_rate_array_id integer;

-- update based off of the diffusion_data_shared.unique_ranked_rate_arrays_com_ranked_rate_array_id_seq
UPDATE diffusion_data_shared.unique_ranked_rate_arrays_com_maine
SET ranked_rate_array_id = nextval('diffusion_data_shared.unique_ranked_rate_arrays_com_ranked_rate_array_id_seq');

ALTER TABLE diffusion_data_shared.unique_ranked_rate_arrays_com_maine
ADD primary key (ranked_rate_array_id);

-- create index on the arrays
CREATE INDEX unique_ranked_rate_arrays_com_maine_rate_id_btree
ON diffusion_data_shared.unique_ranked_rate_arrays_com_maine 
USING btree(rate_id_alias_array);

CREATE INDEX unique_ranked_rate_arrays_com_maine_rank_btree
ON diffusion_data_shared.unique_ranked_rate_arrays_com_maine 
USING btree(rank_array);

------------------------------------------------------------------------------------------------------------
-- create lookup table for each point to a ranked_rate_array_id
DROP TABLE IF EXISTS diffusion_data_shared.pt_ranked_rate_array_lkup_com_maine;
CREATE TABLE diffusion_data_shared.pt_ranked_rate_array_lkup_com_maine as
SELECT a.pt_gid, b.ranked_rate_array_id
FROM diffusion_data_shared.pt_ranked_rate_arrays_com_maine a
LEFT JOIN diffusion_data_shared.unique_ranked_rate_arrays_com_maine b
ON a.rate_id_alias_array = b.rate_id_alias_array
and a.rank_array = b.rank_array;
-- 10530 rows

-- check that the row count matches the row count of diffusion_shared.pt_grid_us_com_new
SELECT count(*)
FROM diffusion_shared.pt_grid_us_com a
LEFT JOIN diffusion_shared.county_geom b
ON a.county_id = b.county_id
where b.state_abbr = 'ME';
-- 10530

-- add primary key
ALTER TABLE diffusion_data_shared.pt_ranked_rate_array_lkup_com_maine
ADD PRIMARY KEY (pt_gid);

-- add index
CREATE INDEX pt_ranked_rate_array_lkup_com_maine_rate_array_btree
ON diffusion_data_shared.pt_ranked_rate_array_lkup_com_maine
using btree(ranked_rate_array_id);

-- make sure no nulls
SELECT count(*)
FROM diffusion_data_shared.pt_ranked_rate_array_lkup_com_maine
where ranked_rate_array_id is null;

------------------------------------------------------------------------------------------------------------
-- add the ranked_rate_array_id back to the main pt table
UPDATE diffusion_shared.pt_grid_us_com a
set ranked_rate_array_id = b.ranked_rate_array_id
from diffusion_data_shared.pt_ranked_rate_array_lkup_com_maine b
where a.gid = b.pt_gid;
-- ** make sure to update microdata and pt join view to account for ranked_rate_array_id now **

------------------------------------------------------------------------------------------------------------
-- unnest the unique ranked rate arrays into normal table structure
INSERT INTO diffusion_shared.ranked_rate_array_lkup_com
SELECT ranked_rate_array_id, 
	unnest(rate_id_alias_array) as rate_id_alias, 
	unnest(rank_array) as rank
FROM diffusion_data_shared.unique_ranked_rate_arrays_com_maine;
-- 30 rows added

-- make sure no overlaps with old ranke_rate_array_ids
SELECT *
FROM diffusion_shared.ranked_rate_array_lkup_com a
innER JOIN diffusion_data_shared.unique_ranked_rate_arrays_com_maine b
ON a.ranked_rate_array_id = b.ranked_rate_array_id;
--30 rows, all set
------------------------------------------------------------------------------------------------------------
-- *********************************************************************************************************

------------------------------------------------------------------------------------------------------------
-- RESIDENTIAL
------------------------------------------------------------------------------------------------------------
-- group the ranked urdb rates into arrays for each individual point 
DROP TABLE IF EXISTS diffusion_data_shared.pt_ranked_rate_arrays_com_maine;
CREATE TABLE diffusion_data_shared.pt_ranked_rate_arrays_res_maine AS
SELECT a.pt_gid, 
	array_agg(a.rate_id_alias order by a.rank asc, a.rate_id_alias asc) as rate_id_alias_array,
	array_agg(a.rank order by a.rank asc, a.rate_id_alias asc) as rank_array
FROM diffusion_data_shared.pt_ranked_rates_lkup_res_maine a
GROUP BY pt_gid;
-- 40714 rows

-- check that the row count matches the row count of diffusion_shared.pt_grid_us_res_new
SELECT count(*)
FROM diffusion_shared.pt_grid_us_res a
LEFT JOIN diffusion_shared.county_geom b
ON a.county_id = b.county_id
where b.state_abbr = 'ME';
-- 40714

-- make sure there are no emtpy arrays
select count(*)
FROM diffusion_data_shared.pt_ranked_rate_arrays_res_maine
where rate_id_alias_array is null;
-- 0
select count(*)
FROM diffusion_data_shared.pt_ranked_rate_arrays_res_maine
where rate_id_alias_array = '{}';
-- 0
-- all set

-- create indices
CREATE INDEX pt_ranked_rate_arrays_res_maine_rate_id_btree 
ON diffusion_data_shared.pt_ranked_rate_arrays_res_maine
using btree(rate_id_alias_array);

CREATE INDEX pt_ranked_rate_arrays_res_maine_rank_btree 
ON diffusion_data_shared.pt_ranked_rate_arrays_res_maine
using btree(rank_array);

CREATE INDEX pt_ranked_rate_arrays_res_maine_gid_btree 
ON diffusion_data_shared.pt_ranked_rate_arrays_res_maine
using btree(pt_gid);

------------------------------------------------------------------------------------------------------------
-- find the distinct ranked rate arrays across all points
DROP TABLE IF EXISTS diffusion_data_shared.unique_ranked_rate_arrays_res_maine;
CREATE TABLE diffusion_data_shared.unique_ranked_rate_arrays_res_maine AS
SELECT rate_id_alias_array, rank_array
FROM diffusion_data_shared.pt_ranked_rate_arrays_res_maine
GROUP BY rate_id_alias_array, rank_array;
-- 5 rows

-- add a unique id for each unique ranked rate array
ALTER TABLE diffusion_data_shared.unique_ranked_rate_arrays_res_maine
ADD ranked_rate_array_id integer;

-- update based off of the diffusion_data_shared.unique_ranked_rate_arrays_res_ranked_rate_array_id_seq
UPDATE diffusion_data_shared.unique_ranked_rate_arrays_res_maine
SET ranked_rate_array_id = nextval('diffusion_data_shared.unique_ranked_rate_arrays_res_ranked_rate_array_id_seq');

ALTER TABLE diffusion_data_shared.unique_ranked_rate_arrays_res_maine
ADD primary key (ranked_rate_array_id);

-- create index on the arrays
CREATE INDEX unique_ranked_rate_arrays_res_maine_rate_id_btree
ON diffusion_data_shared.unique_ranked_rate_arrays_res_maine 
USING btree(rate_id_alias_array);

CREATE INDEX unique_ranked_rate_arrays_res_maine_rank_btree
ON diffusion_data_shared.unique_ranked_rate_arrays_res_maine 
USING btree(rank_array);

------------------------------------------------------------------------------------------------------------
-- create lookup table for each point to a ranked_rate_array_id
DROP TABLE IF EXISTS diffusion_data_shared.pt_ranked_rate_array_lkup_res_maine;
CREATE TABLE diffusion_data_shared.pt_ranked_rate_array_lkup_res_maine as
SELECT a.pt_gid, b.ranked_rate_array_id
FROM diffusion_data_shared.pt_ranked_rate_arrays_res_maine a
LEFT JOIN diffusion_data_shared.unique_ranked_rate_arrays_res_maine b
ON a.rate_id_alias_array = b.rate_id_alias_array
and a.rank_array = b.rank_array;
-- 40714 rows

-- check that the row count matches the row count of diffusion_shared.pt_grid_us_res_new
SELECT count(*)
FROM diffusion_shared.pt_grid_us_res a
LEFT JOIN diffusion_shared.county_geom b
ON a.county_id = b.county_id
where b.state_abbr = 'ME';
-- 40714

-- add primary key
ALTER TABLE diffusion_data_shared.pt_ranked_rate_array_lkup_res_maine
ADD PRIMARY KEY (pt_gid);

-- add index
CREATE INDEX pt_ranked_rate_array_lkup_res_maine_rate_array_btree
ON diffusion_data_shared.pt_ranked_rate_array_lkup_res_maine
using btree(ranked_rate_array_id);

-- make sure no nulls
SELECT count(*)
FROM diffusion_data_shared.pt_ranked_rate_array_lkup_res_maine
where ranked_rate_array_id is null;

------------------------------------------------------------------------------------------------------------
-- add the ranked_rate_array_id back to the main pt table
UPDATE diffusion_shared.pt_grid_us_res a
set ranked_rate_array_id = b.ranked_rate_array_id
from diffusion_data_shared.pt_ranked_rate_array_lkup_res_maine b
where a.gid = b.pt_gid;
-- ** make sure to update microdata and pt join view to account for ranked_rate_array_id now **

------------------------------------------------------------------------------------------------------------
-- unnest the unique ranked rate arrays into normal table structure
INSERT INTO diffusion_shared.ranked_rate_array_lkup_res
SELECT ranked_rate_array_id, 
	unnest(rate_id_alias_array) as rate_id_alias, 
	unnest(rank_array) as rank
FROM diffusion_data_shared.unique_ranked_rate_arrays_res_maine;
-- 15 rows added

-- make sure no overlaps with old ranke_rate_array_ids
SELECT *
FROM diffusion_shared.ranked_rate_array_lkup_res a
innER JOIN diffusion_data_shared.unique_ranked_rate_arrays_res_maine b
ON a.ranked_rate_array_id = b.ranked_rate_array_id;
--15 rows, all set
------------------------------------------------------------------------------------------------------------
-- *********************************************************************************************************


------------------------------------------------------------------------------------------------------------
-- INDUSTRIAL
------------------------------------------------------------------------------------------------------------
-- group the ranked urdb rates into arrays for each individual point 
DROP TABLE IF EXISTS diffusion_data_shared.pt_ranked_rate_arrays_ind_maine;
CREATE TABLE diffusion_data_shared.pt_ranked_rate_arrays_ind_maine AS
SELECT a.pt_gid, 
	array_agg(a.rate_id_alias order by a.rank asc, a.rate_id_alias asc) as rate_id_alias_array,
	array_agg(a.rank order by a.rank asc, a.rate_id_alias asc) as rank_array
FROM diffusion_data_shared.pt_ranked_rates_lkup_ind_maine a
GROUP BY pt_gid;
-- 5944 rows

-- check that the row count matches the row count of diffusion_shared.pt_grid_us_ind_new
SELECT count(*)
FROM diffusion_shared.pt_grid_us_ind a
LEFT JOIN diffusion_shared.county_geom b
ON a.county_id = b.county_id
where b.state_abbr = 'ME';
-- 5944

-- make sure there are no emtpy arrays
select count(*)
FROM diffusion_data_shared.pt_ranked_rate_arrays_ind_maine
where rate_id_alias_array is null;
-- 0
select count(*)
FROM diffusion_data_shared.pt_ranked_rate_arrays_ind_maine
where rate_id_alias_array = '{}';
-- 0
-- all set

-- create indices
CREATE INDEX pt_ranked_rate_arrays_ind_maine_rate_id_btree 
ON diffusion_data_shared.pt_ranked_rate_arrays_ind_maine
using btree(rate_id_alias_array);

CREATE INDEX pt_ranked_rate_arrays_ind_maine_rank_btree 
ON diffusion_data_shared.pt_ranked_rate_arrays_ind_maine
using btree(rank_array);

CREATE INDEX pt_ranked_rate_arrays_ind_maine_gid_btree 
ON diffusion_data_shared.pt_ranked_rate_arrays_ind_maine
using btree(pt_gid);

------------------------------------------------------------------------------------------------------------
-- find the distinct ranked rate arrays across all points
DROP TABLE IF EXISTS diffusion_data_shared.unique_ranked_rate_arrays_ind_maine;
CREATE TABLE diffusion_data_shared.unique_ranked_rate_arrays_ind_maine AS
SELECT rate_id_alias_array, rank_array
FROM diffusion_data_shared.pt_ranked_rate_arrays_ind_maine
GROUP BY rate_id_alias_array, rank_array;
-- 4 rows

-- add a unique id for each unique ranked rate array
ALTER TABLE diffusion_data_shared.unique_ranked_rate_arrays_ind_maine
ADD ranked_rate_array_id integer;

-- update based off of the diffusion_data_shared.unique_ranked_rate_arrays_ind_ranked_rate_array_id_seq
UPDATE diffusion_data_shared.unique_ranked_rate_arrays_ind_maine
SET ranked_rate_array_id = nextval('diffusion_data_shared.unique_ranked_rate_arrays_ind_ranked_rate_array_id_seq');

ALTER TABLE diffusion_data_shared.unique_ranked_rate_arrays_ind_maine
ADD primary key (ranked_rate_array_id);

-- create index on the arrays
CREATE INDEX unique_ranked_rate_arrays_ind_maine_rate_id_btree
ON diffusion_data_shared.unique_ranked_rate_arrays_ind_maine 
USING btree(rate_id_alias_array);

CREATE INDEX unique_ranked_rate_arrays_ind_maine_rank_btree
ON diffusion_data_shared.unique_ranked_rate_arrays_ind_maine 
USING btree(rank_array);

------------------------------------------------------------------------------------------------------------
-- create lookup table for each point to a ranked_rate_array_id
DROP TABLE IF EXISTS diffusion_data_shared.pt_ranked_rate_array_lkup_ind_maine;
CREATE TABLE diffusion_data_shared.pt_ranked_rate_array_lkup_ind_maine as
SELECT a.pt_gid, b.ranked_rate_array_id
FROM diffusion_data_shared.pt_ranked_rate_arrays_ind_maine a
LEFT JOIN diffusion_data_shared.unique_ranked_rate_arrays_ind_maine b
ON a.rate_id_alias_array = b.rate_id_alias_array
and a.rank_array = b.rank_array;
-- 5944 rows

-- check that the row count matches the row count of diffusion_shared.pt_grid_us_ind_new
SELECT count(*)
FROM diffusion_shared.pt_grid_us_ind a
LEFT JOIN diffusion_shared.county_geom b
ON a.county_id = b.county_id
where b.state_abbr = 'ME';
-- 5944

-- add primary key
ALTER TABLE diffusion_data_shared.pt_ranked_rate_array_lkup_ind_maine
ADD PRIMARY KEY (pt_gid);

-- add index
CREATE INDEX pt_ranked_rate_array_lkup_ind_maine_rate_array_btree
ON diffusion_data_shared.pt_ranked_rate_array_lkup_ind_maine
using btree(ranked_rate_array_id);

-- make sure no nulls
SELECT count(*)
FROM diffusion_data_shared.pt_ranked_rate_array_lkup_ind_maine
where ranked_rate_array_id is null;

------------------------------------------------------------------------------------------------------------
-- add the ranked_rate_array_id back to the main pt table
UPDATE diffusion_shared.pt_grid_us_ind a
set ranked_rate_array_id = b.ranked_rate_array_id
from diffusion_data_shared.pt_ranked_rate_array_lkup_ind_maine b
where a.gid = b.pt_gid;
-- ** make sure to update microdata and pt join view to account for ranked_rate_array_id now **

------------------------------------------------------------------------------------------------------------
-- unnest the unique ranked rate arrays into normal table structure
INSERT INTO diffusion_shared.ranked_rate_array_lkup_ind
SELECT ranked_rate_array_id, 
	unnest(rate_id_alias_array) as rate_id_alias, 
	unnest(rank_array) as rank
FROM diffusion_data_shared.unique_ranked_rate_arrays_ind_maine;
-- 16 rows added

-- make sure no overlaps with old ranke_rate_array_ids
SELECT *
FROM diffusion_shared.ranked_rate_array_lkup_ind a
innER JOIN diffusion_data_shared.unique_ranked_rate_arrays_ind_maine b
ON a.ranked_rate_array_id = b.ranked_rate_array_id;
--16 rows, all set
------------------------------------------------------------------------------------------------------------
-- *********************************************************************************************************

