library(RPostgreSQL)
library(reshape2)
library(dplyr)
library(ggplot2)

drv = dbDriver("PostgreSQL") 
conn = dbConnect(drv, host='gispgdb.nrel.gov', port=5432, dbname='dav-gis', user='mgleason', password='mgleason')


wres = read.csv('/Volumes/Staff/mgleason/dGeo/Data/Source_Data/EIA_Heating_Oil_Prices/simplified/residential.csv', check.names = F)
wresm = melt(wres, id.vars = c('date'), variable.name = 'region', value.name = 'dlrs_per_gal')
wresm$date = as.Date(as.character(wresm$date), format = "%d-%b-%y")

wresm$year = format(wresm$date, '%Y')
resm =  filter(wresm, region == 'U.S.') %>%
        group_by(year) %>%
        summarize(dlrs_per_gal_res = mean(dlrs_per_gal, na.rm = T))


############################################################################################################
sql = "SELECT year, region, dlrs_per_gal, sector_abbr
       FROM eia.avg_no2_fuel_oil_price_by_region_by_sector_1978_2010
        WHERE region_type = 'state';"
df = dbGetQuery(conn, sql)

m = merge(df, resm, by = c('year'), )

ggplot(data = m) +
  geom_point(aes(x = dlrs_per_gal, y = dlrs_per_gal_res, colour = sector_abbr))

# filter

mod = lm(m$dlrs_per_gal ~ m$dlrs_per_gal_res + m$region + m$sector_abbr + m$year)
summary(mod)
hist(mod$residuals)

plot(mod$residuals  ~ mod$model$'m$dlrs_per_gal_res')


plot(mod$fitted.values ~ mod$model$'m$year')
plot(mod$model$'m$dlrs_per_gal' ~ mod$model$'m$year')

