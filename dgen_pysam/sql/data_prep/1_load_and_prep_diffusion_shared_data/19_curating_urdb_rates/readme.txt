*******************************
Overview of URDB Rate Analysis
*******************************

General Steps:
	1. Tag Utilities (and their rates) to county geometries
	2. Parse up a rate's utility geometry based on whether it applies to the entire utility region or to a specific climate zone (CA Only)
	3. Determine utility type probabilities/weights
		- Determine Utility Customer Distribution
			- Perform NN for utility boundaries missing customer counts
			- Disaggregate utility customer counts to tracts using tract blg counts per sector
			- (*) Perfrom NN for tracts that do not overlap utility
	4. Spatially rank rates per tract (based on distance bin, utility type, and the euclidean distance)
		- Rank rates for each tract
		- Note: Non-spatial ranking is performed in python




***********************
Steps for New Rates
***********************
I. If the rate belongs to an existing utility:
	- Change State Rate Rankings:
		- 1. Remove all state ranks within the state in question
		- 2. Create additional table for new state rankings and rerun the rankings for the state
		- 3. Append the state changes (#2) with #1
		- 4. Copy over the final table (overwrite it) to diffusion_shared schema
	- *Note* -> if the updated rates are in CA, we will need to do additonal work to parse up the rate geometry based on the climate zone (if any)
	
	- TABLES TO UPDATE:
		- diffusion_shared
			- diffusion_shared.tracts_ranked_rates_lkup_20161005
			- diffusion_shared.tract_util_type_weights_res
			- diffusion_shared.tract_util_type_weights_com
			- diffusion_shared.tract_util_type_weights_ind
			- diffusion_shared.urdb3_rate_sam_jsons_20161005
		- diffusion_data_shared
			1. urdb_rates_attrs_lkup_2016100
				- add in new rate (with max rate_id_alias +1 as the new rate_id_alias) and rate attributes
			2. diffusion_data_shared.urdb3_rate_sam_jsons_20161005
				- from #1, add rate_id_alias and json of the new rate(s)
			3. diffusion_data_shared.urdb_rates_geoms_20161005
				- copy geometry of similiar rate and add in rate attributes
			4. urdb_rates_type_lkup
				- run python code (in sql folder) to quickly get rate type value
			5. urdb_rates_sam_min_max
				- run python code (in sql folder) to quickly get min/max values
			6. tract_ranked_rates_final_20161005
				- redo ranks for the entire state where the new rate was added
					- delete, redo, and concatenate
			7. diffusion_data_shared.tracts_ranked_rates_lkup_20161005
				- redo ranks for the entire state where the new rate was added
					- delete, redo, and concatenate
			

II. If the rate belongs to a NEW utility:
	- We will need to redo most of the steps and append them to the final tables
