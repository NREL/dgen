library(RPostgreSQL)
library(reshape2)
drv = dbDriver("PostgreSQL") 
conn = dbConnect(drv, host='gispgdb.nrel.gov', port=5432, dbname='dav-gis', user='mgleason', password='mgleason')

sql = "SELECT year, state as state_abbr,
            cents_per_kwh_residential as residential,
          	cents_per_kwh_commercial as commercial,
          	cents_per_kwh_industrial as industrial
          FROM eia.avg_elec_price_by_state_by_provider_1990_2014
          where year = 2014
          and state <> 'US'
          and sales_type = 'Total Electric Industry';"
df = dbGetQuery(conn,sql)

dfm = melt(df, id.vars = c('year', 'state_abbr'), value.name = 'cents_per_kwh', variable.name = 'sector')
dfm$sector_abbr = substring(dfm$sector, 1, 3)

sql = "SET ROLE 'diffusion-writers';"
dbSendQuery(conn, sql)
dbWriteTable(conn, c('diffusion_shared', 'eia_state_avg_elec_prices_2014'),  dfm, row.names = F, overwrite = T)

# add primary key
sql = "ALTER TABLE diffusion_shared.eia_state_avg_elec_prices_2014
      ADD PRIMARY KEY (year, state_abbr, sector_abbr);"
dbSendQuery(conn, sql)

# any nulls
sql = "select *
  FROM diffusion_shared.eia_state_avg_elec_prices_2014
where cents_per_kwh is null;"
check = dbGetQuery(conn, sql)
nrow(check)
# = 0 (all set)