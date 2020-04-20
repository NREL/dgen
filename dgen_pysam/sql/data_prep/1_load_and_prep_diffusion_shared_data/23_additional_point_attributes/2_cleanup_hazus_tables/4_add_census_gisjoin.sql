set role 'hazus-writers';

-- add gisjoin column to HAZUS data tables (with index)

------------------------------------------------------------------------------------------------------------
-- TRACTS
------------------------------------------------------------------------------------------------------------
-- count table
ALTER TABLE hazus.hzbldgcountoccupt
ADD COLUMN census_2010_gisjoin varchar(14);

UPDATE hazus.hzbldgcountoccupt a
set census_2010_gisjoin = b.gisjoin
FROM census_2010.geometries_tract b
where a.tract = b.geoid10;
-- 73669

-- how many nulls (that have bldgs)
select count(*)
FROM hazus.hzbldgcountoccupt
where has_bldgs = True
and census_2010_gisjoin is null;
-- 0 --  all set

-- add index
CREATE INDEX hzbldgcountoccupt_btree_census_2010_gisjoin
ON hazus.hzbldgcountoccupt
USING BTREE(census_2010_gisjoin);


ALTER TABLE hazus.hzsqfootageoccupt
ADD COLUMN census_2010_gisjoin varchar(14);

UPDATE hazus.hzsqfootageoccupt a
set census_2010_gisjoin = b.gisjoin
FROM census_2010.geometries_tract b
where a.tract = b.geoid10;

-- how many nulls (that have bldgs)
select count(*)
FROM hazus.hzsqfootageoccupt
where has_bldgs = True
and census_2010_gisjoin is null;
-- 0 --  all set

-- add index
CREATE INDEX hzsqfootageoccupt_btree_census_2010_gisjoin
ON hazus.hzsqfootageoccupt
USING BTREE(census_2010_gisjoin);

------------------------------------------------------------------------------------------------------------
-- BLOCKS
------------------------------------------------------------------------------------------------------------

--------------------------------------------------------------
-- **** NEED TO RUN THIS WHEN JULIANS PROCESSES FINISH ****
--------------------------------------------------------------
-- attribute state tables (using loop)
DO LANGUAGE plpgsql $$
	-- get the state ids
	DECLARE recs CURSOR FOR 
				select table_name, right(table_name, 2) as state_abbr
				from tablenames('hazus') t
				WHERE t like 'hzbldgcountoccupb_%'
				OR t like 'hzsqfootageoccupb_%'
				ORDER BY 1;
	BEGIN
		for rec in recs loop
			execute 
			
			'ALTER TABLE hazus.'|| rec.table_name || ' 
			 ADD COLUMN census_2010_gisjoin varchar(18);

			 UPDATE hazus.'|| rec.table_name || ' a
			 SET census_2010_gisjoin = b.gisjoin
			 FROM census_2010.block_geom_'|| rec.state_abbr || ' b
			 where a.censusblock = b.geoid10;
			-- 73669

			 CREATE INDEX '|| rec.table_name || '_btree_gisjoin 
			 ON hazus.'|| rec.table_name || ' 
			 USING BTREE(census_2010_gisjoin);
			';
		end loop;
end$$;


-- add column to parent tables
ALTER TABLE hazus.hzsqfootageoccupb
ADD COLUMN census_2010_gisjoin varchar(18);

ALTER TABLE hazus.hzbldgcountoccupb
ADD COLUMN census_2010_gisjoin varchar(18);

-- check that it worked
select count(*)
FROM hazus.hzsqfootageoccupb
where has_bldgs = True
and census_2010_gisjoin is null;
-- 0 -- all set

select count(*)
FROM hazus.hzsqfootageoccupb
where has_bldgs = True
and census_2010_gisjoin is null;
-- 0 -- all set

