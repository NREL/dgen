library(RPostgreSQL)
library(reshape2)
library(stringr)
library(dplyr)

drv = dbDriver("PostgreSQL") 
conn = dbConnect(drv, host='gispgdb.nrel.gov', port=5432, dbname='dav-gis', user='mgleason', password='mgleason')

# read in the raw data from kevin
df = read.csv('/Volumes/Staff/mgleason/dGeo/Data/Source_Data/Thermal_Demand_kmccabe/comm_demand_by_county_and_cdms_bldg_type_2016_03_21.csv', check.names = F)

# unit conversions
df$space_heating_thermal_load_mmbtu = df$county_spht_mbtu/1e3
df$water_heating_thermal_load_mmbtu = df$county_wtht_mbtu/1e3
df$space_cooling_thermal_load_mmbtu = df$county_cool_mbtu/1e3
df$total_heating_thermal_load_mmbtu = df$space_heating_thermal_load_mmbtu + df$water_heating_thermal_load_mmbtu

# lpad  fips codes
df$state_fips = sprintf('%02d', df$state_fips)
df$county_fips = sprintf('%03d', df$county_fips)

cdf = group_by(df, county_id, state_fips, county_fips, state_abbr, county) %>%
      summarize(
                sqft = sum(sqft),
                space_heating_thermal_load_mmbtu = sum(space_heating_thermal_load_mmbtu),
                water_heating_thermal_load_mmbtu = sum(water_heating_thermal_load_mmbtu),
                space_cooling_thermal_load_mmbtu = sum(space_cooling_thermal_load_mmbtu),
                total_heating_thermal_load_mmbtu = sum(total_heating_thermal_load_mmbtu)
              )
# convert to real df
cdf = as.data.frame(cdf)

# check row count (should be 3141)
nrow(cdf)
# 3141 -- all set

# add sector
cdf$sector_abbr = 'com'

sql = "SET ROLE 'diffusion-writers';"
dbSendQuery(conn, sql)

dbWriteTable(conn, c('diffusion_shared', 'county_thermal_demand_com'), cdf, row.names = F, overwrite = T)

# add primary key
sql = "ALTER TABLE diffusion_shared.county_thermal_demand_com
       ADD PRIMARY KEY (county_id);"
dbSendQuery(conn, sql)
