set role 'diffusion-writers';

DROP TABLE IF EXISTS diffusion_shared.cdms_bldg_types_to_sectors_lkup;
CREATE TABLE diffusion_shared.cdms_bldg_types_to_sectors_lkup
(
	cdms text primary key,
	sector_abbr varchar(3)
);

\COPY  diffusion_shared.cdms_bldg_types_to_sectors_lkup FROM '/Volumes/Staff/mgleason/dGeo/Data/Source_Data/HAZUS/cdms_types_to_sectors.csv' with csv header;

-- check results
select *
FROM diffusion_shared.cdms_bldg_types_to_sectors_lkup;
-- 33 rows -- good
-- all are complete - good

-- note: this table was created primarily by Kevin McCabe, who determined which CDMS
-- types could be mapped to commercial buildings using CBECS pba/pba plus codes.
-- the remaining types are easily divisible into residential and industrial.

select *
FROM diffusion_shared.cdms_bldg_types_to_sectors_lkup
where sector_abbr = 'res';
