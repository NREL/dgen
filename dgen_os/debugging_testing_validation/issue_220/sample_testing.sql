DROP TABLE IF EXISTS diffusion_solar.sample_sets_res;
CREATE TABLE diffusion_solar.sample_sets_res AS
         WITH all_bins AS
         (
             SELECT a.county_id, 
                     b.doeid as load_id, 
                     b.nweight as weight, 
                     b.kwh as ann_cons_kwh,
                     generate_series(1,100) as sample_set
             FROM diffusion_solar.counties_to_model a
             LEFT JOIN diffusion_shared.eia_microdata_recs_2009 b
             ON a.census_region = b.census_region
             --WHERE a.county_id in  (289,290)
        ), 
        sampled_bins AS 
        (
            SELECT a.county_id, sample_set,
                    unnest(sample(array_agg(a.load_id ORDER BY a.load_id),
					10,1 * a.county_id * sample_set,
					True,
					array_agg(a.weight ORDER BY a.load_id))) as load_id
            FROM all_bins a
            GROUP BY a.county_id, sample_set
        ), 
        numbered_samples AS
        (
            SELECT a.county_id, a.sample_set, a.load_id,
                   ROW_NUMBER() OVER (PARTITION BY a.county_id,a.sample_set ORDER BY a.county_id, a.sample_set, a.load_id) as bin_id 
            FROM sampled_bins a
        )
        SELECT  a.county_id, a.sample_set, a.bin_id,
                    b.doeid as load_id, 
                     b.nweight as weight, 
                     b.kwh as ann_cons_kwh,
                     c.total_customers_2011_residential as county_total_customers_2011,
                     c.total_load_mwh_2011_residential as county_total_load_mwh_2011,
                     b.kwh * c.total_customers_2011_residential * b.nweight/sum(b.nweight) OVER (PARTITION BY a.county_id, a.sample_set) as load_kwh_in_bin
        FROM numbered_samples a
        LEFT JOIN diffusion_shared.eia_microdata_recs_2009 b
        ON a.load_id = b.doeid
        LEFT JOIN diffusion_shared.load_and_customers_by_county_us c
        ON a.county_id = c.county_id;


with a AS
(
	SELECT county_id, sample_set,
		sum(load_kwh_in_bin)/1000 as sampled_county_load, 
		first(county_total_load_mwh_2011) as actual_county_load
	FROM diffusion_solar.sample_sets_res
	group by county_id, sample_set
),
b as
(
	SELECT *, abs(actual_county_load-sampled_county_load)/actual_county_load as perc_diff
	FROM a
)
SELECT county_id, sum((perc_diff<0.05)::INTEGER)
FROm b
GROUP by county_id
ORDER BY sum asc;