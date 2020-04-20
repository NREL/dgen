SET ROLE 'diffusion-writers';

DROP TABLE IF EXISTS diffusion_solar.reeds_time_slice_lkup;
CREATE TABLE diffusion_solar.reeds_time_slice_lkup
(
	hour_index integer primary key,
	reeds_time_slice varchar(3)
);

\COPY  diffusion_solar.reeds_time_slice_lkup FROM '/Volumes/Staff/mgleason/DG_Solar/Data/Source_Data/reeds/reeds_ts_lkup.csv' with csv header;;

select *
FROM diffusion_solar.reeds_time_slice_lkup