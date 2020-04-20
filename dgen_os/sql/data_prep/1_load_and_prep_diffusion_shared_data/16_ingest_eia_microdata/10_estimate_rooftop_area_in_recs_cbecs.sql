-- RECS

-- now check the coding of the stories variable
select num_floors, sum(sample_wt), count(*)
from diffusion_shared.eia_microdata_recs_2009_expanded_bldgs
group by num_floors
order by num_floors;

-- add a column for the roof area in sqft
ALTER TABLE diffusion_shared.eia_microdata_recs_2009_expanded_bldgs
ADD COLUMN roof_sqft integer;

-- calculate the roof area in sqft as the total sqft / number of floors in the home
UPDATE diffusion_shared.eia_microdata_recs_2009_expanded_bldgs c
set roof_sqft = totsqft/num_floors;
-- 12083 rows

-- make sure no nulls
select count(*)
from diffusion_shared.eia_microdata_recs_2009_expanded_bldgs
where roof_sqft is null;
-- zero --  all set

-- check results
select roof_sqft, num_floors, totsqft, num_tenants, *
from diffusion_shared.eia_microdata_recs_2009_expanded_bldgs
order by 1;
-- there are some very small roof areas but they appear to be consistent with the building square footage 
-- also some roof large areas but they all appear to be cosnsitent with building square footage
-- so things look reasonable

---------------------------------------------------------------------------------------------------

-- CBECS
-- check the proportion of buildings with different nfloors
select num_floors, count(*), sum(sample_wt)
FROM diffusion_shared.eia_microdata_cbecs_2003_expanded
group by num_floors
order by num_floors;

-- add a column for the roof area in sqft
ALTER TABLE diffusion_shared.eia_microdata_cbecs_2003_expanded
ADD COLUMN roof_sqft integer;

-- assume all strip malls are single floor
UPDATE diffusion_shared.eia_microdata_cbecs_2003_expanded
set roof_sqft = totsqft/num_floors;
-- 5081 rows

-- make sure no nulls
select count(*)
from diffusion_shared.eia_microdata_cbecs_2003_expanded
where roof_sqft is null;
-- zero --  all set

-- check results
select roof_sqft, num_floors, totsqft, num_tenants, *
from diffusion_shared.eia_microdata_cbecs_2003_expanded
order by 1;
-- same patterns as in recs. things look weird in some cases, but reasonable given the original data

