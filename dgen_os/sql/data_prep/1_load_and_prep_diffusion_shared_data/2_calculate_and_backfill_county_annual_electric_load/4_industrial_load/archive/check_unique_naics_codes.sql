SELECT naicscode_3, count(*) as number_of_entities  
from hsip_2012.all_points_with_naics
group by naicscode_3
order by naicscode_3; -- 99 rows



SELECT naicscode_3, table_name, count(*) as number_of_entities  
from hsip_2012.all_points_with_naics
group by naicscode_3, table_name
order by naicscode_3; -- 99 rows


select * FROm hsip_2012.all_points_with_naics
where naicscode_3 = '111'
limit 100;


select naicsdesc
FROM hsip_2012.agri_animal_aquaculture_facilities
where gid in (71,
78,
291,
639,
1062,
1290,
1335,
1468,
1557,
1559,
1657,
1790,
1802,
1826,
1902)




SELECT *
FROM hsip_2012.mnfg_fabricated_metal_product_manufacturing
where naicscode_3 = '111'