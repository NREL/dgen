-- find the unique combinations of ranked rates (some points will have identical rankings)
------------------------------------------------------------------------------------------------------------
-- COMMERCIAL
------------------------------------------------------------------------------------------------------------
-- group the ranked urdb rates into arrays for each individual point 
DROP TABLE IF EXISTS diffusion_shared_data.pt_ranked_rate_arrays_com;
CREATE TABLE diffusion_shared_data.pt_ranked_rate_arrays_com
(
	pt_gid integer,
	rate_id_alias_array integer[],
	rank_array integer[]
);

SELECT parsel_2('dav-gis','mgleason','mgleason',
		'diffusion_shared.pt_ranked_rates_lkup_com','pt_gid',
		'SELECT a.pt_gid, 
			array_agg(a.rate_id_alias order by a.rank asc, a.rate_id_alias asc) as rate_id_alias_array,
			array_agg(a.rank order by a.rank asc, a.rate_id_alias asc) as rank_array
		FROM diffusion_shared.pt_ranked_rates_lkup_com a
		GROUP BY pt_gid;',
		'diffusion_shared_data.pt_ranked_rate_arrays_com', 'a', 22);

-- check that the row count matches the row count of diffusion_shared.pt_grid_us_com_new
SELECT count(*)
FROM diffusion_shared.pt_grid_us_com_new;
-- 1603958

select count(*)
FROM diffusion_shared_data.pt_ranked_rate_arrays_com;
-- 1603958

-- make sure there are no emtpy arrays
select count(*)
FROM diffusion_shared_data.pt_ranked_rate_arrays_com
where rate_id_alias_array is null;
-- 0
select count(*)
FROM diffusion_shared_data.pt_ranked_rate_arrays_com
where rate_id_alias_array = '{}';
-- 0
-- all set

-- create indices
CREATE INDEX pt_ranked_rate_arrays_com_rate_id_btree 
ON diffusion_shared_data.pt_ranked_rate_arrays_com
using btree(rate_id_alias_array);

CREATE INDEX pt_ranked_rate_arrays_com_rank_btree 
ON diffusion_shared_data.pt_ranked_rate_arrays_com
using btree(rank_array);

CREATE INDEX pt_ranked_rate_arrays_com_gid_btree 
ON diffusion_shared_data.pt_ranked_rate_arrays_com
using btree(pt_gid);

------------------------------------------------------------------------------------------------------------
-- find the distinct ranked rate arrays across all points
DROP TABLE IF EXISTS diffusion_shared_data.unique_ranked_rate_arrays_com;
CREATE TABLE diffusion_shared_data.unique_ranked_rate_arrays_com AS
SELECT rate_id_alias_array, rank_array
FROM diffusion_shared_data.pt_ranked_rate_arrays_com
GROUP BY rate_id_alias_array, rank_array;
-- 56073 rows

-- add a unique id for each unique ranked rate array
ALTER TABLE diffusion_shared_data.unique_ranked_rate_arrays_com
ADD ranked_rate_array_id serial;

ALTER TABLE diffusion_shared_data.unique_ranked_rate_arrays_com
ADD primary key (ranked_rate_array_id);

-- create index on the arrays
CREATE INDEX unique_ranked_rate_arrays_com_rate_id_btree
ON diffusion_shared_data.unique_ranked_rate_arrays_com 
USING btree(rate_id_alias_array);

CREATE INDEX unique_ranked_rate_arrays_com_rank_btree
ON diffusion_shared_data.unique_ranked_rate_arrays_com 
USING btree(rank_array);



------------------------------------------------------------------------------------------------------------
-- create lookup table for each point to a ranked_rate_array_id
DROP TABLE IF EXISTS diffusion_shared_data.pt_ranked_rate_array_lkup_com;
CREATE TABLE diffusion_shared_data.pt_ranked_rate_array_lkup_com
(
	pt_gid integer,
	ranked_rate_array_id integer
);


SELECT parsel_2('dav-gis','mgleason','mgleason',
		'diffusion_shared_data.pt_ranked_rate_arrays_com','pt_gid',
		'SELECT a.pt_gid, b.ranked_rate_array_id
		FROM diffusion_shared_data.pt_ranked_rate_arrays_com a
		LEFT JOIN diffusion_shared_data.unique_ranked_rate_arrays_com b
		ON a.rate_id_alias_array = b.rate_id_alias_array
		and a.rank_array = b.rank_array;',
		'diffusion_shared_data.pt_ranked_rate_array_lkup_com', 'a', 22);

select count(*)
FROM diffusion_shared_data.pt_ranked_rate_array_lkup_com;
-- 1603958 rows

select count(*)
FROM diffusion_shared.pt_grid_us_com_new;
-- matches pt grid com (1603958)

-- add primary key
ALTER TABLE diffusion_shared_data.pt_ranked_rate_array_lkup_com
ADD PRIMARY KEY (pt_gid);

-- add index
CREATE INDEX pt_ranked_rate_array_lkup_com_rate_array_btree
ON diffusion_shared_data.pt_ranked_rate_array_lkup_com
using btree(ranked_rate_array_id);

-- make sure no nulls
SELECT count(*)
FROM diffusion_shared_data.pt_ranked_rate_array_lkup_com
where ranked_rate_array_id is null;

------------------------------------------------------------------------------------------------------------
-- add the ranked_rate_array_id back to the main pt table
ALTER TABLE diffusion_shared.pt_grid_us_com_new
ADD COLUMN ranked_rate_array_id integer;

UPDATE diffusion_shared.pt_grid_us_com_new a
set ranked_rate_array_id = b.ranked_rate_array_id
from diffusion_shared_data.pt_ranked_rate_array_lkup_com b
where a.gid = b.pt_gid;
-- ** make sure to update microdata and pt join view to account for ranked_rate_array_id now **

-- add an index
CREATE INDEX pt_grid_us_com_new_ranked_rate_array_id_btree
ON diffusion_shared.pt_grid_us_com_new
USING btree(ranked_rate_array_id);

-- check no nulls
SELECT count(*)
FROM diffusion_shared.pt_grid_us_com_new
where ranked_rate_array_id is null;

VACUUM ANALYZE diffusion_shared.pt_grid_us_com_new;
------------------------------------------------------------------------------------------------------------
-- unnest the unique ranked rate arrays into normal table structure
DROP TABLE IF EXISTS diffusion_shared.ranked_rate_array_lkup_com;
CREATE TABLE diffusion_shared.ranked_rate_array_lkup_com as
SELECT ranked_rate_array_id, 
	unnest(rate_id_alias_array) as rate_id_alias, 
	unnest(rank_array) as rank
FROM diffusion_shared_data.unique_ranked_rate_arrays_com;
-- 2,665,185

-- add indices
CREATE INDEX ranked_rate_array_lkup_com_ranked_rate_array_id_btree
ON diffusion_shared.ranked_rate_array_lkup_com
using btree(ranked_rate_array_id);

CREATE INDEX ranked_rate_array_lkup_com_rate_id_alias_btree
ON diffusion_shared.ranked_rate_array_lkup_com
using btree(rate_id_alias);

CREATE INDEX ranked_rate_array_lkup_com_rank_btree
ON diffusion_shared.ranked_rate_array_lkup_com
using btree(rank);
------------------------------------------------------------------------------------------------------------



-- do some testing:
with a AS
(
	SELECT a.county_id, a.bin_id, 
		a.ranked_rate_array_id,
		a.max_demand_kw, 
		a.state_abbr,
		b.rate_id_alias,
		c.rank as rate_rank,
		d.rate_type
	FROM diffusion_solar.pt_com_best_option_each_year a
	LEFT JOIN diffusion_shared.urdb_rates_by_state_com b
	ON a.max_demand_kw <= b.urdb_demand_max
	and a.max_demand_kw >= b.urdb_demand_min
	and a.state_abbr = b.state_abbr
	LEFT JOIN diffusion_shared.ranked_rate_array_lkup_com c
	ON a.ranked_rate_array_id = c.ranked_rate_array_id
	and b.rate_id_alias = c.rate_id_alias
	LEFT JOIN urdb_rates.combined_singular_verified_rates_lookup d
	on b.rate_id_alias = d.rate_id_alias
	and d.res_com = 'C'
	where a.year = 2014
),
b as
(
	SELECT *, row_number() OVER (partition by county_id, bin_id order by rate_rank asc) as rank
		-- *** THIS SHOULD BE A RANK WITH A SUBSEQUENT TIE BREAKER BASED ON USER DEFINED RATE TYPE PROBABILITIES
	FROM a
)
SELECT *
FROM b 
where rank = 1;

select distinct(rate_type)
FROM urdb_rates.combined_singular_verified_rates_lookup
order by 1;



------------------------------------------------------------------------------------------------------------
-- RESIDENTIAL
------------------------------------------------------------------------------------------------------------
-- group the ranked urdb rates into arrays for each individual point 
DROP TABLE IF EXISTS diffusion_shared_data.pt_ranked_rate_arrays_res;
CREATE TABLE diffusion_shared_data.pt_ranked_rate_arrays_res
(
	pt_gid integer,
	rate_id_alias_array integer[],
	rank_array integer[]
);

SELECT parsel_2('dav-gis','mgleason','mgleason',
		'diffusion_shared.pt_ranked_rates_lkup_res','pt_gid',
		'SELECT a.pt_gid, 
			array_agg(a.rate_id_alias order by a.rank asc, a.rate_id_alias asc) as rate_id_alias_array,
			array_agg(a.rank order by a.rank asc, a.rate_id_alias asc) as rank_array
		FROM diffusion_shared.pt_ranked_rates_lkup_res a
		GROUP BY pt_gid;',
		'diffusion_shared_data.pt_ranked_rate_arrays_res', 'a', 22);

-- check that the row count matches the row count of diffusion_shared.pt_grid_us_com_new
SELECT count(*)
FROM diffusion_shared.pt_grid_us_res_new;
-- 5751859

select count(*)
FROM diffusion_shared_data.pt_ranked_rate_arrays_res;
-- 5751859

-- make sure there are no emtpy arrays
select count(*)
FROM diffusion_shared_data.pt_ranked_rate_arrays_res
where rate_id_alias_array is null;
-- 0
select count(*)
FROM diffusion_shared_data.pt_ranked_rate_arrays_res
where rate_id_alias_array = '{}';
-- 0
-- all set

-- create indices
CREATE INDEX pt_ranked_rate_arrays_res_rate_id_btree 
ON diffusion_shared_data.pt_ranked_rate_arrays_res
using btree(rate_id_alias_array);

CREATE INDEX pt_ranked_rate_arrays_res_rank_btree 
ON diffusion_shared_data.pt_ranked_rate_arrays_res
using btree(rank_array);

CREATE INDEX pt_ranked_rate_arrays_res_gid_btree 
ON diffusion_shared_data.pt_ranked_rate_arrays_res
using btree(pt_gid);

------------------------------------------------------------------------------------------------------------
-- find the distinct ranked rate arrays across all points
DROP TABLE IF EXISTS diffusion_shared_data.unique_ranked_rate_arrays_res;
CREATE TABLE diffusion_shared_data.unique_ranked_rate_arrays_res AS
SELECT rate_id_alias_array, rank_array
FROM diffusion_shared_data.pt_ranked_rate_arrays_res
GROUP BY rate_id_alias_array, rank_array;
-- 644052 rows

-- add a unique id for each unique ranked rate array
ALTER TABLE diffusion_shared_data.unique_ranked_rate_arrays_res
ADD ranked_rate_array_id serial;

ALTER TABLE diffusion_shared_data.unique_ranked_rate_arrays_res
ADD primary key (ranked_rate_array_id);

-- create index on the arrays
CREATE INDEX unique_ranked_rate_arrays_res_rate_id_btree
ON diffusion_shared_data.unique_ranked_rate_arrays_res 
USING btree(rate_id_alias_array);

CREATE INDEX unique_ranked_rate_arrays_res_rank_btree
ON diffusion_shared_data.unique_ranked_rate_arrays_res 
USING btree(rank_array);



------------------------------------------------------------------------------------------------------------
-- create lookup table for each point to a ranked_rate_array_id
DROP TABLE IF EXISTS diffusion_shared_data.pt_ranked_rate_array_lkup_res;
CREATE TABLE diffusion_shared_data.pt_ranked_rate_array_lkup_res
(
	pt_gid integer,
	ranked_rate_array_id integer
);


SELECT parsel_2('dav-gis','mgleason','mgleason',
		'diffusion_shared_data.pt_ranked_rate_arrays_res','pt_gid',
		'SELECT a.pt_gid, b.ranked_rate_array_id
		FROM diffusion_shared_data.pt_ranked_rate_arrays_res a
		LEFT JOIN diffusion_shared_data.unique_ranked_rate_arrays_res b
		ON a.rate_id_alias_array = b.rate_id_alias_array
		and a.rank_array = b.rank_array;',
		'diffusion_shared_data.pt_ranked_rate_array_lkup_res', 'a', 22);

select count(*)
FROM diffusion_shared_data.pt_ranked_rate_array_lkup_res;
-- 5751859 rows
-- matches pt grid res (5751859)

-- add primary key
ALTER TABLE diffusion_shared_data.pt_ranked_rate_array_lkup_res
ADD PRIMARY KEY (pt_gid);

-- add index
CREATE INDEX pt_ranked_rate_array_lkup_res_rate_array_btree
ON diffusion_shared_data.pt_ranked_rate_array_lkup_res
using btree(ranked_rate_array_id);

-- make sure no nulls
SELECT count(*)
FROM diffusion_shared_data.pt_ranked_rate_array_lkup_res
where ranked_rate_array_id is null;

------------------------------------------------------------------------------------------------------------
-- add the ranked_rate_array_id back to the main pt table
ALTER TABLE diffusion_shared.pt_grid_us_res_new
ADD COLUMN ranked_rate_array_id integer;

UPDATE diffusion_shared.pt_grid_us_res_new a
set ranked_rate_array_id = b.ranked_rate_array_id
from diffusion_shared_data.pt_ranked_rate_array_lkup_res b
where a.gid = b.pt_gid;

-- add an index
CREATE INDEX pt_grid_us_res_new_ranked_rate_array_id_btree
ON diffusion_shared.pt_grid_us_res_new
USING btree(ranked_rate_array_id);

-- check no nulls
SELECT count(*)
FROM diffusion_shared.pt_grid_us_res_new
where ranked_rate_array_id is null;

VACUUM ANALYZE diffusion_shared.pt_grid_us_res_new;
-- ** make sure to update microdata and pt join view to account for ranked_rate_array_id now **
------------------------------------------------------------------------------------------------------------
-- unnest the unique ranked rate arrays into normal table structure
DROP TABLE IF EXISTS diffusion_shared.ranked_rate_array_lkup_res;
CREATE TABLE diffusion_shared.ranked_rate_array_lkup_res as
SELECT ranked_rate_array_id, 
	unnest(rate_id_alias_array) as rate_id_alias, 
	unnest(rank_array) as rank
FROM diffusion_shared_data.unique_ranked_rate_arrays_res;
-- 35,740,171

-- add indices
CREATE INDEX ranked_rate_array_lkup_res_ranked_rate_array_id_btree
ON diffusion_shared.ranked_rate_array_lkup_res
using btree(ranked_rate_array_id);

CREATE INDEX ranked_rate_array_lkup_res_rate_id_alias_btree
ON diffusion_shared.ranked_rate_array_lkup_res
using btree(rate_id_alias);

CREATE INDEX ranked_rate_array_lkup_res_rank_btree
ON diffusion_shared.ranked_rate_array_lkup_res
using btree(rank);
------------------------------------------------------------------------------------------------------------


------------------------------------------------------------------------------------------------------------
-- INDUSTRIAL
------------------------------------------------------------------------------------------------------------
-- group the ranked urdb rates into arrays for each individual point 
DROP TABLE IF EXISTS diffusion_shared_data.pt_ranked_rate_arrays_ind;
CREATE TABLE diffusion_shared_data.pt_ranked_rate_arrays_ind
(
	pt_gid integer,
	rate_id_alias_array integer[],
	rank_array integer[]
);

SELECT parsel_2('dav-gis','mgleason','mgleason',
		'diffusion_shared.pt_ranked_rates_lkup_ind','pt_gid',
		'SELECT a.pt_gid, 
			array_agg(a.rate_id_alias order by a.rank asc, a.rate_id_alias asc) as rate_id_alias_array,
			array_agg(a.rank order by a.rank asc, a.rate_id_alias asc) as rank_array
		FROM diffusion_shared.pt_ranked_rates_lkup_ind a
		GROUP BY pt_gid;',
		'diffusion_shared_data.pt_ranked_rate_arrays_ind', 'a', 22);
-- **

-- check that the row count matches the row count of diffusion_shared.pt_grid_us_com_new
SELECT count(*)
FROM diffusion_shared.pt_grid_us_ind_new;
-- 1145187

select count(*)
FROM diffusion_shared_data.pt_ranked_rate_arrays_ind;
-- 1145187

-- make sure there are no emtpy arrays
select count(*)
FROM diffusion_shared_data.pt_ranked_rate_arrays_ind
where rate_id_alias_array is null;
-- 0
select count(*)
FROM diffusion_shared_data.pt_ranked_rate_arrays_ind
where rate_id_alias_array = '{}';
-- 0
-- all set

-- create indices
CREATE INDEX pt_ranked_rate_arrays_ind_rate_id_btree 
ON diffusion_shared_data.pt_ranked_rate_arrays_ind
using btree(rate_id_alias_array);

CREATE INDEX pt_ranked_rate_arrays_ind_rank_btree 
ON diffusion_shared_data.pt_ranked_rate_arrays_ind
using btree(rank_array);

CREATE INDEX pt_ranked_rate_arrays_ind_gid_btree 
ON diffusion_shared_data.pt_ranked_rate_arrays_ind
using btree(pt_gid);

------------------------------------------------------------------------------------------------------------
-- find the distinct ranked rate arrays across all points
DROP TABLE IF EXISTS diffusion_shared_data.unique_ranked_rate_arrays_ind;
CREATE TABLE diffusion_shared_data.unique_ranked_rate_arrays_ind AS
SELECT rate_id_alias_array, rank_array
FROM diffusion_shared_data.pt_ranked_rate_arrays_ind
GROUP BY rate_id_alias_array, rank_array;
-- 85356 rows

-- add a unique id for each unique ranked rate array
ALTER TABLE diffusion_shared_data.unique_ranked_rate_arrays_ind
ADD ranked_rate_array_id serial;

ALTER TABLE diffusion_shared_data.unique_ranked_rate_arrays_ind
ADD primary key (ranked_rate_array_id);

-- create index on the arrays
CREATE INDEX unique_ranked_rate_arrays_ind_rate_id_btree
ON diffusion_shared_data.unique_ranked_rate_arrays_ind 
USING btree(rate_id_alias_array);

CREATE INDEX unique_ranked_rate_arrays_ind_rank_btree
ON diffusion_shared_data.unique_ranked_rate_arrays_ind 
USING btree(rank_array);



------------------------------------------------------------------------------------------------------------
-- create lookup table for each point to a ranked_rate_array_id
DROP TABLE IF EXISTS diffusion_shared_data.pt_ranked_rate_array_lkup_ind;
CREATE TABLE diffusion_shared_data.pt_ranked_rate_array_lkup_ind
(
	pt_gid integer,
	ranked_rate_array_id integer
);


SELECT parsel_2('dav-gis','mgleason','mgleason',
		'diffusion_shared_data.pt_ranked_rate_arrays_ind','pt_gid',
		'SELECT a.pt_gid, b.ranked_rate_array_id
		FROM diffusion_shared_data.pt_ranked_rate_arrays_ind a
		LEFT JOIN diffusion_shared_data.unique_ranked_rate_arrays_ind b
		ON a.rate_id_alias_array = b.rate_id_alias_array
		and a.rank_array = b.rank_array;',
		'diffusion_shared_data.pt_ranked_rate_array_lkup_ind', 'a', 22);

select count(*)
FROM diffusion_shared_data.pt_ranked_rate_array_lkup_ind;
-- 1145187 rows
-- matches pt grid ind (1145187)

-- add primary key
ALTER TABLE diffusion_shared_data.pt_ranked_rate_array_lkup_ind
ADD PRIMARY KEY (pt_gid);

-- add index
CREATE INDEX pt_ranked_rate_array_lkup_ind_rate_array_btree
ON diffusion_shared_data.pt_ranked_rate_array_lkup_ind
using btree(ranked_rate_array_id);

-- make sure no nulls
SELECT count(*)
FROM diffusion_shared_data.pt_ranked_rate_array_lkup_ind
where ranked_rate_array_id is null;

------------------------------------------------------------------------------------------------------------
-- add the ranked_rate_array_id back to the main pt table
ALTER TABLE diffusion_shared.pt_grid_us_ind_new
ADD COLUMN ranked_rate_array_id integer;

UPDATE diffusion_shared.pt_grid_us_ind_new a
set ranked_rate_array_id = b.ranked_rate_array_id
from diffusion_shared_data.pt_ranked_rate_array_lkup_ind b
where a.gid = b.pt_gid;

-- add an index
CREATE INDEX pt_grid_us_ind_new_ranked_rate_array_id_btree
ON diffusion_shared.pt_grid_us_ind_new
USING btree(ranked_rate_array_id);

-- check no nulls
SELECT count(*)
FROM diffusion_shared.pt_grid_us_ind_new
where ranked_rate_array_id is null;

VACUUM ANALYZE diffusion_shared.pt_grid_us_ind_new;
-- ** make sure to update microdata and pt join view to account for ranked_rate_array_id now **
------------------------------------------------------------------------------------------------------------
-- unnest the unique ranked rate arrays into normal table structure
DROP TABLE IF EXISTS diffusion_shared.ranked_rate_array_lkup_ind;
CREATE TABLE diffusion_shared.ranked_rate_array_lkup_ind as
SELECT ranked_rate_array_id, 
	unnest(rate_id_alias_array) as rate_id_alias, 
	unnest(rank_array) as rank
FROM diffusion_shared_data.unique_ranked_rate_arrays_ind;
-- 4,375,650

-- add indices
CREATE INDEX ranked_rate_array_lkup_ind_ranked_rate_array_id_btree
ON diffusion_shared.ranked_rate_array_lkup_ind
using btree(ranked_rate_array_id);

CREATE INDEX ranked_rate_array_lkup_ind_rate_id_alias_btree
ON diffusion_shared.ranked_rate_array_lkup_ind
using btree(rate_id_alias);

CREATE INDEX ranked_rate_array_lkup_ind_rank_btree
ON diffusion_shared.ranked_rate_array_lkup_ind
using btree(rank);
------------------------------------------------------------------------------------------------------------
