set role 'hazus-writers';

-- mark rows without any buildings or 0 square footage
------------------------------------------------------------------------------------------
-- TRACTS
------------------------------------------------------------------------------------------
-- create a table that indicates which tracts have no square footage
DROP TABLE IF EXISTS hazus.tracts_without_bldgs;
CREATE TABLE hazus.tracts_without_bldgs AS
SELECT tract
FROM hazus.hzbldgcountoccupt
wherE (res1i + res2i + res3ai + res3bi + res3ci + res3di + res3ei + res3fi + res4i + res5i + res6i + 
	com1i + com2i + com3i + com4i + com5i + com6i + com7i + com8i + com9i + com10i + 
	ind1i + ind2i + ind3i + ind4i + ind5i + ind6i + 
	agr1i + 
	rel1i + 
	gov1i + gov2i + 
	edu1i + edu2i) = 0
-- 104 rows

-- add primary key
ALTER TABLE hazus.tracts_without_bldgs
ADD PRIMARY KEY (tract);

DROP TABLE IF EXISTS hazus.tracts_without_sqft;
CREATE TABLE hazus.tracts_without_sqft AS
SELECT tract
FROM hazus.hzsqfootageoccupt
where (res1f + res2f + res3af + res3bf + res3cf + res3df + res3ef + res3ff + res4f + res5f + res6f + 
	com1f + com2f + com3f + com4f + com5f + com6f + com7f + com8f + com9f + com10f + 
	ind1f + ind2f + ind3f + ind4f + ind5f + ind6f + 
	agr1f + 
	rel1f + 
	gov1f + gov2f + 
	edu1f + edu2f) = 0;
-- 92

-- add primary key
ALTER TABLE hazus.tracts_without_sqft
ADD PRIMARY KEY (tract);


-- why don't row counts match? do they overlap?
select *
from hazus.tracts_without_bldgs a
full outer join hazus.tracts_without_sqft b
ON a.tract = b.tract;
-- these are ALL cases where there are 0 buildings but > 0 sf
-- probably safer/more inclusive to use the buildings as the exclusion layer

-- look into one case
-- select  com4f 
-- FROM hazus.hzsqfootageoccupt
-- where tract = '21143980100'
-- 
-- select com4i
-- from hazus.hzbldgcountoccupt
-- where tract = '21143980100'


------------------------------------------------------------------------------------------
-- BLOCKS
------------------------------------------------------------------------------------------
-- create a table that indicates which tracts have no square footage
DROP TABLE IF EXISTS hazus.blocks_without_bldgs;
CREATE TABLE hazus.blocks_without_bldgs AS
SELECT censusblock
FROM hazus.hzbldgcountoccupb
wherE (res1i + res2i + res3ai + res3bi + res3ci + res3di + res3ei + res3fi + res4i + res5i + res6i + 
	com1i + com2i + com3i + com4i + com5i + com6i + com7i + com8i + com9i + com10i + 
	ind1i + ind2i + ind3i + ind4i + ind5i + ind6i + 
	agr1i + 
	rel1i + 
	gov1i + gov2i + 
	edu1i + edu2i) = 0
-- 4,224,024 rows

-- add primary key
ALTER TABLE hazus.blocks_without_bldgs
ADD PRIMARY KEY (censusblock);

DROP TABLE IF EXISTS hazus.blocks_without_sqft;
CREATE TABLE hazus.blocks_without_sqft AS
SELECT censusblock
FROM hazus.hzsqfootageoccupb
where (res1f + res2f + res3af + res3bf + res3cf + res3df + res3ef + res3ff + res4f + res5f + res6f + 
	com1f + com2f + com3f + com4f + com5f + com6f + com7f + com8f + com9f + com10f + 
	ind1f + ind2f + ind3f + ind4f + ind5f + ind6f + 
	agr1f + 
	rel1f + 
	gov1f + gov2f + 
	edu1f + edu2f) = 0;
-- 4,010,040 rows

-- add primary key
ALTER TABLE hazus.blocks_without_sqft
ADD PRIMARY KEY (censusblock);

-- why don't row counts match? do they overlap?
select sum((a.censusblock is null)::INTEGER), sum((b.censusblock is null)::INTEGER)
from hazus.blocks_without_bldgs a
full outer join hazus.blocks_without_sqft b
ON a.censusblock = b.censusblock;
-- these are ALL cases where there are 0 buildings but > 0 sf
-- probably safer/more inclusive to use the buildings as the exclusion layer

--------------------------------------------------------------------------------------------------------------
-- apply the *_without_bldgs tables as an exclusion on the raw data

-- TRACTS
-- (add an attribute "has_bldgs" T/F and an index)
ALTER TABLE hazus.hzbldgcountoccupt
ADD COLUMN has_bldgs boolean default true;

UPDATE hazus.hzbldgcountoccupt a
set has_bldgs = False
FROM hazus.tracts_without_bldgs b
WHERE a.tract = b.tract;
-- 104 rows -- correct number matchs above

ALTER TABLE hazus.hzsqfootageoccupt
ADD COLUMN has_bldgs boolean default true;

UPDATE hazus.hzsqfootageoccupt a
set has_bldgs = False
FROM hazus.tracts_without_bldgs b
WHERE a.tract = b.tract;
-- 104 rows -- correct number matchs above

-- add indices
CREATE INDEX hzsqfootageoccupt_btree_has_bldgs
ON  hazus.hzsqfootageoccupt
USING BTREE(has_bldgs)
WHERE has_bldgs = TRUE;

CREATE INDEX hzbldgcountoccupt_btree_has_bldgs
ON  hazus.hzbldgcountoccupt
USING BTREE(has_bldgs)
WHERE has_bldgs = TRUE;


-- BLOCKS
-- attribute state tables (using loop)
DO LANGUAGE plpgsql $$
	-- get the state ids
	DECLARE recs CURSOR FOR 
				select table_name
				from tablenames('hazus') t
				WHERE t like 'hzbldgcountoccupb_%'
				OR t like 'hzsqfootageoccupb_%'
				ORDER BY 1;
	BEGIN
		for rec in recs loop
			execute 
			
			'ALTER TABLE hazus.'|| rec.table_name || ' 
			 ADD COLUMN has_bldgs BOOLEAN DEFAULT TRUE;

			 UPDATE hazus.'|| rec.table_name || ' a
			 SET has_bldgs = False
			 FROM hazus.blocks_without_bldgs b
			 WHERE a.censusblock = b.censusblock;

			 CREATE INDEX '|| rec.table_name || '_btree_has_bldgs 
			 ON hazus.'|| rec.table_name || ' 
			 USING BTREE(has_bldgs)
			 WHERE has_bldgs = TRUE;
			';
		end loop;
end$$;

-- add column to parent tables
ALTER TABLE hazus.hzsqfootageoccupb
ADD COLUMN has_bldgs boolean;

ALTER TABLE hazus.hzbldgcountoccupb
ADD COLUMN has_bldgs boolean;

-- check that it worked
select count(*)
FROM hazus.hzsqfootageoccupb
where has_bldgs <> True
-- expect 4224024
-- returned value is 4224024 -- all set
select count(*)
FROM hazus.hzsqfootageoccupb
where has_bldgs <> True;
-- returned value is 4224024 -- all set