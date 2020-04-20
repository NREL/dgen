-- Table: diffusion_wind.incentives

-- DROP TABLE diffusion_wind.incentives;

CREATE TABLE diffusion_wind.incentives
(
  uid integer NOT NULL,
  incentive_id integer,
  increment_1_capacity_kw numeric,
  increment_2_capacity_kw numeric,
  increment_3_capacity_kw numeric,
  increment_4_capacity_kw numeric,
  pbi_fit_duration_years numeric,
  pbi_fit_end_date date,
  pbi_fit_min_output_kwh_yr numeric,
  pbi_fit_max_size_for_dlrs_calc_kw numeric,
  ptc_duration_years numeric,
  ptc_end_date date,
  rating_basis_ac_dc text,
  fit_dlrs_kwh numeric,
  pbi_dlrs_kwh numeric,
  pbi_fit_dlrs_kwh numeric,
  increment_1_rebate_dlrs_kw numeric,
  increment_2_rebate_dlrs_kw numeric,
  increment_3_rebate_dlrs_kw numeric,
  increment_4_rebate_dlrs_kw numeric,
  max_dlrs_yr numeric,
  max_tax_credit_dlrs numeric,
  tax_credit_dlrs_kw numeric,
  max_tax_deduction_dlrs numeric,
  pbi_fit_max_dlrs numeric,
  pbi_fit_pcnt_cost_max numeric,
  pbi_fit_max_size_kw numeric,
  pbi_fit_min_size_kw numeric,
  ptc_dlrs_kwh numeric,
  rebate_dlrs_kw numeric,
  rebate_max_dlrs numeric,
  rebate_max_size_kw numeric,
  rebate_min_size_kw numeric,
  rebate_pcnt_cost_max numeric,
  tax_credit_pcnt_cost numeric,
  tax_deduction_pcnt_cost numeric,
  tax_credit_max_size_kw numeric,
  tax_credit_min_size_kw numeric,
  sector_abbr character varying(3) NOT NULL,
  CONSTRAINT incentives_pkey PRIMARY KEY (uid, sector_abbr)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE diffusion_wind.incentives
  OWNER TO "diffusion-writers";

-- Index: diffusion_wind.incentives_sector_abbr_btree

-- DROP INDEX diffusion_wind.incentives_sector_abbr_btree;

CREATE INDEX incentives_sector_abbr_btree
  ON diffusion_wind.incentives
  USING btree
  (sector_abbr COLLATE pg_catalog."default");

-- Index: diffusion_wind.incentives_uid_btree

-- DROP INDEX diffusion_wind.incentives_uid_btree;

CREATE INDEX incentives_uid_btree
  ON diffusion_wind.incentives
  USING btree
  (uid);


-- Trigger: sync_last_mod on diffusion_wind.incentives

-- DROP TRIGGER sync_last_mod ON diffusion_wind.incentives;

CREATE TRIGGER sync_last_mod
  AFTER INSERT OR UPDATE OR DELETE OR TRUNCATE
  ON diffusion_wind.incentives
  FOR EACH STATEMENT
  EXECUTE PROCEDURE public.sync_last_mod();

