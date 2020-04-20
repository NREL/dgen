library(reshape2)
library(ggplot2)
library(dplyr)

######################################################################################################
# INPUTS
in_csv = '/Users/mgleason/NREL_Projects/github/diffusion/sql/data_prep/2a_prep_wind_resource_data/2_update_wind_generation_data/1_create_powercurve_csvs/powercurve_update_2016_04_25.csv'
out_folder = '/Users/mgleason/NREL_Projects/github/windpy/windspeed2power/powercurves'
out_tidy = '/Users/mgleason/NREL_Projects/github/diffusion/sql/data_prep/2a_prep_wind_resource_data/2_update_wind_generation_data/1_create_powercurve_csvs/powercurve_update_tidy_2016_04_25.csv'
######################################################################################################
cur_date = format(Sys.time(), '%Y_%m_%d')
precision_digits = 3

pcm = read.csv(in_csv, check.names = F)

for (col in 2:ncol(pcm)){
  turbine_name = names(pcm)[col]
  pc = pcm[, c(1, col)]
  names(pc) = c('windspeed_ms', 'generation_kw')
  pc[, 'generation_kw'] = round(pc[, 'generation_kw'], 3)
  out_file = sprintf('dwind_turbine_%s_%s.csv', turbine_name, cur_date)
  out_file_path = file.path(out_folder, out_file)
  write.csv(pc, out_file_path, row.names = F)
}


m = melt(pcm, id.vars = c('windspeed_ms'), variable.name = 'power_curve', value.name = 'kwh')
write.csv(m, out_tidy, row.names = F)

cols = c('#66c2a4', '#e31a1c', '#fec44f', '#c994c7', '#238b45', '#005824', '#e7298a', '#91003f')
ggplot(data = m) +
  geom_line(aes(x = windspeed_ms, y = kwh, colour = power_curve)) +
  scale_colour_manual(values = cols)

# current turbines only
m_c = filter(m, power_curve %in% c(1, 2, 3, 4))

ggplot(data = m_c) +
  geom_line(aes(x = windspeed_ms, y = kwh, colour = power_curve), size = .75) +
  scale_colour_manual(values = cols)