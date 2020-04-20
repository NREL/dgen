set role 'diffusion-writers';


DROP TABLE IF EXISTS diffusion_template.input_solar_finances_res cascade;
CREATE TABLE diffusion_template.input_solar_finances_res 
(
	year integer NOT null,
	-- loan params
	loan_term_yrs integer NOT NULL,
	loan_rate numeric NOT NULL,
	loan_down_payment numeric NOT NULL,
	loan_discount_rate numeric NOT NULL,
	loan_tax_rate numeric NOT NULL,
	-- lease params
	lease_term_yrs integer NOT NULL,
	lease_rate numeric NOT NULL,
	lease_down_payment numeric NOT NULL,
	lease_discount_rate numeric NOT NULL,
	lease_tax_rate numeric NOT NULL	
);

DROP TABLE IF EXISTS diffusion_template.input_solar_finances_com cascade;
CREATE TABLE diffusion_template.input_solar_finances_com 
(
	year integer NOT null,
	-- loan params
	loan_term_yrs integer NOT NULL,
	loan_rate numeric NOT NULL,
	loan_down_payment numeric NOT NULL,
	loan_discount_rate numeric NOT NULL,
	loan_tax_rate numeric NOT NULL,
	loan_length_of_irr_analysis_yrs integer NOT NULL,
	-- lease params
	lease_term_yrs integer NOT NULL,
	lease_rate numeric NOT NULL,
	lease_down_payment numeric NOT NULL,
	lease_discount_rate numeric NOT NULL,
	lease_tax_rate numeric NOT NULL,
	lease_length_of_irr_analysis_yrs integer NOT NULL
);

DROP TABLE IF EXISTS diffusion_template.input_solar_finances_ind cascade;
CREATE TABLE diffusion_template.input_solar_finances_ind 
(
	year integer NOT null,
	-- loan params
	loan_term_yrs integer NOT NULL,
	loan_rate numeric NOT NULL,
	loan_down_payment numeric NOT NULL,
	loan_discount_rate numeric NOT NULL,
	loan_tax_rate numeric NOT NULL,
	loan_length_of_irr_analysis_yrs integer NOT NULL,
	-- lease params
	lease_term_yrs integer NOT NULL,
	lease_rate numeric NOT NULL,
	lease_down_payment numeric NOT NULL,
	lease_discount_rate numeric NOT NULL,
	lease_tax_rate numeric NOT NULL,
	lease_length_of_irr_analysis_yrs integer NOT NULL
);


DROP VIEW IF EXISTS diffusion_template.input_solar_finances CASCADE;
CREATE VIEW diffusion_template.input_solar_finances AS

SELECT year, 'res'::text as sector_abbr, 'host_owned'::text as business_model,
	loan_term_yrs as loan_term_yrs, 
	loan_rate as loan_rate, 
	loan_down_payment as down_payment,
	loan_discount_rate as discount_rate,
	loan_tax_rate as tax_rate,
	0::integer as length_of_irr_analysis_yrs
FROM diffusion_template.input_solar_finances_res

UNION ALL

SELECT year, 'res'::text as sector_abbr, 'tpo'::text as business_model,
	lease_term_yrs as loan_term_yrs, 
	lease_rate as loan_rate, 
	lease_down_payment as down_payment,
	lease_discount_rate as discount_rate,
	lease_tax_rate as tax_rate,
	0::integer as length_of_irr_analysis_yrs
FROM diffusion_template.input_solar_finances_res

UNION ALL

SELECT year, 'com'::text as sector_abbr, 'host_owned'::text as business_model,
	loan_term_yrs as loan_term_yrs, 
	loan_rate as loan_rate, 
	loan_down_payment as down_payment,
	loan_discount_rate as discount_rate,
	loan_tax_rate as tax_rate,
	loan_length_of_irr_analysis_yrs as length_of_irr_analysis_yrs
FROM diffusion_template.input_solar_finances_com

UNION ALL

SELECT year, 'com'::text as sector_abbr, 'tpo'::text as business_model,
	lease_term_yrs as loan_term_yrs, 
	lease_rate as loan_rate, 
	lease_down_payment as down_payment,
	lease_discount_rate as discount_rate,
	lease_tax_rate as tax_rate,
	lease_length_of_irr_analysis_yrs as length_of_irr_analysis_yrs
FROM diffusion_template.input_solar_finances_com

UNION ALL

SELECT year, 'ind'::text as sector_abbr, 'host_owned'::text as business_model,
	loan_term_yrs as loan_term_yrs, 
	loan_rate as loan_rate, 
	loan_down_payment as down_payment,
	loan_discount_rate as discount_rate,
	loan_tax_rate as tax_rate,
	loan_length_of_irr_analysis_yrs as length_of_irr_analysis_yrs
FROM diffusion_template.input_solar_finances_ind

UNION ALL

SELECT year, 'ind'::text as sector_abbr, 'tpo'::text as business_model,
	lease_term_yrs as loan_term_yrs, 
	lease_rate as loan_rate, 
	lease_down_payment as down_payment,
	lease_discount_rate as discount_rate,
	lease_tax_rate as tax_rate,
	lease_length_of_irr_analysis_yrs as length_of_irr_analysis_yrs
FROM diffusion_template.input_solar_finances_ind;


DROP TABLE IF EXIStS diffusion_template.input_solar_finances_depreciation_schedule CASCADE;
CREATE TABLE diffusion_template.input_solar_finances_depreciation_schedule
(
	ownership_year integer NOT NULL,
	year integer NOT NULL,
	deprec_rate numeric NOT NULL
);