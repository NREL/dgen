-- RESIDENTIAL
--check mins
select min(urdb_demand_min)
FROM diffusion_data_shared.urdb_rates_by_state_res_maine
group by state_abbr
order by 1 desc;
-- should be zero in all cases and 49 rows

select max(urdb_demand_max)
FROM diffusion_data_shared.urdb_rates_by_state_res_maine
group by state_abbr
order by 1 asc;
-- really huge nmber

select max(urdb_demand_max-urdb_demand_min)
FROM diffusion_data_shared.urdb_rates_by_state_res_maine
group by state_abbr
order by 1;
-- really huge nmber

with a AS
(
	select state_abbr, ST_Union(ST_MakeLine(ST_MakePoint(0,urdb_demand_min),
			    ST_MakePoint(0, urdb_demand_max))) as span
	from diffusion_data_shared.urdb_rates_by_state_res_maine
	GROUP BY state_abbr
),
b as 
(
	SELECT state_abbr, ST_Covers(span,
					ST_MakeLine(ST_MakePoint(0,0),
					ST_MakePoint(0, 1e+38))) as covers

	FROM a
)
SELECT *
FROM b 
where covers = false;


-- INDUSTRIAL
--check mins
select min(urdb_demand_min)
FROM diffusion_data_shared.urdb_rates_by_state_ind_maine
group by state_abbr
order by 1 desc;
-- should be zero in all cases and 49 rows

select max(urdb_demand_max)
FROM diffusion_data_shared.urdb_rates_by_state_ind_maine
group by state_abbr
order by 1 asc;
-- really huge nmber

select max(urdb_demand_max-urdb_demand_min)
FROM diffusion_data_shared.urdb_rates_by_state_ind_maine
group by state_abbr
order by 1;
-- really huge nmber

with a AS
(
	select state_abbr, ST_Union(ST_MakeLine(ST_MakePoint(0,urdb_demand_min),
			    ST_MakePoint(0, urdb_demand_max))) as span
	from diffusion_data_shared.urdb_rates_by_state_ind_maine
	GROUP BY state_abbr
),
b as 
(
	SELECT state_abbr, ST_Covers(span,
					ST_MakeLine(ST_MakePoint(0,0),
					ST_MakePoint(0, 1e+38))) as covers

	FROM a
)
SELECT *
FROM b 
where covers = false;
-- ALL SET FOR ALL SECTORS !