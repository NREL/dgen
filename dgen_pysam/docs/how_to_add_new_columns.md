# Adding Columns to Postgres Pts Table
##Database Edits
* If the data are stored directed in the Pts Table:
	* Edit all of the following:
		* diffusion_repo/sql/data_prep/4_load_and_populate_residential_points_grid.sql
		* diffusion_repo/sql/data_prep/5_load_and_populate_commercial_points_grid.sql
		* diffusion_repo/sql/data_prep/5b_load_and_populate_industrial_points_grid.sql
	* Edit diffusion_repo/sql/data_prep/10_create_views.sql
	    * Specifically edit the creation scripts for wind_ds.pt_grid_us_res_joined, wind_ds.pt_grid_us_com_joined, and wind_ds.pt_grid_us_ind_joined (order doesn't matter)
* Else:
    * Edit diffusion_repo/sql/data_prep/10_create_views.sql
	    * Specifically edit the creation scripts for wind_ds.pt_grid_us_res_joined, wind_ds.pt_grid_us_com_joined, and wind_ds.pt_grid_us_ind_joined (order doesn't matter)

##Script Edits:
* In data_functions.py:
    * Edit generate_customer_bins(), under  "Find All Combinations of Costs and Resource for Each Customer Bin"
        * Add new field to the sql string with alias a. (order doesn't matter)
    * Edit copy_outputs_to_csv():
        * Add new field to the sql string three times (once for each sector subquery) with alias b. (order does matter -- match to order in reload_results.py)
* In reload_results.py:
	* Edit sql string:
		* Add new field to the table creation sql string with the correct data type (order does matter -- match to order in copy_outputs_to_csv())


#Adding Columns to Python Data Frame
##Database Edits
* Edit diffusion_repo/sql/data_prep/12_initialize_output_tables.sql:
	* Add new column to each of the sector tables (order doesn't matter)

## Script Edits
* In dg_wind_model.py:
    * Add the column to the main pandas df
* In data_functions.py:
    * Edit write_outputs():
        * Add field to fields list (order doesn't matter)
    * Edit copy_outputs_to_csv():
        * Add new field to the sql string three times (once for each sector subquery) with alias a. (order does matter -- match to order in reload_results.py)
* In reload_results.py:
	* Edit sql string:
		* Add new field to the table creation sql string with the correct data type (order does matter -- match to order in copy_outputs_to_csv())
