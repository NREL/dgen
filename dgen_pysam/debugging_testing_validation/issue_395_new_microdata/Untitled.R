new = read.csv('/Users/mgleason/NREL_Projects/github/diffusion/runs/results_20150904_161713/BAU/wind/outputs.csv.gz')
new2 = read.csv('/Users/mgleason/NREL_Projects/github/diffusion/runs/results_20150904_163102/BAU/wind/outputs.csv.gz')
old = read.csv('/Users/mgleason/NREL_Projects/github/diffusion/runs/db_md_benchmark_separate_microdata/BAU/wind/outputs.csv.gz')

nrow(new)
nrow(old)

ncol(new)
ncol(old)

names(new)

# load is identical
hist(new$load_kwh_per_customer_in_bin)
hist(old$load_kwh_per_customer_in_bin)

hist(new$initial_capacity_mw)
hist(old$initial_capacity_mw)

hist(new$cf_bin)
hist(old$cf_bin)

plot(load_kwh_per_customer_in_bin ~ cf_bin, data = new2)
plot(load_kwh_per_customer_in_bin ~ cf_bin, data = new)
plot(load_kwh_per_customer_in_bin ~ cf_bin, data = old)

hist(new$max_market_share)
max(new$max_market_share)
max(old$max_market_share)
max(new2$max_market_share)

library(dplyr)
new_max = filter(new, npv4 > 0)
new_max2 = filter(new2, npv4 > 0)
old_max = filter(old, npv4 > 0)

hist(new_max$max_market_share)
hist(old_max$max_market_share)

plot(max_market_share ~ initial_customers_in_bin, data = new_max)
plot(max_market_share ~ initial_customers_in_bin, data = new_max2)
plot(max_market_share ~ initial_customers_in_bin, data = old_max)

hist(new$initial_customers_in_bin)
hist(new2$initial_customers_in_bin)
hist(old$initial_customers_in_bin)

plot(cf_bin ~ initial_customers_in_bin, data = new_max)
plot(cf_bin ~ initial_customers_in_bin, data = new_max2)
plot(cf_bin ~ initial_customers_in_bin, data = old_max)

plot(cf_bin ~ initial_customers_in_bin, data = new)

plot(cf_bin ~ initial_customers_in_bin, data = new_max2, main = 'new2')
plot(cf_bin ~ initial_customers_in_bin, data = old_max, main = 'old')


plot(npv4 ~ initial_customers_in_bin, data = new_max2, main = 'new2')
plot(npv4 ~ initial_customers_in_bin, data = new_max, main = 'new')
plot(npv4 ~ initial_customers_in_bin, data = old_max, main = 'old')


hist(new_max$cf_bin)
hist(new_max2$cf_bin)
hist(old_max$cf_bin)

plot(npv4 ~ total_value_of_incentives, data = new_max2)
plot(npv4 ~ total_value_of_incentives, data = new_max)
plot(npv4 ~ total_value_of_incentives, data = old_max)

plot(max_market_share ~ total_value_of_incentives, data = new_max2)
plot(max_market_share ~ total_value_of_incentives, data = new_max)
plot(max_market_share ~ total_value_of_incentives, data = old_max)

hist(filter(new, year == 2026)$new_adopters)
hist(filter(new, year == 2026)$new_adopters)

library(ggplot2)
ggplot(data = new) +
  geom_line(aes(x = year, y = new_adopters, colour = as.factor(micro_id)))

unique(filter(new, new_adopters > 500)$micro_id)
# 318040

ggplot(data = new2) +
  geom_line(aes(x = year, y = new_adopters, colour = as.factor(micro_id)))

unique(filter(new2, new_adopters > 500)$micro_id)
# 390627


ggplot(data = old) +
  geom_line(aes(x = year, y = new_adopters, colour = as.factor(micro_id)))

unique(filter(old, new_adopters > 200)$micro_id)
# 402843



new_bin = filter(new, micro_id == 318040)
new2_bin = filter(new2, micro_id == 390627)
old_bin = filter(old, micro_id == 402843)

plot(max_market_share ~ new_adopters, data = new)
plot(max_market_share ~ new_adopters, data = old)

plot(incentive_array_id ~ new_adopters, data = new)
plot(incentive_array_id ~ new_adopters, data = old)

plot(cf_bin ~ max_market_share, data = new)
plot(cf_bin ~ max_market_share, data = old)

# cf_bin seems to be important
plot(cf_bin ~ max_market_share, data = new)
plot(cf_bin ~ max_market_share, data = new2)
plot(cf_bin ~ max_market_share, data = old)
# highest max market shares are assocaited with high cf bin

# cost of elec doesn't seem solely responsible
plot(cost_of_elec_dols_per_kwh ~ max_market_share, data = new)
plot(cost_of_elec_dols_per_kwh ~ max_market_share, data = new2)
plot(cost_of_elec_dols_per_kwh ~ max_market_share, data = old)

plot(initial_customers_in_bin ~ max_market_share, data = new)
plot(initial_customers_in_bin ~ max_market_share, data = new2)
plot(initial_customers_in_bin ~ max_market_share, data = old)

plot(customers_in_bin ~ max_market_share, data = new)
plot(customers_in_bin ~ max_market_share, data = new2)
plot(customers_in_bin ~ max_market_share, data = old)

plot(system_size_kw ~ max_market_share, data = new, ylim = c(0,100))
plot(system_size_kw ~ max_market_share, data = new2, ylim = c(0,100))
plot(system_size_kw ~ max_market_share, data = old, ylim = c(0,100))


# the differences in final CA installed capacity can be accounted for in just these
# three bins
max(new_bin$installed_capacity)
max(new2_bin$installed_capacity)
max(old$installed_capacity)

# all have similar economics and resources, as well as varying customers_in_bin

# however, the main difference seems to be the number_of_adopters_last_year
# and installed_capacity_last_year 
# for the old case, the initial isntalled capacity starts very low (34 kw)
# vs 100-700 for the new cases

new_bin$initial_market_share
new2_bin$initial_market_share
old_bin$initial_market_share
# initial market share lines up very well across all three, so the proportions are similar

new_bin$initial_number_of_adopters
new2_bin$initial_number_of_adopters
old_bin$initial_number_of_adopters
# these differ significantly

new_bin$initial_capacity_mw
new2_bin$initial_capacity_mw
old_bin$initial_capacity_mw


new_bin$initial_customers_in_bin
new2_bin$initial_customers_in_bin
old_bin$initial_customers_in_bin

new_bin$initial_load_kwh_in_bin
new2_bin$initial_load_kwh_in_bin
old_bin$initial_load_kwh_in_bin

