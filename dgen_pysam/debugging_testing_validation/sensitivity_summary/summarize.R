library(ggplot2)
library(dplyr)

summarize_outputs = function(output_files_list){
  
  output_list = list()
  for (i in 1:length(output_files_list)){
    output = output_files_list[[i]]
    df = read.csv(output)
    tech = unique(df$tech)
    
    if (tech == 'solar'){
      df$turbine_height_m = as.numeric(NA)
    }
    
    sf = group_by(df, year, sector) %>%
      summarize(cap_gw = sum(installed_capacity)/1000/1000,
                systems = sum(number_of_adopters),
                cf = mean(cf),
                rate = mean(cost_of_elec_dols_per_kwh),
                system_size_kw = mean(system_size_kw),
                load = mean(load_kwh_per_customer_in_bin),
                first_year_bill_without_system = mean(first_year_bill_without_system),
                first_year_bill_with_system = mean(first_year_bill_with_system),
                turbine_height_m = mean(turbine_height_m),
                total_value_of_incentives = mean(total_value_of_incentives),
                npv4 = mean(npv4)
                
      ) %>% 
      as.data.frame()
    sf$seed = i
    
    output_list[[i]] = sf
    
  }
  
  all_sf = do.call(rbind, output_list)
  all_sf$seed = as.factor(all_sf$seed)
  
  return(all_sf)
}

# setwd('/Users/mgleason/NREL_Projects/github/diffusion/runs/results_ny_complex_rates_blocks')
setwd('/Volumes/gispgdb.nrel.gov/github/diffusion/runs/results_block_microdata_co_complex_rates_fix')
# setwd('/Volumes/gispgdb.nrel.gov/github/diffusion/runs/results_block_microdata_co_flat_rates_fix')
all_files = list.files(recursive = T)
outputs_wind_blocks = all_files[grepl('*/outputs_wind.csv.gz',all_files)]
outputs_solar_blocks = all_files[grepl('*/outputs_solar.csv.gz',all_files)]
sf_wind_blocks = summarize_outputs(outputs_wind_blocks)
sf_solar_blocks = summarize_outputs(outputs_solar_blocks)

# setwd('/Users/mgleason/NREL_Projects/github/diffusion/runs/results_ny_complex_rates_pts')
setwd('/Users/mgleason/NREL_Projects/github/diffusion/runs/results_point_microdata_sensitivity')
# setwd('/Volumes/gispgdb.nrel.gov/github/diffusion/runs/results_point_microdata_co_flat_rates')
all_files = list.files(recursive = T)
outputs_wind_points = all_files[grepl('*/outputs_wind.csv.gz',all_files)]
outputs_solar_points = all_files[grepl('*/outputs_solar.csv.gz',all_files)]
sf_wind_points = summarize_outputs(outputs_wind_points)
sf_solar_points = summarize_outputs(outputs_solar_points)


ggplot() +
  geom_line(data = sf_wind_points, aes(x = year, y = cap_gw, fill = seed), size = 2, colour = 'gray', stat = 'identity') +
  geom_line(data = sf_wind_blocks, aes(x = year, y = cap_gw, fill = seed), colour = 'black', stat = 'identity') +
  facet_wrap(~sector, scales = 'free')


ggplot() +
  geom_line(data = sf_solar_points, aes(x = year, y = cap_gw, fill = seed), size = 2, colour = 'gray', stat = 'identity') +
  geom_line(data = sf_solar_blocks, aes(x = year, y = cap_gw, fill = seed), colour = 'black', stat = 'identity') +
  facet_wrap(~sector, scales = 'free')


ggplot() +
  geom_boxplot(data = sf_solar_points, aes(x = 1, y = cf)) +
  geom_boxplot(data = sf_solar_blocks, aes(x = 2, y = cf)) +
  facet_wrap(~sector, scales = 'free')
ggplot() +
  geom_boxplot(data = sf_solar_points, aes(x = 1, y = rate)) +
  geom_boxplot(data = sf_solar_blocks, aes(x = 2, y = rate)) +
  facet_wrap(~sector, scales = 'free')
ggplot() +
  geom_boxplot(data = sf_solar_points, aes(x = 1, y = system_size_kw)) +
  geom_boxplot(data = sf_solar_blocks, aes(x = 2, y = system_size_kw)) +
  facet_wrap(~sector, scales = 'free')
ggplot() +
  geom_boxplot(data = sf_solar_points, aes(x = 1, y = load)) +
  geom_boxplot(data = sf_solar_blocks, aes(x = 2, y = load)) +
  facet_wrap(~sector, scales = 'free')
ggplot() +
  geom_boxplot(data = sf_solar_points, aes(x = 1, y = first_year_bill_without_system)) +
  geom_boxplot(data = sf_solar_blocks, aes(x = 2, y = first_year_bill_without_system)) +
  facet_wrap(~sector, scales = 'free')
ggplot() +
  geom_boxplot(data = sf_solar_points, aes(x = 1, y = first_year_bill_with_system)) +
  geom_boxplot(data = sf_solar_blocks, aes(x = 2, y = first_year_bill_with_system)) +
  facet_wrap(~sector, scales = 'free')
ggplot() +
  geom_boxplot(data = sf_solar_points, aes(x = 1, y = total_value_of_incentives)) +
  geom_boxplot(data = sf_solar_blocks, aes(x = 2, y = total_value_of_incentives)) +
  facet_wrap(~sector, scales = 'free')
ggplot() +
  geom_boxplot(data = sf_solar_points, aes(x = 1, y = npv4)) +
  geom_boxplot(data = sf_solar_blocks, aes(x = 2, y = npv4)) +
  facet_wrap(~sector, scales = 'free')






ggplot() +
  geom_boxplot(data = sf_wind_points, aes(x = 1, y = cf)) +
  geom_boxplot(data = sf_wind_blocks, aes(x = 2, y = cf)) +
  facet_wrap(~sector, scales = 'free')
ggplot() +
  geom_boxplot(data = sf_wind_points, aes(x = 1, y = rate)) +
  geom_boxplot(data = sf_wind_blocks, aes(x = 2, y = rate)) +
  facet_wrap(~sector, scales = 'free')
ggplot() +
  geom_boxplot(data = sf_wind_points, aes(x = 1, y = system_size_kw)) +
  geom_boxplot(data = sf_wind_blocks, aes(x = 2, y = system_size_kw)) +
  facet_wrap(~sector, scales = 'free')
ggplot() +
  geom_boxplot(data = sf_wind_points, aes(x = 1, y = load)) +
  geom_boxplot(data = sf_wind_blocks, aes(x = 2, y = load)) +
  facet_wrap(~sector, scales = 'free')
ggplot() +
  geom_boxplot(data = sf_wind_points, aes(x = 1, y = first_year_bill_without_system)) +
  geom_boxplot(data = sf_wind_blocks, aes(x = 2, y = first_year_bill_without_system)) +
  facet_wrap(~sector, scales = 'free')
ggplot() +
  geom_boxplot(data = sf_wind_points, aes(x = 1, y = first_year_bill_with_system)) +
  geom_boxplot(data = sf_wind_blocks, aes(x = 2, y = first_year_bill_with_system)) +
  facet_wrap(~sector, scales = 'free')
ggplot() +
  geom_boxplot(data = sf_wind_points, aes(x = 1, y = turbine_height_m)) +
  geom_boxplot(data = sf_wind_blocks, aes(x = 2, y = turbine_height_m)) +
  facet_wrap(~sector, scales = 'free')
ggplot() +
  geom_boxplot(data = sf_wind_points, aes(x = 1, y = total_value_of_incentives)) +
  geom_boxplot(data = sf_wind_blocks, aes(x = 2, y = total_value_of_incentives)) +
  facet_wrap(~sector, scales = 'free')
ggplot() +
  geom_boxplot(data = sf_wind_points, aes(x = 1, y = npv4)) +
  geom_boxplot(data = sf_wind_blocks, aes(x = 2, y = npv4)) +
  facet_wrap(~sector, scales = 'free')



for (i in 1:10){
  output = outputs_solar_points[i]
  setwd('/Volumes/gispgdb.nrel.gov/github/diffusion/runs/results_block_microdata_co_flat_rates')
  dfp = read.csv(output)
  
  output = outputs_solar_blocks[i]
  setwd('/Volumes/gispgdb.nrel.gov/github/diffusion/runs/results_point_microdata_co_flat_rates')
  dfb = read.csv(output)
  
  summary(filter(dfp, sector == 'residential')$cost_of_elec_dols_per_kwh)
  summary(filter(dfb, sector == 'residential')$cost_of_elec_dols_per_kwh)
  
  # summary(dfp$cost_of_elec_dols_per_kwh)
  # summary(dfb$cost_of_elec_dols_per_kwh)
  
  
  dfp_hi = filter(dfp, sector == 'residential' & cost_of_elec_dols_per_kwh > .5)
  dfb_hi = filter(dfb, sector == 'residential' & cost_of_elec_dols_per_kwh > .5)
  
  # dfp_hi = filter(dfp, cost_of_elec_dols_per_kwh > 1)
  # dfb_hi = filter(dfb, cost_of_elec_dols_per_kwh > 1)
  
  print(i)
  print(unique(dfp_hi$rate_id_alias))
  print(unique(dfb_hi$rate_id_alias))
  print('\n')
  
}







