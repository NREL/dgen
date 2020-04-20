# Description: Generate Delineated Areas based on pt well locations
	# -- Create Convex Hulls (--this is done outside of script due to a few problems with reported well areas)
	# -- Buffer the Convex Hulls until they are within +/- 10% of the USGS Circular 892 reported area

# Important -- This script must be run on Donna's mac mini due to complications with python modules and arcpy/ArcGIS python dir on gisdata

import arcpy
import numpy as np
from arcpy import *
import pandas as pd

# Setup Paths
shp = r'S://mgleason/dGeo/Data/Source_Data/USGS_Circular_892/mmooney/temp/delineated_areas/source_data/delineated_areas_xy_prj.shp'
temp_buffer_output = r'S://mgleason/dGeo/Data/Source_Data/USGS_Circular_892/mmooney/temp/delineated_areas/temp_data/buffers_1'
temp_buffer_output_2 = r'S://mgleason/dGeo/Data/Source_Data/USGS_Circular_892/mmooney/temp/delineated_areas/temp_data/buffers_2'
convex_hulls = r'S://mgleason/dGeo/Data/Source_Data/USGS_Circular_892/mmooney/temp/delineated_areas/temp_data/convex_hulls/delineated_areas_convex_hulls_fixed.shp' # includes manual edits
merge_output = r'S://mgleason/dGeo/Data/Source_Data/USGS_Circular_892/mmooney/temp/delineated_areas/delineated_areas_final.shp'
wksp =  r'S://mgleason/dGeo/Data/Source_Data/USGS_Circular_892/mmooney/temp/delineated_areas/temp_data/convex_hulls'

# Define list to store issues
    # i.e. Store the UID where the area original Convex Hull Area is larger than 15% of the USGS Area
issues =[] 


def main_func(shp, temp_buffer_output, temp_buffer_output_2, convex_hulls, merge_output, issues): 
	# Create Layer
	da_lyr = 'da'
	arcpy.MakeFeatureLayer_management(shp, da_lyr)

	# Get list of uids
	uids, uarea, umax, umin = np.array([]), np.array([]), np.array([]), np.array([])
	scur = arcpy.da.SearchCursor(da_lyr, ['uid', 'geo_area', 'min_010', 'max_010'])
	for row in scur:
		uids = np.append(uids, row[0])
		uarea = np.append(uarea, row[1])
		umin = np.append(umin, row[2])
		umax = np.append(umax, row[3])
	df = pd.DataFrame({'uids': uids, 'uarea': uarea, 'umin': umin, 'umax': umax})
	df = df.drop_duplicates(['uids', 'uarea', 'umin', 'umax'])
	uid_len = len(df['uids'])

	# Create Convex Hulls for Each UID (if no problems exists) 
	arcpy.env.workspace = wksp
	arcpy.env.overwriteOutput = True
	#arcpy.MinimumBoundingGeometry_management(da_lyr, convex_hulls, "CONVEX_HULL", "LIST", "uid") #Note: if a record has no xy, convex hull will terminate without warning msg

	# Add Field / Calculate Area
	convex_lyr = calculate_area_join_fields('convex_lyr', convex_hulls, da_lyr, 'False', '')
	# Join Fields to complete table attributes
	

	# Loop through Uids
	for i, uid in enumerate(df['uids']):

		buff_temp1 = temp_buffer_output + '/' + uid + '.shp'
		buff_temp2 = temp_buffer_output_2 + '/' + uid + '.shp'

		print '____________________________'
		print 'STARTING {0} ....'.format(uid)
		# Select All Points belonging to the same UID/ DA
		exp = "{0} = '{1}'".format("uid", uid)
		arcpy.SelectLayerByAttribute_management(convex_lyr, "NEW_SELECTION", exp)


		# Find UID Areas that need to be Buffered:
		scur = arcpy.da.SearchCursor(convex_lyr, ['uid', 'area', 'min_010', 'max_010'])
		for row in scur:
			# Find UID
			if row[0] == uid:
				# Find UID Convex Hulls that Are Same Size as Area
				if row[2] <= row[1] <= row[3]:
					arcpy.CopyFeatures_management(convex_lyr, buff_temp1)
					print '--- Area {0} is within +/-12p bounds of {1}:{2}'.format('%.2f' % row[1], int(row[2]), int(row[3]))
				# Find Potential Issues, where the Convex Hull is GREATER THAN usgs area
				elif row[1] > row[3]:
					issues.append(uid)
					print '--- [ISSUE] Area {0} is OUTSIDE +/-12p bounds of {1}:{2}'.format('%.2f' % row[1], int(row[2]), int(row[3]))
					arcpy.CopyFeatures_management(convex_lyr, buff_temp1) # Copy Anyways
				# Find Convex Hulls that Need to be Buffered so that they are within the Bounds of +/- %15 Error
				else:
					#---------------------------------
					# Buffer till Area is B/w +/- 10%
					#----------------------------------
					# ---- Set Buffer Steps Based on Area ---#
						# The idea is to choose a buffer that fits within the +/- % bounds

					if row[1] <= 20: # Super Small Sizes
						print '--- Buffering {0} @ {1} KM Intervals'.format(uid, 0.25)
						r = loop_buffer_get_area(convex_lyr, buff_temp1, buff_temp2, row[0], row[1], row[2], row[3], 0.25, i, uid_len, da_lyr)
						if r == 0:
							print '--- Buffering {0} @ {1} KM Intervals'.format(uid, 0.05)
							r2 =loop_buffer_get_area(convex_lyr, buff_temp1, buff_temp2, row[0], row[1], row[2], row[3], 0.05, i, uid_len, da_lyr)
							if r2 == 0:
								print '--- Buffering {0} @ {1} KM Intervals'.format(uid, 0.01)
								r3 = loop_buffer_get_area(convex_lyr, buff_temp1, buff_temp2, row[0], row[1], row[2], row[3], 0.01, i, uid_len, da_lyr)
					
					elif 20 < row[1] <= 100: # Small-Medium Sizes
						print '--- Buffering {0} @ {1} KM Intervals'.format(uid, 1)
						r = loop_buffer_get_area(convex_lyr, buff_temp1, buff_temp2, row[0], row[1], row[2], row[3], 1, i, uid_len, da_lyr)
						if r == 0:
							print '--- Buffering {0} @ {1} KM Intervals'.format(uid, 0.5)
							r2 = loop_buffer_get_area(convex_lyr, buff_temp1, buff_temp2, row[0], row[1], row[2], row[3], 0.5, i, uid_len, da_lyr)
							if r2 == 0:
								print '--- Buffering {0} @ {1} KM Intervals'.format(uid, 0.25)
								r2 = loop_buffer_get_area(convex_lyr, buff_temp1, buff_temp2, row[0], row[1], row[2], row[3], 0.25, i, uid_len, da_lyr)
							
					else:  # Larger Sizes
						print '--- Buffering {0} @ {1} KM Intervals'.format(uid, 1.5)
						r= loop_buffer_get_area(convex_lyr, buff_temp1, buff_temp2, row[0], row[1], row[2], row[3], 1.5, i, uid_len, da_lyr)
						if r ==0:
							print '--- Buffering {0} @ {1} KM Intervals'.format(uid, 1)
							r2= loop_buffer_get_area(convex_lyr, buff_temp1, buff_temp2, row[0], row[1], row[2], row[3], 1, i, uid_len, da_lyr)
					
	print '\n___ DONE w/ Buffer Looping ___\n'
	print ' *****  Here are the issues we have come across: {0}'.format(issues)

	# Merge All Buffers Together
	print '______________________ \n merging...'
	mlist = []
	arcpy.env.workspace = temp_buffer_output
	for shp in os.listdir(temp_buffer_output):
		if shp.endswith('shp'):
			mlist.append(shp)
	arcpy.Merge_management(mlist, merge_output)



def loop_buffer_get_area(convex_lyr, buff_temp1, buff_temp2, uid, geo_area, Min, Max, bval,i, uid_len, da_lyr):
	bval_original = bval
	while bval < Max + 1:
	    arcpy.env.workspace = temp_buffer_output_2
	    arcpy.env.overwriteOutput= True
	    arcpy.Buffer_analysis(convex_lyr, buff_temp2, '{0} Kilometers'.format(bval), "FULL", "ROUND", "ALL")

	    buf_lyr = calculate_area_join_fields('buf_lyr', buff_temp2, da_lyr, 'True', uid)

	    scur2 = arcpy.da.SearchCursor(buf_lyr, ['area'])
	    for row in scur2:
	    	buf_area = row[0]              
	    del scur2
	    
	    # Check if buffer area is within the +/- 10% bounds
	    if Min <= buf_area <= Max:
	        print '       *** {0} KM has area of {1}, which IS WITHIN the of bounds {2}:{3}.'.format(bval, '%.2f' % buf_area, int(Min), int(Max))
	        # Copy feature over to temp folder 1
	        arcpy.CopyFeatures_management(buf_lyr, buff_temp1)
	        buf_lyr_final = 'buff_layer_final{0}'.format(uid)
	        arcpy.MakeFeatureLayer_management(buff_temp1, buf_lyr_final)
	        try:
	        	# -- Add UID INFO
	        	try:
	        		arcpy.AddField_management(buf_lyr_final, 'uid', 'TEXT')
	        	except:
	        		continue
	        	exp = '"{0}"'.format(uid)
	        	arcpy.CalculateField_management(buf_lyr_final, 'uid', exp)
	        	# -- Add Other FIeld Info
	        	fill_val = [Max, Min, geo_area, buf_area]
	        	fill_field = ['max_010', 'min_010', 'geo_area', 'area']	
	        	for ff, fill in enumerate(fill_field):
	        		try:
	        			arcpy.AddField_management(buf_lyr_final, fill, 'DOUBLE')
	        		except:
	        			continue
	        		exp = "{0}".format(fill_val[ff])	
	        except Exception, e:
	        	print e
	        print '        ------ {0} out of {1} complete ------'.format(i, uid_len)
	        rval = 1  # To signal success
	        bval = Max + 100
	        break # End Buffer Iteration
	        print 'break is not working...'

	    # Check if Buffer Size is too Large to get within +/- 10% bounds
	    elif buf_area >= Max + 1:
	    	print 'issue!! -- USGS Area: {0}, GIS Area: {1}'.format(int(Max), buf_area)
	    	rval = 0 # Return 0 to tell code that this buffer size is too large and that we need to size down and redo the iteration
	    	bval = Max + 100
	    	break # End Buffer Iteration to Start a new one with different buffer size parameter
	    
	    # Otherwise, Contiue Buffering Until:
	    			# 1) area is w/in +/- 10%
					# OR
					# 2) We determine the Buffer size is too large
	    else:
	    	bval = bval + bval_original
	    	continue # Keep Buffering till area is within bounds
	return rval



def calculate_area_join_fields(lyr_name, shpfile, da_lyr, buffer_bool, uid):
	lyr = arcpy.MakeFeatureLayer_management(shpfile, lyr_name)
	try:
		arcpy.AddField_management(lyr_name, 'area', 'DOUBLE')
	except Exception, e:
		print e
	arcpy.CalculateField_management(lyr, 'area',  "!SHAPE.AREA@SQUAREKILOMETERS!", 'PYTHON_9.3')
	#if buffer_bool == 'False':
		#arcpy.JoinField_management (lyr, 'uid', da_lyr, 'uid', ['geo_area', 'max_010', 'min_010'])
	return lyr


if __name__ == '__main__':
	main_func(shp, temp_buffer_output, temp_buffer_output_2, convex_hulls, merge_output, issues)




