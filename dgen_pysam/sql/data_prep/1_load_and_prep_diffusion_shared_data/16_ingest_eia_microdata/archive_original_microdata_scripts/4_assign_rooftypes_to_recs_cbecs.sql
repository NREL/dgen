-- NOTE: These lookup tables are based on SolarDS (CBECS) and my interpretation (RECS)

--- load lookup table for CBECS roof material to roof style
set role 'diffusion-writers';
DROP tABLE IF EXISTS diffusion_solar.roof_material_to_roof_style_cbecs;
CREATE TABLE diffusion_solar.roof_material_to_roof_style_cbecs
(
	rfcns8 integer,
	description text,
	roof_style text
);

set role 'server-superusers';
COPY diffusion_solar.roof_material_to_roof_style_cbecs 
FROM '/home/mgleason/data/dg_solar/cbecs_roof_material_to_roof_style.csv' with csv header;
set role 'diffusion-writers';

-- add indices
CREATE INDEX roof_material_to_roof_style_cbecs_rfcns8_btree
ON diffusion_solar.roof_material_to_roof_style_cbecs 
using btree(rfcns8);

CREATE INDEX roof_material_to_roof_style_cbecs_roof_style_btree
ON diffusion_solar.roof_material_to_roof_style_cbecs 
using btree(roof_style);

--- load lookup table for RECS roof material to roof style
set role 'diffusion-writers';
DROP tABLE IF EXISTS diffusion_solar.roof_material_to_roof_style_recs;
CREATE TABLE diffusion_solar.roof_material_to_roof_style_recs
(
	rooftype integer,
	description text,
	roof_style text
);

set role 'server-superusers';
COPY diffusion_solar.roof_material_to_roof_style_recs 
FROM '/home/mgleason/data/dg_solar/recs_roof_material_to_roof_style.csv' with csv header;
set role 'diffusion-writers';

-- add indices
CREATE INDEX roof_material_to_roof_style_recs_rcfns_btree
ON diffusion_solar.roof_material_to_roof_style_recs 
using btree(rooftype);

CREATE INDEX roof_material_to_roof_style_recs_roof_style_btree
ON diffusion_solar.roof_material_to_roof_style_recs 
using btree(roof_style);

------------------------------------------------------------------------------------------------
--- add roof style to cbecs
ALTER TABLE diffusion_shared.eia_microdata_cbecs_2003
ADD COLUMN roof_style text;

UPDATE diffusion_shared.eia_microdata_cbecs_2003 a
SET roof_style = b.roof_style
from diffusion_data_solar.roof_material_to_roof_style_cbecs b
where a.rfcns8 = b.rfcns8;
-- 4712 rows

-- strip malls are null
select *
FROM diffusion_shared.eia_microdata_cbecs_2003
where roof_style is null;

-- manually set these to flat
UPDATE diffusion_shared.eia_microdata_cbecs_2003
set roof_style = 'flat'
where crb_model = 'strip_mall';
-- 395 rows

select distinct(roof_style)
FROM diffusion_shared.eia_microdata_cbecs_2003;
-- pitched
-- flat

------------------------------------------------------------------------------------------------
--- add roof style to recs
ALTER TABLE diffusion_shared.eia_microdata_recs_2009
ADD COLUMN roof_style text;

UPDATE diffusion_shared.eia_microdata_recs_2009 a
SET roof_style = b.roof_style
from diffusion_solar.roof_material_to_roof_style_recs b
where a.rooftype = b.rooftype;

-- only nulls should be where rooftype = -2 (-->non-single family homes)
select distinct(rooftype)
FROM diffusion_shared.eia_microdata_recs_2009
where roof_style is null;

