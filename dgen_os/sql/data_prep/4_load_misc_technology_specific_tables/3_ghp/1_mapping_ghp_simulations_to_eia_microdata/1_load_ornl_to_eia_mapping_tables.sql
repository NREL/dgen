set role 'diffusion-writers';

DROP TABLE IF EXISTS diffusion_geo.ornl_simulations_lkup;
CREATE TABLE diffusion_geo.ornl_simulations_lkup
(
	baseline_type integer primary key,
	building_type text,
	baseline_cooling text,
	baseline_heating text,
	provided boolean
);

\COPY diffusion_geo.ornl_simulations_lkup FROM '/Users/kmccabe/dGeo/Data/ORNL_GHP_CRB_Simulations/lkup_tables/csvs/crb_descriptions.csv' with csv header;

----------------------------------------------------------------------------

DROP TABLE IF EXISTS diffusion_geo.ornl_building_type_lkup;
CREATE TABLE diffusion_geo.ornl_building_type_lkup
(
	building_type text,
	sector_abbr varchar(3),
	pba integer,
	pba_desc text,
	typehuq integer,
	typehuq_desc text
);

\COPY diffusion_geo.ornl_building_type_lkup FROM '/Users/kmccabe/dGeo/Data/ORNL_GHP_CRB_Simulations/lkup_tables/csvs/building_type_to_pba_lkup.csv' with csv header;

----------------------------------------------------------------------------

DROP TABLE IF EXISTS diffusion_geo.ornl_baseline_heating_lkup;
CREATE TABLE diffusion_geo.ornl_baseline_heating_lkup
(
	sector_abbr varchar(3),
	baseline_heating text,
	analog_type text,
	eia_system_type text,
	eia_fuel_type text
);


\COPY diffusion_geo.ornl_baseline_heating_lkup FROM '/Users/kmccabe/dGeo/Data/ORNL_GHP_CRB_Simulations/lkup_tables/csvs/baseline_heating_system_lkup.csv' with csv header;

----------------------------------------------------------------------------

DROP TABLE IF EXISTS diffusion_geo.ornl_baseline_cooling_lkup;
CREATE TABLE diffusion_geo.ornl_baseline_cooling_lkup
(
	sector_abbr varchar(3),
	baseline_cooling text,
	analog_type text,
	eia_system_type text,
	eia_fuel_type text
);

\COPY diffusion_geo.ornl_baseline_cooling_lkup FROM '/Users/kmccabe/dGeo/Data/ORNL_GHP_CRB_Simulations/lkup_tables/csvs/baseline_cooling_system_lkup.csv' with csv header;

----------------------------------------------------------------------------
