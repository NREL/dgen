----------------------------------------------------------------------
-- WIND
--create table using zonal stats
DROP TABLE IF EXISTS diffusion_shared.capital_cost_multipliers_us;
CREATE TABLE diffusion_shared.capital_cost_multipliers_us AS
WITH tile_stats as (
	select a.county_id, a.state_abbr,
		ST_SummaryStats(ST_Clip(b.rast, 1, a.the_geom_96703, true)) as stats
		FROM diffusion_shared.county_geom a
		INNER JOIN dg_wind.cap_costs_idw_onshore_wind_10x10 b
		ON ST_Intersects(a.the_geom_96703,b.rast)
		where a.state_abbr not in ('AK','HI') -- the interpolate grid goes into some of these states, but the original points were restricted to conus
),
aggregated as (
	--aggregate the results from each tile
	SELECT county_id, state_abbr, 
		sum((stats).sum)/sum((stats).count) as raw_multiplier
	FROM tile_stats
	GROUP by county_id, state_abbr
)
SELECT county_id,
	case when state_abbr in ('PA','NJ','NY','RI','CT','MA','VT','NH','ME') then raw_multiplier+0.2 -- per consistency with the methodology we used for REEDs
	ELSE raw_multiplier
	end as onshore_wind_cap_cost_multiplier
FROM aggregated;


-- some small counties are going to have no cap_cost_multplier because they didn't contain a raster cell centroid
-- for these, find the mean of all cells they INTERSECT, 
DROP TABLE IF EXISTS dg_wind.missing_capcost;
CREATE TABLE dg_wind.missing_capcost AS
with tile_intersections AS (
	select m.county_id, a.the_geom_96703 as county_geom, ST_PixelAsPolygons(b.rast) as gv
	FROM diffusion_shared.capital_cost_multipliers_us m
	LEFT JOin diffusion_shared.county_geom a 
	ON m.county_id = a.county_id
	INNER JOIN dg_wind.cap_costs_idw_onshore_wind_10x10 b
	ON ST_Intersects(a.the_geom_96703,b.rast)
	where m.onshore_wind_cap_cost_multiplier is null)
SELECT county_id, ST_Transform(county_geom,4326) as the_geom_4326, avg((gv).val) as cap_cost
FROM tile_intersections
where ST_Intersects(county_geom,(gv).geom)
GROUP BY county_id, county_geom;

-- add these changes into the main table
UPDATE diffusion_shared.capital_cost_multipliers_us a
SET onshore_wind_cap_cost_multiplier = b.cap_cost
FROM dg_wind.missing_capcost b
where a.cap_cost_multiplier is null
and a.county_id = b.county_id;

-- check this worked
select count(*)
FROM diffusion_shared.capital_cost_multipliers_us
where onshore_wind_cap_cost_multiplier is null;

-- ADD PRIMARY KEY
ALTER TABLE diffusion_shared.capital_cost_multipliers_us ADD PRIMARY KEY (county_id);

-- create table to check results
-- DROP VIEW IF EXISTS dg_wind.capital_costs_with_geoms;
-- CREATE OR REPLACE VIEW dg_wind.capital_costs_with_geoms AS
-- SELECT a.county_id, a.county, a.state_abbr, a.the_geom_4326,
-- 	b.cap_cost_multiplier
-- FROM diffusion_shared.county_geom a
-- inner join diffusion_shared.capital_cost_multipliers_us b
-- on a.county_id = b.county_id;
-- export to shapefile and create a map to compare to the REEDs region level multipliers
----------------------------------------------------------------------


----------------------------------------------------------------------
-- SOLAR
-- calculate zonal statistics
create table diffusion_solar_data.cap_costs_idw_pv_mw_10x10_agg as
with tile_stats as
(
	select a.county_id, a.state_abbr, ST_SummaryStats(ST_Clip(b.rast, 1, a.the_geom_96703, TRUE)) as stats
	from diffusion_shared.county_geom a 
	inner join diffusion_solar_data.cap_costs_idw_pv_mw_10x10 b
	on ST_Intersects(a.the_geom_96703, b.rast)
	where a.state_abbr not in ('AK', 'HI')
)

select county_id, state_abbr, sum((stats).sum)/sum((stats).count) as pv_20mw_cap_cost_multplier
from tile_stats
group by county_id, state_abbr;

-- some small counties are going to have no cap_cost_multplier because they didn't contain a raster cell centroid
-- for these, find the mean of all cells they INTERSECT, 
create table diffusion_solar_data.missing_cap_costs as

with tile_intersection as 
(
	select a.county_id, b.the_geom_96703 as county_geom, ST_PixelAsPolygons(c.rast) as poly
	from diffusion_solar_data.cap_costs_idw_pv_mw_10x10 a
	left join diffusion_shared.county_geom b 
	on a.county_id = b.county_id
	inner join diffusion_solar_data.cap_costs_idw_pv_mw_10x10_raster c
	on ST_Intersects(b.the_geom_96703, c.rast)
	where a.pv_20mw_cap_cost_multplier is null
)

select county_id, ST_Transform(county_geom, 4326) as the_geom_4326, avg((poly).val) as cap_cost
from tile_intersection
where ST_Intersects(county_geom,(poly).geom)
group by county_id, county_geom;

update diffusion_solar_data.cap_costs_idw_pv_mw_10x10 a
set pv_20mw_cap_cost_multplier = b.cap_cost
from diffusion_solar_data.missing_cap_costs b
where a.pv_20mw_cap_cost_multplier is null
and a.county_id = b.county_id;

select count(*)
from diffusion_solar_data.cap_costs_idw_pv_mw_10x10
where pv_20mw_cap_cost_multplier is null;

update diffusion_shared.capital_cost_multipliers_us a
set pv_20mw_cap_cost_multplier = b.pv_20mw_cap_cost_multplier
from diffusion_solar_data.cap_costs_idw_pv_mw_10x10 b
where a.county_id = b.county_id;