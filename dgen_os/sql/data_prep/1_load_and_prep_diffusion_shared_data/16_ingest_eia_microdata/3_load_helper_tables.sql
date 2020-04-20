-- ingest lookup table to translate recs reportable domain to states
set role 'diffusion-writers';
DrOP TABLE IF EXISTS diffusion_shared_data.eia_reportable_domain_to_state_recs_2009;
CREATE TABLE diffusion_shared_data.eia_reportable_domain_to_state_recs_2009
(
	reportable_domain integer,
	state_name text primary key
);

SET ROLE 'server-superusers';
COPY  diffusion_shared_data.eia_reportable_domain_to_state_recs_2009
FROM '/srv/home/mgleason/data/dg_wind/recs_reportable_dominain_to_state.csv' with csv header;
set role 'diffusion-writers';

-- create index for reportable domai column in this table and the recs table
CREATE INDEX eia_reportable_domain_to_state_recs_2009_reportable_domain_btree 
ON diffusion_shared_data.eia_reportable_domain_to_state_recs_2009
USING btree(reportable_domain);

------------------------------------------------------------------------------------------
-- add lookup table for cbecs pba8
DROP TABLE IF EXISTS diffusion_shared_data.eia_microdata_cbecs_2003_pba_lookup;
CREATE TABLE  diffusion_shared_data.eia_microdata_cbecs_2003_pba_lookup (
	pba8	integer primary key,
	description text
);
SET ROLE 'server-superusers';
COPY diffusion_shared_data.eia_microdata_cbecs_2003_pba_lookup 
FROM '/srv/home/mgleason/data/dg_wind/pba8_lookup.csv' with csv header QUOTE '''';
SET ROLE 'diffusion-writers';
------------------------------------------------------------------------------------------
-- add lookup table for pbaplus8
DROP TABLE IF EXISTS diffusion_shared_data.eia_microdata_cbecs_2003_pbaplus8_lookup;
CREATE TABLE  diffusion_shared_data.eia_microdata_cbecs_2003_pbaplus8_lookup (
	pbaplus8	integer primary key,
	description text
);
SET ROLE 'server-superusers';
COPY diffusion_shared_data.eia_microdata_cbecs_2003_pbaplus8_lookup 
FROM '/srv/home/mgleason/data/dg_wind/pbaplus8_lookup.csv' with csv header QUOTE '''';
SET ROLE 'diffusion-writers';
------------------------------------------------------------------------------------------
-- extract all of the disctinct pba/pbaplus8 building uses
SET ROLE 'server-superusers';
COPY 
(
	with a as
	(
		SELECT pba8, pbaplus8
		from diffusion_shared.eia_microdata_cbecs_2003
		group by pba8, pbaplus8
	)
	SELECT a.pba8, b.description as pba8_desc,
	       a.pbaplus8, c.description as pbaplus8_desc
	FROM a
	left join diffusion_shared_data.eia_microdata_cbecs_2003_pba_lookup b
	ON a.pba8 = b.pba8
	LEFT JOIN diffusion_shared_data.eia_microdata_cbecs_2003_pbaplus8_lookup c
	on a.pbaplus8 = c.pbaplus8
	order by a.pba8, a.pbaplus8
) TO '/srv/home/mgleason/data/dg_wind/cbecs_to_eplus_commercial_building_types.csv' with csv header;
SET ROLE 'diffusion-writers';

-- manually edit this table to identify the DOE Commercial Building Type (there 16)
-- associated with each pba8/pbaplus8 combination
-- use http://www.nrel.gov/docs/fy11osti/46861.pdf as a starting point
-- then reload the resulting lookup table to diffusion_shared.cbecs_pba8_pbaplus8_to_eplus_bldg_types
------------------------------------------------------------------------------------------
SET role 'diffusion-writers';
DROP TABLE IF EXISTS diffusion_shared_data.cbecs_2003_pba_to_eplus_crbs;
CREATE TABLE diffusion_shared_data.cbecs_2003_pba_to_eplus_crbs
(
	pba8 integer,
	pba8_desc text,
	pbaplus8 integer,
	pbaplus8_desc text,
	sqft_min numeric,
	sqft_max numeric,
	crb_model text,
	defined_by text,
	notes text
);

SET ROLE 'server-superusers';
COPY diffusion_shared_data.cbecs_2003_pba_to_eplus_crbs 
FROM '/srv/home/mgleason/data/dg_wind/cbecs_to_eplus_commercial_building_types.csv' 
with csv header;
SET ROLE 'diffusion-writers';

-- create indices on pba8 and pbaplus 8
CREATE INDEX cbecs_2003_pba_to_eplus_crbs_pba8_btree
ON diffusion_shared_data.cbecs_2003_pba_to_eplus_crbs 
using btree(pba8);

CREATE INDEX cbecs_2003_pba_to_eplus_crbs_pbaplus8_btree
ON diffusion_shared_data.cbecs_2003_pba_to_eplus_crbs 
using btree(pbaplus8);
------------------------------------------------------------------------------------------------

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
