library(dplyr)
library(RPostgreSQL)
library(reshape2)
library(ggplot2)

drv <- dbDriver("PostgreSQL")
# connect to postgres
con <- dbConnect(drv, host="gispgdb.nrel.gov", dbname="dav-gis", user="mgleason", password="mgleason")

# source units for tc are W/m-K -- convert to BTU/hr-ft-F for consistency with Xiaobing
# conversion factor found here: http://web.mit.edu/2.51/www/data.html
sql = "SELECT state_abbr, sitethermalconductivity/1.7307 as tc
        FROM diffusion_geo.smu_thermal_conductivity_cores
        WHERE state_abbr IS NOT NULL
        AND sitethermalconductivity IS NOT NULL;"
df = dbGetQuery(con, sql)


ggplot(data = df) +
  geom_histogram(aes(x = tc)) +
  facet_wrap(~state_abbr, scales = 'free')

# assume distribution is normal
r = group_by(df, state_abbr) %>%
         summarize(lmin = log(min(tc)),
                   lmax = log(max(tc)),
                   min = min(tc),
                   max = max(tc),
                   mean = mean(tc),
                   median = median(tc),
                   count = sum(!is.na(tc))
                   )
r$lmid = r$lmin + (r$lmax - r$lmin)/2
r$lsd2 = (r$lmax - r$lmin)/2
r$lsd = r$lsd2/2
r = data.frame(r)
# calculate the quantiles
r$q25 = qlnorm(0.25, r$lmid, r$lsd)
r$q50 = qlnorm(0.5, r$lmid, r$lsd)
r$q75 = qlnorm(0.75, r$lmid, r$lsd)
# round all values to 4 places
r[, 2:ncol(r)] = round(r[, 2:ncol(r)], 4)
plot(r$median ~ r$q50)

# check method for simulating a distribution using lmid and lsd
for (abbr in unique(df$state_abbr)){
  sf = filter(df, state_abbr == abbr)
  rf = filter(r, state_abbr == abbr)
  x =  rlnorm(1000, meanlog = rf$lmid[1], sdlog = rf$lsd[1])
  x2 = sf$tc
  dx = data.frame(tc = x, type = 'sim')
  dx2 = data.frame(tc = x2, type = 'obs')
  dxc = rbind(dx, dx2)
  g = ggplot(data = dxc)+
    geom_histogram(aes(x = tc)) +
    facet_wrap( ~ type, nrow = 2, ncol = 1)
  outf = sprintf('/Volumes/Staff/mgleason/dGeo/Graphics/smu_thermal_conducivity_distributions/%s.png', abbr)
  ggsave(outf, g, width = 4, height = 7, units = 'in')
}

# results look pretty solid

# return the r dataframe to postgres -- this will satisfy our thermal conductivity ranges for the model
sql = "SET ROLE 'diffusion-writers';"
dbSendQuery(con, sql)

dbWriteTable(con, c('diffusion_geo', 'thermal_conductivity_summary_by_state'), r, row.names = F, overwrite = T)


# also dump to csv
cols = c('state_abbr', 'min', 'max', 'mean', 'median', 'count', 'q25', 'q50', 'q75')
write.csv(r[, cols], '/Volumes/Staff/mgleason/dGeo/Graphics/smu_thermal_conducivity_distributions/summaries.csv', row.names = F)



