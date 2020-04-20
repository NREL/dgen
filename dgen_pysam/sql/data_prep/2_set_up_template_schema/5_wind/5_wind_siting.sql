SET ROLE 'diffusion-writers';


DROP TABLE IF EXISTS diffusion_template.input_wind_siting_property_setbacks;
CREATE TABLE diffusion_template.input_wind_siting_property_setbacks
(
	blade_height_setback_factor numeric NOT NULL,
	required_parcel_size_cap_acres numeric NOT NULL
);


DROP TABLE IF EXISTS diffusion_template.input_wind_siting_canopy_clearance;
CREATE TABLE diffusion_template.input_wind_siting_canopy_clearance
(
	canopy_clearance_rotor_factor numeric NOT NULL,
	canopy_clearance_static_adder_m numeric NOT null,
	canopy_pct_requiring_clearance numeric not null
);


DROP VIEW IF EXISTS diffusion_template.input_wind_siting_settings_all;
CREATE VIEW diffusion_template.input_wind_siting_settings_all AS
select a.*, b.*
from diffusion_template.input_wind_siting_property_setbacks a
CROSS JOIN diffusion_template.input_wind_siting_canopy_clearance b;

DROP VIEW IF EXISTS diffusion_template.input_wind_siting_turbine_sizes;
CREATE VIEW diffusion_template.input_wind_siting_turbine_sizes as
SELECT a.turbine_size_kw, a.rotor_radius_m,
	b.turbine_height_m,
	b.turbine_height_m - a.rotor_radius_m * c.canopy_clearance_rotor_factor as effective_min_blade_height_m,
	b.turbine_height_m + a.rotor_radius_m as effective_max_blade_height_m
FROM diffusion_wind.turbine_size_to_rotor_radius_lkup a
LEFT JOIN diffusion_template.input_wind_performance_allowable_turbine_sizes b
	ON a.turbine_size_kw = b.turbine_size_kw
CROSS JOIN diffusion_template.input_wind_siting_settings_all c;