\COPY diffusion_shared.max_market_share TO '/Volumes/Staff/mgleason/DG_Solar/Data/Source_Data/nrel_tpo_maxmarketshare_2015_10_14/old_max_market_share_archived_on_2015_10_14.csv' with csv header;

-- drop old max market share for "monthly_bill_savings"
-- this was redundant with percent_monthly_bill_savings and never used
DELETE FROM diffusion_shared.max_market_share
where metric = 'monthly_bill_savings';
-- 4804

-- check how many rows there are for NREL tpo curves
select count(*)
FROM diffusion_shared.max_market_share
where source = 'NREL'
and business_model = 'tpo';
-- 603
-- matches row count of the new data

-- check the range of metric values for existing NREL TPO MMS curve
select min(metric_value), max(metric_value)
FROM diffusion_shared.max_market_share
where source = 'NREL'
and business_model = 'tpo';
-- 0 - 2

DELETE FROM diffusion_shared.max_market_share
where source = 'NREL'
and business_model = 'tpo';
-- 603 rows deleted

-- check total row count
select count(*)
FROM diffusion_shared.max_market_share;
-- 4312 

\COPY diffusion_shared.max_market_share FROM '/Volumes/Staff/mgleason/DG_Solar/Data/Source_Data/nrel_tpo_maxmarketshare_2015_10_14/max_market_share_nrel_tpo.csv' with csv header;

-- check new count, should be 4915
select count(*)
FROM diffusion_shared.max_market_share;
--  4915, all set!

-- check the range
select min(metric_value), max(metric_value)
FROM diffusion_shared.max_market_share
where source = 'NREL'
and business_model = 'tpo';
-- still 0 - 2 -- all set!

-- do some checking of the results
select distinct sector
from diffusion_shared.max_market_share;
-- looks fine

select distinct sector_abbr
from diffusion_shared.max_market_share;
-- looks fine

select distinct source
from diffusion_shared.max_market_share;
-- looks fine

select distinct business_model
from diffusion_shared.max_market_share;
-- looks fine

-- all looks good to me


----------------------------------------------------------------------------------------------------------------
-- per issue #512, reproduce  the NREL host-owned residential MMS curve for industrial and commercial sectors
insert into diffusion_shared.max_market_share
select metric, metric_value, max_market_share, source, business_model, 
	unnest(array['commercial', 'industrial']) as sector,
	unnest(array['com', 'ind']) as sector_abbr
FROM diffusion_shared.max_market_share
where source = 'NREL'
and business_model = 'host_owned'
and sector = 'residential';
-- 3206 rows

select distinct sector_abbr, business_model, source
FROM diffusion_shared.max_market_share
order by 1, 2, 3

-- check that it worked