library(RPostgreSQL)
library(ggplot2)
library(dplyr)


#############################################
# CONNECT TO POSTGRES
drv = dbDriver("PostgreSQL") 
conn = dbConnect(drv, host='dnpdb001.bigde.nrel.gov', port=5433, dbname='dgen_db', user='mgleason', password='mgleason') 
#############################################

sql = "SELECT *
       FROM diffusion_results_2015_10_15_15h25m30s.outputs_all;"
x = dbGetQuery(conn, sql)

# flat rates
# diffusion_results_2015_10_13_20h12m22s

# When system swize limits are turned off, 
# sys_sector         avg avg_wt_new_adopters avg_wt_customers     med
# 1  bignonres 5780.445741         5527.890512      1346.483742 3660.80
# 2     nonres   74.973931           74.173233        39.293325   27.59
# 3        res    4.502319            4.390429         4.070698    3.72
# 4.5/.9 = 5 (0.9 is the avg load scalar for CA res )
# so, a combination of the load scalars + tech potential limits 
# could account for smaller than expected system sizing for res

# nonres and big nonres are actually pretty aligned
# with actual sizing when you account for the lidar tech potential limits
# and turn off the bad rates
# TO DO: look into whether any cities in CA have particularly low tech potential limits?
# try to fix the load scalars for residential?
# fix crappy rate data?



# weighted averages should be by market_share
# because number of adopters  = market share * number of customers in bin
# and number of customers in bin is going to be higher for less exceptional
# load users (we initialize market share the same for all counties in each state)
mutate(x, sys_sector = ifelse(sector == 'residential', 'res', ifelse(system_size_kw < 500, 'nonres', 'bignonres'))) %>%
  mutate(adopted = new_adopters > 0) %>%
  filter(year == 2014) %>%
  group_by(sys_sector) %>%
  summarize(avg = mean(system_size_kw),
            avg_wt_new_adopters = sum(system_size_kw * market_share)/sum(market_share),
            avg_wt_customers = sum(system_size_kw * customers_in_bin)/sum(customers_in_bin),
            med = median(system_size_kw)
            )

mutate(x, sys_sector = ifelse(sector == 'residential', 'res', ifelse(system_size_kw < 500, 'nonres', 'bignonres'))) %>%
  mutate(adopted = new_adopters > 0) %>%
  filter(year == 2014) %>%
  filter(ur_enable_net_metering == 't') %>%
  group_by(sys_sector) %>%
  summarize(avg = mean(system_size_kw),
            avg_wt_new_adopters = sum(system_size_kw * new_adopters)/sum(new_adopters),
            avg_wt_customers = sum(system_size_kw * customers_in_bin)/sum(customers_in_bin),
            med = median(system_size_kw)
  )


y = filter(x, year == 2014) %>%
    mutate(adopted = new_adopters > 0) %>%
    mutate(sys_sector = ifelse(sector == 'residential', 'res', ifelse(system_size_kw < 500, 'nonres', 'bignonres'))) %>%
    select(system_size_kw, adopted, sys_sector, load_kwh_per_customer_in_bin)

ggplot(data = y) +
  geom_histogram(aes(x = system_size_kw, fill = adopted)) +
  facet_wrap(~ sys_sector, scales = 'free')


ggplot(data = y) +
  geom_point(aes(x = load_kwh_per_customer_in_bin, y = system_size_kw, colour = adopted)) +
  facet_wrap(~ sys_sector, scales = 'free')




z = filter(f, year == 2014) %>%
  mutate(adopted = new_adopters > 0) %>%
  mutate(sys_sector = ifelse(sector == 'residential', 'res', ifelse(system_size_kw < 500, 'nonres', 'bignonres'))) %>%
  mutate(offset_ratio = aep/load_kwh_per_customer_in_bin)



ggplot(data = z) +
  geom_boxplot(aes(x = adopted, y = load_kwh_per_customer_in_bin)) +
  facet_wrap( ~ sys_sector, scales = 'free')


ggplot(data = z) +
  geom_boxplot(aes(x = adopted, y = first_year_bill_without_system), outlier.shape = NA) +
  facet_wrap(~ sys_sector, scales = 'free') +
  coord_cartesian(ylim = c(0, 1e5)) # for nonres
# bills for adopters tend to be higher without system


ggplot(data = z) +
  geom_boxplot(aes(x = adopted, y = first_year_bill_with_system), outlier.shape = NA) +
  facet_wrap(~ sys_sector, scales = 'free') +
  coord_cartesian(ylim = c(0, 100000)) # for nonres

ggplot(data = z) +
  geom_boxplot(aes(x = adopted, y = total_value_of_incentives), outlier.shape = NA) +
  facet_wrap(~ sys_sector, scales = 'free') +
# value of incentives actually tends to line up very well -- no differences betrween adopters and non
  
ggplot(data = z) +
  geom_boxplot(aes(x = adopted, y = total_value_of_incentives/ic), outlier.shape = NA) +
  facet_wrap(~ sys_sector, scales = 'free')  +
  coord_cartesian(ylim = c(0, .4)) # for nonres
# but, value of incentives as a percent of installed costs tends to be higher for adoptrs

ggplot(data = z) +
  geom_boxplot(aes(x = adopted, y = cf), outlier.shape = NA) +
  facet_wrap(~ sys_sector, scales = 'free') 
# cf is higher for adopters in nonres and big nonres, but not res??

ggplot(data = z) +
  geom_boxplot(aes(x = adopted, y = max_demand_kw), outlier.shape = NA) +
  facet_wrap(~ sys_sector, scales = 'free') +
  coord_cartesian(ylim = c(0, 4000)) # for nonres
# max_demand_kw is higher for big and regular nonres adopters


# makes sense since load is also higher for big and regular nonrs adopters
ggplot(data = z) +
  geom_boxplot(aes(x = adopted, y = load_kwh_per_customer_in_bin), outlier.shape = NA) +
  facet_wrap( ~ sys_sector, scales = 'free') +
  coord_cartesian(ylim = c(0, 1e7)) # for nonres
# for non res, the contributing factors so far are:
  # load
  # max demand
  # first year bill
  # cf


ggplot(data = z) +
  geom_boxplot(aes(x = adopted, y = cost_of_elec_dols_per_kwh), outlier.shape = NA) +
  facet_wrap( ~ sys_sector, scales = 'free') +
  coord_cartesian(ylim = c(0, .4)) 
# for res, it appears to be rates!!


ggplot(data = z) +
  geom_boxplot(aes(x = adopted, y = first_year_bill_without_system-first_year_bill_with_system), outlier.shape = NA) +
  facet_wrap( ~ sys_sector, scales = 'free') +
  coord_cartesian(ylim = c(0, 1e7)) 

ggplot(data = z) +
  geom_bar(aes(x = as.factor(z$rate_id_alias), fill = adopted), stat = 'bin', position = 'dodge') +
  facet_wrap( ~ sys_sector, scales = 'free')


rates = z %>% filter(adopted == T) %>%
  group_by(rate_id_alias, sys_sector) %>%
  summarize(count = sum(adopted == T))

ggplot(data = rates) +
  geom_bar(aes(x = as.factor(rates$rate_id_alias), y = count), stat = 'identity', position = 'dodge') +
  facet_wrap( ~ sys_sector, scales = 'free')

filter(rates, count > 500)

# ggplot(data = z) +
#   geom_histogram(aes(x = offset_ratio, fill = adopted)) +
#   facet_wrap(~ sys_sector, scales = 'free')
# 
# ggplot(data = z) +
#   geom_boxplot(aes(x = adopted, y = load_kwh_per_customer_in_bin)) +
#   facet_wrap( ~ sys_sector, scales = 'free')
# 
# a = filter(z, offset_ratio < 0.02) %>%
#      filter(sys_sector != 'res') %>%
#      filter(adopted == T)
# 
# 
# ggplot(data = z) +
#   geom_point(aes(x = offset_ratio, y = npv4, colour = adopted)) +
#   facet_wrap(~ sys_sector, scales = 'free') +



