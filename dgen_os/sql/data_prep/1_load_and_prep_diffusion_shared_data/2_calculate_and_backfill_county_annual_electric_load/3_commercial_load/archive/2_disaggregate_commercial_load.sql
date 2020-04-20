-- using cbecs data, calculate the proportion of the total regional load consumed by each pba in each region
-- format results into normal form
DROP TABLE IF EXISTS dg_wind.cbecs_elec_consumption_proportions;
CREATE TABLE dg_wind.cbecs_elec_consumption_proportions AS

SELECT a.building_type, 
	a.northeast_elec_load_billion_kwh/sum(northeast_elec_load_billion_kwh) OVER () as regional_load_proportion,
	'Northeast'::text as region
FROM dg_wind.cbecs_elec_consumption_by_census_region_and_pba a

UNION ALL

SELECT a.building_type, 
	a.midwest_elec_load_billion_kwh/sum(midwest_elec_load_billion_kwh) OVER () as regional_load_proportion,
	'Midwest'::text as region
FROM dg_wind.cbecs_elec_consumption_by_census_region_and_pba a

UNION ALL

SELECT a.building_type, 
	a.south_elec_load_billion_kwh/sum(south_elec_load_billion_kwh) OVER () as regional_load_proportion,
	'South'::text as region
FROM dg_wind.cbecs_elec_consumption_by_census_region_and_pba a


UNION ALL

SELECT a.building_type, 
	a.west_elec_load_billion_kwh/sum(west_elec_load_billion_kwh) OVER () as regional_load_proportion,
	'West'::text as region
FROM dg_wind.cbecs_elec_consumption_by_census_region_and_pba a;

-- check HSIP and navteq for overlaps/duplication
	-- i think navteq is what i should use for commercial, and hsip for manufacturing?
	-- 

-- next steps:
	
	-- create a table of the navteq points that only includes those fac_types associated with the CBECs PBAs, including the pba code
	-- intersect the subset navteq point table against dg_wind.electric_service_territories_states_with_rates_backfilled, attributing each with gid, and total_commercial_sales_mwh, and census region
	-- to each service territory, join in the proprtions from dg_wind.cbecs_elec_consumption_proportions based on the census region and the distinct pbas that are present (based on previous step)
		-- sum the proportions and re-weight eacha according to the sum
	-- multiple the recalced proprtion against the total load in that service territory, then divide by the number of entities associated with that pba
	-- allocate values back to the points
	-- convert to raster
	

DROP TABLE IF EXISTS dg_wind.navteq_points_pbas_only AS
SELECT *
FROM 


--  test join
SELECT a.region, a.pba_code, b.naics_3, c.table_name
FROM dg_wind.cbecs_elec_consumption_proportions a
LEFT JOIN dg_wind.naics_pba_crosswalk b
ON a.pba_code = b.pba_code
INNER JOIN hsip_2012.all_points_with_naics c
ON b.naics_3 = c.naicscode_3
where a.pba_code = 26
order by a.region, a.pba_code

	