-- the urdb_to_sam.py script incorrectly named the ur_ec_enable and ur_dc_enable
-- fields as ec_enable and dc_enable
-- this script corrects those names in the sam_json cols

-- ***********************************************************************************************

-- THIS SCRIPT IS NO LONGER NECESSARY BECAUSEE urdb_to_sam.py WAS UPDATED TO FIX THIS ON THE FLY)

-- ***********************************************************************************************
-- set role 'urdb_rates-writers'; 

-- -- backup the original sam json tables
-- CREATE TABLE urdb_rates.urdb3_singular_rates_sam_data_20141202_backup AS
-- SELECT *
-- FROM urdb_rates.urdb3_singular_rates_sam_data_20141202;

-- CREATE TABLE urdb_rates.urdb3_verified_rates_sam_data_20141202_backup AS
-- SELECT *
-- FROM urdb_rates.urdb3_verified_rates_sam_data_20141202;

-- -- fix the incorrectly named fields
-- UPDATE urdb_rates.urdb3_singular_rates_sam_data_20141202
-- SET sam_json = REPLACE(replace(sam_json::text, 'ec_enable',  'ur_ec_enable'), 'dc_enable', 'ur_dc_enable')::json;

-- UPDATE urdb_rates.urdb3_verified_rates_sam_data_20141202
-- SET sam_json = REPLACE(replace(sam_json::text, 'ec_enable',  'ur_ec_enable'), 'dc_enable', 'ur_dc_enable')::json;