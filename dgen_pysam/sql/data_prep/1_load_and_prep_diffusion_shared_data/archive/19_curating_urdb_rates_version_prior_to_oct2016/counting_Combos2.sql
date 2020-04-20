
with a as
(
	SELECT census_division_abbr, count(*)
	FROM diffusion_shared.pt_grid_us_com a
	left join diffusion_shared.county_geom b
	on a.county_id = b.county_id
	group by census_division_abbr
),
b as 
(
	select census_division_abbr, count(*)
	FROM diffusion_shared.eia_microdata_cbecs_2003 c
	where pba8 <> 1
	group by census_division_abbr
)
select a.count*b.count, b.census_division_abbr
FROM a
left join b
on a.census_division_abbr = b.census_division_abbr;



with a as
(
	SELECT recs_2009_reportable_domain as rep_dom, count(*)
	FROM diffusion_shared.pt_grid_us_res a
	left join diffusion_shared.county_geom b
	on a.county_id = b.county_id
	group by recs_2009_reportable_domain
),
b as 
(
	select reportable_domain as rep_dom, count(*)
	FROM diffusion_shared.eia_microdata_recs_2009 c
	where typehuq in (1,2) AND kownrent = 1
	group by reportable_domain
)
select a.count*b.count, b.rep_dom
FROM a
left join b
on a.rep_dom = b.rep_dom;






with c as
(
	SELECT a.county_id, hdf_load_index, census_division_abbr
	FROM diffusion_shared.pt_grid_us_com a
	left join diffusion_shared.county_geom b
	on a.county_id = b.county_id
	group by a.county_id, hdf_load_index, census_division_abbr
),
a as
(
	SELECT census_division_abbr, count(*)
	FROM c
	GROUP BY census_division_abbr
)

,
b as 
(
	select census_division_abbr, count(*)
	FROM diffusion_shared.eia_microdata_cbecs_2003 c
	where pba8 <> 1
	group by census_division_abbr
)
select a.count*b.count, b.census_division_abbr
FROM a
left join b
on a.census_division_abbr = b.census_division_abbr;



with c as
(
	SELECT a.county_id, hdf_load_index, recs_2009_reportable_domain as rep_dom
	FROM diffusion_shared.pt_grid_us_res a
	left join diffusion_shared.county_geom b
	on a.county_id = b.county_id
	group by a.county_id, hdf_load_index, recs_2009_reportable_domain
),
a as
(
	SELECT rep_dom, count(*)
	FROM c
	GROUP BY rep_dom
),
b as 
(
	select reportable_domain as rep_dom, count(*)
	FROM diffusion_shared.eia_microdata_recs_2009 c
	where typehuq in (1,2) AND kownrent = 1
	group by reportable_domain
)
select a.count*b.count, b.rep_dom
FROM a
left join b
on a.rep_dom = b.rep_dom;
