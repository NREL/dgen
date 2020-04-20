set role 'diffusion-writers';

DROP TABLE IF EXISTS diffusion_wind.tech_potential_by_state;
CREATE TABLE diffusion_wind.tech_potential_by_state AS
select state_abbr, 
	round(sum(total_generation_kwh/1000/1000)::NUMERIC, 1) as gen_gwh,
	sum(systems_count) as systems_count, 
	round(sum(total_capacity_kw::NUMERIC/1000/1000)::NUMERIC, 1) as cap_gw
from diffusion_data_wind.tech_pot_block_turbine_size_selected
GROUP BY state_abbr;
-- 49 rows

-- add primary key
ALTER TABLE diffusion_wind.tech_potential_by_state
ADD PRIMARY KEY (state_abbr);

select sum(gen_gwh), sum(systems_count), sum(cap_gw)
FROM diffusion_wind.tech_potential_by_state;