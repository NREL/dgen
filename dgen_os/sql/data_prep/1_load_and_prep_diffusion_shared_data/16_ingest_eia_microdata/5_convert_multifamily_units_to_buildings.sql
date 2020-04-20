set role 'diffusion-writers';
-- split out RECS single family and multifamily housing units, 
-- and then convert multifamily housing units to multifamily buildings 
-- by multiplying relevant variables by the num_tenants in the building

-- first: make sure no records are identified as single_family_res = T but num_tenants <> 1
select count(*)
FROM diffusion_shared.eia_microdata_recs_2009_expanded
where single_family_res = True and num_tenants <> 1;

select distinct num_tenants
from diffusion_shared.eia_microdata_recs_2009_expanded
where single_family_res = true;
-- all set

-- extract single family buildings
drop table if exists diffusion_shared.eia_microdata_recs_2009_expanded_singlefamily_bldgs;
CREATE TABLE diffusion_shared.eia_microdata_recs_2009_expanded_singlefamily_bldgs AS
SEleCT *
FROM diffusion_shared.eia_microdata_recs_2009_expanded
where single_family_res = True;
-- 9243 rows

-- extract housing units from multifamily buildings and convert into buildings 
DROP TABLE IF EXISTS diffusion_shared.eia_microdata_recs_2009_expanded_multifamily_bldgs;
CREATE TABLE diffusion_shared.eia_microdata_recs_2009_expanded_multifamily_bldgs AS
select building_id, 
	sample_wt / num_tenants::NUMERIC as sample_wt, 
	census_region, census_division_abbr, reportable_domain, climate_zone, pba, pbaplus, typehuq, roof_material, 
	False as owner_occupied, 
	kwh * num_tenants as kwh, 
	year_built, single_family_res, 
	num_tenants, 
	num_floors, 
	space_heat_equip, space_heat_fuel, space_heat_age_min, 
	space_heat_age_max, water_heat_equip, water_heat_fuel, water_heat_age_min, 
	water_heat_age_max, space_cool_equip, space_cool_fuel, space_cool_age_min, 
	space_cool_age_max, ducts, 
	totsqft * num_tenants as totsqft, 
	totsqft_heat * num_tenants as totsqft_heat, 
	totsqft_cool * num_tenants as totsqft_cool, 
	kbtu_space_heat * num_tenants as kbtu_space_heat, 
	kbtu_space_cool * num_tenants as kbtu_space_cool, 
	kbtu_water_heat * num_tenants as kbtu_water_heat
FROM diffusion_shared.eia_microdata_recs_2009_expanded
where single_family_res = False;
-- 2849 rows

-- recombine into a single table
DROP TABLE IF EXISTS diffusion_shared.eia_microdata_recs_2009_expanded_bldgs;
CREATE TABLE diffusion_shared.eia_microdata_recs_2009_expanded_bldgs AS
select *
FROM diffusion_shared.eia_microdata_recs_2009_expanded_multifamily_bldgs
UNION ALL
select *
FROM diffusion_shared.eia_microdata_recs_2009_expanded_singlefamily_bldgs;
-- 12083 rows

-- matches count of source table?
select count(*)
FROM diffusion_shared.eia_microdata_recs_2009_expanded;
-- 12083
-- yes!

-- drop the units table, keeping only the buildings table
DROP TABLE IF EXISTS diffusion_shared.eia_microdata_recs_2009_expanded;
-- drop intermediate tables
drop table if exists diffusion_shared.eia_microdata_recs_2009_expanded_singlefamily_bldgs;
DROP TABLE IF EXISTS diffusion_shared.eia_microdata_recs_2009_expanded_multifamily_bldgs;
