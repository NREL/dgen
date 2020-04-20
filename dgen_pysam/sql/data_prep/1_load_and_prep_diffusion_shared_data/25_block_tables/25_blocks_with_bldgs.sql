set role 'diffusion-writers';

------------------------------------------------------------------------------------------------
DROP VIEW IF EXISTS diffusion_blocks.blocks_with_buildings;
CREATE TABLE diffusion_blocks.blocks_with_buildings AS
select pgid
from diffusion_blocks.blocks_res
union
select pgid
from diffusion_blocks.blocks_com	
UNION
select pgid
from diffusion_blocks.blocks_ind;

---------------------------------------------------------------------------------------------------
-- QAQC

-- add primary key
ALTER TABLE diffusion_blocks.blocks_with_buildings
ADD PRIMARY KEY (pgid);

-- check count
select count(*)
FROM diffusion_blocks.blocks_with_buildings;
-- 6903895
