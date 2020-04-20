SET ROLE 'diffusion-writers';

-- delete old data
DROP TABLE IF EXISTS diffusion_solar.solar_program_target_cost_projections CASCADE;
-- note: the drop will cascade to  view diffusion_template.input_solar_cost_projections_to_model
-- which needs to be recreated
CREATE TABLE diffusion_solar.solar_program_target_cost_projections
(
  sector character varying(3),
  year integer,
  capital_cost_dollars_per_kw numeric,
  inverter_cost_dollars_per_kw numeric,
  fixed_om_dollars_per_kw_per_yr numeric,
  variable_om_dollars_per_kwh numeric,
  scenario text
);

\COPY diffusion_solar.solar_program_target_cost_projections (sector, year, capital_cost_dollars_per_kw, scenario, inverter_cost_dollars_per_kw, fixed_om_dollars_per_kw_per_yr, variable_om_dollars_per_kwh) FROM '/Volumes/Staff/mgleason/DG_Solar/Data/Source_Data/DOE_solar_program_cost_targets/all_costs_2015_11_19.csv' with csv header;

-- look at the data
select *
FROM diffusion_solar.solar_program_target_cost_projections;

-- create indices on sector, year and scenario
CREATE INDEX solar_program_target_cost_projections_btree_sector
ON diffusion_solar.solar_program_target_cost_projections
USING BTREE(sector);

CREATE INDEX solar_program_target_cost_projections_btree_year
ON diffusion_solar.solar_program_target_cost_projections
USING BTREE(year);

CREATE INDEX solar_program_target_cost_projections_btree_scenario
ON diffusion_solar.solar_program_target_cost_projections
USING BTREE(scenario);


select distinct scenario, sector
from diffusion_solar.solar_program_target_cost_projections;