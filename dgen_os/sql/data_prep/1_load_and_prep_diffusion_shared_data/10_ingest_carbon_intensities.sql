DROP TABLE IF EXISTS diffusion_shared.carbon_intensities CASCADE;
CREATE TABLE diffusion_shared.carbon_intensities (
	state_abbr character varying(2),
	no_carbon_price_t_per_kwh numeric,
	state_carbon_price_t_per_kwh numeric,
	ng_offset_t_per_kwh numeric
);

SET ROLE 'server-superusers';
COPY diffusion_shared.carbon_intensities FROM '/home/mgleason/data/dg_wind/CarbonIntensities.csv' with csv header;
RESET ROLE;

CREATE INDEX carbon_intensities_state_abbr_btree ON diffusion_shared.carbon_intensities USING btree(state_abbr);


