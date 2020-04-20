set role 'diffusion-writers';
------------------------------------------------------------------------------------------------

DROP TABLE IF EXISTS diffusion_blocks.electric_utilities_lkup;
CREATE TABLE diffusion_blocks.electric_utilities_lkup AS
with a as
(
	select statefp as state_fips, utility_num, ownership, utility_name,
		sum(coalesce(res_customers, 0)) as res_customers,
		sum(coalesce(com_customers, 0)) as com_customers,
		sum(coalesce(ind_customers, 0)) as ind_customers,
		sum(coalesce(res_customers, 0)) + sum(coalesce(com_customers, 0)) + sum(coalesce(ind_customers, 0)) as tot_customers
	from eia.eia_861_electricity_sales_all_sectors_2013
	where utility_num <> 99999  -- ignore adjustments
		and ownership <> 'Behind the Meter'
	GROUP BY statefp, utility_num, ownership, utility_name
)
select a.*,
	case when ownership = 'Investor Owned' THEN 'IOU'
	     WHEN ownership in ('Political Subdivision', 'Municipal') THEN 'Muni'
	     WHEN ownership = 'Cooperative' THEN 'Coop'
	     ELSE 'All Other'
	end as utility_type_general
from a;
-- 2564 rows


--------------------------------------------------------------------------------------------------
-- QA/QC

-- add primary key
ALTER TABLE diffusion_blocks.electric_utilities_lkup
ADD PRIMARY KEY (utility_num, state_fips);

-- check for nulls
select *
FROM diffusion_blocks.electric_utilities_lkup
where utility_name is null
or ownership is null
or utility_type_general is null
or res_customers is null
or com_customers is null
or ind_customers is null
or tot_customers is null;
-- 0 -- all set

-- check utility/ownership combos
select distinct utility_type_general, ownership
from diffusion_blocks.electric_utilities_lkup
order by 1;

