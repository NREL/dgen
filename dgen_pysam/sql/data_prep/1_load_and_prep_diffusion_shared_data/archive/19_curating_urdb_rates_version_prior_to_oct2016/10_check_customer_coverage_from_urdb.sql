-- do all companies from the urdb data match a company from the ventyx retail sales data?
-- how many distinct company ids are there in the urdb data?
-- NOTE: need to do this because the ur_name is the primary key in this table, 
-- but there may be multiple aliases of ur_name for th same company id
select distinct(ventyx_company_id_2014)
FROM urdb_rates.urdb3_verified_and_singular_ur_names_20141202;
-- 1190

-- is company id a unique id for the ventyx retail sales data?
select company_id, count(*)
FROM  ventyx.retail_sales_2012_20140305
group by company_id
order by count desc;

select *
FROM ventyx.retail_sales_2011
where company_id = 62946
-- no -- it is not a unique id because some companies are split across states


-- does every company id from urdb have a match in the ventyx sales data?
with a as
(
	select distinct(ventyx_company_id_2014) as ventyx_company_id_2014
	FROM urdb_rates.urdb3_verified_and_singular_ur_names_20141202
)
select *
FROM a
LEFT join ventyx.retail_sales_2012_20140305 b
ON a.ventyx_company_id_2014 = b.company_id::text
where b.company_id is null;
-- no: four company ids from urdb aren't found in the retail sales data
-- this is small enough to ignore for now


-- SQL code below gives covered sum and total sum and can be used to manually calcualte % coverage
-- for automated calculation of % coverage, run : 10b_summarize_coverage.R


-- 
-- -- 
-- with a as
-- (
-- 	select distinct(ventyx_company_id_2014) as ventyx_company_id_2014
-- 	FROM urdb_rates.urdb3_verified_and_singular_ur_names_20141202
-- ),
-- b as
-- (
-- 	SELECT  sum(b.bundled_energy_only_delivery_only_residential_revenue_000s) as res_revenue_000s,
-- 		sum(b.bundled_delivery_only_residential_sales_mwh) as res_sales_mwh,
-- 		sum(b.bundled_delivery_only_residential_customers) as res_customers,
-- 
-- 		sum(b.bundled_energy_only_delivery_only_commercial_revenue_000s) as com_revenue_000s,
-- 		sum(b.bundled_delivery_only_commercial_sales_mwh) as com_sales_mwh,
-- 		sum(b.bundled_delivery_only_commercial_customers) as com_customers,
-- 
-- 		sum(b.bundled_energy_only_delivery_only_industrial_revenue_000s) as ind_revenue_000s,
-- 		sum(b.bundled_delivery_only_industrial_sales_mwh)  as ind_sales_mwh,
-- 		sum(b.bundled_delivery_only_industrial_customers) as ind_customers
-- 	from a
-- 	inner join ventyx.retail_sales_2012_20140305 b
-- 	ON a.ventyx_company_id_2014 = b.company_id::text
-- ),
-- c as 
-- (
-- 	SELECT  
-- 		sum(b.bundled_energy_only_delivery_only_residential_revenue_000s) as res_revenue_000s,
-- 		sum(b.bundled_delivery_only_residential_sales_mwh) as res_sales_mwh,
-- 		sum(b.bundled_delivery_only_residential_customers) as res_customers,
-- 
-- 		sum(b.bundled_energy_only_delivery_only_commercial_revenue_000s) as com_revenue_000s,
-- 		sum(b.bundled_delivery_only_commercial_sales_mwh) as com_sales_mwh,
-- 		sum(b.bundled_delivery_only_commercial_customers) as com_customers,
-- 
-- 		sum(b.bundled_energy_only_delivery_only_industrial_revenue_000s) as ind_revenue_000s,
-- 		sum(b.bundled_delivery_only_industrial_sales_mwh)  as ind_sales_mwh,
-- 		sum(b.bundled_delivery_only_industrial_customers) as ind_customers
-- 	from ventyx.retail_sales_2012_20140305 b
-- )
-- SELECT *
-- FROM b
-- union all
-- Select *
-- from c;




-- could also look at it based on the source eia data...but results are essentially the same
-- with x as
-- (
-- 	select distinct(eia_id_2011) as eia_id_2011
-- 	FROM urdb_rates.urdb3_verified_and_singular_ur_names_20141202
-- ),
-- a as
-- (
-- SELECT  --b.state_code, 
-- 	sum(b.residential_sales) as residential_sales, 
-- 	sum(b.residential_consumers) as residential_consumers, 
-- 	sum(b.commercial_sales) as commercial_sales, 
-- 	sum(b.commercial_consumers) as commercial_consumers, 
-- 	sum(b.industrial_sales) as industrial_sales, 
--        sum(b.industrial_consumers) as industrial_consumers
-- from x
-- inner join eia.eia_861_file_2_2011 b
-- ON x.eia_id_2011 = b.utility_id::text
-- --group by state_code
-- ),
-- b as 
-- (
-- SELECT  --b.state_code, 
-- 	sum(b.residential_sales) as residential_sales, 
-- 	sum(b.residential_consumers) as residential_consumers, 
-- 	sum(b.commercial_sales) as commercial_sales, 
-- 	sum(b.commercial_consumers) as commercial_consumers, 
-- 	sum(b.industrial_sales) as industrial_sales, 
--        sum(b.industrial_consumers) as industrial_consumers
-- from eia.eia_861_file_2_2011 b
-- )
-- SELECT *
-- FROM a
union all
Select *
from b;

