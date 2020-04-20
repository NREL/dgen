-- associate each i, j bin with a transmission zone using area weighted intersect
DROP TABLE IF EXISTS diffusion_wind.ij_tzone_lookup;
CREATE TABLE diffusion_wind.ij_tzone_lookup AS
WITH a AS (
	SELECT a.gid, a.i, a.j,
	b.zone_id, 
	case 	when b.zone_id is NOT null THEN ST_Area(ST_Intersection(a.the_geom_96703, b.the_geom_96703)) 
		else 0
		END as isect_area, 
	a.the_geom_96703
	FROM aws_2014.ij_polygons a
	LEFT JOIN ventyx.transmission_zones_07232013 b
	ON ST_Intersects(a.the_geom_96703, b.the_geom_96703)
	where b.country <> 'Canada' or b.country is null
	)
SELECT DISTINCT ON (a.gid, a.i, a.j) a.gid as tmy_grid_gid, a.i, a.j, a.zone_id as transmission_zone_id, a.the_geom_96703
FROM a
ORDER BY a.gid, a.i, a.j, a.isect_area DESC;

-- check for nulls
select *
FROM diffusion_wind.ij_tzone_lookup
where transmission_zone_id is null;

-- fix the nulls by simply using the nearest neighbor
DROP TABLE IF EXISTS diffusion_wind_data.ij_no_transzone;
CREATE TABLE diffusion_wind_data.ij_no_transzone AS
with candidates as (

SELECT a.tmy_grid_gid, a.the_geom_96703, 
	unnest((select array(SELECT b.zone_id
	 FROM ventyx.transmission_zones_07232013 b
	 ORDER BY a.the_geom_96703 <#> b.the_geom_96703 LIMIT 3))) as zone_id
FROM diffusion_wind.ij_tzone_lookup a
where a.transmission_zone_id is null
 )

SELECT distinct ON (tmy_grid_gid) a.tmy_grid_gid, a.the_geom_96703, a.zone_id as transmission_zone_id
FROM candidates a
lEFT JOIN ventyx.transmission_zones_07232013 b
ON a.zone_id = b.zone_id
ORDER BY tmy_grid_gid, ST_Distance(a.the_geom_96703,b.the_geom_96703) asc;
-- look at in Q: these are all either offshore grid cells or just south of the souther border

-- 
UPDATE diffusion_wind.ij_tzone_lookup a
SET transmission_zone_id = b.transmission_zone_id
FROM diffusion_wind_data.ij_no_transzone b
WHERE a.transmission_zone_id is null
and a.tmy_grid_gid = b.tmy_grid_gid;

-- check for nulls again
select *
FROM diffusion_wind.ij_tzone_lookup
where transmission_zone_id is null;
-- none


