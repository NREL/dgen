set role 'diffusion-writers';

DROP TABLE IF EXISTS diffusion_blocks.tract_building_count_by_sector_temp;
CREATE TABLE diffusion_blocks.tract_building_count_by_sector_temp AS
SELECT a.tract_id_alias,
	sum(b.bldg_count_res) as bldg_count_res,
	sum(b.bldg_count_res_single_family) as bldg_count_res_single_family,
	sum(b.bldg_count_res_multi_family) as bldg_count_res_multi_family,
	sum(b.bldg_count_com) as bldg_count_com,
	sum(b.bldg_count_ind) as bldg_count_ind
FROM diffusion_blocks.block_tract_id_alias a
LEFT JOIN diffusion_blocks.block_bldg_counts b
	ON a.pgid = b.pgid
group by a.tract_id_alias;
-- 72739 rows
	

select *
from diffusion_blocks.tract_building_count_by_sector_temp
where not(bldg_count_res > 0
OR bldg_count_com > 0
OR bldg_count_ind > 0);
-- 63 tracks with no buildings
-- delete these

delete from diffusion_blocks.tract_building_count_by_sector_temp
where not(bldg_count_res > 0
OR bldg_count_com > 0
OR bldg_count_ind > 0);
-- 63 rows deleted

-- sum up the total by census division abbr
DROP TABLE IF EXISTS diffusion_blocks.tract_building_count_by_census_division;
CREATe TABLE diffusion_blocks.tract_building_count_by_census_division AS
select c.division_abbr as census_division_abbr, 
	sum(a.bldg_count_com) as bldg_count_com_cd
from diffusion_blocks.tract_building_count_by_sector_temp a
LEFT JOIN diffusion_blocks.tract_ids b
	ON a.tract_id_alias = b.tract_id_alias
LEFT JOIN eia.census_regions_20140123 c
	ON b.state_fips = c.statefp
GROUP BY c.division_abbr;

-- create final table, adjusting bldg_count_com to sum to eia totals at census division level
DROP TABLE IF EXISTS diffusion_blocks.tract_building_count_by_sector;
CREATE TABLE diffusion_blocks.tract_building_count_by_sector AS
SELECT a.tract_id_alias, c.division_abbr as census_division_abbr,
	a.bldg_count_res,
	a.bldg_count_res_single_family,
	a.bldg_count_res_multi_family,
	a.bldg_count_com::NUMERIC/d.bldg_count_com_cd * e.bldg_count as bldg_count_com,
	a.bldg_count_ind
from diffusion_blocks.tract_building_count_by_sector_temp a
LEFT JOIN diffusion_blocks.tract_ids b
	ON a.tract_id_alias = b.tract_id_alias
LEFT JOIN eia.census_regions_20140123 c
	ON b.state_fips = c.statefp
LEFT JOIN diffusion_blocks.tract_building_count_by_census_division d
	ON c.division_abbr = d.census_division_abbr
LEFT join eia.cbecs_2012_building_counts_by_census_division e
	ON c.division_abbr = e.census_division_abbr;
-- 72676 rows	

-- QAQC
-- add primary key
ALTER TABLE  diffusion_blocks.tract_building_count_by_sector
ADD PRIMARY KEY (tract_id_alias);

-- check row count 
select count(*)
FROM diffusion_blocks.tract_ids;
-- 72739 (should be 63 less than this = 72676)
select count(*)
FROM diffusion_blocks.tract_building_count_by_sector;
-- 72676 -- all set

-- check the counts by census_division_abbr match the eia totals
with a as
(
	select census_division_abbr, sum(bldg_count_com) as bldg_count_com
	from diffusion_blocks.tract_building_count_by_sector
	group by census_division_abbr
)
select *, b.bldg_count as eia_bldg_count
FROM a
left join eia.cbecs_2012_building_counts_by_census_division b
on a.census_division_abbr = b.census_division_abbr;
-- perfect

-- drop the census_division_abbr column
ALTER TABLE diffusion_blocks.tract_building_count_by_sector
DROP COLUMN census_division_abbr;

-- look at a few rows of data
select *
from diffusion_blocks.tract_building_count_by_sector
limit 10;

-- drop the intermediate tables
DROP TABLE IF EXISTS diffusion_blocks.tract_building_count_by_census_division;
drop TABLE IF EXISTS diffusion_blocks.tract_building_count_by_sector_temp;