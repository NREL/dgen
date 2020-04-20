library(dplyr)
# CO
# dfb = read.csv('/Users/mgleason/NREL_Projects/github/diffusion/runs/results_benchmark/BAU/solar/outputs_solar.csv.gz')
# dfc = read.csv('/Users/mgleason/NREL_Projects/github/diffusion/runs/archive/results_benchmark_blocks_commercial_customers/BAU/solar/outputs_solar.csv.gz')

# NY
dfb = read.csv('/Users/mgleason/NREL_Projects/github/diffusion/runs/archive/results_ny_switch_to_commercial_bldgs/BAU/solar/outputs_solar.csv.gz')
dfc = read.csv('/Users/mgleason/NREL_Projects/github/diffusion/runs/archive/results_ny_complex_rates_blocks/BAU/solar/outputs_solar.csv.gz')



# cat(names(dfb), sep = '\n')

dfbc = filter(dfb, sector == 'commercial' & year == 2014)
dfcc = filter(dfc, sector == 'commercial' & year == 2014)

dfbc$sqft_roof_occupied = 1/dfbc$density_w_per_sqft * dfbc$system_size_kw*1000
dfbc$pct_roof_occupied = dfbc$sqft_roof_occupied/dfbc$available_roof_sqft


dfcc$sqft_roof_occupied = 1/dfcc$density_w_per_sqft * dfcc$system_size_kw*1000
dfcc$pct_roof_occupied = dfcc$sqft_roof_occupied/dfcc$available_roof_sqft

sum(dfcc$pct_roof_occupied >= .99)/nrow(dfcc) # 46%
sum(dfbc$pct_roof_occupied >= .99)/nrow(dfbc) # 75%

dfbc$pct_load_satisfied = dfbc$aep/dfbc$load_kwh_per_customer_in_bin
dfcc$pct_load_satisfied = dfcc$aep/dfcc$load_kwh_per_customer_in_bin

sum(dfcc$pct_load_satisfied >= .94)/nrow(dfcc) # 54%
sum(dfbc$pct_load_satisfied >= .94)/nrow(dfbc) # 25%


# deployment change
sum(filter(dfb, sector == 'commercial' & year == 2024)$installed_capacity)/sum(filter(dfc, sector == 'commercial' & year == 2024)$installed_capacity)
sum(filter(dfb, year == 2024)$installed_capacity)/sum(filter(dfc, year == 2024)$installed_capacity)

