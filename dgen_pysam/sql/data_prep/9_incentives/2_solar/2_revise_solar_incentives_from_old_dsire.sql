SET ROLE 'diffusion-writers';

-- CG did a fairly rapid review of the DSIRE incentives for Solar
-- and made some manual edits. we will use his new version and archive the original incentives
-- ALTER TABLE diffusion_solar.incentives
-- RENAME TO incentives_archive;

DROP TABLE IF EXISTS diffusion_solar.incentives;
CREATE TABLE diffusion_solar.incentives
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
	CONSTRAINT incentives_pkey_new PRIMARY KEY (uid, sector_abbr)
);

\COPY diffusion_solar.incentives FROM '/Volumes/Staff/mgleason/DG_Solar/Data/Source_Data/dsire_revised_by_cg_2015_10_14/incentives_cleanup_nas.csv' with csv header;


-- compare the datasets
SELECT count(*)
FROM diffusion_solar.incentives;
-- 1082

SELECT count(*)
FROM diffusion_solar.incentives_archive;
-- 1082

-- are all incentives from the old data still in the new?
select *
from diffusion_solar.incentives_archive a
left join diffusion_solar.incentives b
ON a.uid = b.uid
and a.sector_abbr = b.sector_abbr
where b.uid is null;
-- yes

-- all set