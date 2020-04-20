CREATE OR REPLACE VIEW wind_ds_data.wind_resource_grid AS
SELECT a.i, a.j, a.cf_bin, a.height, a.turbine_id, a.aep, a.excess_gen_factor, b.st, b.the_geom_96703, b.the_geom_centroid_96703
FROM wind_ds.wind_resource_annual a
INNER JOIN aws.tmy_grid b
ON a.i = b.i
and a.j = b.j;
