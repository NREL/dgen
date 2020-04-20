SET ROLE 'diffusion-writers';

------------------------------------------------------------------------------------------------------------------------

DROP TABLE IF EXISTS diffusion_solar.incentives;
CREATE TABLE diffusion_solar.incentives AS 
         SELECT uid, incentive_id, 
            pv_res_increment_1_capacity_kw as increment_1_capacity_kw,
	    pv_res_increment_2_capacity_kw as increment_2_capacity_kw,
            pv_increment_3_capacity_kw AS increment_3_capacity_kw, 
            pv_increment_4_capacity_kw AS increment_4_capacity_kw,
            pv_pbi_fit_duration_years AS pbi_fit_duration_years, 
            pv_pbi_fit_end_date AS pbi_fit_end_date,
            NULL::NUMERIC as pbi_fit_min_output_kwh_yr ,
            pv_pbi_fit_max_size_for_dlrs_calc_kw as pbi_fit_max_size_for_dlrs_calc_kw, -- added (missing other pbi ones)
            pv_ptc_duration_years AS ptc_duration_years, 
            pv_ptc_end_date AS ptc_end_date,
            pv_rating_basis_ac_dc_ptc AS rating_basis_ac_dc, 
            pv_res_fit_dlrs_kwh AS fit_dlrs_kwh, 
            pv_res_pbi_dlrs_kwh AS pbi_dlrs_kwh, 
            COALESCE(pv_res_fit_dlrs_kwh, 0::numeric) + COALESCE(pv_res_pbi_dlrs_kwh, 0::numeric) AS pbi_fit_dlrs_kwh, 
            pv_res_increment_1_rebate_dlrs_kw AS increment_1_rebate_dlrs_kw, 
            pv_res_increment_2_rebate_dlrs_kw AS increment_2_rebate_dlrs_kw, 
            NULL::numeric AS increment_3_rebate_dlrs_kw, 
            NULL::numeric AS increment_4_rebate_dlrs_kw, 
            pv_res_max_dlrs_yr AS max_dlrs_yr, 
            pv_res_max_tax_credit_dlrs AS max_tax_credit_dlrs, 
            null::numeric as tax_credit_dlrs_kw,
            pv_res_max_tax_deduction_dlrs AS max_tax_deduction_dlrs, 
            pv_res_pbi_fit_max_dlrs AS pbi_fit_max_dlrs, 
            pv_res_pbi_fit_pcnt_cost_max AS pbi_fit_pcnt_cost_max, 
	    null::numeric as pbi_fit_max_size_kw,
            null::numeric as pbi_fit_min_size_kw,
            pv_res_ptc_dlrs_kwh AS ptc_dlrs_kwh, 
            pv_res_rebate_dlrs_kw AS rebate_dlrs_kw, 
            null::numeric as rebate_max_dlrs,
            pv_res_rebate_max_size_kw AS rebate_max_size_kw, 
            pv_res_rebate_min_size_kw AS rebate_min_size_kw, 
            pv_res_rebate_pcnt_cost_max AS rebate_pcnt_cost_max, 
            pv_res_tax_credit_pcnt_cost AS tax_credit_pcnt_cost, 
            pv_res_tax_deduction_pcnt_cost AS tax_deduction_pcnt_cost, 
            pv_tax_credit_max_size_kw AS tax_credit_max_size_kw, 
            pv_tax_credit_min_size_kw AS tax_credit_min_size_kw, 
            'res'::character varying(3) AS sector_abbr
           FROM geo_incentives.pv_incentives
          WHERE is_res = true
UNION ALL 
         SELECT uid, incentive_id, 
            pv_com_increment_1_capacity_kw as increment_1_capacity_kw,
	    pv_com_increment_2_capacity_kw as increment_2_capacity_kw,
            pv_increment_3_capacity_kw AS increment_3_capacity_kw, 
            pv_increment_4_capacity_kw AS increment_4_capacity_kw, -- added 4 -- (also missing increments 1 and 2)
            pv_pbi_fit_duration_years AS pbi_fit_duration_years, 
            pv_pbi_fit_end_date AS pbi_fit_end_date, 
            NULL::NUMERIC as pbi_fit_min_output_kwh_yr,
            pv_pbi_fit_max_size_for_dlrs_calc_kw as pbi_fit_max_size_for_dlrs_calc_kw, -- added (missing other pbi ones)
            pv_ptc_duration_years AS ptc_duration_years, 
            pv_ptc_end_date AS ptc_end_date,
            pv_rating_basis_ac_dc_ptc AS rating_basis_ac_dc, 
            pv_com_fit_dlrs_kwh AS fit_dlrs_kwh, 
            pv_com_pbi_dlrs_kwh AS pbi_dlrs_kwh, 
            COALESCE(pv_com_fit_dlrs_kwh, 0::numeric) + COALESCE(pv_com_pbi_dlrs_kwh, 0::numeric) AS pbi_fit_dlrs_kwh, 
            pv_com_increment_1_rebate_dlrs_kw AS increment_1_rebate_dlrs_kw, 
            pv_com_increment_2_rebate_dlrs_kw AS increment_2_rebate_dlrs_kw, 
            pv_com_increment_3_rebate_dlrs_kw AS increment_3_rebate_dlrs_kw,
            pv_com_increment_4_rebate_dlrs_kw AS increment_4_rebate_dlrs_kw,
            pv_com_max_dlrs_yr AS max_dlrs_yr, 
            pv_com_max_tax_credit_dlrs AS max_tax_credit_dlrs, 
            pv_com_tax_credit_dlrs_kw as tax_credit_dlrs_kw,
            pv_com_max_tax_deduction_dlrs AS max_tax_deduction_dlrs, 
            pv_com_pbi_fit_max_dlrs AS pbi_fit_max_dlrs, 
            pv_com_pbi_fit_pcnt_cost_max AS pbi_fit_pcnt_cost_max, 
	    pv_com_pbi_fit_max_size_kw as pbi_fit_max_size_kw,
            pv_com_pbi_fit_min_size_kw as pbi_fit_min_size_kw,
            pv_com_ptc_dlrs_kwh AS ptc_dlrs_kwh, 
            pv_com_rebate_dlrs_kw AS rebate_dlrs_kw,    
            pv_com_max_rebate_dlrs as rebate_max_dlrs,
            pv_com_rebate_max_size_kw AS rebate_max_size_kw, 
            pv_com_rebate_min_size_kw AS rebate_min_size_kw, 
            pv_com_rebate_pcnt_cost_max AS rebate_pcnt_cost_max, 
            pv_com_tax_credit_pcnt_cost AS tax_credit_pcnt_cost, 
            pv_com_tax_deduction_pcnt_cost AS tax_deduction_pcnt_cost, 
            pv_tax_credit_max_size_kw AS tax_credit_max_size_kw, 
            pv_tax_credit_min_size_kw AS tax_credit_min_size_kw, 
            'com'::character varying(3) AS sector_abbr
           FROM geo_incentives.pv_incentives
          WHERE is_com = true
UNION ALL 
         SELECT uid, incentive_id, 
            pv_com_increment_1_capacity_kw as increment_1_capacity_kw,
	    pv_com_increment_2_capacity_kw as increment_2_capacity_kw,
            pv_increment_3_capacity_kw AS increment_3_capacity_kw, 
            pv_increment_4_capacity_kw AS increment_4_capacity_kw, -- added 4 -- (also missing increments 1 and 2)
            pv_pbi_fit_duration_years AS pbi_fit_duration_years, 
            pv_pbi_fit_end_date AS pbi_fit_end_date, 
            NULL::NUMERIC as pbi_fit_min_output_kwh_yr,
            pv_pbi_fit_max_size_for_dlrs_calc_kw as pbi_fit_max_size_for_dlrs_calc_kw, -- added (missing other pbi ones)
            pv_ptc_duration_years AS ptc_duration_years, 
            pv_ptc_end_date AS ptc_end_date,
            pv_rating_basis_ac_dc_ptc AS rating_basis_ac_dc, 
            pv_com_fit_dlrs_kwh AS fit_dlrs_kwh, 
            pv_com_pbi_dlrs_kwh AS pbi_dlrs_kwh, 
            COALESCE(pv_com_fit_dlrs_kwh, 0::numeric) + COALESCE(pv_com_pbi_dlrs_kwh, 0::numeric) AS pbi_fit_dlrs_kwh, 
            pv_com_increment_1_rebate_dlrs_kw AS increment_1_rebate_dlrs_kw, 
            pv_com_increment_2_rebate_dlrs_kw AS increment_2_rebate_dlrs_kw, 
            pv_com_increment_3_rebate_dlrs_kw AS increment_3_rebate_dlrs_kw,
            pv_com_increment_4_rebate_dlrs_kw AS increment_4_rebate_dlrs_kw,
            pv_com_max_dlrs_yr AS max_dlrs_yr, 
            pv_com_max_tax_credit_dlrs AS max_tax_credit_dlrs, 
            pv_com_tax_credit_dlrs_kw as tax_credit_dlrs_kw,
            pv_com_max_tax_deduction_dlrs AS max_tax_deduction_dlrs, 
            pv_com_pbi_fit_max_dlrs AS pbi_fit_max_dlrs, 
            pv_com_pbi_fit_pcnt_cost_max AS pbi_fit_pcnt_cost_max, 
	    pv_com_pbi_fit_max_size_kw as pbi_fit_max_size_kw,
            pv_com_pbi_fit_min_size_kw as pbi_fit_min_size_kw,
            pv_com_ptc_dlrs_kwh AS ptc_dlrs_kwh, 
            pv_com_rebate_dlrs_kw AS rebate_dlrs_kw,    
            pv_com_max_rebate_dlrs as rebate_max_dlrs,
            pv_com_rebate_max_size_kw AS rebate_max_size_kw, 
            pv_com_rebate_min_size_kw AS rebate_min_size_kw, 
            pv_com_rebate_pcnt_cost_max AS rebate_pcnt_cost_max, 
            pv_com_tax_credit_pcnt_cost AS tax_credit_pcnt_cost, 
            pv_com_tax_deduction_pcnt_cost AS tax_deduction_pcnt_cost, 
            pv_tax_credit_max_size_kw AS tax_credit_max_size_kw, 
            pv_tax_credit_min_size_kw AS tax_credit_min_size_kw, 
            'ind'::character varying(3) AS sector_abbr
           FROM geo_incentives.pv_incentives
          WHERE is_com = true;

-- add primary key
ALTER TABLE diffusion_solar.incentives
ADD PRIMARY KEY (uid, sector_abbr);

-- add indices on those two feilds separately
CREATE INDEX incentives_uid_btree
ON diffusion_solar.incentives
using BTREE(uid);

CREATE INDEX incentives_sector_abbr_btree
ON diffusion_solar.incentives
using BTREE(sector_abbr);