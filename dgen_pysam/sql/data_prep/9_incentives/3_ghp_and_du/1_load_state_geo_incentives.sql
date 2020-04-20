set role 'diffusion-writers';

DROP TABLE IF EXISTS diffusion_geo.state_dsire_incentives;
CREATE TABLE diffusion_geo.state_dsire_incentives
(
	incentive_type	text,
	state_abbr	varchar(2),
	sector_abbr	varchar(3),
	tech 		varchar(3),
	fixed_dlrs	numeric,
	fixed_tons	numeric,
	dlrs_per_ton 	numeric,
	cap_dlrs double precision,
	min_size_tons double precision,
	max_size_tons double precision,
	start_date date,
	exp_date date,
	dsire_prog_name text,
	dsire_last_updated date,
	dsire_link text,
	val_pct_cost numeric,
	dlrs_per_kwh numeric,
	cap_pct_cost double precision,
	duration_years double precision
);

\COPY diffusion_geo.state_dsire_incentives FROM '/Volumes/Staff/mgleason/dGeo/Data/Source_Data/DSIRE_Incentives_mmooney/reviewed/separate_csvs/incentives_all.csv' with csv header null 'NA';

-- reproduce all commercial rows for ind as well
insert into diffusion_geo.state_dsire_incentives
select incentive_type, state_abbr, 'ind' as sector_abbr, tech, fixed_dlrs, fixed_tons, 
       dlrs_per_ton, cap_dlrs, min_size_tons, max_size_tons, start_date, 
       exp_date, dsire_prog_name, dsire_last_updated, dsire_link, val_pct_cost, 
       dlrs_per_kwh, cap_pct_cost, duration_years
FROM diffusion_geo.state_dsire_incentives
where sector_abbr = 'com';
--14 rows

-- review results
select *
FROM diffusion_geo.state_dsire_incentives;

