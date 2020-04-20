With total_county_capacities AS (
SELECT county_id, sum(nameplate_capacity_kw*0.001*customers_in_bin) as total_county_capacity_mw
FROM wind_ds.pt_res_best_option_each_year
GROUP BY county_id)
SELECT a.county_id, b.capacity_mw_Residential as initial_county_capacity, a.total_county_capacity_mw, b.capacity_mw_Residential/a.total_county_capacity_mw as initial_market_share, b.capacity_mw_residential/a.total_county_capacity_mw/10 as initial_market_share_per_bin
FROM total_county_capacities a
LEFT JOIN wind_ds.starting_wind_capacities_mw_2014_us b
ON a.county_id = b.county_id;
