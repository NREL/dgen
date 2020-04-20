-- move results over to wind_ds
DROP TABLE IF EXISTS diffusion_shared.load_and_customers_by_county_us CASCADE;
CREATE TABLE diffusion_shared.load_and_customers_by_county_us AS
SELECT a.county_id, 
	b.total_customers_2011_residential::NUmeric, 
	b.total_load_mwh_2011_residential::NUmeric,
	c.total_customers_2011_commercial::NUmeric, 
	c.total_load_mwh_2011_commercial::NUmeric,
	d.total_customers_2011_industrial::NUmeric, 
	d.total_load_mwh_2011_industrial::NUmeric
FROM diffusion_shared.county_geom a
LEFT JOIN dg_wind.res_load_by_county_us b
	ON a.county_id = b.county_id
LEFT JOIN dg_wind.com_load_by_county_us c
	ON a.county_id = c.county_id
LEFT JOIN dg_wind.ind_load_by_county_us d
	ON a.county_id = d.county_id
where a.state_abbr not in ('AK','HI');

ALTER TABLE diffusion_shared.load_and_customers_by_county_us ADD primary key(county_id);

ALTER TABLE diffusion_shared.load_and_customers_by_county_us
OWNER TO "diffusion-writers";

