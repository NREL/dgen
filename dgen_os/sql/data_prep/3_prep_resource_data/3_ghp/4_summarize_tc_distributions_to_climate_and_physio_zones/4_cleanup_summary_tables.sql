set role 'diffusion-writers';


ALTER TABLE diffusion_geo.thermal_conductivity_summary_by_climate_zone
ADD PRIMARY KEY (climate_zone);

ALTER TABLE diffusion_geo.thermal_conductivity_summary_by_physio_division
ADD PRIMARY KEY (physio_division);

COMMENT ON TABLE diffusion_geo.thermal_conductivity_summary_by_climate_zone IS 'units are BTU/hr-ft-F';

COMMENT ON TABLE diffusion_geo.thermal_conductivity_summary_by_physio_division IS 'units are BTU/hr-ft-F';

