import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib
matplotlib.style.use('ggplot')

# Setup Paths
csv = '/Volumes/Staff/mgleason/dGeo/Data/Source_Data/EIA_NewBuilds_HousingStarts_ComFloospace/plots/dissag_newbuilds_from_region_to_state_popprojections_all_fields_to_plot.csv'
out_image_path = '/Volumes/Staff/mgleason/dGeo/Data/Source_Data/EIA_NewBuilds_HousingStarts_ComFloospace/plots'


def __create_plots(df, region_list, scenerio_list):
	grouped = df.groupby(['Region', 'scenerio'])
	for (region, name), group in grouped:
	# Make Graphs for Each Scenerio/Region
			#== Housing Starts -- SINGLE FAMILY UNITS==
				#--Setup regional Data for Plotting
				state = group[['hss_proj','year','State']]
				state= pd.pivot_table(state, values= ['hss_proj'],index=['year'], columns='State')
				#--Setup regional Data for Plotting
				regional = group[['year','hss']]#.drop_duplicates([['year','hss']])
				# Assign Titles
				regional_title = '{0} Regional Projections of Single-Family Housing Starts (millions), {1} Scenerio'.format(region, name)
				state_title = 'State Projection Disaggregates of {0} Regional Single Family Housing Starts (millions), {1} Scenerio'.format(region, name)
				# Plot the Figure (2 subplots)
				fig, axes = plt.subplots(nrows=2, ncols=1)
				regional.plot('year','hss',ax=axes[0], fontsize=8); axes[0].set_title(regional_title, fontsize=10);
				state.plot(ax=axes[1], legend = False, fontsize=8); axes[1].set_title(state_title, fontsize=10); #axes[0].legend_.remove();
				#axes[1].legend().draggable()
				# Save the Figure
				
				figname = '{0}/hss_{1}_{2}.png'.format(out_image_path, region, name) 
				fig.tight_layout
				fig.savefig(figname)
				print 'saved figures for {0}, housing_starts'.format(name)
				

			#== Housing Starts -- MULTI FAMILY UNITS ==
				#--Setup regional Data for Plotting
				state = group[['year','State','hsm_proj']]
				state= pd.pivot_table(state, values= ['hsm_proj'],index=['year'], columns='State')
				#--Setup regional Data for Plotting
				regional = group[['year','hsm']]
				regional = regional.set_index('year')
				# Assign Titles
				regional_title = '{0} Regional Projections of Multi-Family Housing Starts (millions), {1} Scenerio'.format(region, name)
				state_title = 'State Projection Disaggregates of {0} Regional Multi Family Housing Starts (millions), {1} Scenerio'.format(region, name)
				# Plot the Figure (2 subplots)
				fig, axes = plt.subplots(nrows=2, ncols=1)
				regional.plot(ax=axes[0], fontsize=8); axes[0].set_title(regional_title, fontsize=10);
				state.plot(ax=axes[1], legend=False, fontsize=8); axes[1].set_title(state_title, fontsize=10); #axes[0].legend_.remove();
				#axes[1].legend().draggable()
				# Save the Figure
				
				figname = '{0}/hsm_{1}_{2}.png'.format(out_image_path, region, name) 
				fig.tight_layout
				fig.savefig(figname)
				print 'saved figures for {0}, housing_starts multifamily'.format(name)

			#== Commercial Floorspace ==
				#--Setup regional Data for Plotting
				state = group[['year','State','cf_proj']]
				state= pd.pivot_table(state, values= ['cf_proj'],index=['year'], columns='State')
				#--Setup regional Data for Plotting
				regional = group[['year','cf']]
				regional = regional.set_index('year')

				# Assign Titles
				regional_title = '{0} Regional Projections of Commercial Floorspace (billions of sqft), {1} Scenerio'.format (region, name)
				state_title = 'State Projection Disaggregates of {0} Regional Commercial Floorspace (billions of sqft), {1} Scenerio'.format(region, name)
				# Plot the Figure (2 subplots)
				fig, axes = plt.subplots(nrows=2, ncols=1)
				regional.plot(ax=axes[0], fontsize=8); axes[0].set_title(regional_title, fontsize=10);
				state.plot(ax=axes[1], legend=False, fontsize=8); axes[1].set_title(state_title, fontsize=10); axes[0].legend_.remove();
				#axes[1].legend().draggable()
				# Save the Figure
				figname = '{0}/cf_{1}_{2}.png'.format(out_image_path, region, name) 
				fig.tight_layout()
				fig.savefig(figname)
				print 'saved figures for {0}, commercial floorspace'.format(name)
				
if __name__ == '__main__':
	#__disaggregate_from_region_to_state(pproject)
	df = pd.read_csv(csv, header=0)
	scenerio_list = np.unique(df['scenerio'])
	region_list = np.unique(df['Region'])
	__create_plots(df, region_list, scenerio_list)
