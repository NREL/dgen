library(RPostgreSQL)


####################################################################################
# connect to postgres
drv = dbDriver("PostgreSQL") 
conn = dbConnect(drv, host='gispgdb.nrel.gov', port=5432, dbname='dav-gis', user='mgleason', password='mgleason') 
####################################################################################

sql = "SET ROLE 'eia-writers';"
dbSendQuery(conn, sql)

setwd('/Volumes/Staff/mgleason/DG_Wind/Data/Source_Data/EIA/EIA_microdata/CBECS_2003')

for (i in c('01','02','15','16')){
  # load the data to postgres
  cbecs = read.csv(sprintf('FILE%s.csv', i))
  names(cbecs) = tolower(names(cbecs))
  out_table = sprintf('cbecs_2003_microdata_file_%s',i)
  dbWriteTable(conn, c('eia', out_table), cbecs, overwrite = T, row.names = F)
  
  # add comment on table to indicate source
  sql = sprintf("COMMENT ON TABLE eia.%s IS
              'Source: http://www.eia.gov/consumption/commercial/data/2003/index.cfm?view=microdata, File %s. 
               Data dictionary available at: http://www.eia.gov/consumption/commercial/data/2003/pdf/layouts&formats.pdf';", out_table, i)
  dbSendQuery(conn, sql)

  # add column descriptions
  dict = read.csv(sprintf('dictionary_file%s.csv', i), stringsAsFactors = F)
  for (r in 1:nrow(dict)){
    col = dict$col[r]
    desc = dict$desc[r]
    sql = sprintf("COMMENT ON COLUMN eia.%s.%s IS '%s';", out_table, col, desc)
    dbSendQuery(conn, sql)    
  }

  # add primary key
  sql = sprintf("ALTER TABLE eia.%s ADD PRIMARY KEY (pubid8);", out_table)
  dbSendQuery(conn, sql)     
}



