set role 'diffusion-writers';


DROP TABLE IF EXISTS diffusion_template.input_ghp_leasing_availability;
CREATE TABLE diffusion_template.input_ghp_leasing_availability
(
	state_abbr character varying(2) not null,
	year integer not null,
	leasing_allowed boolean not null,
	CONSTRAINT input_ghp_leasing_availability_year_fkey FOREIGN KEY (year)
		REFERENCES diffusion_config.sceninp_year_range (val) MATCH SIMPLE
		ON UPDATE NO ACTION ON DELETE RESTRICT
);
