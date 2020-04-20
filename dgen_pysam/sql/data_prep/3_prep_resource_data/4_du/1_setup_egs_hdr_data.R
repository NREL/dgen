library(dplyr)
library(reshape2)
library(ggplot2)
library(RPostgreSQL)
library(gstat)
library(sp)
library(ggthemes)
library(grid)
library(scales)
library(fitdistrplus)

################################################################################################
# CONNECT TO PG
drv <- dbDriver("PostgreSQL")
# connect to postgres
con <- dbConnect(drv, host="gispgdb.nrel.gov", dbname="dav-gis", user="mgleason", password="mgleason")

sql = "SET ROLE 'dgeo-writers';"
dbSendQuery(con, sql)

################################################################################################


sql = "SELECT gid,
ci95_500 as ci95,
t_500,
t_1000,
t_1500,
t_2000,
t_2500,
t_3000  
FROM dgeo.egs_temp_at_depth_all_update"
df = dbGetQuery(con, sql)

dfm = melt(df, id.vars = c('gid', 'ci95'), value.name = 't_deg_c_mean')
dfm$depth_km = as.numeric(substring(dfm$variable, 3, 6))/1000.
dfm$t_deg_c_sd = dfm$ci95/2

# assign thicknesses
dfm$thickness_km = 0.5
dfm[dfm$depth_km == .5, 'thickness_m'] = 0.45 # 500 m slice only runs from 300 - 750 m

# subset to the columns of interest
out_cols = c('gid', 't_deg_c_mean', 'depth_km', 't_deg_c_sd', 'thickness_km')
dfm_out = dfm[, out_cols]
# change postgres role
sql = "SET ROLE 'diffusion-writers';"
dbSendQuery(con, sql)

# write results to postgres
dbWriteTable(con, c('diffusion_geo', 'egs_hdr_temperature_at_depth'), dfm_out, row.names = F, overwrite = T)

# add primary key
sql = "ALTER TABLE diffusion_geo.egs_hdr_temperature_at_depth
      ADD PRIMARY KEY (gid, depth_km);"
dbSendQuery(con, sql)

# add index on gid
sql = "CREATE INDEX egs_hdr_temperature_at_depth_btree_gid
      ON diffusion_geo.egs_hdr_temperature_at_depth
      USING BTREE(gid);"
dbSendQuery(con, sql)

# change column types
sql = "ALTER TABLE diffusion_geo.egs_hdr_temperature_at_depth
      ALTER COLUMN t_deg_c_mean TYPE NUMERIC USING t_deg_c_mean::NUMERIC;"
dbSendQuery(con, sql)

sql = "ALTER TABLE diffusion_geo.egs_hdr_temperature_at_depth
      ALTER COLUMN t_deg_c_sd TYPE NUMERIC USING t_deg_c_sd::NUMERIC;"
dbSendQuery(con, sql)

sql = "ALTER TABLE diffusion_geo.egs_hdr_temperature_at_depth
      ALTER COLUMN depth_km TYPE NUMERIC USING depth_km::NUMERIC;"
dbSendQuery(con, sql)

sql = "ALTER TABLE diffusion_geo.egs_hdr_temperature_at_depth
      ALTER COLUMN thickness_km TYPE NUMERIC USING thickness_km::NUMERIC;"
dbSendQuery(con, sql)




# create new table
# simulate temp (use rlnorm and rnorm)
#  change any temperatures that are outside of focus range (30-150) to zero
# dfm[dfm$t < 30, 't'] = 0
# dfm[dfm$t > 150, 't'] = 0

# for each year:
# calculate extractable resource (from input recovery factor)
# calculate number of wells (from reservoir area and input area per wellset)
# calculate extractable resource per well


