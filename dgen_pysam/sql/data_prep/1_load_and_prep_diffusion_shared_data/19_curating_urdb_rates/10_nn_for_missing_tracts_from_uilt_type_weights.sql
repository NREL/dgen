-- Process:

-- 1. Identifying the counties assigned to each utility
-- 2. Use the agent count to break down the sample weight

-- What about the agents not assigned to a utility?
	-- we performed a nearest neighbor to identify the rates
	-- how do we perform a nearest neighbor to identify utility type?
		-- needs to be similar to rate ranking process

		-- for any of the tracts that do not actually fall within a utility territory, we need to perform a nearest neighbor to basically determine the sample weights

		-- 1. identify which sector tracts were not assigned to a utility
			-- perform nearest neighbor to identify the sample weight (of utility_type)
				-- 1. maybe just do SIMPLE nearest neighbor (within the same state) OR do nearest neighbor?

--------------------------------------------------------------------------------------------------------------------------------------

-- 1. Identify which sector tracts were not assigned to a utility
	-- Create a table to store these tracts and sector labels

	set role 'diffusion-writers';
	drop table if exists diffusion_data_shared.tract_util_type_weight_missing_tracts;
	create table diffusion_data_shared.tract_util_type_weight_missing_tracts as (
	--Commercial
	with com_agents as (
		with b as (
			select a.pgid, b.tract_fips, b.state_fips, b.county_fips
			from diffusion_blocks.blocks_com a
			left join diffusion_blocks.block_geoms b
			on a.pgid = b.pgid)
		select distinct a.tract_id_alias, b.state_fips, b.county_fips from 
		diffusion_blocks.tract_geoms a
		right join b
		on a.state_fips = b.state_fips and a.county_fips = b.county_fips and a.tract_fips = b.tract_fips),
	missing_com as (
		select a.tract_id_alias, 'C'::text as sector 
		from com_agents a
		where a.tract_id_alias not in 	
			(select b.tract_id_alias 
			from diffusion_data_shared.tract_util_type_weight_com b)),
	--Residential
	res_agents as (
		with b as (
			select a.pgid, b.tract_fips, b.state_fips, b.county_fips
			from diffusion_blocks.blocks_res a
			left join diffusion_blocks.block_geoms b
			on a.pgid = b.pgid)
		select distinct a.tract_id_alias, b.state_fips, b.county_fips from 
		diffusion_blocks.tract_geoms a
		right join b
		on a.state_fips = b.state_fips and a.county_fips = b.county_fips and a.tract_fips = b.tract_fips),
	missing_res as (
		select a.tract_id_alias, 'R'::text as sector 
		from res_agents a
		where a.tract_id_alias not in 	
			(select b.tract_id_alias 
			from diffusion_data_shared.tract_util_type_weight_res b)),

	-- Industrial
	ind_agents as (
		with b as (
			select a.pgid, b.tract_fips, b.state_fips, b.county_fips
			from diffusion_blocks.blocks_ind a
			left join diffusion_blocks.block_geoms b
			on a.pgid = b.pgid)
		select distinct a.tract_id_alias, b.state_fips, b.county_fips from 
		diffusion_blocks.tract_geoms a
		right join b
		on a.state_fips = b.state_fips and a.county_fips = b.county_fips and a.tract_fips = b.tract_fips),
	missing_ind as (
		select a.tract_id_alias, 'I'::text as sector 
		from ind_agents a
		where a.tract_id_alias not in 	
			(select b.tract_id_alias 
			from diffusion_data_shared.tract_util_type_weight_ind b))

	select * from missing_com
	union all
	select * from missing_res
	union all
	select * from missing_ind);		
3320 | C
  3870 | R
 19277 | I


-- 2. TWO OPTIONS

-- 2. Perform another NN to assign utility weights to these OR do a random 
		-- best way to do this is just to get the sum of the weights for all of the others??
		-- the idea here is that these sample weights are just used to randomly identify what the utility type is for a given agent... 
			-- so, we can take the sum of all nearest neighbors within 50 miles and within the same state

			-- then we would need to take the sum in the next group as well?
			-- 

-- 2. Make these equally random??
	-- this keeps things simple


-- basically, I want to be able to identify which tracts we have
-- 


set role 'diffusion-writers';
drop table if exists diffusion_data_shared.tract_util_type_weight_missing_tracts_nn;
create table diffusion_data_shared.tract_util_type_weight_missing_tracts_nn as (
with com as (
	with missing_tracts as (
		select a.*, b.state_fips, b.the_geom_96703 from
		 diffusion_data_shared.tract_util_type_weight_missing_tracts a
		 left join diffusion_blocks.tract_geoms b
		 on a.tract_id_alias = b.tract_id_alias
		 where a.sector = 'C'),
	knowngeoms_com as (
		select a.*, b.the_geom_96703
		from diffusion_data_shared.tract_util_type_weight_com a
		left join diffusion_blocks.tract_geoms b
		on a.tract_id_alias = b.tract_id_alias   
	        ),
	nn as (
		select 
			(case when b.utility_type = 'IOU' then 1
	 			when b.utility_type = 'Coop' then 2
	 			when b.utility_type = 'Muni' then 3
	 			when b.utility_type = 'Other' then 4 end)::int as utility_id,
			a.state_fips,
			a.tract_id_alias,
			b.utility_type,
			b.util_type_weight
		from missing_tracts a
		left join knowngeoms_com b
		on a.state_fips = b.state_fips
		and st_distance(a.the_geom_96703, b.the_geom_96703) <= 80467.2),
	sum_util_weights as (
		select 
			utility_id, 
			state_fips,
			tract_id_alias, 
			utility_type, 
			sum(util_type_weight) as util_type_weight
		from nn
		group by utility_id, state_fips, 
		tract_id_alias, utility_type
		order by tract_id_alias, utility_type
		)
	select 
		a.utility_id, 
		'C'::text as sector,
		b.state_fips, 
		b.county_fips, 
		b.tract_fips, 
		a.tract_id_alias, 
		a.utility_type, 
		a.util_type_weight
	from sum_util_weights a
	left join diffusion_blocks.tract_geoms b
	on a.tract_id_alias = b.tract_id_alias
	),
res as (
	with missing_tracts as (
		select a.*, b.state_fips, b.the_geom_96703 from
		 diffusion_data_shared.tract_util_type_weight_missing_tracts a
		 left join diffusion_blocks.tract_geoms b
		 on a.tract_id_alias = b.tract_id_alias
		 where a.sector = 'R'),
	knowngeoms_res as (
		select a.*, b.the_geom_96703
		from diffusion_data_shared.tract_util_type_weight_res a
		left join diffusion_blocks.tract_geoms b
		on a.tract_id_alias = b.tract_id_alias   
	        ),
	nn as (
		select 
			(case when b.utility_type = 'IOU' then 1
	 			when b.utility_type = 'Coop' then 2
	 			when b.utility_type = 'Muni' then 3
	 			when b.utility_type = 'Other' then 4 end)::int as utility_id,
			a.state_fips,
			a.tract_id_alias,
			b.utility_type,
			b.util_type_weight
		from missing_tracts a
		left join knowngeoms_res b
		on a.state_fips = b.state_fips
		and st_distance(a.the_geom_96703, b.the_geom_96703) <= 80467.2),
	sum_util_weights as (
		select 
			utility_id, 
			state_fips,
			tract_id_alias, 
			utility_type,
			sum(util_type_weight) as util_type_weight
		from nn
		group by utility_id, state_fips, 
		tract_id_alias, utility_type
		order by tract_id_alias, utility_type
		)
	select 
		a.utility_id, 
		'R'::text as sector,
		b.state_fips, 
		b.county_fips, 
		b.tract_fips, 
		a.tract_id_alias, 
		a.utility_type, 
		a.util_type_weight
	from sum_util_weights a
	left join diffusion_blocks.tract_geoms b
	on a.tract_id_alias = b.tract_id_alias
	),
ind as (
	with missing_tracts as (
		select a.*, b.state_fips, b.the_geom_96703 from
		 diffusion_data_shared.tract_util_type_weight_missing_tracts a
		 left join diffusion_blocks.tract_geoms b
		 on a.tract_id_alias = b.tract_id_alias
		 where a.sector = 'I'),
knowngeoms_ind as (
		select a.*, b.the_geom_96703
		from diffusion_data_shared.tract_util_type_weight_ind a
		left join diffusion_blocks.tract_geoms b
		on a.tract_id_alias = b.tract_id_alias 
	        ),
	nn as (
		select 
			(case when b.utility_type = 'IOU' then 1
	 			when b.utility_type = 'Coop' then 2
	 			when b.utility_type = 'Muni' then 3
	 			when b.utility_type = 'Other' then 4 end)::int as utility_id,
			a.state_fips,
			a.tract_id_alias,
			b.utility_type,
			b.util_type_weight
		from missing_tracts a
		left join knowngeoms_ind b
		on a.state_fips = b.state_fips
		and st_distance(a.the_geom_96703, b.the_geom_96703) <= 80467.2),
	sum_util_weights as (
		select 
			utility_id, 
			state_fips,
			tract_id_alias, 
			utility_type,
			sum(util_type_weight) as util_type_weight
		from nn
		group by utility_id, state_fips, 
		tract_id_alias, utility_type
		order by tract_id_alias, utility_type
		)
	select 
		a.utility_id, 
		'I'::text as sector,
		b.state_fips, 
		b.county_fips, 
		b.tract_fips, 
		a.tract_id_alias, 
		a.utility_type, 
		a.util_type_weight
	from sum_util_weights a
	left join diffusion_blocks.tract_geoms b
	on a.tract_id_alias = b.tract_id_alias
	)
select * from com 
union all 
select * from ind
union all
select * from res
);


-------------------------------------------------------------------------------------------------------------------------------------------
-- QAQC
-- NEXT --> check to make sure that all missing tracts are accounted for (in at least 1 utility type)
select tract_id_alias
from diffusion_data_shared.tract_util_type_weight_missing_tracts
where sector = 'C'
and tract_id_alias not in (select tract_id_alias from diffusion_data_shared.tract_util_type_weight_missing_tracts_nn where sector = 'C');
	-- (if 0 then good to go)
		-- total = 0 √

select tract_id_alias
from diffusion_data_shared.tract_util_type_weight_missing_tracts
where sector = 'I'
and tract_id_alias not in (select tract_id_alias from diffusion_data_shared.tract_util_type_weight_missing_tracts_nn where sector = 'I');
	-- (if 0 then good to go)
		-- total = 0 √

select tract_id_alias
from diffusion_data_shared.tract_util_type_weight_missing_tracts
where sector = 'R'
and tract_id_alias not in (select tract_id_alias from diffusion_data_shared.tract_util_type_weight_missing_tracts_nn where sector = 'R');
	-- (if 0 then good to go)
		-- total = 0 √



