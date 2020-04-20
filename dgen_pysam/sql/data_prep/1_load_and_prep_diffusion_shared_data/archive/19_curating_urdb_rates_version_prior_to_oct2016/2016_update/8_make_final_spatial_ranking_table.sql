set role "diffusion-writers";
create table diffusion_data_shared.cnty_ranked_rates_final_20161005 as (
	select b.cnty_geoid10 as rank_cnty_geoid10, b.utility_type as rank_utility_type,
		a.rate_util_reg_gid, a.rank_id, a.rank, 
		c.util_reg_gid, c.eia_id, c.rate_id_alias, c.state_fips,
		b.cnty_geoid10, c.sector, c.demand_min, c.demand_max, c.energy_min, c.energy_max
	from diffusion_data_shared.cnty_ranked_rates_lkup_20161005 a
	left join diffusion_data_shared.cnty_to_util_type_lkup b
	on a.gid = b.gid
	left join diffusion_data_shared.urdb_rates_attrs_lkup_20161005 c
	on a.rate_util_reg_gid = c.rate_util_reg_gid);

-- Add block id?