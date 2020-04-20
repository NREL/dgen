library(RPostgreSQL)
library(reshape2)
library(stringr)
library(dplyr)

drv = dbDriver("PostgreSQL") 
conn = dbConnect(drv, host='gispgdb.nrel.gov', port=5432, dbname='dav-gis', user='mgleason', password='mgleason')

# read in the raw data from kevin
df = read.csv('/Volumes/Staff/mgleason/dGeo/Data/Source_Data/Thermal_Demand_kmccabe/comm_demand_by_county_and_cdms_bldg_type_2016_03_21.csv', check.names = F)

#################################################################################
# QAQC
# 1 -  do the values sum back to the census division totals?
g = group_by(df, division_abbr) %>%
  summarize(
    resum_spht_total_division = sum(county_spht_mbtu),
    resum_wtht_total_division = sum(county_wtht_mbtu),
    resum_cool_total_division = sum(county_cool_mbtu),
    act_spht_total_division = min(spht_total_mbtu_division),
    act_wtht_total_division = min(wtht_total_mbtu_division),
    act_cool_total_division = min(cool_total_mbtu_division)
  )
round(max(g$resum_spht_total_division - g$act_spht_total_division), 2)
round(max(g$resum_wtht_total_division - g$act_wtht_total_division), 2)
round(max(g$resum_cool_total_division - g$act_cool_total_division), 2)
# all zeros --> all set


# 2 - how close are the "estimated" values to the recalibrated final values?
# first, check at the county level
cdf = group_by(df, county_id) %>%
  summarize(
    spht_est_mbtu = sum(spht_est_mbtu),
    wtht_est_mbtu = sum(wtht_est_mbtu),
    cool_est_mbtu = sum(cool_est_mbtu),
    county_spht_mbtu = sum(county_spht_mbtu),
    county_wtht_mbtu = sum(county_wtht_mbtu),
    county_cool_mbtu = sum(county_cool_mbtu)
  )

max(cdf$spht_est_mbtu/cdf$county_spht_mbtu) # .86
mean(cdf$spht_est_mbtu/cdf$county_spht_mbtu) # .72
min(cdf$spht_est_mbtu/cdf$county_spht_mbtu) # .63

max(cdf$wtht_est_mbtu/cdf$county_wtht_mbtu) # .91
mean(cdf$wtht_est_mbtu/cdf$county_wtht_mbtu) # .67
min(cdf$wtht_est_mbtu/cdf$county_wtht_mbtu) # .50

max(cdf$cool_est_mbtu/cdf$county_cool_mbtu) # 1.05
mean(cdf$cool_est_mbtu/cdf$county_cool_mbtu) # 0.69
min(cdf$cool_est_mbtu/cdf$county_cool_mbtu) # 0.59
# values are all a little low, but
# all very reasonable underestimates

# how do the square footage values compare at the census division level to what is in CBECS?
sf = group_by(df, division_abbr) %>%
  summarize(
    total_sqft = sum(sqft)/1e6
  )

# division_abbr total_sqft
# 1           ENC   7851.034
# 2           ESC   3078.733
# 3            MA   7016.265
# 4           MTN   2681.889
# 5            NE   2785.881
# 6           PAC   6241.667
# 7            SA   9609.237
# 8           WNC   3606.654
# 9           WSC   4956.045

# values from CBECS (https://www.eia.gov/consumption/commercial/data/archive/cbecs/cbecs2003/detailed_tables_2003/2003set1/2003html/a1.html)
# ENC  12,424
# ESC  3,719	
# MA  10,543	
# MTN  4,207	
# NE  3,452
# PAC  8,613
# SA	13,999	
# WNC  5,680		
# WSC	9,022		
# 
# cbecs/hazus
12424/7851.034 #ENC
3719/3078.733 #ESC
10543/7016.265 #MA
4207/2681.889 #MTN
3452/2785.881 #NE
8613/6241.667 #PAC
13999/9609.237 #SA
5680/3606.654 #WNC
9022/4956.045 #WSC
# cbecs values are 1.25-1.8x the CDMS values

# hazus/cbecs
7851.034/12424 #ENC
3078.733/3719 #ESC
7016.265/10543 #MA
2681.889/4207 #MTN
2785.881/3452 #NE
6241.667/8613 #PAC
9609.237/13999 #SA
3606.654/5680 #WNC
4956.045/9022 #WSC
# CDMS values are 0.5-0.8x the cbecs values
# so, if intensity values are to be trusted,
# the "estimated" values should be roughly 0.5-0.8x the recalibrated
# values

# check this again at the census division level
ddf = group_by(df, division_abbr) %>%
  summarize(
    spht_est_mbtu = sum(spht_est_mbtu),
    wtht_est_mbtu = sum(wtht_est_mbtu),
    cool_est_mbtu = sum(cool_est_mbtu),
    county_spht_mbtu = sum(county_spht_mbtu),
    county_wtht_mbtu = sum(county_wtht_mbtu),
    county_cool_mbtu = sum(county_cool_mbtu)
  )

ddf$spht_ratio = ddf$spht_est_mbtu/ddf$county_spht_mbtu
ddf$wtht_ratio = ddf$wtht_est_mbtu/ddf$county_wtht_mbtu
ddf$cool_ratio = ddf$cool_est_mbtu/ddf$county_cool_mbtu

ddf[, c('division_abbr', 'spht_ratio', 'wtht_ratio', 'cool_ratio')]
# ratios are ~600-1000, which are way high, but due to a unit issue, if you divide by 1000, they are all a little low

# expected ratios based on SF would be
7851.034/12424 #ENC 0.63
3078.733/3719 #ESC  0.82
7016.265/10543 #MA  0.67
2681.889/4207 #MTN  0.64
2785.881/3452 #NE   0.81
6241.667/8613 #PAC  0.72
9609.237/13999 #SA  0.68
3606.654/5680 #WNC  0.63
4956.045/9022 #WSC  0.55
# these are very well aligned with the ratios
