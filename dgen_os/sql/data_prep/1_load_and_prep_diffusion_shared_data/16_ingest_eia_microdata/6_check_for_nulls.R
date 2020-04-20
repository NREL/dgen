library(dplyr)
library(RPostgreSQL)
library(reshape2)

drv <- dbDriver("PostgreSQL")
# connect to postgres
con <- dbConnect(drv, host="gispgdb.nrel.gov", dbname="dav-gis", user="mgleason", password="mgleason")

# ------------------------------------------------------------------------------------------------------------------------
# RECS

sql = "select *
      FROM diffusion_shared.eia_microdata_recs_2009_expanded_bldgs;"
recs = dbGetQuery(con, sql)

s = summary(is.na(recs))
s

# building_id     sample_wt       census_region   census_division_abbr reportable_domain climate_zone   
# Mode :logical   Mode :logical   Mode :logical   Mode :logical        Mode :logical     Mode :logical  
# FALSE:12083     FALSE:12083     FALSE:12083     FALSE:12083          FALSE:12083       FALSE:12083    
# NA's :0         NA's :0         NA's :0         NA's :0              NA's :0           NA's :0        
# 
# pba          pbaplus        roof_material   owner_occupied     kwh          year_built     
# Mode:logical   Mode:logical   Mode :logical   Mode :logical   Mode :logical   Mode :logical  
# TRUE:12083     TRUE:12083     FALSE:12083     FALSE:12083     FALSE:12083     FALSE:12083    
# NA's:0         NA's:0         NA's :0         NA's :0         NA's :0         NA's :0        
# 
# single_family_res num_tenants     num_floors      space_heat_equip space_heat_fuel space_heat_age_min
# Mode :logical     Mode :logical   Mode :logical   Mode :logical    Mode :logical   Mode :logical     
# FALSE:12083       FALSE:12083     FALSE:12083     FALSE:12083      FALSE:12083     FALSE:11934       
# NA's :0           NA's :0         NA's :0         NA's :0          NA's :0         TRUE :149         
#                                                                                     NA's :0           
# space_heat_age_max water_heat_equip water_heat_fuel water_heat_age_min water_heat_age_max
# Mode :logical      Mode :logical    Mode :logical   Mode :logical      Mode :logical     
# FALSE:11934        FALSE:12083      FALSE:12083     FALSE:12049        FALSE:12049       
# TRUE :149          NA's :0          NA's :0         TRUE :34           TRUE :34          
# NA's :0                                             NA's :0            NA's :0           
#  space_cool_equip space_cool_fuel space_cool_age_min space_cool_age_max   ducts          totsqft       
#  Mode :logical    Mode :logical   Mode :logical      Mode :logical      Mode :logical   Mode :logical  
#  FALSE:12083      FALSE:12083     FALSE:9940         FALSE:9940         FALSE:12083     FALSE:12083    
#  NA's :0          NA's :0         TRUE :2143         TRUE :2143         NA's :0         NA's :0        
#                                   NA's :0            NA's :0                                           
#  totsqft_heat    totsqft_cool    kbtu_space_heat kbtu_space_cool kbtu_water_heat
#  Mode :logical   Mode :logical   Mode :logical   Mode :logical   Mode :logical  
#  FALSE:12083     FALSE:12083     FALSE:12083     FALSE:12083     FALSE:12083    
#  NA's :0         NA's :0         NA's :0         NA's :0         NA's :0     

# ONLY vars with nulls are:
# space_heat_age_min
# space_heat_age_max
# water_heat_age_min
# water_heat_age_max
# space_cool_age_min
# space_cool_age_max

# why??
filter(recs, is.na(space_heat_age_min)) %>%
    summarize(unique(space_heat_equip))
filter(recs, is.na(space_heat_age_max)) %>%
  summarize(unique(space_heat_equip))
# no heating equipment


filter(recs, is.na(space_cool_age_min)) %>%
  summarize(unique(space_cool_equip))
filter(recs, is.na(space_cool_age_max)) %>%
  summarize(unique(space_cool_equip))
# no cooling equipment

filter(recs, is.na(water_heat_age_min)) %>%
  summarize(unique(water_heat_equip))
filter(recs, is.na(water_heat_age_max)) %>%
  summarize(unique(water_heat_equip))
# no water heating equipment
# all seems ok

# look for values of -2 (commonly used to indicate NA)
summary(recs)
# none show up

# we seem to be all set for RECS
# ------------------------------------------------------------------------------------------------------------------------
# CBECS

sql = "select *
      FROM diffusion_shared.eia_microdata_cbecs_2003_expanded;"
cbecs = dbGetQuery(con, sql)

s = summary(is.na(cbecs))
s

# building_id     sample_wt       census_region   census_division_abbr reportable_domain climate_zone   
# Mode :logical   Mode :logical   Mode :logical   Mode :logical        Mode:logical      Mode :logical  
# FALSE:4820      FALSE:4820      FALSE:4820      FALSE:4820           TRUE:4820         FALSE:4820     
# NA's :0         NA's :0         NA's :0         NA's :0              NA's:0            NA's :0        
# pba           pbaplus        roof_material   owner_occupied     kwh          year_built     
# Mode :logical   Mode :logical   Mode :logical   Mode :logical   Mode :logical   Mode :logical  
# FALSE:4820      FALSE:4820      FALSE:4820      FALSE:4820      FALSE:4820      FALSE:4820     
# NA's :0         NA's :0         NA's :0         NA's :0         NA's :0         NA's :0        
# single_family_res num_tenants     num_floors      space_heat_equip space_heat_fuel space_heat_age_min
# Mode :logical     Mode :logical   Mode :logical   Mode :logical    Mode :logical   Mode :logical     
# FALSE:4820        FALSE:4820      FALSE:4820      FALSE:4820       FALSE:4820      FALSE:4820        
# NA's :0           NA's :0         NA's :0         NA's :0          NA's :0         NA's :0           
# space_heat_age_max water_heat_equip water_heat_fuel water_heat_age_min water_heat_age_max
# Mode :logical      Mode :logical    Mode :logical   Mode :logical      Mode :logical     
# FALSE:4820         FALSE:4820       FALSE:4820      FALSE:4820         FALSE:4820        
# NA's :0            NA's :0          NA's :0         NA's :0            NA's :0           
#  space_cool_equip space_cool_fuel space_cool_age_min space_cool_age_max  ducts          totsqft       
#  Mode :logical    Mode :logical   Mode :logical      Mode :logical      Mode:logical   Mode :logical  
#  FALSE:4820       FALSE:4820      FALSE:4820         FALSE:4820         TRUE:4820      FALSE:4820     
#  NA's :0          NA's :0         NA's :0            NA's :0            NA's:0         NA's :0        
#  totsqft_heat    totsqft_cool    kbtu_space_heat kbtu_space_cool kbtu_water_heat
#  Mode :logical   Mode :logical   Mode :logical   Mode :logical   Mode :logical  
#  FALSE:4820      FALSE:4820      FALSE:4820      FALSE:4820      FALSE:4820     
#  NA's :0         NA's :0         NA's :0         NA's :0         NA's :0        


# no nulls remain
summary(cbecs)
