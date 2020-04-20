library(dplyr)
library(ggplot2)
aeo_df = read.csv('/Volumes/Staff/mgleason/dGeo/Data/Source_Data/EIA_NewBuilds_HousingStarts_ComFloospace/data_for_converting_to_scalars/aeo_new_building_projections_2015.csv')
census_df = read.csv('/Volumes/Staff/mgleason/dGeo/Data/Source_Data/EIA_NewBuilds_HousingStarts_ComFloospace/data_for_converting_to_scalars/nhgis0038_ds191_20125_2012_state.csv')




# --------------------------------------------------------------------------------
# RESIDENTIAL
# --------------------------------------------------------------------------------
# process into totals for multifamily and singlefamily
cat(names(census_df), sep = '\n')
multifamily = c('QYYE004', 'QYYE005', 'QYYE006', 'QYYE007', 'QYYE008', 'QYYE009')
singlefamily = c('QYYE002', 'QYYE003')

census_df_simple = census_df[, c('STATE', 'STATEA')]
census_df_simple$multifamily_baseline = rowSums(census_df[, multifamily])
census_df_simple$singlefamily_baseline = rowSums(census_df[, singlefamily])
# rename columns and simplify further
census_df_simple = mutate(census_df_simple, state_fips = STATEA) %>%
                   select(state_fips, multifamily_baseline, singlefamily_baseline)
# merge to aeo df
res_df = merge(aeo_df, census_df_simple, by = 'state_fips')
# check for negative values in the housing starts
sum(res_df$housing_starts_single_family_millions < 0) # 0
sum(res_df$housing_starts_multi_family_millions < 0) # 0
# all set!

# sum up into biannual data
keep_years = seq(2012, 2050, 2)
res_df = arrange(res_df,state_abbr, scenario, year) %>%
         group_by(scenario, state_fips) %>%
         mutate(hu_starts_single_family_millions_biannual = housing_starts_single_family_millions + lag(housing_starts_single_family_millions)) %>%
         mutate(hu_starts_multi_family_millions_biannual = housing_starts_multi_family_millions + lag(housing_starts_multi_family_millions)) %>%
         filter(year %in% keep_years)
# fix data for 2012
res_df$hu_starts_single_family_millions_biannual = ifelse(res_df$year == 2012, res_df$housing_starts_single_family_millions, res_df$hu_starts_single_family_millions_biannual)
res_df$hu_starts_multi_family_millions_biannual = ifelse(res_df$year == 2012, res_df$housing_starts_multi_family_millions, res_df$hu_starts_multi_family_millions_biannual)
# make sure the sums match the original sums
test_orig = group_by(aeo_df,  scenario, state_fips) %>%
            summarize(sf_total = sum(housing_starts_single_family_millions),
                      mf_total = sum(housing_starts_multi_family_millions))
test_new = group_by(res_df,  scenario, state_fips) %>%
           summarize(sf_total = sum(hu_starts_single_family_millions_biannual),
                     mf_total = sum(hu_starts_multi_family_millions_biannual))

diffs = merge(test_orig, test_new, by = c('state_fips', 'scenario'), suffixes = c('_orig', '_new'))
# are there any differences?
summary(diffs$sf_total_orig - diffs$sf_total_new) # no -- infinitesimally small diffs
summary(diffs$mf_total_orig - diffs$mf_total_new) # no -- infinitesimally small diffs

# calculate the biannual growth as percentrs relative to the baeline
res_df$incremental_growth_pct_singlefamily = (res_df$housing_starts_single_family_millions * 1e6)/res_df$singlefamily_baseline
res_df$incremental_growth_pct_multifamily = (res_df$housing_starts_multi_family_millions * 1e6)/res_df$multifamily_baseline
# check all values are < 1
summary(res_df$incremental_growth_pct_singlefamily)
# Min.  1st Qu.   Median     Mean  3rd Qu.     Max. 
# 0.001445 0.007025 0.010110 0.011960 0.016100 0.040300 
summary(res_df$incremental_growth_pct_multifamily)
# Min.  1st Qu.   Median     Mean  3rd Qu.     Max. 
# 0.002895 0.011060 0.016800 0.020000 0.026490 0.081890 
# All set!

# rename the growth column
res_df = mutate(res_df, res_single_family_growth = incremental_growth_pct_singlefamily) %>%
         mutate(res_multi_family_growth = incremental_growth_pct_multifamily)

# drop columns we don't need
keep_cols = c('state_fips',
              'state',
              'state_abbr',
              'census_division',
              'census_division_abbr',
              'year',
              'scenario',
              'res_single_family_growth',
              'res_multi_family_growth')
res_df = res_df[, keep_cols]

# --------------------------------------------------------------------------------
# COMMERCIAL
# --------------------------------------------------------------------------------
# isolate the first and last years
first_year_only = filter(aeo_df, year == 2012) %>%
                  mutate(commercial_sq_ft_billions_baseline = commercial_sq_ft_billions) %>%
                  select(state_fips, scenario, commercial_sq_ft_billions_baseline) 
last_year_only = filter(aeo_df, year == 2050) %>%
  mutate(commercial_sq_ft_billions_final = commercial_sq_ft_billions) %>%
  select(state_fips, scenario, commercial_sq_ft_billions_final) 
# join to the main dataframe
com_df = merge(aeo_df, first_year_only, by = c('state_fips', 'scenario')) %>%
         merge(last_year_only, by = c('state_fips', 'scenario'))
# drop the non-even years
keep_years = seq(2012, 2050, 2)
com_df = filter(com_df, year %in% keep_years)
# calculate incremental growth year by year
com_df = arrange(com_df,state_abbr, scenario, year) %>%
         group_by(state_abbr, scenario) %>%
         mutate(commercial_sq_ft_billions_floored = cummax(commercial_sq_ft_billions)) %>%
        mutate(commercial_sq_ft_billions_fix = pmin(commercial_sq_ft_billions_floored, commercial_sq_ft_billions_final))
# calculate incremental growth year by year
com_df = arrange(com_df,state_abbr, scenario, year) %>%
         group_by(state_abbr, scenario) %>%
         mutate(incremental_growth_abs = commercial_sq_ft_billions_fix - lag(commercial_sq_ft_billions_fix))
# replace values for 2012 with zero
com_df$incremental_growth_abs = ifelse(com_df$year == 2012, 0, com_df$incremental_growth_abs)
# check for negatives
sum(com_df$incremental_growth_abs < 0) # 0
# calculate growth as a percent
com_df$incremental_growth_pct = com_df$incremental_growth_abs/com_df$commercial_sq_ft_billions_baseline

# check results

test = mutate(com_df, estimated_growth = incremental_growth_pct * commercial_sq_ft_billions_baseline) %>%
  group_by(scenario, state_fips) %>%
  summarize(total_estimated_growth = sum(estimated_growth)) %>%
  merge(first_year_only, by = c('state_fips', 'scenario')) %>%
  merge(last_year_only, by = c('state_fips', 'scenario')) %>%
  mutate(actual_growth = commercial_sq_ft_billions_final - commercial_sq_ft_billions_baseline) 
# check differences between commercial_sq_ft_billions_total and final_total
summary((test$total_estimated_growth - test$actual_growth)/test$actual_growth)
# some under-estimates 
test[(test$total_estimated_growth - test$actual_growth)/test$actual_growth != 0, ]
# west virginia and DC under a few different scenarios
# these are cases where the final actual growth is negative -- we don't want to model this, so everything looks okay
# rename the incremental_growth_pct column
com_df = mutate(com_df, com_growth = incremental_growth_pct)
keep_cols = c('state_fips',
              'state',
              'state_abbr',
              'census_division',
              'census_division_abbr',
              'year',
              'scenario',
             'com_growth')
com_df = com_df[, keep_cols]

# --------------------------------------------------------------------------------
# COMBINE AND OUTPUT
# --------------------------------------------------------------------------------
join_cols = c('state_fips',
              'state',
              'state_abbr',
              'census_division',
              'census_division_abbr',
              'year',
              'scenario')
out_df = merge(res_df, com_df, by = join_cols)
# confirm row count matches original rows
nrow(filter(aeo_df, year %in% keep_years)) == nrow(out_df)
# write to csv
write.csv(out_df, '/Volumes/Staff/mgleason/dGeo/Data/Source_Data/EIA_NewBuilds_HousingStarts_ComFloospace/data_for_converting_to_scalars/output/new_building_growth_multipliers.csv', row.names = F)
