-- MECS was last completed in 2010, but other EIA and ventyx data are current through 2011. For consistency,
-- created an estimated MECS 2011 total purchased electricity from the 2010 data. This is done by using the
-- eia table 2 state level industrial data from 2010 and 2011, aggregating state data to census regions,
-- calculating the ratio 2011:2010 regional sums as a scale factor,
-- then applying the scale factor to the mecs 2010 data (joined on census region)


-- join states to 2011 and 2010 industrial load totals in million kwh
CREATE or replace VIEW eia.estimated_mecs_2011_table_11_1_total_purchases AS
with states as (
SELECT a.state_name,a.region,a.region_long_name,b.state, b.ind as ind_2011, c.ind as ind_2010
FROM eia.census_regions a
left join eia.table_2_sales_by_state_2011 b
on a.state_name = b.state
left join eia.table_2_sales_by_state_2010 c
on a.state_name = c.state),
-- aggregate state totals to census regions and calculated 2011:2010 scale_factor
multiplier as (
SELECT region, region_long_name, sum(ind_2011) as ind_2011, sum(ind_2010) as ind_2010,  sum(ind_2011)/sum(ind_2010) as scale_factor
FROM states
group by region, region_long_name)
-- join mecs 2010 data to the multiplier and apply the scale factor to the total purchases in millions of kwh
SELECT a.region, a.naics_code, a.industry_name, 
	a.tot_purchases_mkwh_elec * b.scale_factor as tot_purchases_mkwh_elec, a.source
from eia.mecs_2010_table_11_1 a
left join multiplier b
on a.region = b.region_long_name
where a.region <> 'United States'
;