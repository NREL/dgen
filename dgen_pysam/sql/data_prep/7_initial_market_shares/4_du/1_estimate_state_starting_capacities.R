library(stringr)
library(reshape2)
library(ggplot2)
library(RPostgreSQL)
library(dplyr)

################################################################################################################################################
drv <- dbDriver("PostgreSQL")
# connect to postgres
con <- dbConnect(drv, host="gispgdb.nrel.gov", dbname="dav-gis", user="mgleason", password="mgleason")

sql = "SET ROLE 'diffusion-writers';"
dbSendQuery(con, sql)

# cumulative US installations  (as of 2012) by sector
df = read.csv('/Volumes/Staff/mgleason/dGeo/Data/Source_Data/du_existing_market_share/Geo Installations Database 2015-12-31.csv')
# drop columns after 43
df = df[, 1:43]
# drop other columns we don't need
cols = c('State', 
         'Spa..Pool', 
         'Aqua.culture', 
         'District.Heating', 
         'Space.Heating', 
         'Green.House', 
         'Dehydration', 
         'Irrigation', 
         'Other', 
         'Other...Description', 
         'Capacity.1',  # MWt
         'Energy.Use.1', # GWh/yr
         'Status.of.Project'
)
df = df[, cols]

# rename columns to lower case
names(df) = tolower(names(df))

# rename capacity field
names(df)[which(names(df) == 'capacity.1')] = 'capacity_mw'
names(df)[which(names(df) == 'energy.use.1')] = 'generation_gwh_per_year'

# filter our rows that status = closed
df = filter(df, status.of.project != 'closed')

# also filter out rows with unknown capacity
df = filter(df, !is.na(capacity_mw))

# recode the "other" uses
cat(as.character(unique(df$other...description)), sep = '\n')
# Reptile Park
# Snow Melting
# Algae Production
# Industrial
# Laundry

df$reptilepark = ifelse(df$other == 1 & df$other...description == 'Reptile Park', 1, NA)
df$snowmelting = ifelse(df$other == 1 & df$other...description == 'Snow Melting', 1, NA)
df$algaeproduction = ifelse(df$other == 1 & df$other...description == 'Algae Production', 1, NA)
df$industrial = ifelse(df$other == 1 & df$other...description == 'Industrial', 1, NA)
df$laundry = ifelse(df$other == 1 & df$other...description == 'Laundry', 1, NA)


# now apportion the percent of uses by sector (com, res, ind, ag)
cat(names(df), sep = '\n')

res_uses = c('district.heating',
             'space.heating')

com_uses = c('district.heating', 
             'spa..pool', 
             'laundry', 
             'snowmelting', 
             'space.heating', 
             'reptilepark')

ag_uses = c('aqua.culture', 
            'algaeproduction', 
            'irrigation', 
            'green.house')

ind_uses = c('industrial',
             'dehydration')

df$count_res = rowSums(df[, res_uses], na.rm = T)
df$count_com = rowSums(df[, com_uses], na.rm = T)
df$count_ag = rowSums(df[, ag_uses], na.rm = T)
df$count_ind = rowSums(df[, ind_uses], na.rm = T)

df$count_all = rowSums(df[, c('count_res', 'count_com', 'count_ag', 'count_ind')], na.rm = T)

# recalculate weights for each sector
df$wt_res = df$count_res / df$count_all
df$wt_com = df$count_com / df$count_all
df$wt_ag = df$count_ag / df$count_all
df$wt_ind = df$count_ind / df$count_all

# make sure wt sums always = 1
unique(rowSums(df[, c('wt_res', 'wt_com', 'wt_ind', 'wt_ag')])) == 1
# TRUE -- all set

# disaggregate the capacity to each class
df$cap_mw_res = df$wt_res * df$capacity_mw
df$cap_mw_com = df$wt_com * df$capacity_mw
df$cap_mw_ag = df$wt_ag * df$capacity_mw
df$cap_mw_ind = df$wt_ind * df$capacity_mw

# same with energy
df$gen_gwh_res = df$wt_res * df$generation_gwh_per_year
df$gen_gwh_com = df$wt_com * df$generation_gwh_per_year
df$gen_gwh_ag = df$wt_ag * df$generation_gwh_per_year
df$gen_gwh_ind = df$wt_ind * df$generation_gwh_per_year


# sum up capacities and generation to states
dfg = group_by(df, state) %>%
  summarize(
      cap_mw_res = sum(cap_mw_res, na.rm = T),
      cap_mw_com = sum(cap_mw_com, na.rm = T),
      cap_mw_ind = sum(cap_mw_ind, na.rm = T),
      cap_mw_agr = sum(cap_mw_ag, na.rm = T),
      gen_gwh_res = sum(gen_gwh_res, na.rm = T),
      gen_gwh_com = sum(gen_gwh_com, na.rm = T),
      gen_gwh_agr = sum(gen_gwh_ag, na.rm = T),
      gen_gwh_ind = sum(gen_gwh_ind, na.rm = T)
  )

# melt
dfm = melt(dfg, id.vars = 'state')
dfm$measure = substring(dfm$variable, 1, 3)
dfm$sector_abbr = str_sub(dfm$variable, start = -3)

# filter out the two pieces
gen = filter(dfm[, c('state', 'sector_abbr', 'value', 'measure')], measure == 'gen')
names(gen)[3] = 'generation_gwh'
cap = filter(dfm[, c('state', 'sector_abbr', 'value', 'measure')], measure == 'cap')
names(cap)[3] = 'capacity_mw'

m = merge(gen[, c(1, 2, 3)], cap[, c(1, 2, 3)], by = c('state', 'sector_abbr'))
# drop rows with zero cap and gen
m = filter(m, generation_gwh > 0 | capacity_mw > 0)

# rename state column
names(m)[1] = 'state_abbr'


# QAQC -- do the sums match the original sums?
q = group_by(m, state_abbr) %>%
    summarize(generation_gwh = sum(generation_gwh),
              capacity_mw = sum(capacity_mw))

# origin table
o = group_by(df, state) %>%
  summarize(generation_gwh = sum(generation_gwh_per_year),
            capacity_mw = sum(capacity_mw))

qo = merge(q, o, by.x = 'state_abbr', by.y = 'state')
max(qo$generation_gwh.x - qo$generation_gwh.y)
max(qo$capacity_mw.x - qo$capacity_mw.y)
# 0 and 0 -- all set

# write results to postgres
dbWriteTable(con, c('diffusion_geo', 'starting_capacities_2004_du'), m, row.names = F, overwrite = T)


