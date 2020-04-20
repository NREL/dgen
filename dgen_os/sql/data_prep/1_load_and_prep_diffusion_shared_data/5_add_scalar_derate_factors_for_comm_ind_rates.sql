-- add (fake) derate factors
ALTER TABLE diffusion_shared.annual_ave_elec_rates_2011 ADD COLUMN comm_derate_factor numeric,
						add column ind_derate_factor numeric;

UPDATE diffusion_shared.annual_ave_elec_rates_2011
SET (comm_derate_factor , ind_derate_factor) = (0.8, 0.8);