SET ROLE 'diffusion-writers';

-- as part of his review, CG also came up with a new table of SRECS
DROP TABLE IF EXISTS diffusion_solar.srecs;
CREATE TABLE diffusion_solar.srecs
(
	state_abbr varchar(2) not null,
	uid integer,
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
	sector_abbr character varying(3) NOT NULL
);

\COPY diffusion_solar.srecs FROM '/Volumes/Staff/mgleason/DG_Solar/Data/Source_Data/dsire_revised_by_cg_2015_10_14/srec.csv' with csv header;

-- add an index on state_abbr and sector_abbr
CREATE INDEX srecs_state_abbr_btree
ON diffusion_solar.srecs
USING BTREE(state_abbr);

CREATE INDEX srecs_sector_abbr_btree
ON diffusion_solar.srecs
USING BTREE(sector_abbr);

-- check row count
SELECT count(*)
FROM diffusion_solar.srecs
-- 27
