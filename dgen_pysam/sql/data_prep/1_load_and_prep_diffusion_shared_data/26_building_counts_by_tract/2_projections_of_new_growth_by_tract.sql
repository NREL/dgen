set role 'diffusion-writers';

drop table if exists diffusion_blocks.tract_building_growth_aeo_2015 CASCADE;
CREATE TABLE diffusion_blocks.tract_building_growth_aeo_2015 AS
select a.tract_id_alias, 
	d.scenario,
	d.year,
	round(a.bldg_count_com * d.com_growth, 3) as new_bldgs_com,
	round(a.bldg_count_res_single_family * d.res_single_family_growth, 3) as new_bldgs_res_single_family,
	round(a.bldg_count_res_multi_family * d.res_multi_family_growth, 3) as new_bldgs_res_multi_family
from diffusion_blocks.tract_building_count_by_sector a
lEFT JOIN diffusion_blocks.tract_ids b
ON a.tract_id_alias = b.tract_id_alias
lEFT JOIN diffusion_shared.state_fips_lkup c
ON b.state_fips::INTEGER = c.state_fips
left join diffusion_shared.aeo_new_building_multipliers_2015 d
ON c.state_abbr = d.state_abbr;

-- add primary key on state, year, scenario
ALTER TABLE diffusion_blocks.tract_building_growth_aeo_2015
ADD PRIMARY KEY (tract_id_alias, year, scenario);

-- add indices
create INDEX tract_building_growth_aeo_2015_btree_state_abbr
on diffusion_blocks.tract_building_growth_aeo_2015
using btree(tract_id_alias);

create INDEX tract_building_growth_aeo_2015_btree_year
on diffusion_blocks.tract_building_growth_aeo_2015
using btree(year);

create INDEX tract_building_growth_aeo_2015_btree_scenario
on diffusion_blocks.tract_building_growth_aeo_2015
using btree(scenario);