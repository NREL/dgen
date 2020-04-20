-- assume sampling at 5% of all buildings
DROP TABLE IF EXISTS mgleason.temp_tract;
CREATE TABLE mgleason.temp_tract AS
with microdata_joined as
(
	select bldg_count_com as sample_weight, *
	FROM diffusion_blocks.block_microdata_com a
  	where tract_id_alias = 1
),
b as
(
	select a.*, unnest(diffusion_shared.r_array_extract(a.bldg_probs_com, b.bldg_types)) as hazus_bldg_type,
		    unnest(diffusion_shared.r_array_extract(a.bldg_probs_com, a.bldg_probs_com)) as hazus_bldg_count
	from microdata_joined a
	LEFT join diffusion_blocks.bldg_type_arrays b
	ON b.sector_abbr = 'com'
)
select *
FROM b




with microdata_joined as
(
	select bldg_count_com as sample_weight, *
	FROM diffusion_blocks.block_microdata_com a
--  	where tract_id_alias = 1
	where state_abbr = 'CO'
),
b as
(
	select a.*, unnest(diffusion_shared.r_array_extract(a.bldg_probs_com, b.bldg_types)) as hazus_bldg_type,
		    unnest(diffusion_shared.r_array_extract(a.bldg_probs_com, a.bldg_probs_com)) as hazus_bldg_count
	from microdata_joined a
	LEFT join diffusion_blocks.bldg_type_arrays b
	ON b.sector_abbr = 'com'
)-- 22 rows -- this could be a separate, pre-built table -- this is how many unique combinations of building types x blocks there are
-- c as
-- (
-- 	 -- this step temporarily expands the table
-- 	select b.*, c.pbaplus
-- 	FROM b
-- 	LEFT JOIN diffusion_shared.cdms_bldg_types_to_pba_plus_lkup c
-- 	ON b.hazus_bldg_type = c.cdms
-- ),
-- d as
-- (
-- 	select c.*, d.building_id, d.sample_wt as bldg_sample_wt
-- 	from c
-- 	lEFT JOIN diffusion_shared.eia_microdata_cbecs_2003_expanded d
-- 	ON c.census_division_abbr = d.census_division_abbr
-- 	ANd c.pbaplus = d.pbaplus
-- 	where d.sample_wt is not null -- this should be removed -- it's just for debugging
-- ),
-- e as
-- (
-- 	select d.pgid, d.hazus_bldg_type,
-- 			    unnest(diffusion_shared.sample(array_agg(building_id ORDER BY building_id), 
-- 							   1, 
-- 							   1 * d.pgid, 
-- 							   True, 
-- 							   array_agg(bldg_sample_wt::NUMERIC ORDER BY building_id))
-- 							   ) as building_id
-- 	from d
-- 	GROUP BY d.pgid, d.hazus_bldg_type
-- )-- ,
-- g as
-- (
-- 	select b.hazus_bldg_count as buildings_in_bin, -- note: for commercial, this needs to be rescaled because hazus over estiamtes count of buildings
-- 		b.*, 
-- 		f.*
-- 	from e
-- 	left join b 
-- 	ON e.pgid = b.pgid
-- 	and e.hazus_bldg_type = b.hazus_bldg_type
-- 	LEFT JOIN diffusion_shared.eia_microdata_cbecs_2003_expanded f
-- 	ON e.building_id = f.building_id
-- )
select distinct tract_id_alias, hazus_bldg_type--, hazus_bldg_count, pgid
FROM b
--order by 1, 3,2;

-- 6690696

-- issues to address:
	-- how to do this for residential 
		-- how to incorporate baseline heating system type frequencies
		-- how to deal with multiple occupancy and/or non-owner occupied bldgs?
	-- this may not scale well -- how to represent some fraction of all buildings with fewer rows? maybe not ideal since tracts are so small to begin with
		-- or maybe a combination of % of buildings in tract (for large tracts) and minimum agents per tract (e.g., 10) for small tracts?
	-- need to ensure total # of buildings and total thermal load sum to known totals at larger regional levels (county, census division ,etc.
	-- waht is the role of owner occupied buildings in commercial?
	-- what to do for industrial?
	-- how to add new builds?
	-- issue to fix:
		-- cbecs pba plus x census_division-abbr combos are missing (pbaplus = 20, census_division_abbr = MTN) -- fix by either switching to a different region or generalizing to pba code
-- additional attributes to add:
-- immutable
	-- system age simulated
	-- capital cost multipliers (not for agents -- for plants)
	-- map to a baseline system type (for costs)
-- mutable
	-- system expected lifetime parameters
	-- system lifetime expired in any given year?
	-- local or regional cost of fuel
