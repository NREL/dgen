SET ROLE 'diffusion-writers';

DROP TABLE IF EXISTS diffusion_template.input_main_dsire_incentive_options_raw CASCADE;
CREATE TABLE diffusion_template.input_main_dsire_incentive_options_raw
(
  tech text not null,
  dsire_default_exp_date date not null,
    CONSTRAINT dsire_tech FOREIGN KEY (tech)
	REFERENCES diffusion_config.sceninp_technologies (val) MATCH SIMPLE
	ON UPDATE NO ACTION ON DELETE RESTRICT,
  CONSTRAINT dsire_default_exp_date_check CHECK (dsire_default_exp_date >= '1/1/2012'::DATE)
);


drop view IF EXISTS diffusion_template.input_main_dsire_incentive_options;
CREATE VIEW diffusion_template.input_main_dsire_incentive_options AS
SELECT lower(tech) as tech, 
	dsire_default_exp_date, 
	EXTRACT(YEAR FROM dsire_default_exp_date)::INTEGER as dsire_default_exp_year
FROM diffusion_template.input_main_dsire_incentive_options_raw;


