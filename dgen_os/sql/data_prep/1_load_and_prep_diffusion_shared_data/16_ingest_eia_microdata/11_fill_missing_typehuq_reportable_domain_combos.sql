set role 'diffusion-writers';

-- check for missing combos 
with a as
(
	select distinct typehuq
	from diffusion_shared.eia_microdata_recs_2009_expanded_bldgs
),
b as
(
	select distinct reportable_domain
	from diffusion_shared.eia_microdata_recs_2009_expanded_bldgs
),
c as
(
	select a.typehuq, b.reportable_domain
	from a
	cross join b
),
d as
(
	select distinct reportable_domain, typehuq
	from diffusion_shared.eia_microdata_recs_2009_expanded_bldgs
)
select c.reportable_domain, c.typehuq
from c
left join d
ON c.typehuq = d.typehuq
and c.reportable_domain = d.reportable_domain
where d.typehuq is null;
-- only one missing reportable_domain/type_huq combo:
-- 6,1 -- Illinois and mobile home

-- solution:
-- replace with data from Indiana/Ohio (rd= 7)and Mobile Home
-- need to use new building ids
select max(building_id)
FROM diffusion_shared.eia_microdata_recs_2009_expanded_bldgs;
-- 12083

DROP SEQUENCE IF EXISTS diffusion_shared.eia_microdata_recs_2009_expanded_bldgs_bldg_ids;
CREATE SEQUENCE diffusion_shared.eia_microdata_recs_2009_expanded_bldgs_bldg_ids
INCREMENT 1
START 12084;

INSERT INTO diffusion_shared.eia_microdata_recs_2009_expanded_bldgs
select nextval('diffusion_shared.eia_microdata_recs_2009_expanded_bldgs_bldg_ids') as building_id, 
	sample_wt, census_region, census_division_abbr, 
       6 as reportable_domain, climate_zone, pba, pbaplus, typehuq, roof_material, 
       owner_occupied, kwh, year_built, single_family_res, num_tenants, 
       num_floors, space_heat_equip, space_heat_fuel, space_heat_age_min, 
       space_heat_age_max, water_heat_equip, water_heat_fuel, water_heat_age_min, 
       water_heat_age_max, space_cool_equip, space_cool_fuel, space_cool_age_min, 
       space_cool_age_max, ducts, totsqft, totsqft_heat, totsqft_cool, 
       kbtu_space_heat, kbtu_space_cool, kbtu_water_heat, crb_model, 
       roof_style, roof_sqft
from diffusion_shared.eia_microdata_recs_2009_expanded_bldgs
where reportable_domain = 7
and typehuq = 1;

-- drop the sequence
DROP SEQUENCE IF EXISTS diffusion_shared.eia_microdata_recs_2009_expanded_bldgs_bldg_ids;

-- run the original query again to check for missing vals
-- result: all set this time


----------------------------------------------------------------------------------------------------
-- also need to check for typehuq x num_tenants categories
-- from diffusion_shared.cdms_to_eia_lkup
select *
FROM diffusion_shared.cdms_to_eia_lkup;
-- 2,Single-Family Detached,1,1
-- 3,Single-Family Attached,1,1
-- 1,Mobile Home,1,1
-- 4,Apartment in Building with 2 - 4 Units,2,3
-- 4,Apartment in Building with 2 - 4 Units,3,4
-- 5,Apartment in Building with 5+ Units,5,9
-- 5,Apartment in Building with 5+ Units,10,19
-- 5,Apartment in Building with 5+ Units,20,49
-- 5,Apartment in Building with 5+ Units,50,10000

-- check each of these occurs in each reportable domain
select distinct reportable_domain
from diffusion_shared.eia_microdata_recs_2009_expanded_bldgs c;
-- should be 27 reportable domains

select distinct reportable_domain
from diffusion_shared.eia_microdata_recs_2009_expanded_bldgs c
WHERE typehuq = 1
and num_tenants between 1 and 1;
-- 27 -- all set

select distinct reportable_domain
from diffusion_shared.eia_microdata_recs_2009_expanded_bldgs c
WHERE typehuq = 2
and num_tenants between 1 and 1;
-- 27 -- all set

select distinct reportable_domain
from diffusion_shared.eia_microdata_recs_2009_expanded_bldgs c
WHERE typehuq = 3
and num_tenants between 1 and 1;
-- 27 -- all set

select distinct reportable_domain
from diffusion_shared.eia_microdata_recs_2009_expanded_bldgs c
WHERE typehuq = 4
and num_tenants between 2 and 3;
-- 27 -- all set

select distinct reportable_domain
from diffusion_shared.eia_microdata_recs_2009_expanded_bldgs c
WHERE typehuq = 4
and num_tenants between 3 and 4;
-- 27 -- all set

select distinct reportable_domain
from diffusion_shared.eia_microdata_recs_2009_expanded_bldgs c
WHERE typehuq = 5
and num_tenants between 5 and 9;
-- 27 -- all set

select distinct reportable_domain
from diffusion_shared.eia_microdata_recs_2009_expanded_bldgs c
WHERE typehuq = 5
and num_tenants between 10 and 19;
-- 27 -- all set

select distinct reportable_domain
from diffusion_shared.eia_microdata_recs_2009_expanded_bldgs c
WHERE typehuq = 5
and num_tenants between 20 and 49;
-- 26 -- need to fix

select distinct reportable_domain
from diffusion_shared.eia_microdata_recs_2009_expanded_bldgs c
WHERE typehuq = 5
and num_tenants between 50 and 10000;
-- 26 need to fix

-- which ones are missing from the last two categories?
with a as
(
	select distinct reportable_domain
	from diffusion_shared.eia_microdata_recs_2009_expanded_bldgs c
),
b as
(
	select distinct reportable_domain
	from diffusion_shared.eia_microdata_recs_2009_expanded_bldgs c
	WHERE typehuq = 5
	and num_tenants between 20 and 49
)
select a.reportable_domain
from a
left join b
on a.reportable_domain = b.reportable_domain
where b.reportable_domain is null;
-- reportable_domain = 25

with a as
(
	select distinct reportable_domain
	from diffusion_shared.eia_microdata_recs_2009_expanded_bldgs c
),
b as
(
	select distinct reportable_domain
	from diffusion_shared.eia_microdata_recs_2009_expanded_bldgs c
	WHERE typehuq = 5
	and num_tenants between 50 and 10000
)
select a.reportable_domain
from a
left join b
on a.reportable_domain = b.reportable_domain
where b.reportable_domain is null;
-- reportable_domain = 25

-- which state(s) is this?
select *
from eia.recs_2009_state_to_reportable_domain_lkup
where reportable_domain = 25;
-- New Mexico
-- Nevada

-- replae with data from Arizona -- rd = 24
select *
from diffusion_shared.eia_microdata_recs_2009_expanded_bldgs
where reportable_domain = 24
and num_tenants >= 20
and typehuq = 5;
-- 13 rows will be duplicated and reassigned to rd 25

select max(building_id)
from diffusion_shared.eia_microdata_recs_2009_expanded_bldgs;
-- 12091

-- create a new sequence for iDS
DROP SEQUENCE IF EXISTS diffusion_shared.eia_microdata_recs_2009_expanded_bldgs_bldg_ids;
CREATE SEQUENCE diffusion_shared.eia_microdata_recs_2009_expanded_bldgs_bldg_ids
INCREMENT 1
START 12092;

INSERT INTO diffusion_shared.eia_microdata_recs_2009_expanded_bldgs
select nextval('diffusion_shared.eia_microdata_recs_2009_expanded_bldgs_bldg_ids') as building_id, 
	sample_wt, census_region, census_division_abbr, 
       25 as reportable_domain, climate_zone, pba, pbaplus, typehuq, roof_material, 
       owner_occupied, kwh, year_built, single_family_res, num_tenants, 
       num_floors, space_heat_equip, space_heat_fuel, space_heat_age_min, 
       space_heat_age_max, water_heat_equip, water_heat_fuel, water_heat_age_min, 
       water_heat_age_max, space_cool_equip, space_cool_fuel, space_cool_age_min, 
       space_cool_age_max, ducts, totsqft, totsqft_heat, totsqft_cool, 
       kbtu_space_heat, kbtu_space_cool, kbtu_water_heat, crb_model, 
       roof_style, roof_sqft
from diffusion_shared.eia_microdata_recs_2009_expanded_bldgs
where reportable_domain = 24
and num_tenants >= 20
and typehuq = 5;
-- 13 rows added

-- double check everything is all set now
select distinct reportable_domain
from diffusion_shared.eia_microdata_recs_2009_expanded_bldgs c
WHERE typehuq = 5
and num_tenants between 20 and 49;
-- 27 -- all set

select distinct reportable_domain
from diffusion_shared.eia_microdata_recs_2009_expanded_bldgs c
WHERE typehuq = 5
and num_tenants between 50 and 10000;
-- 27 -- all set