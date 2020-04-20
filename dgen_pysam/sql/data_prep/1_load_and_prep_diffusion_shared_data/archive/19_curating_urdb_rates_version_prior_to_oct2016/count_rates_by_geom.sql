DROP TABLE IF EXIStS diffusion_shared.urdb_rates_geom_rate_counts;
CREATE TABLE diffusion_shared.urdb_rates_geom_rate_counts as
with a as
(
	select rate_id_alias, geom_gid
	from diffusion_shared.urdb_rates_geoms_res a
	UNION ALL
	select rate_id_alias, geom_gid
	from diffusion_shared.urdb_rates_geoms_com
),
b as
(
	SELECT geom_gid, count(rate_id_alias)
	from a
	group by geom_gid
)
select b.*, c.the_geom_96703
FROM b
left join urdb_rates.ventyx_electric_service_territories_w_vs_rates_20141202 c
ON b.geom_gid = c.gid;