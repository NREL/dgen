SET ROLE 'urdb_rates-writers';
DROP VIEW if exists urdb_rates.combined_singular_verified_rates_lookup;
CREATE OR REPLACE VIEW urdb_rates.combined_singular_verified_rates_lookup AS
SELECT urdb_rate_id, rate_id_alias, utility_name, sub_territory_name,
	demand_min, demand_max, rate_type,
	res_com
from urdb_rates.urdb3_verified_rates_lookup_20141202
UNION all
SELECT urdb_rate_id, rate_id_alias, utility_name, sub_territory_name,
	demand_min, demand_max, 'UNK'::text as rate_type, 
	res_com
from urdb_rates.urdb3_singular_rates_lookup_20141202
where verified = False;