-- Move cnty_util_type_weight lkups
drop table if exists diffusion_shared.cnty_util_type_weights_res;
create table diffusion_shared.cnty_util_type_weights_res as (
	select 
		(case when utility_type = 'IOU' then 1
		when utility_type = 'Coop' then 2
		when utility_type = 'Muni' then 3
		when utility_type = 'Other' then 4 end)::int as utility_id, 
		'R'::text as sector,
		*
	from diffusion_data_shared.cnty_util_type_weight_res
	union all
	select 
		utility_id, 
		state_fips, 
		county_fips, 
		(state_fips || county_fips) as geoid,
		--cnty_fips, 
		--cnty_id_alias, 
		utility_type, 
		util_type_weight
	from diffusion_data_shared.cnty_util_type_weight_missing_cntys_nn
	where sector = 'R'
	);



--set role 'diffusion-writers';
drop table if exists diffusion_shared.cnty_util_type_weights_com;
create table diffusion_shared.cnty_util_type_weights_com as (
	select 
		(case when utility_type = 'IOU' then 1
		when utility_type = 'Coop' then 2
		when utility_type = 'Muni' then 3
		when utility_type = 'Other' then 4 end)::int as utility_id, 
		'C'::text as sector,
		*
		from diffusion_data_shared.cnty_util_type_weight_com
			union all
	select 
		utility_id, 
		state_fips, 
		county_fips, 
		(state_fips || county_fips) as geoid
		utility_type, 
		util_type_weight
	from diffusion_data_shared.cnty_util_type_weight_missing_cntys_nn
	where sector = 'C');

--set role 'diffusion-writers';
drop table if exists diffusion_shared.cnty_util_type_weights_ind;
create table diffusion_shared.cnty_util_type_weights_ind as (
	select 
		(case when utility_type = 'IOU' then 1
		when utility_type = 'Coop' then 2
		when utility_type = 'Muni' then 3
		when utility_type = 'Other' then 4 end)::int as utility_id, 
		'I'::text as sector,
		*
	from diffusion_data_shared.cnty_util_type_weight_ind
	union all
	select
		utility_id, 
		state_fips, 
		county_fips, 
		(state_fips || county_fips) as geoid,
		utility_type, 
		util_type_weight
	from diffusion_data_shared.cnty_util_type_weight_missing_cntys_nn
	where sector = 'I');


-----------
-- QAQC
-- check to make sure that all missing cntys are accounted for
-- remove any 0 weights (these will throw off the sample)
-- check again
		-- com
		with a as (select * from diffusion_data_shared.cnty_util_type_weight_missing_cntys where sector = 'C')
		select * from a
		where (state_fips || county_fips) not in 
		(select (state_fips || county_fips) from diffusion_shared.cnty_util_type_weights_com);
		-- 0 rows missing (all accounted for)
		--232 --******

		-- res
		with a as (select * from diffusion_data_shared.cnty_util_type_weight_missing_cntys where sector = 'R')
		select * from a
		where (state_fips || county_fips) not in 
		(select (state_fips || county_fips) from diffusion_shared.cnty_util_type_weights_res);
		-- 0 rows missing (all accounted for)
		-- 265 - ********

		-- ind
		with a as (select * from diffusion_data_shared.cnty_util_type_weight_missing_cntys where sector = 'I')
		select * from a
		where (state_fips || county_fips) not in 
		(select (state_fips || county_fips) from diffusion_shared.cnty_util_type_weights_ind);
		-- 920 rows missing
		-- 0 rows missing (all accounted for)


-- drop table
	drop table if exists diffusion_data_shared.cnty_util_type_weight_com;
	drop table if exists diffusion_data_shared.cnty_util_type_weight_res;
	drop table if exists diffusion_data_shared.cnty_util_type_weight_ind;
