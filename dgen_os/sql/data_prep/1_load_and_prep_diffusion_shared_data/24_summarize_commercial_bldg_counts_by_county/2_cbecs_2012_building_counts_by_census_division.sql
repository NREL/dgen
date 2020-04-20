set role 'eia-writers';

DROP TABLE IF EXISTS eia.cbecs_2012_building_counts_by_census_division;
CREATE TABLE eia.cbecs_2012_building_counts_by_census_division
(
	census_division_abbr varchar(3) primary key,
	bldg_count integer
);



\COPY  eia.cbecs_2012_building_counts_by_census_division FROM '/Volumes/Staff/mgleason/DG_Solar/Data/Source_Data/EIA_CBECS_2012/cbecs_2012_total_bldg_counts.csv' with csv header;

select *
FROM  eia.cbecs_2012_building_counts_by_census_division;