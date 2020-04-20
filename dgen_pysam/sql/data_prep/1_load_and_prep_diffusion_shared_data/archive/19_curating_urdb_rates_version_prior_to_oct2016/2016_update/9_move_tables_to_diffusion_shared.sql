set role 'diffusion-writers;'
-- Move Tables to Diffusion Shared
	-- 1. Copy Ranks
drop table if exsits diffusion_shared.cnty_ranked_rates_final_20161005;
create table diffusion_shared.cnty_ranked_rates_final_20161005 as (
	select * from diffusion_data_shared.cnty_ranked_rates_final_20161005);
	-- 2. Copy Sam Data
drop table if exists diffusion_shared.urdb3_rate_sam_jsons_20161005;
create table diffusion_shared.urdb3_rate_sam_jsons_20161005 as (
	select distinct rate_id_alias, json from diffusion_data_shared.urdb_rates_sam_min_max);

-- Change Ownership of all tables
alter table diffusion_data_shared.cnty_ranked_rates_lkup_20161005
owner to "diffusion-writers";
alter table diffusion_data_shared.cnty_to_util_type_lkup
owner to "diffusion-writers";
alter table diffusion_data_shared.urdb_rates_attrs_lkup_20161005
owner to "diffusion-writers";
alter table diffusion_data_shared.urdb_rates_geoms_20161005
owner to "diffusion-writers";