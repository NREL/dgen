set role 'diffusion-writers';

-- combine lookup tables to create one table showing all options
drop table if exists diffusion_geo.eia_buildings_to_ornl_baseline_lkup;
CREATE TABLE diffusion_geo.eia_buildings_to_ornl_baseline_lkup AS
select a.baseline_type,
	a.provided,
	b.sector_abbr,
	case when b.sector_abbr = 'res' then typehuq
	     when b.sector_abbr = 'com' then pba
	end as pba_or_typehuq,
	case when b.sector_abbr = 'res' then typehuq_desc
	     when b.sector_abbr = 'com' then pba_desc
	end as pba_or_typehuq_desc,	
	c.eia_system_type as space_heat_equip,
	c.eia_fuel_type as space_heat_fuel,
	d.eia_system_type as space_cool_equip,
	d.eia_fuel_type as space_cool_fuel
from diffusion_geo.ornl_simulations_lkup a
lEFT JOIN diffusion_geo.ornl_building_type_lkup b
	ON a.building_type = b.building_type
LEFT JOIN diffusion_geo.ornl_baseline_heating_lkup c
	on a.baseline_heating = c.baseline_heating
LEFT JOIN diffusion_geo.ornl_baseline_cooling_lkup d
	on a.baseline_cooling = d.baseline_cooling;
-- 3964 rows

-- add primary key
ALTER TABLE diffusion_geo.eia_buildings_to_ornl_baseline_lkup
ADD PRIMARY KEY (sector_abbr, 
		 pba_or_typehuq, 
		 space_heat_equip, 
		 space_heat_fuel, 
		 space_cool_equip, 
		 space_cool_fuel);

-- add index on ornl_baseline_type
CREATE INDEX eia_buildings_to_ornl_baseline_lkup_baseline_type_btree
ON diffusion_geo.eia_buildings_to_ornl_baseline_lkup
USING BTREE(baseline_type);

-- how many ahve been provided so far?
select count(*)
FROM diffusion_geo.eia_buildings_to_ornl_baseline_lkup
where provided = True;
-- 2470 of 3964
-- 2016-10-11 update:
-- 2884 of 3964