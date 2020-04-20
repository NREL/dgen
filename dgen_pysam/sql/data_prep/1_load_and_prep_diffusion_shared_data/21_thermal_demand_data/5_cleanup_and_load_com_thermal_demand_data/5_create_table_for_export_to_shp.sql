set role 'dgeo-writers';

DROP TABLE IF EXISTS dgeo.county_thermal_demand_thermal_com;
CREATE TABLE dgeo.county_thermal_demand_com AS
select a.*--, b.the_geom_96703
from diffusion_shared.county_thermal_demand_com a
left join diffusion_shared.county_geom b
on a.county_id = b.county_id;
-- 3141 rows

select max(total_heating_thermal_load_mmbtu)*1e6
from diffusion_shared.county_thermal_demand_res
2866000000
6029040197.3640000000000000000000000000