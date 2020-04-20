select *
from diffusion_solar.utilityrate3_results
order by 2, 3, 1

CREATe SCHEMA wes;
CREATE TABLE wes.utilityrate3_results 
(LIKE diffusion_solar.utilityrate3_results);

COPY wes.utilityrate3_results from '/home/mgleason/utilityrate3_results_wes.csv' with csv header;

select count(*)
FROM  wes.utilityrate3_results;

select count(*)
FROM diffusion_solar.utilityrate3_results

select *
FROM diffusion_solar.utilityrate3_results a
left join wes.utilityrate3_results b
ON a.uid = b.uid
where a.elec_cost_with_system_year1 <> b.elec_cost_with_system_year1
order by a.uid

CREATE TABLE wes.unique_rate_gen_load_combinations 
(LIKE diffusion_solar.unique_rate_gen_load_combinations);

COPY wes.unique_rate_gen_load_combinations from '/home/mgleason/unique_rate_gen_load_combinations_wes.csv' with csv header;

with c as
(
	select a.uid
	FROM diffusion_solar.utilityrate3_results a
	left join wes.utilityrate3_results b
	ON a.uid = b.uid
	where a.elec_cost_with_system_year1 <> b.elec_cost_with_system_year1
	order by a.uid
)
select *
from diffusion_solar.unique_rate_gen_load_combinations a
inner join wes.unique_rate_gen_load_combinations b
ON a.rate_id_alias = b.rate_id_alias AND
a.rate_source = b.rate_source AND
a.hdf_load_index = b.hdf_load_index AND
a.crb_model = b.crb_model AND
a.load_kwh_per_customer_in_bin = b.load_kwh_per_customer_in_bin AND
a.solar_re_9809_gid = b.solar_re_9809_gid AND
a.tilt = b.tilt AND
a.azimuth = b.azimuth AND
a.system_size_kw = b.system_size_kw AND
a.ur_enable_net_metering = b.ur_enable_net_metering AND
a.ur_nm_yearend_sell_rate = b.ur_nm_yearend_sell_rate AND
a.ur_flat_sell_rate = b.ur_flat_sell_rate
where a.uid <> b.uid;

-- ok, so uids don't always match, but the data do

with a as
(
	SELECT c.uid, a.county_id, a.bin_id, a.year, a.load_kwh_per_customer_in_bin, a.system_size_kw,
		c.elec_cost_with_system_year1 as first_year_bill_with_system, 
		c.elec_cost_without_system_year1 as first_year_bill_without_system
	FROM diffusion_solar.pt_com_best_option_each_year a
	LEFT JOIN diffusion_solar.unique_rate_gen_load_combinations b
		ON a.rate_id_alias = b.rate_id_alias
		AND a.rate_source = b.rate_source
		AND a.hdf_load_index = b.hdf_load_index
		AND a.crb_model = b.crb_model
		AND a.load_kwh_per_customer_in_bin = b.load_kwh_per_customer_in_bin
		AND a.system_size_kw = b.system_size_kw
		AND a.solar_re_9809_gid = b.solar_re_9809_gid
		and a.tilt = b.tilt
		and a.azimuth = b.azimuth
		AND a.ur_enable_net_metering = b.ur_enable_net_metering
		AND a.ur_nm_yearend_sell_rate = b.ur_nm_yearend_sell_rate
		AND a.ur_flat_sell_rate = b.ur_flat_sell_rate
	LEFT JOIN diffusion_solar.utilityrate3_results c
		ON b.uid = c.uid
),
b as
(
	SELECT c.uid, a.county_id, a.bin_id, a.year, a.load_kwh_per_customer_in_bin, a.system_size_kw,
		c.elec_cost_with_system_year1 as first_year_bill_with_system, 
		c.elec_cost_without_system_year1 as first_year_bill_without_system
	FROM diffusion_solar.pt_com_best_option_each_year a
	LEFT JOIN wes.unique_rate_gen_load_combinations b
		ON a.rate_id_alias = b.rate_id_alias
		AND a.rate_source = b.rate_source
		AND a.hdf_load_index = b.hdf_load_index
		AND a.crb_model = b.crb_model
		AND a.load_kwh_per_customer_in_bin = b.load_kwh_per_customer_in_bin
		AND a.system_size_kw = b.system_size_kw
		AND a.solar_re_9809_gid = b.solar_re_9809_gid
		and a.tilt = b.tilt
		and a.azimuth = b.azimuth
		AND a.ur_enable_net_metering = b.ur_enable_net_metering
		AND a.ur_nm_yearend_sell_rate = b.ur_nm_yearend_sell_rate
		AND a.ur_flat_sell_rate = b.ur_flat_sell_rate
	LEFT JOIN wes.utilityrate3_results c
		ON b.uid = c.uid
)
select *
FROM a
LEFT JOIN b
on a.county_id = b.county_id
and a.bin_id = b.bin_id
and a.year = b.year
where a.first_year_bill_without_system <> b.first_year_bill_without_system;

-- ok, so all matches here...wtf

CREATE TABLE wes.pt_res_elec_costs (LIKE diffusion_solar.pt_res_elec_costs);
COPY wes.pt_res_elec_costs from '/home/mgleason/pt_res_elec_costs_wes.csv' with csv header;

-- compare to native table
select *
from diffusion_solar.pt_res_elec_costs a
left join wes.pt_res_elec_costs b
on a.county_id = b.county_id
and a.bin_id = b.bin_id
and a.year = b.year
where a.first_year_bill_without_system <> b.first_year_bill_without_system;
-- everything matches --- this makes me think it is something that happens after the data is read into python


DROP TABLE IF EXISTS wes.pt_com_elec_costs;
CREATE TABLE wes.pt_com_elec_costs (LIKE diffusion_solar.pt_com_elec_costs);
COPY wes.pt_com_elec_costs from '/home/mgleason/pt_com_elec_costs_wes.csv' with csv header;

-- compare to native table
select *
from diffusion_solar.pt_com_elec_costs a
left join wes.pt_com_elec_costs b
on a.county_id = b.county_id
and a.bin_id = b.bin_id
and a.year = b.year
where a.first_year_bill_without_system <> b.first_year_bill_without_system
or a.first_year_bill_with_system <> b.first_year_bill_with_system;
-- everything matches --- this makes me think it is something that happens after the data is read into python


WITH eplus as 
(
	SELECT hdf_index, crb_model, nkwh
	FROM diffusion_shared.energy_plus_normalized_load_res
	WHERE crb_model = 'reference'
	UNION ALL
	SELECT hdf_index, crb_model, nkwh
	FROM diffusion_shared.energy_plus_normalized_load_com
), 
a as
(
	select rate_id_alias, rate_source,
				hdf_load_index, crb_model, load_kwh_per_customer_in_bin,
				solar_re_9809_gid, tilt, azimuth, system_size_kw, 
				ur_enable_net_metering, ur_nm_yearend_sell_rate, ur_flat_sell_rate
	from diffusion_solar.pt_com_best_option_each_year --- CHANGE THIS TO wes.
	where county_id = 330 and bin_id = 7
)
SELECT 1 as uid, 
	b.sam_json as rate_json, 
	a.load_kwh_per_customer_in_bin, c.nkwh as consumption_hourly,
	a.system_size_kw, d.cf as generation_hourly,
	a.ur_enable_net_metering, a.ur_nm_yearend_sell_rate, a.ur_flat_sell_rate
from a
LEFT JOIN diffusion_solar.all_rate_jsons b 
    ON a.rate_id_alias = b.rate_id_alias
    AND a.rate_source = b.rate_source

-- JOIN THE LOAD DATA
LEFT JOIN eplus c
	ON a.crb_model = c.crb_model
	AND a.hdf_load_index = c.hdf_index

-- JOIN THE RESOURCE DATA
LEFT JOIN diffusion_solar.solar_resource_hourly d
	ON a.solar_re_9809_gid = d.solar_re_9809_gid
	AND a.tilt = d.tilt
	AND a.azimuth = d.azimuth





SELECT *
FROM diffusion_solar.unique_rate_gen_load_combinations a
INNER JOIN b
ON a.rate_id_alias = b.rate_id_alias AND
	a.rate_source = b.rate_source AND
	a.hdf_load_index = b.hdf_load_index AND
	a.crb_model = b.crb_model AND
	a.load_kwh_per_customer_in_bin = b.load_kwh_per_customer_in_bin AND
	a.solar_re_9809_gid = b.solar_re_9809_gid AND
	a.tilt = b.tilt AND
	a.azimuth = b.azimuth AND
	a.system_size_kw = b.system_size_kw AND
	a.ur_enable_net_metering = b.ur_enable_net_metering AND
	a.ur_nm_yearend_sell_rate = b.ur_nm_yearend_sell_rate AND
	a.ur_flat_sell_rate = b.ur_flat_sell_rate 









 sql = """SELECT a.*, b.first_year_bill_with_system, b.first_year_bill_without_system
            FROM %(schema)s.pt_%(sector_abbr)s_best_option_each_year a
            LEFT JOIN %(schema)s.pt_%(sector_abbr)s_elec_costs b
                    ON a.county_id = b.county_id
                    AND a.bin_id = b.bin_id
                    AND a.year = b.year
            WHERE a.year = %(year)s"""


-- change folder back to drwxr-xr-x (0755)

-- differences:
-- 
-- - business model (140) -- but all bills match for these
-- - bills w and wo system (725) -- business model generally matches

CREATE TABLE wes.pt_com_best_option_each_year (LIKE diffusion_solar.pt_com_best_option_each_year);
COPY wes.pt_com_best_option_each_year FROM '/home/mgleason/pt_com_best_option_each_year_wes.csv' with csv header;

select a.*, b.*
FROM diffusion_solar.pt_com_best_option_each_year a
left join wes.pt_com_best_option_each_year b
ON a.county_id = b.county_id
and a.bin_id = b.bin_id
and a.year = b.year
where a.reeds_reg <> b.reeds_reg OR
a.rate_escalation_factor <> b.rate_escalation_factor OR
a.incentive_array_id <> b.incentive_array_id OR
a.ranked_rate_array_id <> b.ranked_rate_array_id OR
a.carbon_price_cents_per_kwh <> b.carbon_price_cents_per_kwh OR
a.fixed_om_dollars_per_kw_per_yr <> b.fixed_om_dollars_per_kw_per_yr OR
a.variable_om_dollars_per_kwh <> b.variable_om_dollars_per_kwh OR
a.installed_costs_dollars_per_kw <> b.installed_costs_dollars_per_kw OR
a.inverter_cost_dollars_per_kw <> b.inverter_cost_dollars_per_kw OR
a.ann_cons_kwh <> b.ann_cons_kwh OR
--a.customers_in_bin <> b.customers_in_bin OR
--a.initial_customers_in_bin <> b.initial_customers_in_bin OR
--a.load_kwh_in_bin <> b.load_kwh_in_bin OR
--a.initial_load_kwh_in_bin <> b.initial_load_kwh_in_bin OR
a.load_kwh_per_customer_in_bin <> b.load_kwh_per_customer_in_bin OR
a.crb_model <> b.crb_model OR
a.max_demand_kw <> b.max_demand_kw OR
a.rate_id_alias <> b.rate_id_alias OR
a.rate_source <> b.rate_source OR
a.naep <> b.naep OR
a.aep <> b.aep OR
a.system_size_kw <> b.system_size_kw OR
a.npanels <> b.npanels OR
a.ur_enable_net_metering <> b.ur_enable_net_metering OR
a.nem_system_size_limit_kw <> b.nem_system_size_limit_kw OR
a.ur_nm_yearend_sell_rate <> b.ur_nm_yearend_sell_rate OR
a.ur_flat_sell_rate <> b.ur_flat_sell_rate OR
a.tilt <> b.tilt OR
a.azimuth <> b.azimuth OR
a.derate <> b.derate OR
a.pct_shaded <> b.pct_shaded OR
a.solar_re_9809_gid <> b.solar_re_9809_gid OR
a.density_w_per_sqft <> b.density_w_per_sqft OR
a.inverter_lifetime_yrs <> b.inverter_lifetime_yrs OR
a.roof_sqft <> b.roof_sqft OR
a.roof_style <> b.roof_style OR
a.roof_planes <> b.roof_planes OR
a.rooftop_portion <> b.rooftop_portion OR
a.slope_area_multiplier <> b.slope_area_multiplier OR
a.unshaded_multiplier <> b.unshaded_multiplier OR
a.available_roof_sqft <> b.available_roof_sqft OR
a.owner_occupancy_status <> b.owner_occupancy_status ;






select a.county_id, a.bin_id, a.year, a.micro_id,
	b.county_id, b.bin_id, b.year, b.micro_id,
a.customers_in_bin, b.customers_in_bin,
a.initial_customers_in_bin, b.initial_customers_in_bin,
a.load_kwh_in_bin, b.load_kwh_in_bin,
a.initial_load_kwh_in_bin, b.initial_load_kwh_in_bin 

FROM diffusion_solar.pt_com_best_option_each_year a
left join wes.pt_com_best_option_each_year b
ON a.county_id = b.county_id
and a.bin_id = b.bin_id
and a.year = b.year
where 
	round(a.customers_in_bin::NUMERIC, 6) <> round(b.customers_in_bin::NUMERIC, 6) OR
round(a.initial_customers_in_bin::NUMERIC, 6) <> round(b.initial_customers_in_bin::NUMERIC, 6) OR
round(a.load_kwh_in_bin::NUMERIC, 6) <> round(b.load_kwh_in_bin::NUMERIC, 6) OR
round(a.initial_load_kwh_in_bin::NUMERIC, 6) <> round(b.initial_load_kwh_in_bin::NUMERIC, 6)
