set role 'diffusion-writers';

DROP TABLE IF EXISTS diffusion_solar.reeds_h17_to_h3_ratio_by_pca;
CREATE TABLE diffusion_solar.reeds_h17_to_h3_ratio_by_pca
(
	pca_reg integer primary key,
	ratio numeric
);

\COPY diffusion_solar.reeds_h17_to_h3_ratio_by_pca FROM '/Volumes/Staff/mgleason/DG_Solar/Data/Source_Data/reeds/h17_to_h3_ratio_by_pca.csv' with csv header;

select *
FROM diffusion_solar.reeds_h17_to_h3_ratio_by_pca;