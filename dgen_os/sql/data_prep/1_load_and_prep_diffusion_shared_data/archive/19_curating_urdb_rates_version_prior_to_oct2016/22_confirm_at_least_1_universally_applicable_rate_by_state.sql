-- RESIDENTIAL
--check mins
select min(urdb_demand_min)
FROM diffusion_shared.urdb_rates_by_state_res
where rate_id_alias not in 
	(815, 2090, 80, 523, 452, 844, 1857, 2034, 2306, 888, 1368, 974, 1031, 
	471, 1856, 1165, 1325, 1271, 40, 1831, 1966, 277, 751, 1512, 154, 275, 
	1740, 2318, 1853, 1163, 333, 784, 1172, 321, 1626, 527, 1207, 233, 
	1492, 98, 1851, 1737, 292, 874, 218, 1979, 1372, 1427, 45, 2330, 956, 
	1161, 414, 785, 1084, 1298, 2145, 1449, 2094, 413, 1792, 149, 1182, 
	1791, 186, 1330, 953, 2154)
group by state_abbr
order by 1 desc;
-- should be zero in all cases and 49 rows

select max(urdb_demand_max)
FROM diffusion_shared.urdb_rates_by_state_res
where rate_id_alias not in 
	(815, 2090, 80, 523, 452, 844, 1857, 2034, 2306, 888, 1368, 974, 1031, 
	471, 1856, 1165, 1325, 1271, 40, 1831, 1966, 277, 751, 1512, 154, 275, 
	1740, 2318, 1853, 1163, 333, 784, 1172, 321, 1626, 527, 1207, 233, 
	1492, 98, 1851, 1737, 292, 874, 218, 1979, 1372, 1427, 45, 2330, 956, 
	1161, 414, 785, 1084, 1298, 2145, 1449, 2094, 413, 1792, 149, 1182, 
	1791, 186, 1330, 953, 2154)
group by state_abbr
order by 1 asc;
-- should all be the same huge number and 49 rows

select max(urdb_demand_max-urdb_demand_min)
FROM diffusion_shared.urdb_rates_by_state_res
where rate_id_alias not in 
	(815, 2090, 80, 523, 452, 844, 1857, 2034, 2306, 888, 1368, 974, 1031, 
	471, 1856, 1165, 1325, 1271, 40, 1831, 1966, 277, 751, 1512, 154, 275, 
	1740, 2318, 1853, 1163, 333, 784, 1172, 321, 1626, 527, 1207, 233, 
	1492, 98, 1851, 1737, 292, 874, 218, 1979, 1372, 1427, 45, 2330, 956, 
	1161, 414, 785, 1084, 1298, 2145, 1449, 2094, 413, 1792, 149, 1182, 
	1791, 186, 1330, 953, 2154)
group by state_abbr
order by 1;
-- should all be the same huge number and 49 rows

with a AS
(
	select state_abbr, ST_Union(ST_MakeLine(ST_MakePoint(0,urdb_demand_min),
			    ST_MakePoint(0, urdb_demand_max))) as span
	from diffusion_shared.urdb_rates_by_state_res
	where rate_id_alias not in 
		(815, 2090, 80, 523, 452, 844, 1857, 2034, 2306, 888, 1368, 974, 1031, 
		471, 1856, 1165, 1325, 1271, 40, 1831, 1966, 277, 751, 1512, 154, 275, 
		1740, 2318, 1853, 1163, 333, 784, 1172, 321, 1626, 527, 1207, 233, 
		1492, 98, 1851, 1737, 292, 874, 218, 1979, 1372, 1427, 45, 2330, 956, 
		1161, 414, 785, 1084, 1298, 2145, 1449, 2094, 413, 1792, 149, 1182, 
		1791, 186, 1330, 953, 2154)
	GROUP BY state_abbr
),
b as 
(
	SELECT state_abbr, ST_Covers(span,
					ST_MakeLine(ST_MakePoint(0,0),
					ST_MakePoint(0, 1e+99))) as covers

	FROM a
)
SELECT *
FROM b 
where covers = false;


-- COMMERCIAL
--check mins
select min(urdb_demand_min)
FROM diffusion_shared.urdb_rates_by_state_com
where rate_id_alias not in 
	(815, 2090, 80, 523, 452, 844, 1857, 2034, 2306, 888, 1368, 974, 1031, 
	471, 1856, 1165, 1325, 1271, 40, 1831, 1966, 277, 751, 1512, 154, 275, 
	1740, 2318, 1853, 1163, 333, 784, 1172, 321, 1626, 527, 1207, 233, 
	1492, 98, 1851, 1737, 292, 874, 218, 1979, 1372, 1427, 45, 2330, 956, 
	1161, 414, 785, 1084, 1298, 2145, 1449, 2094, 413, 1792, 149, 1182, 
	1791, 186, 1330, 953, 2154)
group by state_abbr
order by 1 desc;
-- should be zero in all cases

select state_abbr, max(urdb_demand_max)
FROM diffusion_shared.urdb_rates_by_state_com
where rate_id_alias not in 
	(815, 2090, 80, 523, 452, 844, 1857, 2034, 2306, 888, 1368, 974, 1031, 
	471, 1856, 1165, 1325, 1271, 40, 1831, 1966, 277, 751, 1512, 154, 275, 
	1740, 2318, 1853, 1163, 333, 784, 1172, 321, 1626, 527, 1207, 233, 
	1492, 98, 1851, 1737, 292, 874, 218, 1979, 1372, 1427, 45, 2330, 956, 
	1161, 414, 785, 1084, 1298, 2145, 1449, 2094, 413, 1792, 149, 1182, 
	1791, 186, 1330, 953, 2154)
group by state_abbr
order by 2 asc;
-- should all be the same huge number
-- not quite: in ME, coverage is only up to 10000000000 kw (10000 GW), but this is so high, it should be fine

select state_abbr, max(urdb_demand_max-urdb_demand_min)
FROM diffusion_shared.urdb_rates_by_state_com
where rate_id_alias not in 
	(815, 2090, 80, 523, 452, 844, 1857, 2034, 2306, 888, 1368, 974, 1031, 
	471, 1856, 1165, 1325, 1271, 40, 1831, 1966, 277, 751, 1512, 154, 275, 
	1740, 2318, 1853, 1163, 333, 784, 1172, 321, 1626, 527, 1207, 233, 
	1492, 98, 1851, 1737, 292, 874, 218, 1979, 1372, 1427, 45, 2330, 956, 
	1161, 414, 785, 1084, 1298, 2145, 1449, 2094, 413, 1792, 149, 1182, 
	1791, 186, 1330, 953, 2154)
group by state_abbr
order by 2 asc;
-- should all be the same huge number
-- not quite: in ME, coverage is only up to 10000000000 kw (10000 GW), but this is so high, it should be fine

-- check that htere is full coverage from 0 to 1e99
with a AS
(
	select state_abbr, ST_Union(ST_MakeLine(ST_MakePoint(0,urdb_demand_min),
			    ST_MakePoint(0, urdb_demand_max))) as span
	from diffusion_shared.urdb_rates_by_state_com
	where rate_id_alias not in 
		(815, 2090, 80, 523, 452, 844, 1857, 2034, 2306, 888, 1368, 974, 1031, 
		471, 1856, 1165, 1325, 1271, 40, 1831, 1966, 277, 751, 1512, 154, 275, 
		1740, 2318, 1853, 1163, 333, 784, 1172, 321, 1626, 527, 1207, 233, 
		1492, 98, 1851, 1737, 292, 874, 218, 1979, 1372, 1427, 45, 2330, 956, 
		1161, 414, 785, 1084, 1298, 2145, 1449, 2094, 413, 1792, 149, 1182, 
		1791, 186, 1330, 953, 2154)
	GROUP BY state_abbr
),
b as 
(
	SELECT state_abbr, ST_Covers(span,
					ST_MakeLine(ST_MakePoint(0,0),
					ST_MakePoint(0, 1e+99))) as covers

	FROM a
)
SELECT *
FROM b 
where covers = false;

-- not quite: in ME, coverage is only up to 10000000000 kw (10000 GW), but this is so high, it should be fine

-- INDUSTRIAL
--check mins
select min(urdb_demand_min)
FROM diffusion_shared.urdb_rates_by_state_ind
where rate_id_alias not in 
	(815, 2090, 80, 523, 452, 844, 1857, 2034, 2306, 888, 1368, 974, 1031, 
	471, 1856, 1165, 1325, 1271, 40, 1831, 1966, 277, 751, 1512, 154, 275, 
	1740, 2318, 1853, 1163, 333, 784, 1172, 321, 1626, 527, 1207, 233, 
	1492, 98, 1851, 1737, 292, 874, 218, 1979, 1372, 1427, 45, 2330, 956, 
	1161, 414, 785, 1084, 1298, 2145, 1449, 2094, 413, 1792, 149, 1182, 
	1791, 186, 1330, 953, 2154)
group by state_abbr
order by 1 desc;
-- should be zero in all cases

select max(urdb_demand_max)
FROM diffusion_shared.urdb_rates_by_state_ind
where rate_id_alias not in 
	(815, 2090, 80, 523, 452, 844, 1857, 2034, 2306, 888, 1368, 974, 1031, 
	471, 1856, 1165, 1325, 1271, 40, 1831, 1966, 277, 751, 1512, 154, 275, 
	1740, 2318, 1853, 1163, 333, 784, 1172, 321, 1626, 527, 1207, 233, 
	1492, 98, 1851, 1737, 292, 874, 218, 1979, 1372, 1427, 45, 2330, 956, 
	1161, 414, 785, 1084, 1298, 2145, 1449, 2094, 413, 1792, 149, 1182, 
	1791, 186, 1330, 953, 2154)
group by state_abbr
order by 1 asc;
-- should all be the same huge number

select state_abbr, max(urdb_demand_max-urdb_demand_min)
FROM diffusion_shared.urdb_rates_by_state_ind
where rate_id_alias not in 
	(815, 2090, 80, 523, 452, 844, 1857, 2034, 2306, 888, 1368, 974, 1031, 
	471, 1856, 1165, 1325, 1271, 40, 1831, 1966, 277, 751, 1512, 154, 275, 
	1740, 2318, 1853, 1163, 333, 784, 1172, 321, 1626, 527, 1207, 233, 
	1492, 98, 1851, 1737, 292, 874, 218, 1979, 1372, 1427, 45, 2330, 956, 
	1161, 414, 785, 1084, 1298, 2145, 1449, 2094, 413, 1792, 149, 1182, 
	1791, 186, 1330, 953, 2154)
group by state_abbr
order by 2 asc;
-- should all be the same huge number

-- check that htere is full coverage
with a AS
(
	select state_abbr, ST_Union(ST_MakeLine(ST_MakePoint(0,urdb_demand_min),
			    ST_MakePoint(0, urdb_demand_max))) as span
	from diffusion_shared.urdb_rates_by_state_ind
	where rate_id_alias not in 
		(815, 2090, 80, 523, 452, 844, 1857, 2034, 2306, 888, 1368, 974, 1031, 
		471, 1856, 1165, 1325, 1271, 40, 1831, 1966, 277, 751, 1512, 154, 275, 
		1740, 2318, 1853, 1163, 333, 784, 1172, 321, 1626, 527, 1207, 233, 
		1492, 98, 1851, 1737, 292, 874, 218, 1979, 1372, 1427, 45, 2330, 956, 
		1161, 414, 785, 1084, 1298, 2145, 1449, 2094, 413, 1792, 149, 1182, 
		1791, 186, 1330, 953, 2154)
	GROUP BY state_abbr
),
b as 
(
	SELECT state_abbr, ST_Covers(span,
					ST_MakeLine(ST_MakePoint(0,0),
					ST_MakePoint(0, 1e+99))) as covers

	FROM a
)
SELECT *
FROM b 
where covers = false;
-- same issue as COM, but should be fine since only ME has a smaller demand max, and it is still 10,000 GW