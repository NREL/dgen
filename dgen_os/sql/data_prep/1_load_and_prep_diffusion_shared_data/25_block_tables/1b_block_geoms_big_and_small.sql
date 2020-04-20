set role 'diffusion-writers';

DROP VIEW IF EXISTS diffusion_blocks.block_geoms_small;
CREATE VIEW diffusion_blocks.block_geoms_small AS
select *
from  diffusion_blocks.block_geoms
where exceeds_10_acres = False;


DROP VIEW IF EXISTS diffusion_blocks.block_geoms_big;
CREATE VIEW diffusion_blocks.block_geoms_big AS
select *
from  diffusion_blocks.block_geoms
where exceeds_10_acres = True;