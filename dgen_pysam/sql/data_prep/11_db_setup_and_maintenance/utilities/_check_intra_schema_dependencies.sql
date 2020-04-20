-- use the following query to find all dependencies for a given schema:
-- 
with schema_oid as
(
	-- find the oid of the schema of interest
	select oid as schema_oid
	from pg_catalog.pg_namespace
--  	WHERE nspname = 'diffusion_wind'
-- 	where nspname = 'diffusion_wind_data'
-- 	where nspname = 'diffusion_wind_config'
	where nspname = 'diffusion_solar'
-- 	where nspname = 'diffusion_solar_data'
-- 	where nspname = 'diffusion_solar_config'
),
schema_tables_and_views as
(
	select a.oid as table_oid, a.relnamespace as schema_oid, *
	FROM pg_catalog.pg_class a
	inner join schema_oid b
	ON a.relnamespace = b.schema_oid
),
dependent_objects as 
(
	select b.objid as dependent_object_oid
	FROM schema_tables_and_views a
	LEFT JOIN pg_depend b
	ON a.table_oid = b.refobjid
),
dependent_objects_in_diff_schema AS
(
	SELECT b.relname, b.relnamespace
	FROM dependent_objects a
	left join pg_catalog.pg_class b
	on a.dependent_object_oid = b.oid
	left join schema_oid c
	ON b.relnamespace = c.schema_oid
	where c.schema_oid is null
	and b.relkind in ('r','i','s','v','c')
	order by 2
)
SELECT b.nspname, a.relname
FROM dependent_objects_in_diff_schema a
left join pg_catalog.pg_namespace b
oN b.oid = a.relnamespace;
----------------------------------------------------------------------------------------------------


-- to find view dependencies:
select distinct(table_schema)
FROM information_schema.view_table_usage
where view_schema = 'diffusion_shared'  
and table_schema <> 'diffusion_shared';


-- move tables for:
-- diffusion_wind: (note: this was a one time fix)
-- ALTER TABLE diffusion_wind_data.archive_wind_resource_current_mid_turbine SET SCHEMA diffusion_wind;
-- ALTER TABLE diffusion_wind_data.archive_wind_resource_current_large_turbine SET SCHEMA diffusion_wind;
-- ALTER TABLE diffusion_wind_data.archive_wind_resource_nearfuture_small_turbine SET SCHEMA diffusion_wind;
-- ALTER TABLE diffusion_wind_data.archive_wind_resource_nearfuture_mid_and_large_turbine SET SCHEMA diffusion_wind;
-- ALTER TABLE diffusion_wind_data.archive_wind_resource_future_small_turbine SET SCHEMA diffusion_wind;
-- ALTER TABLE diffusion_wind_data.archive_wind_resource_future_mid_and_large_turbine SET SCHEMA diffusion_wind;
-- ALTER TABLE diffusion_wind_data.wind_resource_far_future_small_turbine SET SCHEMA diffusion_wind;
-- ALTER TABLE diffusion_wind_data.wind_resource_near_future_mid_size_turbine SET SCHEMA diffusion_wind;
-- ALTER TABLE diffusion_wind_data.wind_resource_far_future_mid_size_and_large_turbine SET SCHEMA diffusion_wind;
-- ALTER TABLE diffusion_wind_data.archive_wind_resource_current_small_turbine SET SCHEMA diffusion_wind;
-- ALTER TABLE diffusion_wind_data.wind_resource_current_residential_turbine SET SCHEMA diffusion_wind;
-- ALTER TABLE diffusion_wind_data.wind_resource_current_small_commercial_turbine SET SCHEMA diffusion_wind;
-- ALTER TABLE diffusion_wind_data.wind_resource_current_mid_size_turbine SET SCHEMA diffusion_wind;
-- ALTER TABLE diffusion_wind_data.wind_resource_near_future_residential_turbine SET SCHEMA diffusion_wind;

-- diffusion_wind_data: None
-- diffusion_solar: None
-- diffusion_solar_data: None
-- diffusion_solar_config: None
-- diffusion_wind_config: None


