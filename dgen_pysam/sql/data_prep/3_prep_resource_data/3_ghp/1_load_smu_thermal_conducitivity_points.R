library(dplyr)
library(RPostgreSQL)
library(reshape2)

drv <- dbDriver("PostgreSQL")
# connect to postgres
con <- dbConnect(drv, host="gispgdb.nrel.gov", dbname="dav-gis", user="mgleason", password="mgleason")

df = read.csv('/Volumes/Staff/mgleason/dGeo/Data/Source_Data/SMU_Borehole_Thermal_Conductivity/core.template_thermalconductivity_materialized.csv', stringsAsFactors = F)

# replace null placeholder values with NA
df[df == 'nil:missing'] = NA
df[df == ""] = NA
df[df == -99999.0] = NA

# change names to lowercase
names(df) = tolower(names(df))

# write to postgres
sql = "SET ROLE 'diffusion-writers';"
dbSendQuery(con, sql)

dbWriteTable(con, c('diffusion_geo', 'smu_thermal_conductivity_cores'), df, row.names = F, overwrite = T)

