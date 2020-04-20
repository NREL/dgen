
------------------------------------------------------------------------------------------------
--- add roof style to cbecs
ALTER TABLE diffusion_shared.eia_microdata_cbecs_2003_expanded
ADD COLUMN roof_style text;

UPDATE diffusion_shared.eia_microdata_cbecs_2003_expanded a
SET roof_style = b.roof_style
from diffusion_data_solar.roof_material_to_roof_style_cbecs b
where a.roof_material = b.rfcns8;
-- 5081 rows

-- check for nulls
select *
FROM diffusion_shared.eia_microdata_cbecs_2003_expanded
where roof_style is null;
-- none, all set

select distinct(roof_style)
FROM diffusion_shared.eia_microdata_cbecs_2003_expanded;

------------------------------------------------------------------------------------------------
--- add roof style to recs
ALTER TABLE diffusion_shared.eia_microdata_recs_2009_expanded_bldgs
ADD COLUMN roof_style text;

UPDATE diffusion_shared.eia_microdata_recs_2009_expanded_bldgs a
SET roof_style = b.roof_style
from diffusion_data_solar.roof_material_to_roof_style_recs b
where a.roof_material = b.rooftype;
-- 12083 rows

-- check for nulls
select *
FROM diffusion_shared.eia_microdata_recs_2009_expanded_bldgs
where roof_style is null;
-- none -- all set
