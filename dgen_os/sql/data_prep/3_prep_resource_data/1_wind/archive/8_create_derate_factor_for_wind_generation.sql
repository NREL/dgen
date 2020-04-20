-- per 3/12/14 meeting with Robert Preus and Tony Jimenez, we decided to
-- apply a 15% derate factor to all wind production values to go from gcf to ncf 

-- to facilitate future knowledge of spatial variation in derate factors,
-- we will create a version taht is based on individual counties

CREATE TABLE wind_ds.wind_derate_factors_by_state AS
sELECT distinct(state_abbr), 0.85::numeric as derate_factor
FROM wind_ds.county_geom a;

CREATE INDEX wind_derate_factors_by_state_state_abbr_btree ON wind_ds.wind_derate_factors_by_state using btree(state_abbr);