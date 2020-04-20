-- find all rates within 50 mi of each point with the same utility_type

-- RESIDENTIAL
DROP TABLE IF EXISTS diffusion_data_shared.county_ranked_lidar_city_lkup_res;
CREATE TABLE diffusion_data_shared.county_ranked_lidar_city_lkup_res As
with a as
(
	SELECT a.county_id, a.ulocale,
		b.city_id, b.year, b.dist_m
	FROM diffusion_data_shared.county_ulocale_lkup_res a
	LEFT JOIN diffusion_data_shared.county_to_lidar_city_distances_lkup b
		ON a.county_id = b.county_id
	INNER JOIN pv_rooftop_dsolar_integration.city_ulocale_zone_lkup c
		ON b.city_id = c.city_id
		and c.zone = 'residential'
		and a.ulocale = c.ulocale
)
select county_id,  ulocale, city_id,
	rank() OVER (partition by county_id,  ulocale ORDER BY dist_m ASC, year DESC) as rank
from a;
-- 135898 rows

-- add indices
CREATE INDEX county_ranked_lidar_lkup_res_county_id_btree
ON diffusion_data_shared.county_ranked_lidar_city_lkup_res
using btree(county_id);

CREATE INDEX county_ranked_lidar_lkup_res_rank_btree
ON diffusion_data_shared.county_ranked_lidar_city_lkup_res
using btree(rank);

CREATE INDEX county_ranked_lidar_lkup_res_ulocale_btree
ON diffusion_data_shared.county_ranked_lidar_city_lkup_res
using btree(ulocale);

------------------------------------------------------------------------------------------------
-- COMMERCIAL
DROP TABLE IF EXISTS diffusion_data_shared.county_ranked_lidar_city_lkup_com;
CREATE TABLE diffusion_data_shared.county_ranked_lidar_city_lkup_com As
with a as
(
	SELECT a.county_id, a.ulocale,
		b.city_id, b.year, b.dist_m
	FROM diffusion_data_shared.county_ulocale_lkup_com a
	LEFT JOIN diffusion_data_shared.county_to_lidar_city_distances_lkup b
		ON a.county_id = b.county_id
	INNER JOIN pv_rooftop_dsolar_integration.city_ulocale_zone_lkup c
		ON b.city_id = c.city_id
		and c.zone = 'com_ind'
		and a.ulocale = c.ulocale
)
select county_id,  ulocale, city_id,
	rank() OVER (partition by county_id,  ulocale ORDER BY dist_m ASC, year DESC) as rank
from a;
-- 125294 rows

-- add indices
CREATE INDEX county_ranked_lidar_lkup_com_county_id_btree
ON diffusion_data_shared.county_ranked_lidar_city_lkup_com
using btree(county_id);

CREATE INDEX county_ranked_lidar_lkup_com_rank_btree
ON diffusion_data_shared.county_ranked_lidar_city_lkup_com
using btree(rank);

CREATE INDEX county_ranked_lidar_lkup_com_ulocale_btree
ON diffusion_data_shared.county_ranked_lidar_city_lkup_com
using btree(ulocale);
------------------------------------------------------------------------------------------------

-- INDUSTRIAL
DROP TABLE IF EXISTS diffusion_data_shared.county_ranked_lidar_city_lkup_ind;
CREATE TABLE diffusion_data_shared.county_ranked_lidar_city_lkup_ind As
with a as
(
	SELECT a.county_id, a.ulocale,
		b.city_id, b.year, b.dist_m
	FROM diffusion_data_shared.county_ulocale_lkup_ind a
	LEFT JOIN diffusion_data_shared.county_to_lidar_city_distances_lkup b
		ON a.county_id = b.county_id
	INNER JOIN pv_rooftop_dsolar_integration.city_ulocale_zone_lkup c
		ON b.city_id = c.city_id
		and c.zone = 'com_ind'
		and a.ulocale = c.ulocale
)
select county_id,  ulocale, city_id,
	rank() OVER (partition by county_id,  ulocale ORDER BY dist_m ASC, year DESC) as rank
from a;
-- 125400 rows

-- add indices
CREATE INDEX county_ranked_lidar_lkup_ind_county_id_btree
ON diffusion_data_shared.county_ranked_lidar_city_lkup_ind
using btree(county_id);

CREATE INDEX county_ranked_lidar_lkup_ind_rank_btree
ON diffusion_data_shared.county_ranked_lidar_city_lkup_ind
using btree(rank);

CREATE INDEX county_ranked_lidar_lkup_ind_ulocale_btree
ON diffusion_data_shared.county_ranked_lidar_city_lkup_ind
using btree(ulocale);
