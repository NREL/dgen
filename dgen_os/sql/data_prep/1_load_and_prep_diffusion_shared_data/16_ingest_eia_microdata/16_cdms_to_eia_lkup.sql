set role 'diffusion-writers';

DROP VIEW IF EXISTS diffusion_shared.cdms_to_eia_lkup;

CREATE OR REPLACE VIEW diffusion_shared.cdms_to_eia_lkup AS 
         SELECT cdms, 
            cdms_description, 
            typehuq AS eia_type, 
            typehuq_description AS eia_description, 
            min_tenants, 
            max_tenants,
            CASE WHEN min_tenants = 1 and max_tenants = 1 then true
            else False
            end as single_family_res
           FROM diffusion_shared.cdms_bldg_types_to_typehuq_lkup
UNION ALL 
         SELECT cdms, 
            cdms_description, 
            pbaplus AS eia_type, 
            pbaplus_description AS eia_description, 
            NULL::integer AS min_tenants, 
            NULL::integer AS max_tenants,
            NULL::BOOLEAN as single_family_res
           FROM diffusion_shared.cdms_bldg_types_to_pba_plus_lkup;