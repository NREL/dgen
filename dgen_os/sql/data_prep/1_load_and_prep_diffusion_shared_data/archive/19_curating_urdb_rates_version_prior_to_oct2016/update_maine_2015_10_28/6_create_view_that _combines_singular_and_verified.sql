-- set role
set role 'urdb_rates-writers';

DROP VIEW if exists urdb_rates.combined_singular_verified_rates_lookup_20151028;
CREATE OR REPLACE VIEW urdb_rates.combined_singular_verified_rates_lookup_20151028 AS
SELECT urdb_rate_id, rate_id_alias, utility_name, sub_territory_name,
	demand_min, demand_max, COALESCE(rate_type, 'UNK'::TEXT) as rate_type,
	res_com, pct_of_state_sector_cust
from urdb_rates.urdb3_verified_rates_lookup_20151028 a
UNION all
SELECT urdb_rate_id, rate_id_alias, utility_name, sub_territory_name,
	demand_min, demand_max, 'UNK'::text as rate_type,
	res_com, NULL::NUMERIC AS pct_of_state_sector_cust
from urdb_rates.urdb3_singular_rates_lookup_20151028 b
where b.verified = False;

