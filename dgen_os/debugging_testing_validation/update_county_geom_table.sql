ALTER TABLE diffusion_shared.pt_grid_us_com DROP CONSTRAINT county_id_fkey;

ALTER TABLE diffusion_solar.starting_capacities_mw_2014_us DROP CONSTRAINT county_id;
ALTER TABLE diffusion_wind.starting_capacities_mw_2014_us DROP CONSTRAINT county_id;

DELETE FROM diffusion_shared.county_geom;

ALTER TABLE diffusion_shared.county_geom
ADD COLUMN climate_zone_building_america integer,
ADD COLUMN climate_zone_cbecs_2003 integer;

INSERT INTO diffusion_shared.county_geom
SELECT *
FROM diffusion_shared.county_geom_temp;

DROP TABLE IF EXISTS diffusion_shared.county_geom_temp;

ALTER TABLE diffusion_shared.pt_grid_us_res
  ADD CONSTRAINT pt_grid_us_res_pkey PRIMARY KEY(gid);

