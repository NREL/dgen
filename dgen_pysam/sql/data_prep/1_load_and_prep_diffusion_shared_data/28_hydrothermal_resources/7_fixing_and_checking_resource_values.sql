----------------------------------------------------------------------------------------------------
-- ACCESSIBLE RESOURCE

-- POLYS
-- first, check the values -- are they right?
select 2.6 * 1e+15 * gis_res_area_km2 * res_thickness_km * (res_temp_deg_c - 15)/1e18 as ar_ej,
	accessible_resource_base_1e18_joules,
	diffusion_geo.accessible_resource_joules(res_thickness_km * gis_res_area_km2, res_temp_deg_c)/1e18
from diffusion_geo.resources_hydrothermal_poly;
-- no, something is off

-- fix them
UPDATE diffusion_geo.resources_hydrothermal_poly
set accessible_resource_base_1e18_joules = 
	round(diffusion_geo.accessible_resource_joules(res_thickness_km * gis_res_area_km2, res_temp_deg_c)/1e18, 3);
-- fixed 184 rows

-- replace any negatives with value of zero
UPDATE diffusion_geo.resources_hydrothermal_poly
set accessible_resource_base_1e18_joules = 0
where accessible_resource_base_1e18_joules < 0;
-- one row affected


-- POINTS
-- check that the values are right
select 2.6 * 1e+15 * res_vol_km3 * (res_temp_deg_c - 15)/1e18 as ar_ej,
	accessible_resource_base_1e18_joules,
	diffusion_geo.accessible_resource_joules(res_vol_km3, res_temp_deg_c)/1e18
from diffusion_geo.resources_hydrothermal_pt;
-- these look right
-- double check

select max(@(accessible_resource_base_1e18_joules - diffusion_geo.accessible_resource_joules(res_vol_km3, res_temp_deg_c)/1e18))
from diffusion_geo.resources_hydrothermal_pt;
-- biggest difference is very small
-- no problems

-- check aggregate results
with a as
(
	select sum(accessible_resource_base_1e18_joules) as ar
	from diffusion_geo.resources_hydrothermal_poly
	UNION ALL
	select sum(accessible_resource_base_1e18_joules) as ar
	from diffusion_geo.resources_hydrothermal_pt
)
select sum(ar)
FROM a;
-- 28,386.097 exajoules -- matches Table 2 in the paper

-- how about the breakout by system type?
with a as
(
	select sys_type, sum(accessible_resource_base_1e18_joules) as ar
	from diffusion_geo.resources_hydrothermal_poly
	group by sys_type
	UNION ALL
	select sys_type, sum(accessible_resource_base_1e18_joules) as ar
	from diffusion_geo.resources_hydrothermal_pt
	group by sys_type
)
select sys_type, sum(ar)
FROM a
group by sys_type;
-- yes -- also matches Table 2 in the paper

------------------------------------------------------------------------------------------------------------
-- RESOURCE
-- POLYS
-- first, check the values -- are they right?
select 4.1 * 1000 * 0.5 * gis_res_area_km2/area_per_well_km2 * 31.5 * 30 * 8760 * 3600 * (res_temp_deg_c - 15)/1e18 as r,
	mean_resource_1e18_joules,
	diffusion_geo.extractable_resource_joules_production_plan(gis_res_area_km2/area_per_well_km2, res_temp_deg_c)/1e18
from diffusion_geo.resources_hydrothermal_poly;
-- yes, the look close
-- confirm

select max(@(mean_resource_1e18_joules - diffusion_geo.extractable_resource_joules_production_plan(n_wells, res_temp_deg_c)/1e18))
from diffusion_geo.resources_hydrothermal_poly;
-- biggest difference is very small 0.01160916435000000000 -- go ahead and fix though

-- check n wells is right
select round(gis_res_area_km2/area_per_well_km2, 0), n_wells
from diffusion_geo.resources_hydrothermal_poly;
-- round instead of truncates since lots of areas are approx anyway
-- looks good

UPDATE diffusion_geo.resources_hydrothermal_poly
set mean_resource_1e18_joules = round(diffusion_geo.extractable_resource_joules_production_plan(n_wells, res_temp_deg_c)/1e18, 3);
-- 184 rows affected

-- change negatives to zero
UPDATE diffusion_geo.resources_hydrothermal_poly
set mean_resource_1e18_joules = 0
where mean_resource_1e18_joules < 0;

-- POINTS
select round(diffusion_geo.accessible_resource_joules(res_vol_km3, res_temp_deg_c)/1e18 * 0.125, 3),
	mean_resource_1e18_joules
from diffusion_geo.resources_hydrothermal_pt;
-- yes, the look close
-- confirm

select max(@(mean_resource_1e18_joules - round(diffusion_geo.accessible_resource_joules(res_vol_km3, res_temp_deg_c)/1e18 * 0.125, 3)))
from diffusion_geo.resources_hydrothermal_pt;
-- max difference is 0.001 -- all set


-- check aggregate results
with a as
(
	select sum(mean_resource_1e18_joules) as r
	from diffusion_geo.resources_hydrothermal_poly
	UNION ALL
	select sum(mean_resource_1e18_joules) as r
	from diffusion_geo.resources_hydrothermal_pt
)
select sum(r)
FROM a;
-- 87.258 exajoules -- matches Table 2 in the paper

-- how about the breakout by system type?
with a as
(
	select sys_type, sum(mean_resource_1e18_joules) as r
	from diffusion_geo.resources_hydrothermal_poly
	group by sys_type
	UNION ALL
	select sys_type, sum(mean_resource_1e18_joules) as r
	from diffusion_geo.resources_hydrothermal_pt
	group by sys_type
)
select sys_type, sum(r)
FROM a
group by sys_type;
-- also matches Table 2 in the paper
------------------------------------------------------------------------------------------------------------
-- BENEFICIAL HEAT
select round(4.1 * 1000 * 0.5 * gis_res_area_km2/area_per_well_km2 * 31.5 * 30 * 8760 * 3600 * 0.6 * (res_temp_deg_c - 25)/1e18, 3) as r,
	beneficial_heat_1e18_joules,
	round(diffusion_geo.beneficial_heat_joules_production_plan(n_wells, res_temp_deg_c)/1e18, 3)
from diffusion_geo.resources_hydrothermal_poly;
-- yes, they look close
-- confirm
select max(@(beneficial_heat_1e18_joules - round(diffusion_geo.beneficial_heat_joules_production_plan(n_wells, res_temp_deg_c)/1e18, 3)))
from diffusion_geo.resources_hydrothermal_poly;
-- biggest difference is very small -- 0.014
-- leave as is


-- POINTS
select round(2.6 * 1e+15 * res_vol_km3 * 0.125 * 0.6 * (res_temp_deg_c - 25)/1e18, 3) as ar_ej,
	round(diffusion_geo.beneficial_heat_joules_recovery_factor(res_vol_km3, res_temp_deg_c)/1e18, 3),
	beneficial_heat_1e18_joules
from diffusion_geo.resources_hydrothermal_pt;
-- yes, the look close
-- confirm

select max(@(beneficial_heat_1e18_joules - round(diffusion_geo.beneficial_heat_joules_recovery_factor(res_vol_km3, res_temp_deg_c)/1e18, 3)))
from diffusion_geo.resources_hydrothermal_pt;
-- max difference is 0.002 -- all set

-- check totals
with a as
(
	select sum(beneficial_heat_1e18_joules) as r
	from diffusion_geo.resources_hydrothermal_poly
	UNION ALL
	select sum(beneficial_heat_1e18_joules) as r
	from diffusion_geo.resources_hydrothermal_pt
)
select sum(r) as bh_exajoules,
	sum(r)*277778/1e6 as bh_million_gwh,
	sum(r)*277778/(30*8760) as bh_gwt_for_30_yrs
FROM a;
-- 41.134 exajoules
-- 11.4261202520000000 million gwh -- 11.2 million in the paper
-- 43.4783875646879756 gwt for 30 years

-- how about the breakout by system type?
with a as
(
	select sys_type, sum(beneficial_heat_1e18_joules) as r
	from diffusion_geo.resources_hydrothermal_poly
	group by sys_type
	UNION ALL
	select sys_type, sum(beneficial_heat_1e18_joules) as r
	from diffusion_geo.resources_hydrothermal_pt
	group by sys_type
)
select sys_type, sum(r) as bh_exajoules,
	sum(r)*277778/1e6 as bh_million_gwh,
	sum(r)*277778/(30*8760) as bh_mwt_for_30_yrs
FROM a
group by sys_type;
-- type, exajoules, million gwh, gwt
-- delineated area,2.680,0.74444504000000000000,2.8327436834094368
-- sedimentary basin,27.329,7.5913949620000000,28.8865866133942161
-- coastal plain,0.424,0.11777787200000000000,0.44816541856925418569
-- isolated system,10.701,2.9725023780000000,11.3108918493150685
-- the exajoules match the paper closely, so all looks good

