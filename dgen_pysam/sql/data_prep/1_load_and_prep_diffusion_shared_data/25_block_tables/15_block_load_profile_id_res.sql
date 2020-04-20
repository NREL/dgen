SET ROLE 'diffusion-writers';

------------------------------------------------------------------------------------------------------
-- create table

DROP TABLE IF EXISTS diffusion_blocks.block_load_profile_id_res;
CREATE TABLE diffusion_blocks.block_load_profile_id_res AS
select a.pgid, b.hdf_index as hdf_load_index
from diffusion_blocks.block_resource_id_solar a
LEFT JOIN diffusion_data_shared.solar_re_9809_to_eplus_load_res b
ON a.solar_re_9809_gid = b.solar_re_9809_gid;

------------------------------------------------------------------------------------------------------
-- QAQC

-- add primary key
ALTER TABLE diffusion_blocks.block_load_profile_id_res
ADD PRIMARY KEY (pgid);

-- check count
select count(*)
FROM diffusion_blocks.block_load_profile_id_res;
-- 10535171

-- check for nulls
select count(*)
FROM diffusion_blocks.block_load_profile_id_res
where hdf_load_index is null;
-- 71749

-- where are these?
select distinct b.state_abbr
from diffusion_blocks.block_load_profile_id_res a
LEFT JOIN diffusion_blocks.block_geoms b
ON a.pgid = b.pgid
where a.hdf_load_index is null;
-- NM
-- AK
-- HI
-- CA

-- what's going on with NM and CA?
select distinct b.state_abbr, b.county_fips
from diffusion_blocks.block_load_profile_id_res a
LEFT JOIN diffusion_blocks.block_geoms b
ON a.pgid = b.pgid
where a.hdf_load_index is null
and b.state_abbr in ('CA', 'NM')
order by 1, 2;

-- these gaps are due to missing stations in the load data
-- fix them with a nearest neighbor from same county with data
with a as
(
	select a.pgid, b.state_fips, b.county_fips, b.the_point_96703
	from diffusion_blocks.block_load_profile_id_res a
	left join diffusion_blocks.block_geoms b
	ON a.pgid = b.pgid
	where a.hdf_load_index is null
	and b.state_abbr not in ('HI', 'AK')
),
b as
(
	select a.pgid, a.hdf_load_index, b.state_fips, b.county_fips, b.the_point_96703
	from diffusion_blocks.block_load_profile_id_res a
	left join diffusion_blocks.block_geoms b
	ON a.pgid = b.pgid
	where a.hdf_load_index is NOT null
	and b.state_abbr not in ('HI', 'AK')
),
c as
(
	select a.pgid, b.hdf_load_index, 
		ST_Distance(a.the_point_96703, b.the_point_96703) as dist_m
	from a
	left join b
	ON a.state_fips = b.state_fips
	and a.county_fips = b.county_fips
),
d AS
(
	select distinct on (c.pgid) c.pgid, c.hdf_load_index
	from c
	ORDER BY c.pgid ASC, c.dist_m asc
)
UPDATE diffusion_blocks.block_load_profile_id_res e
set hdf_load_index = d.hdf_load_index
from d
where e.pgid = d.pgid
AND e.hdf_load_index is null;
-- 21108 rows

-- recheck for nulls outside of AK and HI
select distinct b.state_abbr
from diffusion_blocks.block_load_profile_id_res a
LEFT JOIN diffusion_blocks.block_geoms b
ON a.pgid = b.pgid
where a.hdf_load_index is null;
-- AK and HI only, all set!