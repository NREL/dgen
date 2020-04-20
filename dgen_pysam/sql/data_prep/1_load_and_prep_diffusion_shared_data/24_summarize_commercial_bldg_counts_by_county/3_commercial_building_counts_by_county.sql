set role 'diffusion-writers';

-- note: the HAZUS commercial buildings total about 7.5 million, while CBECS 2012 lists only 5.5 million bldgs
-- so for consistency, we need to recalibrate the HAZUS county sums so that they total to the
-- census division totals from CBECS 2012

DROP TABLE IF EXISTS diffusion_shared.commercial_bldgs_count_by_county;
CREATe TABLE diffusion_shared.commercial_bldgs_count_by_county AS
WITH a as
(
	SELECT b.state_fips, b.county_fips, sum(bldg_count_com) as count_bldgs
	FROM diffusion_blocks.block_bldg_counts a
	LEFT JOIN diffusion_blocks.block_geoms b
	ON a.pgid = b.pgid
	GROUP BY b.state_fips, b.county_fips
),
b as
(
	SELECT b.county_id, a.state_fips, a.county_fips, b.census_division_abbr,
		count_bldgs
	FROM a
	LEFT JOIN diffusion_blocks.county_geoms b
	ON a.state_fips = b.state_fips
	and a.county_fips = b.county_fips
),
c as
(
	select b.county_id, b.state_fips, b.county_fips, b.census_division_abbr,
			count_bldgs::NUMERIC/sum(count_bldgs) OVER (PARTITION BY b.census_division_abbr) as county_portion,
			c.bldg_count as census_div_bldg_count
	FROM b
	left join eia.cbecs_2012_building_counts_by_census_division c
	ON b.census_division_abbr = c.census_division_abbr
)
select county_id, state_fips, county_fips, census_division_abbr, county_portion * census_div_bldg_count as bldg_count
FROM c;

-- add primary key on county_id
alter table diffusion_shared.commercial_bldgs_count_by_county
ADD PRIMARY KEY (county_id);

-- add index on state fips and county fips
CREATE INDEX commercial_bldgs_count_by_county_btree_state_fips
ON diffusion_shared.commercial_bldgs_count_by_county
USING BTREE(state_fips);

CREATE INDEX commercial_bldgs_count_by_county_btree_county_fips
ON diffusion_shared.commercial_bldgs_count_by_county
USING BTREE(county_fips);

-- check sums by census division abbr
with a as
(
	select census_division_abbr, round(sum(bldg_count),0) as bldg_count_est
	from diffusion_shared.commercial_bldgs_count_by_county
	group by census_division_abbr
)
select a.census_division_abbr, bldg_count_est, bldg_count as bldg_count_act
from  a
left join eia.cbecs_2012_building_counts_by_census_division b
on a.census_division_abbr = b.census_division_abbr;
-- all values match
