one  = read.csv('/Users/mgleason/NREL_Projects/github/diffusion_226f66/diffusion/runs/results_20151001_162556/BAU/wind/econ_results.csv', stringsAsFactors = F)
two = read.csv('/Users/mgleason/NREL_Projects/github/diffusion/runs/results_20151001_162724/BAU/wind/econ_results.csv', stringsAsFactors = F)

names(one)[which(names(one) == 'sector_abbr_x')] = 'sector_abbr'
one = one[, names(one) != 'sector_abbr_y']

# names(two)[which(names(two) == 'sector_x')] = 'sector'
# two = two[, names(two) != 'sector_y']

one = one[, names(two)]

# check sizes
nrow(one) 
nrow(two)

# check column names match
all(names(one) == names(two))

# subset to cols of interest
# one = one[,c('county_id','bin_id','year','turbine_size_kw','turbine_height_m')]
# two = two[,c('county_id','bin_id','year','turbine_size_kw','turbine_height_m')]

ids = c('county_id','bin_id','year','sector_abbr', 'tech','business_model')

# compare
m = merge(one, two, by = ids, suffixes = c('.1','.2'))

mismatched = c()
for (n in names(one)){
  if (!(n %in% ids)){
    var1 = sprintf('%s.1', n)
    var2 = sprintf('%s.2', n)
    match = all.equal(m[, var1], m[, var2], na.rm = T)
    if (match != T){
      print(n)
      mismatched = c(mismatched, var1, var2)
    }
  }
  
}
# any rows where the values aren't equal?

a = m[m$market_share_last_year.1 != m$market_share_last_year.2, c(ids, mismatched, 'ann_cons_kwh.1', 'ann_cons_kwh.2')]

m[m$business_model.1 != m$business_model.2, c(ids, 'metric.1', 'metric_value.1', 'business_model.1', 'metric.2', 'metric_value.2', 'business_model.2')]
y = m[m$business_model.1 != m$business_model.2, c(ids, mismatched)]

x = m[m$first_year_bill_without_system.1 != m$first_year_bill_without_system.2, c(ids, mismatched)]

nrow(m[m$density_w_per_sqft.1 != m$density_w_per_sqft.2,])
write.csv(x, '/Users/mgleason/NREL_Projects/git_repos/diffusion/runs_solar/results_20150310_172432/dSolar/diff2.csv', row.names = F)
