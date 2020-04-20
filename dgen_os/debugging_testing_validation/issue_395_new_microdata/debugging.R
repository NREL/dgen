# 
# dir = '/Users/mgleason/NREL_Projects/github/diffusion/runs/microdata_comparison/new_microdata'
# 
# scenarios = c('eight', 'five', 'four', 'nine', 'one', 'seven', 'six', 'ten', 'three', 'two')
# for (scenario in scenarios){
#   fpath = sprintf('%s/%s/wind/outputs.csv.gz', dir, scenario)
#   df = read.csv(fpath)
#   print(scenario)
#   print(unique(filter(df, new_adopters > 100)$micro_id))
#   
# #   g = ggplot(data = df) +
# #     geom_line(aes(x = year, y = new_adopters, colour = as.factor(micro_id)))
# #   print(g)
# }
# 
# 
# 
# scenarios = c('eight', 'five', 'four', 'nine', 'one', 'seven', 'six', 'ten', 'three', 'two')
# for (scenario in scenarios){
#   fpath = sprintf('%s/%s/wind/outputs.csv.gz', dir, scenario)
#   df = read.csv(fpath)
#   ff = filter(df, year == 2030)
#   g = ggplot(data = ff) +
#         geom_point(aes(x = initial_number_of_adopters, y = new_adopters)) +
#         ggtitle( scenario)
#   print(g)
# }
# 
# scenarios = c('eight', 'five', 'four', 'nine', 'one', 'seven', 'six', 'ten', 'three', 'two')
# for (scenario in scenarios){
#   fpath = sprintf('%s/%s/wind/outputs.csv.gz', dir, scenario)
#   df = read.csv(fpath)
#   ff = filter(df, year == 2030)
#   g = ggplot(data = ff) +
#     geom_point(aes(x = cf_bin, y = new_adopters)) +
#     ggtitle( scenario)
#   print(g)
# }
# 
# 
# scenarios = c('eight', 'five', 'four', 'nine', 'one', 'seven', 'six', 'ten', 'three', 'two')
# for (scenario in scenarios){
#   fpath = sprintf('%s/%s/wind/outputs.csv.gz', dir, scenario)
#   df = read.csv(fpath)
# #   ff = filter(df, year == 2030)
#   g = ggplot(data = df) +
#     geom_point(aes(x = turbine_id, y = new_adopters)) +
#     ggtitle( scenario)
#   print(g)
# }
# 
# g = ggplot(data = df) +
#   geom_point(aes(x = turbine_id, y = naep, colour = cf_bin)) +
#   ggtitle( scenario)
# 
# 
# g = ggplot(data = df) +
#   geom_point(aes(x = turbine_height_m, y = naep, colour = turbine_id)) +
#   ggtitle( scenario)
# 
# 
# 
# 
# 
# 
# 
# dir = '/Users/mgleason/NREL_Projects/github/diffusion/runs/microdata_comparison/new_microdata'
# scenarios = c('eight', 'five', 'four', 'nine', 'one', 'seven', 'six', 'ten', 'three', 'two')
# for (scenario in scenarios){
#   fpath = sprintf('%s/%s/wind/outputs.csv.gz', dir, scenario)
#   df = read.csv(fpath)
#   ff = filter(df, year == 2030) %>%
#        mutate(spike = new_adopters > 100)
#   g = ggplot(data = ff) +
#     geom_boxplot(aes(x = spike, y = load_kwh_per_customer_in_bin)) +
# #     facet_wrap(~spike) + 
#     ggtitle( scenario)
#   print(g)
# }
# 


library(reshape2)
library(ggplot2)
library(dplyr)

dir = '/Users/mgleason/NREL_Projects/github/diffusion/runs/microdata_comparison'
scenarios = c('eight', 'five', 'four', 'nine', 'one', 'seven', 'six', 'ten', 'three', 'two')

big_diffusers_list = list()
i = 1
for (scenario in scenarios){
  fpath = sprintf('%s/new_microdata/%s/wind/outputs.csv.gz', dir, scenario)
  df = read.csv(fpath)
  ff = filter(df, year == 2030 & new_adopters > 100) %>% 
    mutate(src = 'new')
  big_diffusers_list[[i]] = ff
  i = i +1
  
  fpath = sprintf('%s/old_microdata/%s/wind/outputs.csv.gz', dir, scenario)
  df = read.csv(fpath)
  ff = filter(df, year == 2030 & new_adopters > 100) %>% 
    mutate(src = 'old')
  big_diffusers_list[[i]] = ff
  
  i = i +1
}

library(reshape2)
big_diffusers = do.call('rbind', big_diffusers_list)
big_melt = melt(big_diffusers[,c("src", "ic", "lcoe", "max_market_share", "new_market_share", "first_year_bill_with_system", "first_year_bill_without_system", "npv4", "excess_generation_percent", "total_value_of_incentives", "incentive_array_id", "ranked_rate_array_id", "fixed_om_dollars_per_kw_per_yr", "variable_om_dollars_per_kwh", "installed_costs_dollars_per_kw", "customers_in_bin", "load_kwh_per_customer_in_bin", "rate_id_alias", "naep", "aep", "system_size_kw", "turbine_id", "cf_bin", "turbine_height_m", "cost_of_elec_dols_per_kwh", "initial_market_share", "initial_number_of_adopters", "initial_capacity_mw")], id.vars = c('src'))

ggplot(data = big_melt) +
  geom_boxplot(aes(x = src, y = value)) + 
  facet_wrap(~variable, scales = 'free')

#filter(big_diffusers, initial_number_of_adopters > 200)$micro_id
#318040 311281

#filter(big_diffusers, initial_number_of_adopters > 200)$cf_bin
#39 39



dir = '/Users/mgleason/NREL_Projects/github/diffusion/runs/microdata_comparison'
scenarios = c('eight', 'five', 'four', 'nine', 'one', 'seven', 'six', 'ten', 'three', 'two')

big_starters_list = list()
i = 1
for (scenario in scenarios){
  fpath = sprintf('%s/new_microdata/%s/wind/outputs.csv.gz', dir, scenario)
  df = read.csv(fpath)
  ff = filter(df, year == 2014 & initial_number_of_adopters > 200) %>% 
    mutate(src = 'new')
  big_starters_list[[i]] = ff
  i = i +1
  
  fpath = sprintf('%s/old_microdata/%s/wind/outputs.csv.gz', dir, scenario)
  df = read.csv(fpath)
  ff = filter(df, year == 2014 & initial_number_of_adopters > 200) %>% 
    mutate(src = 'old')
  big_starters_list[[i]] = ff
  
  i = i +1
}

big_starters = do.call('rbind', big_starters_list)
# filter(big_diffusers, initial_number_of_adopters > 200)


big_filter = filter(big_starters, cf_bin > 24)


#318040 311281
