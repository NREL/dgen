SET ROLE 'diffusion-writers';

DROP TABLE IF EXISTS diffusion_template.input_reeds_mode CASCADE;
CREATE TABLE diffusion_template.input_reeds_mode
(
	reeds_mode boolean not null
);



DROP TABLE IF EXISTS diffusion_template.input_reeds_capital_costs CASCADE;
CREATE TABLE diffusion_template.input_reeds_capital_costs
(
	year integer not null,
	capital_cost_dollars_per_kw numeric not null,
	CONSTRAINT input_reeds_capital_costs_year_fkey FOREIGN KEY (year)
	REFERENCES diffusion_config.sceninp_year_range (val) MATCH SIMPLE
	ON UPDATE NO ACTION ON DELETE RESTRICT	
);



DROP VIEW IF EXISTS diffusion_template.input_reeds_capital_costs_by_sector CASCADE;
CREATE VIEW diffusion_template.input_reeds_capital_costs_by_sector AS
SELECT year, capital_cost_dollars_per_kw * 1.5 as capital_cost_dollars_per_kw, 'res'::character varying(3) as sector_abbr
FROM diffusion_template.input_reeds_capital_costs
UNION ALL
SELECT year, capital_cost_dollars_per_kw * 1.25 as capital_cost_dollars_per_kw, 'com'::character varying(3) as sector_abbr
FROM diffusion_template.input_reeds_capital_costs
UNION ALL
SELECT year, capital_cost_dollars_per_kw * 1.25 as capital_cost_dollars_per_kw, 'ind'::character varying(3) as sector_abbr
FROM diffusion_template.input_reeds_capital_costs;


