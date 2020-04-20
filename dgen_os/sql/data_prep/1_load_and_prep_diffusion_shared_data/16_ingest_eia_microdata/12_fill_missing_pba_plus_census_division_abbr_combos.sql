set role 'diffusion-writers';

-- check for missing combos 
with a as
(
	select distinct pbaplus
	from diffusion_shared.eia_microdata_cbecs_2003_expanded
),
b as
(
	select distinct census_division_abbr
	from diffusion_shared.eia_microdata_cbecs_2003_expanded
),
c as
(
	select a.pbaplus, b.census_division_abbr
	from a
	cross join b
),
d as
(
	select distinct census_division_abbr, pbaplus
	from diffusion_shared.eia_microdata_cbecs_2003_expanded
)
select c.census_division_abbr, c.pbaplus
from c
left join d
ON c.pbaplus = d.pbaplus
and c.census_division_abbr = d.census_division_abbr
where d.pbaplus is null;
-- several missing combos: (solution noted)
-- WSC,15 -- replace with data from SA (ESC is not available)
-- WSC,44 -- replace with data from ESC
-- MTN,20 -- replace with data from PAC
-- MTN,44 -- replace with data from PAC
-- NE,34 -- replace with data from ENC
-- NE,46 -- replace with data from ENC
-- NE,48 -- replace with data from ENC
-- NE,15 -- replace with data from ENC
-- NE,30 -- replace with data from ENC
-- NE,20 -- replace with data from ENC
-- WNC,8 -- replace with data from ENC
-- WNC,15 -- replace with data from ENC
-- ESC,15 -- replace with data from SA (WCS is not available)


-- need to use new building ids
select max(building_id)
FROM diffusion_shared.eia_microdata_cbecs_2003_expanded;
-- 12083

DROP SEQUENCE IF EXISTS diffusion_shared.eia_microdata_cbecs_2003_expanded_bldg_ids;
CREATE SEQUENCE diffusion_shared.eia_microdata_cbecs_2003_expanded_bldg_ids
INCREMENT 1
START 6218;

-- WSC,15 -- replace with data from SA (ESC is not available)
INSERT INTO diffusion_shared.eia_microdata_cbecs_2003_expanded
select nextval('diffusion_shared.eia_microdata_cbecs_2003_expanded_bldg_ids') as building_id, 
	sample_wt, 
	'South' as census_region, 
	'WSC' as census_division_abbr, 
       reportable_domain, climate_zone, pba, pbaplus, typehuq, roof_material, 
       owner_occupied, kwh, year_built, single_family_res, num_tenants, 
       num_floors, space_heat_equip, space_heat_fuel, space_heat_age_min, 
       space_heat_age_max, water_heat_equip, water_heat_fuel, water_heat_age_min, 
       water_heat_age_max, space_cool_equip, space_cool_fuel, space_cool_age_min, 
       space_cool_age_max, ducts, totsqft, totsqft_heat, totsqft_cool, 
       kbtu_space_heat, kbtu_space_cool, kbtu_water_heat, crb_model, 
       roof_style, roof_sqft
from diffusion_shared.eia_microdata_cbecs_2003_expanded
where census_division_abbr = 'SA'
and pbaplus = 15;
-- 2 rows added

-- WSC,44 -- replace with data from ESC
INSERT INTO diffusion_shared.eia_microdata_cbecs_2003_expanded
select nextval('diffusion_shared.eia_microdata_cbecs_2003_expanded_bldg_ids') as building_id, 
	sample_wt, 
	'South' as census_region, 
	'WSC' as census_division_abbr, 
       reportable_domain, climate_zone, pba, pbaplus, typehuq, roof_material, 
       owner_occupied, kwh, year_built, single_family_res, num_tenants, 
       num_floors, space_heat_equip, space_heat_fuel, space_heat_age_min, 
       space_heat_age_max, water_heat_equip, water_heat_fuel, water_heat_age_min, 
       water_heat_age_max, space_cool_equip, space_cool_fuel, space_cool_age_min, 
       space_cool_age_max, ducts, totsqft, totsqft_heat, totsqft_cool, 
       kbtu_space_heat, kbtu_space_cool, kbtu_water_heat, crb_model, 
       roof_style, roof_sqft
from diffusion_shared.eia_microdata_cbecs_2003_expanded
where census_division_abbr = 'ESC'
and pbaplus = 44;
-- 2 rows added


-- MTN,20 -- replace with data from PAC
INSERT INTO diffusion_shared.eia_microdata_cbecs_2003_expanded
select nextval('diffusion_shared.eia_microdata_cbecs_2003_expanded_bldg_ids') as building_id, 
	sample_wt, 
	'West' as census_region, 
	'MTN' as census_division_abbr, 
       reportable_domain, climate_zone, pba, pbaplus, typehuq, roof_material, 
       owner_occupied, kwh, year_built, single_family_res, num_tenants, 
       num_floors, space_heat_equip, space_heat_fuel, space_heat_age_min, 
       space_heat_age_max, water_heat_equip, water_heat_fuel, water_heat_age_min, 
       water_heat_age_max, space_cool_equip, space_cool_fuel, space_cool_age_min, 
       space_cool_age_max, ducts, totsqft, totsqft_heat, totsqft_cool, 
       kbtu_space_heat, kbtu_space_cool, kbtu_water_heat, crb_model, 
       roof_style, roof_sqft
from diffusion_shared.eia_microdata_cbecs_2003_expanded
where census_division_abbr = 'PAC'
and pbaplus = 20;
-- 4 rows added

-- MTN,44 -- replace with data from PAC
INSERT INTO diffusion_shared.eia_microdata_cbecs_2003_expanded
select nextval('diffusion_shared.eia_microdata_cbecs_2003_expanded_bldg_ids') as building_id, 
	sample_wt, 
	'West' as census_region, 
	'MTN' as census_division_abbr, 
       reportable_domain, climate_zone, pba, pbaplus, typehuq, roof_material, 
       owner_occupied, kwh, year_built, single_family_res, num_tenants, 
       num_floors, space_heat_equip, space_heat_fuel, space_heat_age_min, 
       space_heat_age_max, water_heat_equip, water_heat_fuel, water_heat_age_min, 
       water_heat_age_max, space_cool_equip, space_cool_fuel, space_cool_age_min, 
       space_cool_age_max, ducts, totsqft, totsqft_heat, totsqft_cool, 
       kbtu_space_heat, kbtu_space_cool, kbtu_water_heat, crb_model, 
       roof_style, roof_sqft
from diffusion_shared.eia_microdata_cbecs_2003_expanded
where census_division_abbr = 'PAC'
and pbaplus = 44;
-- 1 row added

-- NE,34 -- replace with data from ENC
INSERT INTO diffusion_shared.eia_microdata_cbecs_2003_expanded
select nextval('diffusion_shared.eia_microdata_cbecs_2003_expanded_bldg_ids') as building_id, 
	sample_wt, 
	'Northeast' as census_region, 
	'NE' as census_division_abbr, 
       reportable_domain, climate_zone, pba, pbaplus, typehuq, roof_material, 
       owner_occupied, kwh, year_built, single_family_res, num_tenants, 
       num_floors, space_heat_equip, space_heat_fuel, space_heat_age_min, 
       space_heat_age_max, water_heat_equip, water_heat_fuel, water_heat_age_min, 
       water_heat_age_max, space_cool_equip, space_cool_fuel, space_cool_age_min, 
       space_cool_age_max, ducts, totsqft, totsqft_heat, totsqft_cool, 
       kbtu_space_heat, kbtu_space_cool, kbtu_water_heat, crb_model, 
       roof_style, roof_sqft
from diffusion_shared.eia_microdata_cbecs_2003_expanded
where census_division_abbr = 'ENC'
and pbaplus = 34;
-- 13 rows added

-- NE,46 -- replace with data from ENC
INSERT INTO diffusion_shared.eia_microdata_cbecs_2003_expanded
select nextval('diffusion_shared.eia_microdata_cbecs_2003_expanded_bldg_ids') as building_id, 
	sample_wt, 
	'Northeast' as census_region, 
	'NE' as census_division_abbr, 
       reportable_domain, climate_zone, pba, pbaplus, typehuq, roof_material, 
       owner_occupied, kwh, year_built, single_family_res, num_tenants, 
       num_floors, space_heat_equip, space_heat_fuel, space_heat_age_min, 
       space_heat_age_max, water_heat_equip, water_heat_fuel, water_heat_age_min, 
       water_heat_age_max, space_cool_equip, space_cool_fuel, space_cool_age_min, 
       space_cool_age_max, ducts, totsqft, totsqft_heat, totsqft_cool, 
       kbtu_space_heat, kbtu_space_cool, kbtu_water_heat, crb_model, 
       roof_style, roof_sqft
from diffusion_shared.eia_microdata_cbecs_2003_expanded
where census_division_abbr = 'ENC'
and pbaplus = 46;
-- 28 rows added

-- NE,48 -- replace with data from ENC
INSERT INTO diffusion_shared.eia_microdata_cbecs_2003_expanded
select nextval('diffusion_shared.eia_microdata_cbecs_2003_expanded_bldg_ids') as building_id, 
	sample_wt, 
	'Northeast' as census_region, 
	'NE' as census_division_abbr, 
       reportable_domain, climate_zone, pba, pbaplus, typehuq, roof_material, 
       owner_occupied, kwh, year_built, single_family_res, num_tenants, 
       num_floors, space_heat_equip, space_heat_fuel, space_heat_age_min, 
       space_heat_age_max, water_heat_equip, water_heat_fuel, water_heat_age_min, 
       water_heat_age_max, space_cool_equip, space_cool_fuel, space_cool_age_min, 
       space_cool_age_max, ducts, totsqft, totsqft_heat, totsqft_cool, 
       kbtu_space_heat, kbtu_space_cool, kbtu_water_heat, crb_model, 
       roof_style, roof_sqft
from diffusion_shared.eia_microdata_cbecs_2003_expanded
where census_division_abbr = 'ENC'
and pbaplus = 48;
-- 13 rows added

-- NE,15 -- replace with data from ENC
INSERT INTO diffusion_shared.eia_microdata_cbecs_2003_expanded
select nextval('diffusion_shared.eia_microdata_cbecs_2003_expanded_bldg_ids') as building_id, 
	sample_wt, 
	'Northeast' as census_region, 
	'NE' as census_division_abbr, 
       reportable_domain, climate_zone, pba, pbaplus, typehuq, roof_material, 
       owner_occupied, kwh, year_built, single_family_res, num_tenants, 
       num_floors, space_heat_equip, space_heat_fuel, space_heat_age_min, 
       space_heat_age_max, water_heat_equip, water_heat_fuel, water_heat_age_min, 
       water_heat_age_max, space_cool_equip, space_cool_fuel, space_cool_age_min, 
       space_cool_age_max, ducts, totsqft, totsqft_heat, totsqft_cool, 
       kbtu_space_heat, kbtu_space_cool, kbtu_water_heat, crb_model, 
       roof_style, roof_sqft
from diffusion_shared.eia_microdata_cbecs_2003_expanded
where census_division_abbr = 'ENC'
and pbaplus = 15;
-- 1 row added

-- NE,30 -- replace with data from ENC
INSERT INTO diffusion_shared.eia_microdata_cbecs_2003_expanded
select nextval('diffusion_shared.eia_microdata_cbecs_2003_expanded_bldg_ids') as building_id, 
	sample_wt, 
	'Northeast' as census_region, 
	'NE' as census_division_abbr, 
       reportable_domain, climate_zone, pba, pbaplus, typehuq, roof_material, 
       owner_occupied, kwh, year_built, single_family_res, num_tenants, 
       num_floors, space_heat_equip, space_heat_fuel, space_heat_age_min, 
       space_heat_age_max, water_heat_equip, water_heat_fuel, water_heat_age_min, 
       water_heat_age_max, space_cool_equip, space_cool_fuel, space_cool_age_min, 
       space_cool_age_max, ducts, totsqft, totsqft_heat, totsqft_cool, 
       kbtu_space_heat, kbtu_space_cool, kbtu_water_heat, crb_model, 
       roof_style, roof_sqft
from diffusion_shared.eia_microdata_cbecs_2003_expanded
where census_division_abbr = 'ENC'
and pbaplus = 30;
-- 5 rows added

-- NE,20 -- replace with data from ENC
INSERT INTO diffusion_shared.eia_microdata_cbecs_2003_expanded
select nextval('diffusion_shared.eia_microdata_cbecs_2003_expanded_bldg_ids') as building_id, 
	sample_wt, 
	'Northeast' as census_region, 
	'NE' as census_division_abbr, 
       reportable_domain, climate_zone, pba, pbaplus, typehuq, roof_material, 
       owner_occupied, kwh, year_built, single_family_res, num_tenants, 
       num_floors, space_heat_equip, space_heat_fuel, space_heat_age_min, 
       space_heat_age_max, water_heat_equip, water_heat_fuel, water_heat_age_min, 
       water_heat_age_max, space_cool_equip, space_cool_fuel, space_cool_age_min, 
       space_cool_age_max, ducts, totsqft, totsqft_heat, totsqft_cool, 
       kbtu_space_heat, kbtu_space_cool, kbtu_water_heat, crb_model, 
       roof_style, roof_sqft
from diffusion_shared.eia_microdata_cbecs_2003_expanded
where census_division_abbr = 'ENC'
and pbaplus = 20;
-- 6 rows added

-- WNC,8 -- replace with data from ENC
INSERT INTO diffusion_shared.eia_microdata_cbecs_2003_expanded
select nextval('diffusion_shared.eia_microdata_cbecs_2003_expanded_bldg_ids') as building_id, 
	sample_wt, 
	'Midwest' as census_region, 
	'WNC' as census_division_abbr, 
       reportable_domain, climate_zone, pba, pbaplus, typehuq, roof_material, 
       owner_occupied, kwh, year_built, single_family_res, num_tenants, 
       num_floors, space_heat_equip, space_heat_fuel, space_heat_age_min, 
       space_heat_age_max, water_heat_equip, water_heat_fuel, water_heat_age_min, 
       water_heat_age_max, space_cool_equip, space_cool_fuel, space_cool_age_min, 
       space_cool_age_max, ducts, totsqft, totsqft_heat, totsqft_cool, 
       kbtu_space_heat, kbtu_space_cool, kbtu_water_heat, crb_model, 
       roof_style, roof_sqft
from diffusion_shared.eia_microdata_cbecs_2003_expanded
where census_division_abbr = 'ENC'
and pbaplus = 8;
-- 12 rows added

-- WNC,15 -- replace with data from ENC
INSERT INTO diffusion_shared.eia_microdata_cbecs_2003_expanded
select nextval('diffusion_shared.eia_microdata_cbecs_2003_expanded_bldg_ids') as building_id, 
	sample_wt, 
	'Midwest' as census_region, 
	'WNC' as census_division_abbr, 
       reportable_domain, climate_zone, pba, pbaplus, typehuq, roof_material, 
       owner_occupied, kwh, year_built, single_family_res, num_tenants, 
       num_floors, space_heat_equip, space_heat_fuel, space_heat_age_min, 
       space_heat_age_max, water_heat_equip, water_heat_fuel, water_heat_age_min, 
       water_heat_age_max, space_cool_equip, space_cool_fuel, space_cool_age_min, 
       space_cool_age_max, ducts, totsqft, totsqft_heat, totsqft_cool, 
       kbtu_space_heat, kbtu_space_cool, kbtu_water_heat, crb_model, 
       roof_style, roof_sqft
from diffusion_shared.eia_microdata_cbecs_2003_expanded
where census_division_abbr = 'ENC'
and pbaplus = 15;
-- 1 row added

-- ESC,15 -- replace with data from SA (WCS is not available)
INSERT INTO diffusion_shared.eia_microdata_cbecs_2003_expanded
select nextval('diffusion_shared.eia_microdata_cbecs_2003_expanded_bldg_ids') as building_id, 
	sample_wt, 
	'South' as census_region, 
	'ESC' as census_division_abbr, 
       reportable_domain, climate_zone, pba, pbaplus, typehuq, roof_material, 
       owner_occupied, kwh, year_built, single_family_res, num_tenants, 
       num_floors, space_heat_equip, space_heat_fuel, space_heat_age_min, 
       space_heat_age_max, water_heat_equip, water_heat_fuel, water_heat_age_min, 
       water_heat_age_max, space_cool_equip, space_cool_fuel, space_cool_age_min, 
       space_cool_age_max, ducts, totsqft, totsqft_heat, totsqft_cool, 
       kbtu_space_heat, kbtu_space_cool, kbtu_water_heat, crb_model, 
       roof_style, roof_sqft
from diffusion_shared.eia_microdata_cbecs_2003_expanded
where census_division_abbr = 'SA'
and pbaplus = 15;
-- 2 rows added

-- drop the sequence
DROP SEQUENCE IF EXISTS diffusion_shared.eia_microdata_recs_2009_expanded_bldgs_bldg_ids;

-- run the original query again to check for missing vals
-- result: all set this time