-- find all rates within 50 mi of each point with the same utility_type

-- COMMERCIAL
DROP TABLE IF EXISTS diffusion_shared_data.pt_ranked_rates_lkup_com;
CREATE TABLE diffusion_shared_data.pt_ranked_rates_lkup_com
(
	pt_gid integer,
	rate_id_alias integer,
	rank integer
);



SELECT parsel_2('dav-gis','mgleason','mgleason',
		'diffusion_shared.pt_grid_us_com_new','gid',
		'WITH a as
			(
				SELECT a.gid as pt_gid, d.rate_id_alias, 
					(a.utility_type = d.utility_type) as utility_type_match,
					ST_Distance(a.the_geom_96703, d.the_geom_96703) as distance_m
				FROM diffusion_shared.pt_grid_us_com_new a
				INNER JOIN diffusion_shared.county_geom b
				ON a.county_id = b.county_id
				INNER JOIN diffusion_shared.urdb_rates_by_state_com c
				ON b.state_abbr = c.state_abbr
				INNER JOIN diffusion_shared.urdb_rates_geoms_com d
				ON c.rate_id_alias = d.rate_id_alias
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
				FROM c;',
		'diffusion_shared_data.pt_ranked_rates_lkup_com', 'a', 22);


-- add indices
CREATE INDEX pt_ranked_rates_lkup_com_pt_gid_btree
ON diffusion_shared_data.pt_ranked_rates_lkup_com
using btree(pt_gid);

CREATE INDEX pt_ranked_rates_lkup_com_urdb_rank_btree
ON diffusion_shared_data.pt_ranked_rates_lkup_com
using btree(rank);

CREATE INDEX pt_ranked_rates_lkup_com_rate_id_alias_btree
ON diffusion_shared_data.pt_ranked_rates_lkup_com
using btree(rate_id_alias);

select count(*)
FROM diffusion_shared_data.pt_ranked_rates_lkup_com;
-- 56,567,275
------------------------------------------------------------------------------

-- INDUSTRIAL
DROP TABLE IF EXISTS diffusion_shared_data.pt_ranked_rates_lkup_ind;
CREATE TABLE diffusion_shared_data.pt_ranked_rates_lkup_ind
(
	pt_gid integer,
	rate_id_alias integer,
	rank integer
);



SELECT parsel_2('dav-gis','mgleason','mgleason',
		'diffusion_shared.pt_grid_us_ind_new','gid',
		'WITH a as
			(
				SELECT a.gid as pt_gid, d.rate_id_alias, 
					(a.utility_type = d.utility_type) as utility_type_match,
					ST_Distance(a.the_geom_96703, d.the_geom_96703) as distance_m
				FROM diffusion_shared.pt_grid_us_ind_new a
				INNER JOIN diffusion_shared.county_geom b
				ON a.county_id = b.county_id
				INNER JOIN diffusion_shared.urdb_rates_by_state_ind c
				ON b.state_abbr = c.state_abbr
				INNER JOIN diffusion_shared.urdb_rates_geoms_com d
				ON c.rate_id_alias = d.rate_id_alias
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
				FROM c;',
		'diffusion_shared_data.pt_ranked_rates_lkup_ind', 'a', 22);


-- add indices
CREATE INDEX pt_ranked_rates_lkup_ind_pt_gid_btree
ON diffusion_shared_data.pt_ranked_rates_lkup_ind
using btree(pt_gid);

CREATE INDEX pt_ranked_rates_lkup_ind_urdb_rank_btree
ON diffusion_shared_data.pt_ranked_rates_lkup_ind
using btree(rank);

CREATE INDEX pt_ranked_rates_lkup_ind_rate_id_alias_btree
ON diffusion_shared_data.pt_ranked_rates_lkup_ind
using btree(rate_id_alias);

select count(*)
FROM diffusion_shared_data.pt_ranked_rates_lkup_ind;
-- 42,112,773
------------------------------------------------------------------------------

-- RESIDENTIAL
DROP TABLE IF EXISTS diffusion_shared_data.pt_ranked_rates_lkup_res;
CREATE TABLE diffusion_shared_data.pt_ranked_rates_lkup_res
(
	pt_gid integer,
	rate_id_alias integer,
	rank integer
);



SELECT parsel_2('dav-gis','mgleason','mgleason',
		'diffusion_shared.pt_grid_us_res_new','gid',
		'WITH a as
			(
				SELECT a.gid as pt_gid, d.rate_id_alias, 
					(a.utility_type = d.utility_type) as utility_type_match,
					ST_Distance(a.the_geom_96703, d.the_geom_96703) as distance_m
				FROM diffusion_shared.pt_grid_us_res_new a
				INNER JOIN diffusion_shared.county_geom b
				ON a.county_id = b.county_id
				INNER JOIN diffusion_shared.urdb_rates_by_state_res c
				ON b.state_abbr = c.state_abbr
				INNER JOIN diffusion_shared.urdb_rates_geoms_res d
				ON c.rate_id_alias = d.rate_id_alias
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
				FROM c;',
		'diffusion_shared_data.pt_ranked_rates_lkup_res', 'a', 22);


-- add indices
CREATE INDEX pt_ranked_rates_lkup_res_gid_btree
ON diffusion_shared_data.pt_ranked_rates_lkup_res
using btree(pt_gid);

CREATE INDEX pt_ranked_rates_lkup_res_urdb_rank_btree
ON diffusion_shared_data.pt_ranked_rates_lkup_res
using btree(rank);

CREATE INDEX pt_ranked_rates_lkup_res_rate_id_alias_btree
ON diffusion_shared_data.pt_ranked_rates_lkup_res
using btree(rate_id_alias);

select count(*)
FROM diffusion_shared_data.pt_ranked_rates_lkup_res;
-- 222,280,019