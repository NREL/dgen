DROP TYPE diffusion_wind.scoe_return;

CREATE TYPE diffusion_wind.scoe_return AS
   (scoe numeric,
    nturb numeric,
    nem_available boolean);
ALTER TYPE diffusion_wind.scoe_return
  OWNER TO "diffusion-writers";


DROP FUNCTION diffusion_wind.scoe(ic numeric, fom numeric, vom numeric, naep numeric, cap numeric, ann_elec_cons numeric, nem_system_limit_kw float, oversize_factor numeric, undersize_factor numeric);
SET ROLE 'server-superusers';
CREATE OR REPLACE FUNCTION diffusion_wind.scoe(ic numeric, fom numeric, vom numeric, naep numeric, cap numeric, ann_elec_cons numeric, nem_system_limit_kw float, excess_generation_factor numeric, oversize_factor numeric default 1.15, undersize_factor numeric default 0.5)
  RETURNS float AS
  $BODY$

    """ Calculate simple metric for evaluating optimal capacity-height among several
        possibilities. The metric does not caclulate value of incentives, which are 
        assumed to scale btw choices. In sizing, allow production to exceed annual 
        generation by default 15%, and undersize by 50%.
        
       IN:
           ic  - Installed Cost ($/kW)
           fom - Fixed O&M ($/kW-yr)
           vom - Variable O&M ($/kWh)
           naep - Annual Elec Production (kWh/kw/yr)
           cap - Proposed capacity (kW)
           ann_elec_cons - Annual Electricity Consumption (kWh/customer/yr)
           oversize_factor - Severe penalty for  proposed capacities whose aep exceed
                             annual electricity consumption by 15% (default)
           undersize_factor - Small penalty for proposed capacities whose aep is beneath
                             annual electricity consumption by 50% (default)
       
       OUT:
           scoe - numpy array - simple lcoe (lower is better)
    """
    if nem_system_limit_kw > cap:
        nem_factor = 1  
    else:
        nem_factor = excess_generation_factor
        
    if naep == 0:
        return float('inf')
    else:
        scoe = (ic + 30 * fom + 30 * naep * vom) / (30 * naep) # $/kWh
        # add in a penalty for oversizing that scales with the degree of oversizing
        oversized = ((naep * cap / ann_elec_cons) > (nem_factor * oversize_factor)) * ((naep * cap / ann_elec_cons) / (nem_factor * oversize_factor))
        undersized = ((naep * cap / ann_elec_cons) < (nem_factor * undersize_factor)) / ((naep * cap / ann_elec_cons) / (nem_factor * undersize_factor))
        scoe = scoe + oversized * 10 + undersized * 0.1 # Penalize under/over sizing    
         
        return scoe

  $BODY$
  LANGUAGE plpythonu stable
  COST 100;
RESET ROLE;
