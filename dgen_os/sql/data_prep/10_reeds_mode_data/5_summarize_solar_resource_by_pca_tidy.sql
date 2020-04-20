set role 'diffusion-writers';

DROP TABLE IF EXISTS diffusion_solar.reeds_solar_resource_by_pca_summary_tidy;
CREATE TABLE diffusion_solar.reeds_solar_resource_by_pca_summary_tidy AS
select a.pca_reg, 
	count(a.solar_re_9809_gid) as n_points, 
	b.tilt, 
	b.azimuth, 
	b.reeds_time_slice,
	AVG(b.cf_avg) as cf_avg
from diffusion_solar.pca_solar_re_9809_combinations a
lEFT JOIN diffusion_solar.reeds_avg_cf_by_orientation_and_time_slice b
ON a.solar_re_9809_gid = b.solar_re_9809_gid
group by a.pca_reg, b.tilt, b.azimuth, b.reeds_time_slice;

-- add a primary key on pca_reg, tilt, azimuth, and time_slice
ALTER TABLE diffusion_solar.reeds_solar_resource_by_pca_summary_tidy
ADD PRIMARY KEY (pca_reg, tilt, azimuth, reeds_time_slice);

-- add indices on tilt, azimuth, pca_reg, and time_slice
CREATE INDEX reeds_solar_resource_by_pca_summary_tidy_pca_reg_btree
ON diffusion_solar.reeds_solar_resource_by_pca_summary_tidy
USING BTREE(pca_reg);

CREATE INDEX reeds_solar_resource_by_pca_summary_tidy_tilt_btree
ON diffusion_solar.reeds_solar_resource_by_pca_summary_tidy
USING BTREE(tilt);

CREATE INDEX reeds_solar_resource_by_pca_summary_tidy_azimuth_btree
ON diffusion_solar.reeds_solar_resource_by_pca_summary_tidy
USING BTREE(azimuth);

CREATE INDEX reeds_solar_resource_by_pca_summary_tidy_reeds_time_slice_btree
ON diffusion_solar.reeds_solar_resource_by_pca_summary_tidy
USING BTREE(reeds_time_slice);

-- add in data for H17, using the ratio lookups applied to H3
INSERT INTO diffusion_solar.reeds_solar_resource_by_pca_summary_tidy
select a.pca_reg, a.n_points, a.tilt, a.azimuth, 
	'H17'::Varchar(3) as reeds_time_slice,
	a.cf_avg * b.ratio as cf_avg
from diffusion_solar.reeds_solar_resource_by_pca_summary_tidy a
LEFT JOIN diffusion_solar.reeds_h17_to_h3_ratio_by_pca b
ON a.pca_reg = b.pca_reg
where a.reeds_time_slice = 'H03';
-- 4020 rows

vACUUM ANALYZE diffusion_solar.reeds_solar_resource_by_pca_summary_tidy;