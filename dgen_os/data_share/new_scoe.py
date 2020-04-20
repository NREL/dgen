def scoe(load_kwh_per_customer_in_bin, 
        naep, 
        turbine_size_kw,
        system_size_limit_kw, 
        sys_size_target_nem, 
        sys_oversize_limit_nem,
        sys_size_target_no_nem,
        sys_oversize_limit_no_nem ):
    # -*- coding: utf-8 -*-
    """
    Created on Mon Jan 12 15:37:16 2015
    
    @author: mgleason
    """

    
    if system_size_limit_kw == 0:
        # if not net metering, the target percentage of load is sys_size_target_no_nem
        # and the oversize limit is the sys_oversize_limit_no_nem
        target_kwh = load_kwh_per_customer_in_bin * sys_size_target_no_nem
        oversize_limit_kwh = load_kwh_per_customer_in_bin * sys_oversize_limit_no_nem
        # set nem availability to false
        nem_available = False
    elif system_size_limit_kw > 0:
        # if there is net metering...
        # check that the system is within the net metering size limit
        if turbine_size_kw > system_size_limit_kw:
            # if not,  return very high cost
            scoe = load_kwh_per_customer_in_bin * 10
            nturb = 1
            nem_available = False
            return scoe, nturb, nem_available
        else:
            # if the system is within the limit,
            # the target percentage of load is sys_size_target_nem
            target_kwh = load_kwh_per_customer_in_bin * sys_size_target_nem
            oversize_limit_kwh = load_kwh_per_customer_in_bin * sys_oversize_limit_nem
            nem_available = True

    # calculate the system generation from naep and turbine_size_kw
    aep = turbine_size_kw * naep

    # check whether the aep is equal to zero or whether the system is above the oversize limit
    if aep == 0 or aep > oversize_limit_kwh:
            # if so, return very high cost
            scoe = load_kwh_per_customer_in_bin * 10
            nturb = 1
            nem_available = False
            return scoe, nturb, nem_available 
    
    # if the turbine is the max turbine size (1.5 MW) and less than the target generation
    # determine whether multiple turbines should be installed
    if turbine_size_kw == 1500 and aep < target_kwh:
        # This indicates we want a project larger than 1500 kW. Return -1 scoe
        # and the optimal continuous number of turbines
        scoe = -1
        nturb  = target_kwh/aep
        nturb = min(4, nturb) #Don't allow projects larger than 6 MW
    else:
        # for remaining conditions, 
        # calculate the absolute different of how far the aep is from the target generation
        scoe = abs(aep-target_kwh)            
        nturb = 1    

    return scoe, nturb, nem_available
