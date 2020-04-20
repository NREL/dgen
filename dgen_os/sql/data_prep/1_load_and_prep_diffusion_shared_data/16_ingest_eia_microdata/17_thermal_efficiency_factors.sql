set role 'diffusion-writers';

DROP TABLE IF EXISTS diffusion_geo.cbecs_recs_thermal_efficiency_factors;
CREATE TABLE diffusion_geo.cbecs_recs_thermal_efficiency_factors
(
	equipment_type text,
	fuel text,
	end_use text,
	sector_abbr varchar(3),
	count integer,
	efficiency numeric,
	notes text
);

\COPY diffusion_geo.cbecs_recs_thermal_efficiency_factors from '/Volumes/Staff/mgleason/dGeo/Data/Source_Data/Thermal_Demand_kmccabe/equip_fuel_types_and_efficiencies.csv' with csv header;

-- drop the count field
ALTER TABLE diffusion_geo.cbecs_recs_thermal_efficiency_factors
DROP COLUMN count;

-- edit the efficiency field to be decimal
UPDATE diffusion_geo.cbecs_recs_thermal_efficiency_factors
set efficiency = round(efficiency/100, 2)
where end_use <> 'space_cool';
-- 138 rows

-- add primary key
ALTER TABLE diffusion_geo.cbecs_recs_thermal_efficiency_factors
ADD PRIMARY KEY (equipment_type, fuel, end_use, sector_abbr);

-- look at the data
select *
FROM diffusion_geo.cbecs_recs_thermal_efficiency_factors;

-- check results -- does it cover all records in the microdata?
-- check space heat first
select count(a.*)
from diffusion_shared.cbecs_recs_expanded_combined a
left join diffusion_geo.cbecs_recs_thermal_efficiency_factors b
on a.sector_abbr = b.sector_abbr
and a.space_heat_equip = b.equipment_type
and a.space_heat_fuel = b.fuel
where a.sector_abbr <> 'ind'
and b.end_use = 'space_heat'
and b.efficiency is null;
-- 0 all set

-- check space cool next
select count(a.*)
from diffusion_shared.cbecs_recs_expanded_combined a
left join diffusion_geo.cbecs_recs_thermal_efficiency_factors b
on a.sector_abbr = b.sector_abbr
and a.space_cool_equip = b.equipment_type
and a.space_cool_fuel = b.fuel
where a.sector_abbr <> 'ind'
and b.end_use = 'space_cool'
and b.efficiency is null;
-- 0 all set

-- check water heat last
select count(a.*)
from diffusion_shared.cbecs_recs_expanded_combined a
left join diffusion_geo.cbecs_recs_thermal_efficiency_factors b
on a.sector_abbr = b.sector_abbr
and a.water_heat_equip = b.equipment_type
and a.water_heat_fuel = b.fuel
where a.sector_abbr <> 'ind'
and b.end_use = 'water_heat'
and b.efficiency is null;
-- 0 all set