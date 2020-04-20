ALTER TABLE diffusion_solar.reeds_solar_resource_by_pca_summary_tidy
ALTER COLUMN pca_reg TYPE varchar(4) using pca_reg::varchar(4);

-- add a prefix of p to each pca_reg
UPDATE diffusion_solar.reeds_solar_resource_by_pca_summary_tidy
SET pca_reg = 'p' || pca_reg;

-- next, alter the time slices to drop any 0s
-- test the regex query
select distinct regexp_replace(reeds_time_slice, 'H0', 'H'), reeds_time_slice
FROM diffusion_solar.reeds_solar_resource_by_pca_summary_tidy
order by 2;

-- apply it
UPDATE diffusion_solar.reeds_solar_resource_by_pca_summary_tidy
set reeds_time_slice = regexp_replace(reeds_time_slice, 'H0', 'H');