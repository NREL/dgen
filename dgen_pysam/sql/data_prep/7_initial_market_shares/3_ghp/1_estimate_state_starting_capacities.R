library(reshape2)
library(ggplot2)
library(RPostgreSQL)
library(dplyr)

################################################################################################################################################
drv <- dbDriver("PostgreSQL")
# connect to postgres
con <- dbConnect(drv, host="gispgdb.nrel.gov", dbname="dav-gis", user="mgleason", password="mgleason")

sql = "SET ROLE 'diffusion-writers';"
dbSendQuery(con, sql)

# cumulative US installations  (as of 2012) by sector
us = read.csv('/Volumes/Staff/mgleason/dGeo/Data/Source_Data/ghp_existing_market_share/navigant_us_cumulative_capacity.csv')

# annual US shipments (for 2008 and 2009) by state
states = read.csv('/Volumes/Staff/mgleason/dGeo/Data/Source_Data/ghp_existing_market_share/eia_table4_6_simple.csv')

# sum the 2008 and 2009 shipments for each state 
states$combined_tons = rowSums(states[, c('shipments_tons_2008', 'shipments_tons_2009')], na.rm = T)

# convert these to weights (which sum to 1)
states$national_tons = sum(states$combined_tons, na.rm = T )
states$wt = states$combined_tons/states$national_tons
sum(states$wt)

# add in the cumulative installations by sector from the navigant table
states$res_national_tons_2012 = us[us$sector_abbr == 'res', 'cumulative_capacity_tons_2012']
states$com_national_tons_2012 = us[us$sector_abbr == 'com', 'cumulative_capacity_tons_2012']
# disaggregate using the weights
states$capacity_tons_2012_res = states$wt * states$res_national_tons_2012
states$capacity_tons_2012_com = states$wt * states$com_national_tons_2012

# extract the data of interest
df = states[, c('destination_state', 'capacity_tons_2012_res', 'capacity_tons_2012_com')]
# melt
dfm = melt(df, id.vars = 'destination_state', value.name = 'capacity_tons')
names(dfm)[1] = 'state'
dfm$sector_abbr = ifelse(dfm$variable == 'capacity_tons_2012_res', 'res', 'com')
dfm = dfm[, c('state', 'sector_abbr', 'capacity_tons')]

# confirm results match the navigant national totals
g = group_by(dfm, sector_abbr) %>%
    summarize(cap = sum(capacity_tons)) %>%
    merge(us, by = 'sector_abbr')
g$cap-g$cumulative_capacity_tons_2012
# 0 0 all set

# write results to postgres
dbWriteTable(con, c('diffusion_geo', 'starting_capacities_2012_ghp'), dfm, row.names = F, overwrite = T)

# dump to a csv
write.csv(dfm, '/Volumes/Staff/mgleason/dGeo/Data/Output/ghp_starting_capacities_by_state_2012/est_cumulative_ghp_capacity_tons_2012.csv', row.names = F)
