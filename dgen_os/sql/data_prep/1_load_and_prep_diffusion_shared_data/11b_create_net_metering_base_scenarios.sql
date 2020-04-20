SET ROLE 'diffusion-writers';
-- full everywhere
DROP tABlE IF EXISTS diffusion_shared.nem_scenario_full_everywhere;
CREATE TABLE diffusion_shared.nem_scenario_full_everywhere AS
-- get states from state_fips_lkup table
SELECT generate_series(2014,2050,2) as year,
	state_abbr, 
	unnest(array['res','com','ind']) as sector_abbr,
       'Inf'::double precision as system_size_limit_kw,
       0::numeric as year_end_excess_sell_rate_dlrs_per_kwh,
       0::numeric hourly_excess_sell_rate_dlrs_per_kwh

FROM diffusion_shared.state_fips_lkup
where state_abbr <> 'PR';

-- none everywhere
DROP tABlE IF EXISTS diffusion_shared.nem_scenario_none_everywhere;
CREATE TABLE diffusion_shared.nem_scenario_none_everywhere AS
-- get states from state_fips_lkup table
SELECT generate_series(2014,2050,2) as year,
	state_abbr, 
	unnest(array['res','com','ind']) as sector_abbr,
       0::double precision as system_size_limit_kw,
       0::numeric as year_end_excess_sell_rate_dlrs_per_kwh,
       0::numeric hourly_excess_sell_rate_dlrs_per_kwh
FROM diffusion_shared.state_fips_lkup
where state_abbr <> 'PR';

-- BAU
-- old version
-- DROP tABlE IF EXISTS diffusion_shared.nem_scenario_bau_old;
-- CREATE TABLE diffusion_shared.nem_scenario_bau_old AS
-- -- get states from state_fips_lkup table
-- SELECT generate_series(2014,2050,2) as year,
-- 	state_abbr, 
--        sector as sector_abbr,
--        utility_type,
--        nem_system_limit_kw as system_size_limit_kw,
--        0::numeric as year_end_excess_sell_rate_dlrs_per_kwh,
--        0::numeric hourly_excess_sell_rate_dlrs_per_kwh
-- FROM diffusion_shared.net_metering_availability_2013;

--- new version
DROP TABLE IF EXISTS diffusion_shared.net_metering_availability_2015;
CREATE TABLE diffusion_shared.net_metering_availability_2015
(
	state_abbr character varying(2),
	exp_year integer,
	sector_abbr character varying(3),
	nem_system_limit_kw DOUBLE PRECISION
);
-- add primary key on state, sector
ALTER TABLE  diffusion_shared.net_metering_availability_2015
ADD PRIMARY KEY (state_abbr, sector_abbr);

\COPY diffusion_shared.net_metering_availability_2015 FROM '/Volumes/Staff/mgleason/DG_Solar/Data/Source_Data/nem_update_20151014/nem_bau_update_20151014_reformat.csv' with csv header;

-- update the expiration years based off of even more recent updates from ben
DROP TABLE IF EXISTS diffusion_shared.nem_expirations;
CREATE TABLE diffusion_shared.nem_expirations
(
	state_abbr varchar(2) primary key,
	year integer
);


\COPY diffusion_shared.nem_expirations FROM '/Volumes/Staff/mgleason/DG_Solar/Data/Source_Data/nem_update_20151120/nem_expiration_update_2015_11_20.txt' with csv header;

select *
FROM diffusion_shared.nem_expirations a;

select distinct state_abbr, exp_year
FROM diffusion_shared.net_metering_availability_2015
;

-- apply these to diffusion_shared.nem_scenario_bau
UPDATE diffusion_shared.net_metering_availability_2015 a
SET exp_year = b.year
FROM diffusion_shared.nem_expirations b
where a.state_abbr = b.state_abbr;
-- drop the table with the exp years
DROP TABLE IF EXISTS diffusion_shared_nem_expirations;


set role 'diffusion-writers';

-- create the scenarion bau table
DROP tABlE IF EXISTS diffusion_shared.nem_scenario_bau CASCADE;
CREATE TABLE diffusion_shared.nem_scenario_bau AS
with a as
(
	SELECT generate_series(2014, exp_year, 2) as year,
		state_abbr, 
	       sector_abbr,
	       nem_system_limit_kw as system_size_limit_kw,
	       0::numeric as year_end_excess_sell_rate_dlrs_per_kwh,
	       0::numeric hourly_excess_sell_rate_dlrs_per_kwh
	FROM diffusion_shared.net_metering_availability_2015
)
select year, state_abbr, sector_abbr,
	       system_size_limit_kw, year_end_excess_sell_rate_dlrs_per_kwh,
	       hourly_excess_sell_rate_dlrs_per_kwh
from a;
-- add primary key on year, state_abbr, sector_abbr
ALTER TABLE diffusion_shared.nem_scenario_bau 
ADD PRIMARY KEY (year, state_abbr, sector_abbr);

select count(*)
FROM diffusion_shared.nem_scenario_bau;
-- 1635

