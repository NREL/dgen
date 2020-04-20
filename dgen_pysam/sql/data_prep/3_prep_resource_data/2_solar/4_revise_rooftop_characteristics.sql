--- load table with various characteristics and probabilities
set role 'diffusion-writers';
ALTER TABLE diffusion_solar.rooftop_characteristics
RENAME TO rooftop_solards_characteristics;


-- change values tilt of zero to 15 (for consistency with lidar data)
UPDATE  diffusion_solar.rooftop_solards_characteristics
set tilt = 15
where roof_style = 'flat';
-- 3 rows affected

-- add a gcr column (0.7 for flat, 0.98 for tilted -- also for consistency with lidar data)
ALTER TABLE diffusion_solar.rooftop_solards_characteristics
ADD COLUMN gcr numeric;

UPDATE diffusion_solar.rooftop_solards_characteristics
set gcr = case when roof_style = 'flat' then 0.7
          else 0.98
          end;

-- review the changes
select *
FROM diffusion_solar.rooftop_solards_characteristics;