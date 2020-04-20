-- Need to account for climate zones in CA because rates are based off of these zones


--------------------------------------------------------
-- CLIMATE ZONES
--------------------------------------------------------
-- Filter to see what utilities are in CA 
with a as (
	select a.utility_name, b.state_fips, a.uri
	FROM urdb_rates.urdb3_verified_rates_sam_data_20161005 a
	right join
	urdb_rates.urdb_utility_eia_and_county_ids_lkup_20161005 b
	on a.rate_id_alias = b.rate_id_alias
	where b.state_fips like '06')
	select distinct utility_name from a
	-- RESULTS (Utilities in CA)
		-- Note: I think we can ignore the climate zones for any utiliy starting with "City of ..."; This includes:
			--"City of Biggs, California (Utility Company)"
			--"City & County of San Francisco (Utility Company)"
			--"City of Palo Alto, California (Utility Company)"
			--"City of Anaheim, California (Utility Company)"
			--"City of Needles, California (Utility Company)"
			--"City of Pasadena, California (Utility Company)"
			--"City of Ukiah, California (Utility Company)"
			--"City of Riverside, California (Utility Company)"
			--"City of Santa Clara, California (Utility Company)"
			--"Tuolumne County Pub Power Agny"
		-- we can also probably ignore these since they are city-wide still
			--"Bear Valley Electric Service"
			--"Turlock Irrigation District"
			--"Sacramento Municipal Utility District"
			--"Los Angeles Department of Water & Power"
			--"Lassen Municipal Utility District"
		-- this leaves us with the following to look into:
			--"PacifiCorp"
			--"Pacific Gas & Electric Co"
			--"Southern California Edison Co"
			--"San Diego Gas & Electric Co"
			--"Western Area Power Administration"


	with a as (
		select a.rate_id_alias, a.rate_name, a.utility_name, b.state_fips, a.uri
		FROM urdb_rates.urdb3_verified_rates_sam_data_20161005 a
		right join
		urdb_rates.urdb_utility_eia_and_county_ids_lkup_20161005 b
		on a.rate_id_alias = b.rate_id_alias
		where b.state_fips like '06')
		select distinct rate_id_alias, utility_name, rate_name from a
		where a.rate_name like '%Region%' and utility_name in ('PacifiCorp', 'Pacific Gas & Electric Co', 'Southern California Edison Co', 'San Diego Gas & Electric Co', 'Western Area Power Administration')
		order by utility_name, rate_name;
		--3643;"Pacific Gas & Electric Co";"E-1 -Residential Service Baseline Region Q"
		--3644;"Pacific Gas & Electric Co";"E-1 -Residential Service Baseline Region R"
		--3645;"Pacific Gas & Electric Co";"E-1 -Residential Service Baseline Region S"
		--3646;"Pacific Gas & Electric Co";"E-1 -Residential Service Baseline Region T"
		--3647;"Pacific Gas & Electric Co";"E-1 -Residential Service Baseline Region V"
		--3648;"Pacific Gas & Electric Co";"E-1 -Residential Service Baseline Region W"
		--3649;"Pacific Gas & Electric Co";"E-1 -Residential Service Baseline Region X"
		--3650;"Pacific Gas & Electric Co";"E-1 -Residential Service Baseline Region Y"
		--3651;"Pacific Gas & Electric Co";"E-1 -Residential Service Baseline Region Z"
		--3652;"Pacific Gas & Electric Co";"E-TOU Option A - Residential Time of Use Service Baseline Region P"
		--3639;"Pacific Gas & Electric Co";"E-TOU Option A - Residential Time of Use Service Baseline Region Q"
		--3635;"Pacific Gas & Electric Co";"E-TOU Option A - Residential Time of Use Service Baseline Region R"
		--3636;"Pacific Gas & Electric Co";"E-TOU Option A - Residential Time of Use Service Baseline Region S"
		--3640;"Pacific Gas & Electric Co";"E-TOU Option A - Residential Time of Use Service Baseline Region T"
		--3633;"Pacific Gas & Electric Co";"E-TOU Option A - Residential Time of Use Service Baseline Region V"
		--3637;"Pacific Gas & Electric Co";"E-TOU Option A - Residential Time of Use Service Baseline Region W"
		--3638;"Pacific Gas & Electric Co";"E-TOU Option A - Residential Time of Use Service Baseline Region X"
		--3641;"Pacific Gas & Electric Co";"E-TOU Option A - Residential Time of Use Service Baseline Region Y"
		--3642;"Pacific Gas & Electric Co";"E-TOU Option A - Residential Time of Use Service Baseline Region Z"
		--3634;"Pacific Gas & Electric Co";"E-TOU Option B - Residential Time of Use Service (All Baseline Regions)"
		--4132;"San Diego Gas & Electric Co";"DR - Coastal Baseline Region"
		--4136;"San Diego Gas & Electric Co";"DR - Desert Baseline Region"
		--4134;"San Diego Gas & Electric Co";"DR - Inland Baseline Region"
		--4137;"San Diego Gas & Electric Co";"DR-LI - Coastal Baseline Region"
		--4139;"San Diego Gas & Electric Co";"DR-LI - Desert Baseline Region"
		--4138;"San Diego Gas & Electric Co";"DR-LI - Inland Baseline Region"
		--4133;"San Diego Gas & Electric Co";"DR-LI - Mountain Baseline Region"
		--4135;"San Diego Gas & Electric Co";"DR - Mountain Baseline Region"
		--4140;"San Diego Gas & Electric Co";"TOU-DR Coastal Baseline Region"
		--4143;"San Diego Gas & Electric Co";"TOU-DR Desert Baseline Region"
		--4141;"San Diego Gas & Electric Co";"TOU-DR Inland Baseline Region"
		--4142;"San Diego Gas & Electric Co";"TOU-DR Mountain Baseline Region"
		--4263;"Southern California Edison Co";"Domestic Service: D - Baseline Region 10"
		--4269;"Southern California Edison Co";"Domestic Service: D - Baseline Region 13"
		--4270;"Southern California Edison Co";"Domestic Service: D - Baseline Region 14"
		--4271;"Southern California Edison Co";"Domestic Service: D - Baseline Region 15"
		--4272;"Southern California Edison Co";"Domestic Service: D - Baseline Region 16"
		--4266;"Southern California Edison Co";"Domestic Service: D - Baseline Region 5"
		--4267;"Southern California Edison Co";"Domestic Service: D - Baseline Region 6"
		--4262;"Southern California Edison Co";"Domestic Service: D - Baseline Region 8"
		--4268;"Southern California Edison Co";"Domestic Service: D - Baseline Region 9"
		--4275;"Southern California Edison Co";"Time-of-use Tiered Domestic: TOU-D-T-Region 10"
		--4276;"Southern California Edison Co";"Time-of-use Tiered Domestic: TOU-D-T - Region 13"
		--4277;"Southern California Edison Co";"Time-of-use Tiered Domestic: TOU-D-T - Region 14"
		--4278;"Southern California Edison Co";"Time-of-use Tiered Domestic: TOU-D-T - Region 15"
		--4279;"Southern California Edison Co";"Time-of-use Tiered Domestic: TOU-D-T - Region 16"
		--4264;"Southern California Edison Co";"Time-of-use Tiered Domestic: TOU-D-T-Region 5"
		--4265;"Southern California Edison Co";"Time-of-use Tiered Domestic: TOU-D-T - Region 6"
		--4273;"Southern California Edison Co";"Time-of-use Tiered Domestic: TOU-D-T - Region 8"
		--4274;"Southern California Edison Co";"Time-of-use Tiered Domestic: TOU-D-T - Region 9"
		--5273;"Western Area Power Administration";"Desert Southwest Region Boulder Canyon Project AZ"
		--5274;"Western Area Power Administration";"Desert Southwest Region Intertie Project"

		-- this leaves us with the following to look into:
			--"Pacific Gas & Electric Co"
			--"Southern California Edison Co"
			--"San Diego Gas & Electric Co"
			--"Western Area Power Administration"

	--------------
	-- SCE
	--------------
	-- for SCE:
	-- see: https://www.sce.com/wps/wcm/connect/f08b847c-4d53-4a5b-9612-b1678187ba0c/Baseline_Region_Map.pdf?MOD=AJPERES
	-- the codes used and boundaries seem to line up nearly exactly with the official cliamte zones
	-- one exception is that a Northern portion of the official climate zones 14 is coded as climate zone 15 by SCE
	-- I think we can ignore this consering the map from SCE is out of date, this is not a high pop density area,
	-- and the climate is probalby pretty similar to 14 (so rates shouldn't vary a ton)

	-- Methods - Parse up the counties by climate zone and apply these zones as the geometries
		-- pt. 1 (update geometry and add index)
		create index ca_climate_zones_20141202_gist on urdb_rates.ca_climate_zones_20141202 using gist(the_geom_96703);
		-- pt. 2 intersect
		drop table if exists urdb_rates.county_utility_regions_sce_geoms;
		create table urdb_rates.county_utility_regions_sce_geoms as (
			with pge_counties as (
				with a as (select distinct utility_name, eia_id from urdb_rates.urdb3_verified_rates_sam_data_20161005 
					where utility_name = 'Southern California Edison Co' and rate_name like '%Region%')-- note- we are excluding the "All Regions" rate with alias 3634
				select distinct a.eia_id, a.utility_name, b.county_fips, b.the_geom_96703 from
				a left join urdb_rates.utility_county_geoms_20161005 b 
				on a.eia_id = b.eia_id),
			intersection as (
			select a.eia_id, a.utility_name, a.county_fips, b.climate_zone, st_intersection(a.the_geom_96703, b.the_geom_96703) as the_geom_96703
			from pge_counties a
			inner join urdb_rates.ca_climate_zones_20141202 b
			on st_intersects(a.the_geom_96703, b.the_geom_96703))
			select eia_id, utility_name, county_fips, climate_zone, st_makevalid(st_collectionextract(st_union(the_geom_96703), 3))
			from intersection group by eia_id, utility_name, county_fips, climate_zone order by county_fips, climate_zone);

		-- associate the rates to the appropriate regions
		drop table if exists urdb_rates.county_utility_regions_sce;
		create table urdb_rates.county_utility_regions_sce as (
			with a as (select utility_name, eia_id, rate_id_alias, rate_name from urdb_rates.urdb3_verified_rates_sam_data_20161005 
				where utility_name = 'Southern California Edison Co' and rate_name like '%Region%') -- note- we are excluding the "All Regions" rate with alias 3634
			select a.rate_id_alias, a.rate_name, NULL::text as utility_region, b.*
			from a
			left join urdb_rates.county_utility_regions_sce_geoms b 
			on a.eia_id = b.eia_id);

		update urdb_rates.county_utility_regions_sce
			set utility_region = case
				when rate_id_alias = '4263' then '10'
				when rate_id_alias = '4269' then '13'
				when rate_id_alias = '4270' then '14'
				when rate_id_alias = '4271' then '15'
				when rate_id_alias = '4272' then '16'
				when rate_id_alias = '4266' then '05'
				when rate_id_alias = '4267' then '06'
				when rate_id_alias = '4262' then '08'
				when rate_id_alias = '4268' then '09'
				when rate_id_alias = '4275' then '10'
				when rate_id_alias = '4276' then '13'
				when rate_id_alias = '4277' then '14'
				when rate_id_alias = '4278' then '15'
				when rate_id_alias = '4279' then '16'
				when rate_id_alias = '4264' then '05'
				when rate_id_alias = '4265' then '06'
				when rate_id_alias = '4273' then '08'
				when rate_id_alias = '4274' then '09'
				END;
		
		-- Remove counties that do not fall within the climate zone that the rate applies to
		delete from urdb_rates.county_utility_regions_sce where utility_region != climate_zone;

		-- Delete old county geometries from lkup and geom table
		-- Part 1 -- delete the counties outside of the climate zone
			with a as (select a.* from urdb_rates.urdb_utility_eia_and_county_ids_lkup_20161005 a
				right join urdb_rates.county_utility_regions_sce b
				on a.rate_id_alias = b.rate_id_alias
				where a.cnty_fips != b.county_fips and a.rate_id_alias = b.rate_id_alias)
			delete from urdb_rates.urdb_utility_eia_and_county_ids_lkup_20161005 where rate_id_alias in (select rate_id_alias from a) and cnty_fips in (select cnty_fips from a);

		-- Part 2 -- delete all county geoms with the rate_id_alias fields that have regions (we will join these new geometries later)
		delete from urdb_rates.utility_county_geoms_20161005 where rate_id_alias in ('4263','4269','4270','4271','4272','4266','4267','4262','4268','4275','4276','4277','4278','4279','4264','4265','4273','4274');
	
	--------------
	-- SDGE
	--------------
	-- for SDGE: 
	-- see http://www.sdge.com/baseline-allowance-calculator
	-- CA_Coastal = intersection of SDGE with zones 06, 07, and 08
	-- CA_Inland = intersection of SDGE with zone 10
	-- CA_Mountain = intersection of SDGE with zone 14
	-- CA_Desert = intersection of SDGE with zone 15

	-- Part 1 -- Parse up counties by climate zone and select only appropriate zones
	-- Part 2 -- Replace Geomtries in geom table (do this during merge)
	-- Part 3 -- Remove counties that do not apply to the rate in the lkup table

	drop table if exists urdb_rates.county_utility_regions_sde;
	create table urdb_rates.county_utility_regions_sde as (
		with mountain as (
			with u as (select * from urdb_rates.utility_county_geoms_20161005 where rate_id_alias in ('4133', '4135', '4142')),
			mountain_climate_geom as (select * from urdb_rates.ca_climate_zones_20141202 where climate_zone = '14')
			select a.rate_id_alias, a.eia_id, a.state_fips, a.county_fips, a.county, 
				a.state, a.state_abbr, a.geoid10, 'Mountain'::text as utility_region, '14'::text as climate_zone,
				st_intersection(a.the_geom_96703, b.the_geom_96703) as the_geom_96703
			from u a
			inner join mountain_climate_geom b
			on st_intersects(a.the_geom_96703, b.the_geom_96703)),
		coastal as (
			with u as (select * from urdb_rates.utility_county_geoms_20161005 where rate_id_alias in ('4132', '4137', '4140')),
			mountain_climate_geom as (select * from urdb_rates.ca_climate_zones_20141202 where climate_zone in ('06', '07', '08'))
			select a.rate_id_alias, a.eia_id, a.state_fips, a.county_fips, a.county, 
				a.state, a.state_abbr, a.geoid10, 'Coastal'::text as utility_region, '06, 07, 08'::text as climate_zone,
				st_intersection(a.the_geom_96703, b.the_geom_96703) as the_geom_96703
			from u a
			inner join mountain_climate_geom b
			on st_intersects(a.the_geom_96703, b.the_geom_96703)),
		inland as (
			with u as (select * from urdb_rates.utility_county_geoms_20161005 where rate_id_alias in ('4134', '4138', '4141')),
			mountain_climate_geom as (select * from urdb_rates.ca_climate_zones_20141202 where climate_zone = '10')
			select a.rate_id_alias, a.eia_id, a.state_fips, a.county_fips, a.county, 
				a.state, a.state_abbr, a.geoid10, 'Inland'::text as utility_region, '10'::text as climate_zone,
				st_intersection(a.the_geom_96703, b.the_geom_96703) as the_geom_96703
			from u a
			inner join mountain_climate_geom b
			on st_intersects(a.the_geom_96703, b.the_geom_96703)),
		desert as (
					with u as (select * from urdb_rates.utility_county_geoms_20161005 where rate_id_alias in ('4136', '4139', '4143')),
			mountain_climate_geom as (select * from urdb_rates.ca_climate_zones_20141202 where climate_zone = '15')
			select a.rate_id_alias, a.eia_id, a.state_fips, a.county_fips, a.county, 
				a.state, a.state_abbr, a.geoid10, 'Desert'::text as utility_region, '15'::text as climate_zone,
				st_intersection(a.the_geom_96703, b.the_geom_96703) as the_geom_96703
			from u a
			inner join mountain_climate_geom b
			on st_intersects(a.the_geom_96703, b.the_geom_96703))
		select * from mountain union all
		select * from coastal union all
		select * from inland union all
		select * from desert);

	-- delete county 059 for desert and mountain regions (lkup table)
	delete from urdb_rates.urdb_utility_eia_and_county_ids_lkup_20161005
		where (rate_id_alias in ('4136', '4139', '4143', '4133', '4135', '4142') and (cnty_fips = '059'));
	-- delete all rate_id_alias geometries because we will join the urdb_rates.county_utility_regions_sde later during a union all
	delete from urdb_rates.utility_county_geoms_20161005
		where rate_id_alias in ('4136', '4139', '4143', '4133', '4135', '4142', '4132', '4137', '4140', '4134', '4138', '4141');



	--------------
	-- WAPA
	--------------
	-- Desert Southwest region only
	-- https://www.wapa.gov/regions/DSW/Pages/dsw.aspx
	-- Not using the "climate zones" boundaries here
	-- Looks like I need to apply only the southwest CA counties to this region
		-- no systematic way to do this. Performing filter based on eye-balling/ best judgement
		-- note: eyeballing is pretty straightforward here because the eia-to-county-mapping shows a clear division between the southwest ca counties and the counties belonging to other regions
		-- Imperial, Riverside, and San Bernardino

	-- Part 1 -- delete the counties outside of the southwest region in the lookup table
	with a as (
		select a.*, b.state_abbr from urdb_rates.urdb_utility_eia_and_county_ids_lkup_20161005 a
		left join urdb_rates.utility_county_geoms_20161005 b
		on a.rate_id_alias = b.rate_id_alias and a.state_fips = b.state_fips
		where a.rate_id_alias in ('5273', '5274') and a.cnty_fips not in ('065', '071','025') and b.state_abbr not in ('06', '04', '32'))
	delete from urdb_rates.urdb_utility_eia_and_county_ids_lkup_20161005
		where (rate_id_alias in (select rate_id_alias from a) and cnty_fips in (select cnty_fips from a) and state_fips in (select state_fips from a))
	-- Part 2 -- delete the counties outside of the SW region in the geometry table (note --> do not need to join these new geoms to during union all)
	with a as (
		select a.*, b.state_abbr from urdb_rates.utility_county_geoms_20161005 a
		left join urdb_rates.utility_county_geoms_20161005 b
		on a.rate_id_alias = b.rate_id_alias and a.state_fips = b.state_fips
		where a.rate_id_alias in ('5273', '5274') and a.county_fips not in ('065', '071','025') and b.state_abbr not in ('06', '04', '32'))
	delete from urdb_rates.utility_county_geoms_20161005
		where (rate_id_alias in (select rate_id_alias from a) and county_fips in (select county_fips from a) and state_fips in (select state_fips from a))


	--------------
	-- PGE
	--------------
	-- see http://www.pge.com/baseline/#
	-- http://www.pge.com/nots/rates/PGECZ_90Rev.pdf
		-- Source: http://www.pge.com/includes/docs/pdfs/about/edusafety/training/pec/toolbox/arch/climate/california_climate_zones_01-16.pdf
	-- this one is really wonky and doesnt line up very well
	-- but PGE publishes a zipcode to baselien territory lookup table that we can use instead:
		-- http://www.pge.com/tariffs/RESZIPS.XLS

		-- load the zip to baseline lookup table
		DROP TABLE IF EXISTS urdb_rates.pge_zip_to_baseline;
		CREATE TABLE urdb_rates.pge_zip_to_baseline (
			zipcode character varying(5),
			baseline_territory text,
			service_agreement_count integer,
			percentage numeric,
			notes text);

		set role 'server-superusers';
		COPY urdb_rates.pge_zip_to_baseline FROM '/srv/home/mgleason/data/dg_wind/pge_zip_to_baseline_territory.csv' 
		with csv header;
		SEt role 'urdb_rates-writers';

		-- manually add a few more to ensure full coverage of the pge territory
		-- note: these are based on visual inspection and best guesses at the correct territory for each of the added zips
		INSErT INTO urdb_rates.pge_zip_to_baseline (baseline_territory, zipcode)
			VALUES 
			('Y','96130'),
			('Y','96119'),
			('Y','96122'),
			('Y','96103'),
			('Y','96124'),
			('Y','96126'),
			('Z','96161'),
			('P','96146'),
			('P','96141'),
			('P','96142'),
			('Z','96150'),
			('Z','96155'),
			('Y','96120'),
			('Y','95646'),
			('Y','95373'),
			('R','93271'),
			('R','93262'),
			('R','93271'),
			('W','93222'),
			('W','93225'),
			('W','93536'),
			('W','93518'),
			('W','93215'),
			('X','94128'),
			('X','94592');

		-- dissolve the zipcodes into single polygons for each territory
		DROP TABLE IF EXISTS urdb_rates.pge_zip_to_baseline_geoms;
		CREATE TABLE urdb_rates.pge_zip_to_baseline_geoms as
		with a as
		(
			-- the lookup table indicates some zipcodes cross territories
			-- for our purposes, it will be good enough to simply pick the 
			-- majority territory for each zipcode
			select distinct on (zipcode) zipcode, baseline_territory
			FROM urdb_rates.pge_zip_to_baseline a
			order by zipcode, percentage desc
		)
			SELECT a.baseline_territory, (ST_Dump(ST_Union(b.the_geom_4326))).geom as the_geom_4326
			FROM a
			inner JOIN shapes.zip_polys_20141005 b
			ON a.zipcode = b.zip
			GROUP BY a.baseline_territory;

		-- intersect these with the PGE boundaries from ventyx
		-- pt. 1 (update geometry and add index)
			alter table urdb_rates.pge_zip_to_baseline_geoms
				add column the_geom_96703 geometry;
			update urdb_rates.pge_zip_to_baseline_geoms
				set the_geom_96703 = st_transform(the_geom_4326, 96703);
			create index pge_zip_to_baseline_geoms_gist on urdb_rates.pge_zip_to_baseline_geoms using gist(the_geom_96703);
		-- pt. 2 intersect
		drop table if exists urdb_rates.county_utility_regions_pge_geoms;
		create table urdb_rates.county_utility_regions_pge_geoms as (
			with pge_counties as (
				with a as (select distinct utility_name, eia_id from urdb_rates.urdb3_verified_rates_sam_data_20161005 
					where utility_name = 'Pacific Gas & Electric Co' and rate_name like '%Region%' and rate_id_alias != '3634')-- note- we are excluding the "All Regions" rate with alias 3634
				select distinct a.eia_id, a.utility_name, b.county_fips, b.the_geom_96703 from
				a left join urdb_rates.utility_county_geoms_20161005 b 
				on a.eia_id = b.eia_id),
			intersection as (
			select a.eia_id, a.utility_name, a.county_fips, b.baseline_territory, st_intersection(a.the_geom_96703, b.the_geom_96703) as the_geom_96703
			from pge_counties a
			inner join urdb_rates.pge_zip_to_baseline_geoms b
			on st_intersects(a.the_geom_96703, b.the_geom_96703))
			select eia_id, utility_name, county_fips, baseline_territory, st_makevalid(st_collectionextract(st_union(the_geom_96703), 3))
			from intersection group by eia_id, utility_name, county_fips, baseline_territory order by county_fips, baseline_territory);

		-- associate the rates to the appropriate regions
		drop table if exists urdb_rates.county_utility_regions_pge;
		create table urdb_rates.county_utility_regions_pge as (
			with a as (select utility_name, eia_id, rate_id_alias, rate_name from urdb_rates.urdb3_verified_rates_sam_data_20161005 
				where utility_name = 'Pacific Gas & Electric Co' and rate_name like '%Region%' and rate_id_alias != '3634') -- note- we are excluding the "All Regions" rate with alias 3634
			select a.rate_id_alias, a.rate_name, NULL::text as utility_region, b.*
			from a
			left join urdb_rates.county_utility_regions_pge_geoms b 
			on a.eia_id = b.eia_id);
		update urdb_rates.county_utility_regions_pge
			set utility_region = case when rate_id_alias = '3652' then 'P'
				when rate_id_alias = '3639' then 'Q'
				when rate_id_alias = '3635' then 'R'
				when rate_id_alias = '3636' then 'S'
				when rate_id_alias = '3640' then 'T'
				when rate_id_alias = '3633' then 'V'
				when rate_id_alias = '3637' then 'W'
				when rate_id_alias = '3638' then 'X'
				when rate_id_alias = '3641' then 'Y'
				when rate_id_alias = '3642' then 'Z'
				when rate_id_alias = '3643' then 'Q'
				when rate_id_alias = '3644' then 'R'
				when rate_id_alias = '3645' then 'S'
				when rate_id_alias = '3646' then 'T'
				when rate_id_alias = '3647' then 'V'
				when rate_id_alias = '3648' then 'W'
				when rate_id_alias = '3649' then 'X'
				when rate_id_alias = '3650' then 'Y'
				when rate_id_alias = '3651' then 'Z'
				END;
		-- remove counties that do not belong to the rate's region
		delete from urdb_rates.county_utility_regions_pge where utility_region != baseline_territory

		
		-- Delete old county geometries from lkup and geom table
		-- Part 1 -- delete the counties outside of climate zone
			with a as (select a.* from urdb_rates.urdb_utility_eia_and_county_ids_lkup_20161005 a
				right join urdb_rates.county_utility_regions_pge b
				on a.rate_id_alias = b.rate_id_alias
				where a.cnty_fips != b.county_fips and a.rate_id_alias = b.rate_id_alias)
			delete from urdb_rates.urdb_utility_eia_and_county_ids_lkup_20161005 where rate_id_alias in (select rate_id_alias from a) and cnty_fips in (select cnty_fips from a)
		-- Part 2 -- delete all county geoms with the rate_id_alias fields that have regions
		delete from urdb_rates.utility_county_geoms_20161005 where rate_id_alias in ('3643','3644','3645','3646','3647','3648','3649','3650','3651','3652','3639','3635','3636','3640','3633','3637','3638','3641','3642')




---------------------
-- Update Geom Table
---------------------
		-- merge the geometry table that has been modified (modified to remove sde, sce, and pge geoms that have regions)
		-- to the new sde, sce, and pge geometries
		drop table if exists urdb_rates.temp;
		create table urdb_rates.temp as (
		with a as (
		select rate_id_alias, eia_id, state_fips, county_fips, county, state, state_abbr, geoid10, NULL::text as utility_region, the_geom_96703 from urdb_rates.utility_county_geoms_20161005),
		b as (
			select a.rate_id_alias, a.eia_id, '06'::text as state_fips, a.county_fips, b.county, 'California'::text as state, 'CA'::text as state_abbr,
			('06'||a.county_fips||'_'||a.utility_region)::text as geoid10, a.utility_region, a.the_geom_96703
			from urdb_rates.county_utility_regions_sde a
			left join diffusion_blocks.county_geoms b
			on '06' = b.state_fips and a.county_fips = b.county_fips),
		c as (
			select a.rate_id_alias, a.eia_id, '06'::text as state_fips, a.county_fips, b.county, 'California'::text as state, 'CA'::text as state_abbr,
			('06'||a.county_fips||'_'||a.utility_region)::text as geoid10, a.utility_region, a.st_makevalid as the_geom_96703
			from urdb_rates.county_utility_regions_sce a
			left join diffusion_blocks.county_geoms b
			on '06' = b.state_fips and a.county_fips = b.county_fips),
		d as (
			select a.rate_id_alias, a.eia_id, '06'::text as state_fips, a.county_fips, b.county, 'California'::text as state, 'CA'::text as state_abbr,
			('06'||a.county_fips||'_'||a.utility_region)::text as geoid10, a.utility_region, a.st_makevalid as the_geom_96703
			from urdb_rates.county_utility_regions_pge a
			left join diffusion_blocks.county_geoms b
			on '06' = b.state_fips and a.county_fips = b.county_fips)
		select * from a union all select * from b union all select * from c union all select * from d);
		
		-- remove old geom table and update new table to have the same name
		drop table if exists urdb_rates.utility_county_geoms_20161005;
		alter table urdb_rates.temp
		rename to utility_county_geoms_20161005;

		-- add gid column
		alter table urdb_rates.utility_county_geoms_20161005
		add column gid serial;

		-- create indices
		create index utility_county_geoms_20161005_gist on urdb_rates.utility_county_geoms_20161005 using gist(the_geom_96703);
		create index utility_county_geoms_20161005_rate_id_alias_btree on urdb_rates.utility_county_geoms_20161005 using btree(rate_id_alias);
		create index utility_county_geoms_20161005_geoid10_btree on urdb_rates.utility_county_geoms_20161005 using btree(geoid10);
		create index utility_county_geoms_20161005_gid_btree on urdb_rates.utility_county_geoms_20161005 using btree(gid);



------------------------------------------------------------------------------
--- Things TO THINK about
-- 1. What about other "region" specific rates? outside of CA? -- e.g. Corn Belt Energy Coorporation
-- 2. What about the county islands in CA?
-- do I want to fix geometry table so that there are not extra geometries? Or will this make the spatial analysis confusing?
-- make sure all tables are set to 'diffusion-writers'


-- QAQC where Region is in the name of the rate 
		--2080;"Corn Belt Energy Corporation";"Industrial Substation RATE ("ISR") (Central Region)"
		--2083;"Corn Belt Energy Corporation";"RATE 14 Electric Heat for Commercial (Central Region)"
		--2082;"Corn Belt Energy Corporation";"RATE 19 Electric Heat (Northern Region)"
		--2079;"Corn Belt Energy Corporation";"RATE 1 Residential & Farm Service (Central Region)"
		--2084;"Corn Belt Energy Corporation";"RATE 3 General Service - Single-Phase (Central Region)"
		--2085;"Corn Belt Energy Corporation";"RATE 3 General Service - Single-Phase (Northern Region)"
		--2086;"Corn Belt Energy Corporation";"RATE 5 General Service over 50 kW Demand (Central Region)"
		--2081;"Corn Belt Energy Corporation";"Small Industrial Substation Rate ("SISR") (Central Region)"

------------------------------------------------------------------------------