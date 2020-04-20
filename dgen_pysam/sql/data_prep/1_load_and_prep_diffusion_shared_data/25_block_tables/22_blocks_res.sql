SET ROLE 'diffusion-writers';

------------------------------------------------------------------------------------------
DROP TABLE IF EXISTS diffusion_blocks.blocks_res;
CREATE TABLE  diffusion_blocks.blocks_res AS
select pgid
from diffusion_blocks.block_bldg_counts
where bldg_count_res > 0;
-- 6379963 rows

-- note: decided to do this based on bldg counts instead of housing units for 
-- conssitency with the other sectors and so that there aren't any resulting data gaps
-- there are about 128005 blocks with > 0 HU but 0 bldgs, but about 126,000 of them have <= 5 HU
-- so it's generally safe to just ignore these blocks
------------------------------------------------------------------------------------------

-- add primary key
ALTER TABLE diffusion_blocks.blocks_res
ADD PRIMARY KEY (pgid);

