-- the database is designed in 3 parts:

-- Part 1 -- base
	-- consists of:
		-- diffusion_blocks
		-- diffusion_load_profiles
		-- diffusion_points
		-- diffusion_resource_solar
		-- diffusion_resource_wind
	-- these are large datasets that do not change very often, and therefore generally do not need to be included in minor model version updates
	-- therefore, they are only copied from gispgdb to bigde infrequently and are stored on bigde as:
	-- dgen_db_base

-- Part 2 -- archived/intermediate non-model data
	-- consists of:
		-- diffusion_data_* schemas
	-- these are not actively used in the model and never need to be cloned to bigde

-- Part 3 -- scaffold
	-- consists of:
		-- diffusion_config
		-- diffusion_geo
		-- diffusion_wind
		-- diffusion_solar
		-- diffusion_shared
		-- diffusion_template
	-- these represent smaller schemas that change very frequently
	-- they need to be pushed to bigde from dav-gis very commonly during active model development, but since they are small, transfers are faster

------------------------------------------------------------------------------------------------------------------------------------------------

-- Step 1 (you can skip this if you are not changing db_base at all):
DROP DATABASE IF EXISTS "dgen_db_base";
CREATE DATABASE "dgen_db_base";
ALTER DATABASe dgen_db_base with CONNECTION LIMIT 100;
GRANT ALL ON DATABASE "dgen_db_base" TO "diffusion-admins" WITH GRANT OPTION;
GRANT CONNECT, TEMPORARY ON DATABASE "dgen_db_base" TO public;
GRANT ALL ON DATABASE "dgen_db_base" TO postgres WITH GRANT OPTION;
GRANT CONNECT, TEMPORARY ON DATABASE "dgen_db_base" TO "diffusion-writers";
GRANT CONNECT, TEMPORARY ON DATABASE "dgen_db_base" TO "diffusion-schema-writers";
GRANT CONNECT, TEMPORARY ON DATABASE "dgen_db_base" TO "diffusion-intermediate";
ALTER DATABASE dgen_db_base owner to "diffusion-admins";
GRANT CREATE ON database "dgen_db_base" to "diffusion-schema-writers" ;
-- *** -- *** -- *** -- *** -- *** -- *** -- *** -- *** -- *** -- *** -- *** 
-- CHANGE DATABASE CONNECTION MANUALLY BEFORE PROCEEDING!!!!!!
-- *** -- *** -- *** -- *** -- *** -- *** -- *** -- *** -- *** -- *** -- *** 

------------------------------------------------------------------------------------------------
-- Step 2 (only necessary if you are changing base schemas):
-- clone base schemas
-- ssh to gispgdb, then:
-- pg_dump -h localhost -U mgleason -O -n diffusion_blocks -n diffusion_load_profiles -n diffusion_points -n diffusion_resource_solar -n diffusion_resource_wind -v dav-gis  | psql -h dnpdb001.bigde.nrel.gov -p 5433 -U mgleason_su -e dgen_db_base
-- note: this should take 6-8 hours

-- to update or change a single schema (e.g., diffusion_blocks)
-- archive the existing dgen_db_base
CREATE DATABASE dgen_db_base_archive WITH TEMPLATE dgen_db_base;

-- now on the main version, you can delete the old schema nad replace it from gispgdb
set role 'diffusion-writers';
DROP SCHEMA IF EXISTS diffusion_blocks cASCADE;
-- ssh to gispgdb, then:
-- pg_dump -h localhost -U mgleason -O -n diffusion_blocks -v dav-gis  | psql -h dnpdb001.bigde.nrel.gov -p 5433 -U mgleason_su -e dgen_db_base

------------------------------------------------------------------------------------------------
-- Step 3:
-- copy dgen_db_base to a new database on bigde that will be built out with the full datasets

-- archive the existing dgen_db if necessary
-- ALTER DATABASE dgen_db RENAME TO dgen_db_tag_1p5p2;
-- or drop it (if necessary)
DROP DATABASE dgen_db;
-- copy dgen_db_base to a new database on bigde that will be built out with the full datasets
-- ssh to dnpdb001.bigde.nrel.gov
-- start a screen session and connect to psotgres:
	-- psql -d dgen_db_tag_1p4 -U mgleason_su -p 5433

CREATE DATABASE dgen_db WITH TEMPLATE dgen_db_base;
	-- note: this may take about 25 minutes
	
-- make sure diffusion-schema-writers have the right privileges to create schemas
GRANT CREATE ON database "dgen_db" to "diffusion-schema-writers" ;
------------------------------------------------------------------------------------------------
-- Step 4:
-- copy over scaffold schemas from gispgdb to the newly created dgen_db
-- ssh to gispgdb, then:
-- pg_dump -h localhost -U mgleason -O -n diffusion_config -n diffusion_geo -n diffusion_wind -n diffusion_solar -n diffusion_shared -n diffusion_template -v dav-gis  | psql -h dnpdb001.bigde.nrel.gov -p 5433 -U mgleason_su -e dgen_db
-- note: this should take < 5 mins

------------------------------------------------------------------------------------------------
-- Step 5:
-- correct table and schema ownership (if necessary)

-- fix schemas
select 'ALTER SCHEMA ' || schema_name || ' OWNER TO "diffusion-writers";'
from information_schema.schemata
where schema_name like 'diffusion_%';

-- fix tables
with b as
(
	select schema_name
	from information_schema.schemata
	where schema_name like 'diffusion_%'

)
select 'ALTER TABLE ' || table_schema || '.' || table_name || ' OWNER TO "diffusion-writers";' 
from information_schema.tables  a
INNER JOIN b
ON a.table_schema = b.schema_name;

-- fix views
with b as
(
	select schema_name
	from information_schema.schemata
	where schema_name like 'diffusion_%'

)
select 'ALTER TABLE ' || table_schema || '.' || table_name || ' OWNER TO "diffusion-writers";' 
from information_schema.views  a
INNER JOIN b
ON a.table_schema = b.schema_name;

-- fix sequences
with b as
(
	select schema_name
	from information_schema.schemata
	where schema_name like 'diffusion_%'

)
select 'ALTER SEQUENCE ' || sequence_schema || '.' || sequence_name || ' OWNER TO "diffusion-writers";' 
from information_schema.sequences  a
INNER JOIN b
ON a.sequence_schema = b.schema_name;

------------------------------------------------------------------------------------------------
-- Step 6:
-- test the model and debug if necessary
