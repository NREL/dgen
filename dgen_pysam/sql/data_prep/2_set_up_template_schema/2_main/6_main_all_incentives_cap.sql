SET ROLE 'diffusion-writers';

DROP TABLE IF EXISTS diffusion_template.input_main_incentives_cap_raw;
CREATE TABLE diffusion_template.input_main_incentives_cap_raw
(
	tech text not null,
	max_incentive_fraction NUMERIC NOT NULL,
	CONSTRAINT dsire_tech FOREIGN KEY (tech)
		REFERENCES diffusion_config.sceninp_technologies (val) MATCH SIMPLE
		ON UPDATE NO ACTION ON DELETE RESTRICT,
	CONSTRAINT max_incentive_fraction_check CHECK (max_incentive_fraction >= 0 and max_incentive_fraction <= 1)
);



DROP VIEW IF EXISTS diffusion_template.input_main_incentives_cap;
CREATE VIEW diffusion_template.input_main_incentives_cap AS
SELECT lower(tech) as tech, max_incentive_fraction
FROM diffusion_template.input_main_incentives_cap_raw;

