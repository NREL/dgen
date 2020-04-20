set role 'diffusion-writers';


DROP TABLE IF EXISTs diffusion_template.input_solar_rooftop_source_raw CASCADE;
CREATE TABLE diffusion_template.input_solar_rooftop_source_raw
(
	rooftop_source text,
	CONSTRAINT input_solar_rooftop_data_source_fkey FOREIGN KEY (rooftop_source)
	REFERENCES diffusion_config.sceninp_rooftop_data_source (val) MATCH SIMPLE
	ON DELETE RESTRICT
);


DROP VIEW IF EXISTS diffusion_template.input_solar_rooftop_source;
CREATE VIEW diffusion_template.input_solar_rooftop_source AS
SELEct case when rooftop_source = 'EIA Building Microdata' THEN 'recs_cbecs'
	    WHEN rooftop_source = 'LIDAR (Optimal Plane Only)' THEN 'optimal_only'
	    WHEN rooftop_source = 'LIDAR (Optimal Plane Blended)' THEN 'optimal_blended'
	end as rooftop_source
from diffusion_template.input_solar_rooftop_source_raw;