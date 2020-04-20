library(dplyr)
library(RPostgreSQL)
library(reshape2)
library(ggplot2)

drv <- dbDriver("PostgreSQL")
# connect to postgres
con <- dbConnect(drv, host="gispgdb.nrel.gov", dbname="dav-gis", user="mgleason", password="mgleason")

# set role
sql = "SET ROLE 'diffusion-writers';"
dbSendQuery(con, sql)

# source units for tc are W/m-K -- convert to BTU/hr-ft-F for consistency with Xiaobing
# conversion factor found here: http://web.mit.edu/2.51/www/data.html
sql = "SELECT climate_zone, temperature_zone, physio_division, physio_province, sitethermalconductivity/1.7307 as tc
        FROM diffusion_geo.smu_thermal_conductivity_cores
        WHERE climate_zone IS NOT NULL
        AND physio_province IS NOT NULL
        AND sitethermalconductivity IS NOT NULL;"
df = dbGetQuery(con, sql)


setwd('/Volumes/Staff/mgleason/dGeo/Graphics/smu_thermal_conducivity_distributions')

png('boxplots_temperature_zones.png', height = 500, width = 500, units = 'px')
g = ggplot(data = df) +
  geom_boxplot(aes(x = as.factor(temperature_zone), y = tc)) +
  coord_cartesian(ylim = c(0, 3)) +
  xlab('Temperature Zone') +
  ylab('Thermal Conducitivity (BTU/hr-ft-F)')
g
dev.off()
g
# ggsave('boxplots_temperature_zones.png', height = 4, width = 5, units = 'in')

png('boxplots_physio_divisions.png', height = 500, width = 500, units = 'px')
g = ggplot(data = df) +
  geom_boxplot(aes(x = as.factor(physio_division), y = tc)) +
  coord_cartesian(ylim = c(0, 3)) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  xlab('Physiographic Division') +
  ylab('Thermal Conducitivity (BTU/hr-ft-F)')
g
dev.off()
g
# ggsave('boxplots_physio_divisions.png', height = 4, width = 5, units = 'in')

png('boxplots_climate_zones.png', height = 500, width = 500, units = 'px')
g = ggplot(data = df) +
  geom_boxplot(aes(x = as.factor(climate_zone), y = tc)) +
  coord_cartesian(ylim = c(0, 3)) +
  xlab('Climate Zone') +
  ylab('Thermal Conducitivity (BTU/hr-ft-F)')
g
dev.off()
g
# ggsave('boxplots_climate_zones.png', height = 4, width = 5, units = 'in')

png('boxplots_physio_provinces.png', height = 500, width = 500, units = 'px')
g = ggplot(data = df) +
  geom_boxplot(aes(x = as.factor(physio_province), y = tc)) +
  coord_cartesian(ylim = c(0, 3)) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  xlab('Physiographic Province') +
  ylab('Thermal Conducitivity (BTU/hr-ft-F)')
g
# ggsave('boxplots_physio_provinces.png', height = 8, width = 7, units = 'in')
dev.off()
g

####################################################################################################################################
## create summary table for climate zones
# summarize quartiles
rcz = group_by(df, climate_zone) %>%
         summarize(q25 = quantile(tc, 0.25),
                   q50 = median(tc),
                   q75 = quantile(tc, 0.75),
                   count = sum(!is.na(tc))
                   )
rcz = data.frame(rcz)
# round all values to 4 places
rcz[, 2:ncol(rcz)] = round(rcz[, 2:ncol(rcz)], 4)

# return the r dataframe to postgres -- this will satisfy our thermal conductivity ranges for the model
dbWriteTable(con, c('diffusion_geo', 'thermal_conductivity_summary_by_climate_zone'), rcz, row.names = F, overwrite = T)

# also dump to csv
write.csv(rcz, '/Volumes/Staff/mgleason/dGeo/Graphics/smu_thermal_conducivity_distributions/climate_zone_summaries.csv', row.names = F)
####################################################################################################################################
## create summary table for physio divisions
## create summary table for climate zones
# summarize quartiles
rph = group_by(df, physio_division) %>%
  summarize(q25 = quantile(tc, 0.25),
            q50 = median(tc),
            q75 = quantile(tc, 0.75),
            count = sum(!is.na(tc))
  )
rph = data.frame(rph)
# round all values to 4 places
rph[, 2:ncol(rph)] = round(rph[, 2:ncol(rph)], 4)

# return the r dataframe to postgres -- this will satisfy our thermal conductivity ranges for the model
dbWriteTable(con, c('diffusion_geo', 'thermal_conductivity_summary_by_physio_division'), rph, row.names = F, overwrite = T)

# also dump to csv
write.csv(rph, '/Volumes/Staff/mgleason/dGeo/Graphics/smu_thermal_conducivity_distributions/physio_division_summaries.csv', row.names = F)



