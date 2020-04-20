library(dplyr)
library(reshape2)
library(ggplot2)
library(RPostgreSQL)
library(tseries)
library(forecast)

################################################################################################################################################
drv <- dbDriver("PostgreSQL")
# connect to postgres
#con <- dbConnect(drv, host="gispgdb.nrel.gov", dbname="dav-gis", user="mgleason", password="mgleason")

sql = "SET ROLE 'diffusion-writers';"
dbSendQuery(con, sql)

################################################################################################################################################

sql = "SELECT state_fips,
  state,
  census_division,
  census_division_abbr,
  year,
  scenario,
  state_abbr,
  housing_starts_single_family_millions as hu_starts_singlefam,
  housing_starts_multi_family_millions as hu_starts_multifam,
	commercial_sq_ft_billions as com_sqft
FROM diffusion_shared.aeo_new_building_projections_2015
order by year"
df = dbGetQuery(con, sql)

# Get lists of Scenerios and States
scenario <- unique(df$scenario)
states <- unique(df$state_abbr)

# Empty DF to store results
datalist1 = list()

# Loop Through Scenarios
for (p in 1:length(scenario))
  {
  df2 <- df[df$scenario == scenario[p], ]

  datalist2 = list()

  # Loop Through States
  for (i in 1:length(states))
    {
    st_df = df2[df2$state_abbr == states[i],]
    hu_ts_s = ts(st_df$hu_starts_singlefam, start = 2012, end = 2040)
    hu_ts_m = ts(st_df$hu_starts_multifam, start = 2012, end = 2040)
    sf_ts = ts(st_df$com_sqft, start = 2012, end = 2040)


    m_hu_s = auto.arima(hu_ts_s, seasonal = F, stationary = F)
    m_hu_m = auto.arima(hu_ts_m, seasonal = F, stationary = F)
    m_sf = auto.arima(sf_ts, seasonal = F, stationary = F, allowdrift = F)

    # test for residuals independence
    #plot(m_hu_s$residuals, type = 'p')
    Box.test(m_hu_s$residuals, type = 'Ljung')
    hu_s_pred = forecast(m_hu_s, h = 10)
    #plot(hu_s_pred)

    #plot(m_hu_m$residuals, type = 'p')
    Box.test(m_hu_m$residuals, type = 'Ljung')
    hu_m_pred = forecast(m_hu_m, h = 10)
    #plot(hu_m_pred)

    #plot(m_sf$residuals, type = 'p')
    Box.test(m_sf$residuals, type = 'Ljung')
    sf_pred = forecast(m_sf, h =10)
    #plot(sf_pred)

    # to convert back to a dataframe
    sf_pred_vals = sf_pred$mean
    hu_s_pred_vals = hu_s_pred$mean
    hu_m_pred_vals = hu_m_pred$mean

    state_fips = df2$state_fips

    results = data.frame(state_fips = rep(st_df$state_fips[1], 10), state = rep(st_df$state[1],10), census_division = rep(st_df$census_division[1], 10), year = 2041:2050, scenario = rep(st_df$scenario[1],10), housing_starts_single_family_millions = as.numeric(hu_s_pred_vals), housing_starts_multi_family_millions = as.numeric(hu_m_pred_vals), commercial_sq_ft_billions = as.numeric(sf_pred_vals), state_abbr = rep(states[i], 10), census_division_abbr = rep(st_df$census_division_abbr[1], 10))
    print (results)

    datalist2[[i]] <- results
  }
  print (datalist2)
  scenario.results <- dplyr::bind_rows(datalist2)
  datalist1[[p]] <- scenario.results
}
all.results <- dplyr::bind_rows(datalist1)
print (all.results)

# Save output to CSV
write.csv(all.results, file = '/Volumes/Staff/mgleason/dGeo/Data/Source_Data/EIA_NewBuilds_HousingStarts_ComFloospace/ts_project_to_2050.csv')


