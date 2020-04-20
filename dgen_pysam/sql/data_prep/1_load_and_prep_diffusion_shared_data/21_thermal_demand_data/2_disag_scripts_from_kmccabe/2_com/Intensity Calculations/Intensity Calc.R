library(RPostgreSQL)

drv = dbDriver("PostgreSQL") 
conn = dbConnect(drv, host='gispgdb.nrel.gov', port=5432, dbname='dav-gis', user='kmccabe', password='kmccabe')

sql = 'SELECT  a.pubid8, a.region8, a.cendiv8, a.sqft8, a.pba8, a.pbaplus8, a.adjwt8, 
                b.mfhtbtu8, b.mfwtbtu8, b.mfclbtu8
      FROM eia.cbecs_2003_microdata_file_02 a
      LEFT JOIN eia.cbecs_2003_microdata_file_17 b
      ON a.pubid8 = b.pubid8;'
df = dbGetQuery(conn,sql)

pba_cdms_lkup = read.csv('/Users/kmccabe/Documents/R/Commercial Analysis/Intensity Calculations/PBA-CDMS Crosswalk.csv', stringsAsFactors = F)
names(pba_cdms_lkup)[2] = 'pbaplus8'
CDMS_order = c("com1","com2","com3","com4","com5","com6",
         "com7","com8_9","com10","edu1","edu2",
         "gov1","gov2","rel1","res4","res5","res6")
cens_div = c("New England","Middle Atlantic","East North Central","West North Central","South Atlantic",
             "East South Central","West South Central","Mountain","Pacific")

m = merge(df, pba_cdms_lkup, by = c('pbaplus8'))
m$spht_tot = m$adjwt8 * m$mfhtbtu8
m$wtht_tot = m$adjwt8 * m$mfwtbtu8
m$cool_tot = m$adjwt8 * m$mfclbtu8
m$area_tot = m$adjwt8 * m$sqft8

spht_region_cdms = group_by(m, cendiv8, CDMS) %>%
  summarize(spht_region_cdms = sum(spht_tot, na.rm=T))
wtht_region_cdms = group_by(m, cendiv8, CDMS) %>%
  summarize(wtht_region_cdms = sum(wtht_tot, na.rm=T))
cool_region_cdms = group_by(m, cendiv8, CDMS) %>%
  summarize(cool_region_cdms = sum(cool_tot, na.rm=T))
area_region_cdms = group_by(m, cendiv8, CDMS) %>%
  summarize(area_region_cdms = sum(area_tot, na.rm=T))

sp_temp = merge(spht_region_cdms, area_region_cdms, by = c('cendiv8', 'CDMS'))
sp_temp$sp_int = sp_temp$spht_region_cdms/sp_temp$area_region_cdms
sp_temp$spht_region_cdms = NULL
sp_temp$area_region_cdms = NULL
wt_temp = merge(wtht_region_cdms, area_region_cdms, by = c('cendiv8', 'CDMS'))
wt_temp$wt_int = wt_temp$wtht_region_cdms/wt_temp$area_region_cdms
wt_temp$wtht_region_cdms = NULL
wt_temp$area_region_cdms = NULL
cl_temp = merge(cool_region_cdms, area_region_cdms, by = c('cendiv8', 'CDMS'))
cl_temp$cl_int = cl_temp$cool_region_cdms/cl_temp$area_region_cdms
cl_temp$cool_region_cdms = NULL
cl_temp$area_region_cdms = NULL

spht_int = dcast(sp_temp, CDMS ~ cendiv8, value.var = 'sp_int')
spht_int$CDMS = tolower(spht_int$CDMS)
temp = spht_int[2,]
spht_int = spht_int[-2,]
spht_int = rbind(spht_int[1:8,], temp, spht_int[9:16,])
spht_int$CDMS = NULL

wtht_int = dcast(wt_temp, CDMS ~ cendiv8, value.var = 'wt_int')
wtht_int$CDMS = tolower(wtht_int$CDMS)
temp = wtht_int[2,]
wtht_int = wtht_int[-2,]
wtht_int = rbind(wtht_int[1:8,], temp, wtht_int[9:16,])
wtht_int$CDMS = NULL

cool_int = dcast(cl_temp, CDMS ~ cendiv8, value.var = 'cl_int')
cool_int$CDMS = tolower(cool_int$CDMS)
temp = cool_int[2,]
cool_int = cool_int[-2,]
cool_int = rbind(cool_int[1:8,], temp, cool_int[9:16,])
cool_int$CDMS = NULL

dimnames(spht_int) = list(CDMS_order,cens_div)
dimnames(wtht_int) = list(CDMS_order,cens_div)
dimnames(cool_int) = list(CDMS_order,cens_div)

# For zero entries, take average of surrounding census divisions
# ---------------------------------------------------------------
# New England replaced w/ Middle Atlantic and East North Central
spht_int[3,1] = (spht_int[3,2] + spht_int[3,3]) / 2
wtht_int[3,1] = (wtht_int[3,2] + wtht_int[3,3]) / 2
cool_int[3,1] = (cool_int[3,2] + cool_int[3,3]) / 2
# Mountain replaced w/ West North Central, West South Central, and Pacific
wtht_int[5,8] = (wtht_int[5,4] + wtht_int[5,7] + wtht_int[5,9]) / 3

# write.csv(spht_int, 'spht_intensity.csv')
# write.csv(wtht_int, 'wtht_intensity.csv')
# write.csv(cool_int, 'cool_intensity.csv')