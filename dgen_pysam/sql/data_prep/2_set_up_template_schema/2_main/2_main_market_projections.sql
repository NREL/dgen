set role 'diffusion-writers';


DROP TABLE IF EXISTS diffusion_template.input_main_market_inflation;
CREATE TABLE diffusion_template.input_main_market_inflation
(
	ann_inflation numeric NOT NULL
);


DROP TABLE if exists diffusion_template.input_main_market_projections CASCADE;
CREATE TABLE diffusion_template.input_main_market_projections
(
	year integer NOT NULL,
	avoided_costs_dollars_per_kwh numeric NOT NULL,
	carbon_dollars_per_ton numeric NOT NULL,
	user_defined_res_rate_escalations numeric NOT NULL,
	user_defined_com_rate_escalations numeric NOT NULL,
	user_defined_ind_rate_escalations numeric NOT NULL,
	default_rate_escalations numeric NOT NULL,
	CONSTRAINT input_main_market_projections_year_fkey FOREIGN KEY (year)
		REFERENCES diffusion_config.sceninp_year_range (val) MATCH SIMPLE
		ON UPDATE NO ACTION ON DELETE RESTRICT
);


DROP TABLE if exists diffusion_template.input_main_market_flat_electric_rates_raw CASCADE;
CREATE TABLE diffusion_template.input_main_market_flat_electric_rates_raw
(
	state_abbr character varying(2) NOT NULL,
	res_rate_dlrs_per_kwh numeric NOT NULL,
	com_rate_dlrs_per_kwh numeric NOT NULL,
	ind_rate_dlrs_per_kwh numeric NOT NULL
);

DROP VIEW IF EXISTS diffusion_template.input_main_market_flat_electric_rates;
CREATE VIEW diffusion_template.input_main_market_flat_electric_rates AS
SELECT b.state_fips, a.*
FROM diffusion_template.input_main_market_flat_electric_rates_raw a
LEFT JOIN diffusion_shared.state_fips_lkup b
	ON a.state_abbr = b.state_abbr;


DROP TABLE IF EXISTS diffusion_template.input_main_market_rate_type_weights_raw CASCADE;
CREATE TABLE diffusion_template.input_main_market_rate_type_weights_raw
(
	rate_type_desc text  NOT NULL,
	res_weight numeric NOT NULL,
	com_ind_weight numeric NOT NULL
);

DROP VIEW IF EXISTS diffusion_template.input_main_market_rate_type_weights;
CREATE VIEW diffusion_template.input_main_market_rate_type_weights AS
Select b.rate_type, a.rate_type_desc, 
	a.res_weight, a.com_ind_weight as com_weight, a.com_ind_weight as ind_weight
from diffusion_template.input_main_market_rate_type_weights_raw a
LEFT JOIN diffusion_shared.rate_type_desc_lkup b
ON a.rate_type_desc = b.rate_type_desc;


DROP TABLE IF EXISTS diffusion_template.input_main_market_carbon_intensities_grid CASCADE;
CREATE TABLE diffusion_template.input_main_market_carbon_intensities_grid
(
  state_abbr character(2),
  year integer,
  t_co2_per_kwh numeric
);


DROP TABLE IF EXISTS diffusion_template.input_main_market_carbon_intensities_ng CASCADE;
CREATE TABLE diffusion_template.input_main_market_carbon_intensities_ng
(
  state_abbr character(2),
  year integer,
  t_co2_per_kwh numeric
);


DROP VIEW IF EXISTS diffusion_template.carbon_intensities_to_model;
CREATE VIEW diffusion_template.carbon_intensities_to_model AS
WITH a as
(
	SELECT state_abbr, year, t_co2_per_kwh, 'Price Based On State Carbon Intensity'::text as carbon_price
	FROM diffusion_template.input_main_market_carbon_intensities_grid

	UNION ALL

	SELECT state_abbr, year, t_co2_per_kwh, 'Price Based On NG Offset'::text as carbon_price
	FROM diffusion_template.input_main_market_carbon_intensities_ng

	UNION ALL
	
	SELECT state_abbr, year, 0::NUMERIC AS t_co2_per_kwh, 'No Carbon Price'::text as carbon_price
	FROM diffusion_template.input_main_market_carbon_intensities_ng
)
SELECT a.state_abbr, a.year, a.t_co2_per_kwh, 
	c.carbon_dollars_per_ton, 
	a.t_co2_per_kwh * 100 * c.carbon_dollars_per_ton as carbon_price_cents_per_kwh
FROM a
INNER JOIN diffusion_template.input_main_scenario_options b
	ON a.carbon_price = b.carbon_price
LEFT JOIN  diffusion_template.input_main_market_projections c
	ON a.year = c.year;
