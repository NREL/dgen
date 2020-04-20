DROP TABLE IF EXISTS wind_ds_data.missing_ij_icf_res_points;
CREATE TABLE wind_ds_data.missing_ij_icf_res_points AS
SELECT a.gid, a.the_geom_900914, b.iii, b.jjj, b.icf, b.iii::integer as i, b.jjj::integer as j, b.icf::integer/10 as cf_bin
FROM wind_ds.pt_grid_us_res a

LEFT JOIN wind_ds.iiijjjicf_lookup b
ON a.iiijjjicf_id = b.id

LEFT JOIN aws.ij_icf_lookup_onshore c
ON b.iii = c.iii
and b.jjj = c.jjj
and b.icf = c.icf

where c.i is null; -- this filters down to the ones for which there is no matching i, j, icf combo with elev and tmy data
-- 1,251,212 points

CREATE INDEX missing_ij_icf_res_points_the_geom_900914_gist ON wind_ds_data.missing_ij_icf_res_points using gist(the_geom_900914);

-- find which points can be fixed by going up or down one cfbin in the same i j cell
DROP TABLE IF EXISTS wind_ds_data.res_points_adjusted_1cfbin;
CREATE TABLE wind_ds_data.res_points_adjusted_1cfbin AS
with same_cell as (
	SELECT a.*, 
		CASE WHEN b.cf_bin is not null then b.cf_bin -- 1 bin up
		     WHEN c.cf_bin is not null then c.cf_bin -- 1 bin down
		else null
		end as adjusted_cf_bin
	FROM wind_ds_data.missing_ij_icf_res_points a
	-- try same cell, 1 cfbin up
	LEFT JOIN aws.ij_icf_lookup_onshore b
	on a.iii = b.iii
	and a.jjj = b.jjj
	and a.cf_bin+3 = b.cf_bin
	-- try same cell, 1 cfbin down
	LEFT JOIN aws.ij_icf_lookup_onshore c
	on a.iii = c.iii
	and a.jjj = c.jjj
	and a.cf_bin-3 = c.cf_bin)
SELECT gid, iii, jjj, i, j, cf_bin, adjusted_cf_bin
FROM same_cell
where adjusted_cf_bin is not null;
-- 971,659  rows (about 3/4 of the points)



DROP TABLE IF EXISTS wind_ds_data.res_points_adjusted_ij;
CREATE TABLE wind_ds_data.res_points_adjusted_ij AS
with unfixed as (
	SELECT a.gid, a.the_geom_900914, a.iii, a.jjj, a.icf, a.i, a.j, a.cf_bin
	FROM wind_ds_data.missing_ij_icf_res_points a
	LEFT JOIN wind_ds_data.res_points_adjusted_1cfbin b
	ON a.gid = b.gid
	where b.gid is null),
near_cells As (
SELECT a.*, unnest((select array(SELECT b.gid
		 FROM wind_ds_data.aws_20km_cells b
		 ORDER BY a.the_geom_900914 <#> b.the_geom_900914 LIMIT 9))) -- do 9 because the first one will always be the cell the point is located within
		as aws_gid
FROM unfixed a),
nn_ordered AS (
select a.gid, a.the_geom_900914, a.iii, a.jjj, a.icf, a.i, a.j, a.cf_bin,
	a.aws_gid, b.i as near_i, b.j as near_j, row_number() OVER (PARTITION BY a.gid ORDER BY ST_Distance(a.the_geom_900914,b.the_geom_900914) asc) as nn_rank
FROM near_cells a
LEFT JOIN wind_ds_data.aws_20km_cells b
ON a.aws_gid = b.gid
where NOT(b.i = a.i and b.j = a.j)
-- AND b.i <= a.i+1 and  b.i >= a.i-1 -- this may need to go away if we don't find matches
-- and   b.j <= a.j+1 and  b.j >= a.j-1 -- this too
),
nn_cfs as (
select 	a.*, 
		CASE WHEN b.cf_bin is not null then b.cf_bin -- same cf bin
		     WHEN c.cf_bin is not null then c.cf_bin -- 1 bin up
		     WHEN d.cf_bin is not null then d.cf_bin -- 1 bin down
		else null
		end as adjusted_cf_bin

FROM nn_ordered a
-- try same cf bin
LEFT JOIN aws.ij_icf_lookup_onshore b
on a.near_i = b.i
and a.near_j = b.j
and a.cf_bin = b.cf_bin
-- try 1 cfbin up
LEFT JOIN aws.ij_icf_lookup_onshore c
on a.near_i = c.i
and a.near_j = c.j
and a.cf_bin+3 = c.cf_bin
-- try 1 cf bin down
LEFT JOIN aws.ij_icf_lookup_onshore d
on a.near_i = d.i
and a.near_j = d.j
and a.cf_bin-3 = d.cf_bin)
SELECT distinct on (a.gid) a.gid, a.the_geom_900914, a.iii, a.jjj, a.icf, a.i, a.j, a.cf_bin, a.aws_gid, a.near_i, a.near_j, a.nn_rank, adjusted_cf_bin
FROM nn_cfs a
where adjusted_cf_bin is NOT null
order by a.gid, nn_rank asc;
-- 242,280   points (246,327 for 10 nn) (251849 for 12 nn)
--**

-- find everything that is still missing wind resource data
DROP TABLE IF EXISTS wind_ds_data.remaining_missing_res_points;
CREATE TABLE wind_ds_data.remaining_missing_res_points AS
SELECT a.*
FROM wind_ds_data.missing_ij_icf_res_points a
LEFT JOIN wind_ds_data.res_points_adjusted_ij b
ON a.gid = b.gid
lEFT JOIN wind_ds_data.res_points_adjusted_1cfbin c
ON a.gid = c.gid
where b.gid is null and c.gid is null;
-- 37,273  still have no data (drops to 33,226 for 10 nn) (27704  for 12 nn)

-- for the remaining points, pick the closest cfbin in the same ij cell
DROP TABLE IF EXISTS wind_ds_data.res_points_adjusted_multi_cfbins;
CREATE TABLE wind_ds_data.res_points_adjusted_multi_cfbins AS
SELECT distinct ON (a.gid) a.gid, a.the_geom_900914, a.iii, a.jjj, a.icf, a.i, a.j, a.cf_bin, 
       b.cf_bin as adjusted_cf_bin
FROM wind_ds_data.remaining_missing_res_points a
LEFT JOIN aws.ij_icf_lookup_onshore b
ON a.i = b.i
and a.j = b.j
order by a.gid asc, @(a.cf_bin-b.cf_bin) asc;

-- make sure nothing is left
select count(*)
FROM wind_ds_data.res_points_adjusted_multi_cfbins
where adjusted_cf_bin is null;


-- combine all of these, along with non missing points, into a single lookup table
DROP TABLE IF EXISTS wind_ds.ij_cfbin_lookup_res_pts_us;
CREATE TABLE wind_ds.ij_cfbin_lookup_res_pts_us AS
with notmissing as (
	SELECT a.gid as pt_gid, b.iii::integer as i, b.jjj::integer as j, b.icf::integer/10 as cf_bin, 1::integer as aep_scale_factor
	FROM wind_ds.pt_grid_us_res a

	LEFT JOIN wind_ds.iiijjjicf_lookup b
	ON a.iiijjjicf_id = b.id

	LEFT JOIN aws.ij_icf_lookup_onshore c
	ON b.iii = c.iii
	and b.jjj = c.jjj
	and b.icf = c.icf

	where c.i is NOT null),
adjusted_1cfbin as (
	SELECT gid as pt_gid, i, j, adjusted_cf_bin as cf_bin, cf_bin/adjusted_cf_bin as aep_scale_factor
	FROM wind_ds_data.res_points_adjusted_1cfbin
),
adjusted_ij AS (
	SELECT gid as pt_gid, near_i as i, near_j as j, adjusted_cf_bin as cf_bin, cf_bin/adjusted_cf_bin as aep_scale_factor
	FROM wind_ds_data.res_points_adjusted_ij
	),
adjusted_multi_cfbins as (
	SELECT gid as pt_gid, i, j, adjusted_cf_bin as cf_bin, cf_bin/adjusted_cf_bin as aep_scale_factor
	FROM wind_ds_data.res_points_adjusted_multi_cfbins
)
SELECT *
FROM notmissing

UNION ALL

SELECT *
FROM adjusted_1cfbin

UNION ALL

SELECT *
FROM adjusted_ij

UNION ALL

SELECT *
FROM adjusted_multi_cfbins;

ALTER TABLE wind_ds.ij_cfbin_lookup_res_pts_us ADD PRIMARY KEY (pt_gid);
-- count doesnt match because there are duplicate iii,jjj,icfs in aws.ij_icf_lookup_onshore




	SELECT count(*)
	FROM wind_ds.pt_grid_us_res a

	LEFT JOIN wind_ds.iiijjjicf_lookup b
	ON a.iiijjjicf_id = b.id -- 6273234

	LEFT JOIN aws.ij_icf_lookup_onshore c
	ON b.iii = c.iii
	and b.jjj = c.jjj
	and b.icf = c.icf -- more (6274124)


-- here is proof that i j icfs are not unique
select hdf_index, iii, jjj, icf, count(*), array_agg(icf), array_agg(cf_bin)
FROM aws.ij_icf_lookup_onshore
group by hdf_index, iii, jjj, icf
order by count desc

select icf, cf_bin
FROM aws.ij_icf_lookup_onshore
group by hdf_index, iii, jjj, icf
order by count desc

	

	select 5022912+1251212; -- 6274124

