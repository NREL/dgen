-- calculate rates

-- use the ventyx sales data, where it was directly joined to ventyx polygons
-- in remaining areas, backfill with state averages

-- to isolate the remaining areas:
	-- Create view of just the ventyx polygons that were directly joined to sales data
	CREATE OR REPLACE VIEW dg_wind.ests_not_backfilled_geoms as
	SELECT gid as est_gid, the_geom_4326
	FROM dg_wind.ventyx_elec_serv_territories_w_2011_sales_data_backfilled_clip
	where company_id <> -99999;
	-- export to shapefile
		--> F:\data\mgleason\DG_Wind\Data\Analysis\electricity_rates\ests_not_backfilled_geoms.shp
	DROP VIEW dg_wind.ests_not_backfilled_geoms;
	-- Clip the snapped ventyx states_and_provinces.shp (F:\data\mgleason\DG_Wind\Data\Analysis\Ventyx\0p0005_integrate\snapped\states_and_provinces.shp)
		-- to the dissolved county_geoms.shp (F:\data\mgleason\DG_Wind\Data\Analysis\county_boundaries\county_geom_dissolved.shp)
		--> F:\data\mgleason\DG_Wind\Data\Analysis\Ventyx\0p0005_integrate\snapped\states_and_provinces_county_geom_clip.shp
	-- Erase ests_not_backfilled_geoms.shp   from   states_and_provinces_county_geom_clip.shp 
		--> use xy tolerance of 0.005 decimal degrees
		--> F:\data\mgleason\DG_Wind\Data\Analysis\electricity_rates\ests_rate_gaps.shp
	-- Reload to postgres
		--> dg_wind.ests_rate_gaps


DROP TABLE IF EXISTS dg_wind.electricity_rates_2011_backfilled;
CREATE TABLE dg_wind.electricity_rates_2011_backfilled AS
SELECT company_id, state_abbr, the_geom_4326,
	CASE WHEN total_residential_revenue_000s = 0 and total_residential_sales_mwh = 0 THEN NULL
	   ElSE (total_residential_revenue_000s*1000*100)/(total_residential_sales_mwh*1000)
	 end as res_cents_per_kwh,

	CASE WHEN total_commercial_revenue_000s = 0 and total_commercial_sales_mwh = 0 THEN NULL
	   ElSE (total_commercial_revenue_000s*1000*100)/(total_commercial_sales_mwh*1000)
	 end as comm_cents_per_kwh,

	CASE WHEN total_industrial_revenue_000s = 0 and total_industrial_sales_mwh = 0 THEN NULL
	   ElSE (total_industrial_revenue_000s*1000*100)/(total_industrial_sales_mwh*1000)
	 end as ind_cents_per_kwh,
	 data_year,
	 source
FROM dg_wind.ventyx_elec_serv_territories_w_2011_sales_data_backfilled_clip
where source = 'Ventyx Sales Data Join'  -- only for directly joined ventyx data -- not for backfilled state level remainders	 

UNION
-- back fill the rest with 2011 state level averages from eia table 4
SELECT -99999 as company_id, a.abbrev as state_abbr, a.the_geom_4326,
	b.res as res_cents_per_kwh,
	b.com as com_cents_per_kwh,
	b.ind as ind_cents_per_kwh,
       2011 as data_year,
       'EIA Table 4 Rates by State 2011'::text as source
FROM dg_wind.ests_rate_gaps a
LEFT JOIN eia.table_4_rates_by_state_2011 b
ON a.name = b.state;

CREATE INDEX electricity_rates_2011_backfilled_the_geom_4326_gist ON dg_wind.electricity_rates_2011_backfilled using gist(the_geom_4326);

-- fix geoms
UPDATE dg_wind.electricity_rates_2011_backfilled
SET the_geom_4326 = ST_Buffer(the_geom_4326,0.0)
where ST_IsValid(the_geom_4326) = False;

-- add geom for 900914 and index
ALTER TABLE dg_wind.electricity_rates_2011_backfilled ADD COLUMN the_geom_900914 geometry;
UPDATE dg_wind.electricity_rates_2011_backfilled  
SET the_geom_900914 = ST_Transform(the_geom_4326,900914);

CREATE INDEX electricity_rates_2011_backfilled_the_geom_900914_gist ON dg_wind.electricity_rates_2011_backfilled using gist(the_geom_900914);

ALTER TABLE dg_wind.electricity_rates_2011_backfilled ADD COLUMN gid serial;

-- export to shapefile 
	-->F:\data\mgleason\DG_Wind\Data\Analysis\electricity_rates\electricity_rates_2011_backfilled.shp
-- in ArcGIS, convert to a coverage
	-->F:\data\mgleason\DG_Wind\Data\Analysis\electricity_rates\rates_cov
-- Then back to a shapefile
	--> F:\data\mgleason\DG_Wind\Data\Analysis\electricity_rates\ests_no_overlaps.shp
-- delete all columns from the shapefile -- we only care about the geometry
-- reload the shapefile
	 -->dg_wind.est_rate_geoms_no_overlaps
-- any bad geoms?
SELECT st_isvalidreason(the_geom_4326)
FROM dg_wind.est_rate_geoms_no_overlaps
where ST_Isvalid(the_geom_4326) = false;

-- if so, repair the geometry

-- add spatial indices on st centroid and st point on surface
-- DROP spatial index
DROP INDEX dg_wind.est_rate_geoms_no_overlaps_the_geom_4326_gist;
ALTER TABLE dg_wind.est_rate_geoms_no_overlaps ALTER the_geom_4326 type geometry;
-- fix broken geometries
UPDATE dg_wind.est_rate_geoms_no_overlaps
SET the_geom_4326 = ST_Buffer(the_geom_4326,0)
where ST_Isvalid(the_geom_4326) = false;
-- make sure they were all fixed
SELECT st_isvalidreason(the_geom_4326)
FROM dg_wind.est_rate_geoms_no_overlaps
where ST_Isvalid(the_geom_4326) = false;
-- re-create spatial index
CREATE INDEX est_rate_geoms_no_overlaps_the_geom_4326_gist
  ON dg_wind.est_rate_geoms_no_overlaps
  USING gist
  (the_geom_4326);

 
-- add column for point on surface
ALTER TABLE dg_wind.est_rate_geoms_no_overlaps ADD COLUMN the_point_on_surface_4326 geometry;
-- populate that column
UPDATE dg_wind.est_rate_geoms_no_overlaps
SET the_point_on_surface_4326 = ST_PointOnSurface(the_geom_4326); -- need to do it this way because the_geom_4326 has invalid geoms and if i try to fix them, polygons disappear
-- create spatial index
CREATE INDEX est_rate_geoms_no_overlaps_the_geom_4326_pointonsurface_gist ON dg_wind.est_rate_geoms_no_overlaps USING gist(the_point_on_surface_4326);


-- then intersect the centroid/point on surface against the original data, 
-- and populate the rates based on averages of all intersections
DROP TABLE IF EXISTS dg_wind.electricity_rates_2011_backfilled_no_overlaps;
CREATE TABLE dg_wind.electricity_rates_2011_backfilled_no_overlaps AS
WITH ix AS (
SELECT a.gid, a.the_geom_4326, 
	b.company_id, b.state_abbr, b.res_cents_per_kwh, b.comm_cents_per_kwh, 
       b.ind_cents_per_kwh, b.data_year, b.source
FROM dg_wind.est_rate_geoms_no_overlaps a
INNER JOIN dg_wind.electricity_rates_2011_backfilled b
ON ST_Intersects(a.the_point_on_surface_4326,b.the_geom_4326))

SELECT gid, the_geom_4326, array_agg(company_id) as company_id, first(state_abbr) as state_abbr,
	avg(res_cents_per_kwh) as res_cents_per_kwh,
	avg(comm_cents_per_kwh) as comm_cents_per_kwh,
	avg(ind_cents_per_kwh) as ind_cents_per_kwh,
	array_agg(data_year) as data_year, array_agg(source) as source
FROM ix
GROUP BY gid, the_geom_4326;
-- 

-- inspect results in Q -- looks good

-- **
-- move results to diffusion_shared
-- ALTER TABLE diffusion_shared.annual_ave_elec_rates_2011 RENAME TO annual_ave_elec_rates_2011_old;
-- ALTER TABLE diffusion_shared.annual_ave_elec_rates_2011_old SET SCHEMA wind_ds_data;
dROP TABLE IF EXISTS diffusion_shared.annual_ave_elec_rates_2011;
CREATE TABLE diffusion_shared.annual_ave_elec_rates_2011 AS
SELECT *
FROM dg_wind.electricity_rates_2011_backfilled_no_overlaps;

CREATE INDEX annual_ave_elec_rates_2011_the_geom_4326_gist ON diffusion_shared.annual_ave_elec_rates_2011 USING gist(the_geom_4326);

ALTER TABLE diffusion_shared.annual_ave_elec_rates_2011 ADD PRIMARY KEY (gid);

-- **
ALTER TABLE diffusion_shared.annual_ave_elec_rates_2011 
ADD COLUMN the_geom_900914 geometry,
ADD COLUMN the_geom_900915 geometry,
ADD COLUMN the_geom_900916 geometry;

UPDATE diffusion_shared.annual_ave_elec_rates_2011
SET (the_geom_900914, the_geom_900915, the_geom_900916) = (ST_Transform(the_geom_4326,900914),ST_Transform(the_geom_4326,900915),ST_Transform(the_geom_4326,900916));

CREATE INDEX annual_ave_elec_rates_2011_the_geom_900914_gist ON diffusion_shared.annual_ave_elec_rates_2011 USING gist(the_geom_900914);
CREATE INDEX annual_ave_elec_rates_2011_the_geom_900915_gist ON diffusion_shared.annual_ave_elec_rates_2011 USING gist(the_geom_900915);
CREATE INDEX annual_ave_elec_rates_2011_the_geom_900916_gist ON diffusion_shared.annual_ave_elec_rates_2011 USING gist(the_geom_900916);

CREATE INDEX annual_ave_elec_rates_2011_ind_rates_btree ON diffusion_shared.annual_ave_elec_rates_2011 USING btree(ind_cents_per_kwh)
where ind_cents_per_kwh is null;

CREATE INDEX annual_ave_elec_rates_2011_res_rates_btree ON diffusion_shared.annual_ave_elec_rates_2011 USING btree(res_cents_per_kwh)
where res_cents_per_kwh is null;

CREATE INDEX annual_ave_elec_rates_2011_comm_rates_btree ON diffusion_shared.annual_ave_elec_rates_2011 USING btree(comm_cents_per_kwh)
where comm_cents_per_kwh is null;

VACUUM ANALYZE diffusion_shared.annual_ave_elec_rates_2011;

-- check that there are no zero rates
select *
FROM diffusion_shared.annual_ave_elec_rates_2011
where comm_cents_per_kwh = 0