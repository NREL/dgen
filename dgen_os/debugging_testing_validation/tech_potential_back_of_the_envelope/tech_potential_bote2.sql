with all_roof_options as
(
	select a.pubid8, 
		a.roof_style, a.roof_sqft,
		b.uid as roof_char_uid, b.prob_weight
	from diffusion_shared.eia_microdata_cbecs_2003 a
	left join diffusion_solar.rooftop_characteristics b
	ON a.roof_style = b.roof_style
	and sector_abbr = 'com'
	where roof_sqft is not null
	and pba8 <> 1
),
selected_roof_options as
(
	select pubid8,
		 unnest(sample(array_agg(roof_char_uid ORDER BY roof_char_uid),
			1, -- sample size
			2 *  pubid8, -- random generator seed
			False, -- sample w/o replacement
			array_agg(prob_weight ORDER BY roof_char_uid))) as roof_char_uid
	FROM all_roof_options
	GROUP BY pubid8
),
available_roofs as
(
	select a.pubid8, a.adjwt8,
		a.roof_sqft * c.rooftop_portion * c.slope_area_multiplier as available_roof_sqft
	from diffusion_shared.eia_microdata_cbecs_2003 a
	INNER join selected_roof_options b
	ON a.pubid8 = b.pubid8
	left join diffusion_solar.rooftop_characteristics c
	on b.roof_char_uid = c.uid
)
select 14*sum(adjwt8*available_roof_sqft)/1000000000 as total_capacity_gw
from available_roofs; 
-- 540



with all_roof_options as
(
	select a.doeid, 
		a.roof_style, a.roof_sqft,
		b.uid as roof_char_uid, b.prob_weight
	from diffusion_shared.eia_microdata_recs_2009 a
	left join diffusion_solar.rooftop_characteristics b
	ON a.roof_style = b.roof_style
	and b.sector_abbr = 'res'
	where roof_sqft is not null
	and typehuq in (1,2) AND kownrent = 1
),
selected_roof_options as
(
	select doeid,
		 unnest(sample(array_agg(roof_char_uid ORDER BY roof_char_uid),
			1, -- sample size
			3 *  doeid, -- random generator seed
			False, -- sample w/o replacement
			array_agg(prob_weight ORDER BY roof_char_uid))) as roof_char_uid
	FROM all_roof_options
	GROUP BY doeid
),
available_roofs as
(
	select a.doeid, a.nweight,
		a.roof_sqft * c.rooftop_portion * c.slope_area_multiplier as available_roof_sqft
	from diffusion_shared.eia_microdata_recs_2009 a
	INNER join selected_roof_options b
	ON a.doeid = b.doeid
	left join diffusion_solar.rooftop_characteristics c
	on b.roof_char_uid = c.uid
)
select 14*sum(nweight*available_roof_sqft)/1000000000 as total_capacity_gw
from available_roofs; 
-- 800