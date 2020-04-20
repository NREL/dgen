library(RPostgreSQL)


####################################################################################
# connect to postgres
drv = dbDriver("PostgreSQL") 
conn = dbConnect(drv, host='gispgdb.nrel.gov', port=5432, dbname='dav-gis', user='mgleason', password='mgleason') 
####################################################################################

sql = "SET ROLE 'eia-writers';"
dbSendQuery(conn, sql)

setwd('/Volumes/Staff/mgleason/DG_Wind/Data/Source_Data/EIA/EIA_microdata/RECS_2009')


# load the data to postgres
recs = read.csv('recs2009_public.csv')
names(recs) = tolower(names(recs))
out_table = 'recs_2009_microdata'
dbWriteTable(conn, c('eia', out_table), recs, overwrite = T, row.names = F)

# add comment on table to indicate source
sql = sprintf("COMMENT ON TABLE eia.%s IS
            'Source: http://www.eia.gov/consumption/residential/data/2009/index.cfm?view=microdata. 
             Data dictionary available at: http://www.eia.gov/consumption/residential/data/2009/xls/recs2009_public_codebook.xlsx';", out_table)
dbSendQuery(conn, sql)

# add column descriptions
dict = read.csv('data_dictionary.csv', stringsAsFactors = F)
dict$desc = gsub("'","",dict$desc)
for (r in 1:nrow(dict)){
  col = dict$col[r]
  desc = dict$desc[r]
  sql = sprintf("COMMENT ON COLUMN eia.%s.%s IS '%s';", out_table, col, desc)
  dbSendQuery(conn, sql)    
}

# add primary key
sql = sprintf("ALTER TABLE eia.%s ADD PRIMARY KEY (doeid);", out_table)
dbSendQuery(conn, sql)     




