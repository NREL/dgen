library(RPostgreSQL)
library(reshape2)
drv = dbDriver("PostgreSQL") 
conn = dbConnect(drv, host='gispgdb.nrel.gov', port=5432, dbname='dav-gis', user='mgleason', password='mgleason')

res = read.csv('/Volumes/Staff/mgleason/dGeo/Data/Source_Data/EIA_Fuel_Oil_No2/simplified/residential.csv', check.names = F)
com = read.csv('/Volumes/Staff/mgleason/dGeo/Data/Source_Data/EIA_Fuel_Oil_No2/simplified/commercial.csv', check.names = F)
ind = read.csv('/Volumes/Staff/mgleason/dGeo/Data/Source_Data/EIA_Fuel_Oil_No2/simplified/industrial.csv', check.names = F)

resm = melt(res, id.vars = c('year'), variable.name = 'region', value.name = 'dlrs_per_gal')
comm = melt(com, id.vars = c('year'), variable.name = 'region', value.name = 'dlrs_per_gal')
indm = melt(ind, id.vars = c('year'), variable.name = 'region', value.name = 'dlrs_per_gal')

# label sectors
resm$sector = 'residential'
comm$sector = 'commercial'
indm$sector = 'industrial'

# rbind the sectors to a single df
dfm = rbind(resm, comm, indm)
dfm$sector_abbr = substring(dfm$sector, 1, 3)

dfm$cents_per_gal = dfm$dlrs_per_gal*100

# label region type
dfm$region = as.character(dfm$region)

unique(dfm$region)

dfm$region_type = ifelse(dfm$region %in% c("East Coast (PADD 1)", "New England (PADD 1A)", "Central Atlantic (PADD 1B)", 
                                             "Lower Atlantic (PADD 1C)", "Midwest (PADD 2)", "Gulf Coast (PADD 3)",
                                             "Rocky Mountain (PADD 4)", "West Coast (PADD 5)"
                                             ), 'padd', 'state')

dfm$region_type = ifelse(dfm$region == 'U.S.', 'nation', dfm$region_type)

# check results
unique(dfm[dfm$region_type == 'nation', 'region'])
unique(dfm[dfm$region_type == 'padd', 'region'])
unique(dfm[dfm$region_type == 'state', 'region'])


sql = "SET ROLE 'eia-writers';"
dbSendQuery(conn, sql)
dbWriteTable(conn, c('eia', 'avg_no2_fuel_oil_price_by_region_by_sector_1978_2010'),  dfm, row.names = F, overwrite = T)

sql = "COMMENT ON TABLE eia.avg_no2_fuel_oil_price_by_region_by_sector_1978_2010 IS 
      'Sources: https://www.eia.gov/dnav/pet/pet_pri_dist_a_EPD2_pin_dpgal_a.htm
https://www.eia.gov/dnav/pet/pet_pri_dist_a_EPD2_PCS_dpgal_a.htm
https://www.eia.gov/dnav/pet/pet_pri_dist_a_EPD2_PRT_dpgal_a.htm';"
dbSendQuery(conn, sql)

# add primary key
sql = "ALTER TABLE eia.avg_no2_fuel_oil_price_by_region_by_sector_1978_2010 ADD PRIMARY KEY (year, region, sector_abbr);"
dbSendQuery(conn, sql)



########################################################################
library(dplyr)
library(ggplot2)
# filter out non-state data
df = filter(dfm, region_type == 'state') %>%
     select(year, region, dlrs_per_gal, sector_abbr)
dfw = dcast(df, year + region ~ sector_abbr, value.var = 'dlrs_per_gal')
names(dfw)[2] = 'state'

ggplot(data = df) +
  geom_point(aes(x = year, y = dlrs_per_gal, colour = sector_abbr))

ggplot(data = dfw) +
  geom_point(aes(x = res, y = com, colour = region))

ggplot(data = dfw) +
  geom_point(aes(x = res, y = ind, colour = region))


mcom = lm(dfw$com ~ dfw$res + dfw$region)
summary(mcom)
hist(mcom$residuals)
plot(mcom$residuals)

mind = lm(dfw$ind ~ dfw$res + dfw$region)
summary(mind)
hist(mind$residuals)
plot(mind$residuals)
