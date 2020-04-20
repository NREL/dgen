library(RPostgreSQL)
library(reshape2)
drv = dbDriver("PostgreSQL") 
conn = dbConnect(drv, host='gispgdb.nrel.gov', port=5432, dbname='dav-gis', user='mgleason', password='mgleason')

res = read.csv('/Volumes/Staff/mgleason/dGeo/Data/Source_Data/EIA_Natural_Gas_Prices/simplified/residential.csv', check.names = F)
com = read.csv('/Volumes/Staff/mgleason/dGeo/Data/Source_Data/EIA_Natural_Gas_Prices/simplified/commercial.csv', check.names = F)
ind = read.csv('/Volumes/Staff/mgleason/dGeo/Data/Source_Data/EIA_Natural_Gas_Prices/simplified/industrial.csv', check.names = F)

resm = melt(res, id.vars = c('year'), variable.name = 'state', value.name = 'dlrs_per_mcf')
comm = melt(com, id.vars = c('year'), variable.name = 'state', value.name = 'dlrs_per_mcf')
indm = melt(ind, id.vars = c('year'), variable.name = 'state', value.name = 'dlrs_per_mcf')

resm$sector = 'residential'
comm$sector = 'commercial'
indm$sector = 'industrial'

dfm = rbind(resm, comm, indm)
dfm$sector_abbr = substring(dfm$sector, 1, 3)

dfm$cents_per_ccf = dfm$dlrs_per_mcf/10*100


sql = "SET ROLE 'eia-writers';"
dbSendQuery(conn, sql)
dbWriteTable(conn, c('eia', 'avg_ng_price_by_state_by_sector_1967_2014'),  dfm, row.names = F, overwrite = T)

sql = "COMMENT ON TABLE eia.avg_ng_price_by_state_by_sector_1967_2014 IS 
      'Sources: https://www.eia.gov/dnav/ng/ng_pri_sum_a_EPG0_PIN_DMcf_a.htm
      https://www.eia.gov/dnav/ng/ng_pri_sum_a_EPG0_PCS_DMcf_a.htm
      https://www.eia.gov/dnav/ng/ng_pri_sum_a_EPG0_PRS_DMcf_a.htm';"
dbSendQuery(conn, sql)

# add primary key
sql = "ALTER TABLE eia.avg_ng_price_by_state_by_sector_1967_2014 ADD PRIMARY KEY (year, state, sector_abbr);"
dbSendQuery(conn, sql)

