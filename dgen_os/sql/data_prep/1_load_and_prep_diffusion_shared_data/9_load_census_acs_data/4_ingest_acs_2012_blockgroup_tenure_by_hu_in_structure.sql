set role 'diffusion-writers';

-- before running this, subset the raw data from nhgis to the columns of interest:
	-- gisjoin, total occupied housing units, owner-occupied 1 family attached, 
	-- owner-occupied 1 family detached, and owner-occupied mobile homes

DROP TABLE IF EXISTS diffusion_wind_data.acs_2012_blockgroup_tenure_by_units_in_structure;
CREATE TABLE  diffusion_wind_data.acs_2012_blockgroup_tenure_by_units_in_structure
(
	gisjoin character varying(18),
	total_occupied integer,
	own_occ_1str_detached integer,
	own_occ_1str_attached integer,
	own_occ_mobile_homes integer
);

set role 'server-superusers';
COPY diffusion_wind_data.acs_2012_blockgroup_tenure_by_units_in_structure
FROM '/srv/home/mgleason/data/dg_wind/nhgis0018_ds191_20125_2012_blck_grp_simplified.csv'
with csv header;
set role 'diffusion-writers';

-- add primary key
ALTER TABLE diffusion_wind_data.acs_2012_blockgroup_tenure_by_units_in_structure
ADD PRIMARY KEY (gisjoin);

-- calculate combo total of own occ 1 str and mobile homes
ALTER TABLE diffusion_wind_data.acs_2012_blockgroup_tenure_by_units_in_structure
ADD COLUMN total_own_occ_1str_and_mobile integer;

UPDATE diffusion_wind_data.acs_2012_blockgroup_tenure_by_units_in_structure
SET  total_own_occ_1str_and_mobile = own_occ_1str_detached + own_occ_1str_attached + own_occ_mobile_homes;


