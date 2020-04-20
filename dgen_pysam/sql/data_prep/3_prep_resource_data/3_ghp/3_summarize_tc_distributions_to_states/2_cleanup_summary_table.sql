set role 'diffusion-writers';

COMMENT ON TABLE diffusion_geo.thermal_conductivity_summary_by_state IS 'units are BTU/hr-ft-F';

-- add primary key
alter table diffusion_geo.thermal_conductivity_summary_by_state
ADD PRIMARY KEY (state_abbr);

------------------------------------------------------------------------------------------
-- in fill for CT using neighboring states
-- which ones?
select *
from diffusion_geo.thermal_conductivity_summary_by_state
where state_abbr in ('NY', 'MA');
-- they are pretty similar, and NY has much more data, so fill with NY

INSERT INTO diffusion_geo.thermal_conductivity_summary_by_state
SELECT 'CT' as state_abbr, lmin, lmax, min, max, mean, median, 0, lmid, lsd2, lsd, q25, q50, q75
FROM diffusion_geo.thermal_conductivity_summary_by_state
where state_abbr = 'NY';
------------------------------------------------------------------------------------------

-- fix the states that onky had one sample
select *
from diffusion_geo.thermal_conductivity_summary_by_state
where mean = max
and max = min;
-- HI, RI, and WI

-- for WI, use MN or MI or IL?
select *
from diffusion_geo.thermal_conductivity_summary_by_state
where state_abbr in ('WI', 'MN', 'IL', 'MI');
-- they are actually all pretty similar, and the one point from WI looks way off
-- MI is in the middle of hte other two, so use it instead

DELETE FROM diffusion_geo.thermal_conductivity_summary_by_state
where state_abbr = 'WI';

INSERT INTO diffusion_geo.thermal_conductivity_summary_by_state
SELECT 'WI' as state_abbr, lmin, lmax, min, max, mean, median, 0, lmid, lsd2, lsd, q25, q50, q75
FROM diffusion_geo.thermal_conductivity_summary_by_state
where state_abbr = 'MI';

-- for RI, use MA?
select *
from diffusion_geo.thermal_conductivity_summary_by_state
where state_abbr in ('MA', 'NY', 'VT', 'RI');

DELETE FROM diffusion_geo.thermal_conductivity_summary_by_state
where state_abbr = 'RI';

INSERT INTO diffusion_geo.thermal_conductivity_summary_by_state
SELECT 'RI' as state_abbr, lmin, lmax, min, max, mean, median, 0, lmid, lsd2, lsd, q25, q50, q75
FROM diffusion_geo.thermal_conductivity_summary_by_state
where state_abbr = 'MA';

-- for HI??? -- other volcanic states are WA and AK...
select *
from diffusion_geo.thermal_conductivity_summary_by_state
where state_abbr  in ('AK', 'HI', 'WA');
--- use AK, it s eems more reasonable

DELETE FROM diffusion_geo.thermal_conductivity_summary_by_state
where state_abbr = 'HI';

INSERT INTO diffusion_geo.thermal_conductivity_summary_by_state
SELECT 'HI' as state_abbr, lmin, lmax, min, max, mean, median, 0, lmid, lsd2, lsd, q25, q50, q75
FROM diffusion_geo.thermal_conductivity_summary_by_state
where state_abbr = 'AK';

-- make sure 51 states represented
select *
FROM diffusion_shared.state_abbr_lkup a
lEFT JOIN diffusion_geo.thermal_conductivity_summary_by_state b
ON a.state_abbr = b.state_abbr
where b.state_abbr is null;
-- yup, only thing missing is PR