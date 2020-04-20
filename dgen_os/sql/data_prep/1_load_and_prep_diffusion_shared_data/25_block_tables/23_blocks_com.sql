SET ROLE 'diffusion-writers';

------------------------------------------------------------------------------------------
DROP TABLE IF EXISTS diffusion_blocks.blocks_com;
CREATE TABLE  diffusion_blocks.blocks_com AS
select pgid
from diffusion_blocks.block_bldg_counts
where bldg_count_com > 0;
-- 2978842 rows
------------------------------------------------------------------------------------------

-- add primary key
ALTER TABLE diffusion_blocks.blocks_com
ADD PRIMARY KEY (pgid);

