SET ROLE 'diffusion-writers';
------------------------------------------------------------------------------------------------------------
-- RECS

DROP TABLE IF EXISTS diffusion_shared.eia_microdata_recs_2009_expanded CASCADE;
CREATE TABLE diffusion_shared.eia_microdata_recs_2009_expanded AS
select 
	doeid AS building_id,
	nweight AS sample_wt,
	CASE 
	  WHEN regionc = 1 THEN 'Northeast'
	  WHEN regionc = 2 THEN 'Midwest'
	  WHEN regionc = 3 then 'South'
	  WHEN regionc = 4 then 'West'
	END AS census_region,
	CASE 
	  WHEN division = 1 THEN 'NE'
	  WHEN division = 2 THEN 'MA'
	  WHEN division = 3 THEN 'ENC'
	  WHEN division = 4 THEN 'WNC'
	  WHEN division = 5 THEN 'SA'
	  WHEN division = 6 THEN 'ESC'
	  WHEN division = 7 THEN 'WSC'
	  WHEN division = 8 THEN 'MTN' -- NOTE: RECS breaks the MTN into N and S subdivision, but for consistency w CbECS, we will stick with one
	  WHEN division = 9 THEN 'MTN' -- (see above)
	  WHEN division = 10 THEN 'PAC'
	END AS census_division_abbr,
	reportable_domain AS reportable_domain,
	climate_region_pub AS climate_zone,
	NULL::INTEGER as pba,
	NULL::INTEGER as pbaplus,
	typehuq,
	CASE WHEN rooftype = -2 THEN 8
	ELSE rooftype
	END as roof_material,
	CASE 
	  WHEN kownrent = 1 THEN TRUE 
	  ELSE FALSE
	END AS owner_occupied,
	kwh AS kwh,
	yearmade AS year_built,
	typehuq IN (1, 2, 3) AS single_family_res,
	CASE 
	  WHEN typehuq in (1, 2, 3) THEN 1
	  WHEN typehuq = 4 THEN 3
	  WHEN typehuq = 5 THEN numapts
	END AS num_tenants,
	CASE 
	  WHEN typehuq in (1, 2, 3) THEN
		  CASE 
		    WHEN stories = 10 THEN 1
		    WHEN stories = 20 THEN 2
		    WHEN stories = 31 THEN 3
		    WHEN stories = 32 THEN 4
		    WHEN stories = 40 THEN 2
		    WHEN stories = 50 THEN 1
		    ELSE 1
		  END
	  WHEN typehuq = 4 THEN naptflrs
	  WHEN typehuq = 5 THEN numflrs
	END AS num_floors,
	CASE 
	  WHEN equipm = 2 THEN 'steam or hot water system'
	  WHEN equipm = 3 THEN 'central warm-air furnace'
	  WHEN equipm = 4 THEN 'heat pump'
	  WHEN equipm = 5 THEN 'built-in electric units'
	  WHEN equipm = 6 THEN 'floor or wall pipeless furnace'
	  WHEN equipm = 7 THEN 'built-in room heater'
	  WHEN equipm = 8 THEN 'heating stove'
	  WHEN equipm = 9 THEN 'fireplace'
	  WHEN equipm = 10 THEN 'portable electric heaters'
	  WHEN equipm = 11 THEN 'portable kerosene heaters'
	  WHEN equipm = 12 THEN 'cooking stove'
	  WHEN equipm = 21 THEN 'other equipment'
	  WHEN equipm = -2 THEN 'none'
	END AS space_heat_equip,
	CASE 
	  WHEN fuelheat = 1 THEN 'natural gas'
	  WHEN fuelheat = 2 THEN 'propane'
	  WHEN fuelheat = 3 THEN 'distallate fuel oil'
	  WHEN fuelheat = 4 THEN 'distallate fuel oil'
	  WHEN fuelheat = 5 THEN 'electricity'
	  WHEN fuelheat = 7 THEN 'wood'
	  WHEN fuelheat = 8 THEN 'solar energy'
	  WHEN fuelheat = 9 THEN 'other'
	  WHEN fuelheat = 21 THEN 'other'
	  WHEN fuelheat = -2 THEN 'no fuel'
	END AS space_heat_fuel,
	CASE 
	  WHEN equipage = 1 THEN 0
	  WHEN equipage = 2 THEN 2
	  WHEN equipage = 3 THEN 5
	  WHEN equipage = 41 THEN 10
	  WHEN equipage = 42 THEN 15
	  WHEN equipage = 5 THEN 20
	  WHEN equipage = -2 THEN NULL
	END AS space_heat_age_min,
	CASE 
	  WHEN equipage = 1 THEN 2
	  WHEN equipage = 2 THEN 4
	  WHEN equipage = 3 THEN 9
	  WHEN equipage = 41 THEN 14
	  WHEN equipage = 42 THEN 19
	  WHEN equipage = 5 THEN 40
	  WHEN equipage = -2 THEN NULL
	END AS space_heat_age_max,
	CASE 
	  WHEN h2otype1 = 1 THEN 'storage water heater'
	  WHEN h2otype1 = 2 THEN 'tankless water heater'
	  WHEN h2otype1 = -2 THEN 'none'
	END AS water_heat_equip,
	CASE 
	  WHEN fuelh2o = 1 THEN 'natural gas'
	  WHEN fuelh2o = 2 THEN 'propane'
	  WHEN fuelh2o = 3 THEN 'distallate fuel oil'
	  WHEN fuelh2o = 4 THEN 'distallate fuel oil'
	  WHEN fuelh2o = 5 THEN 'electricity'
	  WHEN fuelh2o = 7 THEN 'wood'
	  WHEN fuelh2o = 8 THEN 'solar energy'
	  WHEN fuelh2o = 21 THEN 'other'
	  WHEN fuelh2o = -2 THEN 'none'
	END AS water_heat_fuel,
	CASE 
	  WHEN wheatage = 1 THEN 0
	  WHEN wheatage = 2 THEN 2
	  WHEN wheatage = 3 THEN 5
	  WHEN wheatage = 41 THEN 10
	  WHEN wheatage = 42 THEN 15
	  WHEN wheatage = 5 THEN 20
	  WHEN wheatage = -2 THEN NULL
	END AS water_heat_age_min,
	CASE 
	  WHEN wheatage = 1 THEN 2
	  WHEN wheatage = 2 THEN 4
	  WHEN wheatage = 3 THEN 9
	  WHEN wheatage = 41 THEN 14
	  WHEN wheatage = 42 THEN 19
	  WHEN wheatage = 5 THEN 40
	  WHEN wheatage = -2 THEN NULL
	END AS water_heat_age_max,
	CASE 
	  WHEN cooltype = 1 THEN 'central air'
	  WHEN cooltype = 2 THEN 'window/wall units'
	  WHEN cooltype = 3 THEN 'central air'
	  WHEN cooltype = -2 THEN 'none'
	END AS space_cool_equip,
	'electricity'::TEXT AS space_cool_fuel,
	CASE 
	  WHEN cooltype in (1,3) THEN
	    CASE 
	      WHEN agecenac = 1 THEN 0
	      WHEN agecenac = 2 THEN 2
	      WHEN agecenac = 3 THEN 5
	      WHEN agecenac = 41 THEN 10
	      WHEN agecenac = 42 THEN 15
	      WHEN agecenac = 5 THEN 20
	      WHEN agecenac = -2 THEN NULL
	    END
	  WHEN cooltype = 2 THEN
	   CASE 
	      WHEN wwacage = 1 THEN 0
	      WHEN wwacage = 2 THEN 2
	      WHEN wwacage = 3 THEN 5
	      WHEN wwacage = 41 THEN 10
	      WHEN wwacage = 42 THEN 15
	      WHEN wwacage = 5 THEN 20
	      WHEN wwacage = -2 THEN NULL
	   END
	  ELSE NULL
	END AS space_cool_age_min,
	CASE 
	  WHEN cooltype in (1,3) THEN
	    CASE 
	      WHEN agecenac = 1 THEN 2
	      WHEN agecenac = 2 THEN 4
	      WHEN agecenac = 3 THEN 9
	      WHEN agecenac = 41 THEN 14
	      WHEN agecenac = 42 THEN 19
	      WHEN agecenac = 5 THEN 40
	      WHEN agecenac = -2 THEN NULL
	    END
	  WHEN cooltype = 2 THEN
	    CASE 
	      WHEN wwacage = 1 THEN 2
	      WHEN wwacage = 2 THEN 4
	      WHEN wwacage = 3 THEN 9
	      WHEN wwacage = 41 THEN 14
	      WHEN wwacage = 42 THEN 19
	      WHEN wwacage = 5 THEN 40
	      WHEN wwacage = -2 THEN NULL
	    END
	  ELSE NULL
	END AS space_cool_age_max,
	CASE 
	  WHEN ducts = 0 THEN False
	  WHEN ducts = 1 THEN True
	  WHEN ducts = -2 THEN False
	END AS ducts,
	totsqft_en::NUMERIC AS totsqft,
	tothsqft::NUMERIC AS totsqft_heat,
	totcsqft::NUMERIC AS totsqft_cool,
	totalbtusph::NUMERIC AS kbtu_space_heat,
	totalbtucol::NUMERIC AS kbtu_space_cool,
	totalbtuwth::NUMERIC AS kbtu_water_heat
from eia.recs_2009_microdata;
-- 12083 rows

------------------------------------------------------------------------------------------------------------
-- CBECS
-- -- 
DROP TABLE IF EXISTS diffusion_shared.eia_microdata_cbecs_2003_expanded CASCADE;
CREATE TABLE diffusion_shared.eia_microdata_cbecs_2003_expanded AS
select
	a.pubid8 AS building_id,
	a.adjwt8 AS sample_wt,
	CASE 
	  WHEN a.region8 = 1 THEN 'Northeast'
	  WHEN a.region8 = 2 THEN 'Midwest'
	  WHEN a.region8 = 3 THEN 'South'
	  WHEN a.region8 = 4 THEN 'West'
	END AS census_region,
	CASE 
	  WHEN a.cendiv8 = 1 THEN 'NE'
	  WHEN a.cendiv8 = 2 THEN 'MA'
	  WHEN a.cendiv8 = 3 THEN 'ENC'
	  WHEN a.cendiv8 = 4 THEN 'WNC'
	  WHEN a.cendiv8 = 5 THEN 'SA'
	  WHEN a.cendiv8 = 6 THEN 'ESC'
	  WHEN a.cendiv8 = 7 THEN 'WSC'
	  WHEN a.cendiv8 = 8 THEN 'MTN'
	  WHEN a.cendiv8 = 9 THEN 'PAC'
	END AS census_division_abbr,
	NULL::INTEGER AS reportable_domain,
	a.climate8 AS climate_zone,
	a.pba8 AS pba,
	b.pbaplus8 AS pbaplus,
	NULL::INTEGER as typehuq,
	CASE WHEN a.rfcns8 is null THEN 9
	ELSE a.rfcns8
	END AS roof_material,
	CASE 
	  WHEN a.ownocc8 = 1 THEN TRUE
	  WHEN a.ownocc8 = 2 THEN FALSE
	  WHEN a.ownocc8 = 7 THEN FALSE
	  WHEN a.ownocc8 = 8 THEN FALSE
	  WHEN a.ownocc8 = 9 THEN FALSE
	  else false
	END AS owner_occupied,
	CASE 
	  WHEN o.elcns8 <= 999999999999995 THEn o.elcns8
	  ELSE 0
	END AS kwh,
	CASE 
	  WHEN a.yrcon8 > 9996 THEN NULL
	  ELSE a.yrcon8
	END AS year_built,
	FALSE AS single_family_res,
	CASE 
	  WHEN a.nocc8 > 99996 THEN NULL
	  ELSE a.nocc8
	END AS num_tenants,
	CASE 
	  WHEN a.nfloor8 <=14 THEN nfloor8
	  WHEN a.nfloor8 = 991 THEN 20
	  WHEN a.nfloor8 = 992 THEN 30
	  when a.nfloor8 is null and a.pba8 = 23 THEn 1 -- assume strip malls are single floor
	  when a.nfloor8 is null and a.pba8 = 24 THEn 2 -- assume enclosed malls are two floor
	END AS num_floors,
	CASE 
	  WHEN c.mainht8 = 1 THEN 'furnaces that heat air directly'
	  WHEN c.mainht8 = 2 THEN 'boilers inside the building'
	  WHEN c.mainht8 = 3 THEN 'packaged heating units'
	  WHEN c.mainht8 = 4 THEN 'individual space heaters'
	  WHEN c.mainht8 = 5 THEN 
	    CASE 
	      WHEN c.pkghps8 = 1 THEN 'packaged unit heat pump for heating'
	      WHEN c.splhps8 = 1 THEN 'split system heat pump for heating'
	      WHEN c.rmhps8  = 1 THEN 'individual room heat pump for heating'
	      WHEN c.airhpt8 = 1 THEN 'air source heat pump for heating'
	      WHEN c.grdhpt8 = 1 THEN ' ground source heat pump for heating'
	      WHEN c.wtrhpt8 = 1 THEN 'water loop heat pump for heating'
	      ELSE 'other heat pump for heating'
	    END
	  WHEN c.mainht8 = 6 THEN 'district steam or hot water'
	  WHEN c.mainht8 = 7 THEN 'other heating equipment'
	  WHEN c.mainht8 is null and q.mfhtbtu8 > 0 THEN 'other heating equipment'
	  WHEN c.mainht8 is null and (q.mfhtbtu8 = 0 or q.mfhtbtu8 is null) THEN 'none'
	END AS space_heat_equip,
	CASE 
	  WHEN e.elht18 = 1 THEN 'electricity'
	  WHEN e.nght18 = 1 THEN 'natural gas'
	  WHEN e.fkht18 = 1 THEN 'distallate fuel oil'
	  WHEN e.prht18 = 1 THEN 'propane'
	  WHEN e.stht18 = 1 THEN 'district steam'
	  WHEN e.hwht18 = 1 THEN 'district hot water'
	  WHEN f.woht18 = 1 THEN 'wood'
	  WHEN f.coht18 = 1 THEN 'coal'
	  WHEN f.soht18 = 1 THEN 'solar energy'
	  WHEN f.otht18 = 1 THEN 'other'
	  ELSE 'none'
	END AS space_heat_fuel,
	0::INTEGER AS space_heat_age_min,
	40::INTEGER AS space_heat_age_max,
	CASE 
	  WHEN d.wthteq8 = 1 THEN 'one or more centralized'
	  WHEN d.wthteq8 = 2 THEN 'one or more point-of-use'
	  WHEN d.wthteq8 = 3 THEN 'both types of water heaters'
	  WHEN d.wthteq8 is null and q.mfwtbtu8 > 0 THEN 'other'
	  WHEN d.wthteq8 is null and (q.mfwtbtu8 = 0 or q.mfwtbtu8 is null) THEN 'none'
	END AS water_heat_equip,
	CASE 
	  WHEN e.elwatr8 = 1 THEN 'electricity'
	  WHEN e.ngwatr8 = 1 THEN 'natural gas'
	  WHEN e.fkwatr8 = 1 THEN 'distallate fuel oil'
	  WHEN e.prwatr8 = 1 THEN 'propane'
	  WHEN e.stwatr8 = 1 THEN 'district steam'
	  WHEN e.hwwatr8 = 1 THEN 'district hot water'
	  WHEN f.wowatr8 = 1 THEN 'wood'
	  WHEN f.cowatr8 = 1 THEN 'coal'
	  WHEN f.sowatr8 = 1 THEN 'solar energy'
	  WHEN f.otwatr8 = 1 THEN 'other'
	  ELSE 'none'
	END AS water_heat_fuel,
	0::INTEGER AS water_heat_age_min,
	40::INTEGER AS water_heat_age_max,
	CASE 
	  WHEN c.maincl8 = 1 THEN 'packaged a/c units'
	  WHEN c.maincl8 = 2 THEN 'residential-type central a/c'
	  WHEN c.maincl8 = 3 THEN 'individual room a/c'
	  WHEN c.maincl8 = 4 THEN
	    CASE 
	      WHEN c.pkgcps8 = 1 THEN 'packaged unit heat pump for cooling'
	      WHEN c.splcps8 = 1 THEN 'split system heat pump for cooling'
	      WHEN c.rmcps8  = 1 THEN 'individual room heat pump for cooling'
	      WHEN c.aircpt8 = 1 THEN 'air source heat pump for cooling'
	      WHEN c.grdcpt8 = 1 THEN 'ground source heat pump for cooling'
	      WHEN c.wtrcpt8 = 1 THEN 'water loop heat pump for cooling'
	      ELSE 'other heat pumps for cooling'
	    END
	  WHEN c.maincl8 = 5 THEN 'district chilled water piped in'
	  WHEN c.maincl8 = 6 THEN 'central chillers inside the building'
	  WHEN c.maincl8 = 7 THEN 'swamp coolers or evaporative coolers'
	  WHEN c.maincl8 = 8 THEN 'other cooling equipment'
	  WHEN c.maincl8 is null and q.mfclbtu8 > 0 THEN 'other'
	  WHEN c.maincl8 is null and (q.mfclbtu8 = 0 or q.mfclbtu8 is null) THEN 'none'
	END AS space_cool_equip,
	CASE 
	  WHEN e.elcool8 = 1 THEN 'electricity'
	  WHEN e.ngcool8 = 1 THEN 'natural gas'
	  WHEN e.fkcool8 = 1 THEN 'fuel oil'
	  WHEN e.prcool8 = 1 THEN 'propane'
	  WHEN e.stcool8 = 1 THEN 'district steam'
	  WHEN e.hwcool8 = 1 THEN 'district hot water'
	  WHEN f.cwcool8 = 1 THEN 'district chilled water'
	  WHEN f.otcool8 = 1 THEN 'other'
	  ELSE 'none'
	END AS space_cool_fuel,
	0::INTEGER AS space_cool_age_min,
	40::INTEGER AS space_cool_age_max,
	NULL::BOOLEAN AS ducts,
	CASE 
	  WHEN a.sqft8 < 9999999997 THEN a.sqft8
	  ELSE NULL
	END AS totsqft,
	CASE 
	  WHEN c.heatp8 < 997 AND a.sqft8 < 9999999997 AND q.mfhtbtu8 > 0 THEN c.heatp8/100. * a.sqft8
	  ELSE 0
	END AS totsqft_heat,
	CASE 
	  WHEN c.coolp8 < 997 AND a.sqft8 < 9999999997 AND q.mfclbtu8 > 0 THEN c.coolp8/100. * a.sqft8
	  ELSE 0
	END AS totsqft_cool,
	COALESCE(q.mfhtbtu8, 0) AS kbtu_space_heat,
	COALESCE(q.mfclbtu8, 0) AS kbtu_space_cool,
	COALESCE(q.mfwtbtu8, 0) AS kbtu_water_heat
FROM eia.cbecs_2003_microdata_file_01 a
LEFT JOIN eia.cbecs_2003_microdata_file_02 b
	ON a.pubid8 = b.pubid8
LEFT JOIN eia.cbecs_2003_microdata_file_03 c
	ON a.pubid8 = c.pubid8
LEFT JOIN eia.cbecs_2003_microdata_file_04 d
	ON a.pubid8 = d.pubid8
LEFT JOIN eia.cbecs_2003_microdata_file_05 e
	ON a.pubid8 = e.pubid8
LEFT JOIN eia.cbecs_2003_microdata_file_06 f
	ON a.pubid8 = f.pubid8
LEFT JOIN eia.cbecs_2003_microdata_file_07 g
	ON a.pubid8 = g.pubid8
LEFT JOIN eia.cbecs_2003_microdata_file_08 h
	ON a.pubid8 = h.pubid8
LEFT JOIN eia.cbecs_2003_microdata_file_09 i
	ON a.pubid8 = i.pubid8
LEFT JOIN eia.cbecs_2003_microdata_file_10 j
	ON a.pubid8 = j.pubid8
LEFT JOIN eia.cbecs_2003_microdata_file_11 k
	ON a.pubid8 = k.pubid8
LEFT JOIN eia.cbecs_2003_microdata_file_12 l
	ON a.pubid8 = l.pubid8
LEFT JOIN eia.cbecs_2003_microdata_file_13 m
	ON a.pubid8 = m.pubid8
LEFT JOIN eia.cbecs_2003_microdata_file_14 n
	ON a.pubid8 = n.pubid8
LEFT JOIN eia.cbecs_2003_microdata_file_15 o
	ON a.pubid8 = o.pubid8
LEFT JOIN eia.cbecs_2003_microdata_file_16 p
	ON a.pubid8 = p.pubid8
LEFT JOIN eia.cbecs_2003_microdata_file_17 q
	ON a.pubid8 = q.pubid8
where a.pba8 <> 1; -- ignore vacant buildings
-- 5081 rows
