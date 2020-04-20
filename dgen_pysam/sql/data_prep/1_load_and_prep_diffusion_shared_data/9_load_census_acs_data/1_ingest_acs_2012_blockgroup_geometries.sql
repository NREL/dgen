-- load shapefiles to postgres using shp2pgsql from command line as follows:
--  shp2pgsql -s 102003 -c -g the_geom_102003 -D -I AK_blck_grp_2012.shp acs_2012.blockgroup_geom_AK | psql -h gispgdb -U mgleason dav-gis

-- for each table, then do the following:
SELECT table_schema || '.' || table_name
FROM information_schema.tables 
WHERE table_schema = 'acs_2012'
and table_name like 'blockgroup_geom_%'
order by 1;

-- add 4326 geom
ALTER TABLE acs_2012.blockgroup_geom_al ADD column the_geom_4326 geometry;
ALTER TABLE acs_2012.blockgroup_geom_ar ADD column the_geom_4326 geometry;
ALTER TABLE acs_2012.blockgroup_geom_az ADD column the_geom_4326 geometry;
ALTER TABLE acs_2012.blockgroup_geom_ca ADD column the_geom_4326 geometry;
ALTER TABLE acs_2012.blockgroup_geom_ak ADD column the_geom_4326 geometry;
ALTER TABLE acs_2012.blockgroup_geom_co ADD column the_geom_4326 geometry;
ALTER TABLE acs_2012.blockgroup_geom_ct ADD column the_geom_4326 geometry;
ALTER TABLE acs_2012.blockgroup_geom_dc ADD column the_geom_4326 geometry;
ALTER TABLE acs_2012.blockgroup_geom_de ADD column the_geom_4326 geometry;
ALTER TABLE acs_2012.blockgroup_geom_fl ADD column the_geom_4326 geometry;
ALTER TABLE acs_2012.blockgroup_geom_ga ADD column the_geom_4326 geometry;
ALTER TABLE acs_2012.blockgroup_geom_hi ADD column the_geom_4326 geometry;
ALTER TABLE acs_2012.blockgroup_geom_ia ADD column the_geom_4326 geometry;
ALTER TABLE acs_2012.blockgroup_geom_id ADD column the_geom_4326 geometry;
ALTER TABLE acs_2012.blockgroup_geom_mi ADD column the_geom_4326 geometry;
ALTER TABLE acs_2012.blockgroup_geom_nh ADD column the_geom_4326 geometry;
ALTER TABLE acs_2012.blockgroup_geom_nj ADD column the_geom_4326 geometry;
ALTER TABLE acs_2012.blockgroup_geom_il ADD column the_geom_4326 geometry;
ALTER TABLE acs_2012.blockgroup_geom_mn ADD column the_geom_4326 geometry;
ALTER TABLE acs_2012.blockgroup_geom_nm ADD column the_geom_4326 geometry;
ALTER TABLE acs_2012.blockgroup_geom_nv ADD column the_geom_4326 geometry;
ALTER TABLE acs_2012.blockgroup_geom_mo ADD column the_geom_4326 geometry;
ALTER TABLE acs_2012.blockgroup_geom_ny ADD column the_geom_4326 geometry;
ALTER TABLE acs_2012.blockgroup_geom_ms ADD column the_geom_4326 geometry;
ALTER TABLE acs_2012.blockgroup_geom_oh ADD column the_geom_4326 geometry;
ALTER TABLE acs_2012.blockgroup_geom_ks ADD column the_geom_4326 geometry;
ALTER TABLE acs_2012.blockgroup_geom_mt ADD column the_geom_4326 geometry;
ALTER TABLE acs_2012.blockgroup_geom_in ADD column the_geom_4326 geometry;
ALTER TABLE acs_2012.blockgroup_geom_ok ADD column the_geom_4326 geometry;
ALTER TABLE acs_2012.blockgroup_geom_ky ADD column the_geom_4326 geometry;
ALTER TABLE acs_2012.blockgroup_geom_nc ADD column the_geom_4326 geometry;
ALTER TABLE acs_2012.blockgroup_geom_or ADD column the_geom_4326 geometry;
ALTER TABLE acs_2012.blockgroup_geom_la ADD column the_geom_4326 geometry;
ALTER TABLE acs_2012.blockgroup_geom_nd ADD column the_geom_4326 geometry;
ALTER TABLE acs_2012.blockgroup_geom_ma ADD column the_geom_4326 geometry;
ALTER TABLE acs_2012.blockgroup_geom_pa ADD column the_geom_4326 geometry;
ALTER TABLE acs_2012.blockgroup_geom_ne ADD column the_geom_4326 geometry;
ALTER TABLE acs_2012.blockgroup_geom_md ADD column the_geom_4326 geometry;
ALTER TABLE acs_2012.blockgroup_geom_me ADD column the_geom_4326 geometry;
ALTER TABLE acs_2012.blockgroup_geom_pr ADD column the_geom_4326 geometry;
ALTER TABLE acs_2012.blockgroup_geom_ri ADD column the_geom_4326 geometry;
ALTER TABLE acs_2012.blockgroup_geom_sc ADD column the_geom_4326 geometry;
ALTER TABLE acs_2012.blockgroup_geom_sd ADD column the_geom_4326 geometry;
ALTER TABLE acs_2012.blockgroup_geom_tn ADD column the_geom_4326 geometry;
ALTER TABLE acs_2012.blockgroup_geom_tx ADD column the_geom_4326 geometry;
ALTER TABLE acs_2012.blockgroup_geom_ut ADD column the_geom_4326 geometry;
ALTER TABLE acs_2012.blockgroup_geom_va ADD column the_geom_4326 geometry;
ALTER TABLE acs_2012.blockgroup_geom_vt ADD column the_geom_4326 geometry;
ALTER TABLE acs_2012.blockgroup_geom_wa ADD column the_geom_4326 geometry;
ALTER TABLE acs_2012.blockgroup_geom_wi ADD column the_geom_4326 geometry;
ALTER TABLE acs_2012.blockgroup_geom_wv ADD column the_geom_4326 geometry;
ALTER TABLE acs_2012.blockgroup_geom_wy ADD column the_geom_4326 geometry;

-- update 4326 geom
UPDATE acs_2012.blockgroup_geom_al SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE acs_2012.blockgroup_geom_ar SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE acs_2012.blockgroup_geom_az SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE acs_2012.blockgroup_geom_ca SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE acs_2012.blockgroup_geom_ak SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE acs_2012.blockgroup_geom_co SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE acs_2012.blockgroup_geom_ct SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE acs_2012.blockgroup_geom_dc SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE acs_2012.blockgroup_geom_de SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE acs_2012.blockgroup_geom_fl SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE acs_2012.blockgroup_geom_ga SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE acs_2012.blockgroup_geom_hi SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE acs_2012.blockgroup_geom_ia SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE acs_2012.blockgroup_geom_id SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE acs_2012.blockgroup_geom_mi SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE acs_2012.blockgroup_geom_nh SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE acs_2012.blockgroup_geom_nj SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE acs_2012.blockgroup_geom_il SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE acs_2012.blockgroup_geom_mn SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE acs_2012.blockgroup_geom_nm SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE acs_2012.blockgroup_geom_nv SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE acs_2012.blockgroup_geom_mo SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE acs_2012.blockgroup_geom_ny SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE acs_2012.blockgroup_geom_ms SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE acs_2012.blockgroup_geom_oh SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE acs_2012.blockgroup_geom_ks SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE acs_2012.blockgroup_geom_mt SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE acs_2012.blockgroup_geom_in SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE acs_2012.blockgroup_geom_ok SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE acs_2012.blockgroup_geom_ky SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE acs_2012.blockgroup_geom_nc SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE acs_2012.blockgroup_geom_or SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE acs_2012.blockgroup_geom_la SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE acs_2012.blockgroup_geom_nd SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE acs_2012.blockgroup_geom_ma SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE acs_2012.blockgroup_geom_pa SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE acs_2012.blockgroup_geom_ne SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE acs_2012.blockgroup_geom_md SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE acs_2012.blockgroup_geom_me SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE acs_2012.blockgroup_geom_pr SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE acs_2012.blockgroup_geom_ri SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE acs_2012.blockgroup_geom_sc SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE acs_2012.blockgroup_geom_sd SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE acs_2012.blockgroup_geom_tn SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE acs_2012.blockgroup_geom_tx SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE acs_2012.blockgroup_geom_ut SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE acs_2012.blockgroup_geom_va SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE acs_2012.blockgroup_geom_vt SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE acs_2012.blockgroup_geom_wa SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE acs_2012.blockgroup_geom_wi SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE acs_2012.blockgroup_geom_wv SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);
UPDATE acs_2012.blockgroup_geom_wy SET the_geom_4326 = ST_Transform(the_geom_102003, 4326);

-- add index on new geom
CREATE INDEX blockgroup_geom_al_the_geom_4326_gist ON acs_2012.blockgroup_geom_al USING gist(the_geom_4326);
CREATE INDEX blockgroup_geom_ar_the_geom_4326_gist ON acs_2012.blockgroup_geom_ar USING gist(the_geom_4326);
CREATE INDEX blockgroup_geom_az_the_geom_4326_gist ON acs_2012.blockgroup_geom_az USING gist(the_geom_4326);
CREATE INDEX blockgroup_geom_ca_the_geom_4326_gist ON acs_2012.blockgroup_geom_ca USING gist(the_geom_4326);
CREATE INDEX blockgroup_geom_ak_the_geom_4326_gist ON acs_2012.blockgroup_geom_ak USING gist(the_geom_4326);
CREATE INDEX blockgroup_geom_co_the_geom_4326_gist ON acs_2012.blockgroup_geom_co USING gist(the_geom_4326);
CREATE INDEX blockgroup_geom_ct_the_geom_4326_gist ON acs_2012.blockgroup_geom_ct USING gist(the_geom_4326);
CREATE INDEX blockgroup_geom_dc_the_geom_4326_gist ON acs_2012.blockgroup_geom_dc USING gist(the_geom_4326);
CREATE INDEX blockgroup_geom_de_the_geom_4326_gist ON acs_2012.blockgroup_geom_de USING gist(the_geom_4326);
CREATE INDEX blockgroup_geom_fl_the_geom_4326_gist ON acs_2012.blockgroup_geom_fl USING gist(the_geom_4326);
CREATE INDEX blockgroup_geom_ga_the_geom_4326_gist ON acs_2012.blockgroup_geom_ga USING gist(the_geom_4326);
CREATE INDEX blockgroup_geom_hi_the_geom_4326_gist ON acs_2012.blockgroup_geom_hi USING gist(the_geom_4326);
CREATE INDEX blockgroup_geom_ia_the_geom_4326_gist ON acs_2012.blockgroup_geom_ia USING gist(the_geom_4326);
CREATE INDEX blockgroup_geom_id_the_geom_4326_gist ON acs_2012.blockgroup_geom_id USING gist(the_geom_4326);
CREATE INDEX blockgroup_geom_mi_the_geom_4326_gist ON acs_2012.blockgroup_geom_mi USING gist(the_geom_4326);
CREATE INDEX blockgroup_geom_nh_the_geom_4326_gist ON acs_2012.blockgroup_geom_nh USING gist(the_geom_4326);
CREATE INDEX blockgroup_geom_nj_the_geom_4326_gist ON acs_2012.blockgroup_geom_nj USING gist(the_geom_4326);
CREATE INDEX blockgroup_geom_il_the_geom_4326_gist ON acs_2012.blockgroup_geom_il USING gist(the_geom_4326);
CREATE INDEX blockgroup_geom_mn_the_geom_4326_gist ON acs_2012.blockgroup_geom_mn USING gist(the_geom_4326);
CREATE INDEX blockgroup_geom_nm_the_geom_4326_gist ON acs_2012.blockgroup_geom_nm USING gist(the_geom_4326);
CREATE INDEX blockgroup_geom_nv_the_geom_4326_gist ON acs_2012.blockgroup_geom_nv USING gist(the_geom_4326);
CREATE INDEX blockgroup_geom_mo_the_geom_4326_gist ON acs_2012.blockgroup_geom_mo USING gist(the_geom_4326);
CREATE INDEX blockgroup_geom_ny_the_geom_4326_gist ON acs_2012.blockgroup_geom_ny USING gist(the_geom_4326);
CREATE INDEX blockgroup_geom_ms_the_geom_4326_gist ON acs_2012.blockgroup_geom_ms USING gist(the_geom_4326);
CREATE INDEX blockgroup_geom_oh_the_geom_4326_gist ON acs_2012.blockgroup_geom_oh USING gist(the_geom_4326);
CREATE INDEX blockgroup_geom_ks_the_geom_4326_gist ON acs_2012.blockgroup_geom_ks USING gist(the_geom_4326);
CREATE INDEX blockgroup_geom_mt_the_geom_4326_gist ON acs_2012.blockgroup_geom_mt USING gist(the_geom_4326);
CREATE INDEX blockgroup_geom_in_the_geom_4326_gist ON acs_2012.blockgroup_geom_in USING gist(the_geom_4326);
CREATE INDEX blockgroup_geom_ok_the_geom_4326_gist ON acs_2012.blockgroup_geom_ok USING gist(the_geom_4326);
CREATE INDEX blockgroup_geom_ky_the_geom_4326_gist ON acs_2012.blockgroup_geom_ky USING gist(the_geom_4326);
CREATE INDEX blockgroup_geom_nc_the_geom_4326_gist ON acs_2012.blockgroup_geom_nc USING gist(the_geom_4326);
CREATE INDEX blockgroup_geom_or_the_geom_4326_gist ON acs_2012.blockgroup_geom_or USING gist(the_geom_4326);
CREATE INDEX blockgroup_geom_la_the_geom_4326_gist ON acs_2012.blockgroup_geom_la USING gist(the_geom_4326);
CREATE INDEX blockgroup_geom_nd_the_geom_4326_gist ON acs_2012.blockgroup_geom_nd USING gist(the_geom_4326);
CREATE INDEX blockgroup_geom_ma_the_geom_4326_gist ON acs_2012.blockgroup_geom_ma USING gist(the_geom_4326);
CREATE INDEX blockgroup_geom_pa_the_geom_4326_gist ON acs_2012.blockgroup_geom_pa USING gist(the_geom_4326);
CREATE INDEX blockgroup_geom_ne_the_geom_4326_gist ON acs_2012.blockgroup_geom_ne USING gist(the_geom_4326);
CREATE INDEX blockgroup_geom_md_the_geom_4326_gist ON acs_2012.blockgroup_geom_md USING gist(the_geom_4326);
CREATE INDEX blockgroup_geom_me_the_geom_4326_gist ON acs_2012.blockgroup_geom_me USING gist(the_geom_4326);
CREATE INDEX blockgroup_geom_pr_the_geom_4326_gist ON acs_2012.blockgroup_geom_pr USING gist(the_geom_4326);
CREATE INDEX blockgroup_geom_ri_the_geom_4326_gist ON acs_2012.blockgroup_geom_ri USING gist(the_geom_4326);
CREATE INDEX blockgroup_geom_sc_the_geom_4326_gist ON acs_2012.blockgroup_geom_sc USING gist(the_geom_4326);
CREATE INDEX blockgroup_geom_sd_the_geom_4326_gist ON acs_2012.blockgroup_geom_sd USING gist(the_geom_4326);
CREATE INDEX blockgroup_geom_tn_the_geom_4326_gist ON acs_2012.blockgroup_geom_tn USING gist(the_geom_4326);
CREATE INDEX blockgroup_geom_tx_the_geom_4326_gist ON acs_2012.blockgroup_geom_tx USING gist(the_geom_4326);
CREATE INDEX blockgroup_geom_ut_the_geom_4326_gist ON acs_2012.blockgroup_geom_ut USING gist(the_geom_4326);
CREATE INDEX blockgroup_geom_va_the_geom_4326_gist ON acs_2012.blockgroup_geom_va USING gist(the_geom_4326);
CREATE INDEX blockgroup_geom_vt_the_geom_4326_gist ON acs_2012.blockgroup_geom_vt USING gist(the_geom_4326);
CREATE INDEX blockgroup_geom_wa_the_geom_4326_gist ON acs_2012.blockgroup_geom_wa USING gist(the_geom_4326);
CREATE INDEX blockgroup_geom_wi_the_geom_4326_gist ON acs_2012.blockgroup_geom_wi USING gist(the_geom_4326);
CREATE INDEX blockgroup_geom_wv_the_geom_4326_gist ON acs_2012.blockgroup_geom_wv USING gist(the_geom_4326);
CREATE INDEX blockgroup_geom_wy_the_geom_4326_gist ON acs_2012.blockgroup_geom_wy USING gist(the_geom_4326);

-- add index on gisjoin
CREATE INDEX blockgroup_geom_al_gisjoin_btree ON acs_2012.blockgroup_geom_al USING btree(gisjoin);
CREATE INDEX blockgroup_geom_ar_gisjoin_btree ON acs_2012.blockgroup_geom_ar USING btree(gisjoin);
CREATE INDEX blockgroup_geom_az_gisjoin_btree ON acs_2012.blockgroup_geom_az USING btree(gisjoin);
CREATE INDEX blockgroup_geom_ca_gisjoin_btree ON acs_2012.blockgroup_geom_ca USING btree(gisjoin);
CREATE INDEX blockgroup_geom_ak_gisjoin_btree ON acs_2012.blockgroup_geom_ak USING btree(gisjoin);
CREATE INDEX blockgroup_geom_co_gisjoin_btree ON acs_2012.blockgroup_geom_co USING btree(gisjoin);
CREATE INDEX blockgroup_geom_ct_gisjoin_btree ON acs_2012.blockgroup_geom_ct USING btree(gisjoin);
CREATE INDEX blockgroup_geom_dc_gisjoin_btree ON acs_2012.blockgroup_geom_dc USING btree(gisjoin);
CREATE INDEX blockgroup_geom_de_gisjoin_btree ON acs_2012.blockgroup_geom_de USING btree(gisjoin);
CREATE INDEX blockgroup_geom_fl_gisjoin_btree ON acs_2012.blockgroup_geom_fl USING btree(gisjoin);
CREATE INDEX blockgroup_geom_ga_gisjoin_btree ON acs_2012.blockgroup_geom_ga USING btree(gisjoin);
CREATE INDEX blockgroup_geom_hi_gisjoin_btree ON acs_2012.blockgroup_geom_hi USING btree(gisjoin);
CREATE INDEX blockgroup_geom_ia_gisjoin_btree ON acs_2012.blockgroup_geom_ia USING btree(gisjoin);
CREATE INDEX blockgroup_geom_id_gisjoin_btree ON acs_2012.blockgroup_geom_id USING btree(gisjoin);
CREATE INDEX blockgroup_geom_mi_gisjoin_btree ON acs_2012.blockgroup_geom_mi USING btree(gisjoin);
CREATE INDEX blockgroup_geom_nh_gisjoin_btree ON acs_2012.blockgroup_geom_nh USING btree(gisjoin);
CREATE INDEX blockgroup_geom_nj_gisjoin_btree ON acs_2012.blockgroup_geom_nj USING btree(gisjoin);
CREATE INDEX blockgroup_geom_il_gisjoin_btree ON acs_2012.blockgroup_geom_il USING btree(gisjoin);
CREATE INDEX blockgroup_geom_mn_gisjoin_btree ON acs_2012.blockgroup_geom_mn USING btree(gisjoin);
CREATE INDEX blockgroup_geom_nm_gisjoin_btree ON acs_2012.blockgroup_geom_nm USING btree(gisjoin);
CREATE INDEX blockgroup_geom_nv_gisjoin_btree ON acs_2012.blockgroup_geom_nv USING btree(gisjoin);
CREATE INDEX blockgroup_geom_mo_gisjoin_btree ON acs_2012.blockgroup_geom_mo USING btree(gisjoin);
CREATE INDEX blockgroup_geom_ny_gisjoin_btree ON acs_2012.blockgroup_geom_ny USING btree(gisjoin);
CREATE INDEX blockgroup_geom_ms_gisjoin_btree ON acs_2012.blockgroup_geom_ms USING btree(gisjoin);
CREATE INDEX blockgroup_geom_oh_gisjoin_btree ON acs_2012.blockgroup_geom_oh USING btree(gisjoin);
CREATE INDEX blockgroup_geom_ks_gisjoin_btree ON acs_2012.blockgroup_geom_ks USING btree(gisjoin);
CREATE INDEX blockgroup_geom_mt_gisjoin_btree ON acs_2012.blockgroup_geom_mt USING btree(gisjoin);
CREATE INDEX blockgroup_geom_in_gisjoin_btree ON acs_2012.blockgroup_geom_in USING btree(gisjoin);
CREATE INDEX blockgroup_geom_ok_gisjoin_btree ON acs_2012.blockgroup_geom_ok USING btree(gisjoin);
CREATE INDEX blockgroup_geom_ky_gisjoin_btree ON acs_2012.blockgroup_geom_ky USING btree(gisjoin);
CREATE INDEX blockgroup_geom_nc_gisjoin_btree ON acs_2012.blockgroup_geom_nc USING btree(gisjoin);
CREATE INDEX blockgroup_geom_or_gisjoin_btree ON acs_2012.blockgroup_geom_or USING btree(gisjoin);
CREATE INDEX blockgroup_geom_la_gisjoin_btree ON acs_2012.blockgroup_geom_la USING btree(gisjoin);
CREATE INDEX blockgroup_geom_nd_gisjoin_btree ON acs_2012.blockgroup_geom_nd USING btree(gisjoin);
CREATE INDEX blockgroup_geom_ma_gisjoin_btree ON acs_2012.blockgroup_geom_ma USING btree(gisjoin);
CREATE INDEX blockgroup_geom_pa_gisjoin_btree ON acs_2012.blockgroup_geom_pa USING btree(gisjoin);
CREATE INDEX blockgroup_geom_ne_gisjoin_btree ON acs_2012.blockgroup_geom_ne USING btree(gisjoin);
CREATE INDEX blockgroup_geom_md_gisjoin_btree ON acs_2012.blockgroup_geom_md USING btree(gisjoin);
CREATE INDEX blockgroup_geom_me_gisjoin_btree ON acs_2012.blockgroup_geom_me USING btree(gisjoin);
CREATE INDEX blockgroup_geom_pr_gisjoin_btree ON acs_2012.blockgroup_geom_pr USING btree(gisjoin);
CREATE INDEX blockgroup_geom_ri_gisjoin_btree ON acs_2012.blockgroup_geom_ri USING btree(gisjoin);
CREATE INDEX blockgroup_geom_sc_gisjoin_btree ON acs_2012.blockgroup_geom_sc USING btree(gisjoin);
CREATE INDEX blockgroup_geom_sd_gisjoin_btree ON acs_2012.blockgroup_geom_sd USING btree(gisjoin);
CREATE INDEX blockgroup_geom_tn_gisjoin_btree ON acs_2012.blockgroup_geom_tn USING btree(gisjoin);
CREATE INDEX blockgroup_geom_tx_gisjoin_btree ON acs_2012.blockgroup_geom_tx USING btree(gisjoin);
CREATE INDEX blockgroup_geom_ut_gisjoin_btree ON acs_2012.blockgroup_geom_ut USING btree(gisjoin);
CREATE INDEX blockgroup_geom_va_gisjoin_btree ON acs_2012.blockgroup_geom_va USING btree(gisjoin);
CREATE INDEX blockgroup_geom_vt_gisjoin_btree ON acs_2012.blockgroup_geom_vt USING btree(gisjoin);
CREATE INDEX blockgroup_geom_wa_gisjoin_btree ON acs_2012.blockgroup_geom_wa USING btree(gisjoin);
CREATE INDEX blockgroup_geom_wi_gisjoin_btree ON acs_2012.blockgroup_geom_wi USING btree(gisjoin);
CREATE INDEX blockgroup_geom_wv_gisjoin_btree ON acs_2012.blockgroup_geom_wv USING btree(gisjoin);
CREATE INDEX blockgroup_geom_wy_gisjoin_btree ON acs_2012.blockgroup_geom_wy USING btree(gisjoin);

-- add state abbr column
ALTER TABLE acs_2012.blockgroup_geom_al ADD COLUMN state_abbr character varying (2);
ALTER TABLE acs_2012.blockgroup_geom_ar ADD COLUMN state_abbr character varying (2);
ALTER TABLE acs_2012.blockgroup_geom_az ADD COLUMN state_abbr character varying (2);
ALTER TABLE acs_2012.blockgroup_geom_ca ADD COLUMN state_abbr character varying (2);
ALTER TABLE acs_2012.blockgroup_geom_ak ADD COLUMN state_abbr character varying (2);
ALTER TABLE acs_2012.blockgroup_geom_co ADD COLUMN state_abbr character varying (2);
ALTER TABLE acs_2012.blockgroup_geom_ct ADD COLUMN state_abbr character varying (2);
ALTER TABLE acs_2012.blockgroup_geom_dc ADD COLUMN state_abbr character varying (2);
ALTER TABLE acs_2012.blockgroup_geom_de ADD COLUMN state_abbr character varying (2);
ALTER TABLE acs_2012.blockgroup_geom_fl ADD COLUMN state_abbr character varying (2);
ALTER TABLE acs_2012.blockgroup_geom_ga ADD COLUMN state_abbr character varying (2);
ALTER TABLE acs_2012.blockgroup_geom_hi ADD COLUMN state_abbr character varying (2);
ALTER TABLE acs_2012.blockgroup_geom_ia ADD COLUMN state_abbr character varying (2);
ALTER TABLE acs_2012.blockgroup_geom_id ADD COLUMN state_abbr character varying (2);
ALTER TABLE acs_2012.blockgroup_geom_mi ADD COLUMN state_abbr character varying (2);
ALTER TABLE acs_2012.blockgroup_geom_nh ADD COLUMN state_abbr character varying (2);
ALTER TABLE acs_2012.blockgroup_geom_nj ADD COLUMN state_abbr character varying (2);
ALTER TABLE acs_2012.blockgroup_geom_il ADD COLUMN state_abbr character varying (2);
ALTER TABLE acs_2012.blockgroup_geom_mn ADD COLUMN state_abbr character varying (2);
ALTER TABLE acs_2012.blockgroup_geom_nm ADD COLUMN state_abbr character varying (2);
ALTER TABLE acs_2012.blockgroup_geom_nv ADD COLUMN state_abbr character varying (2);
ALTER TABLE acs_2012.blockgroup_geom_mo ADD COLUMN state_abbr character varying (2);
ALTER TABLE acs_2012.blockgroup_geom_ny ADD COLUMN state_abbr character varying (2);
ALTER TABLE acs_2012.blockgroup_geom_ms ADD COLUMN state_abbr character varying (2);
ALTER TABLE acs_2012.blockgroup_geom_oh ADD COLUMN state_abbr character varying (2);
ALTER TABLE acs_2012.blockgroup_geom_ks ADD COLUMN state_abbr character varying (2);
ALTER TABLE acs_2012.blockgroup_geom_mt ADD COLUMN state_abbr character varying (2);
ALTER TABLE acs_2012.blockgroup_geom_in ADD COLUMN state_abbr character varying (2);
ALTER TABLE acs_2012.blockgroup_geom_ok ADD COLUMN state_abbr character varying (2);
ALTER TABLE acs_2012.blockgroup_geom_ky ADD COLUMN state_abbr character varying (2);
ALTER TABLE acs_2012.blockgroup_geom_nc ADD COLUMN state_abbr character varying (2);
ALTER TABLE acs_2012.blockgroup_geom_or ADD COLUMN state_abbr character varying (2);
ALTER TABLE acs_2012.blockgroup_geom_la ADD COLUMN state_abbr character varying (2);
ALTER TABLE acs_2012.blockgroup_geom_nd ADD COLUMN state_abbr character varying (2);
ALTER TABLE acs_2012.blockgroup_geom_ma ADD COLUMN state_abbr character varying (2);
ALTER TABLE acs_2012.blockgroup_geom_pa ADD COLUMN state_abbr character varying (2);
ALTER TABLE acs_2012.blockgroup_geom_ne ADD COLUMN state_abbr character varying (2);
ALTER TABLE acs_2012.blockgroup_geom_md ADD COLUMN state_abbr character varying (2);
ALTER TABLE acs_2012.blockgroup_geom_me ADD COLUMN state_abbr character varying (2);
ALTER TABLE acs_2012.blockgroup_geom_pr ADD COLUMN state_abbr character varying (2);
ALTER TABLE acs_2012.blockgroup_geom_ri ADD COLUMN state_abbr character varying (2);
ALTER TABLE acs_2012.blockgroup_geom_sc ADD COLUMN state_abbr character varying (2);
ALTER TABLE acs_2012.blockgroup_geom_sd ADD COLUMN state_abbr character varying (2);
ALTER TABLE acs_2012.blockgroup_geom_tn ADD COLUMN state_abbr character varying (2);
ALTER TABLE acs_2012.blockgroup_geom_tx ADD COLUMN state_abbr character varying (2);
ALTER TABLE acs_2012.blockgroup_geom_ut ADD COLUMN state_abbr character varying (2);
ALTER TABLE acs_2012.blockgroup_geom_va ADD COLUMN state_abbr character varying (2);
ALTER TABLE acs_2012.blockgroup_geom_vt ADD COLUMN state_abbr character varying (2);
ALTER TABLE acs_2012.blockgroup_geom_wa ADD COLUMN state_abbr character varying (2);
ALTER TABLE acs_2012.blockgroup_geom_wi ADD COLUMN state_abbr character varying (2);
ALTER TABLE acs_2012.blockgroup_geom_wv ADD COLUMN state_abbr character varying (2);
ALTER TABLE acs_2012.blockgroup_geom_wy ADD COLUMN state_abbr character varying (2);

-- update the state abbr column
UPDATE acs_2012.blockgroup_geom_al SET state_abbr = 'AL';
UPDATE acs_2012.blockgroup_geom_ar SET state_abbr = 'AR';
UPDATE acs_2012.blockgroup_geom_az SET state_abbr = 'AZ';
UPDATE acs_2012.blockgroup_geom_ca SET state_abbr = 'CA';
UPDATE acs_2012.blockgroup_geom_ak SET state_abbr = 'AK';
UPDATE acs_2012.blockgroup_geom_co SET state_abbr = 'CO';
UPDATE acs_2012.blockgroup_geom_ct SET state_abbr = 'CT';
UPDATE acs_2012.blockgroup_geom_dc SET state_abbr = 'DC';
UPDATE acs_2012.blockgroup_geom_de SET state_abbr = 'DE';
UPDATE acs_2012.blockgroup_geom_fl SET state_abbr = 'FL';
UPDATE acs_2012.blockgroup_geom_ga SET state_abbr = 'GA';
UPDATE acs_2012.blockgroup_geom_hi SET state_abbr = 'HI';
UPDATE acs_2012.blockgroup_geom_ia SET state_abbr = 'IA';
UPDATE acs_2012.blockgroup_geom_id SET state_abbr = 'ID';
UPDATE acs_2012.blockgroup_geom_mi SET state_abbr = 'MI';
UPDATE acs_2012.blockgroup_geom_nh SET state_abbr = 'NH';
UPDATE acs_2012.blockgroup_geom_nj SET state_abbr = 'NJ';
UPDATE acs_2012.blockgroup_geom_il SET state_abbr = 'IL';
UPDATE acs_2012.blockgroup_geom_mn SET state_abbr = 'MN';
UPDATE acs_2012.blockgroup_geom_nm SET state_abbr = 'NM';
UPDATE acs_2012.blockgroup_geom_nv SET state_abbr = 'NV';
UPDATE acs_2012.blockgroup_geom_mo SET state_abbr = 'MO';
UPDATE acs_2012.blockgroup_geom_ny SET state_abbr = 'NY';
UPDATE acs_2012.blockgroup_geom_ms SET state_abbr = 'MS';
UPDATE acs_2012.blockgroup_geom_oh SET state_abbr = 'OH';
UPDATE acs_2012.blockgroup_geom_ks SET state_abbr = 'KS';
UPDATE acs_2012.blockgroup_geom_mt SET state_abbr = 'MT';
UPDATE acs_2012.blockgroup_geom_in SET state_abbr = 'IN';
UPDATE acs_2012.blockgroup_geom_ok SET state_abbr = 'OK';
UPDATE acs_2012.blockgroup_geom_ky SET state_abbr = 'KY';
UPDATE acs_2012.blockgroup_geom_nc SET state_abbr = 'NC';
UPDATE acs_2012.blockgroup_geom_or SET state_abbr = 'OR';
UPDATE acs_2012.blockgroup_geom_la SET state_abbr = 'LA';
UPDATE acs_2012.blockgroup_geom_nd SET state_abbr = 'ND';
UPDATE acs_2012.blockgroup_geom_ma SET state_abbr = 'MA';
UPDATE acs_2012.blockgroup_geom_pa SET state_abbr = 'PA';
UPDATE acs_2012.blockgroup_geom_ne SET state_abbr = 'NE';
UPDATE acs_2012.blockgroup_geom_md SET state_abbr = 'MD';
UPDATE acs_2012.blockgroup_geom_me SET state_abbr = 'ME';
UPDATE acs_2012.blockgroup_geom_pr SET state_abbr = 'PR';
UPDATE acs_2012.blockgroup_geom_ri SET state_abbr = 'RI';
UPDATE acs_2012.blockgroup_geom_sc SET state_abbr = 'SC';
UPDATE acs_2012.blockgroup_geom_sd SET state_abbr = 'SD';
UPDATE acs_2012.blockgroup_geom_tn SET state_abbr = 'TN';
UPDATE acs_2012.blockgroup_geom_tx SET state_abbr = 'TX';
UPDATE acs_2012.blockgroup_geom_ut SET state_abbr = 'UT';
UPDATE acs_2012.blockgroup_geom_va SET state_abbr = 'VA';
UPDATE acs_2012.blockgroup_geom_vt SET state_abbr = 'VT';
UPDATE acs_2012.blockgroup_geom_wa SET state_abbr = 'WA';
UPDATE acs_2012.blockgroup_geom_wi SET state_abbr = 'WI';
UPDATE acs_2012.blockgroup_geom_wv SET state_abbr = 'WV';
UPDATE acs_2012.blockgroup_geom_wy SET state_abbr = 'WY';

-- add a constraint on the table
ALTER TABLE acs_2012.blockgroup_geom_al ADD CONSTRAINT blockgroup_geom_al_state_abbr_check CHECK (state_abbr = 'AL');
ALTER TABLE acs_2012.blockgroup_geom_ar ADD CONSTRAINT blockgroup_geom_ar_state_abbr_check CHECK (state_abbr = 'AR');
ALTER TABLE acs_2012.blockgroup_geom_az ADD CONSTRAINT blockgroup_geom_az_state_abbr_check CHECK (state_abbr = 'AZ');
ALTER TABLE acs_2012.blockgroup_geom_ca ADD CONSTRAINT blockgroup_geom_ca_state_abbr_check CHECK (state_abbr = 'CA');
ALTER TABLE acs_2012.blockgroup_geom_ak ADD CONSTRAINT blockgroup_geom_ak_state_abbr_check CHECK (state_abbr = 'AK');
ALTER TABLE acs_2012.blockgroup_geom_co ADD CONSTRAINT blockgroup_geom_co_state_abbr_check CHECK (state_abbr = 'CO');
ALTER TABLE acs_2012.blockgroup_geom_ct ADD CONSTRAINT blockgroup_geom_ct_state_abbr_check CHECK (state_abbr = 'CT');
ALTER TABLE acs_2012.blockgroup_geom_dc ADD CONSTRAINT blockgroup_geom_dc_state_abbr_check CHECK (state_abbr = 'DC');
ALTER TABLE acs_2012.blockgroup_geom_de ADD CONSTRAINT blockgroup_geom_de_state_abbr_check CHECK (state_abbr = 'DE');
ALTER TABLE acs_2012.blockgroup_geom_fl ADD CONSTRAINT blockgroup_geom_fl_state_abbr_check CHECK (state_abbr = 'FL');
ALTER TABLE acs_2012.blockgroup_geom_ga ADD CONSTRAINT blockgroup_geom_ga_state_abbr_check CHECK (state_abbr = 'GA');
ALTER TABLE acs_2012.blockgroup_geom_hi ADD CONSTRAINT blockgroup_geom_hi_state_abbr_check CHECK (state_abbr = 'HI');
ALTER TABLE acs_2012.blockgroup_geom_ia ADD CONSTRAINT blockgroup_geom_ia_state_abbr_check CHECK (state_abbr = 'IA');
ALTER TABLE acs_2012.blockgroup_geom_id ADD CONSTRAINT blockgroup_geom_id_state_abbr_check CHECK (state_abbr = 'ID');
ALTER TABLE acs_2012.blockgroup_geom_mi ADD CONSTRAINT blockgroup_geom_mi_state_abbr_check CHECK (state_abbr = 'MI');
ALTER TABLE acs_2012.blockgroup_geom_nh ADD CONSTRAINT blockgroup_geom_nh_state_abbr_check CHECK (state_abbr = 'NH');
ALTER TABLE acs_2012.blockgroup_geom_nj ADD CONSTRAINT blockgroup_geom_nj_state_abbr_check CHECK (state_abbr = 'NJ');
ALTER TABLE acs_2012.blockgroup_geom_il ADD CONSTRAINT blockgroup_geom_il_state_abbr_check CHECK (state_abbr = 'IL');
ALTER TABLE acs_2012.blockgroup_geom_mn ADD CONSTRAINT blockgroup_geom_mn_state_abbr_check CHECK (state_abbr = 'MN');
ALTER TABLE acs_2012.blockgroup_geom_nm ADD CONSTRAINT blockgroup_geom_nm_state_abbr_check CHECK (state_abbr = 'NM');
ALTER TABLE acs_2012.blockgroup_geom_nv ADD CONSTRAINT blockgroup_geom_nv_state_abbr_check CHECK (state_abbr = 'NV');
ALTER TABLE acs_2012.blockgroup_geom_mo ADD CONSTRAINT blockgroup_geom_mo_state_abbr_check CHECK (state_abbr = 'MO');
ALTER TABLE acs_2012.blockgroup_geom_ny ADD CONSTRAINT blockgroup_geom_ny_state_abbr_check CHECK (state_abbr = 'NY');
ALTER TABLE acs_2012.blockgroup_geom_ms ADD CONSTRAINT blockgroup_geom_ms_state_abbr_check CHECK (state_abbr = 'MS');
ALTER TABLE acs_2012.blockgroup_geom_oh ADD CONSTRAINT blockgroup_geom_oh_state_abbr_check CHECK (state_abbr = 'OH');
ALTER TABLE acs_2012.blockgroup_geom_ks ADD CONSTRAINT blockgroup_geom_ks_state_abbr_check CHECK (state_abbr = 'KS');
ALTER TABLE acs_2012.blockgroup_geom_mt ADD CONSTRAINT blockgroup_geom_mt_state_abbr_check CHECK (state_abbr = 'MT');
ALTER TABLE acs_2012.blockgroup_geom_in ADD CONSTRAINT blockgroup_geom_in_state_abbr_check CHECK (state_abbr = 'IN');
ALTER TABLE acs_2012.blockgroup_geom_ok ADD CONSTRAINT blockgroup_geom_ok_state_abbr_check CHECK (state_abbr = 'OK');
ALTER TABLE acs_2012.blockgroup_geom_ky ADD CONSTRAINT blockgroup_geom_ky_state_abbr_check CHECK (state_abbr = 'KY');
ALTER TABLE acs_2012.blockgroup_geom_nc ADD CONSTRAINT blockgroup_geom_nc_state_abbr_check CHECK (state_abbr = 'NC');
ALTER TABLE acs_2012.blockgroup_geom_or ADD CONSTRAINT blockgroup_geom_or_state_abbr_check CHECK (state_abbr = 'OR');
ALTER TABLE acs_2012.blockgroup_geom_la ADD CONSTRAINT blockgroup_geom_la_state_abbr_check CHECK (state_abbr = 'LA');
ALTER TABLE acs_2012.blockgroup_geom_nd ADD CONSTRAINT blockgroup_geom_nd_state_abbr_check CHECK (state_abbr = 'ND');
ALTER TABLE acs_2012.blockgroup_geom_ma ADD CONSTRAINT blockgroup_geom_ma_state_abbr_check CHECK (state_abbr = 'MA');
ALTER TABLE acs_2012.blockgroup_geom_pa ADD CONSTRAINT blockgroup_geom_pa_state_abbr_check CHECK (state_abbr = 'PA');
ALTER TABLE acs_2012.blockgroup_geom_ne ADD CONSTRAINT blockgroup_geom_ne_state_abbr_check CHECK (state_abbr = 'NE');
ALTER TABLE acs_2012.blockgroup_geom_md ADD CONSTRAINT blockgroup_geom_md_state_abbr_check CHECK (state_abbr = 'MD');
ALTER TABLE acs_2012.blockgroup_geom_me ADD CONSTRAINT blockgroup_geom_me_state_abbr_check CHECK (state_abbr = 'ME');
ALTER TABLE acs_2012.blockgroup_geom_pr ADD CONSTRAINT blockgroup_geom_pr_state_abbr_check CHECK (state_abbr = 'PR');
ALTER TABLE acs_2012.blockgroup_geom_ri ADD CONSTRAINT blockgroup_geom_ri_state_abbr_check CHECK (state_abbr = 'RI');
ALTER TABLE acs_2012.blockgroup_geom_sc ADD CONSTRAINT blockgroup_geom_sc_state_abbr_check CHECK (state_abbr = 'SC');
ALTER TABLE acs_2012.blockgroup_geom_sd ADD CONSTRAINT blockgroup_geom_sd_state_abbr_check CHECK (state_abbr = 'SD');
ALTER TABLE acs_2012.blockgroup_geom_tn ADD CONSTRAINT blockgroup_geom_tn_state_abbr_check CHECK (state_abbr = 'TN');
ALTER TABLE acs_2012.blockgroup_geom_tx ADD CONSTRAINT blockgroup_geom_tx_state_abbr_check CHECK (state_abbr = 'TX');
ALTER TABLE acs_2012.blockgroup_geom_ut ADD CONSTRAINT blockgroup_geom_ut_state_abbr_check CHECK (state_abbr = 'UT');
ALTER TABLE acs_2012.blockgroup_geom_va ADD CONSTRAINT blockgroup_geom_va_state_abbr_check CHECK (state_abbr = 'VA');
ALTER TABLE acs_2012.blockgroup_geom_vt ADD CONSTRAINT blockgroup_geom_vt_state_abbr_check CHECK (state_abbr = 'VT');
ALTER TABLE acs_2012.blockgroup_geom_wa ADD CONSTRAINT blockgroup_geom_wa_state_abbr_check CHECK (state_abbr = 'WA');
ALTER TABLE acs_2012.blockgroup_geom_wi ADD CONSTRAINT blockgroup_geom_wi_state_abbr_check CHECK (state_abbr = 'WI');
ALTER TABLE acs_2012.blockgroup_geom_wv ADD CONSTRAINT blockgroup_geom_wv_state_abbr_check CHECK (state_abbr = 'WV');
ALTER TABLE acs_2012.blockgroup_geom_wy ADD CONSTRAINT blockgroup_geom_wy_state_abbr_check CHECK (state_abbr = 'WY');

-- add a constraint on the fips code too
ALTER TABLE acs_2012.blockgroup_geom_al ADD CONSTRAINT blockgroup_geom_al_state_fips_check CHECK (statefp = '01');
ALTER TABLE acs_2012.blockgroup_geom_ar ADD CONSTRAINT blockgroup_geom_ar_state_fips_check CHECK (statefp = '05');
ALTER TABLE acs_2012.blockgroup_geom_az ADD CONSTRAINT blockgroup_geom_az_state_fips_check CHECK (statefp = '04');
ALTER TABLE acs_2012.blockgroup_geom_ca ADD CONSTRAINT blockgroup_geom_ca_state_fips_check CHECK (statefp = '06');
ALTER TABLE acs_2012.blockgroup_geom_ak ADD CONSTRAINT blockgroup_geom_ak_state_fips_check CHECK (statefp = '02');
ALTER TABLE acs_2012.blockgroup_geom_co ADD CONSTRAINT blockgroup_geom_co_state_fips_check CHECK (statefp = '08');
ALTER TABLE acs_2012.blockgroup_geom_ct ADD CONSTRAINT blockgroup_geom_ct_state_fips_check CHECK (statefp = '09');
ALTER TABLE acs_2012.blockgroup_geom_dc ADD CONSTRAINT blockgroup_geom_dc_state_fips_check CHECK (statefp = '11');
ALTER TABLE acs_2012.blockgroup_geom_de ADD CONSTRAINT blockgroup_geom_de_state_fips_check CHECK (statefp = '10');
ALTER TABLE acs_2012.blockgroup_geom_fl ADD CONSTRAINT blockgroup_geom_fl_state_fips_check CHECK (statefp = '12');
ALTER TABLE acs_2012.blockgroup_geom_ga ADD CONSTRAINT blockgroup_geom_ga_state_fips_check CHECK (statefp = '13');
ALTER TABLE acs_2012.blockgroup_geom_hi ADD CONSTRAINT blockgroup_geom_hi_state_fips_check CHECK (statefp = '15');
ALTER TABLE acs_2012.blockgroup_geom_ia ADD CONSTRAINT blockgroup_geom_ia_state_fips_check CHECK (statefp = '19');
ALTER TABLE acs_2012.blockgroup_geom_id ADD CONSTRAINT blockgroup_geom_id_state_fips_check CHECK (statefp = '16');
ALTER TABLE acs_2012.blockgroup_geom_mi ADD CONSTRAINT blockgroup_geom_mi_state_fips_check CHECK (statefp = '26');
ALTER TABLE acs_2012.blockgroup_geom_nh ADD CONSTRAINT blockgroup_geom_nh_state_fips_check CHECK (statefp = '33');
ALTER TABLE acs_2012.blockgroup_geom_nj ADD CONSTRAINT blockgroup_geom_nj_state_fips_check CHECK (statefp = '34');
ALTER TABLE acs_2012.blockgroup_geom_il ADD CONSTRAINT blockgroup_geom_il_state_fips_check CHECK (statefp = '17');
ALTER TABLE acs_2012.blockgroup_geom_mn ADD CONSTRAINT blockgroup_geom_mn_state_fips_check CHECK (statefp = '27');
ALTER TABLE acs_2012.blockgroup_geom_nm ADD CONSTRAINT blockgroup_geom_nm_state_fips_check CHECK (statefp = '35');
ALTER TABLE acs_2012.blockgroup_geom_nv ADD CONSTRAINT blockgroup_geom_nv_state_fips_check CHECK (statefp = '32');
ALTER TABLE acs_2012.blockgroup_geom_mo ADD CONSTRAINT blockgroup_geom_mo_state_fips_check CHECK (statefp = '29');
ALTER TABLE acs_2012.blockgroup_geom_ny ADD CONSTRAINT blockgroup_geom_ny_state_fips_check CHECK (statefp = '36');
ALTER TABLE acs_2012.blockgroup_geom_ms ADD CONSTRAINT blockgroup_geom_ms_state_fips_check CHECK (statefp = '28');
ALTER TABLE acs_2012.blockgroup_geom_oh ADD CONSTRAINT blockgroup_geom_oh_state_fips_check CHECK (statefp = '39');
ALTER TABLE acs_2012.blockgroup_geom_ks ADD CONSTRAINT blockgroup_geom_ks_state_fips_check CHECK (statefp = '20');
ALTER TABLE acs_2012.blockgroup_geom_mt ADD CONSTRAINT blockgroup_geom_mt_state_fips_check CHECK (statefp = '30');
ALTER TABLE acs_2012.blockgroup_geom_in ADD CONSTRAINT blockgroup_geom_in_state_fips_check CHECK (statefp = '15');
ALTER TABLE acs_2012.blockgroup_geom_ok ADD CONSTRAINT blockgroup_geom_ok_state_fips_check CHECK (statefp = '40');
ALTER TABLE acs_2012.blockgroup_geom_ky ADD CONSTRAINT blockgroup_geom_ky_state_fips_check CHECK (statefp = '21');
ALTER TABLE acs_2012.blockgroup_geom_nc ADD CONSTRAINT blockgroup_geom_nc_state_fips_check CHECK (statefp = '37');
ALTER TABLE acs_2012.blockgroup_geom_or ADD CONSTRAINT blockgroup_geom_or_state_fips_check CHECK (statefp = '41');
ALTER TABLE acs_2012.blockgroup_geom_la ADD CONSTRAINT blockgroup_geom_la_state_fips_check CHECK (statefp = '22');
ALTER TABLE acs_2012.blockgroup_geom_nd ADD CONSTRAINT blockgroup_geom_nd_state_fips_check CHECK (statefp = '38');
ALTER TABLE acs_2012.blockgroup_geom_ma ADD CONSTRAINT blockgroup_geom_ma_state_fips_check CHECK (statefp = '25');
ALTER TABLE acs_2012.blockgroup_geom_pa ADD CONSTRAINT blockgroup_geom_pa_state_fips_check CHECK (statefp = '42');
ALTER TABLE acs_2012.blockgroup_geom_ne ADD CONSTRAINT blockgroup_geom_ne_state_fips_check CHECK (statefp = '31');
ALTER TABLE acs_2012.blockgroup_geom_md ADD CONSTRAINT blockgroup_geom_md_state_fips_check CHECK (statefp = '24');
ALTER TABLE acs_2012.blockgroup_geom_me ADD CONSTRAINT blockgroup_geom_me_state_fips_check CHECK (statefp = '23');
ALTER TABLE acs_2012.blockgroup_geom_pr ADD CONSTRAINT blockgroup_geom_pr_state_fips_check CHECK (statefp = '72');
ALTER TABLE acs_2012.blockgroup_geom_ri ADD CONSTRAINT blockgroup_geom_ri_state_fips_check CHECK (statefp = '44');
ALTER TABLE acs_2012.blockgroup_geom_sc ADD CONSTRAINT blockgroup_geom_sc_state_fips_check CHECK (statefp = '45');
ALTER TABLE acs_2012.blockgroup_geom_sd ADD CONSTRAINT blockgroup_geom_sd_state_fips_check CHECK (statefp = '46');
ALTER TABLE acs_2012.blockgroup_geom_tn ADD CONSTRAINT blockgroup_geom_tn_state_fips_check CHECK (statefp = '47');
ALTER TABLE acs_2012.blockgroup_geom_tx ADD CONSTRAINT blockgroup_geom_tx_state_fips_check CHECK (statefp = '48');
ALTER TABLE acs_2012.blockgroup_geom_ut ADD CONSTRAINT blockgroup_geom_ut_state_fips_check CHECK (statefp = '49');
ALTER TABLE acs_2012.blockgroup_geom_va ADD CONSTRAINT blockgroup_geom_va_state_fips_check CHECK (statefp = '51');
ALTER TABLE acs_2012.blockgroup_geom_vt ADD CONSTRAINT blockgroup_geom_vt_state_fips_check CHECK (statefp = '50');
ALTER TABLE acs_2012.blockgroup_geom_wa ADD CONSTRAINT blockgroup_geom_wa_state_fips_check CHECK (statefp = '53');
ALTER TABLE acs_2012.blockgroup_geom_wi ADD CONSTRAINT blockgroup_geom_wi_state_fips_check CHECK (statefp = '55');
ALTER TABLE acs_2012.blockgroup_geom_wv ADD CONSTRAINT blockgroup_geom_wv_state_fips_check CHECK (statefp = '54');
ALTER TABLE acs_2012.blockgroup_geom_wy ADD CONSTRAINT blockgroup_geom_wy_state_fips_check CHECK (statefp = '56');

-- change type of aland to always be numeric
ALTER TABLE acs_2012.blockgroup_geom_al ALTER COLUMN aland TYPE numeric using aland::numeric;
ALTER TABLE acs_2012.blockgroup_geom_ar ALTER COLUMN aland TYPE numeric using aland::numeric;
ALTER TABLE acs_2012.blockgroup_geom_az ALTER COLUMN aland TYPE numeric using aland::numeric;
ALTER TABLE acs_2012.blockgroup_geom_ca ALTER COLUMN aland TYPE numeric using aland::numeric;
ALTER TABLE acs_2012.blockgroup_geom_ak ALTER COLUMN aland TYPE numeric using aland::numeric;
ALTER TABLE acs_2012.blockgroup_geom_co ALTER COLUMN aland TYPE numeric using aland::numeric;
ALTER TABLE acs_2012.blockgroup_geom_ct ALTER COLUMN aland TYPE numeric using aland::numeric;
ALTER TABLE acs_2012.blockgroup_geom_dc ALTER COLUMN aland TYPE numeric using aland::numeric;
ALTER TABLE acs_2012.blockgroup_geom_de ALTER COLUMN aland TYPE numeric using aland::numeric;
ALTER TABLE acs_2012.blockgroup_geom_fl ALTER COLUMN aland TYPE numeric using aland::numeric;
ALTER TABLE acs_2012.blockgroup_geom_ga ALTER COLUMN aland TYPE numeric using aland::numeric;
ALTER TABLE acs_2012.blockgroup_geom_hi ALTER COLUMN aland TYPE numeric using aland::numeric;
ALTER TABLE acs_2012.blockgroup_geom_ia ALTER COLUMN aland TYPE numeric using aland::numeric;
ALTER TABLE acs_2012.blockgroup_geom_id ALTER COLUMN aland TYPE numeric using aland::numeric;
ALTER TABLE acs_2012.blockgroup_geom_mi ALTER COLUMN aland TYPE numeric using aland::numeric;
ALTER TABLE acs_2012.blockgroup_geom_nh ALTER COLUMN aland TYPE numeric using aland::numeric;
ALTER TABLE acs_2012.blockgroup_geom_nj ALTER COLUMN aland TYPE numeric using aland::numeric;
ALTER TABLE acs_2012.blockgroup_geom_il ALTER COLUMN aland TYPE numeric using aland::numeric;
ALTER TABLE acs_2012.blockgroup_geom_mn ALTER COLUMN aland TYPE numeric using aland::numeric;
ALTER TABLE acs_2012.blockgroup_geom_nm ALTER COLUMN aland TYPE numeric using aland::numeric;
ALTER TABLE acs_2012.blockgroup_geom_nv ALTER COLUMN aland TYPE numeric using aland::numeric;
ALTER TABLE acs_2012.blockgroup_geom_mo ALTER COLUMN aland TYPE numeric using aland::numeric;
ALTER TABLE acs_2012.blockgroup_geom_ny ALTER COLUMN aland TYPE numeric using aland::numeric;
ALTER TABLE acs_2012.blockgroup_geom_ms ALTER COLUMN aland TYPE numeric using aland::numeric;
ALTER TABLE acs_2012.blockgroup_geom_oh ALTER COLUMN aland TYPE numeric using aland::numeric;
ALTER TABLE acs_2012.blockgroup_geom_ks ALTER COLUMN aland TYPE numeric using aland::numeric;
ALTER TABLE acs_2012.blockgroup_geom_mt ALTER COLUMN aland TYPE numeric using aland::numeric;
ALTER TABLE acs_2012.blockgroup_geom_in ALTER COLUMN aland TYPE numeric using aland::numeric;
ALTER TABLE acs_2012.blockgroup_geom_ok ALTER COLUMN aland TYPE numeric using aland::numeric;
ALTER TABLE acs_2012.blockgroup_geom_ky ALTER COLUMN aland TYPE numeric using aland::numeric;
ALTER TABLE acs_2012.blockgroup_geom_nc ALTER COLUMN aland TYPE numeric using aland::numeric;
ALTER TABLE acs_2012.blockgroup_geom_or ALTER COLUMN aland TYPE numeric using aland::numeric;
ALTER TABLE acs_2012.blockgroup_geom_la ALTER COLUMN aland TYPE numeric using aland::numeric;
ALTER TABLE acs_2012.blockgroup_geom_nd ALTER COLUMN aland TYPE numeric using aland::numeric;
ALTER TABLE acs_2012.blockgroup_geom_ma ALTER COLUMN aland TYPE numeric using aland::numeric;
ALTER TABLE acs_2012.blockgroup_geom_pa ALTER COLUMN aland TYPE numeric using aland::numeric;
ALTER TABLE acs_2012.blockgroup_geom_ne ALTER COLUMN aland TYPE numeric using aland::numeric;
ALTER TABLE acs_2012.blockgroup_geom_md ALTER COLUMN aland TYPE numeric using aland::numeric;
ALTER TABLE acs_2012.blockgroup_geom_me ALTER COLUMN aland TYPE numeric using aland::numeric;
ALTER TABLE acs_2012.blockgroup_geom_pr ALTER COLUMN aland TYPE numeric using aland::numeric;
ALTER TABLE acs_2012.blockgroup_geom_ri ALTER COLUMN aland TYPE numeric using aland::numeric;
ALTER TABLE acs_2012.blockgroup_geom_sc ALTER COLUMN aland TYPE numeric using aland::numeric;
ALTER TABLE acs_2012.blockgroup_geom_sd ALTER COLUMN aland TYPE numeric using aland::numeric;
ALTER TABLE acs_2012.blockgroup_geom_tn ALTER COLUMN aland TYPE numeric using aland::numeric;
ALTER TABLE acs_2012.blockgroup_geom_tx ALTER COLUMN aland TYPE numeric using aland::numeric;
ALTER TABLE acs_2012.blockgroup_geom_ut ALTER COLUMN aland TYPE numeric using aland::numeric;
ALTER TABLE acs_2012.blockgroup_geom_va ALTER COLUMN aland TYPE numeric using aland::numeric;
ALTER TABLE acs_2012.blockgroup_geom_vt ALTER COLUMN aland TYPE numeric using aland::numeric;
ALTER TABLE acs_2012.blockgroup_geom_wa ALTER COLUMN aland TYPE numeric using aland::numeric;
ALTER TABLE acs_2012.blockgroup_geom_wi ALTER COLUMN aland TYPE numeric using aland::numeric;
ALTER TABLE acs_2012.blockgroup_geom_wv ALTER COLUMN aland TYPE numeric using aland::numeric;
ALTER TABLE acs_2012.blockgroup_geom_wy ALTER COLUMN aland TYPE numeric using aland::numeric;

-- same for awater
ALTER TABLE acs_2012.blockgroup_geom_al ALTER COLUMN awater TYPE numeric using awater::numeric;
ALTER TABLE acs_2012.blockgroup_geom_ar ALTER COLUMN awater TYPE numeric using awater::numeric;
ALTER TABLE acs_2012.blockgroup_geom_az ALTER COLUMN awater TYPE numeric using awater::numeric;
ALTER TABLE acs_2012.blockgroup_geom_ca ALTER COLUMN awater TYPE numeric using awater::numeric;
ALTER TABLE acs_2012.blockgroup_geom_ak ALTER COLUMN awater TYPE numeric using awater::numeric;
ALTER TABLE acs_2012.blockgroup_geom_co ALTER COLUMN awater TYPE numeric using awater::numeric;
ALTER TABLE acs_2012.blockgroup_geom_ct ALTER COLUMN awater TYPE numeric using awater::numeric;
ALTER TABLE acs_2012.blockgroup_geom_dc ALTER COLUMN awater TYPE numeric using awater::numeric;
ALTER TABLE acs_2012.blockgroup_geom_de ALTER COLUMN awater TYPE numeric using awater::numeric;
ALTER TABLE acs_2012.blockgroup_geom_fl ALTER COLUMN awater TYPE numeric using awater::numeric;
ALTER TABLE acs_2012.blockgroup_geom_ga ALTER COLUMN awater TYPE numeric using awater::numeric;
ALTER TABLE acs_2012.blockgroup_geom_hi ALTER COLUMN awater TYPE numeric using awater::numeric;
ALTER TABLE acs_2012.blockgroup_geom_ia ALTER COLUMN awater TYPE numeric using awater::numeric;
ALTER TABLE acs_2012.blockgroup_geom_id ALTER COLUMN awater TYPE numeric using awater::numeric;
ALTER TABLE acs_2012.blockgroup_geom_mi ALTER COLUMN awater TYPE numeric using awater::numeric;
ALTER TABLE acs_2012.blockgroup_geom_nh ALTER COLUMN awater TYPE numeric using awater::numeric;
ALTER TABLE acs_2012.blockgroup_geom_nj ALTER COLUMN awater TYPE numeric using awater::numeric;
ALTER TABLE acs_2012.blockgroup_geom_il ALTER COLUMN awater TYPE numeric using awater::numeric;
ALTER TABLE acs_2012.blockgroup_geom_mn ALTER COLUMN awater TYPE numeric using awater::numeric;
ALTER TABLE acs_2012.blockgroup_geom_nm ALTER COLUMN awater TYPE numeric using awater::numeric;
ALTER TABLE acs_2012.blockgroup_geom_nv ALTER COLUMN awater TYPE numeric using awater::numeric;
ALTER TABLE acs_2012.blockgroup_geom_mo ALTER COLUMN awater TYPE numeric using awater::numeric;
ALTER TABLE acs_2012.blockgroup_geom_ny ALTER COLUMN awater TYPE numeric using awater::numeric;
ALTER TABLE acs_2012.blockgroup_geom_ms ALTER COLUMN awater TYPE numeric using awater::numeric;
ALTER TABLE acs_2012.blockgroup_geom_oh ALTER COLUMN awater TYPE numeric using awater::numeric;
ALTER TABLE acs_2012.blockgroup_geom_ks ALTER COLUMN awater TYPE numeric using awater::numeric;
ALTER TABLE acs_2012.blockgroup_geom_mt ALTER COLUMN awater TYPE numeric using awater::numeric;
ALTER TABLE acs_2012.blockgroup_geom_in ALTER COLUMN awater TYPE numeric using awater::numeric;
ALTER TABLE acs_2012.blockgroup_geom_ok ALTER COLUMN awater TYPE numeric using awater::numeric;
ALTER TABLE acs_2012.blockgroup_geom_ky ALTER COLUMN awater TYPE numeric using awater::numeric;
ALTER TABLE acs_2012.blockgroup_geom_nc ALTER COLUMN awater TYPE numeric using awater::numeric;
ALTER TABLE acs_2012.blockgroup_geom_or ALTER COLUMN awater TYPE numeric using awater::numeric;
ALTER TABLE acs_2012.blockgroup_geom_la ALTER COLUMN awater TYPE numeric using awater::numeric;
ALTER TABLE acs_2012.blockgroup_geom_nd ALTER COLUMN awater TYPE numeric using awater::numeric;
ALTER TABLE acs_2012.blockgroup_geom_ma ALTER COLUMN awater TYPE numeric using awater::numeric;
ALTER TABLE acs_2012.blockgroup_geom_pa ALTER COLUMN awater TYPE numeric using awater::numeric;
ALTER TABLE acs_2012.blockgroup_geom_ne ALTER COLUMN awater TYPE numeric using awater::numeric;
ALTER TABLE acs_2012.blockgroup_geom_md ALTER COLUMN awater TYPE numeric using awater::numeric;
ALTER TABLE acs_2012.blockgroup_geom_me ALTER COLUMN awater TYPE numeric using awater::numeric;
ALTER TABLE acs_2012.blockgroup_geom_pr ALTER COLUMN awater TYPE numeric using awater::numeric;
ALTER TABLE acs_2012.blockgroup_geom_ri ALTER COLUMN awater TYPE numeric using awater::numeric;
ALTER TABLE acs_2012.blockgroup_geom_sc ALTER COLUMN awater TYPE numeric using awater::numeric;
ALTER TABLE acs_2012.blockgroup_geom_sd ALTER COLUMN awater TYPE numeric using awater::numeric;
ALTER TABLE acs_2012.blockgroup_geom_tn ALTER COLUMN awater TYPE numeric using awater::numeric;
ALTER TABLE acs_2012.blockgroup_geom_tx ALTER COLUMN awater TYPE numeric using awater::numeric;
ALTER TABLE acs_2012.blockgroup_geom_ut ALTER COLUMN awater TYPE numeric using awater::numeric;
ALTER TABLE acs_2012.blockgroup_geom_va ALTER COLUMN awater TYPE numeric using awater::numeric;
ALTER TABLE acs_2012.blockgroup_geom_vt ALTER COLUMN awater TYPE numeric using awater::numeric;
ALTER TABLE acs_2012.blockgroup_geom_wa ALTER COLUMN awater TYPE numeric using awater::numeric;
ALTER TABLE acs_2012.blockgroup_geom_wi ALTER COLUMN awater TYPE numeric using awater::numeric;
ALTER TABLE acs_2012.blockgroup_geom_wv ALTER COLUMN awater TYPE numeric using awater::numeric;
ALTER TABLE acs_2012.blockgroup_geom_wy ALTER COLUMN awater TYPE numeric using awater::numeric;

-- standardize length of gisjoin column
ALTER TABLE acs_2012.blockgroup_geom_al ALTER COLUMN gisjoin TYPE CHARACTER VARYING(15);
ALTER TABLE acs_2012.blockgroup_geom_ar ALTER COLUMN gisjoin TYPE CHARACTER VARYING(15);
ALTER TABLE acs_2012.blockgroup_geom_az ALTER COLUMN gisjoin TYPE CHARACTER VARYING(15);
ALTER TABLE acs_2012.blockgroup_geom_ca ALTER COLUMN gisjoin TYPE CHARACTER VARYING(15);
ALTER TABLE acs_2012.blockgroup_geom_ak ALTER COLUMN gisjoin TYPE CHARACTER VARYING(15);
ALTER TABLE acs_2012.blockgroup_geom_co ALTER COLUMN gisjoin TYPE CHARACTER VARYING(15);
ALTER TABLE acs_2012.blockgroup_geom_ct ALTER COLUMN gisjoin TYPE CHARACTER VARYING(15);
ALTER TABLE acs_2012.blockgroup_geom_dc ALTER COLUMN gisjoin TYPE CHARACTER VARYING(15);
ALTER TABLE acs_2012.blockgroup_geom_de ALTER COLUMN gisjoin TYPE CHARACTER VARYING(15);
ALTER TABLE acs_2012.blockgroup_geom_fl ALTER COLUMN gisjoin TYPE CHARACTER VARYING(15);
ALTER TABLE acs_2012.blockgroup_geom_ga ALTER COLUMN gisjoin TYPE CHARACTER VARYING(15);
ALTER TABLE acs_2012.blockgroup_geom_hi ALTER COLUMN gisjoin TYPE CHARACTER VARYING(15);
ALTER TABLE acs_2012.blockgroup_geom_ia ALTER COLUMN gisjoin TYPE CHARACTER VARYING(15);
ALTER TABLE acs_2012.blockgroup_geom_id ALTER COLUMN gisjoin TYPE CHARACTER VARYING(15);
ALTER TABLE acs_2012.blockgroup_geom_mi ALTER COLUMN gisjoin TYPE CHARACTER VARYING(15);
ALTER TABLE acs_2012.blockgroup_geom_nh ALTER COLUMN gisjoin TYPE CHARACTER VARYING(15);
ALTER TABLE acs_2012.blockgroup_geom_nj ALTER COLUMN gisjoin TYPE CHARACTER VARYING(15);
ALTER TABLE acs_2012.blockgroup_geom_il ALTER COLUMN gisjoin TYPE CHARACTER VARYING(15);
ALTER TABLE acs_2012.blockgroup_geom_mn ALTER COLUMN gisjoin TYPE CHARACTER VARYING(15);
ALTER TABLE acs_2012.blockgroup_geom_nm ALTER COLUMN gisjoin TYPE CHARACTER VARYING(15);
ALTER TABLE acs_2012.blockgroup_geom_nv ALTER COLUMN gisjoin TYPE CHARACTER VARYING(15);
ALTER TABLE acs_2012.blockgroup_geom_mo ALTER COLUMN gisjoin TYPE CHARACTER VARYING(15);
ALTER TABLE acs_2012.blockgroup_geom_ny ALTER COLUMN gisjoin TYPE CHARACTER VARYING(15);
ALTER TABLE acs_2012.blockgroup_geom_ms ALTER COLUMN gisjoin TYPE CHARACTER VARYING(15);
ALTER TABLE acs_2012.blockgroup_geom_oh ALTER COLUMN gisjoin TYPE CHARACTER VARYING(15);
ALTER TABLE acs_2012.blockgroup_geom_ks ALTER COLUMN gisjoin TYPE CHARACTER VARYING(15);
ALTER TABLE acs_2012.blockgroup_geom_mt ALTER COLUMN gisjoin TYPE CHARACTER VARYING(15);
ALTER TABLE acs_2012.blockgroup_geom_in ALTER COLUMN gisjoin TYPE CHARACTER VARYING(15);
ALTER TABLE acs_2012.blockgroup_geom_ok ALTER COLUMN gisjoin TYPE CHARACTER VARYING(15);
ALTER TABLE acs_2012.blockgroup_geom_ky ALTER COLUMN gisjoin TYPE CHARACTER VARYING(15);
ALTER TABLE acs_2012.blockgroup_geom_nc ALTER COLUMN gisjoin TYPE CHARACTER VARYING(15);
ALTER TABLE acs_2012.blockgroup_geom_or ALTER COLUMN gisjoin TYPE CHARACTER VARYING(15);
ALTER TABLE acs_2012.blockgroup_geom_la ALTER COLUMN gisjoin TYPE CHARACTER VARYING(15);
ALTER TABLE acs_2012.blockgroup_geom_nd ALTER COLUMN gisjoin TYPE CHARACTER VARYING(15);
ALTER TABLE acs_2012.blockgroup_geom_ma ALTER COLUMN gisjoin TYPE CHARACTER VARYING(15);
ALTER TABLE acs_2012.blockgroup_geom_pa ALTER COLUMN gisjoin TYPE CHARACTER VARYING(15);
ALTER TABLE acs_2012.blockgroup_geom_ne ALTER COLUMN gisjoin TYPE CHARACTER VARYING(15);
ALTER TABLE acs_2012.blockgroup_geom_md ALTER COLUMN gisjoin TYPE CHARACTER VARYING(15);
ALTER TABLE acs_2012.blockgroup_geom_me ALTER COLUMN gisjoin TYPE CHARACTER VARYING(15);
ALTER TABLE acs_2012.blockgroup_geom_pr ALTER COLUMN gisjoin TYPE CHARACTER VARYING(15);
ALTER TABLE acs_2012.blockgroup_geom_ri ALTER COLUMN gisjoin TYPE CHARACTER VARYING(15);
ALTER TABLE acs_2012.blockgroup_geom_sc ALTER COLUMN gisjoin TYPE CHARACTER VARYING(15);
ALTER TABLE acs_2012.blockgroup_geom_sd ALTER COLUMN gisjoin TYPE CHARACTER VARYING(15);
ALTER TABLE acs_2012.blockgroup_geom_tn ALTER COLUMN gisjoin TYPE CHARACTER VARYING(15);
ALTER TABLE acs_2012.blockgroup_geom_tx ALTER COLUMN gisjoin TYPE CHARACTER VARYING(15);
ALTER TABLE acs_2012.blockgroup_geom_ut ALTER COLUMN gisjoin TYPE CHARACTER VARYING(15);
ALTER TABLE acs_2012.blockgroup_geom_va ALTER COLUMN gisjoin TYPE CHARACTER VARYING(15);
ALTER TABLE acs_2012.blockgroup_geom_vt ALTER COLUMN gisjoin TYPE CHARACTER VARYING(15);
ALTER TABLE acs_2012.blockgroup_geom_wa ALTER COLUMN gisjoin TYPE CHARACTER VARYING(15);
ALTER TABLE acs_2012.blockgroup_geom_wi ALTER COLUMN gisjoin TYPE CHARACTER VARYING(15);
ALTER TABLE acs_2012.blockgroup_geom_wv ALTER COLUMN gisjoin TYPE CHARACTER VARYING(15);
ALTER TABLE acs_2012.blockgroup_geom_wy ALTER COLUMN gisjoin TYPE CHARACTER VARYING(15);


-- create parent table
Drop table if exists acs_2012.blockgroup_geom_parent;
CREATE TABLE acs_2012.blockgroup_geom_parent As
SELECT *
FROM acs_2012.blockgroup_geom_wy
LIMIT 0;

-- inherit children
ALTER TABLE acs_2012.blockgroup_geom_al INHERIT acs_2012.blockgroup_geom_parent;
ALTER TABLE acs_2012.blockgroup_geom_ar INHERIT acs_2012.blockgroup_geom_parent;
ALTER TABLE acs_2012.blockgroup_geom_az INHERIT acs_2012.blockgroup_geom_parent;
ALTER TABLE acs_2012.blockgroup_geom_ca INHERIT acs_2012.blockgroup_geom_parent;
ALTER TABLE acs_2012.blockgroup_geom_ak INHERIT acs_2012.blockgroup_geom_parent;
ALTER TABLE acs_2012.blockgroup_geom_co INHERIT acs_2012.blockgroup_geom_parent;
ALTER TABLE acs_2012.blockgroup_geom_ct INHERIT acs_2012.blockgroup_geom_parent;
ALTER TABLE acs_2012.blockgroup_geom_dc INHERIT acs_2012.blockgroup_geom_parent;
ALTER TABLE acs_2012.blockgroup_geom_de INHERIT acs_2012.blockgroup_geom_parent;
ALTER TABLE acs_2012.blockgroup_geom_fl INHERIT acs_2012.blockgroup_geom_parent;
ALTER TABLE acs_2012.blockgroup_geom_ga INHERIT acs_2012.blockgroup_geom_parent;
ALTER TABLE acs_2012.blockgroup_geom_hi INHERIT acs_2012.blockgroup_geom_parent;
ALTER TABLE acs_2012.blockgroup_geom_ia INHERIT acs_2012.blockgroup_geom_parent;
ALTER TABLE acs_2012.blockgroup_geom_id INHERIT acs_2012.blockgroup_geom_parent;
ALTER TABLE acs_2012.blockgroup_geom_mi INHERIT acs_2012.blockgroup_geom_parent;
ALTER TABLE acs_2012.blockgroup_geom_nh INHERIT acs_2012.blockgroup_geom_parent;
ALTER TABLE acs_2012.blockgroup_geom_nj INHERIT acs_2012.blockgroup_geom_parent;
ALTER TABLE acs_2012.blockgroup_geom_il INHERIT acs_2012.blockgroup_geom_parent;
ALTER TABLE acs_2012.blockgroup_geom_mn INHERIT acs_2012.blockgroup_geom_parent;
ALTER TABLE acs_2012.blockgroup_geom_nm INHERIT acs_2012.blockgroup_geom_parent;
ALTER TABLE acs_2012.blockgroup_geom_nv INHERIT acs_2012.blockgroup_geom_parent;
ALTER TABLE acs_2012.blockgroup_geom_mo INHERIT acs_2012.blockgroup_geom_parent;
ALTER TABLE acs_2012.blockgroup_geom_ny INHERIT acs_2012.blockgroup_geom_parent;
ALTER TABLE acs_2012.blockgroup_geom_ms INHERIT acs_2012.blockgroup_geom_parent;
ALTER TABLE acs_2012.blockgroup_geom_oh INHERIT acs_2012.blockgroup_geom_parent;
ALTER TABLE acs_2012.blockgroup_geom_ks INHERIT acs_2012.blockgroup_geom_parent;
ALTER TABLE acs_2012.blockgroup_geom_mt INHERIT acs_2012.blockgroup_geom_parent;
ALTER TABLE acs_2012.blockgroup_geom_in INHERIT acs_2012.blockgroup_geom_parent;
ALTER TABLE acs_2012.blockgroup_geom_ok INHERIT acs_2012.blockgroup_geom_parent;
ALTER TABLE acs_2012.blockgroup_geom_ky INHERIT acs_2012.blockgroup_geom_parent;
ALTER TABLE acs_2012.blockgroup_geom_nc INHERIT acs_2012.blockgroup_geom_parent;
ALTER TABLE acs_2012.blockgroup_geom_or INHERIT acs_2012.blockgroup_geom_parent;
ALTER TABLE acs_2012.blockgroup_geom_la INHERIT acs_2012.blockgroup_geom_parent;
ALTER TABLE acs_2012.blockgroup_geom_nd INHERIT acs_2012.blockgroup_geom_parent;
ALTER TABLE acs_2012.blockgroup_geom_ma INHERIT acs_2012.blockgroup_geom_parent;
ALTER TABLE acs_2012.blockgroup_geom_pa INHERIT acs_2012.blockgroup_geom_parent;
ALTER TABLE acs_2012.blockgroup_geom_ne INHERIT acs_2012.blockgroup_geom_parent;
ALTER TABLE acs_2012.blockgroup_geom_md INHERIT acs_2012.blockgroup_geom_parent;
ALTER TABLE acs_2012.blockgroup_geom_me INHERIT acs_2012.blockgroup_geom_parent;
ALTER TABLE acs_2012.blockgroup_geom_pr INHERIT acs_2012.blockgroup_geom_parent;
ALTER TABLE acs_2012.blockgroup_geom_ri INHERIT acs_2012.blockgroup_geom_parent;
ALTER TABLE acs_2012.blockgroup_geom_sc INHERIT acs_2012.blockgroup_geom_parent;
ALTER TABLE acs_2012.blockgroup_geom_sd INHERIT acs_2012.blockgroup_geom_parent;
ALTER TABLE acs_2012.blockgroup_geom_tn INHERIT acs_2012.blockgroup_geom_parent;
ALTER TABLE acs_2012.blockgroup_geom_tx INHERIT acs_2012.blockgroup_geom_parent;
ALTER TABLE acs_2012.blockgroup_geom_ut INHERIT acs_2012.blockgroup_geom_parent;
ALTER TABLE acs_2012.blockgroup_geom_va INHERIT acs_2012.blockgroup_geom_parent;
ALTER TABLE acs_2012.blockgroup_geom_vt INHERIT acs_2012.blockgroup_geom_parent;
ALTER TABLE acs_2012.blockgroup_geom_wa INHERIT acs_2012.blockgroup_geom_parent;
ALTER TABLE acs_2012.blockgroup_geom_wi INHERIT acs_2012.blockgroup_geom_parent;
ALTER TABLE acs_2012.blockgroup_geom_wv INHERIT acs_2012.blockgroup_geom_parent;
ALTER TABLE acs_2012.blockgroup_geom_wy INHERIT acs_2012.blockgroup_geom_parent;


-- make sure all tables were inherited
select distinct(state_abbr)
from acs_2012.blockgroup_geom_parent;

-- make sure no nulls geom_4326
select state_abbr, sum((the_geom_4326 is null)::integer)
from acs_2012.blockgroup_geom_parent
group by state_abbr;

-- acs_2012.blockgroup_geom_al
-- acs_2012.blockgroup_geom_ar
-- acs_2012.blockgroup_geom_az
-- acs_2012.blockgroup_geom_ca
-- acs_2012.blockgroup_geom_ak
-- acs_2012.blockgroup_geom_co
-- acs_2012.blockgroup_geom_ct
-- acs_2012.blockgroup_geom_dc
-- acs_2012.blockgroup_geom_de
-- acs_2012.blockgroup_geom_fl
-- acs_2012.blockgroup_geom_ga
-- acs_2012.blockgroup_geom_hi
-- acs_2012.blockgroup_geom_ia
-- acs_2012.blockgroup_geom_id
-- acs_2012.blockgroup_geom_mi
-- acs_2012.blockgroup_geom_nh
-- acs_2012.blockgroup_geom_nj
-- acs_2012.blockgroup_geom_il
-- acs_2012.blockgroup_geom_mn
-- acs_2012.blockgroup_geom_nm
-- acs_2012.blockgroup_geom_nv
-- acs_2012.blockgroup_geom_mo
-- acs_2012.blockgroup_geom_ny
-- acs_2012.blockgroup_geom_ms
-- acs_2012.blockgroup_geom_oh
-- acs_2012.blockgroup_geom_ks
-- acs_2012.blockgroup_geom_mt
-- acs_2012.blockgroup_geom_in
-- acs_2012.blockgroup_geom_ok
-- acs_2012.blockgroup_geom_ky
-- acs_2012.blockgroup_geom_nc
-- acs_2012.blockgroup_geom_or
-- acs_2012.blockgroup_geom_la
-- acs_2012.blockgroup_geom_nd
-- acs_2012.blockgroup_geom_ma
-- acs_2012.blockgroup_geom_pa
-- acs_2012.blockgroup_geom_ne
-- acs_2012.blockgroup_geom_md
-- acs_2012.blockgroup_geom_me
-- acs_2012.blockgroup_geom_pr
-- acs_2012.blockgroup_geom_ri
-- acs_2012.blockgroup_geom_sc
-- acs_2012.blockgroup_geom_sd
-- acs_2012.blockgroup_geom_tn
-- acs_2012.blockgroup_geom_tx
-- acs_2012.blockgroup_geom_ut
-- acs_2012.blockgroup_geom_va
-- acs_2012.blockgroup_geom_vt
-- acs_2012.blockgroup_geom_wa
-- acs_2012.blockgroup_geom_wi
-- acs_2012.blockgroup_geom_wv
-- acs_2012.blockgroup_geom_wy