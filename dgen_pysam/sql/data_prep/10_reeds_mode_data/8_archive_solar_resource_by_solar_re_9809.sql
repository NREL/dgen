-- reeds summaries by solar re 9809 are huge, so to avoid having to transfer them to dgen_db
-- move them to diffusion_data_solar

ALTER TABLE  diffusion_solar.reeds_avg_cf_by_orientation_and_time_slice
set schema diffusion_data_solar;