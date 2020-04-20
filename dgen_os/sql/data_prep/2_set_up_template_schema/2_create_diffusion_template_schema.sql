set role 'server-superusers';
drop schema if exists diffusion_template cascade;
SELECT add_schema('diffusion_template', 'diffusion');

