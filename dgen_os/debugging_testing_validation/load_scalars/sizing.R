x = read.csv('/Users/mgleason/Desktop/outputs_solar.csv.gz')
library(dplyr)
library(ggplot2)

mutate(x, sys_sector = ifelse(sector == 'residential', 'res', ifelse(system_size_kw < 500, 'nonres', 'bignonres'))) %>%
  mutate(adopted = new_adopters > 0) %>%
  filter(year == 2014) %>%
  group_by(sys_sector, adopted) %>%
  summarize(avg = mean(system_size_kw),
            avg_wt_new_adopters = sum(system_size_kw * new_adopters)/sum(new_adopters),
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




z = filter(x, year == 2014) %>%
  mutate(adopted = new_adopters > 0) %>%
  mutate(sys_sector = ifelse(sector == 'residential', 'res', ifelse(system_size_kw < 500, 'nonres', 'bignonres'))) %>%
  mutate(offset_ratio = aep/load_kwh_per_customer_in_bin) %>%
  select(offset_ratio, adopted, sys_sector, npv4, system_size_kw, load_kwh_per_customer_in_bin, state_abbr)

ggplot(data = z) +
  geom_histogram(aes(x = offset_ratio, fill = adopted)) +
  facet_wrap(~ sys_sector, scales = 'free')

zca = filter(z, state_abbr == 'CA')
ggplot(data = zca) +
  geom_boxplot(aes(x = adopted, y = load_kwh_per_customer_in_bin)) +
  facet_wrap( ~ sys_sector, scales = 'free')

a = filter(z, offset_ratio < 0.02) %>%
     filter(sys_sector != 'res') %>%
     filter(adopted == T)


ggplot(data = z) +
  geom_point(aes(x = offset_ratio, y = npv4, colour = adopted)) +
  facet_wrap(~ sys_sector, scales = 'free') +



