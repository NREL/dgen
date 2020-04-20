set role 'diffusion-writers';
DROP VIEW IF EXISTS diffusion_geo.cbecs_2012_subset_for_xiaobing;
CREATE VIEW diffusion_geo.cbecs_2012_subset_for_xiaobing AS
select pubid, finalwt, mfhtbtu, mfclbtu,
	sqft,
	CASE WHEN pubclim = 1 THEN 'Very cold/Cold'
		WHEN pubclim = 2 THEN 'Mixed-humid'
		WHEN pubclim = 3 THEN 'Hot-dry/Mixed-dry/Hot-humid'
		WHEN pubclim = 5 THEN 'Marine'
		WHEN pubclim = 7 THEN 'Withheld to protect confidentiality'
	END as pubclim, 
	CASE WHEN pba = 1 THEN 'Vacant'
		WHEN pba = 2 THEN 'Office'
		WHEN pba = 4 THEN 'Laboratory'
		WHEN pba = 5 THEN 'Nonrefrigerated warehouse'
		WHEN pba = 6 THEN 'Food sales'
		WHEN pba = 7 THEN 'Public order and safety'
		WHEN pba = 8 THEN 'Outpatient health care'
		WHEN pba = 11 THEN 'Refrigerated warehouse'
		WHEN pba = 12 THEN 'Religious worship'
		WHEN pba = 13 THEN 'Public assembly'
		WHEN pba = 14 THEN 'Education'
		WHEN pba = 15 THEN 'Food service'
		WHEN pba = 16 THEN 'Inpatient health care'
		WHEN pba = 17 THEN 'Nursing'
		WHEN pba = 18 THEN 'Lodging'
		WHEN pba = 23 THEN 'Strip shopping mall'
		WHEN pba = 24 THEN 'Enclosed mall'
		WHEN pba = 25 THEN 'Retail other than mall'
		WHEN pba = 26 THEN 'Service'
		WHEN pba = 91 THEN 'Other'
	END as pba,
	CASE 
		WHEN pbaplus = 1 THEN 'Vacant'
		WHEN pbaplus = 2 THEN 'Administrative/professional office'
		WHEN pbaplus = 3 THEN 'Bank/other financial'
		WHEN pbaplus = 4 THEN 'Government office'
		WHEN pbaplus = 5 THEN 'Medical office (non-diagnostic)'
		WHEN pbaplus = 6 THEN 'Mixed-use office'
		WHEN pbaplus = 7 THEN 'Other office'
		WHEN pbaplus = 8 THEN 'Laboratory'
		WHEN pbaplus = 9 THEN 'Distribution/shipping center'
		WHEN pbaplus = 10 THEN 'Non-refrigerated warehouse'
		WHEN pbaplus = 11 THEN 'Self-storage'
		WHEN pbaplus = 12 THEN 'Convenience store'
		WHEN pbaplus = 13 THEN 'Convenience store with gas station'
		WHEN pbaplus = 14 THEN 'Grocery store/food market'
		WHEN pbaplus = 15 THEN 'Other food sales'
		WHEN pbaplus = 16 THEN 'Fire station/police station'
		WHEN pbaplus = 17 THEN 'Other public order and safety'
		WHEN pbaplus = 18 THEN 'Medical office (diagnostic)'
		WHEN pbaplus = 19 THEN 'Clinic/other outpatient health'
		WHEN pbaplus = 20 THEN 'Refrigerated warehouse'
		WHEN pbaplus = 21 THEN 'Religious worship'
		WHEN pbaplus = 22 THEN 'Entertainment/culture'
		WHEN pbaplus = 23 THEN 'Library'
		WHEN pbaplus = 24 THEN 'Recreation'
		WHEN pbaplus = 25 THEN 'Social/meeting'
		WHEN pbaplus = 26 THEN 'Other public assembly'
		WHEN pbaplus = 27 THEN 'College/university'
		WHEN pbaplus = 28 THEN 'Elementary/middle school'
		WHEN pbaplus = 29 THEN 'High school'
		WHEN pbaplus = 30 THEN 'Preschool/daycare'
		WHEN pbaplus = 31 THEN 'Other classroom education'
		WHEN pbaplus = 32 THEN 'Fast food'
		WHEN pbaplus = 33 THEN 'Restaurant/cafeteria'
		WHEN pbaplus = 34 THEN 'Other food service'
		WHEN pbaplus = 35 THEN 'Hospital/inpatient health'
		WHEN pbaplus = 36 THEN 'Nursing home/assisted living'
		WHEN pbaplus = 37 THEN 'Dormitory/fraternity/sorority'
		WHEN pbaplus = 38 THEN 'Hotel'
		WHEN pbaplus = 39 THEN 'Motel or inn'
		WHEN pbaplus = 40 THEN 'Other lodging'
		WHEN pbaplus = 41 THEN 'Vehicle dealership/showroom'
		WHEN pbaplus = 42 THEN 'Retail store'
		WHEN pbaplus = 43 THEN 'Other retail'
		WHEN pbaplus = 44 THEN 'Post office/postal center'
		WHEN pbaplus = 45 THEN 'Repair shop'
		WHEN pbaplus = 46 THEN 'Vehicle service/repair shop'
		WHEN pbaplus = 47 THEN 'Vehicle storage/maintenance'
		WHEN pbaplus = 48 THEN 'Other service'
		WHEN pbaplus = 49 THEN 'Other'
		WHEN pbaplus = 50 THEN 'Strip shopping mall'
		WHEN pbaplus = 51 THEN 'Enclosed mall'
		WHEN pbaplus = 52 THEN 'Courthouse/probation office'
		WHEN pbaplus = 53 THEN 'Bar/pub/lounge'
	end as pbaplus,
	case when yrcon = 995 THEN 1946 
	    ELSE yrcon 
	END as yrcon, 
	CASE WHEN renov = 1 THEN TRUE
	     WHEN renov = 2 THEN FALSE
	     WHEN renov is null THEN null
	END as renov, 
	CASE WHEN renwin = 1 THEN TRUE
	     WHEN renwin = 2 THEN FALSE
	     WHEN renwin is null THEN null
	END as renwin, 
	CASE WHEN renhvc = 1 THEN TRUE
	     WHEN renhvc = 2 THEN FALSE
	     WHEN renhvc is null THEN null
	END as renhvc, 	
	CASE WHEN renins = 1 THEN TRUE
	     WHEN renins = 2 THEN FALSE
	     WHEN renins is null THEN null
	END as renins, 	
	CASE WHEN elht1 = 1 THEN 'electricity'
		 WHEN nght1 = 1 THEN 'natural gas'
		 WHEN fkht1 = 1 THEN 'distallate fuel oil'
		 WHEN prht1 = 1 THEN 'propane'
		 WHEN stht1 = 1 THEN 'district steam'
		 WHEN hwht1 = 1 THEN 'district hot water'
		 WHEN woht1 = 1 THEN 'wood'
		 WHEN coht1 = 1 THEN 'coal'
		 WHEN soht1 = 1 THEN 'solar energy'
		 WHEN otht1 = 1 THEN 'other'
	ELSE 'none'
	END as primary_fuel_heat,
	CASE WHEN mainht = 1 THEN 'Furnaces that heat air directly, without using steam or hot water'
		WHEN mainht = 2 THEN 'Packaged central unit (roof mounted)'
		WHEN mainht = 3 THEN 'Boilers inside (or adjacent to) the building that produce steam or hot water'
		WHEN mainht = 4 THEN 'District steam or hot water piped in from outside the building'
		WHEN mainht = 5 THEN 'Heat pumps (other than components of a packaged unit)'
		WHEN mainht = 6 THEN 'Individual space heaters (other than heat pumps)'
		WHEN mainht = 7 THEN 'Other heating equipment'
		WHEN mainht is NULl THEN NULL
	END as mainht,
	CASE WHEN nwmnht = 1 THEN TRUE
	     WHEN nwmnht = 2 THEN FALSE
	     WHEN nwmnht is null THEN null
	END as nwmnht,
	CASE WHEN maincl = 1 THEN 'Residential-type central air conditioners (other than heat pumps) that cool air directly and circulate it without using chilled water'
		WHEN maincl = 2 THEN 'Packaged air conditioning units (other than heat pumps)'
		WHEN maincl = 3 THEN 'Central chillers inside (or adjacent to) the building that chill water for air conditioning'
		WHEN maincl = 4 THEN 'District chilled water piped in from outside the building'
		WHEN maincl = 5 THEN 'Heat pumps for cooling'
		WHEN maincl = 6 THEN 'Individual room air conditioners (other than heat pumps)'
		WHEN maincl = 7 THEN '""Swamp"" coolers or evaporative coolers'
		WHEN maincl = 8 THEN 'Other cooling equipment'
	END as maincl, 
	case when maincl = 4 and cwcool = 1 THEN 'district chilled water'
		WHEN elcool = 1 THEN 'electricity'
		WHEN ngcool = 1 THEN 'natural gas'
		WHEN fkcool = 1 THEN 'distallate fuel oil'
		WHEN prcool = 1 THEN 'propane'
		WHEN stcool = 1 THEN 'district steam'
		WHEN hwcool = 1 THEN 'district hot water'
		WHEN cwcool = 1 THEN 'district chilled water'
		WHEN otcool = 1 THEN 'other'
	END as primary_cool_fuel,
	CASE WHEN nwmncl = 1 THEN TRUE
	     WHEN nwmncl = 2 THEN FALSE
	     WHEN nwmncl is null THEN null
	END as nwmncl
from eia.cbecs_2012_microdata;


\COPY (SELECT * FROM diffusion_geo.cbecs_2012_subset_for_xiaobing) TO '/Users/mgleason/Desktop/cbecs_2012/cbecs_2012_microdata_extract.csv' WITH CSV HEADER;

-- with a as
-- (
-- select
-- 	CASE WHEN elht1 = 1 THEN TRUE
-- 	     WHEN elht1 = 2 THEN FALSE
-- 	     WHEN elht1 is NULL THEN FALSE
-- 	END AS elht1,
-- 	CASE WHEN nght1 = 1 THEN TRUE
-- 	     WHEN nght1 = 2 THEN FALSE
-- 	     WHEN nght1 is NULL THEN FALSE
-- 	END AS nght1,
-- 	CASE WHEN fkht1 = 1 THEN TRUE
-- 	     WHEN fkht1 = 2 THEN FALSE
-- 	     WHEN fkht1 is NULL THEN FALSE
-- 	END AS fkht1,
-- 	CASE WHEN prht1 = 1 THEN TRUE
-- 	     WHEN prht1 = 2 THEN FALSE
-- 	     WHEN prht1 is NULL THEN FALSE
-- 	END AS prht1,
-- 	CASE WHEN stht1 = 1 THEN TRUE
-- 	     WHEN stht1 = 2 THEN FALSE
-- 	     WHEN stht1 is NULL THEN FALSE
-- 	END AS stht1,
-- 	CASE WHEN hwht1 = 1 THEN TRUE
-- 	     WHEN hwht1 = 2 THEN FALSE
-- 	     WHEN hwht1 is NULL THEN FALSE
-- 	END AS hwht1,
-- 	CASE WHEN woht1 = 1 THEN TRUE
-- 	     WHEN woht1 = 2 THEN FALSE
-- 	     WHEN woht1 is NULL THEN FALSE
-- 	END AS woht1,
-- 	CASE WHEN coht1 = 1 THEN TRUE
-- 	     WHEN coht1 = 2 THEN FALSE
-- 	     WHEN coht1 is NULL THEN FALSE
-- 	END AS coht1,
-- 	CASE WHEN soht1 = 1 THEN TRUE
-- 	     WHEN soht1 = 2 THEN FALSE
-- 	     WHEN soht1 is NULL THEN FALSE
-- 	END AS soht1,
-- 	CASE WHEN otht1 = 1 THEN TRUE
-- 	     WHEN otht1 = 2 THEN FALSE
-- 	     WHEN otht1 is NULL THEN FALSE
-- 	END AS otht1
-- 	from eia.cbecs_2012_microdata
-- )
-- ,
-- b as (
-- select elht1::INTEGER + 
-- nght1::INTEGER + 
-- fkht1::INTEGER + 
-- prht1::INTEGER + 
-- stht1::INTEGER + 
-- hwht1::INTEGER + 
-- woht1::INTEGER + 
-- coht1::INTEGER + 
-- soht1::INTEGER + 
-- otht1::INTEGER as tot_heat
-- from a
-- )
-- select max(tot_heat)
-- from b;
-- -- all set -- try for cooling and secondary heating too?



-- 
-- with a as
-- (
-- select
-- 	CASE WHEN elht2 = 1 THEN TRUE
-- 	     WHEN elht2 = 2 THEN FALSE
-- 	     WHEN elht2 is NULL THEN FALSE
-- 	END AS elht2,
-- 	CASE WHEN nght2 = 1 THEN TRUE
-- 	     WHEN nght2 = 2 THEN FALSE
-- 	     WHEN nght2 is NULL THEN FALSE
-- 	END AS nght2,
-- 	CASE WHEN fkht2 = 1 THEN TRUE
-- 	     WHEN fkht2 = 2 THEN FALSE
-- 	     WHEN fkht2 is NULL THEN FALSE
-- 	END AS fkht2,
-- 	CASE WHEN prht2 = 1 THEN TRUE
-- 	     WHEN prht2 = 2 THEN FALSE
-- 	     WHEN prht2 is NULL THEN FALSE
-- 	END AS prht2,
-- 	CASE WHEN stht2 = 1 THEN TRUE
-- 	     WHEN stht2 = 2 THEN FALSE
-- 	     WHEN stht2 is NULL THEN FALSE
-- 	END AS stht2,
-- 	CASE WHEN hwht2 = 1 THEN TRUE
-- 	     WHEN hwht2 = 2 THEN FALSE
-- 	     WHEN hwht2 is NULL THEN FALSE
-- 	END AS hwht2,
-- 	CASE WHEN woht2 = 1 THEN TRUE
-- 	     WHEN woht2 = 2 THEN FALSE
-- 	     WHEN woht2 is NULL THEN FALSE
-- 	END AS woht2,
-- 	CASE WHEN coht2 = 1 THEN TRUE
-- 	     WHEN coht2 = 2 THEN FALSE
-- 	     WHEN coht2 is NULL THEN FALSE
-- 	END AS coht2,
-- 	CASE WHEN soht2 = 1 THEN TRUE
-- 	     WHEN soht2 = 2 THEN FALSE
-- 	     WHEN soht2 is NULL THEN FALSE
-- 	END AS soht2,
-- 	CASE WHEN otht2 = 1 THEN TRUE
-- 	     WHEN otht2 = 2 THEN FALSE
-- 	     WHEN otht2 is NULL THEN FALSE
-- 	END AS otht2
-- 	from eia.cbecs_2012_microdata
-- )
-- ,
-- b as (
-- select elht2::INTEGER + 
-- nght2::INTEGER + 
-- fkht2::INTEGER + 
-- prht2::INTEGER + 
-- stht2::INTEGER + 
-- hwht2::INTEGER + 
-- woht2::INTEGER + 
-- coht2::INTEGER + 
-- soht2::INTEGER + 
-- otht2::INTEGER as tot_heat
-- from a
-- )
-- select max(tot_heat)
-- from b;
-- -- max is 3 -- can't simplify
-- 
-- 
-- 
-- 
-- WITH a as
-- (
-- select
-- CASE WHEN elcool = 1 THEN TRUE ELSE FALSE END as elcool,
-- CASE WHEN ngcool = 1 THEN TRUE ELSE FALSE END as ngcool,
-- CASE WHEN fkcool = 1 THEN TRUE ELSE FALSE END as fkcool,
-- CASE WHEN prcool = 1 THEN TRUE ELSE FALSE END as prcool,
-- CASE WHEN stcool = 1 THEN TRUE ELSE FALSE END as stcool,
-- CASE WHEN hwcool = 1 THEN TRUE ELSE FALSE END as hwcool,
-- CASE WHEN cwcool = 1 THEN TRUE ELSE FALSE END as cwcool,
-- CASE WHEN otcool = 1 THEN TRUE ELSE FALSE END as otcool
-- from eia.cbecs_2012_microdata
-- ),
-- b as
-- (
-- select *,
-- elcool::INTEGER +
-- ngcool::INTEGER +
-- fkcool::INTEGER +
-- prcool::INTEGER +
-- stcool::INTEGER +
-- hwcool::INTEGER +
-- cwcool::INTEGER +
-- otcool::INTEGER  as totcool
-- from a
-- 
-- )
-- select *
-- from b
-- where totcool > 1;

-- exploring cooling combos to decide how to handle them
-- 
-- select distinct diffusion_shared.r_remove_nulls_from_array(
-- array[ 
-- CASE WHEN elcool = 1 THEN 'electricity' else null END,
-- CASE WHEN ngcool = 1 THEN 'natural gas' ELSE NULL END,
-- CASE WHEN fkcool = 1 THEN 'distallate fuel oil' ELSE NULL END,
-- CASE WHEN prcool = 1 THEN 'propane' ELSE NULL END,
-- CASE WHEN stcool = 1 THEN 'district steam' ELSE NULL END,
-- CASE WHEN hwcool = 1 THEN 'district hot water' ELSE NULL END,
-- CASE WHEN cwcool = 1 THEN 'district chilled water' ELSE NULL END,
-- CASE WHEN otcool = 1 THEN 'other' ELSE NULL END
-- ])
-- from eia.cbecs_2012_microdata ;
-- 
-- 
-- 
-- select
-- 	case when maincl = 4 and cwcool = 1 THEN 'district chilled water'
-- 		WHEN elcool = 1 THEN 'electricity'
-- 		WHEN ngcool = 1 THEN 'natural gas'
-- 		WHEN fkcool = 1 THEN 'distallate fuel oil'
-- 		WHEN prcool = 1 THEN 'propane'
-- 		WHEN stcool = 1 THEN 'district steam'
-- 		WHEN hwcool = 1 THEN 'district hot water'
-- 		WHEN cwcool = 1 THEN 'district chilled water'
-- 		WHEN otcool = 1 THEN 'other'
-- 		END as primary_cool_fuel,
-- 		diffusion_shared.r_remove_nulls_from_array(
-- array[ 
-- CASE WHEN elcool = 1 THEN 'electricity' else null END,
-- CASE WHEN ngcool = 1 THEN 'natural gas' ELSE NULL END,
-- CASE WHEN fkcool = 1 THEN 'distallate fuel oil' ELSE NULL END,
-- CASE WHEN prcool = 1 THEN 'propane' ELSE NULL END,
-- CASE WHEN stcool = 1 THEN 'district steam' ELSE NULL END,
-- CASE WHEN hwcool = 1 THEN 'district hot water' ELSE NULL END,
-- CASE WHEN cwcool = 1 THEN 'district chilled water' ELSE NULL END,
-- CASE WHEN otcool = 1 THEN 'other' ELSE NULL END
-- ])
-- FROM eia.cbecs_2012_microdata 