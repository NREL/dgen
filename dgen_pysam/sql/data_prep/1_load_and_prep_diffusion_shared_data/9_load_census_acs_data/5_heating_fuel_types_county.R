library(RPostgreSQL)
library(reshape2)
library(stringr)
library(dplyr)

drv = dbDriver("PostgreSQL") 
conn = dbConnect(drv, host='gispgdb.nrel.gov', port=5432, dbname='dav-gis', user='mgleason', password='mgleason')

df = read.csv('/Volumes/Staff/mgleason/dGeo/Data/Source_Data/ACS2009_2013_County_HeatingFuelTypes/nhgis0034_csv/nhgis0034_ds201_20135_2013_county_simplified.csv', check.names = F)

# fix the names
names(df) = tolower(names(df))
remap = list(
            'statea' = 'state_fips',
            'countya' = 'county_fips',
            'fuel_oil' = 'distallate_fuel_oil'
  )

for (n in names(remap)){
  i = which(names(df) == n)
  names(df)[i] = remap[[n]]
}

# fix the county and state fips fields
df$state_fips = str_pad(df$state_fips, 2, 'left', '0')
df$county_fips = str_pad(df$county_fips, 3, 'left', '0')

# drop PR
df = filter(df, state != 'Puerto Rico')

# how many unique counties are there?
nrow(df) # 3143

# the ones that need to be fix should include:
# Hoonah-Angoon Census Area + Skagway Municipality = Skagway-Hoonah-Angoon,Alaska 2,232
# Wrangell City and Borough + Alaska,Petersburg Borough = Wrangell-Petersburg,Alaska 2,280
# Prince of Wales-Hyder Census Area = Prince of Wales-Outer Ketchikan,Alaska 2,201

# Hoonah-Angoon Census Area + Skagway Municipality = Skagway-Hoonah-Angoon,Alaska 2,232
rep_row = filter(df, county %in% c('Hoonah-Angoon Census Area', 'Skagway Municipality')) %>%
          summarize(state = 'Alaska',
                    state_fips = '02',
                    county = 'Skagway-Hoonah-Angoon',
                    county_fips = '232',
                    total = sum(total, na.rm = T),
                    natural_gas = sum(natural_gas, na.rm = T),
                    propane = sum(propane, na.rm = T),
                    electricity = sum(electricity, na.rm = T),
                    distallate_fuel_oil = sum(distallate_fuel_oil, na.rm = T),
                    coal = sum(coal, na.rm = T),
                    wood = sum(wood, na.rm = T),
                    solar = sum(solar, na.rm = T),
                    other = sum(other, na.rm = T),
                    none = sum(none, na.rm = T)
                    )
df = rbind(df, rep_row)


# Wrangell City and Borough + Alaska,Petersburg Borough = Wrangell-Petersburg,Alaska 2,280
rep_row = filter(df, county %in% c('Wrangell City and Borough', 'Petersburg Census Area')) %>%
  summarize(state = 'Alaska',
            state_fips = '02',
            county = 'Wrangell-Petersburg',
            county_fips = '280',
            total = sum(total, na.rm = T),
            natural_gas = sum(natural_gas, na.rm = T),
            propane = sum(propane, na.rm = T),
            electricity = sum(electricity, na.rm = T),
            distallate_fuel_oil = sum(distallate_fuel_oil, na.rm = T),
            coal = sum(coal, na.rm = T),
            wood = sum(wood, na.rm = T),
            solar = sum(solar, na.rm = T),
            other = sum(other, na.rm = T),
            none = sum(none, na.rm = T)
  )
df = rbind(df, rep_row)


# Prince of Wales-Hyder Census Area = Prince of Wales-Outer Ketchikan,Alaska 2,201
rep_row = filter(df, county == 'Prince of Wales-Hyder Census Area') %>%
  summarize(state = 'Alaska',
            state_fips = '02',
            county = 'Prince of Wales-Outer Ketchikan',
            county_fips = '201',
            total = sum(total, na.rm = T),
            natural_gas = sum(natural_gas, na.rm = T),
            propane = sum(propane, na.rm = T),
            electricity = sum(electricity, na.rm = T),
            distallate_fuel_oil = sum(distallate_fuel_oil, na.rm = T),
            coal = sum(coal, na.rm = T),
            wood = sum(wood, na.rm = T),
            solar = sum(solar, na.rm = T),
            other = sum(other, na.rm = T),
            none = sum(none, na.rm = T)
  )
df = rbind(df, rep_row)

# drop the old rows
df = filter(df, !(county %in% c('Prince of Wales-Hyder Census Area', 'Wrangell City and Borough', 'Petersburg Census Area',  'Hoonah-Angoon Census Area', 'Skagway Municipality')))

# check count
nrow(df)
# 3141

# rename a couple columns
remap = list(
  'distallate_fuel_oil' = 'distallate fuel oil',
  'natural_gas' = 'natural gas'
)

for (n in names(remap)){
  i = which(names(df) == n)
  names(df)[i] = remap[[n]]
}

# melt the df
dfm = melt(df, id.vars = c("state", "state_fips", "county", "county_fips"), variable.name = 'fuel_type', value.name = 'housing_units')

# write to postgres
sql = "SET ROLE 'diffusion-writers';"
dbSendQuery(conn, sql)
dbWriteTable(conn, c('diffusion_shared', 'acs_2013_county_housing_units_by_fuel_type'),  dfm, row.names = F, overwrite = T)

# add the county_id
sql = "ALTER TABLE diffusion_shared.acs_2013_county_housing_units_by_fuel_type
       ADD county_id INTEGER;
      
       UPDATE diffusion_shared.acs_2013_county_housing_units_by_fuel_type a
       SET county_id = b.county_id
       FROM diffusion_shared.county_geom b
       where a.state_fips = lpad(b.state_fips::TEXT, 2, '0')
       and a.county_fips = b.county_fips;
"
dbSendQuery(conn, sql)

# make fuel type + county_id primary key
sql = "ALTER TABLE diffusion_shared.acs_2013_county_housing_units_by_fuel_type
       ADD PRIMARY KEY (county_id, fuel_type);"
dbSendQuery(conn, sql)

# add indices
sql = "CREATE INDEX acs_2013_county_housing_units_by_fuel_type_btree_county_id
        ON  diffusion_shared.acs_2013_county_housing_units_by_fuel_type
        USING BTREE(county_id); 
        
        CREATE INDEX acs_2013_county_housing_units_by_fuel_type_btree_fuel_type
        ON  diffusion_shared.acs_2013_county_housing_units_by_fuel_type
        USING BTREE(fuel_type);"
dbSendQuery(conn, sql)



