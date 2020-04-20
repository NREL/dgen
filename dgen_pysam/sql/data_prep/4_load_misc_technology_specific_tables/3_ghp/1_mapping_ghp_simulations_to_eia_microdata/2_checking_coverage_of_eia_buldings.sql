-- test join for commercial
WITH a as
(
	select a.baseline_type,
		a.provided,
		b.sector_abbr,
		b.pba, 
		b.pba_desc,
		b.typehuq, 
		b.typehuq_desc,
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
		on a.baseline_cooling = d.baseline_cooling
)
select 	sum(sample_wt * (kbtu_space_heat + kbtu_space_cool))
from diffusion_shared.cbecs_recs_expanded_combined  b
left join a
on a.pba = b.pba
and a.space_heat_equip = b.space_heat_equip
and a.space_heat_fuel = b.space_heat_fuel
and a.space_cool_equip = b.space_cool_equip
and a.space_cool_fuel = b.space_cool_fuel
where b.sector_abbr = 'com'
and a.baseline_type is not null
and a.provided = True;
-- 966859170784.26 provided so far, 1722450178969.06.44 eventually
-- 2016-10-11 update:
-- 1250395831259.91 provided with updated ORNL sims, 1722450178969.06.44 eventually
-- vs
select sum(sample_wt * (kbtu_space_heat + kbtu_space_cool))
from diffusion_shared.cbecs_recs_expanded_combined a
WHERE a.sector_abbr = 'com';
-- 2902688529218.28

select 1722450178969.06/2902688529218.; -- 59% covered eventually
select 966859170784/2902688529218.; -- 33% covered so far

--2016-10-11 update:
select 1722450178969.06/2902688529218.; -- 59% covered eventually
select 1250395831259.91/2902688529218.; -- 43% covered so far

-- to see what's not covered:
-- with a as
-- (
-- 	select a.*
-- 	from diffusion_shared.cbecs_recs_expanded_combined a
-- 	LEFT JOIN diffusion_geo.ornl_building_type_lkup b
-- 		ON a.pba = b.pba
-- 		and a.sector_abbr = b.sector_abbr
-- 	LEFT JOIN diffusion_geo.ornl_baseline_heating_lkup c
-- 		ON a.space_heat_equip = c.eia_system_type
-- 		and a.space_heat_fuel = c.eia_fuel_type
-- 		and a.sector_abbr = c.sector_abbr
-- 	LEFT JOIN diffusion_geo.ornl_baseline_cooling_lkup d
-- 		ON a.space_cool_equip = d.eia_system_type
-- 		and a.space_cool_fuel = d.eia_fuel_type
-- 		and a.sector_abbr = d.sector_abbr
-- 	LEFT JOIN diffusion_geo.ornl_simulations_lkup e
-- 		ON b.building_type = e.building_type
-- 		and c.baseline_heating = e.baseline_heating
-- 		and d.baseline_cooling = e.baseline_cooling
-- 	WHERE a.sector_abbr = 'com'
-- 	AND e.building_id is null
-- )
-- select space_cool_equip, space_cool_fuel,
-- 	space_heat_equip, space_heat_fuel,
-- 	pba,
-- 	round(sum(sample_wt * (kbtu_space_heat + kbtu_space_cool))::NUMERIC, 0) as total_kbtu
-- from a
-- where pba not in (6 ,4, 11)
-- group by space_cool_equip, space_cool_fuel,
-- 	space_heat_equip, space_heat_fuel,
-- 	pba
-- order by total_kbtu desc;

----------------------------------------------------------------------------
-- test join for residential
WITH a as
(
	select a.baseline_type,
		a.provided,
		b.sector_abbr,
		b.pba, 
		b.pba_desc,
		b.typehuq, 
		b.typehuq_desc,
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
		on a.baseline_cooling = d.baseline_cooling
)
select 	sum(sample_wt * (kbtu_space_heat + kbtu_space_cool))
from diffusion_shared.cbecs_recs_expanded_combined  b
left join a
on a.typehuq = b.typehuq
and a.space_heat_equip = b.space_heat_equip
and a.space_heat_fuel = b.space_heat_fuel
and a.space_cool_equip = b.space_cool_equip
and a.space_cool_fuel = b.space_cool_fuel
where b.sector_abbr = 'res'
and a.baseline_type is not null
and a.provided = true;


-- 3635994524189.14 eventually, 3320713162463.03 provided so far
-- 2016-10-11 update:
-- 3635994524189.14 provided so far
-- vs
select  sum(sample_wt * (kbtu_space_heat + kbtu_space_cool))
from diffusion_shared.cbecs_recs_expanded_combined a
WHERE a.sector_abbr = 'res';
-- 4870316830087.82 total

select 3635994524189.14/4870316830087.; -- 75% eventually
select 3320713162463.02/4870316830087.; -- 68% -- so far

-- 2016-10-11 update:
select 3635994524189.14/4870316830087.; -- 75% eventually
select 3635994524189.14/4870316830087.; -- 75% -- so far
-- seems sufficient

-- what's not covered:
-- with a as
-- (
-- 	select a.*
-- 	from diffusion_shared.cbecs_recs_expanded_combined a
-- 	LEFT JOIN diffusion_geo.ornl_building_type_lkup b
-- 		ON a.typehuq = b.typehuq
-- 		and a.sector_abbr = b.sector_abbr
-- 	LEFT JOIN diffusion_geo.ornl_baseline_heating_lkup c
-- 		ON a.space_heat_equip = c.eia_system_type
-- 		and a.space_heat_fuel = c.eia_fuel_type
-- 		and a.sector_abbr = c.sector_abbr
-- 	LEFT JOIN diffusion_geo.ornl_baseline_cooling_lkup d
-- 		ON a.space_cool_equip = d.eia_system_type
-- 		and a.space_cool_fuel = d.eia_fuel_type
-- 		and a.sector_abbr = c.sector_abbr
-- 	LEFT JOIN diffusion_geo.ornl_simulations_lkup e
-- 		ON b.building_type = e.building_type
-- 		and c.baseline_heating = e.baseline_heating
-- 		and d.baseline_cooling = e.baseline_cooling
-- 	WHERE a.sector_abbr = 'res'
-- 	AND e.building_id is null
-- )
-- select space_cool_equip, space_cool_fuel,
-- 	space_heat_equip, space_heat_fuel,
-- 	typehuq,
-- 	round(sum(sample_wt * (kbtu_space_heat + kbtu_space_cool))::NUMERIC, 0) as total_kbtu
-- from a
-- group by space_cool_equip, space_cool_fuel,
-- 	space_heat_equip, space_heat_fuel,
-- 	typehuq
-- order by total_kbtu desc;