set role 'diffusion-writers';

------------------------------------------------------------------------------------------------------------
-- check that the spatial assignments of pts to blockgroups performed
-- before will completely represent all pts in the res grid
select count(*)
from diffusion_shared.pt_grid_us_res a
LEFT JOIN diffusion_data_wind.pt_grid_us_res_new_acs_2012_blockgroup_lkup b
ON a.gid = b.gid
where b.gid is null;
-- 0  missing -- all set

------------------------------------------------------------------------------------------------------------

-- check that the types of heating represented in Census can be reproduced in RECS
DROP TABLE IF EXISTS diffusion_data_shared.heating_fuel_representation_check;
CREATE TABLE diffusion_data_shared.heating_fuel_representation_check AS
with a as
(
	select b.reportable_domain, 
		sum(a.natural_gas) as natural_gas, 
		sum(a.propane) as propane, 
		sum(a.electricity) as electricity, 
		sum(a.distallate_fuel_oil) as distallate_fuel_oil, 
		sum(a.wood) as wood, 
		sum(a.solar_energy) as solar_energy, 
		sum(a.other + a.coal_or_coke) as other, 
		sum(a.no_fuel) as no_fuel,
		sum(a.natural_gas+a.propane+a.electricity+a.distallate_fuel_oil+a.wood+a.solar_energy+a.other+a.coal_or_coke+a.no_fuel) as hu
	from diffusion_shared.acs_2012_blockgroup_housing_units_by_fuel_type a
	left join eia.recs_2009_state_to_reportable_domain_lkup b
	ON substring(a.gisjoin, 2, 2) = b.state_fips
	GROUP by b.reportable_domain
),
b as
(
	select reportable_domain, 
		sum((space_heat_fuel = 'natural gas')::INTEGER) as natural_gas,
		sum((space_heat_fuel = 'propane')::INTEGER) as propane,
		sum((space_heat_fuel = 'electricity')::INTEGER) as electricity,
		sum((space_heat_fuel = 'distallate fuel oil')::INTEGER) as distallate_fuel_oil,
		sum((space_heat_fuel = 'wood')::INTEGER) as wood,
		sum((space_heat_fuel = 'solar energy')::INTEGER) as solar_energy,
		sum((space_heat_fuel = 'other')::INTEGER) as other,
		sum((space_heat_fuel = 'no fuel')::INTEGER) as no_fuel
	from diffusion_shared.eia_microdata_recs_2009_expanded_bldgs a
	group by reportable_domain
)
select a.reportable_domain,
	(a.natural_gas > 0 and b.natural_gas = 0) as natural_gas_not_represented,
	(a.propane > 0 and b.propane = 0) as propane_not_represented,
	(a.electricity > 0 and b.electricity = 0) as electricity_not_represented,
	(a.distallate_fuel_oil > 0 and b.distallate_fuel_oil = 0) as distallate_fuel_oil_not_represented,
	(a.wood > 0 and b.wood = 0) as wood_not_represented,
	(a.solar_energy > 0 and b.solar_energy = 0) as solar_energy_not_represented,
	(a.other > 0 and b.other = 0) as other_not_represented,
	(a.no_fuel > 0 and b.no_fuel = 0) as no_fuel_not_represented,
	a.natural_gas as acs_natural_gas, b.natural_gas as recs_natural_gas,
	a.propane as acs_propane, b.propane as recs_propane,
	a.electricity as acs_electricity, b.electricity as recs_electricity,
	a.distallate_fuel_oil as acs_distallate_fuel_oil, b.distallate_fuel_oil as recs_distallate_fuel_oil,
	a.wood as acs_wood, b.wood as recs_wood,
	a.solar_energy as acs_solar_energy, b.solar_energy as recs_solar_energy,
	a.other as acs_other, b.other as recs_other,
	a.no_fuel as acs_no_fuel, b.no_fuel as recs_no_fuel,
	a.hu
from a
left join b
ON a.reportable_domain = b.reportable_domain
where a.reportable_domain is not null;
-- 27 rows

-- check for problematic fuel types
SELECT count(*)
FROM diffusion_data_shared.heating_fuel_representation_check
where natural_gas_not_represented = True;
-- 0 rows, all set

SELECT count(*)
FROM diffusion_data_shared.heating_fuel_representation_check
where propane_not_represented = True;
-- 0 rows, all set

SELECT count(*)
FROM diffusion_data_shared.heating_fuel_representation_check
where electricity_not_represented = True;
-- 0 rows, all set

SELECT count(*)
FROM diffusion_data_shared.heating_fuel_representation_check
where wood_not_represented = True;
-- 0 rows, all set

-- problematic fuel types are: dfo, solar, other, none
-- each is investigated below
SELECT reportable_domain, round(acs_solar_energy/hu::NUMERIC, 4) as pct, acs_solar_energy, recs_solar_energy
FROM diffusion_data_shared.heating_fuel_representation_check
where solar_energy_not_represented = True
order by pct;
-- 26 rows, but max % of all HU is 0.1% -- safe to ignore "solar energy" completely

SELECT reportable_domain, round(acs_other/hu::NUMERIC, 4) as pct, acs_other, recs_other
FROM diffusion_data_shared.heating_fuel_representation_check
where other_not_represented = True
order by pct;
-- 14 rows, but max% of all HU is 0.8% -- safe to ignore "other" completely

SELECT reportable_domain, round(acs_no_fuel/hu::NUMERIC, 4) as pct, acs_no_fuel, recs_no_fuel
FROM diffusion_data_shared.heating_fuel_representation_check
where no_fuel_not_represented = True
order by pct;
-- 13 rows -- but max% of all HU is 0.6% -- safe to ignore "no fuel" completely

SELECT reportable_domain, round(acs_distallate_fuel_oil/hu::NUMERIC, 4) as pct, acs_distallate_fuel_oil, recs_distallate_fuel_oil
FROM diffusion_data_shared.heating_fuel_representation_check
where distallate_fuel_oil_not_represented = True
order by pct;
-- 8 rows
-- 7/8 are <1%, so we can probably ignore them
-- for RD 23 (UT, WY, ID, MT), 1% of HU in the reportable domain use dfo
-- still think it's okay to ignore
-- RDs for which to exclude dfo are:
	-- 24
	-- 20
	-- 21
	-- 22
	-- 6
	-- 11
	-- 19
	-- 23

-- these correspond to the following fips codes:
select state_fips
from eia.recs_2009_state_to_reportable_domain_lkup
where reportable_domain in (24, 20, 21, 22, 6, 11, 19, 23);
-- 05
-- 04
-- 08
-- 16
-- 17
-- 20
-- 22
-- 30
-- 31
-- 40
-- 47
-- 48
-- 49
-- 56
-- where state fips is in this set, set dfo count to 0


------------------------------------------------------------------------------------------------------------
-- add the new column
ALTER TABLE diffusion_shared.pt_grid_us_res
ADD COLUMN heating_type_probs integer[];

-- run the update
WITH b as
(
	select a.gid, 
		array[b.natural_gas, 
			b.propane, 
			b.electricity, 
			CASE WHEN substring(a.blockgroup_gisjoin, 2, 2) in ('05', '04', '08', '16', '17', '20', '22', '30', '31', '40', '47', '48', '49', '56') THEN 0 -- see explanation in previous code block
			ELSE b.distallate_fuel_oil
			END, 
			b.wood] as heating_type_probs
	from diffusion_data_wind.pt_grid_us_res_new_acs_2012_blockgroup_lkup a
	LEFT JOIN diffusion_shared.acs_2012_blockgroup_housing_units_by_fuel_type b
	ON a.blockgroup_gisjoin = b.gisjoin
)
UPDATE diffusion_shared.pt_grid_us_res a
set heating_type_probs = b.heating_type_probs
from b
where a.gid = b.gid;
-- 5751859 rows updated

-- add a comment on the column defining the order of the fuel types
COMMENT ON COLUMN diffusion_shared.pt_grid_us_res.heating_type_probs IS
'Fuel Types are (in order): natural gas, propane, electricity, distallate fuel oil, wood';

-- check for nulls
select count(*)
FROM diffusion_shared.pt_grid_us_res
where heating_type_probs is null
or heating_type_probs = array[]::INTEGER[];
-- 0 -- good

-- check for pts with sum of all probs = 0
select count(*)
FROM diffusion_shared.pt_grid_us_res
where r_array_sum(heating_type_probs) = 0;
-- 324 -- not ideal

-- which points
DROP TABLE IF EXISTS  diffusion_data_shared.pt_grid_us_res_no_fuel_types;
CREATE TABLE diffusion_data_shared.pt_grid_us_res_no_fuel_types AS
select *
FROM diffusion_shared.pt_grid_us_res
where r_array_sum(heating_type_probs) = 0;
-- look at them in Q

select a.gid, c.*
from diffusion_data_shared.pt_grid_us_res_no_fuel_types a
left join diffusion_data_wind.pt_grid_us_res_new_acs_2012_blockgroup_lkup b
ON a.gid = b.gid
LEFT JOIN diffusion_shared.acs_2012_blockgroup_housing_units_by_fuel_type c
ON b.blockgroup_gisjoin = c.gisjoin;
-- all of these have either 0 across all fuel types, or just <= 10 HU in the no_fuel class

-- safe to drop these points
DELETE FROM diffusion_shared.pt_grid_us_res
where r_array_sum(heating_type_probs) = 0;
-- 324 points deleted

------------------------------------------------------------------------------------------------------------
-- create a table that defines the order of all heating fuel types
DROP TABLE IF EXISTS diffusion_shared.heating_fuel_type_array;
CREATE TABLE diffusion_shared.heating_fuel_type_array
(
	heating_type_array text[]
);

INSERT INTO diffusion_shared.heating_fuel_type_array
select array
[
	'natural gas', 
	'propane', 
	'electricity', 
	'distallate fuel oil', 
	'wood'
];
-- note: the formatting matches the distinct space_heat_fuel values in diffusion_shared.eia_microdata_recs_2009_expanded_bldgs

-- check results
select *
FROM diffusion_shared.heating_fuel_type_array;
