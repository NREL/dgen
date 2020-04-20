DROP TABLE IF EXISTS diffusion_data_shared.block_county_ulocale_lkup_res;
CREATE TABLE diffusion_data_shared.block_county_ulocale_lkup_res AS
SELECT distinct county_id, ulocale
FROM diffusion_blocks.block_microdata_res
-- 6326 rows

DROP TABLE IF EXISTS diffusion_data_shared.block_county_ulocale_lkup_com;
CREATE TABLE diffusion_data_shared.block_county_ulocale_lkup_com AS
SELECT distinct county_id, ulocale
FROM diffusion_blocks.block_microdata_com;
-- 6072 rows

DROP TABLE IF EXISTS diffusion_data_shared.block_county_ulocale_lkup_ind;
CREATE TABLE diffusion_data_shared.block_county_ulocale_lkup_ind AS
SELECT distinct county_id, ulocale
FROM diffusion_blocks.block_microdata_ind;
-- 5985 rows

-- create indices
CREATE INDEX block_county_ulocale_lkup_res_county_id_btree
ON diffusion_data_shared.block_county_ulocale_lkup_res
USING BTREE(county_id);

CREATE INDEX block_county_ulocale_lkup_res_ulocale_btree
ON diffusion_data_shared.block_county_ulocale_lkup_res
USING BTREE(ulocale);

CREATE INDEX block_county_ulocale_lkup_com_county_id_btree
ON diffusion_data_shared.block_county_ulocale_lkup_com
USING BTREE(county_id);

CREATE INDEX block_county_ulocale_lkup_com_ulocale_btree
ON diffusion_data_shared.block_county_ulocale_lkup_com
USING BTREE(ulocale);

CREATE INDEX block_county_ulocale_lkup_ind_county_id_btree
ON diffusion_data_shared.block_county_ulocale_lkup_ind
USING BTREE(county_id);

CREATE INDEX block_county_ulocale_lkup_ind_ulocale_btree
ON diffusion_data_shared.block_county_ulocale_lkup_ind
USING BTREE(ulocale);