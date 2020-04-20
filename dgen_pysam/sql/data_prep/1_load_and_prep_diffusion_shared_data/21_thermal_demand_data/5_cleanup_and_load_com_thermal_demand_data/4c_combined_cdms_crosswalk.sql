set role 'diffusion-writers';

DROP VIEW IF EXISTS diffusion_shared.cdms_to_eia_lkup;
CREATE VIEW diffusion_shared.cdms_to_eia_lkup AS
SELECT cdms, cdms_description,
	typehuq as eia_type,
	typehuq_description as eia_description,
	min_tenants,
	max_tenants
FROM diffusion_shared.cdms_bldg_types_to_typehuq_lkup
UNION ALL
SELECT cdms, cdms_description,
	pbaplus as eia_type,
	pbaplus_description as eia_description,
	NULL::INTEGER as min_tenants,
	NULL::INTEGER as max_tenants
FROM diffusion_shared.cdms_bldg_types_to_pba_plus_lkup;

