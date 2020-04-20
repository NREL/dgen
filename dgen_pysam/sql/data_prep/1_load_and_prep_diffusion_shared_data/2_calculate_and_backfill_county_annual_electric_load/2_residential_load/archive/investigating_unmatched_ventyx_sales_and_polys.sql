CREATE TABLE dg_wind.ventyx_polys_no_ventyx_sales AS
SELECT a.*,

b.bundled_energy_only_delivery_only_residential_revenue_000s as total_residential_revenue_000s,
b.bundled_delivery_only_residential_sales_mwh as total_residential_sales_mwh,
b.bundled_delivery_only_residential_customers as total_residential_customers,

b.bundled_energy_only_delivery_only_commercial_revenue_000s as total_commercial_revenue_000s,
b.bundled_delivery_only_commercial_sales_mwh as total_commercial_sales_mwh,
b.bundled_delivery_only_commercial_customers as total_commercial_customers,

b.bundled_energy_only_delivery_only_industrial_revenue_000s as total_industrial_revenue_000s,
b.bundled_delivery_only_industrial_sales_mwh  as total_industrial_sales_mwh,
b.bundled_delivery_only_industrial_customers as total_industrial_customers,

b.year as data_year

FROM dg_wind.electric_services_territories_ventyx_states_edit a
LEFT join ventyx.electric_utility_rates_2011 b
ON a.state_abbr = b.customer_state
and a.company_id = b.company_id
where b.company_id is null; -- 733 rows


DROP TABLE IF EXISTS  dg_wind.ventyx_sales_no_ventyx_polys;
CREATE TABLE dg_wind.ventyx_sales_no_ventyx_polys AS
SELECT b.*

FROM ventyx.electric_utility_rates_2011 b
LEFT join  dg_wind.electric_services_territories_ventyx_states_edit a
ON b.customer_state = a.state_abbr
and b.company_id = a.company_id
where a.company_id is null; -- 574 rows failed to match