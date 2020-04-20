library(reshape2)
library(dplyr)
library(RPostgreSQL)

# Runs separate R file to calculate intensity values in matrix form (CDMS bldg type x Census division)
# source('/Users/kmccabe/Documents/R/Commercial Analysis/Intensity Calculations/Intensity Calc.R', echo=TRUE)

# Read relevant csv files (change file path if necessary)
census_divs = read.csv('/Users/kmccabe/Documents/R/Commercial Analysis/state_to_census_regions_divs_lkup.csv', stringsAsFactors = F)
cdms = read.csv('/Users/kmccabe/Documents/R/Commercial Analysis/cdms_building_sf_by_county_and_bldg_type.csv', stringsAsFactors = F)
spht_int = read.csv('/Users/kmccabe/Documents/R/Commercial Analysis/spht_intensity.csv', check.names = F, stringsAsFactors = F)
wtht_int = read.csv('/Users/kmccabe/Documents/R/Commercial Analysis/wtht_intensity.csv', check.names = F, stringsAsFactors = F)
cool_int = read.csv('/Users/kmccabe/Documents/R/Commercial Analysis/cool_intensity.csv', check.names = F, stringsAsFactors = F)

# Combines COM8 & COM9 bldg types, renames column, removes extra.
cdms$com8 = cdms$com8 + cdms$com9
names(cdms)[24] = 'com8_9'
cdms$com9 = NULL

# Renames specific columns for later matching purposes.
names(cdms)[1] = 'state_abbr'
names(spht_int)[1] = 'bldg_type'
names(wtht_int)[1] = 'bldg_type'
names(cool_int)[1] = 'bldg_type'

# Melt data frames
spht_int_m = melt(spht_int, id.var = ('bldg_type'), variable.name = 'division', value.name = 'spht_mbtu_per_sqft')
wtht_int_m = melt(wtht_int, id.var = ('bldg_type'), variable.name = 'division', value.name = 'wtht_mbtu_per_sqft')
cool_int_m = melt(cool_int, id.var = ('bldg_type'), variable.name = 'division', value.name = 'cool_mbtu_per_sqft')

cdms_m = melt(cdms, id.var = c('state_abbr', 'state_fips', 'county', 'county_fips', 'county_id'), 
              variable.name = 'bldg_type', value.name = 'sqft')

# Merge demand data frames to building type data frame. Calculate demand totals per county with intensity and square footage data.
m = merge(cdms_m, census_divs, by = ('state_abbr'))
m2 = merge(m, spht_int_m, by = c('bldg_type', 'division'))
m2 = merge(m2, wtht_int_m, by = c('bldg_type', 'division'))
m2 = merge(m2, cool_int_m, by = c('bldg_type', 'division'))
m2$spht_est_mbtu = m2$spht_mbtu_per_sqft * m2$sqft
m2$wtht_est_mbtu = m2$wtht_mbtu_per_sqft * m2$sqft
m2$cool_est_mbtu = m2$cool_mbtu_per_sqft * m2$sqft

# Sum county demand totals grouped by division to find division totals.
s_spht = group_by(m2, division) %>%
  summarize(spht_total_est_mbtu = sum(spht_est_mbtu))
s_wtht = group_by(m2, division) %>%
  summarize(wtht_total_est_mbtu = sum(wtht_est_mbtu))
s_cool = group_by(m2, division) %>%
  summarize(cool_total_est_mbtu = sum(cool_est_mbtu))

# Merge data frames. Calculate county weights.
m3 = merge(m2, s_spht, by = c('division'))
m3 = merge(m3, s_wtht, by = c('division'))
m3 = merge(m3, s_cool, by = c('division'))
m3$spht_wt = m3$spht_est_mbtu / m3$spht_total_est_mbtu
m3$wtht_wt = m3$wtht_est_mbtu / m3$wtht_total_est_mbtu
m3$cool_wt = m3$cool_est_mbtu / m3$cool_total_est_mbtu

# Create data frame with CBECS summary table totals, by division (1E9 * TBTU = mBTU)
s2_spht = data.frame('division' = s_spht$division, 'spht_total_mbtu_division' = 1E9*c(676,113,488,167,186,131,278,198,128))
s2_wtht = data.frame('division' = s_wtht$division, 'wtht_total_mbtu_division' = 1E9*c(77,32,74,41,20,68,100,30,59))
s2_cool = data.frame('division' = s_cool$division, 'cool_total_mbtu_division' = 1E9*c(46,27,45,31,10,55,162,21,119))
# # Use microdata sums instead of summary table totals.
# drv = dbDriver("PostgreSQL")
# conn = dbConnect(drv, host='gispgdb.nrel.gov', port=5432, dbname='dav-gis', user='kmccabe', password='kmccabe')
# 
# sql = 'SELECT  a.cendiv8, a.adjwt8, b.mfhtbtu8, b.mfwtbtu8, b.mfclbtu8
#       FROM eia.cbecs_2003_microdata_file_02 a
#       LEFT JOIN eia.cbecs_2003_microdata_file_17 b
#       ON a.pubid8 = b.pubid8;'
# df = dbGetQuery(conn,sql)
# df$spht_est_mbtu = df$adjwt8 * df$mfhtbtu8 / 1E3
# df$wtht_est_mbtu = df$adjwt8 * df$mfwtbtu8 / 1E3
# df$cool_est_mbtu = df$adjwt8 * df$mfclbtu8 / 1E3
# s2_spht = group_by(df, cendiv8) %>%
#   summarize(spht_total_mbtu_division = sum(spht_est_mbtu, na.rm=T))
# s2_wtht = group_by(df, cendiv8) %>%
#   summarize(wtht_total_mbtu_division = sum(wtht_est_mbtu, na.rm=T))
# s2_cool = group_by(df, cendiv8) %>%
#   summarize(cool_total_mbtu_division = sum(cool_est_mbtu, na.rm=T))
# div_names = c('New England', 'Middle Atlantic', 'East North Central', 'West North Central', 'South Atlantic',
#               'East South Central', 'West South Central', 'Mountain', 'Pacific')
# s2_spht$cendiv8 = div_names
# s2_wtht$cendiv8 = div_names
# s2_cool$cendiv8 = div_names
# names(s2_spht)[1] = 'division'
# names(s2_wtht)[1] = 'division'
# names(s2_cool)[1] = 'division'

# Merges summary table data frames by census div., multiplies by county weights for county demand totals
m4 = merge(m3, s2_spht, by = c('division'))
m4 = merge(m4, s2_wtht, by = c('division'))
m4 = merge(m4, s2_cool, by = c('division'))
m4$county_spht_mbtu = m4$spht_wt * m4$spht_total_mbtu_division
m4$county_wtht_mbtu = m4$wtht_wt * m4$wtht_total_mbtu_division
m4$county_cool_mbtu = m4$cool_wt * m4$cool_total_mbtu_division

# Orders and rearranges columns
m4 = m4[with(m4, order(state_fips, county_fips, bldg_type)), ]
m4 = m4[c(11, 10, 1, 12, 9, 3, 5, 4, 6, 7, 8, 2, 13:30)]

# # Casts back into matrix form (doesn't work with all 3 demand types in m4)
# m4_cast = dcast(m4, region + region_long_name + division + division_abbr + state_name + state_abbr + state_fips + 
#                   county + county_fips + county_id ~ bldg_type, value.var = 'county_spht_mbtu')

# Write melted form (m4) or matrix form (m4_cast) to csv file
# write.csv(m4, '/Users/kmccabe/Documents/R/Thermal Demand (R Code)/Commercial Analysis/comm_demand_by_county_and_cdms_bldg_type.csv', row.names = F)
# write.csv(m4_cast, 'spht_by_county_and_cdms_bldg_type.csv')