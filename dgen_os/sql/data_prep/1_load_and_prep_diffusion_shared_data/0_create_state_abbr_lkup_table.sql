set role 'diffusion-writers';

DROP TABLE IF EXISTS diffusion_shared.state_abbr_lkup;
CREATE TABLE diffusion_shared.state_abbr_lkup as
select name as state, stusps as state_abbr
from census_2014.tl_2014_us_state
where name not in ('Guam', 'Commonwealth of the Northern Mariana Islands', 'United States Virgin Islands', 'American Samoa')
order by 2;

ALTER TABLE diffusion_shared.state_abbr_lkup
ADD PRIMARY KEY (state_abbr);

CREATE INDEX state_abbr_lkup_state_btree
ON diffusion_shared.state_abbr_lkup
USING BTREE(state)