#Automate calculation of when NEM expires

library(dplyr)
library(tidyr)

## Read and format data
# The Freeing the grid (ftg) data is very messy, so we only want a few columns. I manually pre-formated the max_fraction_demand column, the max fraction of load
# that can be supplied by DERs before NEM cap is breached. Note we are also assuming that only PV is contributing towards cap. 
#If there is no limit specified, then 1e40 is used as the fraction
#Some states specify a MW cap, which is listed as an integer
#Some states assess the cap as a % of annual energy (cap_based_on_energy)
# So any value [0,1] is interpreted as a percent

peak_demand = read.csv("peak_demand_111115.csv",header = T,stringsAsFactors = F) %>%
  gather(., year, peak_demand_mw, - state) %>%
  mutate(year = substr(year,2,5))

current_nem_policies = read.csv("current_nem_policies_060616.csv",header = T,stringsAsFactors = F) %>%
  select(state, max_fraction_demand, cap_based_on_energy)

lmn = read.csv('lmn.csv',header = T,stringsAsFactors = F)

ts_lkup = read.csv('ts_lkup.csv', header = T,stringsAsFactors = F)

region_lkup = unique(read.csv('region_lkup.csv', header = T,stringsAsFactors = F))

cf_data = read.csv('cf_by_time_slice_pca_and_year.csv', header = T, stringsAsFactors = F)

installed_capacity_mw_by_state = read.csv("installed_cap_060616.csv",header = T, stringsAsFactors = F)

## Supporting calculations
# Calculate total retail energy consumed (MWh) by state and year
total_state_energy = merge(lmn, ts_lkup) %>%
  merge(.,region_lkup) %>%
  group_by(state, year) %>%
  summarise(annual_mwh = sum(value * hours))%>%
  as.data.frame(.)

# Calculate weighted mean cf by state 
cf_data %>%
  merge(.,region_lkup) %>%
  group_by(state,ts) %>%
  summarize(cf = mean(cf)) %>% #Average over pca-specific cf
  merge(.,ts_lkup) %>%
  group_by(state) %>%
  summarise(cf = weighted.mean(cf,hours)) # Use hours per ts to determine annual cf

# Read the scenario data
installed_capacity_mw_by_state %>%
  gather(., year, installed_cap_mw, - state) %>%
  mutate(year = substr(year,2,5)) %>%
  merge(.,cf_data) %>%
  mutate(annual_mwh_generated = cf * installed_cap_mw * 8760) %>%
  merge(.,total_state_energy)

## Calulate whether the cap was reached in any given year
# Merge the peak demand and current nem policies file to determine the amount of DER capacity required to breach cap in any given year, then convert to peak generation with cf_data
df = current_nem_policies %>%
  merge(., peak_demand) %>%
  mutate(mw_needed_to_breach_cap = peak_demand_mw * max_fraction_demand)

# Overwrite limits when stated as MW (>1 MW)
df[1<df$max_fraction_demand & df$max_fraction_demand<1e40,'mw_needed_to_breach_cap']  = df[1<df$max_fraction_demand & df$max_fraction_demand<1e40,'max_fraction_demand']

# Merge the scenario data, and determine the year the cap is breached!
df = merge(df, installed_capacity_mw_by_state, by = c('state','year')) %>%
  mutate(energy_needed = max_fraction_demand * annual_mwh) %>%
  mutate(cap_breached = ifelse(cap_based_on_energy == 0, installed_cap_mw > mw_needed_to_breach_cap, annual_mwh_generated > energy_needed)) # Assess via demand or energy

## Loop over years to determine first year cap was reached
out = data.frame('state' = c(),'year' = c(), stringsAsFactors = F)
for(stat in unique(df$state)){
  tmp = filter(df, state == stat) %>%
    arrange(year)
  out2 = data.frame('state' = stat, 'year' = as.numeric(tmp[min(which(tmp$cap_breached == TRUE)),'year'])) # Find the first year cap is breached
  out = rbind(out, out2)}

out[is.na(out$year),'year'] = 2050 # If it's never breached, use 2050

# Some misc edits based an analyst judgement
out[out$state == 'NV','year'] = 2015

## Write results
write.csv(out,'projected_nem_expiration_dates.csv')
