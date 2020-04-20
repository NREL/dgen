library(RPostgreSQL)
library(reshape2)


#############################################
# CONNECT TO POSTGRES
drv = dbDriver("PostgreSQL") 
conn = dbConnect(drv, host='gispgdb', port=5432, dbname='dav-gis', user='mgleason', password='mgleason') 
#############################################

sql = "SELECT *
       FROM diffusion_solar.reeds_solar_resource_by_pca_summary_tidy"
df = dbGetQuery(conn, sql)


df_wide = dcast(df, pca_reg + n_points + tilt + azimuth ~ reeds_time_slice, value.var = 'cf_avg')
names(df_wide) = tolower(names(df_wide))
names(df_wide)[2] = 'npoints'
head(df_wide)

dbWriteTable(conn, c('diffusion_solar', 'reeds_solar_resource_by_pca_summary_wide'), df_wide, overwrite = T, row.names = F)

# add primary key
sql = "ALTER TABLE diffusion_solar.reeds_solar_resource_by_pca_summary_wide
ADD PRIMARY KEY (pca_reg, tilt, azimuth);"
dbSendQuery(conn, sql)

# change owner
sql = 'ALTER TABLE diffusion_solar.reeds_solar_resource_by_pca_summary_wide OWNER TO "diffusion-writers";'
dbSendQuery(conn, sql)




