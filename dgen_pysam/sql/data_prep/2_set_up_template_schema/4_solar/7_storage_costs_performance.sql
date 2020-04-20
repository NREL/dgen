---------------------------------------------------------------------------------------------------
set role 'diffusion-writers';

DROP TABLE IF EXISTS diffusion_shared.battery_cost_projections;
CREATE TABLE diffusion_shared.battery_cost_projections
(
  year integer,
  sector_abbr text,
  scenario text,
  batt_kwh_cost numeric,
  batt_kw_cost numeric,
  batt_kwh_cost_ratio numeric,
  batt_kw_cost_ratio numeric
);

\COPY diffusion_shared.battery_cost_projections FROM 'C:/Users/pdas/Documents/NREL_Projects/dGen/data/source_data/storage_cost_projections/storage_cost_projections.csv' with csv header;


ALTER TABLE diffusion_shared.battery_cost_projections
ADD PRIMARY KEY (year, sector_abbr, scenario);

CREATE INDEX battery_cost_projections_year_btree
  ON diffusion_shared.battery_cost_projections
  USING btree (year);

CREATE INDEX battery_cost_projections_sector_abbr_btree
  ON diffusion_shared.battery_cost_projections
  USING btree (sector_abbr); 
  
CREATE INDEX battery_cost_projections_scenario_btree
  ON diffusion_shared.battery_cost_projections
  USING btree (scenario);

ALTER TABLE diffusion_shared.battery_cost_projections
  OWNER TO "diffusion-writers";
GRANT ALL ON TABLE diffusion_shared.battery_cost_projections TO "diffusion-writers";
GRANT SELECT ON TABLE diffusion_shared.battery_cost_projections TO public;
---------------------------------------------------------------------------------------------------


---------------------------------------------------------------------------------------------------

DROP TABLE IF EXISTS diffusion_template.input_storage_cost_projections_res CASCADE;
CREATE TABLE diffusion_template.input_storage_cost_projections_res
(
  year integer NOT NULL,
  batt_kwh_cost numeric NOT NULL,
  batt_kw_cost numeric NOT NULL,
  capacity_om_dollars_per_kwh numeric NOT NULL,
  power_om_dollars_per_kw numeric NOT NULL
);

DROP TABLE IF EXISTS diffusion_template.input_storage_cost_projections_com CASCADE;
CREATE TABLE diffusion_template.input_storage_cost_projections_com
(
  year integer NOT NULL,
  batt_kwh_cost numeric NOT NULL,
  batt_kw_cost numeric NOT NULL,
  capacity_om_dollars_per_kwh numeric NOT NULL,
  power_om_dollars_per_kw numeric NOT NULL
);

DROP TABLE IF EXISTs diffusion_template.input_storage_cost_projections_ind CASCADE;
CREATE TABLE diffusion_template.input_storage_cost_projections_ind
(
  year integer NOT NULL,
  batt_kwh_cost numeric NOT NULL,
  batt_kw_cost numeric NOT NULL,
  capacity_om_dollars_per_kwh numeric NOT NULL,
  power_om_dollars_per_kw numeric NOT NULL
);
---------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------
DROP VIEW IF EXISTS diffusion_template.input_storage_cost_projections_userdefined;
CREATE VIEW diffusion_template.input_storage_cost_projections_userdefined AS

SELECT year, 
'res'::character varying(3) as sector_abbr, 
'User Defined'::text as scenario,
batt_kwh_cost, batt_kw_cost
FROM diffusion_template.input_storage_cost_projections_res

UNION ALL

SELECT year, 
'com'::character varying(3) as sector_abbr, 
'User Defined'::text as scenario,
batt_kwh_cost, batt_kw_cost
FROM diffusion_template.input_storage_cost_projections_com

UNION ALL

SELECT year, 
'ind'::character varying(3) as sector_abbr, 
'User Defined'::text as scenario,
batt_kwh_cost, batt_kw_cost
FROM diffusion_template.input_storage_cost_projections_ind;
---------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------

-- storage cost projections to model
DROP VIEW IF EXISTS diffusion_template.input_storage_cost_projections_to_model;
CREATE OR REPLACE VIEW diffusion_template.input_storage_cost_projections_to_model AS
WITH a AS 
(
  SELECT *
  FROM diffusion_template.input_storage_cost_projections_userdefined
  WHERE year = 2014
),

b AS
(
  SELECT c.year, c.sector_abbr, c.scenario, 
        c.batt_kwh_cost, c.batt_kw_cost,
        c.batt_kwh_cost/a.batt_kwh_cost as batt_kwh_cost_ratio,
        c.batt_kw_cost/a.batt_kw_cost as batt_kw_cost_ratio
        FROM diffusion_template.input_storage_cost_projections_userdefined c, a
        WHERE c.sector_abbr = a.sector_abbr AND c.scenario= a.scenario

  UNION ALL

  SELECT *
  FROM diffusion_shared.battery_cost_projections
)

SELECT b.*
FROM b
INNER JOIN diffusion_template.input_main_scenario_options d
ON lower(b.scenario) = lower(d.storage_cost_projections);
---------------------------------------------------------------------------------------------------


---------------------------------------------------------------------------------------------------
-- Obtain battery round-trip efficiency parameters (i.e. Replacement Year, Replacement Cost Fraction
-- from the input sheet

DROP TABLE IF EXIStS diffusion_template.input_battery_roundtrip_efficiency CASCADE;
CREATE TABLE diffusion_template.input_battery_roundtrip_efficiency
(
  year integer NOT NULL,
  sector text NOT NULL,
  battery_roundtrip_efficiency numeric NOT NULL,
  CONSTRAINT battery_roundtrip_efficiency_check CHECK (battery_roundtrip_efficiency <= 1::numeric)
);
---------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------

-- Obtain battery replacement parameters (i.e. Replacement Year, Replacement Cost Fraction
-- from the input sheet.

DROP TABLE IF EXIStS diffusion_template.input_battery_replacement_parameters CASCADE;
CREATE TABLE diffusion_template.input_battery_replacement_parameters
(
  batt_replacement_year integer NOT NULL,
  batt_replacement_cost_fraction numeric NOT NULL,
  CONSTRAINT batt_replacement_cost_fraction_check CHECK (batt_replacement_cost_fraction <= 1::numeric)
);
---------------------------------------------------------------------------------------------------