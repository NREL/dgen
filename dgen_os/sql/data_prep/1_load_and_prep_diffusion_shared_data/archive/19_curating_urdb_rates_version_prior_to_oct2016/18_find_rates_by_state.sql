-- create 
-- RESIDENTIAL
DROP TABLE IF EXISTS diffusion_shared.urdb_rates_by_state_res;
CREATE TABLE diffusion_shared.urdb_rates_by_state_res AS
SELECT a.state_abbr, a.rate_id_alias
from diffusion_shared.pt_rate_isect_lkup_res a
group by a.state_abbr, a.rate_id_alias;
-- COMMERCIAL
DROP TABLE IF EXISTS diffusion_shared.urdb_rates_by_state_com;
CREATE TABLE diffusion_shared.urdb_rates_by_state_com AS
SELECT a.state_abbr, a.rate_id_alias
from diffusion_shared.pt_rate_isect_lkup_com a
group by a.state_abbr, a.rate_id_alias;
-- INDUSTRIAL
DROP TABLE IF EXISTS diffusion_shared.urdb_rates_by_state_ind;
CREATE TABLE diffusion_shared.urdb_rates_by_state_ind AS
SELECT a.state_abbr, a.rate_id_alias
from diffusion_shared.pt_rate_isect_lkup_ind a
group by a.state_abbr, a.rate_id_alias;
----------------------------------------------------------------------

-- add indices
-- RESIDENTIAL
CREATE INDEX urdb_rates_by_state_res_rate_id_alias_btree
ON diffusion_shared.urdb_rates_by_state_res
using btree(rate_id_alias);

CREATE INDEX urdb_rates_by_state_res_state_abbr_btree
ON diffusion_shared.urdb_rates_by_state_res
using btree(state_abbr);

--COMMERCIAL
CREATE INDEX urdb_rates_by_state_com_rate_id_alias_btree
ON diffusion_shared.urdb_rates_by_state_com
using btree(rate_id_alias);

CREATE INDEX urdb_rates_by_state_com_state_abbr_btree
ON diffusion_shared.urdb_rates_by_state_com
using btree(state_abbr);

-- INDUSTRIAL
CREATE INDEX urdb_rates_by_state_ind_rate_id_alias_btree
ON diffusion_shared.urdb_rates_by_state_ind
using btree(rate_id_alias);

CREATE INDEX urdb_rates_by_state_ind_state_abbr_btree
ON diffusion_shared.urdb_rates_by_state_ind
using btree(state_abbr);
----------------------------------------------------------------------

-- add in demand ranges
-- RESIDENTIAL
-- add columns
ALTER TABLE diffusion_shared.urdb_rates_by_state_res
ADD COLUMN urdb_demand_min numeric,
add column urdb_demand_max numeric;
-- update values
UPDATE diffusion_shared.urdb_rates_by_state_res a
SET (urdb_demand_min, urdb_demand_max) = (b.demand_min, b.demand_max)
FROM urdb_rates.combined_singular_verified_rates_lookup b
where a.rate_id_alias = b.rate_id_alias
and b.res_com = 'R';
-- make sure no nulls
SELECT *
FROM diffusion_shared.urdb_rates_by_state_res
where urdb_demand_min is null or urdb_demand_max is null;
-- add indices
CREATE INDEX urdb_rates_by_state_res_urdb_demand_min_btree
ON diffusion_shared.urdb_rates_by_state_res
using btree(urdb_demand_min);
--
CREATE INDEX urdb_rates_by_state_res_urdb_demand_max_btree
ON diffusion_shared.urdb_rates_by_state_res
using btree(urdb_demand_max);

-- COMMERCIAL
-- add columns
ALTER TABLE diffusion_shared.urdb_rates_by_state_com
ADD COLUMN urdb_demand_min numeric,
add column urdb_demand_max numeric;
-- update values
UPDATE diffusion_shared.urdb_rates_by_state_com a
SET (urdb_demand_min, urdb_demand_max) = (b.demand_min, b.demand_max)
FROM urdb_rates.combined_singular_verified_rates_lookup b
where a.rate_id_alias = b.rate_id_alias
and b.res_com = 'C';
-- make sure no nulls
SELECT *
FROM diffusion_shared.urdb_rates_by_state_com
where urdb_demand_min is null or urdb_demand_max is null;
-- add indices
CREATE INDEX urdb_rates_by_state_com_urdb_demand_min_btree
ON diffusion_shared.urdb_rates_by_state_com
using btree(urdb_demand_min);
--
CREATE INDEX urdb_rates_by_state_com_urdb_demand_max_btree
ON diffusion_shared.urdb_rates_by_state_com
using btree(urdb_demand_max);

-- INDUSTRIAL
-- add columns
ALTER TABLE diffusion_shared.urdb_rates_by_state_ind
ADD COLUMN urdb_demand_min numeric,
add column urdb_demand_max numeric;
-- update values
UPDATE diffusion_shared.urdb_rates_by_state_ind a
SET (urdb_demand_min, urdb_demand_max) = (b.demand_min, b.demand_max)
FROM urdb_rates.combined_singular_verified_rates_lookup b
where a.rate_id_alias = b.rate_id_alias
and b.res_com = 'C';
-- make sure no nulls
SELECT *
FROM diffusion_shared.urdb_rates_by_state_ind
where urdb_demand_min is null or urdb_demand_max is null;
-- add indices
CREATE INDEX urdb_rates_by_state_ind_urdb_demand_min_btree
ON diffusion_shared.urdb_rates_by_state_ind
using btree(urdb_demand_min);
--
CREATE INDEX urdb_rates_by_state_ind_urdb_demand_max_btree
ON diffusion_shared.urdb_rates_by_state_ind
using btree(urdb_demand_max);
----------------------------------------------------------------------

-- add in rate types (where known)
-- RESIDENTIAL
-- add columns
ALTER TABLE diffusion_shared.urdb_rates_by_state_res
ADD COLUMN rate_type character varying(4);
-- update values
UPDATE diffusion_shared.urdb_rates_by_state_res a
SET rate_type = b.rate_type
FROM urdb_rates.combined_singular_verified_rates_lookup b
where a.rate_id_alias = b.rate_id_alias
and b.res_com = 'R';
-- make sure no nulls
SELECT *
FROM diffusion_shared.urdb_rates_by_state_res
where rate_type is null;
-- add indices
CREATE INDEX urdb_rates_by_state_res_rate_type_btree
ON diffusion_shared.urdb_rates_by_state_res
using btree(rate_type);

-- COMMERCIAL
-- add columns
ALTER TABLE diffusion_shared.urdb_rates_by_state_com
ADD COLUMN rate_type character varying(4);
-- update values
UPDATE diffusion_shared.urdb_rates_by_state_com a
SET rate_type = b.rate_type
FROM urdb_rates.combined_singular_verified_rates_lookup b
where a.rate_id_alias = b.rate_id_alias
and b.res_com = 'C';
-- make sure no nulls
SELECT *
FROM diffusion_shared.urdb_rates_by_state_com
where rate_type is null;
-- add indices
CREATE INDEX urdb_rates_by_state_com_rate_type_btree
ON diffusion_shared.urdb_rates_by_state_com
using btree(rate_type);

-- INDUSTRIAL
-- add columns
ALTER TABLE diffusion_shared.urdb_rates_by_state_ind
ADD COLUMN rate_type character varying(4);
-- update values
UPDATE diffusion_shared.urdb_rates_by_state_ind a
SET rate_type = b.rate_type
FROM urdb_rates.combined_singular_verified_rates_lookup b
where a.rate_id_alias = b.rate_id_alias
and b.res_com = 'C';
-- make sure no nulls
SELECT *
FROM diffusion_shared.urdb_rates_by_state_ind
where rate_type is null;
-- add indices
CREATE INDEX urdb_rates_by_state_ind_rate_type_btree
ON diffusion_shared.urdb_rates_by_state_ind
using btree(rate_type);


----------------------------------------------------------------------
-- check how many rates there are in each state
SELECT state_abbr, count(*)
FROM diffusion_shared.urdb_rates_by_state_ind
GROUP BY state_abbr
order by count;
-- 5 to 75

SELECT state_abbr, count(*)
FROM diffusion_shared.urdb_rates_by_state_com
GROUP BY state_abbr
order by count;
-- 5 to 79

SELECT state_abbr, count(*)
FROM diffusion_shared.urdb_rates_by_state_res
GROUP BY state_abbr
order by count;
-- 4 to 71

-- all 48 states + DC are represented in all cases