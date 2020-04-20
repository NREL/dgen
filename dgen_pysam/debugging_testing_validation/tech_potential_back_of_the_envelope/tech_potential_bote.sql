-- residential
-- assume every owner-occupied single family (detached or attached) residence installs the same size system (solar ds)
select (sum(own_occu_1str_detached_h)*4 + sum(own_occu_1str_attached_h)*3.1)/1000000
from dg_wind.county_housing_units;




select sum(total_customers_2011_residential)*3.5/1000000
FROM diffusion_shared.load_and_customers_by_county_us;

select distinct(crb_model)
from diffusion_shared.eia_microdata_cbecs_2003
order by 1

with capacities as
(
	select 'Office' as pba_description, 43 as capacity_kw
	UNION
	select 'Laboratory' as pba_description, 43 as capacity_kw
	UNION
	select 'Nonrefrigerated warehouse' as pba_description, 99 as capacity_kw
	UNION
	select 'Food sales' as pba_description, 35 as capacity_kw
	UNION
	select 'Public order and safety' as pba_description, 66 as capacity_kw
	UNION
	select 'Outpatient health care' as pba_description, 45 as capacity_kw
	UNION
	select 'Refrigerated warehouse' as pba_description, 99 as capacity_kw
	UNION
	select 'Religious worship' as pba_description, 45 as capacity_kw
	UNION
	select 'Public assembly' as pba_description, 63 as capacity_kw
	UNION
	select 'Education' as pba_description, 112 as capacity_kw
	UNION
	select 'Food service' as pba_description, 30 as capacity_kw
	UNION
	select 'Inpatient health care' as pba_description, 331 as capacity_kw
	UNION
	select 'Nursing' as pba_description, 331 as capacity_kw
	UNION
	select 'Lodging' as pba_description, 91 as capacity_kw
	UNION
	select 'Strip shopping mall' as pba_description, 194 as capacity_kw
	UNION
	select 'Enclosed mall' as pba_description, 194 as capacity_kw
	UNION
	select 'Retail other than mall' as pba_description, 55 as capacity_kw
	UNION
	select 'Service' as pba_description, 38 as capacity_kw

)
select sum(capacity_kw * adjwt8)/1000000
from diffusion_shared.eia_microdata_cbecs_2003 a
LEFT JOIN diffusion_shared.eia_microdata_cbecs_2003_pba_lookup b
ON a.pba8 = b.pba8
left join capacities c
ON b.description = c.pba_description