
-- create temp table to store data
set role 'diffusion-writers';
drop table if exists diffusion_geo.tract_road_length_temp;
create table diffusion_geo.tract_road_length_temp
(
state_fips varchar(2),
length_m numeric,
tract_fips varchar(6)
);

-- copy data into temp table
\COPY diffusion_geo.tract_road_length_temp FROM /Volumes/Staff/mgleason/dGeo/Data/Analysis/calc_road_length_by_tract/summary_stats/sum_stats_road_length_by_tract_stfips_01.csv with csv header;
\COPY diffusion_geo.tract_road_length_temp FROM /Volumes/Staff/mgleason/dGeo/Data/Analysis/calc_road_length_by_tract/summary_stats/sum_stats_road_length_by_tract_stfips_02.csv with csv header;
\COPY diffusion_geo.tract_road_length_temp FROM /Volumes/Staff/mgleason/dGeo/Data/Analysis/calc_road_length_by_tract/summary_stats/sum_stats_road_length_by_tract_stfips_04.csv with csv header;
\COPY diffusion_geo.tract_road_length_temp FROM /Volumes/Staff/mgleason/dGeo/Data/Analysis/calc_road_length_by_tract/summary_stats/sum_stats_road_length_by_tract_stfips_05.csv with csv header;
\COPY diffusion_geo.tract_road_length_temp FROM /Volumes/Staff/mgleason/dGeo/Data/Analysis/calc_road_length_by_tract/summary_stats/sum_stats_road_length_by_tract_stfips_06.csv with csv header;
\COPY diffusion_geo.tract_road_length_temp FROM /Volumes/Staff/mgleason/dGeo/Data/Analysis/calc_road_length_by_tract/summary_stats/sum_stats_road_length_by_tract_stfips_08.csv with csv header;
\COPY diffusion_geo.tract_road_length_temp FROM /Volumes/Staff/mgleason/dGeo/Data/Analysis/calc_road_length_by_tract/summary_stats/sum_stats_road_length_by_tract_stfips_09.csv with csv header;
\COPY diffusion_geo.tract_road_length_temp FROM /Volumes/Staff/mgleason/dGeo/Data/Analysis/calc_road_length_by_tract/summary_stats/sum_stats_road_length_by_tract_stfips_10.csv with csv header;
\COPY diffusion_geo.tract_road_length_temp FROM /Volumes/Staff/mgleason/dGeo/Data/Analysis/calc_road_length_by_tract/summary_stats/sum_stats_road_length_by_tract_stfips_11.csv with csv header;
\COPY diffusion_geo.tract_road_length_temp FROM /Volumes/Staff/mgleason/dGeo/Data/Analysis/calc_road_length_by_tract/summary_stats/sum_stats_road_length_by_tract_stfips_12.csv with csv header;
\COPY diffusion_geo.tract_road_length_temp FROM /Volumes/Staff/mgleason/dGeo/Data/Analysis/calc_road_length_by_tract/summary_stats/sum_stats_road_length_by_tract_stfips_13.csv with csv header;
\COPY diffusion_geo.tract_road_length_temp FROM /Volumes/Staff/mgleason/dGeo/Data/Analysis/calc_road_length_by_tract/summary_stats/sum_stats_road_length_by_tract_stfips_15.csv with csv header;
\COPY diffusion_geo.tract_road_length_temp FROM /Volumes/Staff/mgleason/dGeo/Data/Analysis/calc_road_length_by_tract/summary_stats/sum_stats_road_length_by_tract_stfips_16.csv with csv header;
\COPY diffusion_geo.tract_road_length_temp FROM /Volumes/Staff/mgleason/dGeo/Data/Analysis/calc_road_length_by_tract/summary_stats/sum_stats_road_length_by_tract_stfips_17.csv with csv header;
\COPY diffusion_geo.tract_road_length_temp FROM /Volumes/Staff/mgleason/dGeo/Data/Analysis/calc_road_length_by_tract/summary_stats/sum_stats_road_length_by_tract_stfips_18.csv with csv header;
\COPY diffusion_geo.tract_road_length_temp FROM /Volumes/Staff/mgleason/dGeo/Data/Analysis/calc_road_length_by_tract/summary_stats/sum_stats_road_length_by_tract_stfips_19.csv with csv header;
\COPY diffusion_geo.tract_road_length_temp FROM /Volumes/Staff/mgleason/dGeo/Data/Analysis/calc_road_length_by_tract/summary_stats/sum_stats_road_length_by_tract_stfips_20.csv with csv header;
\COPY diffusion_geo.tract_road_length_temp FROM /Volumes/Staff/mgleason/dGeo/Data/Analysis/calc_road_length_by_tract/summary_stats/sum_stats_road_length_by_tract_stfips_21.csv with csv header;
\COPY diffusion_geo.tract_road_length_temp FROM /Volumes/Staff/mgleason/dGeo/Data/Analysis/calc_road_length_by_tract/summary_stats/sum_stats_road_length_by_tract_stfips_22.csv with csv header;
\COPY diffusion_geo.tract_road_length_temp FROM /Volumes/Staff/mgleason/dGeo/Data/Analysis/calc_road_length_by_tract/summary_stats/sum_stats_road_length_by_tract_stfips_23.csv with csv header;
\COPY diffusion_geo.tract_road_length_temp FROM /Volumes/Staff/mgleason/dGeo/Data/Analysis/calc_road_length_by_tract/summary_stats/sum_stats_road_length_by_tract_stfips_24.csv with csv header;
\COPY diffusion_geo.tract_road_length_temp FROM /Volumes/Staff/mgleason/dGeo/Data/Analysis/calc_road_length_by_tract/summary_stats/sum_stats_road_length_by_tract_stfips_25.csv with csv header;
\COPY diffusion_geo.tract_road_length_temp FROM /Volumes/Staff/mgleason/dGeo/Data/Analysis/calc_road_length_by_tract/summary_stats/sum_stats_road_length_by_tract_stfips_26.csv with csv header;
\COPY diffusion_geo.tract_road_length_temp FROM /Volumes/Staff/mgleason/dGeo/Data/Analysis/calc_road_length_by_tract/summary_stats/sum_stats_road_length_by_tract_stfips_27.csv with csv header;
\COPY diffusion_geo.tract_road_length_temp FROM /Volumes/Staff/mgleason/dGeo/Data/Analysis/calc_road_length_by_tract/summary_stats/sum_stats_road_length_by_tract_stfips_28.csv with csv header;
\COPY diffusion_geo.tract_road_length_temp FROM /Volumes/Staff/mgleason/dGeo/Data/Analysis/calc_road_length_by_tract/summary_stats/sum_stats_road_length_by_tract_stfips_29.csv with csv header;
\COPY diffusion_geo.tract_road_length_temp FROM /Volumes/Staff/mgleason/dGeo/Data/Analysis/calc_road_length_by_tract/summary_stats/sum_stats_road_length_by_tract_stfips_30.csv with csv header;
\COPY diffusion_geo.tract_road_length_temp FROM /Volumes/Staff/mgleason/dGeo/Data/Analysis/calc_road_length_by_tract/summary_stats/sum_stats_road_length_by_tract_stfips_31.csv with csv header;
\COPY diffusion_geo.tract_road_length_temp FROM /Volumes/Staff/mgleason/dGeo/Data/Analysis/calc_road_length_by_tract/summary_stats/sum_stats_road_length_by_tract_stfips_32.csv with csv header;
\COPY diffusion_geo.tract_road_length_temp FROM /Volumes/Staff/mgleason/dGeo/Data/Analysis/calc_road_length_by_tract/summary_stats/sum_stats_road_length_by_tract_stfips_33.csv with csv header;
\COPY diffusion_geo.tract_road_length_temp FROM /Volumes/Staff/mgleason/dGeo/Data/Analysis/calc_road_length_by_tract/summary_stats/sum_stats_road_length_by_tract_stfips_34.csv with csv header;
\COPY diffusion_geo.tract_road_length_temp FROM /Volumes/Staff/mgleason/dGeo/Data/Analysis/calc_road_length_by_tract/summary_stats/sum_stats_road_length_by_tract_stfips_35.csv with csv header;
\COPY diffusion_geo.tract_road_length_temp FROM /Volumes/Staff/mgleason/dGeo/Data/Analysis/calc_road_length_by_tract/summary_stats/sum_stats_road_length_by_tract_stfips_36.csv with csv header;
\COPY diffusion_geo.tract_road_length_temp FROM /Volumes/Staff/mgleason/dGeo/Data/Analysis/calc_road_length_by_tract/summary_stats/sum_stats_road_length_by_tract_stfips_37.csv with csv header;
\COPY diffusion_geo.tract_road_length_temp FROM /Volumes/Staff/mgleason/dGeo/Data/Analysis/calc_road_length_by_tract/summary_stats/sum_stats_road_length_by_tract_stfips_38.csv with csv header;
\COPY diffusion_geo.tract_road_length_temp FROM /Volumes/Staff/mgleason/dGeo/Data/Analysis/calc_road_length_by_tract/summary_stats/sum_stats_road_length_by_tract_stfips_39.csv with csv header;
\COPY diffusion_geo.tract_road_length_temp FROM /Volumes/Staff/mgleason/dGeo/Data/Analysis/calc_road_length_by_tract/summary_stats/sum_stats_road_length_by_tract_stfips_40.csv with csv header;
\COPY diffusion_geo.tract_road_length_temp FROM /Volumes/Staff/mgleason/dGeo/Data/Analysis/calc_road_length_by_tract/summary_stats/sum_stats_road_length_by_tract_stfips_41.csv with csv header;
\COPY diffusion_geo.tract_road_length_temp FROM /Volumes/Staff/mgleason/dGeo/Data/Analysis/calc_road_length_by_tract/summary_stats/sum_stats_road_length_by_tract_stfips_42.csv with csv header;
\COPY diffusion_geo.tract_road_length_temp FROM /Volumes/Staff/mgleason/dGeo/Data/Analysis/calc_road_length_by_tract/summary_stats/sum_stats_road_length_by_tract_stfips_44.csv with csv header;
\COPY diffusion_geo.tract_road_length_temp FROM /Volumes/Staff/mgleason/dGeo/Data/Analysis/calc_road_length_by_tract/summary_stats/sum_stats_road_length_by_tract_stfips_45.csv with csv header;
\COPY diffusion_geo.tract_road_length_temp FROM /Volumes/Staff/mgleason/dGeo/Data/Analysis/calc_road_length_by_tract/summary_stats/sum_stats_road_length_by_tract_stfips_46.csv with csv header;
\COPY diffusion_geo.tract_road_length_temp FROM /Volumes/Staff/mgleason/dGeo/Data/Analysis/calc_road_length_by_tract/summary_stats/sum_stats_road_length_by_tract_stfips_47.csv with csv header;
\COPY diffusion_geo.tract_road_length_temp FROM /Volumes/Staff/mgleason/dGeo/Data/Analysis/calc_road_length_by_tract/summary_stats/sum_stats_road_length_by_tract_stfips_48.csv with csv header;
\COPY diffusion_geo.tract_road_length_temp FROM /Volumes/Staff/mgleason/dGeo/Data/Analysis/calc_road_length_by_tract/summary_stats/sum_stats_road_length_by_tract_stfips_49.csv with csv header;
\COPY diffusion_geo.tract_road_length_temp FROM /Volumes/Staff/mgleason/dGeo/Data/Analysis/calc_road_length_by_tract/summary_stats/sum_stats_road_length_by_tract_stfips_50.csv with csv header;
\COPY diffusion_geo.tract_road_length_temp FROM /Volumes/Staff/mgleason/dGeo/Data/Analysis/calc_road_length_by_tract/summary_stats/sum_stats_road_length_by_tract_stfips_51.csv with csv header;
\COPY diffusion_geo.tract_road_length_temp FROM /Volumes/Staff/mgleason/dGeo/Data/Analysis/calc_road_length_by_tract/summary_stats/sum_stats_road_length_by_tract_stfips_53.csv with csv header;
\COPY diffusion_geo.tract_road_length_temp FROM /Volumes/Staff/mgleason/dGeo/Data/Analysis/calc_road_length_by_tract/summary_stats/sum_stats_road_length_by_tract_stfips_54.csv with csv header;
\COPY diffusion_geo.tract_road_length_temp FROM /Volumes/Staff/mgleason/dGeo/Data/Analysis/calc_road_length_by_tract/summary_stats/sum_stats_road_length_by_tract_stfips_55.csv with csv header;
\COPY diffusion_geo.tract_road_length_temp FROM /Volumes/Staff/mgleason/dGeo/Data/Analysis/calc_road_length_by_tract/summary_stats/sum_stats_road_length_by_tract_stfips_56.csv with csv header;


-- Create final table to store tracts and road meters
drop table if exists diffusion_geo.tract_road_length;
create table diffusion_geo.tract_road_length as (
select b.tract_id_alias, a.length_m, a.tract_fips, b.tract_fips as b_tract_fips, a.state_fips, b.state_fips as b_state_fips
from diffusion_geo.tract_road_length_temp a
left join diffusion_blocks.tract_geoms b
on a.tract_fips = b.tract_fips and a.state_fips = b.state_fips);

-- Run checks
select count(*) from diffusion_geo.tract_road_length; -- 72,732
select count(*) from diffusion_blocks.tract_geoms; -- 72,739
	-- difference =  7 tracts

-- Create view with 7 tracts that are missing roads to see where they are and if they really are missing roads
drop view if exists diffusion_geo.tracts_without_roads;
create view diffusion_geo.tracts_without_roads as (select a.*, b.the_geom_96703 from diffusion_geo.tract_road_length a
left join diffusion_blocks.tract_geoms b
on a.tract_id_alias = b.tract_id_alias
where a.tract_fips is null);
	-- Good to go; tracts are super small or very remote, seems reasonable


-- Create final table to store tracts and road meters
set role 'diffusion-writers';
drop table if exists diffusion_geo.tract_road_length cascade;
create table diffusion_geo.tract_road_length as (
select b.tract_id_alias, a.length_m as road_meters
from diffusion_geo.tract_road_length_temp a
full join diffusion_blocks.tract_geoms b
on a.tract_fips = b.tract_fips and a.state_fips = b.state_fips);

-- Add primary key for tract_id_alias
alter table diffusion_geo.tract_road_length
add constraint tract_road_length_tract_id_pkey
primary key (tract_id_alias);


-- Set road length to 0 in the 7 tracts that are missing roads
update diffusion_geo.tract_road_length
set length_m = 0
where tract_id_alias = 56268 or tract_id_alias = 2775 or tract_id_alias = 19497 or tract_id_alias = 28921
or tract_id_alias = 71069 or tract_id_alias = 12899 or tract_id_alias = 27134;

-- delete view used to check 7 tracts without roads
drop view if exists diffusion_geo.tracts_without_roads;

-- detete the temp tables
drop table if exists diffusion_geo.tract_road_length_temp;


