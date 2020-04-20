-- load shapefiles to postgres using shp2pgsql from command line as follows:
--  shp2pgsql -s 102003 -c -g the_geom_102003 -D -I RI_block_2010.shp census_2010.block_geom_RI | psql -h gispgdb -U mgleason dav-gis

-- for each table, then do the following:
SELECT table_schema || '.' || table_name
FROM information_schema.tables 
WHERE table_schema = 'census_2010'
and table_name like 'block_geom_%';;

-- add 4326 geom
ALTER TABLE census_2010.block_geom_al ADD column the_geom_4326 geometry;
ALTER TABLE census_2010.block_geom_ar ADD column the_geom_4326 geometry;
ALTER TABLE census_2010.block_geom_az ADD column the_geom_4326 geometry;
ALTER TABLE census_2010.block_geom_ca ADD column the_geom_4326 geometry;
ALTER TABLE census_2010.block_geom_ak ADD column the_geom_4326 geometry;
ALTER TABLE census_2010.block_geom_co ADD column the_geom_4326 geometry;
ALTER TABLE census_2010.block_geom_ct ADD column the_geom_4326 geometry;
ALTER TABLE census_2010.block_geom_dc ADD column the_geom_4326 geometry;
ALTER TABLE census_2010.block_geom_de ADD column the_geom_4326 geometry;
ALTER TABLE census_2010.block_geom_fl ADD column the_geom_4326 geometry;
ALTER TABLE census_2010.block_geom_ga ADD column the_geom_4326 geometry;
ALTER TABLE census_2010.block_geom_hi ADD column the_geom_4326 geometry;
ALTER TABLE census_2010.block_geom_ia ADD column the_geom_4326 geometry;
ALTER TABLE census_2010.block_geom_id ADD column the_geom_4326 geometry;
ALTER TABLE census_2010.block_geom_mi ADD column the_geom_4326 geometry;
ALTER TABLE census_2010.block_geom_nh ADD column the_geom_4326 geometry;
ALTER TABLE census_2010.block_geom_nj ADD column the_geom_4326 geometry;
ALTER TABLE census_2010.block_geom_il ADD column the_geom_4326 geometry;
ALTER TABLE census_2010.block_geom_mn ADD column the_geom_4326 geometry;
ALTER TABLE census_2010.block_geom_nm ADD column the_geom_4326 geometry;
ALTER TABLE census_2010.block_geom_nv ADD column the_geom_4326 geometry;
ALTER TABLE census_2010.block_geom_mo ADD column the_geom_4326 geometry;
ALTER TABLE census_2010.block_geom_ny ADD column the_geom_4326 geometry;
ALTER TABLE census_2010.block_geom_ms ADD column the_geom_4326 geometry;
ALTER TABLE census_2010.block_geom_oh ADD column the_geom_4326 geometry;
ALTER TABLE census_2010.block_geom_ks ADD column the_geom_4326 geometry;
ALTER TABLE census_2010.block_geom_mt ADD column the_geom_4326 geometry;
ALTER TABLE census_2010.block_geom_in ADD column the_geom_4326 geometry;
ALTER TABLE census_2010.block_geom_ok ADD column the_geom_4326 geometry;
ALTER TABLE census_2010.block_geom_ky ADD column the_geom_4326 geometry;
ALTER TABLE census_2010.block_geom_nc ADD column the_geom_4326 geometry;
ALTER TABLE census_2010.block_geom_or ADD column the_geom_4326 geometry;
ALTER TABLE census_2010.block_geom_la ADD column the_geom_4326 geometry;
ALTER TABLE census_2010.block_geom_nd ADD column the_geom_4326 geometry;
ALTER TABLE census_2010.block_geom_ma ADD column the_geom_4326 geometry;
ALTER TABLE census_2010.block_geom_pa ADD column the_geom_4326 geometry;
ALTER TABLE census_2010.block_geom_ne ADD column the_geom_4326 geometry;
ALTER TABLE census_2010.block_geom_md ADD column the_geom_4326 geometry;
ALTER TABLE census_2010.block_geom_me ADD column the_geom_4326 geometry;
ALTER TABLE census_2010.block_geom_pr ADD column the_geom_4326 geometry;
ALTER TABLE census_2010.block_geom_ri ADD column the_geom_4326 geometry;
ALTER TABLE census_2010.block_geom_sc ADD column the_geom_4326 geometry;
ALTER TABLE census_2010.block_geom_sd ADD column the_geom_4326 geometry;
ALTER TABLE census_2010.block_geom_tn ADD column the_geom_4326 geometry;
ALTER TABLE census_2010.block_geom_tx ADD column the_geom_4326 geometry;
ALTER TABLE census_2010.block_geom_ut ADD column the_geom_4326 geometry;
ALTER TABLE census_2010.block_geom_va ADD column the_geom_4326 geometry;
ALTER TABLE census_2010.block_geom_vt ADD column the_geom_4326 geometry;
ALTER TABLE census_2010.block_geom_wa ADD column the_geom_4326 geometry;
ALTER TABLE census_2010.block_geom_wi ADD column the_geom_4326 geometry;
ALTER TABLE census_2010.block_geom_wv ADD column the_geom_4326 geometry;
ALTER TABLE census_2010.block_geom_wy ADD column the_geom_4326 geometry;

-- update 4326 geom
UPDATE census_2010.block_geom_al SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE census_2010.block_geom_ar SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE census_2010.block_geom_az SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE census_2010.block_geom_ca SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE census_2010.block_geom_ak SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE census_2010.block_geom_co SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE census_2010.block_geom_ct SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE census_2010.block_geom_dc SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE census_2010.block_geom_de SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE census_2010.block_geom_fl SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE census_2010.block_geom_ga SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE census_2010.block_geom_hi SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE census_2010.block_geom_ia SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE census_2010.block_geom_id SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE census_2010.block_geom_mi SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE census_2010.block_geom_nh SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE census_2010.block_geom_nj SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE census_2010.block_geom_il SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE census_2010.block_geom_mn SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE census_2010.block_geom_nm SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE census_2010.block_geom_nv SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE census_2010.block_geom_mo SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE census_2010.block_geom_ny SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE census_2010.block_geom_ms SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE census_2010.block_geom_oh SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE census_2010.block_geom_ks SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE census_2010.block_geom_mt SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE census_2010.block_geom_in SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE census_2010.block_geom_ok SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE census_2010.block_geom_ky SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE census_2010.block_geom_nc SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE census_2010.block_geom_or SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE census_2010.block_geom_la SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE census_2010.block_geom_nd SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE census_2010.block_geom_ma SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE census_2010.block_geom_pa SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE census_2010.block_geom_ne SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE census_2010.block_geom_md SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE census_2010.block_geom_me SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE census_2010.block_geom_pr SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE census_2010.block_geom_ri SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE census_2010.block_geom_sc SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE census_2010.block_geom_sd SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE census_2010.block_geom_tn SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE census_2010.block_geom_tx SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE census_2010.block_geom_ut SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE census_2010.block_geom_va SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE census_2010.block_geom_vt SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE census_2010.block_geom_wa SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE census_2010.block_geom_wi SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE census_2010.block_geom_wv SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE census_2010.block_geom_wy SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);

-- add index on new geom
CREATE INDEX block_geom_al_the_geom_4326_gist ON census_2010.block_geom_al USING gist(the_geom_4326);
CREATE INDEX block_geom_ar_the_geom_4326_gist ON census_2010.block_geom_ar USING gist(the_geom_4326);
CREATE INDEX block_geom_az_the_geom_4326_gist ON census_2010.block_geom_az USING gist(the_geom_4326);
CREATE INDEX block_geom_ca_the_geom_4326_gist ON census_2010.block_geom_ca USING gist(the_geom_4326);
CREATE INDEX block_geom_ak_the_geom_4326_gist ON census_2010.block_geom_ak USING gist(the_geom_4326);
CREATE INDEX block_geom_co_the_geom_4326_gist ON census_2010.block_geom_co USING gist(the_geom_4326);
CREATE INDEX block_geom_ct_the_geom_4326_gist ON census_2010.block_geom_ct USING gist(the_geom_4326);
CREATE INDEX block_geom_dc_the_geom_4326_gist ON census_2010.block_geom_dc USING gist(the_geom_4326);
CREATE INDEX block_geom_de_the_geom_4326_gist ON census_2010.block_geom_de USING gist(the_geom_4326);
CREATE INDEX block_geom_fl_the_geom_4326_gist ON census_2010.block_geom_fl USING gist(the_geom_4326);
CREATE INDEX block_geom_ga_the_geom_4326_gist ON census_2010.block_geom_ga USING gist(the_geom_4326);
CREATE INDEX block_geom_hi_the_geom_4326_gist ON census_2010.block_geom_hi USING gist(the_geom_4326);
CREATE INDEX block_geom_ia_the_geom_4326_gist ON census_2010.block_geom_ia USING gist(the_geom_4326);
CREATE INDEX block_geom_id_the_geom_4326_gist ON census_2010.block_geom_id USING gist(the_geom_4326);
CREATE INDEX block_geom_mi_the_geom_4326_gist ON census_2010.block_geom_mi USING gist(the_geom_4326);
CREATE INDEX block_geom_nh_the_geom_4326_gist ON census_2010.block_geom_nh USING gist(the_geom_4326);
CREATE INDEX block_geom_nj_the_geom_4326_gist ON census_2010.block_geom_nj USING gist(the_geom_4326);
CREATE INDEX block_geom_il_the_geom_4326_gist ON census_2010.block_geom_il USING gist(the_geom_4326);
CREATE INDEX block_geom_mn_the_geom_4326_gist ON census_2010.block_geom_mn USING gist(the_geom_4326);
CREATE INDEX block_geom_nm_the_geom_4326_gist ON census_2010.block_geom_nm USING gist(the_geom_4326);
CREATE INDEX block_geom_nv_the_geom_4326_gist ON census_2010.block_geom_nv USING gist(the_geom_4326);
CREATE INDEX block_geom_mo_the_geom_4326_gist ON census_2010.block_geom_mo USING gist(the_geom_4326);
CREATE INDEX block_geom_ny_the_geom_4326_gist ON census_2010.block_geom_ny USING gist(the_geom_4326);
CREATE INDEX block_geom_ms_the_geom_4326_gist ON census_2010.block_geom_ms USING gist(the_geom_4326);
CREATE INDEX block_geom_oh_the_geom_4326_gist ON census_2010.block_geom_oh USING gist(the_geom_4326);
CREATE INDEX block_geom_ks_the_geom_4326_gist ON census_2010.block_geom_ks USING gist(the_geom_4326);
CREATE INDEX block_geom_mt_the_geom_4326_gist ON census_2010.block_geom_mt USING gist(the_geom_4326);
CREATE INDEX block_geom_in_the_geom_4326_gist ON census_2010.block_geom_in USING gist(the_geom_4326);
CREATE INDEX block_geom_ok_the_geom_4326_gist ON census_2010.block_geom_ok USING gist(the_geom_4326);
CREATE INDEX block_geom_ky_the_geom_4326_gist ON census_2010.block_geom_ky USING gist(the_geom_4326);
CREATE INDEX block_geom_nc_the_geom_4326_gist ON census_2010.block_geom_nc USING gist(the_geom_4326);
CREATE INDEX block_geom_or_the_geom_4326_gist ON census_2010.block_geom_or USING gist(the_geom_4326);
CREATE INDEX block_geom_la_the_geom_4326_gist ON census_2010.block_geom_la USING gist(the_geom_4326);
CREATE INDEX block_geom_nd_the_geom_4326_gist ON census_2010.block_geom_nd USING gist(the_geom_4326);
CREATE INDEX block_geom_ma_the_geom_4326_gist ON census_2010.block_geom_ma USING gist(the_geom_4326);
CREATE INDEX block_geom_pa_the_geom_4326_gist ON census_2010.block_geom_pa USING gist(the_geom_4326);
CREATE INDEX block_geom_ne_the_geom_4326_gist ON census_2010.block_geom_ne USING gist(the_geom_4326);
CREATE INDEX block_geom_md_the_geom_4326_gist ON census_2010.block_geom_md USING gist(the_geom_4326);
CREATE INDEX block_geom_me_the_geom_4326_gist ON census_2010.block_geom_me USING gist(the_geom_4326);
CREATE INDEX block_geom_pr_the_geom_4326_gist ON census_2010.block_geom_pr USING gist(the_geom_4326);
CREATE INDEX block_geom_ri_the_geom_4326_gist ON census_2010.block_geom_ri USING gist(the_geom_4326);
CREATE INDEX block_geom_sc_the_geom_4326_gist ON census_2010.block_geom_sc USING gist(the_geom_4326);
CREATE INDEX block_geom_sd_the_geom_4326_gist ON census_2010.block_geom_sd USING gist(the_geom_4326);
CREATE INDEX block_geom_tn_the_geom_4326_gist ON census_2010.block_geom_tn USING gist(the_geom_4326);
CREATE INDEX block_geom_tx_the_geom_4326_gist ON census_2010.block_geom_tx USING gist(the_geom_4326);
CREATE INDEX block_geom_ut_the_geom_4326_gist ON census_2010.block_geom_ut USING gist(the_geom_4326);
CREATE INDEX block_geom_va_the_geom_4326_gist ON census_2010.block_geom_va USING gist(the_geom_4326);
CREATE INDEX block_geom_vt_the_geom_4326_gist ON census_2010.block_geom_vt USING gist(the_geom_4326);
CREATE INDEX block_geom_wa_the_geom_4326_gist ON census_2010.block_geom_wa USING gist(the_geom_4326);
CREATE INDEX block_geom_wi_the_geom_4326_gist ON census_2010.block_geom_wi USING gist(the_geom_4326);
CREATE INDEX block_geom_wv_the_geom_4326_gist ON census_2010.block_geom_wv USING gist(the_geom_4326);
CREATE INDEX block_geom_wy_the_geom_4326_gist ON census_2010.block_geom_wy USING gist(the_geom_4326);

-- add index on gisjoin
CREATE INDEX block_geom_al_gisjoin_btree ON census_2010.block_geom_al USING btree(gisjoin);
CREATE INDEX block_geom_ar_gisjoin_btree ON census_2010.block_geom_ar USING btree(gisjoin);
CREATE INDEX block_geom_az_gisjoin_btree ON census_2010.block_geom_az USING btree(gisjoin);
CREATE INDEX block_geom_ca_gisjoin_btree ON census_2010.block_geom_ca USING btree(gisjoin);
CREATE INDEX block_geom_ak_gisjoin_btree ON census_2010.block_geom_ak USING btree(gisjoin);
CREATE INDEX block_geom_co_gisjoin_btree ON census_2010.block_geom_co USING btree(gisjoin);
CREATE INDEX block_geom_ct_gisjoin_btree ON census_2010.block_geom_ct USING btree(gisjoin);
CREATE INDEX block_geom_dc_gisjoin_btree ON census_2010.block_geom_dc USING btree(gisjoin);
CREATE INDEX block_geom_de_gisjoin_btree ON census_2010.block_geom_de USING btree(gisjoin);
CREATE INDEX block_geom_fl_gisjoin_btree ON census_2010.block_geom_fl USING btree(gisjoin);
CREATE INDEX block_geom_ga_gisjoin_btree ON census_2010.block_geom_ga USING btree(gisjoin);
CREATE INDEX block_geom_hi_gisjoin_btree ON census_2010.block_geom_hi USING btree(gisjoin);
CREATE INDEX block_geom_ia_gisjoin_btree ON census_2010.block_geom_ia USING btree(gisjoin);
CREATE INDEX block_geom_id_gisjoin_btree ON census_2010.block_geom_id USING btree(gisjoin);
CREATE INDEX block_geom_mi_gisjoin_btree ON census_2010.block_geom_mi USING btree(gisjoin);
CREATE INDEX block_geom_nh_gisjoin_btree ON census_2010.block_geom_nh USING btree(gisjoin);
CREATE INDEX block_geom_nj_gisjoin_btree ON census_2010.block_geom_nj USING btree(gisjoin);
CREATE INDEX block_geom_il_gisjoin_btree ON census_2010.block_geom_il USING btree(gisjoin);
CREATE INDEX block_geom_mn_gisjoin_btree ON census_2010.block_geom_mn USING btree(gisjoin);
CREATE INDEX block_geom_nm_gisjoin_btree ON census_2010.block_geom_nm USING btree(gisjoin);
CREATE INDEX block_geom_nv_gisjoin_btree ON census_2010.block_geom_nv USING btree(gisjoin);
CREATE INDEX block_geom_mo_gisjoin_btree ON census_2010.block_geom_mo USING btree(gisjoin);
CREATE INDEX block_geom_ny_gisjoin_btree ON census_2010.block_geom_ny USING btree(gisjoin);
CREATE INDEX block_geom_ms_gisjoin_btree ON census_2010.block_geom_ms USING btree(gisjoin);
CREATE INDEX block_geom_oh_gisjoin_btree ON census_2010.block_geom_oh USING btree(gisjoin);
CREATE INDEX block_geom_ks_gisjoin_btree ON census_2010.block_geom_ks USING btree(gisjoin);
CREATE INDEX block_geom_mt_gisjoin_btree ON census_2010.block_geom_mt USING btree(gisjoin);
CREATE INDEX block_geom_in_gisjoin_btree ON census_2010.block_geom_in USING btree(gisjoin);
CREATE INDEX block_geom_ok_gisjoin_btree ON census_2010.block_geom_ok USING btree(gisjoin);
CREATE INDEX block_geom_ky_gisjoin_btree ON census_2010.block_geom_ky USING btree(gisjoin);
CREATE INDEX block_geom_nc_gisjoin_btree ON census_2010.block_geom_nc USING btree(gisjoin);
CREATE INDEX block_geom_or_gisjoin_btree ON census_2010.block_geom_or USING btree(gisjoin);
CREATE INDEX block_geom_la_gisjoin_btree ON census_2010.block_geom_la USING btree(gisjoin);
CREATE INDEX block_geom_nd_gisjoin_btree ON census_2010.block_geom_nd USING btree(gisjoin);
CREATE INDEX block_geom_ma_gisjoin_btree ON census_2010.block_geom_ma USING btree(gisjoin);
CREATE INDEX block_geom_pa_gisjoin_btree ON census_2010.block_geom_pa USING btree(gisjoin);
CREATE INDEX block_geom_ne_gisjoin_btree ON census_2010.block_geom_ne USING btree(gisjoin);
CREATE INDEX block_geom_md_gisjoin_btree ON census_2010.block_geom_md USING btree(gisjoin);
CREATE INDEX block_geom_me_gisjoin_btree ON census_2010.block_geom_me USING btree(gisjoin);
CREATE INDEX block_geom_pr_gisjoin_btree ON census_2010.block_geom_pr USING btree(gisjoin);
CREATE INDEX block_geom_ri_gisjoin_btree ON census_2010.block_geom_ri USING btree(gisjoin);
CREATE INDEX block_geom_sc_gisjoin_btree ON census_2010.block_geom_sc USING btree(gisjoin);
CREATE INDEX block_geom_sd_gisjoin_btree ON census_2010.block_geom_sd USING btree(gisjoin);
CREATE INDEX block_geom_tn_gisjoin_btree ON census_2010.block_geom_tn USING btree(gisjoin);
CREATE INDEX block_geom_tx_gisjoin_btree ON census_2010.block_geom_tx USING btree(gisjoin);
CREATE INDEX block_geom_ut_gisjoin_btree ON census_2010.block_geom_ut USING btree(gisjoin);
CREATE INDEX block_geom_va_gisjoin_btree ON census_2010.block_geom_va USING btree(gisjoin);
CREATE INDEX block_geom_vt_gisjoin_btree ON census_2010.block_geom_vt USING btree(gisjoin);
CREATE INDEX block_geom_wa_gisjoin_btree ON census_2010.block_geom_wa USING btree(gisjoin);
CREATE INDEX block_geom_wi_gisjoin_btree ON census_2010.block_geom_wi USING btree(gisjoin);
CREATE INDEX block_geom_wv_gisjoin_btree ON census_2010.block_geom_wv USING btree(gisjoin);
CREATE INDEX block_geom_wy_gisjoin_btree ON census_2010.block_geom_wy USING btree(gisjoin);

-- add state abbr column
ALTER TABLE census_2010.block_geom_al ADD COLUMN state_abbr character varying (2);
ALTER TABLE census_2010.block_geom_ar ADD COLUMN state_abbr character varying (2);
ALTER TABLE census_2010.block_geom_az ADD COLUMN state_abbr character varying (2);
ALTER TABLE census_2010.block_geom_ca ADD COLUMN state_abbr character varying (2);
ALTER TABLE census_2010.block_geom_ak ADD COLUMN state_abbr character varying (2);
ALTER TABLE census_2010.block_geom_co ADD COLUMN state_abbr character varying (2);
ALTER TABLE census_2010.block_geom_ct ADD COLUMN state_abbr character varying (2);
ALTER TABLE census_2010.block_geom_dc ADD COLUMN state_abbr character varying (2);
ALTER TABLE census_2010.block_geom_de ADD COLUMN state_abbr character varying (2);
ALTER TABLE census_2010.block_geom_fl ADD COLUMN state_abbr character varying (2);
ALTER TABLE census_2010.block_geom_ga ADD COLUMN state_abbr character varying (2);
ALTER TABLE census_2010.block_geom_hi ADD COLUMN state_abbr character varying (2);
ALTER TABLE census_2010.block_geom_ia ADD COLUMN state_abbr character varying (2);
ALTER TABLE census_2010.block_geom_id ADD COLUMN state_abbr character varying (2);
ALTER TABLE census_2010.block_geom_mi ADD COLUMN state_abbr character varying (2);
ALTER TABLE census_2010.block_geom_nh ADD COLUMN state_abbr character varying (2);
ALTER TABLE census_2010.block_geom_nj ADD COLUMN state_abbr character varying (2);
ALTER TABLE census_2010.block_geom_il ADD COLUMN state_abbr character varying (2);
ALTER TABLE census_2010.block_geom_mn ADD COLUMN state_abbr character varying (2);
ALTER TABLE census_2010.block_geom_nm ADD COLUMN state_abbr character varying (2);
ALTER TABLE census_2010.block_geom_nv ADD COLUMN state_abbr character varying (2);
ALTER TABLE census_2010.block_geom_mo ADD COLUMN state_abbr character varying (2);
ALTER TABLE census_2010.block_geom_ny ADD COLUMN state_abbr character varying (2);
ALTER TABLE census_2010.block_geom_ms ADD COLUMN state_abbr character varying (2);
ALTER TABLE census_2010.block_geom_oh ADD COLUMN state_abbr character varying (2);
ALTER TABLE census_2010.block_geom_ks ADD COLUMN state_abbr character varying (2);
ALTER TABLE census_2010.block_geom_mt ADD COLUMN state_abbr character varying (2);
ALTER TABLE census_2010.block_geom_in ADD COLUMN state_abbr character varying (2);
ALTER TABLE census_2010.block_geom_ok ADD COLUMN state_abbr character varying (2);
ALTER TABLE census_2010.block_geom_ky ADD COLUMN state_abbr character varying (2);
ALTER TABLE census_2010.block_geom_nc ADD COLUMN state_abbr character varying (2);
ALTER TABLE census_2010.block_geom_or ADD COLUMN state_abbr character varying (2);
ALTER TABLE census_2010.block_geom_la ADD COLUMN state_abbr character varying (2);
ALTER TABLE census_2010.block_geom_nd ADD COLUMN state_abbr character varying (2);
ALTER TABLE census_2010.block_geom_ma ADD COLUMN state_abbr character varying (2);
ALTER TABLE census_2010.block_geom_pa ADD COLUMN state_abbr character varying (2);
ALTER TABLE census_2010.block_geom_ne ADD COLUMN state_abbr character varying (2);
ALTER TABLE census_2010.block_geom_md ADD COLUMN state_abbr character varying (2);
ALTER TABLE census_2010.block_geom_me ADD COLUMN state_abbr character varying (2);
ALTER TABLE census_2010.block_geom_pr ADD COLUMN state_abbr character varying (2);
ALTER TABLE census_2010.block_geom_ri ADD COLUMN state_abbr character varying (2);
ALTER TABLE census_2010.block_geom_sc ADD COLUMN state_abbr character varying (2);
ALTER TABLE census_2010.block_geom_sd ADD COLUMN state_abbr character varying (2);
ALTER TABLE census_2010.block_geom_tn ADD COLUMN state_abbr character varying (2);
ALTER TABLE census_2010.block_geom_tx ADD COLUMN state_abbr character varying (2);
ALTER TABLE census_2010.block_geom_ut ADD COLUMN state_abbr character varying (2);
ALTER TABLE census_2010.block_geom_va ADD COLUMN state_abbr character varying (2);
ALTER TABLE census_2010.block_geom_vt ADD COLUMN state_abbr character varying (2);
ALTER TABLE census_2010.block_geom_wa ADD COLUMN state_abbr character varying (2);
ALTER TABLE census_2010.block_geom_wi ADD COLUMN state_abbr character varying (2);
ALTER TABLE census_2010.block_geom_wv ADD COLUMN state_abbr character varying (2);
ALTER TABLE census_2010.block_geom_wy ADD COLUMN state_abbr character varying (2);

-- update the state abbr column
UPDATE census_2010.block_geom_al SET state_abbr = 'AL';
UPDATE census_2010.block_geom_ar SET state_abbr = 'AR';
UPDATE census_2010.block_geom_az SET state_abbr = 'AZ';
UPDATE census_2010.block_geom_ca SET state_abbr = 'CA';
UPDATE census_2010.block_geom_ak SET state_abbr = 'AK';
UPDATE census_2010.block_geom_co SET state_abbr = 'CO';
UPDATE census_2010.block_geom_ct SET state_abbr = 'CT';
UPDATE census_2010.block_geom_dc SET state_abbr = 'DC';
UPDATE census_2010.block_geom_de SET state_abbr = 'DE';
UPDATE census_2010.block_geom_fl SET state_abbr = 'FL';
UPDATE census_2010.block_geom_ga SET state_abbr = 'GA';
UPDATE census_2010.block_geom_hi SET state_abbr = 'HI';
UPDATE census_2010.block_geom_ia SET state_abbr = 'IA';
UPDATE census_2010.block_geom_id SET state_abbr = 'ID';
UPDATE census_2010.block_geom_mi SET state_abbr = 'MI';
UPDATE census_2010.block_geom_nh SET state_abbr = 'NH';
UPDATE census_2010.block_geom_nj SET state_abbr = 'NJ';
UPDATE census_2010.block_geom_il SET state_abbr = 'IL';
UPDATE census_2010.block_geom_mn SET state_abbr = 'MN';
UPDATE census_2010.block_geom_nm SET state_abbr = 'NM';
UPDATE census_2010.block_geom_nv SET state_abbr = 'NV';
UPDATE census_2010.block_geom_mo SET state_abbr = 'MO';
UPDATE census_2010.block_geom_ny SET state_abbr = 'NY';
UPDATE census_2010.block_geom_ms SET state_abbr = 'MS';
UPDATE census_2010.block_geom_oh SET state_abbr = 'OH';
UPDATE census_2010.block_geom_ks SET state_abbr = 'KS';
UPDATE census_2010.block_geom_mt SET state_abbr = 'MT';
UPDATE census_2010.block_geom_in SET state_abbr = 'IN';
UPDATE census_2010.block_geom_ok SET state_abbr = 'OK';
UPDATE census_2010.block_geom_ky SET state_abbr = 'KY';
UPDATE census_2010.block_geom_nc SET state_abbr = 'NC';
UPDATE census_2010.block_geom_or SET state_abbr = 'OR';
UPDATE census_2010.block_geom_la SET state_abbr = 'LA';
UPDATE census_2010.block_geom_nd SET state_abbr = 'ND';
UPDATE census_2010.block_geom_ma SET state_abbr = 'MA';
UPDATE census_2010.block_geom_pa SET state_abbr = 'PA';
UPDATE census_2010.block_geom_ne SET state_abbr = 'NE';
UPDATE census_2010.block_geom_md SET state_abbr = 'MD';
UPDATE census_2010.block_geom_me SET state_abbr = 'ME';
UPDATE census_2010.block_geom_pr SET state_abbr = 'PR';
UPDATE census_2010.block_geom_ri SET state_abbr = 'RI';
UPDATE census_2010.block_geom_sc SET state_abbr = 'SC';
UPDATE census_2010.block_geom_sd SET state_abbr = 'SD';
UPDATE census_2010.block_geom_tn SET state_abbr = 'TN';
UPDATE census_2010.block_geom_tx SET state_abbr = 'TX';
UPDATE census_2010.block_geom_ut SET state_abbr = 'UT';
UPDATE census_2010.block_geom_va SET state_abbr = 'VA';
UPDATE census_2010.block_geom_vt SET state_abbr = 'VT';
UPDATE census_2010.block_geom_wa SET state_abbr = 'WA';
UPDATE census_2010.block_geom_wi SET state_abbr = 'WI';
UPDATE census_2010.block_geom_wv SET state_abbr = 'WV';
UPDATE census_2010.block_geom_wy SET state_abbr = 'WY';

-- add a constraint on the table
ALTER TABLE census_2010.block_geom_al ADD CONSTRAINT block_geom_al_state_abbr_check CHECK (state_abbr = 'AL');
ALTER TABLE census_2010.block_geom_ar ADD CONSTRAINT block_geom_ar_state_abbr_check CHECK (state_abbr = 'AR');
ALTER TABLE census_2010.block_geom_az ADD CONSTRAINT block_geom_az_state_abbr_check CHECK (state_abbr = 'AZ');
ALTER TABLE census_2010.block_geom_ca ADD CONSTRAINT block_geom_ca_state_abbr_check CHECK (state_abbr = 'CA');
ALTER TABLE census_2010.block_geom_ak ADD CONSTRAINT block_geom_ak_state_abbr_check CHECK (state_abbr = 'AK');
ALTER TABLE census_2010.block_geom_co ADD CONSTRAINT block_geom_co_state_abbr_check CHECK (state_abbr = 'CO');
ALTER TABLE census_2010.block_geom_ct ADD CONSTRAINT block_geom_ct_state_abbr_check CHECK (state_abbr = 'CT');
ALTER TABLE census_2010.block_geom_dc ADD CONSTRAINT block_geom_dc_state_abbr_check CHECK (state_abbr = 'DC');
ALTER TABLE census_2010.block_geom_de ADD CONSTRAINT block_geom_de_state_abbr_check CHECK (state_abbr = 'DE');
ALTER TABLE census_2010.block_geom_fl ADD CONSTRAINT block_geom_fl_state_abbr_check CHECK (state_abbr = 'FL');
ALTER TABLE census_2010.block_geom_ga ADD CONSTRAINT block_geom_ga_state_abbr_check CHECK (state_abbr = 'GA');
ALTER TABLE census_2010.block_geom_hi ADD CONSTRAINT block_geom_hi_state_abbr_check CHECK (state_abbr = 'HI');
ALTER TABLE census_2010.block_geom_ia ADD CONSTRAINT block_geom_ia_state_abbr_check CHECK (state_abbr = 'IA');
ALTER TABLE census_2010.block_geom_id ADD CONSTRAINT block_geom_id_state_abbr_check CHECK (state_abbr = 'ID');
ALTER TABLE census_2010.block_geom_mi ADD CONSTRAINT block_geom_mi_state_abbr_check CHECK (state_abbr = 'MI');
ALTER TABLE census_2010.block_geom_nh ADD CONSTRAINT block_geom_nh_state_abbr_check CHECK (state_abbr = 'NH');
ALTER TABLE census_2010.block_geom_nj ADD CONSTRAINT block_geom_nj_state_abbr_check CHECK (state_abbr = 'NJ');
ALTER TABLE census_2010.block_geom_il ADD CONSTRAINT block_geom_il_state_abbr_check CHECK (state_abbr = 'IL');
ALTER TABLE census_2010.block_geom_mn ADD CONSTRAINT block_geom_mn_state_abbr_check CHECK (state_abbr = 'MN');
ALTER TABLE census_2010.block_geom_nm ADD CONSTRAINT block_geom_nm_state_abbr_check CHECK (state_abbr = 'NM');
ALTER TABLE census_2010.block_geom_nv ADD CONSTRAINT block_geom_nv_state_abbr_check CHECK (state_abbr = 'NV');
ALTER TABLE census_2010.block_geom_mo ADD CONSTRAINT block_geom_mo_state_abbr_check CHECK (state_abbr = 'MO');
ALTER TABLE census_2010.block_geom_ny ADD CONSTRAINT block_geom_ny_state_abbr_check CHECK (state_abbr = 'NY');
ALTER TABLE census_2010.block_geom_ms ADD CONSTRAINT block_geom_ms_state_abbr_check CHECK (state_abbr = 'MS');
ALTER TABLE census_2010.block_geom_oh ADD CONSTRAINT block_geom_oh_state_abbr_check CHECK (state_abbr = 'OH');
ALTER TABLE census_2010.block_geom_ks ADD CONSTRAINT block_geom_ks_state_abbr_check CHECK (state_abbr = 'KS');
ALTER TABLE census_2010.block_geom_mt ADD CONSTRAINT block_geom_mt_state_abbr_check CHECK (state_abbr = 'MT');
ALTER TABLE census_2010.block_geom_in ADD CONSTRAINT block_geom_in_state_abbr_check CHECK (state_abbr = 'IN');
ALTER TABLE census_2010.block_geom_ok ADD CONSTRAINT block_geom_ok_state_abbr_check CHECK (state_abbr = 'OK');
ALTER TABLE census_2010.block_geom_ky ADD CONSTRAINT block_geom_ky_state_abbr_check CHECK (state_abbr = 'KY');
ALTER TABLE census_2010.block_geom_nc ADD CONSTRAINT block_geom_nc_state_abbr_check CHECK (state_abbr = 'NC');
ALTER TABLE census_2010.block_geom_or ADD CONSTRAINT block_geom_or_state_abbr_check CHECK (state_abbr = 'OR');
ALTER TABLE census_2010.block_geom_la ADD CONSTRAINT block_geom_la_state_abbr_check CHECK (state_abbr = 'LA');
ALTER TABLE census_2010.block_geom_nd ADD CONSTRAINT block_geom_nd_state_abbr_check CHECK (state_abbr = 'ND');
ALTER TABLE census_2010.block_geom_ma ADD CONSTRAINT block_geom_ma_state_abbr_check CHECK (state_abbr = 'MA');
ALTER TABLE census_2010.block_geom_pa ADD CONSTRAINT block_geom_pa_state_abbr_check CHECK (state_abbr = 'PA');
ALTER TABLE census_2010.block_geom_ne ADD CONSTRAINT block_geom_ne_state_abbr_check CHECK (state_abbr = 'NE');
ALTER TABLE census_2010.block_geom_md ADD CONSTRAINT block_geom_md_state_abbr_check CHECK (state_abbr = 'MD');
ALTER TABLE census_2010.block_geom_me ADD CONSTRAINT block_geom_me_state_abbr_check CHECK (state_abbr = 'ME');
ALTER TABLE census_2010.block_geom_pr ADD CONSTRAINT block_geom_pr_state_abbr_check CHECK (state_abbr = 'PR');
ALTER TABLE census_2010.block_geom_ri ADD CONSTRAINT block_geom_ri_state_abbr_check CHECK (state_abbr = 'RI');
ALTER TABLE census_2010.block_geom_sc ADD CONSTRAINT block_geom_sc_state_abbr_check CHECK (state_abbr = 'SC');
ALTER TABLE census_2010.block_geom_sd ADD CONSTRAINT block_geom_sd_state_abbr_check CHECK (state_abbr = 'SD');
ALTER TABLE census_2010.block_geom_tn ADD CONSTRAINT block_geom_tn_state_abbr_check CHECK (state_abbr = 'TN');
ALTER TABLE census_2010.block_geom_tx ADD CONSTRAINT block_geom_tx_state_abbr_check CHECK (state_abbr = 'TX');
ALTER TABLE census_2010.block_geom_ut ADD CONSTRAINT block_geom_ut_state_abbr_check CHECK (state_abbr = 'UT');
ALTER TABLE census_2010.block_geom_va ADD CONSTRAINT block_geom_va_state_abbr_check CHECK (state_abbr = 'VA');
ALTER TABLE census_2010.block_geom_vt ADD CONSTRAINT block_geom_vt_state_abbr_check CHECK (state_abbr = 'VT');
ALTER TABLE census_2010.block_geom_wa ADD CONSTRAINT block_geom_wa_state_abbr_check CHECK (state_abbr = 'WA');
ALTER TABLE census_2010.block_geom_wi ADD CONSTRAINT block_geom_wi_state_abbr_check CHECK (state_abbr = 'WI');
ALTER TABLE census_2010.block_geom_wv ADD CONSTRAINT block_geom_wv_state_abbr_check CHECK (state_abbr = 'WV');
ALTER TABLE census_2010.block_geom_wy ADD CONSTRAINT block_geom_wy_state_abbr_check CHECK (state_abbr = 'WY');

-- add a constraint on the fips code too
ALTER TABLE census_2010.block_geom_al ADD CONSTRAINT block_geom_al_state_fips_check CHECK (statefp10 = '01');
ALTER TABLE census_2010.block_geom_ar ADD CONSTRAINT block_geom_ar_state_fips_check CHECK (statefp10 = '05');
ALTER TABLE census_2010.block_geom_az ADD CONSTRAINT block_geom_az_state_fips_check CHECK (statefp10 = '04');
ALTER TABLE census_2010.block_geom_ca ADD CONSTRAINT block_geom_ca_state_fips_check CHECK (statefp10 = '06');
ALTER TABLE census_2010.block_geom_ak ADD CONSTRAINT block_geom_ak_state_fips_check CHECK (statefp10 = '02');
ALTER TABLE census_2010.block_geom_co ADD CONSTRAINT block_geom_co_state_fips_check CHECK (statefp10 = '08');
ALTER TABLE census_2010.block_geom_ct ADD CONSTRAINT block_geom_ct_state_fips_check CHECK (statefp10 = '09');
ALTER TABLE census_2010.block_geom_dc ADD CONSTRAINT block_geom_dc_state_fips_check CHECK (statefp10 = '11');
ALTER TABLE census_2010.block_geom_de ADD CONSTRAINT block_geom_de_state_fips_check CHECK (statefp10 = '10');
ALTER TABLE census_2010.block_geom_fl ADD CONSTRAINT block_geom_fl_state_fips_check CHECK (statefp10 = '12');
ALTER TABLE census_2010.block_geom_ga ADD CONSTRAINT block_geom_ga_state_fips_check CHECK (statefp10 = '13');
ALTER TABLE census_2010.block_geom_hi ADD CONSTRAINT block_geom_hi_state_fips_check CHECK (statefp10 = '15');
ALTER TABLE census_2010.block_geom_ia ADD CONSTRAINT block_geom_ia_state_fips_check CHECK (statefp10 = '19');
ALTER TABLE census_2010.block_geom_id ADD CONSTRAINT block_geom_id_state_fips_check CHECK (statefp10 = '16');
ALTER TABLE census_2010.block_geom_mi ADD CONSTRAINT block_geom_mi_state_fips_check CHECK (statefp10 = '26');
ALTER TABLE census_2010.block_geom_nh ADD CONSTRAINT block_geom_nh_state_fips_check CHECK (statefp10 = '33');
ALTER TABLE census_2010.block_geom_nj ADD CONSTRAINT block_geom_nj_state_fips_check CHECK (statefp10 = '34');
ALTER TABLE census_2010.block_geom_il ADD CONSTRAINT block_geom_il_state_fips_check CHECK (statefp10 = '17');
ALTER TABLE census_2010.block_geom_mn ADD CONSTRAINT block_geom_mn_state_fips_check CHECK (statefp10 = '27');
ALTER TABLE census_2010.block_geom_nm ADD CONSTRAINT block_geom_nm_state_fips_check CHECK (statefp10 = '35');
ALTER TABLE census_2010.block_geom_nv ADD CONSTRAINT block_geom_nv_state_fips_check CHECK (statefp10 = '32');
ALTER TABLE census_2010.block_geom_mo ADD CONSTRAINT block_geom_mo_state_fips_check CHECK (statefp10 = '29');
ALTER TABLE census_2010.block_geom_ny ADD CONSTRAINT block_geom_ny_state_fips_check CHECK (statefp10 = '36');
ALTER TABLE census_2010.block_geom_ms ADD CONSTRAINT block_geom_ms_state_fips_check CHECK (statefp10 = '28');
ALTER TABLE census_2010.block_geom_oh ADD CONSTRAINT block_geom_oh_state_fips_check CHECK (statefp10 = '39');
ALTER TABLE census_2010.block_geom_ks ADD CONSTRAINT block_geom_ks_state_fips_check CHECK (statefp10 = '20');
ALTER TABLE census_2010.block_geom_mt ADD CONSTRAINT block_geom_mt_state_fips_check CHECK (statefp10 = '30');
ALTER TABLE census_2010.block_geom_in ADD CONSTRAINT block_geom_in_state_fips_check CHECK (statefp10 = '18');
ALTER TABLE census_2010.block_geom_ok ADD CONSTRAINT block_geom_ok_state_fips_check CHECK (statefp10 = '40');
ALTER TABLE census_2010.block_geom_ky ADD CONSTRAINT block_geom_ky_state_fips_check CHECK (statefp10 = '21');
ALTER TABLE census_2010.block_geom_nc ADD CONSTRAINT block_geom_nc_state_fips_check CHECK (statefp10 = '37');
ALTER TABLE census_2010.block_geom_or ADD CONSTRAINT block_geom_or_state_fips_check CHECK (statefp10 = '41');
ALTER TABLE census_2010.block_geom_la ADD CONSTRAINT block_geom_la_state_fips_check CHECK (statefp10 = '22');
ALTER TABLE census_2010.block_geom_nd ADD CONSTRAINT block_geom_nd_state_fips_check CHECK (statefp10 = '38');
ALTER TABLE census_2010.block_geom_ma ADD CONSTRAINT block_geom_ma_state_fips_check CHECK (statefp10 = '25');
ALTER TABLE census_2010.block_geom_pa ADD CONSTRAINT block_geom_pa_state_fips_check CHECK (statefp10 = '42');
ALTER TABLE census_2010.block_geom_ne ADD CONSTRAINT block_geom_ne_state_fips_check CHECK (statefp10 = '31');
ALTER TABLE census_2010.block_geom_md ADD CONSTRAINT block_geom_md_state_fips_check CHECK (statefp10 = '24');
ALTER TABLE census_2010.block_geom_me ADD CONSTRAINT block_geom_me_state_fips_check CHECK (statefp10 = '23');
ALTER TABLE census_2010.block_geom_pr ADD CONSTRAINT block_geom_pr_state_fips_check CHECK (statefp10 = '72');
ALTER TABLE census_2010.block_geom_ri ADD CONSTRAINT block_geom_ri_state_fips_check CHECK (statefp10 = '44');
ALTER TABLE census_2010.block_geom_sc ADD CONSTRAINT block_geom_sc_state_fips_check CHECK (statefp10 = '45');
ALTER TABLE census_2010.block_geom_sd ADD CONSTRAINT block_geom_sd_state_fips_check CHECK (statefp10 = '46');
ALTER TABLE census_2010.block_geom_tn ADD CONSTRAINT block_geom_tn_state_fips_check CHECK (statefp10 = '47');
ALTER TABLE census_2010.block_geom_tx ADD CONSTRAINT block_geom_tx_state_fips_check CHECK (statefp10 = '48');
ALTER TABLE census_2010.block_geom_ut ADD CONSTRAINT block_geom_ut_state_fips_check CHECK (statefp10 = '49');
ALTER TABLE census_2010.block_geom_va ADD CONSTRAINT block_geom_va_state_fips_check CHECK (statefp10 = '51');
ALTER TABLE census_2010.block_geom_vt ADD CONSTRAINT block_geom_vt_state_fips_check CHECK (statefp10 = '50');
ALTER TABLE census_2010.block_geom_wa ADD CONSTRAINT block_geom_wa_state_fips_check CHECK (statefp10 = '53');
ALTER TABLE census_2010.block_geom_wi ADD CONSTRAINT block_geom_wi_state_fips_check CHECK (statefp10 = '55');
ALTER TABLE census_2010.block_geom_wv ADD CONSTRAINT block_geom_wv_state_fips_check CHECK (statefp10 = '54');
ALTER TABLE census_2010.block_geom_wy ADD CONSTRAINT block_geom_wy_state_fips_check CHECK (statefp10 = '56');

-- do some simple housecleaning for column consistency
-- add uatyp10 character varying(1) to all tables (some tables already have it) -- run these in psql
BEGIN;ALTER TABLE census_2010.block_geom_al ADD COLUMN uatyp10 character varying(1);COMMIT;
BEGIN;ALTER TABLE census_2010.block_geom_ar ADD COLUMN uatyp10 character varying(1);COMMIT;
BEGIN;ALTER TABLE census_2010.block_geom_az ADD COLUMN uatyp10 character varying(1);COMMIT;
BEGIN;ALTER TABLE census_2010.block_geom_ca ADD COLUMN uatyp10 character varying(1);COMMIT;
BEGIN;ALTER TABLE census_2010.block_geom_ak ADD COLUMN uatyp10 character varying(1);COMMIT;
BEGIN;ALTER TABLE census_2010.block_geom_co ADD COLUMN uatyp10 character varying(1);COMMIT;
BEGIN;ALTER TABLE census_2010.block_geom_ct ADD COLUMN uatyp10 character varying(1);COMMIT;
BEGIN;ALTER TABLE census_2010.block_geom_dc ADD COLUMN uatyp10 character varying(1);COMMIT;
BEGIN;ALTER TABLE census_2010.block_geom_de ADD COLUMN uatyp10 character varying(1);COMMIT;
BEGIN;ALTER TABLE census_2010.block_geom_fl ADD COLUMN uatyp10 character varying(1);COMMIT;
BEGIN;ALTER TABLE census_2010.block_geom_ga ADD COLUMN uatyp10 character varying(1);COMMIT;
BEGIN;ALTER TABLE census_2010.block_geom_hi ADD COLUMN uatyp10 character varying(1);COMMIT;
BEGIN;ALTER TABLE census_2010.block_geom_ia ADD COLUMN uatyp10 character varying(1);COMMIT;
BEGIN;ALTER TABLE census_2010.block_geom_id ADD COLUMN uatyp10 character varying(1);COMMIT;
BEGIN;ALTER TABLE census_2010.block_geom_mi ADD COLUMN uatyp10 character varying(1);COMMIT;
BEGIN;ALTER TABLE census_2010.block_geom_nh ADD COLUMN uatyp10 character varying(1);COMMIT;
BEGIN;ALTER TABLE census_2010.block_geom_nj ADD COLUMN uatyp10 character varying(1);COMMIT;
BEGIN;ALTER TABLE census_2010.block_geom_il ADD COLUMN uatyp10 character varying(1);COMMIT;
BEGIN;ALTER TABLE census_2010.block_geom_mn ADD COLUMN uatyp10 character varying(1);COMMIT;
BEGIN;ALTER TABLE census_2010.block_geom_nm ADD COLUMN uatyp10 character varying(1);COMMIT;
BEGIN;ALTER TABLE census_2010.block_geom_nv ADD COLUMN uatyp10 character varying(1);COMMIT;
BEGIN;ALTER TABLE census_2010.block_geom_mo ADD COLUMN uatyp10 character varying(1);COMMIT;
BEGIN;ALTER TABLE census_2010.block_geom_ny ADD COLUMN uatyp10 character varying(1);COMMIT;
BEGIN;ALTER TABLE census_2010.block_geom_ms ADD COLUMN uatyp10 character varying(1);COMMIT;
BEGIN;ALTER TABLE census_2010.block_geom_oh ADD COLUMN uatyp10 character varying(1);COMMIT;
BEGIN;ALTER TABLE census_2010.block_geom_ks ADD COLUMN uatyp10 character varying(1);COMMIT;
BEGIN;ALTER TABLE census_2010.block_geom_mt ADD COLUMN uatyp10 character varying(1);COMMIT;
BEGIN;ALTER TABLE census_2010.block_geom_in ADD COLUMN uatyp10 character varying(1);COMMIT;
BEGIN;ALTER TABLE census_2010.block_geom_ok ADD COLUMN uatyp10 character varying(1);COMMIT;
BEGIN;ALTER TABLE census_2010.block_geom_ky ADD COLUMN uatyp10 character varying(1);COMMIT;
BEGIN;ALTER TABLE census_2010.block_geom_nc ADD COLUMN uatyp10 character varying(1);COMMIT;
BEGIN;ALTER TABLE census_2010.block_geom_or ADD COLUMN uatyp10 character varying(1);COMMIT;
BEGIN;ALTER TABLE census_2010.block_geom_la ADD COLUMN uatyp10 character varying(1);COMMIT;
BEGIN;ALTER TABLE census_2010.block_geom_nd ADD COLUMN uatyp10 character varying(1);COMMIT;
BEGIN;ALTER TABLE census_2010.block_geom_ma ADD COLUMN uatyp10 character varying(1);COMMIT;
BEGIN;ALTER TABLE census_2010.block_geom_pa ADD COLUMN uatyp10 character varying(1);COMMIT;
BEGIN;ALTER TABLE census_2010.block_geom_ne ADD COLUMN uatyp10 character varying(1);COMMIT;
BEGIN;ALTER TABLE census_2010.block_geom_md ADD COLUMN uatyp10 character varying(1);COMMIT;
BEGIN;ALTER TABLE census_2010.block_geom_me ADD COLUMN uatyp10 character varying(1);COMMIT;
BEGIN;ALTER TABLE census_2010.block_geom_pr ADD COLUMN uatyp10 character varying(1);COMMIT;
BEGIN;ALTER TABLE census_2010.block_geom_ri ADD COLUMN uatyp10 character varying(1);COMMIT;
BEGIN;ALTER TABLE census_2010.block_geom_sc ADD COLUMN uatyp10 character varying(1);COMMIT;
BEGIN;ALTER TABLE census_2010.block_geom_sd ADD COLUMN uatyp10 character varying(1);COMMIT;
BEGIN;ALTER TABLE census_2010.block_geom_tn ADD COLUMN uatyp10 character varying(1);COMMIT;
BEGIN;ALTER TABLE census_2010.block_geom_tx ADD COLUMN uatyp10 character varying(1);COMMIT;
BEGIN;ALTER TABLE census_2010.block_geom_ut ADD COLUMN uatyp10 character varying(1);COMMIT;
BEGIN;ALTER TABLE census_2010.block_geom_va ADD COLUMN uatyp10 character varying(1);COMMIT;
BEGIN;ALTER TABLE census_2010.block_geom_vt ADD COLUMN uatyp10 character varying(1);COMMIT;
BEGIN;ALTER TABLE census_2010.block_geom_wa ADD COLUMN uatyp10 character varying(1);COMMIT;
BEGIN;ALTER TABLE census_2010.block_geom_wi ADD COLUMN uatyp10 character varying(1);COMMIT;
BEGIN;ALTER TABLE census_2010.block_geom_wv ADD COLUMN uatyp10 character varying(1);COMMIT;
BEGIN;ALTER TABLE census_2010.block_geom_wy ADD COLUMN uatyp10 character varying(1);COMMIT;

-- change type of aland10 to always be numeric
ALTER TABLE census_2010.block_geom_al ALTER COLUMN aland10 TYPE numeric using aland10::numeric;
ALTER TABLE census_2010.block_geom_ar ALTER COLUMN aland10 TYPE numeric using aland10::numeric;
ALTER TABLE census_2010.block_geom_az ALTER COLUMN aland10 TYPE numeric using aland10::numeric;
ALTER TABLE census_2010.block_geom_ca ALTER COLUMN aland10 TYPE numeric using aland10::numeric;
ALTER TABLE census_2010.block_geom_ak ALTER COLUMN aland10 TYPE numeric using aland10::numeric;
ALTER TABLE census_2010.block_geom_co ALTER COLUMN aland10 TYPE numeric using aland10::numeric;
ALTER TABLE census_2010.block_geom_ct ALTER COLUMN aland10 TYPE numeric using aland10::numeric;
ALTER TABLE census_2010.block_geom_dc ALTER COLUMN aland10 TYPE numeric using aland10::numeric;
ALTER TABLE census_2010.block_geom_de ALTER COLUMN aland10 TYPE numeric using aland10::numeric;
ALTER TABLE census_2010.block_geom_fl ALTER COLUMN aland10 TYPE numeric using aland10::numeric;
ALTER TABLE census_2010.block_geom_ga ALTER COLUMN aland10 TYPE numeric using aland10::numeric;
ALTER TABLE census_2010.block_geom_hi ALTER COLUMN aland10 TYPE numeric using aland10::numeric;
ALTER TABLE census_2010.block_geom_ia ALTER COLUMN aland10 TYPE numeric using aland10::numeric;
ALTER TABLE census_2010.block_geom_id ALTER COLUMN aland10 TYPE numeric using aland10::numeric;
ALTER TABLE census_2010.block_geom_mi ALTER COLUMN aland10 TYPE numeric using aland10::numeric;
ALTER TABLE census_2010.block_geom_nh ALTER COLUMN aland10 TYPE numeric using aland10::numeric;
ALTER TABLE census_2010.block_geom_nj ALTER COLUMN aland10 TYPE numeric using aland10::numeric;
ALTER TABLE census_2010.block_geom_il ALTER COLUMN aland10 TYPE numeric using aland10::numeric;
ALTER TABLE census_2010.block_geom_mn ALTER COLUMN aland10 TYPE numeric using aland10::numeric;
ALTER TABLE census_2010.block_geom_nm ALTER COLUMN aland10 TYPE numeric using aland10::numeric;
ALTER TABLE census_2010.block_geom_nv ALTER COLUMN aland10 TYPE numeric using aland10::numeric;
ALTER TABLE census_2010.block_geom_mo ALTER COLUMN aland10 TYPE numeric using aland10::numeric;
ALTER TABLE census_2010.block_geom_ny ALTER COLUMN aland10 TYPE numeric using aland10::numeric;
ALTER TABLE census_2010.block_geom_ms ALTER COLUMN aland10 TYPE numeric using aland10::numeric;
ALTER TABLE census_2010.block_geom_oh ALTER COLUMN aland10 TYPE numeric using aland10::numeric;
ALTER TABLE census_2010.block_geom_ks ALTER COLUMN aland10 TYPE numeric using aland10::numeric;
ALTER TABLE census_2010.block_geom_mt ALTER COLUMN aland10 TYPE numeric using aland10::numeric;
ALTER TABLE census_2010.block_geom_in ALTER COLUMN aland10 TYPE numeric using aland10::numeric;
ALTER TABLE census_2010.block_geom_ok ALTER COLUMN aland10 TYPE numeric using aland10::numeric;
ALTER TABLE census_2010.block_geom_ky ALTER COLUMN aland10 TYPE numeric using aland10::numeric;
ALTER TABLE census_2010.block_geom_nc ALTER COLUMN aland10 TYPE numeric using aland10::numeric;
ALTER TABLE census_2010.block_geom_or ALTER COLUMN aland10 TYPE numeric using aland10::numeric;
ALTER TABLE census_2010.block_geom_la ALTER COLUMN aland10 TYPE numeric using aland10::numeric;
ALTER TABLE census_2010.block_geom_nd ALTER COLUMN aland10 TYPE numeric using aland10::numeric;
ALTER TABLE census_2010.block_geom_ma ALTER COLUMN aland10 TYPE numeric using aland10::numeric;
ALTER TABLE census_2010.block_geom_pa ALTER COLUMN aland10 TYPE numeric using aland10::numeric;
ALTER TABLE census_2010.block_geom_ne ALTER COLUMN aland10 TYPE numeric using aland10::numeric;
ALTER TABLE census_2010.block_geom_md ALTER COLUMN aland10 TYPE numeric using aland10::numeric;
ALTER TABLE census_2010.block_geom_me ALTER COLUMN aland10 TYPE numeric using aland10::numeric;
ALTER TABLE census_2010.block_geom_pr ALTER COLUMN aland10 TYPE numeric using aland10::numeric;
ALTER TABLE census_2010.block_geom_ri ALTER COLUMN aland10 TYPE numeric using aland10::numeric;
ALTER TABLE census_2010.block_geom_sc ALTER COLUMN aland10 TYPE numeric using aland10::numeric;
ALTER TABLE census_2010.block_geom_sd ALTER COLUMN aland10 TYPE numeric using aland10::numeric;
ALTER TABLE census_2010.block_geom_tn ALTER COLUMN aland10 TYPE numeric using aland10::numeric;
ALTER TABLE census_2010.block_geom_tx ALTER COLUMN aland10 TYPE numeric using aland10::numeric;
ALTER TABLE census_2010.block_geom_ut ALTER COLUMN aland10 TYPE numeric using aland10::numeric;
ALTER TABLE census_2010.block_geom_va ALTER COLUMN aland10 TYPE numeric using aland10::numeric;
ALTER TABLE census_2010.block_geom_vt ALTER COLUMN aland10 TYPE numeric using aland10::numeric;
ALTER TABLE census_2010.block_geom_wa ALTER COLUMN aland10 TYPE numeric using aland10::numeric;
ALTER TABLE census_2010.block_geom_wi ALTER COLUMN aland10 TYPE numeric using aland10::numeric;
ALTER TABLE census_2010.block_geom_wv ALTER COLUMN aland10 TYPE numeric using aland10::numeric;
ALTER TABLE census_2010.block_geom_wy ALTER COLUMN aland10 TYPE numeric using aland10::numeric;

-- same for awater10
ALTER TABLE census_2010.block_geom_al ALTER COLUMN awater10 TYPE numeric using awater10::numeric;
ALTER TABLE census_2010.block_geom_ar ALTER COLUMN awater10 TYPE numeric using awater10::numeric;
ALTER TABLE census_2010.block_geom_az ALTER COLUMN awater10 TYPE numeric using awater10::numeric;
ALTER TABLE census_2010.block_geom_ca ALTER COLUMN awater10 TYPE numeric using awater10::numeric;
ALTER TABLE census_2010.block_geom_ak ALTER COLUMN awater10 TYPE numeric using awater10::numeric;
ALTER TABLE census_2010.block_geom_co ALTER COLUMN awater10 TYPE numeric using awater10::numeric;
ALTER TABLE census_2010.block_geom_ct ALTER COLUMN awater10 TYPE numeric using awater10::numeric;
ALTER TABLE census_2010.block_geom_dc ALTER COLUMN awater10 TYPE numeric using awater10::numeric;
ALTER TABLE census_2010.block_geom_de ALTER COLUMN awater10 TYPE numeric using awater10::numeric;
ALTER TABLE census_2010.block_geom_fl ALTER COLUMN awater10 TYPE numeric using awater10::numeric;
ALTER TABLE census_2010.block_geom_ga ALTER COLUMN awater10 TYPE numeric using awater10::numeric;
ALTER TABLE census_2010.block_geom_hi ALTER COLUMN awater10 TYPE numeric using awater10::numeric;
ALTER TABLE census_2010.block_geom_ia ALTER COLUMN awater10 TYPE numeric using awater10::numeric;
ALTER TABLE census_2010.block_geom_id ALTER COLUMN awater10 TYPE numeric using awater10::numeric;
ALTER TABLE census_2010.block_geom_mi ALTER COLUMN awater10 TYPE numeric using awater10::numeric;
ALTER TABLE census_2010.block_geom_nh ALTER COLUMN awater10 TYPE numeric using awater10::numeric;
ALTER TABLE census_2010.block_geom_nj ALTER COLUMN awater10 TYPE numeric using awater10::numeric;
ALTER TABLE census_2010.block_geom_il ALTER COLUMN awater10 TYPE numeric using awater10::numeric;
ALTER TABLE census_2010.block_geom_mn ALTER COLUMN awater10 TYPE numeric using awater10::numeric;
ALTER TABLE census_2010.block_geom_nm ALTER COLUMN awater10 TYPE numeric using awater10::numeric;
ALTER TABLE census_2010.block_geom_nv ALTER COLUMN awater10 TYPE numeric using awater10::numeric;
ALTER TABLE census_2010.block_geom_mo ALTER COLUMN awater10 TYPE numeric using awater10::numeric;
ALTER TABLE census_2010.block_geom_ny ALTER COLUMN awater10 TYPE numeric using awater10::numeric;
ALTER TABLE census_2010.block_geom_ms ALTER COLUMN awater10 TYPE numeric using awater10::numeric;
ALTER TABLE census_2010.block_geom_oh ALTER COLUMN awater10 TYPE numeric using awater10::numeric;
ALTER TABLE census_2010.block_geom_ks ALTER COLUMN awater10 TYPE numeric using awater10::numeric;
ALTER TABLE census_2010.block_geom_mt ALTER COLUMN awater10 TYPE numeric using awater10::numeric;
ALTER TABLE census_2010.block_geom_in ALTER COLUMN awater10 TYPE numeric using awater10::numeric;
ALTER TABLE census_2010.block_geom_ok ALTER COLUMN awater10 TYPE numeric using awater10::numeric;
ALTER TABLE census_2010.block_geom_ky ALTER COLUMN awater10 TYPE numeric using awater10::numeric;
ALTER TABLE census_2010.block_geom_nc ALTER COLUMN awater10 TYPE numeric using awater10::numeric;
ALTER TABLE census_2010.block_geom_or ALTER COLUMN awater10 TYPE numeric using awater10::numeric;
ALTER TABLE census_2010.block_geom_la ALTER COLUMN awater10 TYPE numeric using awater10::numeric;
ALTER TABLE census_2010.block_geom_nd ALTER COLUMN awater10 TYPE numeric using awater10::numeric;
ALTER TABLE census_2010.block_geom_ma ALTER COLUMN awater10 TYPE numeric using awater10::numeric;
ALTER TABLE census_2010.block_geom_pa ALTER COLUMN awater10 TYPE numeric using awater10::numeric;
ALTER TABLE census_2010.block_geom_ne ALTER COLUMN awater10 TYPE numeric using awater10::numeric;
ALTER TABLE census_2010.block_geom_md ALTER COLUMN awater10 TYPE numeric using awater10::numeric;
ALTER TABLE census_2010.block_geom_me ALTER COLUMN awater10 TYPE numeric using awater10::numeric;
ALTER TABLE census_2010.block_geom_pr ALTER COLUMN awater10 TYPE numeric using awater10::numeric;
ALTER TABLE census_2010.block_geom_ri ALTER COLUMN awater10 TYPE numeric using awater10::numeric;
ALTER TABLE census_2010.block_geom_sc ALTER COLUMN awater10 TYPE numeric using awater10::numeric;
ALTER TABLE census_2010.block_geom_sd ALTER COLUMN awater10 TYPE numeric using awater10::numeric;
ALTER TABLE census_2010.block_geom_tn ALTER COLUMN awater10 TYPE numeric using awater10::numeric;
ALTER TABLE census_2010.block_geom_tx ALTER COLUMN awater10 TYPE numeric using awater10::numeric;
ALTER TABLE census_2010.block_geom_ut ALTER COLUMN awater10 TYPE numeric using awater10::numeric;
ALTER TABLE census_2010.block_geom_va ALTER COLUMN awater10 TYPE numeric using awater10::numeric;
ALTER TABLE census_2010.block_geom_vt ALTER COLUMN awater10 TYPE numeric using awater10::numeric;
ALTER TABLE census_2010.block_geom_wa ALTER COLUMN awater10 TYPE numeric using awater10::numeric;
ALTER TABLE census_2010.block_geom_wi ALTER COLUMN awater10 TYPE numeric using awater10::numeric;
ALTER TABLE census_2010.block_geom_wv ALTER COLUMN awater10 TYPE numeric using awater10::numeric;
ALTER TABLE census_2010.block_geom_wy ALTER COLUMN awater10 TYPE numeric using awater10::numeric;

-- standardize length of gisjoin column
ALTER TABLE census_2010.block_geom_al ALTER COLUMN gisjoin TYPE CHARACTER VARYING(18);
ALTER TABLE census_2010.block_geom_ar ALTER COLUMN gisjoin TYPE CHARACTER VARYING(18);
ALTER TABLE census_2010.block_geom_az ALTER COLUMN gisjoin TYPE CHARACTER VARYING(18);
ALTER TABLE census_2010.block_geom_ca ALTER COLUMN gisjoin TYPE CHARACTER VARYING(18);
ALTER TABLE census_2010.block_geom_ak ALTER COLUMN gisjoin TYPE CHARACTER VARYING(18);
ALTER TABLE census_2010.block_geom_co ALTER COLUMN gisjoin TYPE CHARACTER VARYING(18);
ALTER TABLE census_2010.block_geom_ct ALTER COLUMN gisjoin TYPE CHARACTER VARYING(18);
ALTER TABLE census_2010.block_geom_dc ALTER COLUMN gisjoin TYPE CHARACTER VARYING(18);
ALTER TABLE census_2010.block_geom_de ALTER COLUMN gisjoin TYPE CHARACTER VARYING(18);
ALTER TABLE census_2010.block_geom_fl ALTER COLUMN gisjoin TYPE CHARACTER VARYING(18);
ALTER TABLE census_2010.block_geom_ga ALTER COLUMN gisjoin TYPE CHARACTER VARYING(18);
ALTER TABLE census_2010.block_geom_hi ALTER COLUMN gisjoin TYPE CHARACTER VARYING(18);
ALTER TABLE census_2010.block_geom_ia ALTER COLUMN gisjoin TYPE CHARACTER VARYING(18);
ALTER TABLE census_2010.block_geom_id ALTER COLUMN gisjoin TYPE CHARACTER VARYING(18);
ALTER TABLE census_2010.block_geom_mi ALTER COLUMN gisjoin TYPE CHARACTER VARYING(18);
ALTER TABLE census_2010.block_geom_nh ALTER COLUMN gisjoin TYPE CHARACTER VARYING(18);
ALTER TABLE census_2010.block_geom_nj ALTER COLUMN gisjoin TYPE CHARACTER VARYING(18);
ALTER TABLE census_2010.block_geom_il ALTER COLUMN gisjoin TYPE CHARACTER VARYING(18);
ALTER TABLE census_2010.block_geom_mn ALTER COLUMN gisjoin TYPE CHARACTER VARYING(18);
ALTER TABLE census_2010.block_geom_nm ALTER COLUMN gisjoin TYPE CHARACTER VARYING(18);
ALTER TABLE census_2010.block_geom_nv ALTER COLUMN gisjoin TYPE CHARACTER VARYING(18);
ALTER TABLE census_2010.block_geom_mo ALTER COLUMN gisjoin TYPE CHARACTER VARYING(18);
ALTER TABLE census_2010.block_geom_ny ALTER COLUMN gisjoin TYPE CHARACTER VARYING(18);
ALTER TABLE census_2010.block_geom_ms ALTER COLUMN gisjoin TYPE CHARACTER VARYING(18);
ALTER TABLE census_2010.block_geom_oh ALTER COLUMN gisjoin TYPE CHARACTER VARYING(18);
ALTER TABLE census_2010.block_geom_ks ALTER COLUMN gisjoin TYPE CHARACTER VARYING(18);
ALTER TABLE census_2010.block_geom_mt ALTER COLUMN gisjoin TYPE CHARACTER VARYING(18);
ALTER TABLE census_2010.block_geom_in ALTER COLUMN gisjoin TYPE CHARACTER VARYING(18);
ALTER TABLE census_2010.block_geom_ok ALTER COLUMN gisjoin TYPE CHARACTER VARYING(18);
ALTER TABLE census_2010.block_geom_ky ALTER COLUMN gisjoin TYPE CHARACTER VARYING(18);
ALTER TABLE census_2010.block_geom_nc ALTER COLUMN gisjoin TYPE CHARACTER VARYING(18);
ALTER TABLE census_2010.block_geom_or ALTER COLUMN gisjoin TYPE CHARACTER VARYING(18);
ALTER TABLE census_2010.block_geom_la ALTER COLUMN gisjoin TYPE CHARACTER VARYING(18);
ALTER TABLE census_2010.block_geom_nd ALTER COLUMN gisjoin TYPE CHARACTER VARYING(18);
ALTER TABLE census_2010.block_geom_ma ALTER COLUMN gisjoin TYPE CHARACTER VARYING(18);
ALTER TABLE census_2010.block_geom_pa ALTER COLUMN gisjoin TYPE CHARACTER VARYING(18);
ALTER TABLE census_2010.block_geom_ne ALTER COLUMN gisjoin TYPE CHARACTER VARYING(18);
ALTER TABLE census_2010.block_geom_md ALTER COLUMN gisjoin TYPE CHARACTER VARYING(18);
ALTER TABLE census_2010.block_geom_me ALTER COLUMN gisjoin TYPE CHARACTER VARYING(18);
ALTER TABLE census_2010.block_geom_pr ALTER COLUMN gisjoin TYPE CHARACTER VARYING(18);
ALTER TABLE census_2010.block_geom_ri ALTER COLUMN gisjoin TYPE CHARACTER VARYING(18);
ALTER TABLE census_2010.block_geom_sc ALTER COLUMN gisjoin TYPE CHARACTER VARYING(18);
ALTER TABLE census_2010.block_geom_sd ALTER COLUMN gisjoin TYPE CHARACTER VARYING(18);
ALTER TABLE census_2010.block_geom_tn ALTER COLUMN gisjoin TYPE CHARACTER VARYING(18);
ALTER TABLE census_2010.block_geom_tx ALTER COLUMN gisjoin TYPE CHARACTER VARYING(18);
ALTER TABLE census_2010.block_geom_ut ALTER COLUMN gisjoin TYPE CHARACTER VARYING(18);
ALTER TABLE census_2010.block_geom_va ALTER COLUMN gisjoin TYPE CHARACTER VARYING(18);
ALTER TABLE census_2010.block_geom_vt ALTER COLUMN gisjoin TYPE CHARACTER VARYING(18);
ALTER TABLE census_2010.block_geom_wa ALTER COLUMN gisjoin TYPE CHARACTER VARYING(18);
ALTER TABLE census_2010.block_geom_wi ALTER COLUMN gisjoin TYPE CHARACTER VARYING(18);
ALTER TABLE census_2010.block_geom_wv ALTER COLUMN gisjoin TYPE CHARACTER VARYING(18);
ALTER TABLE census_2010.block_geom_wy ALTER COLUMN gisjoin TYPE CHARACTER VARYING(18);


-- create parent table
Drop table if exists census_2010.block_geom_parent;
CREATE TABLE census_2010.block_geom_parent As
SELECT *
FROM census_2010.block_geom_wy
LIMIT 0;

-- inherit children
ALTER TABLE census_2010.block_geom_al INHERIT census_2010.block_geom_parent;
ALTER TABLE census_2010.block_geom_ar INHERIT census_2010.block_geom_parent;
ALTER TABLE census_2010.block_geom_az INHERIT census_2010.block_geom_parent;
ALTER TABLE census_2010.block_geom_ca INHERIT census_2010.block_geom_parent;
ALTER TABLE census_2010.block_geom_ak INHERIT census_2010.block_geom_parent;
ALTER TABLE census_2010.block_geom_co INHERIT census_2010.block_geom_parent;
ALTER TABLE census_2010.block_geom_ct INHERIT census_2010.block_geom_parent;
ALTER TABLE census_2010.block_geom_dc INHERIT census_2010.block_geom_parent;
ALTER TABLE census_2010.block_geom_de INHERIT census_2010.block_geom_parent;
ALTER TABLE census_2010.block_geom_fl INHERIT census_2010.block_geom_parent;
ALTER TABLE census_2010.block_geom_ga INHERIT census_2010.block_geom_parent;
ALTER TABLE census_2010.block_geom_hi INHERIT census_2010.block_geom_parent;
ALTER TABLE census_2010.block_geom_ia INHERIT census_2010.block_geom_parent;
ALTER TABLE census_2010.block_geom_id INHERIT census_2010.block_geom_parent;
ALTER TABLE census_2010.block_geom_mi INHERIT census_2010.block_geom_parent;
ALTER TABLE census_2010.block_geom_nh INHERIT census_2010.block_geom_parent;
ALTER TABLE census_2010.block_geom_nj INHERIT census_2010.block_geom_parent;
ALTER TABLE census_2010.block_geom_il INHERIT census_2010.block_geom_parent;
ALTER TABLE census_2010.block_geom_mn INHERIT census_2010.block_geom_parent;
ALTER TABLE census_2010.block_geom_nm INHERIT census_2010.block_geom_parent;
ALTER TABLE census_2010.block_geom_nv INHERIT census_2010.block_geom_parent;
ALTER TABLE census_2010.block_geom_mo INHERIT census_2010.block_geom_parent;
ALTER TABLE census_2010.block_geom_ny INHERIT census_2010.block_geom_parent;
ALTER TABLE census_2010.block_geom_ms INHERIT census_2010.block_geom_parent;
ALTER TABLE census_2010.block_geom_oh INHERIT census_2010.block_geom_parent;
ALTER TABLE census_2010.block_geom_ks INHERIT census_2010.block_geom_parent;
ALTER TABLE census_2010.block_geom_mt INHERIT census_2010.block_geom_parent;
ALTER TABLE census_2010.block_geom_in INHERIT census_2010.block_geom_parent;
ALTER TABLE census_2010.block_geom_ok INHERIT census_2010.block_geom_parent;
ALTER TABLE census_2010.block_geom_ky INHERIT census_2010.block_geom_parent;
ALTER TABLE census_2010.block_geom_nc INHERIT census_2010.block_geom_parent;
ALTER TABLE census_2010.block_geom_or INHERIT census_2010.block_geom_parent;
ALTER TABLE census_2010.block_geom_la INHERIT census_2010.block_geom_parent;
ALTER TABLE census_2010.block_geom_nd INHERIT census_2010.block_geom_parent;
ALTER TABLE census_2010.block_geom_ma INHERIT census_2010.block_geom_parent;
ALTER TABLE census_2010.block_geom_pa INHERIT census_2010.block_geom_parent;
ALTER TABLE census_2010.block_geom_ne INHERIT census_2010.block_geom_parent;
ALTER TABLE census_2010.block_geom_md INHERIT census_2010.block_geom_parent;
ALTER TABLE census_2010.block_geom_me INHERIT census_2010.block_geom_parent;
ALTER TABLE census_2010.block_geom_pr INHERIT census_2010.block_geom_parent;
ALTER TABLE census_2010.block_geom_ri INHERIT census_2010.block_geom_parent;
ALTER TABLE census_2010.block_geom_sc INHERIT census_2010.block_geom_parent;
ALTER TABLE census_2010.block_geom_sd INHERIT census_2010.block_geom_parent;
ALTER TABLE census_2010.block_geom_tn INHERIT census_2010.block_geom_parent;
ALTER TABLE census_2010.block_geom_tx INHERIT census_2010.block_geom_parent;
ALTER TABLE census_2010.block_geom_ut INHERIT census_2010.block_geom_parent;
ALTER TABLE census_2010.block_geom_va INHERIT census_2010.block_geom_parent;
ALTER TABLE census_2010.block_geom_vt INHERIT census_2010.block_geom_parent;
ALTER TABLE census_2010.block_geom_wa INHERIT census_2010.block_geom_parent;
ALTER TABLE census_2010.block_geom_wi INHERIT census_2010.block_geom_parent;
ALTER TABLE census_2010.block_geom_wv INHERIT census_2010.block_geom_parent;
ALTER TABLE census_2010.block_geom_wy INHERIT census_2010.block_geom_parent;


-- make sure all tables were inherited
select distinct(state_abbr)
from census_2010.block_geom_parent;

-- make sure no nulls geom_4326
select state_abbr, sum((the_geom_4326 is null)::integer)
from census_2010.block_geom_parent
group by state_abbr;

-- census_2010.block_geom_al
-- census_2010.block_geom_ar
-- census_2010.block_geom_az
-- census_2010.block_geom_ca
-- census_2010.block_geom_ak
-- census_2010.block_geom_co
-- census_2010.block_geom_ct
-- census_2010.block_geom_dc
-- census_2010.block_geom_de
-- census_2010.block_geom_fl
-- census_2010.block_geom_ga
-- census_2010.block_geom_hi
-- census_2010.block_geom_ia
-- census_2010.block_geom_id
-- census_2010.block_geom_mi
-- census_2010.block_geom_nh
-- census_2010.block_geom_nj
-- census_2010.block_geom_il
-- census_2010.block_geom_mn
-- census_2010.block_geom_nm
-- census_2010.block_geom_nv
-- census_2010.block_geom_mo
-- census_2010.block_geom_ny
-- census_2010.block_geom_ms
-- census_2010.block_geom_oh
-- census_2010.block_geom_ks
-- census_2010.block_geom_mt
-- census_2010.block_geom_in
-- census_2010.block_geom_ok
-- census_2010.block_geom_ky
-- census_2010.block_geom_nc
-- census_2010.block_geom_or
-- census_2010.block_geom_la
-- census_2010.block_geom_nd
-- census_2010.block_geom_ma
-- census_2010.block_geom_pa
-- census_2010.block_geom_ne
-- census_2010.block_geom_md
-- census_2010.block_geom_me
-- census_2010.block_geom_pr
-- census_2010.block_geom_ri
-- census_2010.block_geom_sc
-- census_2010.block_geom_sd
-- census_2010.block_geom_tn
-- census_2010.block_geom_tx
-- census_2010.block_geom_ut
-- census_2010.block_geom_va
-- census_2010.block_geom_vt
-- census_2010.block_geom_wa
-- census_2010.block_geom_wi
-- census_2010.block_geom_wv
-- census_2010.block_geom_wy