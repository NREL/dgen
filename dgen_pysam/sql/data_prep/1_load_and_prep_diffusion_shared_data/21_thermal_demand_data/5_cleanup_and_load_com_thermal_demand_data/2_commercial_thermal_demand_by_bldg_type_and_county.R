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

out_cols = c(
              'state_abbr',
              'county',
              'state_fips',
              'county_fips',
              'county_id',
              'sqft',
              'bldg_type',
              'space_heating_thermal_load_mmbtu',
              'water_heating_thermal_load_mmbtu',
              'space_cooling_thermal_load_mmbtu',
              'total_heating_thermal_load_mmbtu'
)

out_df = df[, out_cols]

# add sector
out_df$sector_abbr = 'com'

sql = "SET ROLE 'diffusion-writers';"
dbSendQuery(conn, sql)

dbWriteTable(conn, c('diffusion_shared', 'county_thermal_demand_com_by_bldg_type'), out_df, row.names = F, overwrite = T)

# add primary key
sql = "ALTER TABLE diffusion_shared.county_thermal_demand_com_by_bldg_type
       ADD PRIMARY KEY (county_id, bldg_type);"
dbSendQuery(conn, sql)

# check row count (should be 3141 counties * 17 types = 53397) -- NOTE: 17 instead of 18 because com10 is 0 in all counties
nrow(out_df) # 53397 -- all set

# double check full converage
length(unique(out_df$county_id)) # 3141 counties
# how many counties don't have all types
x = group_by(out_df, county_id) %>%
  summarize(b = sum(!is.na(bldg_type))) %>%
  filter(b != 17)
nrow(x)
# 0 -- all set