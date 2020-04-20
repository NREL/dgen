library(reshape2)
library(dplyr)
library(RPostgreSQL)

# Read csv of housing unit totals (w/ reportable domain & climate region info) by county.
units = read.csv('/Users/kmccabe/Documents/R/Residential Analysis/county_housing_units_w_recs_regions.csv', stringsAsFactors = F)

##### Query space/water heating and cooling demand from RECS Microdata #####
drv = dbDriver("PostgreSQL") 
conn = dbConnect(drv, host='gispgdb.nrel.gov', port=5432, dbname='dav-gis', user='kmccabe', password='kmccabe')

sql = 'SELECT  doeid, regionc, division, reportable_domain, nweight, climate_region_pub, aia_zone, 
       totalbtusph, totalbtuwth, totalbtucol
FROM eia.recs_2009_microdata'

df = dbGetQuery(conn,sql)
df = df[with(df, order(reportable_domain)), ]
#####

# Apply individual weights to demand entries.
df$tot_sph = df$nweight * df$totalbtusph  # mBTU
df$tot_wth = df$nweight * df$totalbtuwth  # mBTU
df$tot_col = df$nweight * df$totalbtucol  # mBTU

# Sum demand totals and housing unit totals grouped by reportable domain/climate region cross-section
sph_summary = group_by(df, reportable_domain, climate_region_pub) %>%
  summarize(domain_zone_sph_total = sum(tot_sph))
wth_summary = group_by(df, reportable_domain, climate_region_pub) %>%
  summarize(domain_zone_wth_total = sum(tot_wth))
col_summary = group_by(df, reportable_domain, climate_region_pub) %>%
  summarize(domain_zone_col_total = sum(tot_col))
units_summary = group_by(units, reportable_domain, climate_region_pub) %>%
  summarize(housing_units_domain_total = sum(housing_units))

# Convert units from mBTU to Trillion BTU
sph_summary$domain_zone_sph_total = sph_summary$domain_zone_sph_total*1000/1E12
wth_summary$domain_zone_wth_total = wth_summary$domain_zone_wth_total*1000/1E12
col_summary$domain_zone_col_total = col_summary$domain_zone_col_total*1000/1E12

# Merge above summaries to single data frame
demand_summary = merge(sph_summary, wth_summary, by = c('reportable_domain', 'climate_region_pub'))
demand_summary = merge(demand_summary, col_summary, by = c('reportable_domain', 'climate_region_pub'))

# Merge housing unit data frame with the unit summary data frame to calculate county weights
m = merge(units, units_summary, by = c('reportable_domain', 'climate_region_pub'))
m$wts = m$housing_units/m$housing_units_domain_total

# Merge housing units data frame (m) with demand summary data frame. Multiply domain/climate region demand totals by county 
# weights to obtain county-level demand totals.
m2 = merge(m, demand_summary, by = c('reportable_domain', 'climate_region_pub'), all.x = T)
m2$county_sph_total_tbtu = m2$wts * m2$domain_zone_sph_total
m2$county_wth_total_tbtu = m2$wts * m2$domain_zone_wth_total
m2$county_col_total_tbtu = m2$wts * m2$domain_zone_col_total

# Reorder data frame
m2 = m2[with(m2, order(reportable_domain, climate_region_pub, fips)), ]

# ?
m2$X = NULL
m2$X.1 = NULL
m2$X.2 = NULL
m2$X.3 = NULL

# Check that sums add to reportable domain totals from RECS summary tables.
check_sph = group_by(m2, reportable_domain) %>%
  summarize(check_sph = sum(county_sph_total_tbtu, na.rm = T))
check_wth = group_by(m2, reportable_domain) %>%
  summarize(check_wth = sum(county_wth_total_tbtu, na.rm = T))
check_col = group_by(m2, reportable_domain) %>%
  summarize(check_col = sum(county_col_total_tbtu, na.rm = T))
t = m2[which(is.na(m2$county_sph_total_tbtu)),c(6:7,9)]

# Write final table to csv
# write.csv(m2, '/Users/kmccabe/Documents/R/Residential Analysis/res_county_demand_tbtu.csv', row.names = F)