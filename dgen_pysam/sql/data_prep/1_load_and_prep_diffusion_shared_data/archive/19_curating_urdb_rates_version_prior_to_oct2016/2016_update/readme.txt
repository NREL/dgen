READ ME FOR TABLES

SCHEMA: urdb_rates
	- this is where the tarriff_generator.py inputs are stored
	- this is where all of the utility geometry data creation took place

SCHEMA: diffusion_data_shared
	- this is where all of the working versions of the ranking-related tables were stored

SCHEMA diffusion_shared
	- this is where all of the final tables that will be used by the model are copied to


urdb_rates.urdb3_verified_rates_sam_data_20161005
		- This is the raw URDB data generated using tarriff_generator.py
urdb_rates.urdb_utility_eia_and_county_ids_lkup_20161005
		- This is the lookup table created that links each rate to a utility to a county
urdb_rates.utility_county_geoms_20161005
		- These geometries are not unionized. Each rate is duplicated for each utility and for each county (or sub region) 

diffusion_data_shared.urdb_rates_sam_min_max
					- This is the copied table of urdb_rates.urdb3_verified_rates_sam_data_20161005 plus min/max demand and energy fields pulled from the json
diffusion_data_shared.urdb_rates_geoms_20161005
					- 
diffusion_data_shared.urdb_rates_attrs_lkup_20161005
			- 
diffusion_data_shared.cnty_to_util_type_lkup
					- 
diffusion_data_shared.cnty_ranked_rates_lkup_20161005
			- 


diffusion_data_shared.cnty_ranked_rates_final_20161005