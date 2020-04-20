set role 'diffusion-writers';

------------------------------------------------------------------------------------------------
-- create the table
DROP TABLE IF EXISTS diffusion_blocks.block_primary_electric_utilities;
CREATE TABLE diffusion_blocks.block_primary_electric_utilities AS
select a.pgid, 
	b.utility_num_res, 
	b.utility_type_res,
	b.utility_num_com, 
	b.utility_type_com,
	b.utility_num_ind, 
	b.utility_type_ind,
	b.utility_num_tot, 
	b.utility_type_tot
from diffusion_blocks.block_geoms a
LEFT JOIN diffusion_blocks.county_primary_electric_utilities b
on a.state_fips = b.state_fips
and a.county_fips = b.county_fips;
-- 10535171 rows
-------------------------------------------------------------------------------------------------
-- QA/QC

-- add primary key
ALTER TABLE diffusion_blocks.block_primary_electric_utilities
ADD PRIMARY KEY (pgid);

-- check count
select count(*)
FROM diffusion_blocks.block_geoms;
-- 10535171 -- all set

-- how many nulls?
select count(*)
FROM diffusion_blocks.block_primary_electric_utilities
where utility_num_res is null
or utility_num_com is null
or utility_num_ind is null
or utility_num_tot is null;
-- 21541!!!


-- -- where are they?
select distinct b.state_abbr, b.county_fips
FROM diffusion_blocks.block_primary_electric_utilities a
left join diffusion_blocks.block_geoms b
ON a.pgid = b.pgid
where a.utility_num_res is null
or a.utility_num_com is null
or a.utility_num_ind is null
or a.utility_num_tot is null
order by state_abbr, county_fips;
-- 11 rows
-- TX, NV, AND AK

-- most likely, these counties had no sales in eia 2013 data
with a as
(
	select distinct b.state_abbr, b.state_fips, b.county_fips
	FROM diffusion_blocks.block_primary_electric_utilities a
	left join diffusion_blocks.block_geoms b
	ON a.pgid = b.pgid
	where a.utility_num_res is null
	or a.utility_num_com is null
	or a.utility_num_ind is null
	or a.utility_num_tot is null
	order by state_abbr, county_fips
)
select a.*, c.ownership, b.*
from a
left join eia.eia_861_2013_county_utility_rates b
ON a.state_fips = b.statefp
and a.county_fips = b.countyfp
LEFT JOIN eia.eia_861_electricity_sales_all_sectors_2013 c
ON b.utility_num = c.utility_num;
-- confirmed this is the case
-- and since no sales, we don't know the utility type

-- however, we can guess it based on utility names
with a as
(
	select distinct b.state_abbr, b.state_fips, b.county_fips
	FROM diffusion_blocks.block_primary_electric_utilities a
	left join diffusion_blocks.block_geoms b
	ON a.pgid = b.pgid
	where a.utility_num_res is null
	or a.utility_num_com is null
	or a.utility_num_ind is null
	or a.utility_num_tot is null
	order by state_abbr, county_fips
),
b AS
(
	select a.state_fips, a.county_fips, b.utility_name, b.utility_num,
		CASE WHEN b.utility_name in ('Native Village of Perryville - (AK)', 'Kokhanok Village Council', 'Pedro Bay Village Council - (AK)', 'City of Atka - (AK)', 'City of Pioche - (NV)', 'City of Egegik - (AK)', 'City of Caliente - (NV)', 'Lincoln County Power Dist No 1', 'City of Saint Paul', 'CBY DBA Yakutat Power') THEN 'Muni'
			WHEN b.utility_name in ('Penoyer Valley Electric Coop', 'Naknek Electric Assn, Inc', 'I-N-N Electric Coop, Inc') THEN 'Coop'
			WHEN b.utility_name in ('Texas-New Mexico Power Co', 'Oncor Electric Delivery Company LLC', 'CenterPoint Energy', 'AEP Texas North Company', 'Alamo Power District No 3') THEN 'All Other'
		END as utility_type
	from a
	left join eia.eia_861_2013_county_utility_rates b
	ON a.state_fips = b.statefp
	and a.county_fips = b.countyfp
),
c as 
(
	select distinct on (state_fips, county_fips)
		state_fips, county_fips, utility_name, utility_num, utility_type
	FROM b
	order by state_fips, county_fips, utility_num -- need to do this because there are multiple utilities for some counties, and since we can't rank on sales, rank arbitrarily on utility num
),
d as
(
	select a.pgid, c.utility_num, c.utility_type
	FROM diffusion_blocks.block_primary_electric_utilities a
	left join diffusion_blocks.block_geoms b
		ON a.pgid = b.pgid
	LEFT JOIN c
		ON b.state_fips = c.state_fips
		and b.county_fips = c.county_fips
	where a.utility_num_res is null
	or a.utility_num_com is null
	or a.utility_num_ind is null
	or a.utility_num_tot is null
)
UPDATE diffusion_blocks.block_primary_electric_utilities e
set (
	utility_num_res, 
	utility_num_com, 
	utility_num_ind, 
	utility_num_tot, 

	utility_type_res, 
	utility_type_com, 
	utility_type_ind, 
	utility_type_tot ) = 

(
	d.utility_num,
	d.utility_num,
	d.utility_num,
	d.utility_num,

	d.utility_type,
	d.utility_type,
	d.utility_type,
	d.utility_type
)
from d
where e.pgid = d.pgid;
-- 21541 rows affected

-- how many nulls remain?
select count(*)
FROM diffusion_blocks.block_primary_electric_utilities
where utility_num_res is null
or utility_num_com is null
or utility_num_ind is null
or utility_num_tot is null;
-- 287

-- -- where are they?
select distinct b.state_abbr, b.county_fips
FROM diffusion_blocks.block_primary_electric_utilities a
left join diffusion_blocks.block_geoms b
ON a.pgid = b.pgid
where a.utility_num_res is null
or a.utility_num_com is null
or a.utility_num_ind is null
or a.utility_num_tot is null
order by state_abbr, county_fips;
-- all are in AK, county_fips = 105

select *
FROM diffusion_blocks.county_geoms
where state_abbr = 'AK'
and county_fips = '105';
-- Hoonah-ANgoon

-- according to the EIA-861 2013 Service Territory FOrm
-- Skagway Hoonah ANgoon is part of 6 utility numbers

-- -- do these utilities exist in the eia table with the same utility_nums??
select *
FROM diffusion_blocks.electric_utilities_lkup
where utility_num in 
(
	219, 
	4329, 
	7822, 
	18541, 
	18963, 
	29297
);
-- only two of them exist -- 4329 and 219
-- of these 2, 219 is has more customers across all categories, so use it to rperesent the county

UPDATE diffusion_blocks.block_primary_electric_utilities
set (
	utility_num_res, 
	utility_num_com, 
	utility_num_ind, 
	utility_num_tot, 

	utility_type_res, 
	utility_type_com, 
	utility_type_ind, 
	utility_type_tot ) = 

(
	219,
	219,
	219,
	219,

	'IOU',
	'IOU',
	'IOU',
	'IOU'
)
where utility_num_res is null
or utility_num_com is null
or utility_num_ind is null
or utility_num_tot is null;


-- any nulls remain?
select count(*)
FROM diffusion_blocks.block_primary_electric_utilities
where utility_num_res is null
or utility_num_com is null
or utility_num_ind is null
or utility_num_tot is null;
-- 0 -- all set !!!!!
-------------------------------------------------------------------------------------------------
