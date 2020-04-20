-- RECS

-- primary key
ALTER TABLE diffusion_shared.eia_microdata_recs_2009_expanded_bldgs
ADD PRIMARY KEY (building_id);

-- indices
CREATE INDEX eia_microdata_recs_2009_reportable_domain_btree 
ON diffusion_shared.eia_microdata_recs_2009_expanded_bldgs
USING btree(reportable_domain);

CREATE INDEX eia_microdata_recs_2009_expanded_bldgs_census_region_btree 
ON diffusion_shared.eia_microdata_recs_2009_expanded_bldgs
USING btree(census_region);

CREATE INDEX eia_microdata_recs_2009_expanded_bldgs_census_division_abbr_btree 
ON diffusion_shared.eia_microdata_recs_2009_expanded_bldgs
USING btree(census_division_abbr);

CREATE INDEX eia_microdata_recs_2009_expanded_bldgs_typehuq_btree
ON diffusion_shared.eia_microdata_recs_2009_expanded_bldgs
using btree(single_family_res)
where single_family_res = True;

CREATE INDEX eia_microdata_recs_2009_expanded_bldgs_num_tenants_btree
ON diffusion_shared.eia_microdata_recs_2009_expanded_bldgs
using btree(num_tenants);

CREATE INDEX eia_microdata_recs_2009_expanded_bldgs_kownrent_btree
ON diffusion_shared.eia_microdata_recs_2009_expanded_bldgs
using btree(owner_occupied)
where owner_occupied = TRUE;

CREATE INDEX eia_microdata_recs_2009_expanded_bldgs_climate_region_pub_btree
ON diffusion_shared.eia_microdata_recs_2009_expanded_bldgs
using btree(climate_zone);
------------------------------------------------------------------------------------------------
-- CBECS

ALTER TABLE diffusion_shared.eia_microdata_cbecs_2003_expanded
ADD PRIMARY KEY (building_id);

-- add indices on ownocc8, pba, pbaplus, and climate8
CREATE INDEX eia_microdata_cbecs_2003_expanded_ownocc8_btree
ON diffusion_shared.eia_microdata_cbecs_2003_expanded
using btree(owner_occupied)
where owner_occupied = TRUE;

CREATE INDEX eia_microdata_cbecs_2003_expanded_pba8_btree
ON diffusion_shared.eia_microdata_cbecs_2003_expanded
using btree(pba);

CREATE INDEX eia_microdata_cbecs_2003_expanded_pbaplus8_btree
ON diffusion_shared.eia_microdata_cbecs_2003_expanded
using btree(pbaplus);

CREATE INDEX eia_microdata_cbecs_2003_expanded_climate8_btree
ON diffusion_shared.eia_microdata_cbecs_2003_expanded
using btree(climate_zone);

CREATE INDEX eia_microdata_cbecs_2003_expanded_census_region_btree 
ON diffusion_shared.eia_microdata_cbecs_2003_expanded
USING btree(census_region);

CREATE INDEX eia_microdata_cbecs_2003_expanded_census_division_abbr_btree 
ON diffusion_shared.eia_microdata_cbecs_2003_expanded
USING btree(census_division_abbr);
------------------------------------------------------------------------------------------

