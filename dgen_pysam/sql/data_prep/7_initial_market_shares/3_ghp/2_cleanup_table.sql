set role 'diffusion-writers';

-- add state abbr column
ALTER TABLE diffusion_geo.starting_capacities_2012_ghp
ADD COLUMN state_abbr varchar(2);

UPDATE diffusion_geo.starting_capacities_2012_ghp a
set state_abbr = b.state_abbr
from diffusion_shared.state_abbr_lkup b
where a.state = b.state;

-- make it the primary key (+ sector_abbr)
ALTER TABLE diffusion_geo.starting_capacities_2012_ghp
ADD primary key (sector_abbr, state_abbr);

-- look at the results
select *
FROM diffusion_geo.starting_capacities_2012_ghp
order by state_abbr, sector_abbr;

-- drop the state column (no longer needed)
ALTER TABLE diffusion_geo.starting_capacities_2012_ghp
DROP COLUMN state;