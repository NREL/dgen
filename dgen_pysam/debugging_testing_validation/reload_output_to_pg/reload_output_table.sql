-- drop existing indices on the diffusion_wind table
DROP INDEX IF EXISTS diffusion_wind.outputs_all_business_model_btree;
DROP INDEX IF EXISTS diffusion_wind.outputs_all_metric_btree;
DROP INDEX IF EXISTS diffusion_wind.outputs_all_sector_btree;
DROP INDEX IF EXISTS diffusion_wind.outputs_all_state_abbr_btree;
DROP INDEX IF EXISTS diffusion_wind.outputs_all_system_size_factors_btree;
DROP INDEX IF EXISTS diffusion_wind.outputs_all_turbine_height_m_btree;
DROP INDEX IF EXISTS diffusion_wind.outputs_all_year_btree;
-- delete everything in the table
delete from diffusion_wind.outputs_all;

-- load the data from the csv file 
-- (may need to scp this over from the compute node and then gzip)
	--  scp mgleason@cn05.bigde.nrel.gov:/home/cdong/github/diffusion/runs_wind/results_20150323_151306/BAU/outputs.csv.gz .
	-- gunzip outputs.csv.gz
-- note: this requires SU privileges
COPY diffusion_wind.outputs_all
FROM '/home/mgleason/data/outputs.csv'
with csv header;

-- recreate all the indices
CREATE INDEX outputs_all_business_model_btree
  ON diffusion_wind.outputs_all
  USING btree
  (business_model COLLATE pg_catalog."default");

CREATE INDEX outputs_all_metric_btree
  ON diffusion_wind.outputs_all
  USING btree
  (metric COLLATE pg_catalog."default");

CREATE INDEX outputs_all_sector_btree
  ON diffusion_wind.outputs_all
  USING btree
  (sector COLLATE pg_catalog."default");

CREATE INDEX outputs_all_state_abbr_btree
  ON diffusion_wind.outputs_all
  USING btree
  (state_abbr COLLATE pg_catalog."default");

CREATE INDEX outputs_all_system_size_factors_btree
  ON diffusion_wind.outputs_all
  USING btree
  (system_size_factors COLLATE pg_catalog."default");

CREATE INDEX outputs_all_turbine_height_m_btree
  ON diffusion_wind.outputs_all
  USING btree
  (turbine_height_m);

CREATE INDEX outputs_all_year_btree
  ON diffusion_wind.outputs_all
  USING btree
  (year);

select sum(installed_capacity)/1000
FROM diffusion_wind.outputs_all
where year = 2050;