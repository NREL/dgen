with a as
(
	SELECT a.table_schema, a.table_name, a.table_schema || '.' || a.table_name as relation_name
	FROM information_schema.tables a
	INNER JOIN information_schema.schemata b
	ON a.table_schema = b.schema_name::TEXT 
	where b.schema_name like 'diffusion_%'
	and b.schema_name not like 'diffusion_data_%'
	order by a.table_schema asc, a.table_name
),
b as
(
	select a.*, pg_total_relation_size(relation_name) as size_bytes
	from a
)
select b.table_schema, sum(b.size_bytes) as size_bytes,
	pg_size_pretty(sum(b.size_bytes)) as size_pretty
from b
group by b.table_schema
order by size_bytes desc;
-- sizes are:
-- diffusion_resource_wind,116155695104,108 GB
-- diffusion_resource_solar,64499761152,60 GB
-- diffusion_blocks,52575330304,49 GB
-- diffusion_points,22452207616,21 GB
-- diffusion_shared,3153698816,3008 MB
-- diffusion_wind,1140989952,1088 MB
-- diffusion_load_profiles,496386048,473 MB
-- diffusion_solar,399327232,381 MB
-- diffusion_geo,173973504,166 MB
-- diffusion_template,679936,664 kB
-- diffusion_config,557056,544 kB

-- look into why diffusion_shared and diffusion_wind are still > 1 GB
with a as
(
	SELECT a.table_schema, a.table_name, a.table_schema || '.' || a.table_name as relation_name
	FROM information_schema.tables a
	INNER JOIN information_schema.schemata b
	ON a.table_schema = b.schema_name::TEXT 
	where b.schema_name in ('diffusion_shared', 'diffusion_wind')
	order by a.table_schema asc, a.table_name
),
b as
(
	select a.*, pg_total_relation_size(relation_name) as size_bytes
	from a
)
select b.table_schema, b.table_name, b.size_bytes,
	pg_size_pretty(b.size_bytes) as size_pretty
from b
order by size_bytes desc;
-- mostly it is the ranked_rate_array_lkup_[sector_abbr] and ij_cfbin_lookup_com_pts_us_[sector_abbr] tables
-- the former will remain, but the ijcfbin lookups may go away with the move to block data