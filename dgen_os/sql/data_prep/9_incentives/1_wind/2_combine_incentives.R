library(xlsx)
library(dplyr)
setwd('/Users/mgleason/NREL_Projects/github/diffusion/sql/data_prep/9_wind_incentives/Data/Output/curated_incentives')
files = c('incentives_cap_rebate.xlsx',
          'incentives_pbi.xlsx',
          'incentives_itc.xlsx',
          'incentives_itd.xlsx',
          'incentives_prod_rebate.xlsx',
          'incentives_ptc.xlsx')

l = list()
for (n in 1:length(files)){
  df_x = read.xlsx(files[n], sheetIndex = 1)
  df_x$exp_date = as.Date(df_x$exp_date)
  df_x$cap_dlrs = as.numeric(as.character(df_x$cap_dlrs))
  if ('cap_pct_cost' %in% names(df_x)){
    df_x$cap_pct_cost = as.numeric(as.character(df_x$cap_pct_cost))    
  }
  df_x$min_size_kw = as.numeric(as.character(df_x$min_size_kw))
  df_x$max_size_kw = as.numeric(as.character(df_x$max_size_kw))
  l[[n]] = df_x

}

df = rbind_all(l)
# fill min_aep_kwh and max_aep_kwh
df$min_aep_kwh = ifelse(is.na(df$min_aep_kwh), 0, df$min_aep_kwh)
df$max_aep_kwh = ifelse(is.na(df$max_aep_kwh), Inf, df$max_aep_kwh)


# write to csv
write.csv(df, 'incentives_all.csv', row.names = F)

# summary stats
# how many states?
length(unique(df$state_abbr)) # 18
# how many com incentives?
sum(df$sector_abbr == 'com') # 20
# how many res incentives?
sum(df$sector_abbr == 'res') # 21
# how many of each type
as.list(table(df$incentive_type))


