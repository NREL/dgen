set role 'server-superusers';
ALTER GROUP "diffusion-schema-writers" DROP USER "diffusion-writers";
ALTER ROLE "diffusion-writers" WITH inherit;
CREATE ROLE "diffusion-intermediate" NOCREATEDB NOCREATEUSER NOLOGIN NOCREATEROLE NOINHERIT;
ALTER GROUP "diffusion-intermediate" ADD USER "diffusion-writers";
ALTER GROUP "diffusion-schema-writers" ADD user "diffusion-intermediate";

set role "diffusion-writers";
CREATE SCHEMA test_schema;
-- should get rejected

set role "diffusion-intermediate";
CREATE SCHEMA test_schema;
-- should get rejected

set role "diffusion-schema-writers";
CREATE SCHEMA test_schema;
DROP SCHEMA test_schema;
-- should work


