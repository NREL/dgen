library(xlsx)
library(reshape)

setwd('/Users/kmccabe/dGeo/Data/ORNL_GHP_CRB_Simulations/ghp_simulation_results')

in_xlsx = 'source/Building Comparison GTV (commercial and residential 9-9-2016).xlsx'
wb = loadWorkbook(in_xlsx)
sheets = getSheets(wb)
sheet_names = names(sheets)

sheets_to_skip = c('GHX Comparison', 'Comparison Charts')
ranges = read.csv('helper/ghp_range_lkup.csv', stringsAsFactors = F)
bldg_type_to_id_lkup = read.csv('helper/building_type_to_baseline_type_lkup.csv', stringsAsFactors = F)

sheet_dfs = list()
for (sheet_name in sheet_names){
  if (sheet_name %in% c(sheets_to_skip)){
    # do nothing
  } else {
    sheet = sheets[sheet_name]
    df_names = c()
    for (row in 1:nrow(ranges)){
      startColumn = ranges[row, 'startColumn']
      endColumn = ranges[row, 'endColumn']
      startRow = ranges[row, 'startRow']
      endRow = ranges[row, 'endRow']
      header = ranges[row, 'header']
      tc_val = ranges[row, 'tc_val']
      df_prefix = ranges[row, 'df_prefix']
      col_prefix = ranges[row, 'col_prefix']
      if (is.na(col_prefix)){
        col_prefix = ''
      }
      
      df = readColumns(sheet[[1]], startColumn, endColumn, startRow, endRow, header = header, stringsAsFactors = F)
      # column name cleanup
      names(df) = tolower(gsub('[\\.]+', '_', names(df)))
      names(df) = gsub('building_tye', 'building_type', names(df))
      names(df) = gsub('_mc|_lc|_hc', '', names(df))
      names(df) = gsub('_$', '', names(df))
      names(df) = sprintf('%s%s', col_prefix, names(df))
      names(df) = gsub('savings_pct_building_type', 'building_type', names(df))
      names(df) = gsub('savings_abs_building_type', 'building_type', names(df))
      
      
      df[, 'tc_val'] = tc_val
      df_name = sprintf('%s_%s', df_prefix, tc_val)
      assign(df_name, df)
      df_names = c(df_names, df_name)
    }
    # combine data into a single csv
    # merge tc vals
    gtc = rbind(ground_thermal_conductivity_btu_per_hftF_tc_1, 
                ground_thermal_conductivity_btu_per_hftF_tc_2,
                ground_thermal_conductivity_btu_per_hftF_tc_3)
    names(gtc)[1] = 'gtc_btu_per_hftF'
    for (df_name in df_names){
      if (!(grepl('ground_thermal', df_name))){
        df = get(df_name)
        df = merge(df, gtc, by = 'tc_val')
        # replace building names with building ids
        df = merge(df, bldg_type_to_id_lkup, by = c('building_type'))
        keep_cols = names(df)[names(df) != 'building_type']
        df = df[, keep_cols]
        assign(df_name, df)
      }
    }
    # now merge across tc_vals
    prefixes = c('baseline', 'ghp', 'savings_abs', 'savings_pct', 'ghx_sizing')
    merged_dfs = list()
    for (tc_val in gtc$tc_val){
      dfs = sprintf('%s_%s', prefixes, tc_val)
      df_list = list()
      for (df_name in dfs){
        df_list[[df_name]] = get(df_name)
      }
      # merge
      merged_df = Reduce(function(...) merge(..., all=T), df_list)
      merged_dfs[[tc_val]] = merged_df
    }
    # rbind the merged dfs
    complete_sheet_df = Reduce(function(...) rbind(...), merged_dfs)
    # city and climate_zone
    city = strsplit(names(sheet), '-')[[1]][1]
    climate_zone = strsplit(names(sheet), '-')[[1]][2]
    complete_sheet_df[, 'city'] = city
    complete_sheet_df[, 'climate_zone'] = climate_zone
    sheet_dfs[[names(sheet)]] = complete_sheet_df
  }
}

# merge everything into one
complete_df = Reduce(function(...) rbind(...), sheet_dfs)
# drop rows where multiple vlaues are NA
complete_df_no_nas = complete_df[rowSums(is.na(complete_df)) < 26,]
# drop the tc_val column
# out_cols = !grepl('tc_val', names(complete_df_no_nas))
# complete_df_no_nas = complete_df_no_nas[, out_cols]
# replace values of NA with NA (applies only to energy savings pct)
complete_df_no_nas[complete_df_no_nas == 'NA'] = NA
# fix dtypes
char_cols = c('building_type', 'city', 'climate_zone', 'tc_val')
for (col in names(complete_df_no_nas)){
  if (col %in% char_cols){
    # do nothing
  } else {
    # cast to numeric
    complete_df_no_nas[, col] = as.numeric(complete_df_no_nas[, col])
  }
}


# expected rows

expected_nrows = 3 * 12 * 13
if (expected_nrows != nrow(complete_df_no_nas)){
  print("Warning: expected number of rows doesn't match actual number of rows")
}
# reorder columns
out_cols = unique(c('baseline_type', names(complete_df_no_nas)))
final_df = complete_df_no_nas[, out_cols]

# write to csv
date = format(Sys.Date(), '%Y_%m_%d')
out_file = sprintf('consolidated/ghp_results_%s.csv', date)
write.csv(final_df, out_file, row.names = F, na = '')



