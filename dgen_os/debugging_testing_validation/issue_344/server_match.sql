DROP TABLE IF EXISTS mgleason.pt_res_best_option_each_year;
ALTER TABLE diffusion_solar.pt_res_best_option_each_year
set schema mgleason; 

-- pg_dump -h dnpdb001.bigde.nrel.gov -p 5433 -t diffusion_solar.pt_res_best_option_each_year -O -U mgleason diffusion_3 | psql -h gispgdb.nrel.gov dav-gis -U mgleason


select 
a.customers_in_bin, b.customers_in_bin,
a.load_kwh_in_bin, b.load_kwh_in_bin,
a.load_kwh_per_customer_in_bin, b.load_kwh_per_customer_in_bin,
a.load_kwh_in_bin/a.customers_in_bin, b.load_kwh_in_bin/b.customers_in_bin
FROM diffusion_solar.pt_res_best_option_each_year a
INNER join mgleason.pt_res_best_option_each_year b
ON a.county_id = b.county_id
and a.bin_id = b.bin_id
where a.customers_in_bin <> b.customers_in_bin


select sum(a.customers_in_bin)/sum(b.customers_in_bin)
FROM diffusion_solar.pt_res_best_option_each_year a
INNER join mgleason.pt_res_best_option_each_year b
ON a.county_id = b.county_id
and a.bin_id = b.bin_id
where a.customers_in_bin <> b.customers_in_bin
group by a.county_id



DROP TABLE IF EXISTS mgleason.load_and_customers_by_county_us;
-- pg_dump -h dnpdb001.bigde.nrel.gov -p 5433 -t diffusion_shared.load_and_customers_by_county_us -O -U mgleason diffusion_3 | sed -e '/^SET search_path = /s/diffusion_shared/mgleason/g' | psql -h gispgdb.nrel.gov dav-gis -U mgleason

select a.county_id,
a.total_customers_2011_residential, b.total_customers_2011_residential,
a.total_load_mwh_2011_residential, b.total_load_mwh_2011_residential,
a.total_customers_2011_commercial, b.total_customers_2011_commercial,
a.total_load_mwh_2011_commercial, b.total_load_mwh_2011_commercial,
a.total_customers_2011_industrial, b.total_customers_2011_industrial,
a.total_load_mwh_2011_industrial, b.total_load_mwh_2011_industrial
FROM diffusion_shared.load_and_customers_by_county_us a
inner join mgleason.load_and_customers_by_county_us b
on a.county_id = b.county_id
where a.total_load_mwh_2011_residential <> b.total_load_mwh_2011_residential;


DROP TABLE IF EXISTS mgleason.county_housing_units;
-- pg_dump -h dnpdb001.bigde.nrel.gov -p 5433 -t diffusion_shared.county_housing_units -O -U mgleason diffusion_3 | sed -e '/^SET search_path = /s/diffusion_shared/mgleason/g' | psql -h gispgdb.nrel.gov dav-gis -U mgleason
select *
FROM diffusion_shared.county_housing_units a
inner join mgleason.county_housing_units b
on a.county_id = b.county_id
and a.perc_own_occu_1str_housing < b.perc_own_occu_1str_housing








DROP TABLE IF EXISTS mgleason.pt_res_sample_load_1;
ALTER TABLE diffusion_solar.pt_res_sample_load_1
set schema mgleason; 

-- pg_dump -h dnpdb001.bigde.nrel.gov -p 5433 -t diffusion_solar.pt_res_sample_load_1 -O -U mgleason diffusion_3 | psql -h gispgdb.nrel.gov dav-gis -U mgleason


select a.county_id, a.bin_id, a.micro_id, b.micro_id, 
	a.county_total_customers_2011, b.county_total_customers_2011,
	a.county_total_load_mwh_2011, b.county_total_load_mwh_2011,
	a.ann_cons_kwh, b.ann_cons_kwh,
	a.weight, b.weight
from diffusion_solar.pt_res_sample_load_1 a
inner join mgleason.pt_res_sample_load_1 b
ON a.county_id = b.county_id
and a.bin_id = b.bin_id