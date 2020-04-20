set role 'diffusion-writers';

DROP TABLE IF EXISTS diffusion_solar.pca_solar_re_9809_combinations;
CREATE TABLE diffusion_solar.pca_solar_re_9809_combinations AS
SELECT DISTINCT solar_re_9809_gid, pca_reg 
FROM diffusion_shared.pt_grid_us_com
UNION
SELECT DISTINCT solar_re_9809_gid, pca_reg 
FROM diffusion_shared.pt_grid_us_res
UNION
SELECT DISTINCT solar_re_9809_gid, pca_reg 
FROM diffusion_shared.pt_grid_us_ind;
--  69025 rows

-- create index on solar_re_9809
CREATE INDEX pca_solar_re_9809_combinations_pca_reg_btree
ON diffusion_solar.pca_solar_re_9809_combinations
USING BTREE(pca_reg);

CREATE INDEX pca_solar_re_9809_combinations_solar_re_9809_gid_btree
ON diffusion_solar.pca_solar_re_9809_combinations
USING BTREE(solar_re_9809_gid);