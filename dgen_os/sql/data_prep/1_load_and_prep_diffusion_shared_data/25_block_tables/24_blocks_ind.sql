SET ROLE 'diffusion-writers';

------------------------------------------------------------------------------------------
DROP TABLE IF EXISTS diffusion_blocks.blocks_ind;
CREATE TABLE  diffusion_blocks.blocks_ind AS
select pgid
from diffusion_blocks.block_bldg_counts
where bldg_count_ind > 0;
-- 945057 rows
------------------------------------------------------------------------------------------

-- add primary key
ALTER TABLE diffusion_blocks.blocks_ind
ADD PRIMARY KEY (pgid);

