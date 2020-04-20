set role 'diffusion-writers';

-- create parent table
DROP TABLE IF EXISTS diffusion_resource_wind.wind_resource_annual;
CREATE TABLE diffusion_resource_wind.wind_resource_annual 
(
        i integer,
        j integer,
        cf_bin integer,
        height integer,
        aep numeric,
        cf_avg numeric,
        turbine_id integer
);


-- inherit individual turbine tables to the parent tables
ALTER TABLE diffusion_resource_wind.wind_resource_annual_turbine_1 INHERIT diffusion_resource_wind.wind_resource_annual;
ALTER TABLE diffusion_resource_wind.wind_resource_annual_turbine_2 INHERIT diffusion_resource_wind.wind_resource_annual;
ALTER TABLE diffusion_resource_wind.wind_resource_annual_turbine_3 INHERIT diffusion_resource_wind.wind_resource_annual;
ALTER TABLE diffusion_resource_wind.wind_resource_annual_turbine_4 INHERIT diffusion_resource_wind.wind_resource_annual;
ALTER TABLE diffusion_resource_wind.wind_resource_annual_turbine_5 INHERIT diffusion_resource_wind.wind_resource_annual;
ALTER TABLE diffusion_resource_wind.wind_resource_annual_turbine_6 INHERIT diffusion_resource_wind.wind_resource_annual;
ALTER TABLE diffusion_resource_wind.wind_resource_annual_turbine_7 INHERIT diffusion_resource_wind.wind_resource_annual;
ALTER TABLE diffusion_resource_wind.wind_resource_annual_turbine_8 INHERIT diffusion_resource_wind.wind_resource_annual;

-- add check constraint on turbine_id
ALTER TABLE diffusion_resource_wind.wind_resource_annual_turbine_1 ADD CONSTRAINT wind_resource_annual_turbine_1_turbine_id_check CHECK (turbine_id = 1);
ALTER TABLE diffusion_resource_wind.wind_resource_annual_turbine_2 ADD CONSTRAINT wind_resource_annual_turbine_2_turbine_id_check CHECK (turbine_id = 2);
ALTER TABLE diffusion_resource_wind.wind_resource_annual_turbine_3 ADD CONSTRAINT wind_resource_annual_turbine_3_turbine_id_check CHECK (turbine_id = 3);
ALTER TABLE diffusion_resource_wind.wind_resource_annual_turbine_4 ADD CONSTRAINT wind_resource_annual_turbine_4_turbine_id_check CHECK (turbine_id = 4);
ALTER TABLE diffusion_resource_wind.wind_resource_annual_turbine_5 ADD CONSTRAINT wind_resource_annual_turbine_5_turbine_id_check CHECK (turbine_id = 5);
ALTER TABLE diffusion_resource_wind.wind_resource_annual_turbine_6 ADD CONSTRAINT wind_resource_annual_turbine_6_turbine_id_check CHECK (turbine_id = 6);
ALTER TABLE diffusion_resource_wind.wind_resource_annual_turbine_7 ADD CONSTRAINT wind_resource_annual_turbine_7_turbine_id_check CHECK (turbine_id = 7);
ALTER TABLE diffusion_resource_wind.wind_resource_annual_turbine_8 ADD CONSTRAINT wind_resource_annual_turbine_8_turbine_id_check CHECK (turbine_id = 8);

-- add primary keys (use combos of i, j, icf, and height)
ALTER TABLE diffusion_resource_wind.wind_resource_annual_turbine_1 ADD CONSTRAINT wind_resource_annual_turbine_1_pkey PRIMARY KEY(i, j, cf_bin, height);
ALTER TABLE diffusion_resource_wind.wind_resource_annual_turbine_2 ADD CONSTRAINT wind_resource_annual_turbine_2_pkey PRIMARY KEY(i, j, cf_bin, height);
ALTER TABLE diffusion_resource_wind.wind_resource_annual_turbine_3 ADD CONSTRAINT wind_resource_annual_turbine_3_pkey PRIMARY KEY(i, j, cf_bin, height);
ALTER TABLE diffusion_resource_wind.wind_resource_annual_turbine_4 ADD CONSTRAINT wind_resource_annual_turbine_4_pkey PRIMARY KEY(i, j, cf_bin, height);
ALTER TABLE diffusion_resource_wind.wind_resource_annual_turbine_5 ADD CONSTRAINT wind_resource_annual_turbine_5_pkey PRIMARY KEY(i, j, cf_bin, height);
ALTER TABLE diffusion_resource_wind.wind_resource_annual_turbine_6 ADD CONSTRAINT wind_resource_annual_turbine_6_pkey PRIMARY KEY(i, j, cf_bin, height);
ALTER TABLE diffusion_resource_wind.wind_resource_annual_turbine_7 ADD CONSTRAINT wind_resource_annual_turbine_7_pkey PRIMARY KEY(i, j, cf_bin, height);
ALTER TABLE diffusion_resource_wind.wind_resource_annual_turbine_8 ADD CONSTRAINT wind_resource_annual_turbine_8_pkey PRIMARY KEY(i, j, cf_bin, height);

-- add indices on i, j, cf_bin
CREATE INDEX wind_resource_annual_turbine_1_i_j_cf_bin_btree ON diffusion_resource_wind.wind_resource_annual_turbine_1 USING BTREE(i,j,cf_bin);
CREATE INDEX wind_resource_annual_turbine_2_i_j_cf_bin_btree ON diffusion_resource_wind.wind_resource_annual_turbine_2 USING BTREE(i,j,cf_bin);
CREATE INDEX wind_resource_annual_turbine_3_i_j_cf_bin_btree ON diffusion_resource_wind.wind_resource_annual_turbine_3 USING BTREE(i,j,cf_bin);
CREATE INDEX wind_resource_annual_turbine_4_i_j_cf_bin_btree ON diffusion_resource_wind.wind_resource_annual_turbine_4 USING BTREE(i,j,cf_bin);
CREATE INDEX wind_resource_annual_turbine_5_i_j_cf_bin_btree ON diffusion_resource_wind.wind_resource_annual_turbine_5 USING BTREE(i,j,cf_bin);
CREATE INDEX wind_resource_annual_turbine_6_i_j_cf_bin_btree ON diffusion_resource_wind.wind_resource_annual_turbine_6 USING BTREE(i,j,cf_bin);
CREATE INDEX wind_resource_annual_turbine_7_i_j_cf_bin_btree ON diffusion_resource_wind.wind_resource_annual_turbine_7 USING BTREE(i,j,cf_bin);
CREATE INDEX wind_resource_annual_turbine_8_i_j_cf_bin_btree ON diffusion_resource_wind.wind_resource_annual_turbine_8 USING BTREE(i,j,cf_bin);

-- add indices on height 
CREATE INDEX wind_resource_annual_turbine_1_height_btree ON diffusion_resource_wind.wind_resource_annual_turbine_1 USING BTREE(height);
CREATE INDEX wind_resource_annual_turbine_2_height_btree ON diffusion_resource_wind.wind_resource_annual_turbine_2 USING BTREE(height);
CREATE INDEX wind_resource_annual_turbine_3_height_btree ON diffusion_resource_wind.wind_resource_annual_turbine_3 USING BTREE(height);
CREATE INDEX wind_resource_annual_turbine_4_height_btree ON diffusion_resource_wind.wind_resource_annual_turbine_4 USING BTREE(height);
CREATE INDEX wind_resource_annual_turbine_5_height_btree ON diffusion_resource_wind.wind_resource_annual_turbine_5 USING BTREE(height);
CREATE INDEX wind_resource_annual_turbine_6_height_btree ON diffusion_resource_wind.wind_resource_annual_turbine_6 USING BTREE(height);
CREATE INDEX wind_resource_annual_turbine_7_height_btree ON diffusion_resource_wind.wind_resource_annual_turbine_7 USING BTREE(height);
CREATE INDEX wind_resource_annual_turbine_8_height_btree ON diffusion_resource_wind.wind_resource_annual_turbine_8 USING BTREE(height);

-- check count of parent table to ensure all tables were inherited
-- should be 888875 * 8 = 7111000
select count(*)
FROM diffusion_resource_wind.wind_resource_annual;
-- 7111000 all set

-- vacuum tables
VACUUM ANALYZE diffusion_resource_wind.wind_resource_annual_turbine_1;
VACUUM ANALYZE diffusion_resource_wind.wind_resource_annual_turbine_2;
VACUUM ANALYZE diffusion_resource_wind.wind_resource_annual_turbine_3;
VACUUM ANALYZE diffusion_resource_wind.wind_resource_annual_turbine_4;
VACUUM ANALYZE diffusion_resource_wind.wind_resource_annual_turbine_5;
VACUUM ANALYZE diffusion_resource_wind.wind_resource_annual_turbine_6;
VACUUM ANALYZE diffusion_resource_wind.wind_resource_annual_turbine_7;
VACUUM ANALYZE diffusion_resource_wind.wind_resource_annual_turbine_8;
VACUUM ANALYZE diffusion_resource_wind.wind_resource_annual;