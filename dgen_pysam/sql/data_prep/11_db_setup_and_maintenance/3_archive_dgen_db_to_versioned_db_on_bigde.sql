-- to truly archive the database (will require full migration to recreate)
ALTER DATABASE dgen_db RENAME TO dgen_db_tag_1p5p1;

-- OR

-- to clone the database (useful during incremental updates)
CREATE DATABASE dgen_db_tag_1p5p1 WITH TEMPLATE dgen_db;
GRANT CREATE ON database "dgen_db_tag_1p5p1" to "diffusion-schema-writers" ;