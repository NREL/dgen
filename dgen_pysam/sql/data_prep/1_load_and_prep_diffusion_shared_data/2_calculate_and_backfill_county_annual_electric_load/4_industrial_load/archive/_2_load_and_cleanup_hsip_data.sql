-- load hsip tables using batch_load_hsip.py

-- find all column names that relate to naics
SELECT distinct(column_name)
FROM information_schema.columns
WHERE table_schema = 'hsip_2012'
and column_name LIKE '%naics%';

-- all naics codes are stored as one of the following:
--'naicscode', 'naics_code', 'naics'

-- need to rename all to be the same: 'naicscode', and all numeric
-- run hsip_renaming_naics.py
-- check that it worked (there should only be naicscode now)
SELECT distinct(column_name)
FROM information_schema.columns
WHERE table_schema = 'hsip_2012'
and column_name LIKE '%naics%';

-- make sure 6 digit naics code is formatted correctly
-- and
-- add 3-digit naics column
-- to do so, run: hsip_add_3digit_naics.py

-- alter geometry columns to remove typmod but add in constraints
-- run hsip_alter_geometry_types.py

-- add in table name and number to each table (this facilitates parallel processing of the parent table)
-- to do so, run: hsip_naics_add_table_name.py

-- create parent table for all tables with naics codes:
DROP TABLE IF EXISTS hsip_2012.all_points_with_naics;
CREATE TABLE hsip_2012.all_points_with_naics (
	gid integer,
	the_geom_4326 geometry,
	naicscode_3 character varying (3),
	table_name TEXT, 
	table_number INTEGER);

-- to inherit the child tables, run: hsip_naics_parent_table_inheritance.py
-- check that it worked:
SELECT Count(*) FROM hsip_2012.all_points_with_naics; -- 5,598,288 points in the parent table

-- if need to remove parent table, run: hsip_naics_parent_table_uninheritance.py
-- then:
-- DROP TABLE IF EXISTS hsip_2012.all_points_with_naics;

-- add in census region
-- create a lookup table (joins will be based on gid and table_number
CREATE TABLE hsip_2012.all_points_with_naics_census_regions_lookup (
	gid integer,
	table_number integer,
	census_region_long_name text);

-- run using parsel, with table_number as the "primary key" (doesn't need to be primary, just needs to allow splitting up the data)
SELECT parsel_2('dav-gis','hsip_2012.all_points_with_naics','table_number',
              'SELECT a.gid, a.table_number, b.region_long_name as census_region_long_name
		FROM hsip_2012.all_points_with_naics a
		lEFT JOIN eia.census_regions b
		ON ST_Intersects(a.the_geom_4326,b.the_geom_4326);',
	'hsip_2012.all_points_with_naics_census_regions_lookup','a',8);

-- create index on gid and table_number
CREATE INDEX census_regions_lookup_gid_btree ON hsip_2012.all_points_with_naics_census_regions_lookup using btree(gid);

CREATE INDEX census_regions_lookup_table_number_btree ON hsip_2012.all_points_with_naics_census_regions_lookup using btree(table_number);

VACUUM ANALYZE hsip_2012.all_points_with_naics_census_regions_lookup;


-- to index naicscode_3 and fac_type columns, run:
		-- navtec_fac_type_indexing.py
		-- hsip_naics_naicscode3_indexing.py

-- create parent table for navtec points
-- first find all of the columns shared by all 12 of the point tables
SELECT column_name, count(*)
        FROM information_schema.columns
        WHERE table_schema = 'hsip_2012'
        and table_name like 'navteq_%'
        group by column_name
        order by count
        ;

DROP TABLE IF EXISTS hsip_2012.all_navtec_pts;
CREATE TABLE hsip_2012.all_navtec_pts (
	gid integer,
	link_id numeric(10,0),
	poi_id numeric(10,0),
	seq_num integer,
	fac_type numeric(10,0),
	poi_name character varying(254),
	poi_langcd character varying(3),
	poi_nmtype character varying(1),
	poi_st_num character varying(10),
	st_num_ful character varying(25),
	st_nful_lc character varying(3),

	st_name character varying(240),
	st_langcd character varying(3),
	poi_st_sd character varying(1),
	acc_type character varying(1),
	ph_number character varying(15),
	chain_id numeric(10,0),
	nat_import character varying(1),
	private character varying(1),
	in_vicin character varying(1),
	num_parent numeric(10,0),
	num_child numeric(10,0),
	percfrref integer,
	van_city character varying(105),
	act_addr character varying(254),
	act_langcd character varying(3),
	act_st_nam character varying(50),
	act_st_num character varying(10),
	act_admin character varying(50),
	act_postal character varying(11),
	state_nm character varying(35),
	  the_geom_4326 geometry,
	  table_name text,
	  table_number integer);

-- to inherit the child tables, run: navtec_pts_parent_table_inheritance.py

-- check that it worked:
SELECT Count(*) FROM hsip_2012.all_navtec_pts; -- 2,476,764 points in the parent table