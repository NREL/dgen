DROP TABLE IF EXISTS diffusion_shared.max_market_share;
CREATE TABLE diffusion_shared.max_market_share (
	years_to_payback integer,
	max_market_share_new numeric,
	max_market_share_retrofit numeric,
	sector text,
	source text);

SET ROLE 'server-superusers';
COPY diffusion_shared.max_market_share FROM '/srv/home/mgleason/data/dg_wind/MaxMarketShare_simplified.csv' with csv header;
RESET ROLE;

CREATE INDEX max_market_share_sector_btree ON diffusion_shared.max_market_share USING btree(sector);
CREATE INDEX max_market_share_source_btree ON diffusion_shared.max_market_share USING btree(source);
CREATE INDEX max_market_share_years_to_payback_btree ON diffusion_shared.max_market_share USING btree(years_to_payback);

-- add a secrtor_abbr column
ALTER TABLE diffusion_shared.max_market_share
ADD COLUMN sector_abbr varchar(3);

UPDATE diffusion_shared.max_market_share
set sector_abbr = case   when sector = 'residential' then 'res'::CHARACTER VARYING(3)
		when sector = 'commercial' then 'com'::CHARACTER VARYING(3)
		when sector = 'industrial' then 'ind'::CHARACTER VARYING(3)
	end;

-- make sure no nulls
select *
FROM diffusion_shared.max_market_share
where sector_abbr is null;
-- 0 rows



VACUUM ANALYZE diffusion_shared.max_market_share;

-- rename to be consistent with input sheet
-- duplicate commercial and name industrial
-- change input sheet options tfor consistency