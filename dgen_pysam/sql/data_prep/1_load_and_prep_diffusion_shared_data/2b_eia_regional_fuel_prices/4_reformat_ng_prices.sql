set role 'diffusion-writers';

DROP TABLE IF EXISTS diffusion_shared.eia_state_avg_ng_prices_2014;
CREATE TABLE diffusion_shared.eia_state_avg_ng_prices_2014 AS
select a.year, b.state_abbr, a.sector, a.sector_abbr, a.cents_per_ccf
FROM eia.avg_ng_price_by_state_by_sector_1967_2014 a
LEFT JOIN diffusion_shared.state_abbr_lkup b
ON a.state = b.state
where year = 2014
And a.state <> 'U.S.';


ALTER TABLe diffusion_shared.eia_state_avg_ng_prices_2014
ADD PRIMARY KEY (year, state_abbr, sector_abbr);

-- check for nulls
select *
FROM diffusion_shared.eia_state_avg_ng_prices_2014
where cents_per_ccf is null;
-- only null is DC/Ind sector

-- can we fill with data from a neighboring state?
select *
FROM diffusion_shared.eia_state_avg_ng_prices_2014
where state_abbr in ('DC', 'MD', 'DE' , 'VA');
-- DC prices are closest to DE for res and com

UPDATE diffusion_shared.eia_state_avg_ng_prices_2014
set cents_per_ccf = 109.5
where state_abbr = 'DC'
and cents_per_ccf is null
and sector_abbr = 'ind';