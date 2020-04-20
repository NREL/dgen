-- Process:

-- 1. Identifying the counties assigned to each utility
-- 2. Use the agent count to break down the sample weight

-- What about the agents not assigned to a utility?
	-- we performed a nearest neighbor to identify the rates
	-- how do we perform a nearest neighbor to identify utility type?
		-- needs to be similar to rate ranking process

		-- for any of the cntys (or counties as of 1/3/17) that do not actually fall within a utility territory, we need to perform a nearest neighbor to basically determine the sample weights

		-- 1. identify which sector cntys were not assigned to a utility
			-- perform nearest neighbor to identify the sample weight (of utility_type)
				-- 1. maybe just do SIMPLE nearest neighbor (within the same state) OR do nearest neighbor?

--------------------------------------------------------------------------------------------------------------------------------------

-- 1. Identify which sector cntys were not assigned to a utility
	-- Create a table to store these cntys and sector labels

	--set role 'diffusion-writers';
	drop table if exists diffusion_data_shared.cnty_util_type_weight_missing_cntys;
	create table diffusion_data_shared.cnty_util_type_weight_missing_cntys as (
	--Commercial
	with com_agents as (
			select  county_fips, state_fips, (state_fips || county_fips) as geoid, sum(bldg_count_com) as bldg_count_com
			from diffusion_data_shared.tract_bldg_counts
			group by county_fips, state_fips
			),
	missing_com as (
		select a.geoid, a.state_fips, a.county_fips, 'C'::text as sector 
		from com_agents a
		where a.geoid not in 	
			(select (b.state_fips || b.county_fips)
			from diffusion_data_shared.cnty_util_type_weight_com b)),
	--Residential
	res_agents as (
			select county_fips, state_fips, (state_fips || county_fips) as geoid, sum(bldg_count_res) as bldg_count_res
			from diffusion_data_shared.tract_bldg_counts
			group by county_fips, state_fips
			),
	missing_res as (
		select a.geoid, a.state_fips, a.county_fips, 'R'::text as sector 
		from res_agents a
		where a.geoid not in 	
			(select (b.state_fips || b.county_fips)
			from diffusion_data_shared.cnty_util_type_weight_res b)),

	-- Industrial
	ind_agents as (
			select county_fips, state_fips, (state_fips || county_fips) as geoid, sum(bldg_count_ind) as bldg_count_ind
			from diffusion_data_shared.tract_bldg_counts
			group by county_fips, state_fips),
	missing_ind as (
		select a.geoid, a.state_fips, a.county_fips, 'I'::text as sector 
		from ind_agents a
		where a.geoid not in 	
			(select (b.state_fips || b.county_fips)
			from diffusion_data_shared.cnty_util_type_weight_ind b))

	select * from missing_com
	union all
	select * from missing_res
	union all
	select * from missing_ind);		
		-- "I";920
		-- "R";265
		-- "C";232



-- 2. TWO OPTIONS

-- 2. Perform another NN to assign utility weights to these OR do a random 
		-- best way to do this is just to get the sum of the weights for all of the others??
		-- the idea here is that these sample weights are just used to randomly identify what the utility type is for a given agent... 
			-- so, we can take the sum of all nearest neighbors within 50 miles and within the same state

			-- then we would need to take the sum in the next group as well?
			-- APPLY THE STATE AVERAGE AS THE CUSTOMER COUNT WHERE WE DO NOT KNOW

-- 2. Make these equally random??
	-- this keeps things simple


-- basically, I want to be able to identify which cntys we have
-- 


--set role 'diffusion-writers';
drop table if exists diffusion_data_shared.cnty_util_type_weight_missing_cntys_nn;
create table diffusion_data_shared.cnty_util_type_weight_missing_cntys_nn as (
with com as (
	with missing_cntys as (
		select a.*, b.the_geom_96703_5m as the_geom_96703 from
		 diffusion_data_shared.cnty_util_type_weight_missing_cntys a
		 left join diffusion_blocks.county_geoms b
		 on a.county_fips = b.county_fips and a.state_fips = b.state_fips
		 where a.sector = 'C'),
	knowngeoms_com as (
		select a.*, b.the_geom_96703_5m as the_geom_96703
		from diffusion_data_shared.cnty_util_type_weight_com a
		left join diffusion_blocks.county_geoms b
		on a.county_fips = b.county_fips and a.state_fips = b.state_fips  
	    ),
	nn as (
		select 
			(case when b.utility_type = 'IOU' then 1
	 			when b.utility_type = 'Coop' then 2
	 			when b.utility_type = 'Muni' then 3
	 			when b.utility_type = 'Other' then 4 end)::int as utility_id,
			a.state_fips,
			a.county_fips,
			a.geoid,
			b.utility_type,
			b.util_type_weight
		from missing_cntys a
		left join knowngeoms_com b
		on a.state_fips = b.state_fips
		and st_distance(a.the_geom_96703, b.the_geom_96703) <= 80467.2),
	sum_util_weights as (
		select 
			utility_id, 
			state_fips,
			county_fips, 
			utility_type, 
			sum(util_type_weight) as util_type_weight
		from nn
		group by utility_id, 
			state_fips,
			county_fips, 
			utility_type
		order by state_fips, county_fips, utility_type
		)
	select 
		a.utility_id, 
		'C'::text as sector,
		b.state_fips, 
		b.county_fips, 
		a.utility_type, 
		a.util_type_weight
	from sum_util_weights a
	left join diffusion_blocks.county_geoms b
	on a.county_fips = b.county_fips and a.state_fips = b.state_fips  
	),
res as (
		with missing_cntys as (
		select a.*, b.the_geom_96703_5m as the_geom_96703 from
		 diffusion_data_shared.cnty_util_type_weight_missing_cntys a
		 left join diffusion_blocks.county_geoms b
		 on a.county_fips = b.county_fips and a.state_fips = b.state_fips
		 where a.sector = 'R'),
	knowngeoms_res as (
		select a.*, b.the_geom_96703_5m as the_geom_96703
		from diffusion_data_shared.cnty_util_type_weight_res a
		left join diffusion_blocks.county_geoms b
		on a.county_fips = b.county_fips and a.state_fips = b.state_fips  
	    ),
	nn as (
		select 
			(case when b.utility_type = 'IOU' then 1
	 			when b.utility_type = 'Coop' then 2
	 			when b.utility_type = 'Muni' then 3
	 			when b.utility_type = 'Other' then 4 end)::int as utility_id,
			a.state_fips,
			a.county_fips,
			a.geoid,
			b.utility_type,
			b.util_type_weight
		from missing_cntys a
		left join knowngeoms_res b
		on a.state_fips = b.state_fips
		and st_distance(a.the_geom_96703, b.the_geom_96703) <= 80467.2),
	sum_util_weights as (
		select 
			utility_id, 
			state_fips,
			county_fips, 
			utility_type, 
			sum(util_type_weight) as util_type_weight
		from nn
		group by utility_id, 
			state_fips,
			county_fips, 
			utility_type
		order by state_fips, county_fips, utility_type
		)
	select 
		a.utility_id, 
		'R'::text as sector,
		b.state_fips, 
		b.county_fips, 
		a.utility_type, 
		a.util_type_weight
	from sum_util_weights a
	left join diffusion_blocks.county_geoms b
	on a.county_fips = b.county_fips and a.state_fips = b.state_fips  
	),
ind as (
		with missing_cntys as (
		select a.*, b.the_geom_96703_5m as the_geom_96703 from
		 diffusion_data_shared.cnty_util_type_weight_missing_cntys a
		 left join diffusion_blocks.county_geoms b
		 on a.county_fips = b.county_fips and a.state_fips = b.state_fips
		 where a.sector = 'I'),
	knowngeoms_ind as (
		select a.*, b.the_geom_96703_5m as the_geom_96703
		from diffusion_data_shared.cnty_util_type_weight_ind a
		left join diffusion_blocks.county_geoms b
		on a.county_fips = b.county_fips and a.state_fips = b.state_fips  
	    ),
	nn as (
		select 
			(case when b.utility_type = 'IOU' then 1
	 			when b.utility_type = 'Coop' then 2
	 			when b.utility_type = 'Muni' then 3
	 			when b.utility_type = 'Other' then 4 end)::int as utility_id,
			a.state_fips,
			a.county_fips,
			a.geoid,
			b.utility_type,
			b.util_type_weight
		from missing_cntys a
		left join knowngeoms_ind b
		on a.state_fips = b.state_fips
		and st_distance(a.the_geom_96703, b.the_geom_96703) <= 80467.2),
	sum_util_weights as (
		select 
			utility_id, 
			state_fips,
			county_fips, 
			utility_type, 
			sum(util_type_weight) as util_type_weight
		from nn
		group by utility_id, 
			state_fips,
			county_fips, 
			utility_type
		order by state_fips, county_fips, utility_type
		)
	select 
		a.utility_id, 
		'I'::text as sector,
		b.state_fips, 
		b.county_fips, 
		a.utility_type, 
		a.util_type_weight
	from sum_util_weights a
	left join diffusion_blocks.county_geoms b
	on a.county_fips = b.county_fips and a.state_fips = b.state_fips  
	)
select * from com 
union all 
select * from ind
union all
select * from res
);


-------------------------------------------------------------------------------------------------------------------------------------------
-- QAQC
-- NEXT --> check to make sure that all missing cntys are accounted for (in at least 1 utility type)
select county_fips, state_fips, (county_fips || state_fips)
from diffusion_data_shared.cnty_util_type_weight_missing_cntys
where sector = 'C'
and (county_fips || state_fips) not in (select (county_fips || state_fips) from diffusion_data_shared.cnty_util_type_weight_missing_cntys_nn where sector = 'C');
	-- (if 0 then good to go)
		-- total = 0 √

select county_fips, state_fips, (county_fips || state_fips)
from diffusion_data_shared.cnty_util_type_weight_missing_cntys
where sector = 'I'
and (county_fips || state_fips) not in (select (county_fips || state_fips) from diffusion_data_shared.cnty_util_type_weight_missing_cntys_nn where sector = 'I');
	-- (if 0 then good to go)
		-- total = 0 √

select county_fips, state_fips, (county_fips || state_fips)
from diffusion_data_shared.cnty_util_type_weight_missing_cntys
where sector = 'R'
and (county_fips || state_fips) not in (select (county_fips || state_fips) from diffusion_data_shared.cnty_util_type_weight_missing_cntys_nn where sector = 'R');
	-- (if 0 then good to go)
		-- total = 0 √



