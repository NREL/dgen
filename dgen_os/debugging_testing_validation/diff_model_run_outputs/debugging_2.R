library(dplyr)

tech = 'wind'
oops_dir = '/Users/mgleason/NREL_Projects/github/diffusion/runs/results_20160825_104907_oops_nrel'

benchmark_dir = '/Users/mgleason/NREL_Projects/github/diffusion/runs/results_20160824_170038_dev_nrel/'
benchmark_file = sprintf('%s/BAU/%s/outputs_%s.csv.gz', benchmark_dir, tech, tech)
oops_file = sprintf('%s/BAU/%s/outputs_%s.csv.gz', oops_dir, tech, tech)
one  = read.csv(benchmark_file, stringsAsFactors = F)
two = read.csv(oops_file, stringsAsFactors = F)

column_mapping_file = sprintf('/Users/mgleason/NREL_Projects/github/diffusion/debugging_testing_validation/diff_model_run_outputs/column_mapping_%s.csv', tech)
column_mapping = read.csv(column_mapping_file, stringsAsFactors = F)

# check sizes
nrow(one) 
nrow(two)

# filter to first year
# one = filter(one, year == 2024)
# two = filter(two, year == 2024)

# filter to specific county
# one = filter(one, county_id == 2117) #
# two = filter(two, county_id == 2117) # 2117

# sort
one = one[with(one, order(sector, county_id, bin_id, tech, year)), ]
two = two[with(two, order(sector, county_id, bin_id, tech, year)), ]

# align the columns
for (row in 1:nrow(column_mapping)){
  b_col = column_mapping$benchmark[row]
  o_col = column_mapping$oops[row]
  names(one)[which(names(one) == b_col)] = o_col
  
}

mismatched = c()
for (col in column_mapping$oops){
    tol = 0.00001
    if (any(is.infinite(one[, col])) | any(is.infinite(two[, col]))){
      mismatch = !all.equal(one[, col], two[, col], na.rm = T)
    } else if (is.numeric(one[, col])){
      mismatch = any(abs(one[, col] - two[, col]) > 0.0001, na.rm = T)      
    } else if (is.character(one[, col])){
      mismatch = all.equal.character(one[, col], two[, col], na.rm = T) != T
    } else {
      mismatch = !all.equal(one[, col], two[, col], na.rm = T)
    }
    if (mismatch == T){
      mismatched = c(mismatched, col)
    }
}

cat(mismatched, sep = '\n')

# additional columns to include
add_cols = c('system_size_kw',
             'first_year_bill_without_system',
             'metric',
             'metric_value',
             'county_id',
             'bin_id',
             'sector'
  )

# save to csv
write.csv(one[, c(mismatched, add_cols)], '/Users/mgleason/NREL_Projects/github/diffusion/runs/debug/benchmark.csv', row.names = F)
write.csv(two[, c(mismatched, add_cols)], '/Users/mgleason/NREL_Projects/github/diffusion/runs/debug/oops.csv', row.names = F)

