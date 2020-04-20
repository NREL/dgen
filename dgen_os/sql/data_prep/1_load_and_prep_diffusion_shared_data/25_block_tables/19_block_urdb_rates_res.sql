set role 'diffusion-writers';

-----------------------------------------------------------------------------------------------------------
-- archive the old, simple distance version
-- DROP TABLE IF EXISTS diffusion_blocks.block_urdb_rates_res_simple_distance;
-- CReATE TABLE diffusion_blocks.block_urdb_rates_res_simple_distance AS
-- SELECT *
-- FROM diffusion_blocks.block_urdb_rates_res; 
-- 10535171 rows

-- residential 
DROP TABLE IF EXISTS diffusion_blocks.block_urdb_rates_res;
CReATE TABLE diffusion_blocks.block_urdb_rates_res 
(
	pgid bigint,
	rate_ids integer[],
	rate_ranks integer[]
);

select parsel_2('dav-gis', 'mgleason', 'mgleason',
		'diffusion_blocks.block_geoms', 'pgid',
		'WITH a as
		(
			SELECT a.pgid, 
				c.rate_id_alias, 
				(d.utility_type_res = c.utility_type) as utility_type_match,
				ST_Distance(a.the_point_96703, c.the_geom_96703) as distance_m
			FROM diffusion_blocks.block_geoms a
			LEFT JOIN diffusion_blocks.block_primary_electric_utilities d
				ON a.pgid = d.pgid
			LEFT JOIN diffusion_shared.urdb_rates_by_state_res b
				ON a.state_abbr = b.state_abbr
			LEFT JOIN diffusion_data_shared.urdb_rates_geoms_res c
				ON b.rate_id_alias = c.rate_id_alias

		),
		b as -- grouping is necessary because rate geoms are exploded (same utility might have several geoms)
		(
			select pgid, rate_id_alias, utility_type_match, min(distance_m) as distance_m
			FROM a
			GROUP BY pgid, utility_type_match, rate_id_alias
		),
		c as
		(
			SELECT pgid,  rate_id_alias, 
				(utility_type_match = true and distance_m <= 80467.2)::integer as near_utility_type_match,
				distance_m
			FROM b
		),
		d as
		(
			SELECT pgid, rate_id_alias,
				rank() OVER (partition by pgid ORDER BY near_utility_type_match DESC, distance_m ASC) as rank
				from c
		)
		select pgid, 
			array_agg(rate_id_alias order by rank, rate_id_alias) as rate_ids, 
			array_agg(rank order by rank, rate_id_alias) as rate_ranks
		from d
		GROUP BY pgid;',
			'diffusion_blocks.block_urdb_rates_res', 'a', 16);
-----------------------------------------------------------------------------------------------------------
-- add primary key
ALTER TABLE diffusion_blocks.block_urdb_rates_res 
ADD PRIMARY KEY (pgid);

-- check count
select count(*)
FROM diffusion_blocks.block_urdb_rates_res;
-- 10535171

-- check for nulls
select count(*)
FROM diffusion_blocks.block_urdb_rates_res
where rate_ids = array[null]::INTEGER[];
-- 50641

-- change to actual nulls
UPDATE diffusion_blocks.block_urdb_rates_res
set rate_ids = NULL
where rate_ids = array[null]::INTEGER[];

-- recheck
select count(*)
FROM diffusion_blocks.block_urdb_rates_res
where rate_ids is null;
-- 50641

-- fix rate ranks too
UPDATE diffusion_blocks.block_urdb_rates_res
set rate_ranks = NULL
where rate_ids is null;


-- where are they?
select distinct b.state_abbr
FROM diffusion_blocks.block_urdb_rates_res a
left join diffusion_blocks.block_geoms b
on a.pgid = b.pgid
where a.rate_ranks is null
OR a.rate_ids is null;
-- AK and HI only -- all set

