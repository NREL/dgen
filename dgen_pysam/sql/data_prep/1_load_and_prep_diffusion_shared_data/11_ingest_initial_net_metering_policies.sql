DROP TABLE IF EXISTS diffusion_shared.net_metering_availability_2013;
CREATE TABLE diffusion_shared.net_metering_availability_2013 (
	state text,
	nem_grade character varying(2),
	sector character varying(3),
	utility_type character varying(9),
	nem_system_limit_kw float
);

SET ROLE 'server-superusers';
COPY diffusion_shared.net_metering_availability_2013 FROM '/home/mgleason/data/dg_wind/NetMeterAvail.csv' with csv header;
RESET ROLE;

ALTER TABLE diffusion_shared.net_metering_availability_2013 
DROP COLUMN nem_grade,
ADD COLUMN state_abbr character varying(2);

UPDATE diffusion_shared.net_metering_availability_2013 a
SET state_abbr = b.state_abbr
FROM esri.dtl_state_20110101 b
WHERE a.state = b.state_name;

-- add in values for utility_type = 'All Other'
INSERT INTO diffusion_shared.net_metering_availability_2013 (state_abbr, sector, utility_type, nem_system_limit_kw) 
SELECT state_abbr, sector, 'All Other'::text as utility_type, 0:: float as nem_system_limit_kw
FROM diffusion_shared.net_metering_availability_2013
GROUP BY state_abbr, sector;

CREATE INDEX net_metering_availability_2013_state_abbr_btree ON diffusion_shared.net_metering_availability_2013
USING btree(state_abbr);

CREATE INDEX net_metering_availability_2013_utility_type_btree ON diffusion_shared.net_metering_availability_2013
USING btree(utility_type);

CREATE INDEX net_metering_availability_2013_sector_btree ON diffusion_shared.net_metering_availability_2013
USING btree(sector);

ALTER TABLE diffusion_shared.net_metering_availability_2013 ADD PRIMARY KEY (state_abbr, sector, utility_type);

ALTER TABLE diffusion_shared.net_metering_availability_2013 
DROP COLUMN state;

-----------------------------------------------------------------
