library(RPostgreSQL)
library(dplyr)
library(ggplot2)
library(robustbase)
library(reshape2)
# library(wesanderson)
# library(RColorBrewer)
library(grid)
library(stringr)




# connect to postgres
drv = dbDriver("PostgreSQL") 
conn = dbConnect(drv, host='gispgdb', port=5432, dbname='dav-gis', user='mgleason', password='mgleason') 


sql = "with a as
(
  SELECT substring(lower(a.scenario) from 9) as scenario, year, unnest(array['res', 'ind', 'com']) as sector_abbr,
		census_division_abbr, load_multiplier, 
		'2013'::text as data_year
	from diffusion_shared.aeo_load_growth_projections_2013 a
),
b as
(
	select substring(b.scenario from 9), year, sector_abbr,
		census_division_abbr, load_multiplier,
		'2014'::text as data_year
	from diffusion_shared.aeo_load_growth_projections_2014 b
)
select *
FROM a
UNION all
select  *
FROM b;"
load_mp = dbGetQuery(conn, sql)


ggplot(data = load_mp)+
  geom_line(aes(x = year, y = load_multiplier, colour = sector_abbr, linetype = data_year))+
  facet_grid(scenario~census_division_abbr)