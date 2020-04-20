set role 'diffusion-writers';

-- before running this, subset the raw data from nhgis to just the two columns of interest:
-- use: cut -f 1,55 -d ',' nhgis0013_ds172_2010_block.csv > nhgis0013_ds172_2010_block_simplified.csv

DROP TABLE IF EXISTS diffusion_wind_data.census_2010_block_housing_units;
CREATE TABLE  diffusion_wind_data.census_2010_block_housing_units
(
	gisjoin character varying(18),
	housing_units integer
);

set role 'server-superusers';
COPY diffusion_wind_data.census_2010_block_housing_units
FROM '/srv/home/mgleason/data/dg_wind/nhgis0013_ds172_2010_block_simplified.csv'
with csv header;
set role 'diffusion-writers';

-- add primary key
ALTER TABLE diffusion_wind_data.census_2010_block_housing_units
ADD PRIMARY KEY (gisjoin);


