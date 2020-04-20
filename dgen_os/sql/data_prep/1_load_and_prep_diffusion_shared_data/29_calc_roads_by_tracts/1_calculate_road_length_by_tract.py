import arcpy, numpy as np
from arcpy import env
import pandas as pd

# Create Shapefile of Tracts (command line)
#pgsql2shp -g the_geom_96703 -f "/Volumes/Staff/mgleason/dGeo/Data/Analysis/calc_road_length_by_tract/census_tracts.shp" -h gispgdb -u mmooney -P mmooney dav-gis diffusion_blocks.tract_geoms

# Define Paths / Shps
temp_intersect_path = r'S:/mgleason/dGeo/Data/Analysis/calc_road_length_by_tract/temp_intersects'
summary_stats_path = r'S:/mgleason/dGeo/Data/Analysis/calc_road_length_by_tract/summary_stats'
road_shp_path = r'S:/mmooney/projects2/2015_12_10_EPSA_Transport_Wind/Data/Data_Gather/DB_Data/roads_all_census_2015/'
tract_shp = r'S:/mgleason/dGeo/Data/Analysis/calc_road_length_by_tract/census_tracts.shp'

# Set up environments
arcpy.env.workspace = temp_intersect_path
arcpy.env.overwriteOutput = True

# Make Layer for The Entire Tract Shp
all_tracts_lyr = 'all_tracts_lyr'
arcpy.MakeFeatureLayer_management(tract_shp, all_tracts_lyr)


# Get List of State Fips to Loop though
st_fips_list = np.array([])
scur = arcpy.da.SearchCursor(all_tracts_lyr, ['state_fips'])
for row in scur:
	st_fips_list = np.append(st_fips_list, str(row[0]))
st_fips_list = np.unique(st_fips_list)


# List to store potential errors
errors = []


# Loop though states
for i, st_fips in enumerate(st_fips_list):
	try:

		# Print Message
		print ('----------------------------------------')
		print ('*-- Starting on State Fips {0} --*'.format(st_fips))
		print ('----------------------------------------')
			
		# Select Tracts in State
		arcpy.SelectLayerByAttribute_management(all_tracts_lyr, "NEW_SELECTION", """"state_fips" = '{0}'""".format(st_fips))

		# Define Road Shapefile
		st_rd_shp = '{0}//roads_all_census_2015_{1}.shp'.format(road_shp_path, st_fips)
		
		# Define Temp Output Intersect
		temp_intersect_shp = '{0}//roads_intersect_bytract_stfips_{1}.shp'.format(temp_intersect_path, st_fips)
		
		#Intersect Roads by Tracts
		arcpy.Intersect_analysis([all_tracts_lyr, st_rd_shp], temp_intersect_shp, 'ALL','', 'LINE')		# *******
		
		# Print Message
		print ('	- (1) Done Intersecting Roads by Tracts')
		
		# Make Layer
		road_intersect_lyr = 'road_intersect_lyr_{0}'.format(st_fips)
		arcpy.MakeFeatureLayer_management(temp_intersect_shp, road_intersect_lyr)
		
		# Add Field to Caclulate Length
		try:
			arcpy.AddField_management(road_intersect_lyr, 'length_m', 'DOUBLE')
		except:
			print '			-- field already exists'

		# Calculate Length (in Meters)
		arcpy.CalculateField_management(road_intersect_lyr, "length_m", "!shape.length@meters!","PYTHON_9.3","#") 	#*******

		# Summary Statistics
		sum_stats_dbf = '{0}/sum_stats_road_length_by_tract_stfips_{1}.dbf'.format(summary_stats_path, st_fips)
		sum_stats_csv = '{0}/sum_stats_road_length_by_tract_stfips_{1}.csv'.format(summary_stats_path, st_fips)
		print ('	- (2) Working on Summary Statistics' )
		arcpy.Statistics_analysis (road_intersect_lyr, sum_stats_dbf, [['length_m', 'SUM']], ['STATE_FIPS', 'TRACT_FIPS', 'GISJOIN'])
		

		# Get Dataframe of dbf table:
		scur = arcpy.da.SearchCursor(sum_stats_dbf, ['STATE_FIPS', 'TRACT_FIPS', 'SUM_length'])
		state_fips_arr = np.array([]).astype(str)
		tract_fips_arr = np.array([]).astype(str)
		sum_length_arr = np.array([])
		for row in scur:
			state_fips_arr = np.append(state_fips_arr, row[0])
			tract_fips_arr = np.append(tract_fips_arr, row[1])
			sum_length_arr = np.append(sum_length_arr, row[2])
		df = pd.DataFrame({'state_fips': state_fips_arr, 'tract_fips': tract_fips_arr, 'sum_length_m': sum_length_arr})
		df.to_csv(sum_stats_csv, sep = ',', header = True, index = False, mode = 'w')



	except Exception, e:
		print e
		errors.append('\n{0}:\n{0}\n\n'.format(st_fips, e))

# Print Errors
print errors
		



# Output = Table
