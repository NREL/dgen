set role 'diffusion-writers';

DROP TABLE IF EXISTS diffusion_geo.hydrothermal_resource_data_dummy;
CREATE TABLE diffusion_geo.hydrothermal_resource_data_dummy
(
	tract_id_alias integer,
	resource_id varchar(5),
	resource_type text,
	system_type text,
	min_depth_m numeric,
	max_depth_m numeric,
	n_wells_in_tract integer,
	extractable_resource_per_well_in_tract_mwh numeric
);

\COPY diffusion_geo.hydrothermal_resource_data_dummy FROM '/Users/mgleason/NREL_Projects/Projects/local_data/dgeo_misc/dummy_resource_data.csv' with csv header;

-- add primary key
ALTER TABLE diffusion_geo.hydrothermal_resource_data_dummy
ADD PRIMARY KEY (tract_id_alias, resource_id);

-- add index on tract_id_alias
CREATE INDEX resource_data_dummy_btree_tract_id_alias
ON diffusion_geo.hydrothermal_resource_data_dummy
USING BTREE(tract_id_alias);

-- look at the data
select *
FROM diffusion_geo.hydrothermal_resource_data_dummy;