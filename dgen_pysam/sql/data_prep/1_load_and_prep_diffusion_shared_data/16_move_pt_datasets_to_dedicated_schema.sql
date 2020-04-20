set role 'server-superusers';

select add_schema('diffusion_points', 'diffusion');

set role 'diffusion-writers';

alter table diffusion_shared.pt_grid_us_com
set schema diffusion_points;

alter table diffusion_shared.pt_grid_us_res
set schema diffusion_points;

alter table diffusion_shared.pt_grid_us_ind
set schema diffusion_points;

