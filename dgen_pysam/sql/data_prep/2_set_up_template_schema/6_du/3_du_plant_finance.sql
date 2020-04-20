set role 'diffusion-writers';

DROP TABLE IF EXISTS diffusion_template.input_du_plant_finances;
CREATE TABLE diffusion_template.input_du_plant_finances
(
	year integer primary key,
	inflation_rate numeric not null,
	interest_rate_nominal numeric not null,
	interest_rate_during_construction_nominal numeric not null,
	rate_of_return_on_equity numeric not null,
	debt_fraction numeric not null,
	tax_rate numeric not null,
	construction_period_yrs integer not null,
	plant_lifetime_yrs integer not null,
	depreciation_period integer not null,
	CONSTRAINT input_du_plant_finances_year_fkey FOREIGN KEY (year)
		REFERENCES diffusion_config.sceninp_year_range (val) MATCH SIMPLE
		ON UPDATE NO ACTION ON DELETE RESTRICT
);



DROP TABLE IF EXISTS diffusion_template.input_du_plant_construction_finance_factor;
CREATE TABLE diffusion_template.input_du_plant_construction_finance_factor
(
	year integer not null,
	year_of_construction integer not null,
	capital_fraction numeric not null,
	CONSTRAINT input_du_plant_construction_finance_factor_year_fkey FOREIGN KEY (year)
		REFERENCES diffusion_config.sceninp_year_range (val) MATCH SIMPLE
		ON UPDATE NO ACTION ON DELETE RESTRICT
);


DROP TABLE IF EXISTS diffusion_template.input_du_plant_depreciation_factor;
CREATE TABLE diffusion_template.input_du_plant_depreciation_factor
(
	year integer not null,
	year_of_operation integer not null,
	depreciation_fraction numeric not null,
	CONSTRAINT input_du_plant_depreciation_factor_year_fkey FOREIGN KEY (year)
		REFERENCES diffusion_config.sceninp_year_range (val) MATCH SIMPLE
		ON UPDATE NO ACTION ON DELETE RESTRICT
);

