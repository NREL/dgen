set role 'diffusion-writers';

-- combine the hydrothermal datasets, filtering to the tracts to model
DROP VIEW IF EXISTS diffusion_template.du_resources_hydrothermal;
CREATE VIEW diffusion_template.du_resources_hydrothermal as
SELECT  a.tract_id_alias,
	a.resource_uid,
	a.resource_type,
	a.system_type,
	a.min_depth_m,
	a.max_depth_m,
	a.n_wells_in_tract,
	a.extractable_resource_per_well_in_tract_mwh
FROM diffusion_geo.hydro_poly_tracts a
INNER JOIN diffusion_template.tracts_to_model b
	ON a.tract_id_alias = b.tract_id_alias
UNION ALL
SELECT a.tract_id_alias,
	a.resource_uid,
	a.resource_type,
	a.system_type,
	a.min_depth_m,
	a.max_depth_m,
	a.n_wells_in_tract,
	a.extractable_resource_per_well_in_tract_mwh
FROM diffusion_geo.hydro_pt_tracts a
INNER JOIN diffusion_template.tracts_to_model b
	ON a.tract_id_alias = b.tract_id_alias;

