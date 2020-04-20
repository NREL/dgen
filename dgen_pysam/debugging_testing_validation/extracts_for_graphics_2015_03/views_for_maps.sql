CREATE VIEW dg_wind.county_rate_and_load AS
SELECT 	a.county_id,
	a.state_fips,
	a.county_fips,
	a.state_abbr,
	a.res_rate_cents_per_kwh as centskwhres,
	a.com_rate_cents_per_kwh centskwhcom,
	a.ind_rate_cents_per_kwh centskwhind,
	a.res_rate_source as ratesrcres,
	a.com_rate_source as ratesrccom,
	a.ind_rate_source as ratesrcind,
	b.the_geom_4326,
	c.total_customers_2011_residential as custres,
	c.total_load_mwh_2011_residential as mwhres,
	c.total_customers_2011_commercial as custcom,
	c.total_load_mwh_2011_commercial as mwhcom,
	c.total_customers_2011_industrial as custind,
	c.total_load_mwh_2011_industrial as mwhind
FROM diffusion_shared.ann_ave_elec_rates_by_county_2012 a
INNER JOIN esri.counties b
ON a.state_fips = b.state_fips::INTEGER
and a.county_fips = b.cnty_fips
INNER JOIN diffusion_shared.load_and_customers_by_county_us c
ON a.county_id = c.county_id
where a.state_abbr not in ('AK','HI');

select *
FROM dg_wind.county_rate_and_load 
where centskwhres > 20;


CREATE VIEW csi.temp_all_geocoded AS
SELECT application_number, address, city, state, the_geom_4326
FROM csi.temp_2014_addresses_previously_geocoded a
UNION  ALL
SELECT application_number, address, city, state, the_geom_4326
FROM csi.temp_2014_addresses_new_correctly_geocoded;

DROP VIEW IF EXISTS dg_wind.pv_starting_cap_mw_by_state;
CREATE VIEW dg_wind.pv_starting_cap_mw_by_state AS
SELECT a.state_abbr, 
	sum(a.capacity_mw_residential+a.capacity_mw_commercial+a.capacity_mw_industrial) as pvcapmw,
	b.the_geom_4326
from diffusion_solar.starting_capacities_mw_2012_q4_us a
LEFT JOIN  esri.dtl_state_20110101 b
ON a.state_abbr = b.state_abbr
group by a.state_abbr, b.the_geom_4326;


DROP VIEW IF EXISTS dg_wind.wind_starting_cap_mw_by_state;
CREATE VIEW dg_wind.wind_starting_cap_mw_by_state AS
SELECT a.state_abbr, 
	sum(a.capacity_mw_residential+a.capacity_mw_commercial+a.capacity_mw_industrial) as pvcapmw,
	b.the_geom_4326
from diffusion_wind.starting_capacities_mw_2014_us a
LEFT JOIN  esri.dtl_state_20110101 b
ON a.state_abbr = b.state_abbr
group by a.state_abbr, b.the_geom_4326;
