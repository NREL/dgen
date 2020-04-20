load('/Users/mgleason/NREL_Projects/github/diffusion/runs/microdata_comparison/old_microdata/scenario_comparison_windscenario_workspace.Rdata')
assign('old_diff_trends', diff_trends)

load('/Users/mgleason/NREL_Projects/github/diffusion/runs/microdata_comparison/new_microdata/scenario_comparison_windscenario_workspace.Rdata')
assign('new_diff_trends', diff_trends)

library(dplyr)
library(ggplot2)
old_diff_cap = filter(old_diff_trends, variable == 'nat_installed_capacity_gw' & data_type == 'Cumulative')
old_diff_bounds = old_diff_cap %>%
                  group_by(year) %>%
                  summarize(q05 = quantile(value, 0.05),
                            q95 = quantile(value, 0.95),
                            med = median(value)
                            )  %>%
                  mutate(src = 'old')

new_diff_cap = filter(new_diff_trends, variable == 'nat_installed_capacity_gw' & data_type == 'Cumulative') 
new_diff_bounds = new_diff_cap %>%
                  group_by(year) %>%
                  summarize(q05 = quantile(value, 0.05),
                            q95 = quantile(value, 0.95),
                            med = median(value)
                    ) %>%
                  mutate(src = 'new')


all_diff_bounds = rbind(old_diff_bounds, new_diff_bounds)

ggplot(data = all_diff_bounds) +
  geom_ribbon(aes(x = year, ymin = q05, ymax = q95, fill = src), alpha = 0.5) +
  geom_line(aes(x = year, y = med, colour = src))

# ggplot(data = all_diff_cap) +
#   geom_ribbon(aes(x = year, ymin = q05, ymax = q95, fill = src), alpha = 0.7)
