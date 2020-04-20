library(RPostgreSQL)
library(reshape2)
library(dplyr)
library(ggplot2)

drv = dbDriver("PostgreSQL") 
conn = dbConnect(drv, host='gispgdb.nrel.gov', port=5432, dbname='dav-gis', user='mgleason', password='mgleason')

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
