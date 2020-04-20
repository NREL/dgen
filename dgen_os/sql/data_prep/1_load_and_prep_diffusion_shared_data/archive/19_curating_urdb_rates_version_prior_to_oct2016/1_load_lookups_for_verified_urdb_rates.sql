set role 'server-superusers';
SELECT add_schema('urdb_rates','urdb_rates');
ALTER GROUP "urdb_rates-writers" ADD user dhetting;

set role 'urdb_rates-writers';
DROP tABLE IF EXIStS urdb_rates.urdb3_verified_rates_lookup_20141202;
CREATE TABLE urdb_rates.urdb3_verified_rates_lookup_20141202
(
	eia_ann_avg_rate numeric,
	utility_name text,
	utility_id integer,
	state_code text,
	rate_name text,
	min_app numeric,
	max_app numeric,
	res_com character varying(1),
	urdb_rate_id text,
	rate_type character varying(4)
);

SET ROLE 'server-superusers';
COPY urdb_rates.urdb3_verified_rates_lookup_20141202 FROM '/srv/home/mgleason/data/urdb/Rate_Data_v903_Urdb3_com.csv' with csv header;
COPY urdb_rates.urdb3_verified_rates_lookup_20141202 FROM '/srv/home/mgleason/data/urdb/Rate_Data_v903_Urdb3_res.csv' with csv header;
SET ROLE 'urdb_rates-writers';


select count(*)
FROM urdb_rates.urdb3_verified_rates_lookup_20141202;
-- around 1152 rates total

