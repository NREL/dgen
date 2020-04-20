-- set role
set role 'urdb_rates-writers';

-- check whether the utilities associated with the new rates are
-- already mapped in the urdb3_verified_and_singular_ur_names_20141202 table
with a as
(
	SELECT distinct(a.ur_name) as ur_name
	FROM urdb_rates.urdb3_verified_rates_sam_data_20151028 a
	LEFT JOIN urdb_rates.urdb3_verified_rates_lookup_20151028 b
	ON a.rate_id_alias = b.rate_id_alias
	where b.state_code = 'ME'
)
select *
from a
LEFT JOIN urdb_rates.urdb3_verified_and_singular_ur_names_20141202 b
ON a.ur_name = b.ur_name;
-- yes, so no changes are necessary to the table
-- if there were changes necessary, refer to ../9_linking_urdb_to_ventyx.sql for logic for how to fill them in



-- since we are all set, simply create a new copy of the table with the updated time stamp
DROP TABLE IF EXISTS urdb_rates.urdb3_verified_and_singular_ur_names_20151028;
CREATE TABLE urdb_rates.urdb3_verified_and_singular_ur_names_20151028 AS
SELECT *
FROM urdb_rates.urdb3_verified_and_singular_ur_names_20141202;

ALTER TABLE urdb_rates.urdb3_verified_and_singular_ur_names_20151028
ADD PRIMARY KEY (ur_name);

-- check that there is full coverage in the actual ventyx territories table
select *
from urdb_rates.urdb3_verified_and_singular_ur_names_20151028 a
left join urdb_rates.ventyx_electric_service_territories_w_vs_rates_20141202 b
ON a.ventyx_company_id_2014 = b.company_id::text
where b.company_id is null;
-- nothing missing


-- load the territories to Q and specifically review the Maine Territories to make sure they are correct
-- compared to map provided by Pieter showing the maine territories -- things match up very well for the 3 utilities of interest
-- however, we still have polygons in there for other utilities. fortunately, this won't matter since
-- we only include polygons associated with rates in linking to point data
