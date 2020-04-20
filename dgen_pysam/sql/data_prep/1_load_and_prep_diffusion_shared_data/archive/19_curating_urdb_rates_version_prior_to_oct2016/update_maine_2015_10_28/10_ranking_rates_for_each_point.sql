-- find all rates within 50 mi of each point with the same utility_type

-- COMMERCIAL
DROP TABLE IF EXISTS diffusion_data_shared.pt_ranked_rates_lkup_com_maine;
CREATE TABLE diffusion_data_shared.pt_ranked_rates_lkup_com_maine AS
WITH a as
(
	SELECT a.gid as pt_gid, d.rate_id_alias, 
		(a.utility_type = d.utility_type) as utility_type_match,
		ST_Distance(a.the_geom_96703, d.the_geom_96703) as distance_m
	FROM diffusion_shared.pt_grid_us_com a
	INNER JOIN diffusion_shared.county_geom b
		ON a.county_id = b.county_id
	INNER JOIN diffusion_data_shared.urdb_rates_by_state_com_maine c
		ON b.state_abbr = c.state_abbr
	INNER JOIN diffusion_data_shared.urdb_rates_geoms_com d
		ON c.rate_id_alias = d.rate_id_alias
	WHERE b.state_abbr = 'ME'
),
b as
(
	select pt_gid, rate_id_alias, utility_type_match, min(distance_m) as distance_m
	FROM a
	GROUP BY pt_gid, rate_id_alias, utility_type_match
),
c as
(
	SELECT pt_gid, rate_id_alias, 
		(utility_type_match = true and distance_m <= 80467.2)::integer as near_utility_type_match,
		distance_m
	from b
)
SELECT pt_gid,  rate_id_alias, 
	rank() OVER (partition by pt_gid ORDER BY near_utility_type_match desc, distance_m asC) as rank
FROM c;
-- 63180 rows

-- add indices
CREATE INDEX pt_ranked_rates_lkup_com_maine_pt_gid_btree
ON diffusion_data_shared.pt_ranked_rates_lkup_com_maine
using btree(pt_gid);

CREATE INDEX pt_ranked_rates_lkup_com_maine_urdb_rank_btree
ON diffusion_data_shared.pt_ranked_rates_lkup_com_maine
using btree(rank);

CREATE INDEX pt_ranked_rates_lkup_com_maine_rate_id_alias_btree
ON diffusion_data_shared.pt_ranked_rates_lkup_com_maine
using btree(rate_id_alias);

------------------------------------------------------------------------------

-- INDUSTRIAL
DROP TABLE IF EXISTS diffusion_data_shared.pt_ranked_rates_lkup_ind_maine;
CREATE TABLE diffusion_data_shared.pt_ranked_rates_lkup_ind_maine AS
WITH a as
(
	SELECT a.gid as pt_gid, d.rate_id_alias, 
		(a.utility_type = d.utility_type) as utility_type_match,
		ST_Distance(a.the_geom_96703, d.the_geom_96703) as distance_m
	FROM diffusion_shared.pt_grid_us_ind a
	INNER JOIN diffusion_shared.county_geom b
		ON a.county_id = b.county_id
	INNER JOIN diffusion_data_shared.urdb_rates_by_state_ind_maine c
		ON b.state_abbr = c.state_abbr
	INNER JOIN diffusion_data_shared.urdb_rates_geoms_ind d
		ON c.rate_id_alias = d.rate_id_alias
	WHERE b.state_abbr = 'ME'
),
b as
(
	select pt_gid, rate_id_alias, utility_type_match, min(distance_m) as distance_m
	FROM a
	GROUP BY pt_gid, rate_id_alias, utility_type_match
),
c as
(
	SELECT pt_gid, rate_id_alias, 
		(utility_type_match = true and distance_m <= 80467.2)::integer as near_utility_type_match,
		distance_m
	from b
)
SELECT pt_gid,  rate_id_alias, 
	rank() OVER (partition by pt_gid ORDER BY near_utility_type_match desc, distance_m asC) as rank
FROM c;
-- 23776 rows

-- add indices
CREATE INDEX pt_ranked_rates_lkup_ind_maine_pt_gid_btree
ON diffusion_data_shared.pt_ranked_rates_lkup_ind_maine
using btree(pt_gid);

CREATE INDEX pt_ranked_rates_lkup_ind_maine_urdb_rank_btree
ON diffusion_data_shared.pt_ranked_rates_lkup_ind_maine
using btree(rank);

CREATE INDEX pt_ranked_rates_lkup_ind_maine_rate_id_alias_btree
ON diffusion_data_shared.pt_ranked_rates_lkup_ind_maine
using btree(rate_id_alias);

------------------------------------------------------------------------------

-- RESIDENTIAL
DROP TABLE IF EXISTS diffusion_data_shared.pt_ranked_rates_lkup_res_maine;
CREATE TABLE diffusion_data_shared.pt_ranked_rates_lkup_res_maine AS
WITH a as
(
	SELECT a.gid as pt_gid, d.rate_id_alias, 
		(a.utility_type = d.utility_type) as utility_type_match,
		ST_Distance(a.the_geom_96703, d.the_geom_96703) as distance_m
	FROM diffusion_shared.pt_grid_us_res a
	INNER JOIN diffusion_shared.county_geom b
		ON a.county_id = b.county_id
	INNER JOIN diffusion_data_shared.urdb_rates_by_state_res_maine c
		ON b.state_abbr = c.state_abbr
	INNER JOIN diffusion_data_shared.urdb_rates_geoms_res d
		ON c.rate_id_alias = d.rate_id_alias
	WHERE b.state_abbr = 'ME'
),
b as
(
	select pt_gid, rate_id_alias, utility_type_match, min(distance_m) as distance_m
	FROM a
	GROUP BY pt_gid, rate_id_alias, utility_type_match
),
c as
(
	SELECT pt_gid, rate_id_alias, 
		(utility_type_match = true and distance_m <= 80467.2)::integer as near_utility_type_match,
		distance_m
	from b
)
SELECT pt_gid,  rate_id_alias, 
	rank() OVER (partition by pt_gid ORDER BY near_utility_type_match desc, distance_m asC) as rank
FROM c;
-- 122142 rows

-- add indices
CREATE INDEX pt_ranked_rates_lkup_res_maine_gid_btree
ON diffusion_data_shared.pt_ranked_rates_lkup_res_maine
using btree(pt_gid);

CREATE INDEX pt_ranked_rates_lkup_res_maine_urdb_rank_btree
ON diffusion_data_shared.pt_ranked_rates_lkup_res_maine
using btree(rank);

CREATE INDEX pt_ranked_rates_lkup_res_maine_rate_id_alias_btree
ON diffusion_data_shared.pt_ranked_rates_lkup_res_maine
using btree(rate_id_alias);
