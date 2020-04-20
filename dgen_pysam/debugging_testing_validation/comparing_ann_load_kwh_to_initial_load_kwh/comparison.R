library(dplyr)
dfb = read.csv('/Users/mgleason/NREL_Projects/github/diffusion/runs/results_commercial_buildings_instead_of_customers/BAU/solar/outputs_solar.csv.gz')
dfc = read.csv('/Users/mgleason/NREL_Projects/github/diffusion/runs/results_benchmark_blocks/BAU/solar/outputs_solar.csv.gz')


cat(names(dfb), sep = '\n')

dfbc = filter(dfb, sector == 'commercial' & year == 2014)
dfcc = filter(dfc, sector == 'commercial' & year == 2014)

summary(dfbc$load_kwh_per_customer_in_bin/ dfbc$ann_cons_kwh)
summary(dfcc$load_kwh_per_customer_in_bin / dfcc$ann_cons_kwh)


plot(dfcc$load_kwh_per_customer_in_bin ~ dfcc$ann_cons_kwh)
# abline(a = 0, b = 1)
abline(a = 0, b = 0.166266, col = 'red')
plot(log(dfbc$load_kwh_per_customer_in_bin) ~ log(dfbc$ann_cons_kwh))
abline(a = 0, b = 1)
abline(a = 0, b = 0.51539)

m1 = lm(I(log(dfbc$load_kwh_per_customer_in_bin)) ~ I(log(dfbc$ann_cons_kwh)) + 0)
m2 = lm(I(log(dfcc$load_kwh_per_customer_in_bin)) ~ I(log(dfcc$ann_cons_kwh)) + 0)
summary(m1)
summary(m2)

x = read.csv('/Users/mgleason/NREL_Projects/github/diffusion/runs/results_20160524_110448/BAU/solar/outputs_solar.csv.gz')
x = filter(x, sector == 'commercial' & year == 2014)
summary(x$load_kwh_per_customer_in_bin/ x$ann_cons_kwh)
summary(x$tenant_portion)
