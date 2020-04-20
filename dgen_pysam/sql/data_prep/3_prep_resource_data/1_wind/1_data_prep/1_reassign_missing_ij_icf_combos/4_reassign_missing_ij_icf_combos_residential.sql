-- find all the points without valid i, j, icf combos
DROP TABLE IF EXISTS diffusion_wind_data.missing_ij_icf_res_points;
CREATE TABLE diffusion_wind_data.missing_ij_icf_res_points AS
SELECT a.gid, a.the_geom_96703, 
	b.raster_value, b.i, b.j, b.cf_bin
FROM diffusion_shared.pt_grid_us_res a

LEFT JOIN aws_2014.iii_jjj_cfbin_raster_lookup b
ON a.iiijjjicf_id = b.raster_value

LEFT JOIN aws_2014.ij_onshore_cf_bins c
ON b.i = c.i
and b.j = c.j
and b.cf_bin = c.cf_bin

where c.i is null; -- this filters down to the ones for which there is no matching i, j, icf combo with elev and tmy data
-- 0   points

-- ****** IF 0 PTS RETURNED, SKIP TO FINAL BLOCK OF QUERIES
-- ****** OTHERWISE, RUN EVEYTHING EXCEPT THE FINAL BLOCK OF QUERIES

CREATE INDEX missing_ij_icf_res_points_the_geom_96703_gist 
ON diffusion_wind_data.missing_ij_icf_res_points 
using gist(the_geom_96703);

-- find which points can be fixed by going up or down one cfbin in the same i j cell
DROP TABLE IF EXISTS diffusion_wind_data.res_points_adjusted_1cfbin;
CREATE TABLE diffusion_wind_data.res_points_adjusted_1cfbin AS
with same_cell as (
	SELECT a.*, 
		CASE WHEN b.cf_bin is not null then b.cf_bin -- 1 bin up
		     WHEN c.cf_bin is not null then c.cf_bin -- 1 bin down
		else null
		end as adjusted_cf_bin
	FROM diffusion_wind_data.missing_ij_icf_res_points a
	-- try same cell, 1 cfbin up
	LEFT JOIN aws_2014.ij_onshore_cf_bins b
	on a.i = b.i
	and a.j = b.j
	and lpad((a.cf_bin::integer + 30)::text, 4, '0') = b.cf_bin
	-- try same cell, 1 cfbin down
	LEFT JOIN aws_2014.ij_onshore_cf_bins c
	on a.i = c.i
	and a.j = c.j
	and lpad((a.cf_bin::integer - 30)::text, 4, '0') = c.cf_bin)
SELECT gid, i, j, cf_bin, adjusted_cf_bin
FROM same_cell
where adjusted_cf_bin is not null;
-- 533 rows (99% of the points)


DROP TABLE IF EXISTS diffusion_wind_data.res_points_adjusted_ij;
CREATE TABLE diffusion_wind_data.res_points_adjusted_ij AS
with unfixed as 
(
	SELECT a.gid, a.the_geom_96703, a.i, a.j, a.cf_bin
	FROM diffusion_wind_data.missing_ij_icf_res_points a
	LEFT JOIN diffusion_wind_data.res_points_adjusted_1cfbin b
	ON a.gid = b.gid
	where b.gid is null
),
near_cells As 
(
	SELECT a.*, unnest((select array(SELECT b.gid
			 FROM aws_2014.ij_polygons b
			 ORDER BY a.the_geom_96703 <#> b.the_geom_96703 LIMIT 9))) -- do 9 because the first one will always be the cell the point is located within
			as aws_gid
	FROM unfixed a
),
nn_ordered AS 
(
	select a.gid, a.the_geom_96703, 
		a.i, a.j, a.cf_bin,
		a.aws_gid, 
		b.i as near_i, 
		b.j as near_j, 
		row_number() OVER (PARTITION BY a.gid ORDER BY ST_Distance(a.the_geom_96703,b.the_geom_96703) asc) as nn_rank
	FROM near_cells a
	LEFT JOIN aws_2014.ij_polygons b
	ON a.aws_gid = b.gid
	where NOT(b.i = a.i and b.j = a.j)
),
nn_cfs as 
(
	select 	a.*, 
			CASE WHEN b.cf_bin is not null then b.cf_bin -- same cf bin
			     WHEN c.cf_bin is not null then c.cf_bin -- 1 bin up
			     WHEN d.cf_bin is not null then d.cf_bin -- 1 bin down
			else null
			end as adjusted_cf_bin

	FROM nn_ordered a
	-- try same cf bin
	LEFT JOIN aws_2014.ij_onshore_cf_bins b
	on a.near_i = b.i
	and a.near_j = b.j
	and a.cf_bin = b.cf_bin
	-- try 1 cfbin up
	LEFT JOIN aws_2014.ij_onshore_cf_bins c
	on a.near_i = c.i
	and a.near_j = c.j
	and lpad((a.cf_bin::integer + 30)::text, 4, '0') = c.cf_bin
	-- try 1 cf bin down
	LEFT JOIN aws_2014.ij_onshore_cf_bins d
	on a.near_i = d.i
	and a.near_j = d.j
	and lpad((a.cf_bin::integer - 30)::text, 4, '0') = d.cf_bin
)
SELECT distinct on (a.gid) a.gid, a.the_geom_96703, 
			   a.i, a.j, a.cf_bin, a.aws_gid, a.near_i, a.near_j, a.nn_rank, adjusted_cf_bin
FROM nn_cfs a
where adjusted_cf_bin is NOT null
order by a.gid, nn_rank asc;
-- 7 points


-- find everything that is still missing wind resource data
DROP TABLE IF EXISTS diffusion_wind_data.remaining_missing_res_points;
CREATE TABLE diffusion_wind_data.remaining_missing_res_points AS
SELECT a.*
FROM diffusion_wind_data.missing_ij_icf_res_points a
LEFT JOIN diffusion_wind_data.res_points_adjusted_ij b
ON a.gid = b.gid
lEFT JOIN diffusion_wind_data.res_points_adjusted_1cfbin c
ON a.gid = c.gid
where b.gid is null and c.gid is null;
-- 0   still have no data

-- -- doesn't apply
-- -- for the remaining points, pick the closest cfbin in the same ij cell
-- DROP TABLE IF EXISTS diffusion_wind_data.res_points_adjusted_multi_cfbins;
-- CREATE TABLE diffusion_wind_data.res_points_adjusted_multi_cfbins AS
-- SELECT distinct ON (a.gid) a.gid, a.the_geom_96703, a.i, a.j, a.cf_bin, 
--        b.cf_bin as adjusted_cf_bin
-- FROM diffusion_wind_data.remaining_missing_res_points a
-- LEFT JOIN aws_2014.ij_onshore_cf_bins b
-- ON a.i = b.i
-- and a.j = b.j
-- order by a.gid asc, @(a.cf_bin::integer-b.cf_bin::integer) asc;
-- 
-- -- make sure nothing is left
-- select count(*)
-- FROM diffusion_wind_data.res_points_adjusted_multi_cfbins
-- where adjusted_cf_bin is null;


-- combine all of these, along with non missing points, into a single lookup table
DROP TABLE IF EXISTS diffusion_wind.ij_cfbin_lookup_res_pts_us;
CREATE TABLE diffusion_wind.ij_cfbin_lookup_res_pts_us AS
with notmissing as 
(
	SELECT a.gid as pt_gid, b.i, b.j, b.cf_bin::integer/10 as cf_bin, 
		1::integer as aep_scale_factor
	FROM diffusion_shared.pt_grid_us_res a

	LEFT JOIN aws_2014.iii_jjj_cfbin_raster_lookup b
	ON a.iiijjjicf_id = b.raster_value

	LEFT JOIN aws_2014.ij_onshore_cf_bins c
	ON b.i = c.i
	and b.j = c.j
	and b.cf_bin = c.cf_bin

	where c.i is NOT null
),
adjusted_1cfbin as 
(
	SELECT gid as pt_gid, i, j, 
		adjusted_cf_bin::integer/10 as cf_bin, 
		(cf_bin::numeric+15)/(adjusted_cf_bin::numeric+15) as aep_scale_factor
	FROM diffusion_wind_data.res_points_adjusted_1cfbin
),
adjusted_ij AS 
(
	SELECT gid as pt_gid, near_i as i, near_j as j, 
		adjusted_cf_bin::integer/10 as cf_bin, 
		(cf_bin::numeric+15)/(adjusted_cf_bin::numeric+15) as aep_scale_factor
	FROM diffusion_wind_data.res_points_adjusted_ij
)--, 
-- adjusted_multi_cfbins as 
-- (
-- 	SELECT gid as pt_gid, i, j, 
-- 		adjusted_cf_bin::integer/10 as cf_bin, 
-- 		(cf_bin::numeric+15)/(adjusted_cf_bin::numeric+15) as aep_scale_factor --NOTE: AEP of Raster = AEP of Weather File * (CF of Raster/ CF of Weather File)
-- 	FROM diffusion_wind_data.res_points_adjusted_multi_cfbins
-- ) -- NOTE: Add 15 to all cfbin values because the value represents the bottom of a 3% (= 30 increment) bin. We want to compare the midpoints between different cf_bins
SELECT *
FROM notmissing

UNION ALL

SELECT *
FROM adjusted_1cfbin

UNION ALL

SELECT *
FROM adjusted_ij;

-- UNION ALL
-- 
-- SELECT *
-- FROM adjusted_multi_cfbins;
-- 6273234   rows
-- count should match diffusion_wind.pt_grid_us_res

SELECT count(*)
FROM diffusion_shared.pt_grid_us_res a
--6273234 rows (and it does!)


-- add primary
ALTER TABLE diffusion_wind.ij_cfbin_lookup_res_pts_us ADD PRIMARY KEY (pt_gid);
-- add foreign key
ALTER TABLE diffusion_wind.ij_cfbin_lookup_res_pts_us
  ADD CONSTRAINT pt_gid_fkey FOREIGN KEY (pt_gid)
      REFERENCES diffusion_shared.pt_grid_us_res (gid) MATCH FULL
      ON UPDATE resTRICT ON DELETE resTRICT;

-- add indices
CREATE INDEX ij_cfbin_lookup_res_pts_us_i_btree ON diffusion_wind.ij_cfbin_lookup_res_pts_us using btree(i);
CREATE INDEX ij_cfbin_lookup_res_pts_us_j_btree ON diffusion_wind.ij_cfbin_lookup_res_pts_us using btree(j);
CREATE INDEX ij_cfbin_lookup_res_pts_us_cf_bin_btree ON diffusion_wind.ij_cfbin_lookup_res_pts_us using btree(cf_bin);

-- check for scale factors of zero
select *
FROM diffusion_wind.ij_cfbin_lookup_res_pts_us
where aep_scale_factor = 0;
-- do any occur? if so, figure out why
-- none


-- test that everything worked
SELECT a.gid, b.i, b.j, b.cf_bin, b.aep_scale_factor, c.aep as aep_raw, c.aep*b.aep_scale_factor as aep_adjusted
FROM diffusion_shared.pt_grid_us_res a
LEFT JOIN diffusion_wind.ij_cfbin_lookup_res_pts_us b
on a.gid = b.pt_gid
LEFT JOIN diffusion_wind.wind_resource_annual c
ON b.i = c.i
and b.j = c.j
and b.cf_bin = c.cf_bin
where c.height = 50
and c.turbine_id = 1
 and b.aep_scale_factor <> 1 -- should return <540 rows
-- and c.aep is null; -- none are returned, so all points are being linked to aep values!!!


------------------------------------------------------------------------------------------
-- SKIP TO HERE IF 0 MISSING PTS; IGNORE IF >0 MISSING PTS
------------------------------------------------------------------------------------------
DROP TABLE IF EXISTS diffusion_wind.ij_cfbin_lookup_res_pts_us;
CREATE TABLE diffusion_wind.ij_cfbin_lookup_res_pts_us AS
SELECT a.gid as pt_gid, 
	b.i, b.j, 
	b.cf_bin::integer/10 as cf_bin
FROM diffusion_shared.pt_grid_us_res a
LEFT JOIN aws_2014.iii_jjj_cfbin_raster_lookup b
	ON a.iiijjjicf_id = b.raster_value
LEFT JOIN aws_2014.ij_onshore_cf_bins c
	ON b.i = c.i
	and b.j = c.j
	and b.cf_bin = c.cf_bin;
-- 5751859 rows

-- add primary
ALTER TABLE diffusion_wind.ij_cfbin_lookup_res_pts_us ADD PRIMARY KEY (pt_gid);


-- add indices
CREATE INDEX ij_cfbin_lookup_res_pts_us_i_btree ON diffusion_wind.ij_cfbin_lookup_res_pts_us using btree(i);
CREATE INDEX ij_cfbin_lookup_res_pts_us_j_btree ON diffusion_wind.ij_cfbin_lookup_res_pts_us using btree(j);
CREATE INDEX ij_cfbin_lookup_res_pts_us_cf_bin_btree ON diffusion_wind.ij_cfbin_lookup_res_pts_us using btree(cf_bin);

-- check for no nulls
SELECT count(*)
FROM diffusion_wind.ij_cfbin_lookup_res_pts_us
where i is null
or j is null
or cf_bin is null;
-- 0

-- check that it links to resource data
SELECT a.gid, b.i, b.j, b.cf_bin, 
	c.aep
FROM diffusion_shared.pt_grid_us_res a
LEFT JOIN diffusion_wind.ij_cfbin_lookup_res_pts_us b
	on a.gid = b.pt_gid
LEFT JOIN diffusion_wind.wind_resource_annual c
	ON b.i = c.i
	and b.j = c.j
	and b.cf_bin = c.cf_bin
where c.height = 50
and c.turbine_id = 1
and c.aep is null; -- none are returned, so all points are being linked to aep values!!!
------------------------------------------------------------------------------------------