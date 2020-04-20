set role 'diffusion-writers';

-- make state_abbr + sector_abbr the primary key
ALTER TABLE diffusion_geo.starting_capacities_2004_du
ADD primary key (sector_abbr, state_abbr);

-- look at the results
select *
FROM diffusion_geo.starting_capacities_2004_du
order by state_abbr, sector_abbr;

