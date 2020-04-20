set role 'diffusion-writers';

DROP TABLE IF EXISTs diffusion_template.input_ghp_siting_vertical CASCADE;
CREATE TABLE diffusion_template.input_ghp_siting_vertical
(
	area_per_well_sqft numeric not null,
	max_well_depth_ft numeric not null
);

DROP TABLE IF EXISTs diffusion_template.input_ghp_siting_horizontal CASCADE;
CREATE TABLE diffusion_template.input_ghp_siting_horizontal
(
	area_per_pipe_length_sqft_per_foot numeric not null
);


DROP VIEW IF EXISTS diffusion_template.input_ghp_siting;
CREATE VIEW diffusion_template.input_ghp_siting AS
SELECT a.area_per_well_sqft as area_per_well_sqft_vertical, 
	a.max_well_depth_ft,
	b.area_per_pipe_length_sqft_per_foot as area_per_pipe_length_sqft_per_foot_horizontal
FROM diffusion_template.input_ghp_siting_vertical a
CROSS JOIN diffusion_template.input_ghp_siting_horizontal b;

