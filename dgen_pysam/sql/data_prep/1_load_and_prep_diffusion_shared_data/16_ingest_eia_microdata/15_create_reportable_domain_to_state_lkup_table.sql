-- I created diffusion_data_shared.eia_reportable_domain_to_state_recs_2009 a long time ago,
-- but it really should live in the eia schema, have a better name, and include state_abbr and state_fips.
-- this script rectifies those issues.
set role 'eia-writers';
DROP TABLE IF EXISTS eia.recs_2009_state_to_reportable_domain_lkup;
CREATE TABLE eia.recs_2009_state_to_reportable_domain_lkup AS
SELECT a.state_name as state, c.state_abbr, lpad(c.state_fips::TEXT, 2, '0') as state_fips, a.reportable_domain
FROM diffusion_data_shared.eia_reportable_domain_to_state_recs_2009 a
LEFT JOIN diffusion_shared.state_abbr_lkup b
ON a.state_name = b.state
left join diffusion_shared.state_fips_lkup c
ON b.state_abbr = c.state_abbr;
-- 51 rows

select *
FROM eia.recs_2009_state_to_reportable_domain_lkup;

-- add primary keys and indices
ALTER TABLE eia.recs_2009_state_to_reportable_domain_lkup
ADD PRIMARY KEY (state_abbr);

CREATE INDEX recs_2009_state_to_reportable_domain_lkup_btree_state_fips
ON eia.recs_2009_state_to_reportable_domain_lkup
USING BTREE(state_fips);

CREATE INDEX recs_2009_state_to_reportable_domain_lkup_btree_state
ON eia.recs_2009_state_to_reportable_domain_lkup
USING BTREE(state);

CREATE INDEX recs_2009_state_to_reportable_domain_lkup_btree_reportable_domain
ON eia.recs_2009_state_to_reportable_domain_lkup
USING BTREE(reportable_domain);
-- all set

vacuum analyze eia.recs_2009_state_to_reportable_domain_lkup;
