library(RPostgreSQL)
library(DBI)

###################################################################################
# change delimiter from fixed width to csv and remove extra columns
files =list.files(path = 'C:/Users/camante/Desktop/Tasks/Mike/May_13_Loading_CBECS_Postgres/CBECS_2003', pattern="dictionary_file", full.names=T, recursive=F)

for (i in c(files)){
  data = read.fwf(i,skip=6,widths=c(15,43,-10,-6), strip.white=TRUE) #Read fixed width file and only keep first two columns
  names(data) <- c("col","desc") #rename columns
  write.table(data, i, sep=",", row.names=FALSE, quote=TRUE) #export to csv
}
  
####################################################################################
# connect to postgres
drv = dbDriver("PostgreSQL") 
conn = dbConnect(drv, host='gispgdb.nrel.gov', port=5432, dbname='dav-gis', user='camante', password='camante') 
####################################################################################

sql = "SET ROLE 'eia-writers';"
dbSendQuery(conn, sql)

setwd('C:/Users/camante/Desktop/Tasks/Mike/May_13_Loading_CBECS_Postgres/CBECS_2003')

for (i in c('01','02','03','04','05','06','07','08','09','10','11','12','13','14','15','16','17','18','19','20')){
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


