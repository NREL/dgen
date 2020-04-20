-- set role
SET ROLE 'urdb_rates-writers';

-- check the rate data
select *
FROM urdb_rates.urdb3_verified_rates_sam_data_20151028 a
INNER JOIN urdb_rates.urdb3_verified_rates_lookup_20151028 b
ON a.rate_id_alias = b.rate_id_alias
where b.state_code = 'ME';
-- looks good

