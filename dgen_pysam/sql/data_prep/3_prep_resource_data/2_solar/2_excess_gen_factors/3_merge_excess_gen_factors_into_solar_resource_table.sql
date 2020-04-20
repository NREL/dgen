-- add the column
ALTER TABLE diffusion_solar.solar_resource_annual
ADD COLUMN excess_gen_factor numeric;

-- update the column
UPDATE diffusion_solar.solar_resource_annual a
SET excess_gen_factor = b.excess_gen_factor
FROM diffusion_solar_data.excess_generation_factors b
where a.solar_re_9809_gid = b.solar_re_9809_gid
and a.tilt = b.tilt
and a.azimuth = b.azimuth;

-- check for nulls
SELECT excess_gen_factor
FROM diffusion_solar.solar_resource_annual
where excess_gen_factor is null;

-- check for min, max, and avg
SELECT min(excess_gen_factor), max(excess_gen_factor), avg(excess_gen_factor)
FROM diffusion_solar.solar_resource_annual

-- seearch for negative values:
select *
FROM diffusion_solar.solar_resource_annual
where excess_gen_factor < 0;

-- where negative, replace with nulls
UPDATE diffusion_solar.solar_resource_annual
set excess_gen_factor = null
where excess_gen_factor < 0;

-- this only happens currently for gid = 3101, due to a bad tm2 file
-- to fix, simply replce with the corresponding values from one of its neighbors
-- in this case, the cell to the south (3451) appears to be the best optoin
with replacements as 
(
	SELECT *
	FROM diffusion_solar.solar_resource_annual
	where solar_re_9809_gid = 3451
)
UPDATE diffusion_solar.solar_resource_annual a
set excess_gen_factor = b.excess_gen_factor
FROM replacements b
where a.solar_re_9809_gid = 3101
and a.tilt = b.tilt
and a.azimuth = b.azimuth;

select *
from diffusion_solar.solar_resource_annual
where solar_re_9809_gid in (3101,3451)
order by tilt, azimuth;

-- check stats again
SELECT min(excess_gen_factor), max(excess_gen_factor), avg(excess_gen_factor)
FROM diffusion_solar.solar_resource_annual
