-- CHECK COMPLETENESS OF ALL TABLES

-----------------------------------------------------------------------------------------------------
-- BLOCKS
-----------------------------------------------------------------------------------------------------
SELECT COUNT(*) FROM hazus.hzbldgcountoccupb; -- 11098632
SELECT COUNT(*) FROM hazus.hzsqfootageoccupb; -- 11098632
SELECT COUNT(*) FROM hazus.hz_census_block; -- 11096649
-- something is screwy..

-- check for mismatches
select count(*)
FROM hazus.hzbldgcountoccupb a
FULL OUTER join  hazus.hzsqfootageoccupb b
ON a.censusblock = b.censusblock
where a.censusblock is null
or b.censusblock is null;
-- 0 -- the "data" tables match perfectly

select count(*)
FROM hazus.hzsqfootageoccupb a
FULL OUTER join  hazus.hz_census_block b
ON a.censusblock = b.censusblock
where a.censusblock is null
or b.censusblock is null;
-- 35 tracts are missing from the geom table

-- can we use the Census 2010 blocks instead??
set role 'dgeo-writers';
DROP TABLE IF EXISTS dgeo.hazus_blocks_to_census2010_blocks;
CREATE TABLE dgeo.hazus_blocks_to_census2010_blocks
(
	state_abbr varchar(2),
	blocks_in_census_missing_from_hazus integer,
	blocks_in_hazus_missing_from_census integer
);

DO LANGUAGE plpgsql $$
	-- get the state ids
	DECLARE recs CURSOR FOR 
				select table_name, right(table_name, 2) as state_abbr
				from tablenames('census_2010') t
				WHERE t like 'block_geom_%'
				and t <> 'block_geom_pr'
				AND length(t) = 13;
	BEGIN
		for rec in recs loop
			execute 
			'INSERT INTO dgeo.hazus_blocks_to_census2010_blocks
			
			 SELECT ''' || rec.state_abbr || ''' AS state_abbr, 
				sum((b.censusblock is null)::INTEGER), 
				sum((a.geoid10 is null)::INTEGER)
			from census_2010.block_geom_' || rec.state_abbr || ' a
			FULL OUTER JOIN hazus.hzbldgcountoccupb_' || rec.state_abbr || ' b
			ON a.geoid10 = b.censusblock
			WHERE a.aland10 > 0
			AND (b.res1i + b.res2i + b.res3ai + b.res3bi + 
				b.res3ci + b.res3di + b.res3ei + b.res3fi + 
				b.res4i + b.res5i + b.res6i + b.com1i + 
				b.com2i + b.com3i + b.com4i + b.com5i + 
				b.com6i + b.com7i + b.com8i + b.com9i + 
				b.com10i + b.ind1i + b.ind2i + b.ind3i + 
				b.ind4i + b.ind5i + b.ind6i + b.agr1i + 
				b.rel1i + b.gov1i + b.gov2i + b.edu1i + b.edu2i) > 0;
			';
		end loop;
end$$;


-- check results
select *
FROM dgeo.hazus_blocks_to_census2010_blocks;
-- PERFECT MATCH!!!!!

-----------------------------------------------------------------------------------------------------
-- TRACTS
-----------------------------------------------------------------------------------------------------
-- make sure row counts match across tables
SELECT COUNT(*) FROM hazus.hzbldgcountoccupt; -- 73669
SELECT COUNT(*) FROM hazus.hzsqfootageoccupt; -- 73669
SELECT COUNT(*) FROM hazus.hz_tract; -- 73634
-- same issue as with blocks -- geom table is inconsistent

-- check for mismatches
select count(*)
FROM hazus.hzsqfootageoccupt a
FULL OUTER join  hazus.hzbldgcountoccupt b
ON a.tract = b.tract
where a.tract is null
or b.tract is null;
-- 0 -- the "data" tables match perfectly

select count(*)
FROM hazus.hzsqfootageoccupt a
FULL OUTER join  hazus.hz_tract b
ON a.tract = b.tract
where a.tract is null
or b.tract is null;
-- 35 tracts are missing from the tract table

-- can we use the Census 2010 tracts instead??
set role 'dgeo-writers';
DROP TABLE IF EXISTS dgeo.hazus_tracts_to_census2010_tracts;
CREATE TABLE dgeo.hazus_tracts_to_census2010_tracts as
select sum((b.tract is null)::INTEGER) as tracts_in_census_missing_from_hazus,
	sum((a.geoid10 is null)::INTEGER) as tracts_in_hazus_missing_from_census
from census_2010.geometries_tract a
FULL OUTER JOIN hazus.hzbldgcountoccupt b
	ON a.geoid10 = b.tract
WHERE a.aland10 > 0
AND (b.res1i + b.res2i + b.res3ai + b.res3bi + 
	b.res3ci + b.res3di + b.res3ei + b.res3fi + 
	b.res4i + b.res5i + b.res6i + b.com1i + 
	b.com2i + b.com3i + b.com4i + b.com5i + 
	b.com6i + b.com7i + b.com8i + b.com9i + 
	b.com10i + b.ind1i + b.ind2i + b.ind3i + 
	b.ind4i + b.ind5i + b.ind6i + b.agr1i + 
	b.rel1i + b.gov1i + b.gov2i + b.edu1i + b.edu2i) > 0;
	
-- check results
select *
FROM dgeo.hazus_tracts_to_census2010_tracts;
-- PERFECT MATCH!!!!!

------------------------------------------------------------------------------------------

-- CONCLUSIONS:
-- HAZUS "data" tables (building counts and square footage) appear to be complete and consistent
-- however, HAZUS geometry tables are missing data (and HAZUS blocks have been edited with NLCD
-- to erase all ladn that isn't developed or agricultural.
-- fortunately, the data tables do seem to line up completely with the Census 2010 blocks
-- and tracts, so we can use those instead (in census_2010 schema).

-- SOLUTION: Use Census 2010 block and tract geoms instead of hazus geom tables
-- next steps:
	-- add gisjoin column to HAZUS data tables (with index)
	-- mark rows without any buildings