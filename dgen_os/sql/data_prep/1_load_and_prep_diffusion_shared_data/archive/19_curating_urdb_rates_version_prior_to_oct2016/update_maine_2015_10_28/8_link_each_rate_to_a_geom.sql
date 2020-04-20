-- create simple tables with each rate_id_alias linked to the appropriate ventyx geom(s)
-- note: may be one-to-main because ventyx geoms are exploded for each company id
set role 'diffusion-writers';

-- COMMERCIAL
-- create a simple table with each rate_id_alias linked to a ventyx geom
DROP TABLE IF EXISTS diffusion_data_shared.urdb_rates_geoms_com;
CREATE TABLE diffusion_data_shared.urdb_rates_geoms_com AS
with a as
(
	-- collect all of the commercial rates
	SELECT rate_id_alias, utility_name as ur_name, sub_territory_name,
	       demand_min, demand_max, rate_type
	FROM urdb_rates.combined_singular_verified_rates_lookup_20151028
	where res_com = 'C'
),
b as 
(
	SELECT a.*, b.ventyx_company_id_2014
	FROM a
	LEFT JOIN urdb_rates.urdb3_verified_and_singular_ur_names_20151028 b
	ON a.ur_name = b.ur_name
)
select b.*, c.the_geom_4326, c.gid as geom_gid, c.company_type_general as utility_type
from b
left join urdb_rates.ventyx_electric_service_territories_w_vs_rates_20141202 c
ON b.ventyx_company_id_2014 = c.company_id::text
and b.sub_territory_name = c.sub_territory_name;

-- make sure there are no nulls
select count(*)
FROM diffusion_data_shared.urdb_rates_geoms_com
where the_geom_4326 is null;

-- create primary key on the rate_id_alias
ALTER TABLE diffusion_data_shared.urdb_rates_geoms_com
ADD PRIMARY KEY (rate_id_alias, geom_gid);

-- create index on the geometry
CREATE INDEX urdb_rates_geoms_com_the_geom_4326_gist
ON  diffusion_data_shared.urdb_rates_geoms_com
using gist(the_geom_4326);

-- add 900914 geom
ALTER TABLE diffusion_data_shared.urdb_rates_geoms_com
ADD column the_geom_900914 geometry;

UPDATE diffusion_data_shared.urdb_rates_geoms_com
SET the_geom_900914 = ST_Transform(the_geom_4326, 900914);

CREATE INDEX urdb_rates_geoms_com_the_geom_900914_gist
ON  diffusion_data_shared.urdb_rates_geoms_com
using gist(the_geom_900914);

-- add 96703 geom
ALTER TABLE diffusion_data_shared.urdb_rates_geoms_com
ADD column the_geom_96703 geometry;

UPDATE diffusion_data_shared.urdb_rates_geoms_com
SET the_geom_96703 = ST_Transform(the_geom_4326, 96703);

CREATE INDEX urdb_rates_geoms_com_the_geom_96703_gist
ON  diffusion_data_shared.urdb_rates_geoms_com
using gist(the_geom_96703);

VACUUM ANALYZE diffusion_data_shared.urdb_rates_geoms_com;
----------------------------------------------------------------------------------------

-- INDUSTRIAL
-- (will only apply to maine for now -- until other industrial data is added
DROP TABLE IF EXISTS diffusion_data_shared.urdb_rates_geoms_ind;
CREATE TABLE diffusion_data_shared.urdb_rates_geoms_ind AS
with a as
(
	-- collect all of the commercial rates
	SELECT rate_id_alias, utility_name as ur_name, sub_territory_name,
	       demand_min, demand_max, rate_type
	FROM urdb_rates.combined_singular_verified_rates_lookup_20151028
	where res_com = 'I'
),
b as 
(
	SELECT a.*, b.ventyx_company_id_2014
	FROM a
	LEFT JOIN urdb_rates.urdb3_verified_and_singular_ur_names_20151028 b
	ON a.ur_name = b.ur_name
)
select b.*, c.the_geom_4326, c.gid as geom_gid, c.company_type_general as utility_type
from b
left join urdb_rates.ventyx_electric_service_territories_w_vs_rates_20141202 c
ON b.ventyx_company_id_2014 = c.company_id::text
and b.sub_territory_name = c.sub_territory_name;

-- make sure there are no nulls
select count(*)
FROM diffusion_data_shared.urdb_rates_geoms_ind
where the_geom_4326 is null;

-- create primary key on the rate_id_alias
ALTER TABLE diffusion_data_shared.urdb_rates_geoms_ind
ADD PRIMARY KEY (rate_id_alias, geom_gid);

-- create index on the geometry
CREATE INDEX urdb_rates_geoms_ind_the_geom_4326_gist
ON  diffusion_data_shared.urdb_rates_geoms_ind
using gist(the_geom_4326);

-- add 900914 geom
ALTER TABLE diffusion_data_shared.urdb_rates_geoms_ind
ADD column the_geom_900914 geometry;

UPDATE diffusion_data_shared.urdb_rates_geoms_ind
SET the_geom_900914 = ST_Transform(the_geom_4326, 900914);

CREATE INDEX urdb_rates_geoms_ind_the_geom_900914_gist
ON  diffusion_data_shared.urdb_rates_geoms_ind
using gist(the_geom_900914);

-- add 96703 geom
ALTER TABLE diffusion_data_shared.urdb_rates_geoms_ind
ADD column the_geom_96703 geometry;

UPDATE diffusion_data_shared.urdb_rates_geoms_ind
SET the_geom_96703 = ST_Transform(the_geom_4326, 96703);

CREATE INDEX urdb_rates_geoms_ind_the_geom_96703_gist
ON  diffusion_data_shared.urdb_rates_geoms_ind
using gist(the_geom_96703);

VACUUM ANALYZE diffusion_data_shared.urdb_rates_geoms_ind;

----------------------------------------------------------------------------------------
-- RESIDENTIAL
-- create a simple table with each rate_id_alias linked to a ventyx geom
DROP TABLE IF EXISTS diffusion_data_shared.urdb_rates_geoms_res;
CREATE TABLE diffusion_data_shared.urdb_rates_geoms_res AS
with a as
(
	-- collect all of the residential rates
	-- collect all of the commercial rates
	SELECT rate_id_alias, utility_name as ur_name, sub_territory_name,
	       demand_min, demand_max, rate_type
	FROM urdb_rates.combined_singular_verified_rates_lookup_20151028
	where res_com = 'R'

),
b as 
(
	SELECT a.*, b.ventyx_company_id_2014
	FROM a
	LEFT JOIN urdb_rates.urdb3_verified_and_singular_ur_names_20151028 b
	ON a.ur_name = b.ur_name
)
select b.*, c.the_geom_4326, c.gid as geom_gid, c.company_type_general as utility_type
from b
left join urdb_rates.ventyx_electric_service_territories_w_vs_rates_20141202 c
ON b.ventyx_company_id_2014 = c.company_id::text
and b.sub_territory_name = c.sub_territory_name;

-- make sure there are no nulls
select count(*)
FROM diffusion_data_shared.urdb_rates_geoms_res
where the_geom_4326 is null;

-- create primary key on the rate_id_alias
ALTER TABLE diffusion_data_shared.urdb_rates_geoms_res
ADD PRIMARY KEY (rate_id_alias, geom_gid);

-- create index on the geometry
CREATE INDEX urdb_rates_geoms_res_the_geom_4326_gist
ON  diffusion_data_shared.urdb_rates_geoms_res
using gist(the_geom_4326);

-- add 900914 geom
ALTER TABLE diffusion_data_shared.urdb_rates_geoms_res
ADD column the_geom_900914 geometry;

UPDATE diffusion_data_shared.urdb_rates_geoms_res
SET the_geom_900914 = ST_Transform(the_geom_4326, 900914);

CREATE INDEX urdb_rates_geoms_res_the_geom_900914_gist
ON  diffusion_data_shared.urdb_rates_geoms_res
using gist(the_geom_900914);

-- add 96703 geom
ALTER TABLE diffusion_data_shared.urdb_rates_geoms_res
ADD column the_geom_96703 geometry;

UPDATE diffusion_data_shared.urdb_rates_geoms_res
SET the_geom_96703 = ST_Transform(the_geom_4326, 96703);

CREATE INDEX urdb_rates_geoms_res_the_geom_96703_gist
ON  diffusion_data_shared.urdb_rates_geoms_res
using gist(the_geom_96703);

VACUUM ANALYZE diffusion_data_shared.urdb_rates_geoms_res;