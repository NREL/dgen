SET ROLE 'diffusion-writers';

DROP TABLE IF EXISTS diffusion_template.input_ghp_bass_res CASCADE;
CREATE TABLE diffusion_template.input_ghp_bass_res
(
	state_abbr character varying(2) NOT NULL,
	p numeric NOT NULL,
	q numeric NOT NULL,
	teq_yr1 numeric NOT NULL
);

DROP TABLE IF EXISTS diffusion_template.input_ghp_bass_com;
CREATE TABLE diffusion_template.input_ghp_bass_com
(
	state_abbr character varying(2) NOT NULL,
	p numeric NOT NULL,
	q numeric NOT NULL,
	teq_yr1 numeric NOT NULL
);


DROP VIEW IF EXISTS diffusion_template.input_ghp_bass_params;
CREATE VIEW diffusion_template.input_ghp_bass_params AS
SELECT state_abbr, p, q, teq_yr1, 'res'::varchar(3) as sector_abbr, 'ghp'::text as tech
FROM diffusion_template.input_ghp_bass_res
UNION ALL
SELECT state_abbr, p, q, teq_yr1, 'com'::varchar(3) as sector_abbr, 'ghp'::text as tech
FROM diffusion_template.input_ghp_bass_com;