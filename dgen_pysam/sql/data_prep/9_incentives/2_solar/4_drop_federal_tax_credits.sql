-- federal tax credits are no longer pulled from dsire
-- they are pulled from the input sheet instead


--------------------------------------------------------------------------------
-- SOLAR
-- identify which incentives to delete
select a.*, b.*
from diffusion_solar.incentives a
left join geo_incentives.incentives b
ON a.incentive_id = b.gid
where state = 'Federal';
-- ids 122 and 124

-- make sure those are the only incentives with those ids
select *
FROM diffusion_solar.incentives
where uid in (124, 122);
-- all set

-- drop them
DELETE FROM diffusion_solar.incentives
where uid in (124, 122)
-- 3 rows deleted

-- check first query again to make sure no federal incentives remain
-- all set

--------------------------------------------------------------------------------