set role 'diffusion-writers';


delete from diffusion_solar.incentives a
USING geo_incentives.incentives b
where a.incentive_id = b.gid
and b.sector <> 'S';
-- 865 incentives removed

-- add state abbr
alter table diffusion_solar.incentives
ADD state_abbr varchar(2);

update diffusion_solar.incentives a
set state_abbr = b.state_abbrev
from  geo_incentives.incentives b
where a.incentive_id = b.gid;

-- check values
select distinct state_abbr
from diffusion_solar.incentives

-- make sure no nulls
select count(*)
from diffusion_solar.incentives
where state_abbr is null;