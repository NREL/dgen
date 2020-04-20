-- change the table owner
set role 'diffusion-writers';

-- create indices
CREATE INDEX hydro_poly_tracts_btree_tract_id_alias
ON diffusion_geo.hydro_poly_tracts
USING BTREE(tract_id_alias);

CREATE INDEX hydro_pt_tracts_btree_tract_id_alias
ON diffusion_geo.hydro_pt_tracts
USING BTREE(tract_id_alias);

CREATE INDEX hydro_poly_tracts_btree_resource_uid
ON diffusion_geo.hydro_poly_tracts
USING BTREE(resource_uid);

CREATE INDEX hydro_pt_tracts_btree_resource_uid
ON diffusion_geo.hydro_pt_tracts
USING BTREE(resource_uid);

-- check for zero or null n wells
select count(*)
FROm diffusion_geo.hydro_poly_tracts
where n_wells_in_tract = 0
or n_wells_in_tract is null;
-- 0 all set

select count(*)
FROm diffusion_geo.hydro_pt_tracts
where n_wells_in_tract = 0
or n_wells_in_tract is null;
-- 0 all set

-- do the same for extractable resource
select count(*)
FROm diffusion_geo.hydro_poly_tracts
where extractable_resource_in_tract_mwh = 0
or extractable_resource_in_tract_mwh is null;
-- 0 all set

select count(*)
FROm diffusion_geo.hydro_pt_tracts
where extractable_resource_in_tract_mwh = 0
or extractable_resource_in_tract_mwh is null;
-- 2 -- delete these

-- fix -- delete these
delete from diffusion_geo.hydro_pt_tracts
where extractable_resource_in_tract_mwh = 0
or extractable_resource_in_tract_mwh is null;
-- 2 rows deleted


-- do the samee for extractable_resource_per_well_in_tract_mwh
select count(*)
FROm diffusion_geo.hydro_poly_tracts
where extractable_resource_per_well_in_tract_mwh = 0
or extractable_resource_per_well_in_tract_mwh is null;
-- 0 all set

select count(*)
FROm diffusion_geo.hydro_pt_tracts
where extractable_resource_per_well_in_tract_mwh = 0
or extractable_resource_per_well_in_tract_mwh is null;
-- 0 all set

-- spot check some values for unit conversions
select *
FROM diffusion_geo.hydro_pt_tracts
where resource_uid = 'OR057'
-- 555555.556 = extract_resource_in_tract_mwh

select *
FROM diffusion_geo.resources_hydrothermal_pt
where uid = 'OR057'
-- 0.002 1e18 joules which = 555555.556 mwh
-- looks good!

-- change sys_type column to system_type
ALTER TABLE diffusion_geo.hydro_pt_tracts
RENAME COLUMN sys_type to system_type;

ALTER TABLE diffusion_geo.hydro_poly_tracts
RENAME COLUMN sys_type to system_type;
