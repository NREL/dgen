library(RPostgreSQL)
library(dplyr)
library(ggplot2)
library(robustbase)
library(reshape2)
library(wesanderson)

# connect to postgres
drv = dbDriver("PostgreSQL") 
conn = dbConnect(drv, host='gispgdb.nrel.gov', port=5432, dbname='dav-gis', user='mgleason', password='mgleason') 

# THIS IS ALL COVERAGE (VERIFIED AND SINGULAR)
sql = "WITH a as
        (
          SELECT DISTINCT(ventyx_company_id_2014) as ventyx_company_id_2014
        	FROM urdb_rates.urdb3_verified_and_singular_ur_names_20141202
        )
      	SELECT  a.ventyx_company_id_2014 IS NOT NULL as covered,
                b.bundled_energy_only_delivery_only_residential_revenue_000s as res_revenue_000s,
            		b.bundled_delivery_only_residential_sales_mwh as res_sales_mwh,
            		b.bundled_delivery_only_residential_customers as res_customers,
            
            		b.bundled_energy_only_delivery_only_commercial_revenue_000s as com_revenue_000s,
            		b.bundled_delivery_only_commercial_sales_mwh as com_sales_mwh,
            		b.bundled_delivery_only_commercial_customers as com_customers,
            
            		b.bundled_energy_only_delivery_only_industrial_revenue_000s as ind_revenue_000s,
            		b.bundled_delivery_only_industrial_sales_mwh  as ind_sales_mwh,
            		b.bundled_delivery_only_industrial_customers as ind_customers
      	FROM ventyx.retail_sales_2012_20140305 b
      	LEFT JOIN a
        ON a.ventyx_company_id_2014 = b.company_id::text;"

urdb_coverage = dbGetQuery(conn, sql)

g = group_by(urdb_coverage, covered)

s = as.data.frame(
                summarize(g, 
                  res_customers = sum(res_customers, na.rm = T),
                  com_customers = sum(com_customers, na.rm = T),
                  ind_customers = sum(ind_customers, na.rm = T),
                  res_load = sum(res_sales_mwh, na.rm = T),
                  com_load = sum(com_sales_mwh, na.rm = T),
                  ind_load = sum(ind_sales_mwh, na.rm = T)
              )
)

total_customers_res = sum(urdb_coverage$res_customers, na.rm = T)
total_customers_com = sum(urdb_coverage$com_customers, na.rm = T)
total_customers_ind = sum(urdb_coverage$ind_customers, na.rm = T)
total_load_res = sum(urdb_coverage$res_sales_mwh, na.rm = T)
total_load_com = sum(urdb_coverage$com_sales_mwh, na.rm = T)
total_load_ind = sum(urdb_coverage$ind_sales_mwh, na.rm = T)


# calculate percentages
s$res_customers_pct = s$res_customers/total_customers_res
s$com_customers_pct = s$com_customers/total_customers_com
s$ind_customers_pct = s$ind_customers/total_customers_ind

s$res_load_pct = s$res_load/total_load_res
s$com_load_pct = s$com_load/total_load_com
s$ind_load_pct = s$ind_load/total_load_ind

# THIS IS JUST COVERAGE FOR VERIFIED
sql = "WITH a as
        (
          SELECT DISTINCT(a.ventyx_company_id_2014) as ventyx_company_id_2014
          FROM urdb_rates.urdb3_verified_and_singular_ur_names_20141202 a
          INNER JOIN urdb_rates.urdb3_verified_rates_lookup_20141202 b
            ON a.ur_name = b.utility_name
        )
        SELECT  a.ventyx_company_id_2014 IS NOT NULL as covered,
        b.bundled_energy_only_delivery_only_residential_revenue_000s as res_revenue_000s,
        b.bundled_delivery_only_residential_sales_mwh as res_sales_mwh,
        b.bundled_delivery_only_residential_customers as res_customers,
        
        b.bundled_energy_only_delivery_only_commercial_revenue_000s as com_revenue_000s,
        b.bundled_delivery_only_commercial_sales_mwh as com_sales_mwh,
        b.bundled_delivery_only_commercial_customers as com_customers,
        
        b.bundled_energy_only_delivery_only_industrial_revenue_000s as ind_revenue_000s,
        b.bundled_delivery_only_industrial_sales_mwh  as ind_sales_mwh,
        b.bundled_delivery_only_industrial_customers as ind_customers
        FROM ventyx.retail_sales_2012_20140305 b
        LEFT JOIN a
        ON a.ventyx_company_id_2014 = b.company_id::text;"

urdb_coverage_ver = dbGetQuery(conn, sql)

gv = group_by(urdb_coverage_ver, covered)

sv = as.data.frame(
                summarize(gv, 
                  res_customers = sum(res_customers, na.rm = T),
                  com_customers = sum(com_customers, na.rm = T),
                  ind_customers = sum(ind_customers, na.rm = T),
                  res_load = sum(res_sales_mwh, na.rm = T),
                  com_load = sum(com_sales_mwh, na.rm = T),
                  ind_load = sum(ind_sales_mwh, na.rm = T)
              )
)

total_customers_res_v = sum(urdb_coverage_ver$res_customers, na.rm = T)
total_customers_com_v = sum(urdb_coverage_ver$com_customers, na.rm = T)
total_customers_ind_v = sum(urdb_coverage_ver$ind_customers, na.rm = T)
total_load_res_v = sum(urdb_coverage_ver$res_sales_mwh, na.rm = T)
total_load_com_v = sum(urdb_coverage_ver$com_sales_mwh, na.rm = T)
total_load_ind_v = sum(urdb_coverage_ver$ind_sales_mwh, na.rm = T)


# calculate percentages
sv$res_customers_pct = sv$res_customers/total_customers_res_v
sv$com_customers_pct = sv$com_customers/total_customers_com_v
sv$ind_customers_pct = sv$ind_customers/total_customers_ind_v

sv$res_load_pct = sv$res_load/total_load_res_v
sv$com_load_pct = sv$com_load/total_load_com_v
sv$ind_load_pct = sv$ind_load/total_load_ind_v

