set role 'diffusion-writers';

-- archive the old table
-- ALTER TABLE diffusion_wind.state_dsire_incentives
-- RENAME TO state_dsire_incentives_archive_2016_03_25;
-- 
-- ALTER TABLE diffusion_wind.state_dsire_incentives_archive_2016_03_25
-- SET SCHEMA diffusion_data_wind;

DROP TABLE IF EXISTS diffusion_wind.state_dsire_incentives;
CREATE TABLE diffusion_wind.state_dsire_incentives
(
	incentive_type	text,
	state_abbr	varchar(2),
	sector_abbr	varchar(3),
	dlrs_per_kw	numeric,
	fixed_dlrs	numeric,
	fixed_kw	numeric,
	min_size_kw	double precision,
	max_size_kw	double precision,
	cap_dlrs	double precision,
	cap_pct_cost	double precision,
	exp_date	date,
	dsire_program_name	text,
	dsire_last_updated	date,
	dsire_link	text,
	dlrs_per_kwh	numeric,
	duration_years	double precision,
	cap_dlrs_yr	double precision,
	val_pct_cost	numeric,
	fixed_kwh	numeric,
	min_aep_kwh	double precision,
	max_aep_kwh	double precision
);

\COPY diffusion_wind.state_dsire_incentives FROM '/Users/mgleason/NREL_Projects/github/diffusion/sql/data_prep/9_wind_incentives/Data/Output/curated_incentives/incentives_all.csv' with csv header null 'NA';

-- reproduce all commercial rows for ind as well
insert into diffusion_wind.state_dsire_incentives
select incentive_type, state_abbr, 'ind' as sector_abbr, dlrs_per_kw, fixed_dlrs, 
       fixed_kw, min_size_kw, max_size_kw, cap_dlrs, cap_pct_cost, exp_date, 
       dsire_program_name, dsire_last_updated, dsire_link, dlrs_per_kwh, 
       duration_years, cap_dlrs_yr, val_pct_cost, fixed_kwh, min_aep_kwh, 
       max_aep_kwh
FROM diffusion_wind.state_dsire_incentives
where sector_abbr = 'com';
-- 22 rows

-- review results
select *
FROM diffusion_wind.state_dsire_incentives;

-- add tech field
ALTER TABLE diffusion_wind.state_dsire_incentives
ADD COLUMN tech varchar(5) default 'wind';

--------------------------------------------------------------------------------------------------------------------------------
-- create an equivalent, but empty table for solar
DROP TABLE IF EXISTS diffusion_solar.state_dsire_incentives;
CREATE TABLE diffusion_solar.state_dsire_incentives
(
	incentive_type	text,
	state_abbr	varchar(2),
	sector_abbr	varchar(3),
	dlrs_per_kw	numeric,
	fixed_dlrs	numeric,
	fixed_kw	numeric,
	min_size_kw	double precision,
	max_size_kw	double precision,
	cap_dlrs	double precision,
	cap_pct_cost	double precision,
	exp_date	date,
	dsire_program_name	text,
	dsire_last_updated	date,
	dsire_link	text,
	dlrs_per_kwh	numeric,
	duration_years	double precision,
	cap_dlrs_yr	double precision,
	val_pct_cost	numeric,
	fixed_kwh	numeric,
	min_aep_kwh	double precision,
	max_aep_kwh	double precision,
	tech		varchar(5)
);



