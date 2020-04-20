set role 'diffusion-writers';

DROP TABLE IF EXISTS diffusion_shared.aeo_energy_price_projections_2015;
CREATE TABLE diffusion_shared.aeo_energy_price_projections_2015
(
	year integer,
	dlrs_per_mmbtu numeric,
	sector_abbr varchar(3),
	census_division_abbr varchar(3),
	fuel_type text,
	scenario text
);

\COPY diffusion_shared.aeo_energy_price_projections_2015 FROM '/Volumes/Staff/mgleason/dGeo/Data/Source_Data/EIA_AEO_2015_Energy_Prices/aeo_2015_energy_price_projections.csv' with csv header;



-- check results
select *
FROM diffusion_shared.aeo_energy_price_projections_2015;
-- 52272 rows


-- add indices
CREATE INDEX aeo_energy_price_projections_2015_btree_year
ON diffusion_shared.aeo_energy_price_projections_2015
USING BTREE(year);

CREATE INDEX aeo_energy_price_projections_2015_btree_sector_abbr
ON diffusion_shared.aeo_energy_price_projections_2015
USING BTREE(sector_abbr);

CREATE INDEX aeo_energy_price_projections_2015_btree_census_division_abbr
ON diffusion_shared.aeo_energy_price_projections_2015
USING BTREE(census_division_abbr);

CREATE INDEX aeo_energy_price_projections_2015_btree_fuel_type
ON diffusion_shared.aeo_energy_price_projections_2015
USING BTREE(fuel_type);

CREATE INDEX aeo_energy_price_projections_2015_btree_scenario
ON diffusion_shared.aeo_energy_price_projections_2015
USING BTREE(scenario);

-- add primary key
ALTER TABLE diffusion_shared.aeo_energy_price_projections_2015
ADD PRIMARY KEY (year, sector_abbr, census_division_abbr, fuel_type, scenario);
-- all set -- all unique

