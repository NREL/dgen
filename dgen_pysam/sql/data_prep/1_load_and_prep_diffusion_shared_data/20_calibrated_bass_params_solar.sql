set role 'diffusion-writers';

-- NOTE: These are not actually used in the model -- they are really just loaded into the database
-- to have a primary record separate from the defaults in the Excel input sheet 

DROP TABLE IF EXISTS diffusion_solar.bass_pq_calibrated_params_solar;
CREATE TABLE diffusion_solar.bass_pq_calibrated_params_solar
(
  state_abbr character varying(2),
  p numeric,
  q numeric,
  sector_abbr text
);


\COPY diffusion_solar.bass_pq_calibrated_params_solar FROM '/Volumes/Staff/mgleason/DG_Solar/Data/Source_Data/bass_parameters/bass_pq_calibrated_params_solar.csv' with csv header;

select *
FROM diffusion_solar.bass_pq_calibrated_params_solar;

CREATE INDEX bass_pq_calibrated_params_solar_sector_abbr_btree
ON diffusion_solar.bass_pq_calibrated_params_solar
USING BTREE(sector_abbr);

CREATE INDEX bass_pq_calibrated_params_solar_state_abbr_btree
ON diffusion_solar.bass_pq_calibrated_params_solar
USING BTREE(state_abbr);

--- update parameters for Maine based on manually calibrated values
-- from  FY16Q1 Maine TA work
select *
FROM diffusion_solar.bass_pq_calibrated_params_solar
where state_abbr = 'ME';

UPDATE diffusion_solar.bass_pq_calibrated_params_solar
SET (p, q) = (0.00059, 0.525)
where state_abbr = 'ME'
and sector_abbr = 'res';

UPDATE diffusion_solar.bass_pq_calibrated_params_solar
SET (p, q) = (0.00208, 0.325)
where state_abbr = 'ME'
and sector_abbr = 'com';

UPDATE diffusion_solar.bass_pq_calibrated_params_solar
SET (p, q) = (0.00208, 0.325)
where state_abbr = 'ME'
and sector_abbr = 'ind';
