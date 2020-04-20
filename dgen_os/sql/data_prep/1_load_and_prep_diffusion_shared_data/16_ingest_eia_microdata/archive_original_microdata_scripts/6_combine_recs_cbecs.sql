SET ROLE 'diffusion-writers';

DROP VIEW IF EXISTS diffusion_shared.cbecs_recs_combined;
CREATE OR REPLACE VIEW diffusion_shared.cbecs_recs_combined AS
SELECT 
	c.pubid8 as bldg_id,
	c.adjwt8 as weight,
	c.elcns8 as ann_cons_kwh,
	c.crb_model as crb_model,
	c.roof_style as roof_style,
	c.roof_sqft as roof_sqft,
	c.ownocc8 as ownocc8,
	c.nocc8 as nocc8,
	'diffusion_shared.eia_microdata_cbecs_2003' as source_table,
	unnest(ARRAY['com', 'ind']) as sector_abbr,
	c.census_division_abbr as census_division_abbr,
	c.census_region as census_region,
	NULL as reportable_domain,
	c.climate8 as climate_zone
FROM diffusion_shared.eia_microdata_cbecs_2003 as c
WHERE c.pba8 <> 1

UNION ALL

SELECT 
	r.doeid as bldg_id,
	r.nweight as weight,
	r.kwh as ann_cons_kwh,
	r.crb_model as crb_model,
	r.roof_style as roof_style,
	r.roof_sqft as roof_sqft,
	1 as ownocc8,
	1 as nocc8,
	'diffusion_shared.eia_microdata_recs_2009' as source_table,
	'res' as sector_abbr,
	r.census_division_abbr as census_division_abbr,
	r.census_region as census_region,
	r.reportable_domain as reportable_domain,
	r.climate_region_pub as climate_zone
FROM diffusion_shared.eia_microdata_recs_2009 as r
WHERE r.typehuq in (1,2,3) AND r.kownrent = 1;

COMMENT ON VIEW diffusion_shared.cbecs_recs_combined IS '''
Combined data from eia_microdata_cbecs_2003 and eia_microdata_recs_2009 with standardized field names. 
See column-level comments for relationship to original field names
''';

COMMENT ON COLUMN diffusion_shared.cbecs_recs_combined.bldg_id IS 'recs.doeid or cbecs.pubid8';
COMMENT ON COLUMN diffusion_shared.cbecs_recs_combined.weight IS 'recs.nweight or cbecs.adjwt8';
COMMENT ON COLUMN diffusion_shared.cbecs_recs_combined.ann_cons_kwh IS 'recs.kwh or cbecs.elcns8';
COMMENT ON COLUMN diffusion_shared.cbecs_recs_combined.crb_model IS 'recs.crb_model or cbecs.crb_model';
COMMENT ON COLUMN diffusion_shared.cbecs_recs_combined.roof_style IS 'recs.roof_style or cbecs.roof_style';
COMMENT ON COLUMN diffusion_shared.cbecs_recs_combined.roof_sqft IS 'recs.roof_sqft or cbecs.roof_sqft';
COMMENT ON COLUMN diffusion_shared.cbecs_recs_combined.ownocc8 IS 'cbecs.ownocc8 or 1 for recs';
COMMENT ON COLUMN diffusion_shared.cbecs_recs_combined.nocc8 IS 'cbecs.nocc8 or 1 for recs';
COMMENT ON COLUMN diffusion_shared.cbecs_recs_combined.source_table IS 'recs or cbecs source table';
COMMENT ON COLUMN diffusion_shared.cbecs_recs_combined.climate_zone IS 'recs.climate_region_pub or cbecs.climate8';
COMMENT ON COLUMN diffusion_shared.cbecs_recs_combined.sector_abbr IS 'Corresponds to sector_abbr in Python scripts';

