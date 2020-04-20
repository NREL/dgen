DROP TABLE IF EXISTS diffusion_data_shared.county_ulocale_lkup_res;
CREATE TABLE diffusion_data_shared.county_ulocale_lkup_res AS
SELECT distinct county_id, ulocale
FROM diffusion_shared.pt_grid_us_res;
-- 6332 rows

DROP TABLE IF EXISTS diffusion_data_shared.county_ulocale_lkup_com;
CREATE TABLE diffusion_data_shared.county_ulocale_lkup_com AS
SELECT distinct county_id, ulocale
FROM diffusion_shared.pt_grid_us_com;
-- 5994 rows

DROP TABLE IF EXISTS diffusion_data_shared.county_ulocale_lkup_ind;
CREATE TABLE diffusion_data_shared.county_ulocale_lkup_ind AS
SELECT distinct county_id, ulocale
FROM diffusion_shared.pt_grid_us_ind;
-- 6039 rows

-- create indices
CREATE INDEX county_ulocale_lkup_res_county_id_btree
ON diffusion_data_shared.county_ulocale_lkup_res
USING BTREE(county_id);

CREATE INDEX county_ulocale_lkup_res_ulocale_btree
ON diffusion_data_shared.county_ulocale_lkup_res
USING BTREE(ulocale);

CREATE INDEX county_ulocale_lkup_com_county_id_btree
ON diffusion_data_shared.county_ulocale_lkup_com
USING BTREE(county_id);

CREATE INDEX county_ulocale_lkup_com_ulocale_btree
ON diffusion_data_shared.county_ulocale_lkup_com
USING BTREE(ulocale);

CREATE INDEX county_ulocale_lkup_ind_county_id_btree
ON diffusion_data_shared.county_ulocale_lkup_ind
USING BTREE(county_id);

CREATE INDEX county_ulocale_lkup_ind_ulocale_btree
ON diffusion_data_shared.county_ulocale_lkup_ind
USING BTREE(ulocale);