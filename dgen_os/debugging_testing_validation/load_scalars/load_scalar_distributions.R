library(RPostgreSQL)
library(ggplot2)
library(dplyr)


#############################################
# CONNECT TO POSTGRES
drv = dbDriver("PostgreSQL") 
conn = dbConnect(drv, host='dnpdb001.bigde.nrel.gov', port=5433, dbname='dgen_db', user='mgleason', password='mgleason') 
#############################################

sql = "   select load_kwh_per_customer_in_bin, ann_cons_kwh, 'res' as sector_abbr, state_abbr
        	from diffusion_results_intensity_factors.pt_res_best_option_each_year_solar
        	UNION ALL
          select load_kwh_per_customer_in_bin, ann_cons_kwh, 'com' as sector_abbr, state_abbr
        	from diffusion_results_intensity_factors.pt_com_best_option_each_year_solar
        	UNION ALL
        	select load_kwh_per_customer_in_bin, ann_cons_kwh, 'ind' as sector_abbr, state_abbr
        	from diffusion_results_intensity_factors.pt_ind_best_option_each_year_solar;"
df = dbGetQuery(conn, sql)

df = mutate(df, load_scalar = load_kwh_per_customer_in_bin/ann_cons_kwh) %>% filter(state_abbr == 'CA')
df_rescom = filter(df, sector_abbr != 'ind')

ggplot(data = df_rescom) +
  geom_histogram(aes(x = load_scalar)) +
  facet_wrap(~ sector_abbr, scales = 'free') +
  xlim(0, 2)

ggplot(data = df_rescom) +
  geom_boxplot(aes(x = sector_abbr, y = load_scalar)) +
  facet_wrap(~ sector_abbr, scales = 'free') +  
  ylim(0, 2)


sf = group_by(df, sector_abbr) %>%
  summarize(avg = mean(load_scalar),
            sd = sd(load_scalar),
            med = median(load_scalar),
            q75 = quantile(load_scalar, .75),
            q25 = quantile(load_scalar, .25))



sql = "select county_id, total_load_mwh_2011_residential as load_mwh, total_customers_2011_residential as customers, 'res' as sector_abbr
      from diffusion_shared.load_and_customers_by_county_us
      UNION ALL
      select county_id, total_load_mwh_2011_commercial as load_mwh, total_customers_2011_commercial as customers, 'com' as sector_abbr
      from diffusion_shared.load_and_customers_by_county_us
      UNION ALL
      select county_id, total_load_mwh_2011_industrial as load_mwh, total_customers_2011_industrial as customers, 'ind' as sector_abbr
      from diffusion_shared.load_and_customers_by_county_us"
load_df = dbGetQuery(conn, sql)

load_df = mutate(avg_load, avg_load = load_mwh/customers)

ggplot(data = load_df) +
  geom_boxplot(aes(x = sector_abbr, y = avg_load)) +
  facet_wrap(~ sector_abbr, scales = 'free') +  
  ylim(0, 2)



s_load = group_by(load_df, sector_abbr) %>%
  summarize(avg = mean(avg_load, na.rm = T),
            sd = sd(avg_load, na.rm = T),
            med = median(avg_load, na.rm = T),
            q75 = quantile(avg_load, .75, na.rm = T),
            q25 = quantile(avg_load, .25, na.rm = T))


sf_ann_cons = group_by(df, sector_abbr) %>%
  summarize(avg = mean(ann_cons_kwh/1000),
            sd = sd(ann_cons_kwh/1000),
            med = median(ann_cons_kwh/1000),
            q75 = quantile(ann_cons_kwh/1000, .75),
            q25 = quantile(ann_cons_kwh/1000, .25))


sf_allocated = group_by(df, sector_abbr) %>%
  summarize(avg = mean(load_kwh_per_customer_in_bin/1000),
            sd = sd(load_kwh_per_customer_in_bin/1000),
            med = median(load_kwh_per_customer_in_bin/1000),
            q75 = quantile(load_kwh_per_customer_in_bin/1000, .75),
            q25 = quantile(load_kwh_per_customer_in_bin/1000, .25))
