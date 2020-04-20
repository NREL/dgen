set role 'diffusion-writers';


DROP TABLE IF EXISTs diffusion_template.input_solar_cost_projections_res CASCADE;
CREATE TABLE diffusion_template.input_solar_cost_projections_res
(
	year integer NOT NULL,
	capital_cost_dollars_per_kw numeric NOT NULL,
	inverter_cost_dollars_per_kw numeric NOT NULL,
	fixed_om_dollars_per_kw_per_yr numeric NOT NULL,
	variable_om_dollars_per_kwh numeric NOT NULL,
	CONSTRAINT input_solar_cost_projections_res_year_fkey FOREIGN KEY (year)
		REFERENCES diffusion_config.sceninp_year_range (val) MATCH SIMPLE
		ON UPDATE NO ACTION ON DELETE RESTRICT
);

DROP TABLE IF EXISTs diffusion_template.input_solar_cost_projections_com CASCADE;
CREATE TABLE diffusion_template.input_solar_cost_projections_com
(
	year integer NOT NULL,
	capital_cost_dollars_per_kw numeric NOT NULL,
	inverter_cost_dollars_per_kw numeric NOT NULL,
	fixed_om_dollars_per_kw_per_yr numeric NOT NULL,
	variable_om_dollars_per_kwh numeric NOT NULL,
	CONSTRAINT input_solar_cost_projections_com_year_fkey FOREIGN KEY (year)
		REFERENCES diffusion_config.sceninp_year_range (val) MATCH SIMPLE
		ON UPDATE NO ACTION ON DELETE RESTRICT
);

DROP TABLE IF EXISTs diffusion_template.input_solar_cost_projections_ind CASCADE;
CREATE TABLE diffusion_template.input_solar_cost_projections_ind
(
	year integer NOT NULL,
	capital_cost_dollars_per_kw numeric NOT NULL,
	inverter_cost_dollars_per_kw numeric NOT NULL,
	fixed_om_dollars_per_kw_per_yr numeric NOT NULL,
	variable_om_dollars_per_kwh numeric NOT NULL,
	CONSTRAINT input_solar_cost_projections_ind_year_fkey FOREIGN KEY (year)
		REFERENCES diffusion_config.sceninp_year_range (val) MATCH SIMPLE
		ON UPDATE NO ACTION ON DELETE RESTRICT
);

DROP VIEW IF EXISTS diffusion_template.input_solar_cost_projections;
CREATE VIEW diffusion_template.input_solar_cost_projections AS

SELECT *, 'res'::character varying(3) as sector_abbr
FROM diffusion_template.input_solar_cost_projections_res

UNION ALL

SELECT *, 'com'::character varying(3) as sector_abbr
FROM diffusion_template.input_solar_cost_projections_com

UNION ALL

SELECT *, 'ind'::character varying(3) as sector_abbr
FROM diffusion_template.input_solar_cost_projections_ind;


DROP TABLE IF EXISTS diffusion_template.input_solar_cost_assumptions;
CREATE TABLE diffusion_template.input_solar_cost_assumptions
(
	cost_assumptions text not null,
	CONSTRAINT input_solar_cost_assumptions_cost_assumptions FOREIGN KEY (cost_assumptions)
		REFERENCES diffusion_config.sceninp_cost_assumptions_solar (val) MATCH SIMPLE
		ON DELETE RESTRICT
);



DROP VIEW IF EXISTS diffusion_template.input_solar_cost_projections_to_model;
CREAte VIEW diffusion_template.input_solar_cost_projections_to_model As
WITH a as 
(
	SELECT year, capital_cost_dollars_per_kw, inverter_cost_dollars_per_kw, 
	       fixed_om_dollars_per_kw_per_yr, variable_om_dollars_per_kwh, 
	       sector_abbr, 'User Defined'::text as source
	FROM diffusion_template.input_solar_cost_projections

	UNION ALL

	SELECT year, capital_cost_dollars_per_kw, inverter_cost_dollars_per_kw, 
		fixed_om_dollars_per_kw_per_yr, variable_om_dollars_per_kwh, 
		sector as sector_abbr, scenario as source
	FROM diffusion_solar.solar_program_target_cost_projections

	UNION ALL

	select year, capital_cost_dollars_per_kw, inverter_cost_dollars_per_kw, 
		fixed_om_dollars_per_kw_per_yr, variable_om_dollars_per_kwh, 
		sector as sector_abbr, 'AEO 2014'::text as source
	from diffusion_solar.solar_costs_aeo2014
),
b as
(
	SELECT a.*
	FROM a
	INNER JOIN diffusion_template.input_solar_cost_assumptions b
	ON lower(a.source) = lower(b.cost_assumptions)
)
SELECT b.year, 
	case when d.reeds_mode = true then c.capital_cost_dollars_per_kw
	else b.capital_cost_dollars_per_kw
	end as installed_costs_dollars_per_kw,
	b.inverter_cost_dollars_per_kw, 
	b.fixed_om_dollars_per_kw_per_yr, b.variable_om_dollars_per_kwh, 
	b.sector_abbr, 
	b.source
from b 
LEFT JOIN diffusion_template.input_reeds_capital_costs_by_sector c
	ON b.year = c.year
	and b.sector_abbr = c.sector_abbr
LEFT JOIN diffusion_template.input_reeds_mode d
ON true;


select *
FROM diffusion_template.input_solar_cost_projections_to_model;

select *
FROM diffusion_solar.cost_projections_to_model;


DROP TABLE IF EXISTS diffusion_template.input_solar_cost_multipliers;
CREATE TABLE diffusion_template.input_solar_cost_multipliers
(
	sector_abbr character varying(3) NOT NULL,
	new_construction_multiplier numeric NOT NULL,
	base_size_kw numeric NOT NULL,
	size_adjustment_factor numeric NOT NULL,  
	CONSTRAINT input_solar_cost_multipliers_sector_fkey FOREIGN KEY (sector_abbr)
		REFERENCES diffusion_config.sceninp_sector (sector_abbr) MATCH SIMPLE
		ON UPDATE NO ACTION ON DELETE RESTRICT
);


------------------------------------------------------------------------------------ 
-- learning rates on/off
DROP TABLE IF EXISTS diffusion_template.input_cost_learning_curves_enabled_solar;
CREATE TABLE diffusion_template.input_cost_learning_curves_enabled_solar
(
	enabled boolean not null
);

-- learning curves
DROP TABLE IF EXISTS diffusion_template.input_solar_cost_learning_rates;
CREATE TABLE diffusion_template.input_solar_cost_learning_rates
(
	year integer NOT NULL primary key,
	learning_rate numeric NOT NULL,
	frac_of_global_mkt numeric NOT NULL,
	CONSTRAINT input_solar_cost_learning_rates_year_fkey FOREIGN KEY (year)
		REFERENCES diffusion_config.sceninp_year_range (val) MATCH SIMPLE
		ON UPDATE NO ACTION ON DELETE RESTRICT
);

-- table to hold cumulative installed capacity (for learning curves)
set role 'diffusion-writers';
DROP TABLE IF EXISTS diffusion_template.cumulative_installed_capacity_solar;
CREATE TABLE diffusion_template.cumulative_installed_capacity_solar
(
	year integer primary key,
	cumulative_installed_capacity numeric
);

-- table to hold annual costs (will be updated to allow for dynamic learning curves)
DROP TABLE IF EXISTS diffusion_template.yearly_technology_costs_solar;
CREATE TABLE diffusion_template.yearly_technology_costs_solar
(
	year integer,
	sector_abbr character varying(3),
	installed_costs_dollars_per_kw numeric,
	inverter_cost_dollars_per_kw numeric,
	fixed_om_dollars_per_kw_per_yr numeric,
	variable_om_dollars_per_kwh numeric
);
ALTER TABLE diffusion_template.yearly_technology_costs_solar
ADD PRIMARY KEY (year, sector_abbr);

