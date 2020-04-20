import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib
matplotlib.style.use('ggplot')

# Setup Paths
eia_csv = '/Volumes/Staff/mgleason/dGeo/Data/Source_Data/EIA_NewBuilds_HousingStarts_ComFloospace/input_data/eia_new_growth_regional.csv'
uva_csv = '/Volumes/Staff/mgleason/dGeo/Data/Source_Data/EIA_NewBuilds_HousingStarts_ComFloospace/input_data/uva_state_pop_projections.csv'
out_csv = '/Volumes/Staff/mgleason/dGeo/Data/Source_Data/EIA_NewBuilds_HousingStarts_ComFloospace/dissag_newbuilds_from_region_to_state_popprojections.csv'
plot_csv = '/Volumes/Staff/mgleason/dGeo/Data/Source_Data/EIA_NewBuilds_HousingStarts_ComFloospace/plots/dissag_newbuilds_from_region_to_state_popprojections_all_fields_to_plot.csv'
out_image_path = '/Volumes/Staff/mgleason/dGeo/Data/Source_Data/EIA_NewBuilds_HousingStarts_ComFloospace/plots'

#Read csv to df 
newbuilds = pd.read_csv(eia_csv, sep=',',header=0)
pproject = pd.read_csv(uva_csv, sep=',',header=0)


# Get lists for years, scenerios, and regions
years_list = np.arange(2010,2041).astype(str).tolist()
years = np.arange(2012, 2041).astype(str)
scenerio_list = np.unique(newbuilds['Scenerio'])
region_list = np.unique(pproject['Region'])
print scenerio_list

# Reshape New Builds CSV
newbuilds = pd.melt(newbuilds, id_vars = ['Region','Scenerio', 'Val'], value_vars=years_list, var_name='Year', value_name='Val2')
newbuilds = newbuilds.pivot_table(index = ['Scenerio','Region', 'Year'], columns='Val', values='Val2')
newbuilds = newbuilds.reset_index()
# Delete hs1 (hs manfg homes) and h2 (hs for single-fam-only)
del newbuilds['hs1'], newbuilds['hs2']

# Change Year Type to String
newbuilds['Year'] = newbuilds['Year'].astype(str)

# Reshape UVA poprojects (pproject)
	# Melt State Population Projections by the Many Years Columns to Create Long Format
pproject = pd.melt(pproject, id_vars=['Fips', 'State', 'Region'], value_vars=years_list, var_name='year', value_name='projected_pop')

# Add new empty columns to melted df:
cols = ['hss','hsm', 'cf', 'hss_proj', 'hsm_proj', 'cf_proj'] 
for c in cols:
	pproject[c] = np.zeros(len(pproject.index)).astype(float)
pproject['scenerio'] = np.zeros(len(pproject.index)).astype(float)


# Create Copies for Each Scenerio
def __disaggregate_from_region_to_state(pproject):
	# Duplicate pproject df by the number of scenerios, append/stack duplicates
			# TODO: Need to figure out better way to do this
	hg, hp, lg, lp, r =pproject.copy(), pproject.copy(), pproject.copy(), pproject.copy(), pproject.copy()
	for i, scenerio in enumerate(scenerio_list):
		if i == 0 :
			hg['scenerio'] = scenerio
			__dissag_iterate(hg, scenerio)
		elif i == 1 :
			hp['scenerio'] = scenerio
			__dissag_iterate(hp, scenerio)
		elif i == 2:
			lg['scenerio'] = scenerio
			__dissag_iterate(lg, scenerio)
		elif i == 3:
			lp['scenerio'] = scenerio
			__dissag_iterate(lp, scenerio)
		else:
			r['scenerio'] = scenerio
			__dissag_iterate(r, scenerio)
	pproject = pd.concat([hg,hp,lg,lp,r]).reset_index()		
	print pproject
	pproject = pd.concat([hg,hp,lg,lp,r]).reset_index()		
	__save_df_2_csv(pproject)

	
def __dissag_iterate(pproject, scenerio):
	for r, region in enumerate(region_list):
		print ' ***** Starting Dissaggregation for {0}, {1}'.format(region, scenerio)
		# Loop Through Scenerios, Create New Dataframe for Each Scenerio
		#=== Loop Through Region-Scenerio Years
		for i, yr in enumerate(years):	
			#for ii, yr in enumerate(years):
				val = newbuilds[(newbuilds['Scenerio'] == scenerio) & (newbuilds['Year']==yr) & (newbuilds['Region']==region)]
				hss = val['hss'].values
				hsm = val['hsm'].values
				cf = val['cf'].values

				#-- State--
					# Disaggregate by State Pop Projections
				# Housing Start 
				query = ((pproject['year'] == yr) & (pproject['Region'] == region) & (pproject['scenerio'] == scenerio))
				pproject['hss_proj'][(query)] = pproject['projected_pop'] * hss
				pproject['hsm_proj'][(query)] = pproject['projected_pop'] * hsm
				# Commercial FloorSpace
				pproject['cf_proj'] [(query)]= pproject['projected_pop'] * cf
				#-- regional --
					# Projected Housing Starts from EIA, regional Level
				# Housing Start
				pproject['hss'][query] = hss
				pproject['hsm'][query] = hsm
				# Commercial FloorSpace
				pproject['cf'][query] = cf 

def __save_df_2_csv(pproject):
	# Save cleaned-up csv with select fields
	out_df = pproject[['Fips','State','Region', 'year', 'scenerio','hss_proj','hsm_proj','cf_proj']]
	out_df = out_df.rename(columns = {'hss_proj': 'hss', 'hsm_proj':'hsm', 'cf_proj':'cf'})
	out_df.to_csv(out_csv, sep=',', header=True)

	# Save csv with all fields for plotting purposes
	pproject.to_csv(plot_csv, sep = ',', header = True)
	
if __name__ == '__main__':
	__disaggregate_from_region_to_state(pproject)

