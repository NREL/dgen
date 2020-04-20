-- create lookup tables that give the rates that intersect each point
-- in the res/com/ind point tables

-- intersect curated rates against commercial point grid to get a lookup table
DROP TABLE IF EXISTS diffusion_shared_data.pt_rate_isect_lkup_com;
CREATE TABLE diffusion_shared_data.pt_rate_isect_lkup_com
(
	pt_gid integer,
	state_abbr character varying(2),
	rate_id_alias integer
);

SELECT parsel_2('dav-gis','mgleason','mgleason',
		'diffusion_shared.pt_grid_us_com_new','gid',
		'SELECT a.gid as pt_gid, 
			c.state_abbr,
			b.rate_id_alias
		FROM diffusion_shared.pt_grid_us_com_new a
		INNER JOIN diffusion_shared.urdb_rates_geoms_com b
		ON ST_Intersects(a.the_geom_4326, b.the_geom_4326)
		INNER JOIN diffusion_shared.county_geom c
		ON a.county_id = c.county_id;',
		'diffusion_shared_data.pt_rate_isect_lkup_com', 'a',22);

-- add indices
CREATE INDEX pt_rate_isect_lkup_com_pt_gid_btree
ON diffusion_shared_data.pt_rate_isect_lkup_com
using btree(pt_gid);

CREATE INDEX pt_rate_isect_lkup_com_state_abbr_btree
ON diffusion_shared_data.pt_rate_isect_lkup_com
using btree(state_abbr);

CREATE INDEX pt_rate_isect_lkup_com_rate_id_alias_btree
ON diffusion_shared_data.pt_rate_isect_lkup_com
using btree(rate_id_alias);

VACUUM ANALYZE diffusion_shared_data.pt_rate_isect_lkup_com;

-- intersect against industrial point grid to get a lookup table
DROP TABLE IF EXISTS diffusion_shared_data.pt_rate_isect_lkup_ind;
CREATE TABLE diffusion_shared_data.pt_rate_isect_lkup_ind
(
	pt_gid integer,
	state_abbr character varying(2),
	rate_id_alias integer
);

SELECT parsel_2('dav-gis','mgleason','mgleason',
		'diffusion_shared.pt_grid_us_ind_new','gid',
		'SELECT a.gid as pt_gid, 
			c.state_abbr,
			b.rate_id_alias
		FROM diffusion_shared.pt_grid_us_ind_new a
		INNER JOIN diffusion_shared.urdb_rates_geoms_com b
		ON ST_Intersects(a.the_geom_4326, b.the_geom_4326)
		INNER JOIN diffusion_shared.county_geom c
		ON a.county_id = c.county_id;',
		'diffusion_shared_data.pt_rate_isect_lkup_ind', 'a', 22);

-- create indices
CREATE INDEX pt_rate_isect_lkup_ind_pt_gid_btree
ON diffusion_shared_data.pt_rate_isect_lkup_ind
using btree(pt_gid);

CREATE INDEX pt_rate_isect_lkup_ind_state_abbr_btree
ON diffusion_shared_data.pt_rate_isect_lkup_ind
using btree(state_abbr);

CREATE INDEX pt_rate_isect_lkup_ind_rate_id_alias_btree
ON diffusion_shared_data.pt_rate_isect_lkup_ind
using btree(rate_id_alias);

VACUUM ANALYZE diffusion_shared_data.pt_rate_isect_lkup_ind;

--------------------------------------------------------------------------------
-- intersect against residential point grid to get a lookup table
DROP TABLE IF EXISTS diffusion_shared_data.pt_rate_isect_lkup_res;
CREATE TABLE diffusion_shared_data.pt_rate_isect_lkup_res
(
	pt_gid integer,
	state_abbr character varying(2),
	rate_id_alias integer
);

SELECT parsel_2('dav-gis','mgleason','mgleason',
		'diffusion_shared.pt_grid_us_res_new','gid',
		'SELECT a.gid as pt_gid, 
			c.state_abbr,
			b.rate_id_alias
		FROM diffusion_shared.pt_grid_us_res_new a
		INNER JOIN diffusion_shared.urdb_rates_geoms_res b
		ON ST_Intersects(a.the_geom_4326, b.the_geom_4326)
		INNER JOIN diffusion_shared.county_geom c
		ON a.county_id = c.county_id;',
		'diffusion_shared_data.pt_rate_isect_lkup_res', 'a',22);

-- add indices
CREATE INDEX pt_rate_isect_lkup_res_pt_gid_btree
ON diffusion_shared_data.pt_rate_isect_lkup_res
using btree(pt_gid);

CREATE INDEX pt_rate_isect_lkup_res_state_abbr_btree
ON diffusion_shared_data.pt_rate_isect_lkup_res
using btree(state_abbr);

CREATE INDEX pt_rate_isect_lkup_res_rate_id_alias_btree
ON diffusion_shared_data.pt_rate_isect_lkup_res
using btree(rate_id_alias);

VACUUM ANALYZE diffusion_shared_data.pt_rate_isect_lkup_res;