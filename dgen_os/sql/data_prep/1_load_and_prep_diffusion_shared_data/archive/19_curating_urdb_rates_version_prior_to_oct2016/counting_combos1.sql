with a as
(
	SELECT b.state_abbr, count(*)
	FROM diffusion_shared.pt_grid_us_res a
	left join diffusion_shared.county_geom b
	on a.county_id = b.county_id
	group by b.state_abbr
),
b as 
(
SELECT state_abbr, count(*)
FROM diffusion_shared.urdb_rates_by_state_res
GROUP by state_abbr
)
select a.count*b.count, b.state_abbr
FROM a
left join b
on a.state_abbr = b.state_abbr;
