set role 'diffusion-writers';

CREATE TABLE dg_wind.existing_distributed_wind_capacity_by_state_2012_q4 (
	state text,
	sector text,
	capacity_mw numeric,
	systems_count numeric);

set role 'server-superusers';
COPY dg_wind.existing_distributed_wind_capacity_by_state_2012_q4 
FROM '/srv/home/mgleason/data/dg_wind/cumulative_dg_wind_capacity_by_state_fy12_q4.csv' 
with csv header;
set role 'diffusion-writers';

-- add state abbr
ALTER TABLE dg_wind.existing_distributed_wind_capacity_by_state_2012_q4 
ADD COLUMN state_abbr character varying(5);

-- this will get most
UPDATE dg_wind.existing_distributed_wind_capacity_by_state_2012_q4 a
SET state_abbr = b.state_abbr
FROM esri.dtl_state_20110101 b
where lower(a.state) = lower(b.state_name);

select distinct(state)
FROM dg_wind.existing_distributed_wind_capacity_by_state_2012_q4
where state_abbr is null;

UPDATE dg_wind.existing_distributed_wind_capacity_by_state_2012_q4
set (state,state_abbr) = ('District of Columbia','DC')
where state = 'DC';

UPDATE dg_wind.existing_distributed_wind_capacity_by_state_2012_q4
set (state,state_abbr) = ('Puerto Rico-Virgin Islands','PR-VI')
where state = 'PR-VI';

-- cast to wide format and move to diffusion_wind schema
DROP TABLE IF EXIStS diffusion_wind.starting_capacities_mw_2012_q4_us;
CREATE TABLE diffusion_wind.starting_capacities_mw_2012_q4_us AS
with a as
(
	select state_abbr, capacity_mw as capacity_mw_residential, systems_count as systems_count_residential
	FROM dg_wind.existing_distributed_wind_capacity_by_state_2012_q4
	where sector = 'Residential'
),
b as
(
	select state_abbr, capacity_mw as capacity_mw_commercial, systems_count as systems_count_commercial
	FROM dg_wind.existing_distributed_wind_capacity_by_state_2012_q4
	where sector = 'Commercial'
),
c as
(
	select state_abbr, capacity_mw as capacity_mw_industrial, systems_count as systems_count_industrial
	FROM dg_wind.existing_distributed_wind_capacity_by_state_2012_q4
	where sector = 'Industrial'
)
select a.state_abbr, 
	a.capacity_mw_residential, 
	b.capacity_mw_commercial, 
	c.capacity_mw_industrial, 
	a.systems_count_residential, 
	b.systems_count_commercial, 
	c.systems_count_industrial
from a
left join b
on a.state_abbr = b.state_abbr
LEFT JOIN c
ON a.state_abbr = c.state_abbr;


-- create primary key and foreign key
ALTER TABLE diffusion_wind.starting_capacities_mw_2012_q4_us
  ADD CONSTRAINT starting_capacities_mw_2012_q4_us_pkey PRIMARY KEY(state_abbr);

