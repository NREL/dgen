set role 'server-superusers';

-- DROP TYPE diffusion_solar.system_sizing_return;

CREATE TYPE diffusion_solar.system_sizing_return AS
   (system_size_kw numeric,
    npanels numeric,
    nem_available boolean);
ALTER TYPE diffusion_solar.system_sizing_return
  OWNER TO "diffusion-writers";


-- Function: diffusion_solar.system_sizing(numeric, numeric, numeric, numeric, double precision, numeric, numeric)

-- DROP FUNCTION diffusion_solar.system_sizing(numeric, numeric, numeric, numeric, double precision, numeric, numeric);

CREATE OR REPLACE FUNCTION diffusion_solar.system_sizing(load_kwh_per_customer_in_bin float, naep float, available_rooftop_space_sqft float, density_w_per_sqft float, system_size_limit_kw double precision, sys_size_target_nem float, sys_size_target_no_nem float)
  RETURNS diffusion_solar.system_sizing_return AS
$BODY$

    """ Calculate optimal system size, number of panels, and other (future) configurations"""

    

    # determine the maximum size of the system taht can be built for this customer based on physical rooftop available
    default_panel_size_sqft = 17.5 # Assume panel size of 17.5 sqft
    max_buildable_system_kw =  0.001 * available_rooftop_space_sqft * density_w_per_sqft

    ideal_system_size_kw_no_nem = (load_kwh_per_customer_in_bin *  sys_size_target_no_nem)/naep
    ideal_system_size_kw_nem = (load_kwh_per_customer_in_bin *  sys_size_target_nem)/naep 
    
    if system_size_limit_kw == 0:
	# if not net metering, the target percentage of load is sys_size_target_no_nem
	ideal_system_size_kw = ideal_system_size_kw_no_nem
	nem_available = False
    elif system_size_limit_kw == float('inf'):
	# if unlimited net metering, the target percentage of load is sys_size_target_nem
	ideal_system_size_kw = ideal_system_size_kw_nem
	nem_available = True
    else: 
	# if there is limited net metering, size to stay under the NEM system size limit
	ideal_system_size_kw = min(ideal_system_size_kw_nem, system_size_limit_kw)
	nem_available = True

    
    system_size_kw = round(min(max_buildable_system_kw, ideal_system_size_kw),2)
    npanels = system_size_kw/(0.001 * density_w_per_sqft * default_panel_size_sqft) # Denom is kW of a panel
    
    return system_size_kw, npanels, nem_available
    
$BODY$
  LANGUAGE plpythonu STABLE
  COST 100;

