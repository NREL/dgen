-- SET ROLE 'server-superusers';
-- SELECT add_schema('seia','seia');

SET ROLE 'seia-writers';
CREATE TABLE seia.cumulative_pv_capacity_by_state_2012_Q4 
(
	state text unique,
	state_abbr character varying(2) unique,
	res_cap_mw	numeric,
	nonres_cap_mw	numeric,
	utility_cap_mw	numeric,
	res_systems_count	numeric,
	nonres_systems_count	numeric,
	utility_systems_count	numeric
);

SET ROLE 'server-superusers';
COPY seia.cumulative_pv_capacity_by_state_2012_Q4  FROM '/srv/home/mgleason/data/dg_solar/cumulative_installed_capacity_and_system_counts_Q4_2012_cleaned.csv' with csv header;
SET ROLE 'seia-writers';

CREATE INDEX cumulative_pv_capacity_by_state_2012_Q4_state_btree 
ON seia.cumulative_pv_capacity_by_state_2012_Q4  using btree(state);

CREATE INDEX cumulative_pv_capacity_by_state_2012_Q4_state_abbr_btree 
ON seia.cumulative_pv_capacity_by_state_2012_Q4  using btree(state_abbr);