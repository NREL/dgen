select *
from diffusion_solar.utilityrate3_results
order by 2, 3, 1

copy diffusion_solar.utilityrate3_results
to '/home/mgleason/utilityrate3_results_wes.csv' with csv header;

COPY diffusion_solar.unique_rate_gen_load_combinations
to '/home/mgleason/unique_rate_gen_load_combinations_wes.csv' with csv header;

COPY diffusion_solar.pt_res_elec_costs
to '/home/mgleason/pt_res_elec_costs_wes.csv' with csv header;

COPY diffusion_solar.pt_com_elec_costs
to '/home/mgleason/pt_com_elec_costs_wes.csv' with csv header;

COPY diffusion_solar.pt_com_best_option_each_year
to '/home/mgleason/pt_com_best_option_each_year_wes.csv' with csv header;