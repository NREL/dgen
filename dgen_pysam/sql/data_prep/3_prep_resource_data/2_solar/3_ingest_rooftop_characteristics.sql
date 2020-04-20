--- load table with various characteristics and probabilities
set role 'diffusion-writers';
DROP tABLE IF EXISTS diffusion_solar.rooftop_characteristics;
CREATE TABLE diffusion_solar.rooftop_characteristics
(
	sector_abbr character varying(3),
	tilt integer,
	azimuth character varying(2),
	prob_weight numeric,
	roof_style text,
	roof_planes integer,
	rooftop_portion numeric,
	slope_area_multiplier numeric,
	unshaded_multiplier numeric
);

set role 'server-superusers';
COPY diffusion_solar.rooftop_characteristics 
FROM '/home/mgleason/data/dg_solar/roof_orientations_updated.csv' with csv header;
set role 'diffusion-writers';

-- add indices
CREATE INDEX rooftop_characteristics_sector_abbr_btree
ON diffusion_solar.rooftop_characteristics 
using btree(sector_abbr);

CREATE INDEX rooftop_characteristics_roof_style_btree
ON diffusion_solar.rooftop_characteristics 
using btree(roof_style);

-- add an integer primary key (need these for stable sampling later)
ALTER TABLE diffusion_solar.rooftop_characteristics 
ADD COLUMN uid serial;

ALTER TABLE diffusion_solar.rooftop_characteristics 
add primary key (uid); 