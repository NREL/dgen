SET ROLE 'diffusion-writers';

DROP VIEW IF EXISTS diffusion_shared.cbecs_recs_expanded_combined;
CREATE OR REPLACE VIEW diffusion_shared.cbecs_recs_expanded_combined AS
SELECT *, pba as pba_or_typehuq,
	'diffusion_shared.eia_microdata_cbecs_2003_expanded' as source_table,
	unnest(ARRAY['com', 'ind']) as sector_abbr
FROM diffusion_shared.eia_microdata_cbecs_2003_expanded as c

UNION ALL

SELECT *, typehuq as pba_or_typehuq,
	'diffusion_shared.eia_microdata_recs_2009_expanded_bldgs' as source_table,
	'res' as sector_abbr
FROM diffusion_shared.eia_microdata_recs_2009_expanded_bldgs;
