set role 'eia-writers';

DROP TABLE IF EXISTS eia.avg_elec_price_by_state_by_provider_1990_2014;
CREATE TABLE eia.avg_elec_price_by_state_by_provider_1990_2014
(
	year integer,
	state varchar(2),
	sales_type text,
	cents_per_kwh_residential numeric,
	cents_per_kwh_commercial numeric,
	cents_per_kwh_industrial numeric,
	cents_per_kwh_transportation numeric,
	cents_per_kwh_other numeric,
	cents_per_kwh_total numeric
);

\COPY eia.avg_elec_price_by_state_by_provider_1990_2014 FROM '/Volumes/Staff/mgleason/dGeo/Data/Source_Data/EIA_Electricity_Prices/simplified/avgprice_annual.csv' with csv header null as 'NA';

ALTER TABLe eia.avg_elec_price_by_state_by_provider_1990_2014
ADD PRIMARY KEY (year, state, sales_type);

COMMENT ON TABLE eia.avg_elec_price_by_state_by_provider_1990_2014 IS 'Source: http://www.eia.gov/electricity/data/state/avgprice_annual.xls';

