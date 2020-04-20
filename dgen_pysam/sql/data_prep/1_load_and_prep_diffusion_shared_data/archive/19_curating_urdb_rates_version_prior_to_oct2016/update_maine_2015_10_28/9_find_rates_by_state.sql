set role 'diffusion-writers';
-- RESIDENTIAL
DROP TABLE IF EXISTS diffusion_data_shared.urdb_rates_by_state_res_maine;
CREATE TABLE diffusion_data_shared.urdb_rates_by_state_res_maine AS
SELECT 'ME'::character varying(2) as state_abbr, a.rate_id_alias, 
	demand_min as urdb_demand_min,
	demand_max as urdb_demand_max,
	'UNK'::TEXT as rate_type,
	pct_of_state_sector_cust as pct_of_customers
from  urdb_rates.urdb3_verified_rates_lookup_20151028 a
where state_code = 'ME'
and res_com = 'R';

-- COMMERCIAL
DROP TABLE IF EXISTS diffusion_data_shared.urdb_rates_by_state_com_maine;
CREATE TABLE diffusion_data_shared.urdb_rates_by_state_com_maine AS
SELECT 'ME'::character varying(2) as state_abbr, a.rate_id_alias, 
	demand_min as urdb_demand_min,
	demand_max as urdb_demand_max,
	'UNK'::TEXT as rate_type,
	pct_of_state_sector_cust as pct_of_customers
from  urdb_rates.urdb3_verified_rates_lookup_20151028 a
where state_code = 'ME'
and res_com = 'C';

-- INDUSTRIAL
DROP TABLE IF EXISTS diffusion_data_shared.urdb_rates_by_state_ind_maine;
CREATE TABLE diffusion_data_shared.urdb_rates_by_state_ind_maine AS
SELECT 'ME'::character varying(2) as state_abbr, a.rate_id_alias, 
	demand_min as urdb_demand_min,
	demand_max as urdb_demand_max,
	'UNK'::TEXT as rate_type,
	pct_of_state_sector_cust as pct_of_customers
from  urdb_rates.urdb3_verified_rates_lookup_20151028 a
where state_code = 'ME'
and res_com = 'I';
----------------------------------------------------------------------

-- add the pct_of_customers column 
ALTER TABLE diffusion_shared.urdb_rates_by_state_com
ADD COLUMN pct_of_customers numeric;

ALTER TABLE diffusion_shared.urdb_rates_by_state_res
ADD COLUMN pct_of_customers numeric;

ALTER TABLE diffusion_shared.urdb_rates_by_state_ind
ADD COLUMN pct_of_customers numeric;
----------------------------------------------------------------------

-- replace the rows in the old table with these rows (for Maine Only)

-- COMMERCIAL
DELETE from diffusion_shared.urdb_rates_by_state_com
where state_abbr = 'ME';
-- 14 rows deleted

INSERT INTO diffusion_shared.urdb_rates_by_state_com
SELECT *
FROM diffusion_data_shared.urdb_rates_by_state_com_maine;
-- 6 rows added


-- INDUSTRIAL
DELETE from diffusion_shared.urdb_rates_by_state_ind
where state_abbr = 'ME';
-- 14 rows deleted

INSERT INTO diffusion_shared.urdb_rates_by_state_ind
SELECT *
FROM diffusion_data_shared.urdb_rates_by_state_ind_maine;
-- 4 rows added


-- RESIDENTIAL
DELETE from diffusion_shared.urdb_rates_by_state_res
where state_abbr = 'ME';
-- 9 rows deleted

INSERT INTO diffusion_shared.urdb_rates_by_state_res
SELECT *
FROM diffusion_data_shared.urdb_rates_by_state_res_maine;
-- 3 rows added