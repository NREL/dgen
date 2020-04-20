alter table diffusion_data_shared.cnty_util_type_all_potential_combos_20170103
owner to "diffusion-writers";
alter table diffusion_data_shared.cntys_ranked_rates_lkup_20170103
owner to "diffusion-writers";
alter table diffusion_data_shared.urdb_rates_attrs_lkup_20170103
owner to "diffusion-writers";


set role "diffusion-writers"; 
drop table if exists diffusion_data_shared.cnty_ranked_rates_final_20170103;
create table diffusion_data_shared.cnty_ranked_rates_final_20170103 as (
	select 
		a.geoid,
		a.county_fips,
		a.state_fips, 
		a.utility_type as rank_utility_type,
		--a.rank_id, 
		b.rank, 
		c.util_reg_gid, 
		c.eia_id, 
		c.rate_id_alias, 
		c.utility_type,
		--c.state_fips,
		c.sector, 
		cast(c.demand_min as numeric), 
		cast(c.demand_max as numeric), 
		cast(c.energy_min as numeric), 
		cast(c.energy_max as numeric)
	from diffusion_data_shared.cnty_util_type_all_potential_combos_20170103 a --*
	--left join diffusion_data_shared.cnty_to_util_type_lkup b
	left join diffusion_data_shared.cntys_ranked_rates_lkup_20170103 b --*
	on a.gid = b.gid
	left join diffusion_data_shared.urdb_rates_attrs_lkup_20170103 c -- ***************
	on b.rate_util_reg_gid = c.rate_util_reg_gid
	);

-- Check to make sure DC is accounted for
select * from diffusion_data_shared.urdb_rates_attrs_lkup_20170103 where eia_id = '15270';

-- Alter table name I randomly made for testing purposes (table has rate type info) 
	-- Run python code(13A_parse_rate_type_from_json.py) first to excnty rate type json (its 100x faster in py)
drop table if exists diffusion_data_shared.urdb_rates_type_lkup;
alter table diffusion_data_shared.urdb_rates_same_min_max_2
rename to urdb_rates_type_lkup;
alter table diffusion_data_shared.urdb_rates_type_lkup
add column tou boolean;
alter table diffusion_data_shared.urdb_rates_type_lkup
owner to "diffusion-writers";

update diffusion_data_shared.urdb_rates_type_lkup
set tou = case when dtou is True or etou is True then True else False end;

update diffusion_data_shared.urdb_rates_sam_min_max
set demand_min = '1e+9' where demand_min = '1e+99';
update diffusion_data_shared.urdb_rates_sam_min_max
set demand_max = '1e+9' where demand_max = '1e+99';

-- Create indices
create index cnty_ranked_rates_20170103_geoid on diffusion_shared.cntys_ranked_rates_lkup_20170103 using btree(geoid);
create index cnty_ranked_rates_final_20170103_rate_id_alias on diffusion_data_shared.cnty_ranked_rates_final_20170103 using btree(rate_id_alias);
create index urdb_rates_sam_min_max_rate_id_alias on diffusion_data_shared.urdb_rates_sam_min_max using btree(rate_id_alias);
create index urdb_rates_type_lkup_rate_id_alias on diffusion_data_shared.urdb_rates_type_lkup using btree(rate_id_alias);


set role 'diffusion-writers';
drop table if exists diffusion_shared.cntys_ranked_rates_lkup_20170103;
create table diffusion_shared.cntys_ranked_rates_lkup_20170103 as (
		select 
			a.geoid,
			a.county_fips,
			a.state_fips, 
			a.rank_utility_type,
			a.rate_id_alias as rate_id_alias,
			a.rank as rate_rank,
			a.rank_utility_type as rate_utility_type,
			a.sector as sector,
			a.demand_min as min_demand_kw, 
			(case when a.demand_max = 1e+99 then 1e9 else a.demand_max end) as max_demand_kw, 
			a.energy_min as min_energy_kwh, 
			(case when a.energy_max = 1e+99 then 1e9 else a.energy_max end) as max_energy_kwh,
			b.tou as rate_type_tou
		from diffusion_data_shared.cnty_ranked_rates_final_20170103 a
		left join diffusion_data_shared.urdb_rates_type_lkup b
		on a.rate_id_alias = b.rate_id_alias
	);

create index cnty_ranked_rates_20170103_cnty_id_alias on diffusion_shared.cntys_ranked_rates_lkup_20170103 using btree(cnty_id_alias);
create index cnty_ranked_rates_20170103_rate_id_alias on diffusion_shared.cntys_ranked_rates_lkup_20170103 using btree(rate_id_alias);
create index cnty_ranked_rates_20170103_sector on diffusion_shared.cntys_ranked_rates_sector using btree(sector_abbr);
create index cnty_ranked_rates_20170103_rank_utility_type on diffusion_shared.cntys_ranked_rates_sector using btree(rank_utility_type);


create table diffusion_shared.urdb3_rate_sam_jsons_20170103 as (
select * from urdb_rates.urdb3_verified_rates_sam_data_20170103);
alter table diffusion_shared.urdb3_rate_sam_jsons_20170103
owner to "diffusion-writers";
alter table diffusion_shared.urdb3_rate_sam_jsons_20170103
add primary key (rate_id_alias);




-- Add county id
alter table diffusion_shared.cnty_util_type_weights_com
set owner to "diffusion-writers";
alter table diffusion_shared.cnty_util_type_weights_com
add column county_id bigint;
update diffusion_shared.cnty_util_type_weights_com a
set county_id = (select b.county_id from diffusion_blocks.county_geoms b where a.state_fips = b.state_fips and a.county_fips = b.county_fips);

alter table diffusion_shared.cnty_util_type_weights_res
set owner to "diffusion-writers";
alter table diffusion_shared.cnty_util_type_weights_res
add column county_id bigint;
update diffusion_shared.cnty_util_type_weights_res a
set county_id = (select b.county_id from diffusion_blocks.county_geoms b where a.state_fips = b.state_fips and a.county_fips = b.county_fips);

alter table diffusion_shared.cnty_util_type_weights_res
set owner to "diffusion-writers";
alter table diffusion_shared.cnty_util_type_weights_ind
add column county_id bigint;
update diffusion_shared.cnty_util_type_weights_ind a
set county_id = (select b.county_id from diffusion_blocks.county_geoms b where a.state_fips = b.state_fips and a.county_fips = b.county_fips);

alter table diffusion_shared.cntys_ranked_rates_lkup_20170103
set owner to "diffusion-writers";
alter table diffusion_shared.cntys_ranked_rates_lkup_20170103
add column county_id bigint;
update diffusion_shared.cntys_ranked_rates_lkup_20170103 a
set county_id = (select b.county_id from diffusion_blocks.county_geoms b where a.state_fips = b.state_fips and a.county_fips = b.county_fips);

-- Add eia_id to json
update diffusion_shared.urdb3_rate_sam_jsons_20170103
set json = (trim( trailing '}' from json::text) || ', "eia_id": "' ||eia_id||'"}')::json


-- TODO -- rename the same_min_max_2 table and document py code in 4_ sql