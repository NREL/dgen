import psycopg2
import pandas as pd
from sqlalchemy import create_engine
import json
from pandas.io.json import json_normalize


engine = create_engine('postgresql://mmooney@gispgdb.nrel.gov:5432/dav-gis')
sql = 'select rate_id_alias, cast(json as text) from diffusion_data_shared.urdb_rates_sam_min_max'
df = pd.read_sql(sql, engine)


dtou = []
etou = []

kwh_min, kwh_max  = [], []
kw_min, kw_max = [], []

for i,ii in enumerate (df['json']):
		x = json_normalize(json.loads(df['json'][i]))
		dtou.append(x['d_tou_exists'][0])
		etou.append(x['e_tou_exists'][0])

		#kw_min.append(x['peak_kW_capacity_min'][0])
		#kw_max.append(x['peak_kW_capacity_max'][0])
		#kwh_min.append(x['kWh_useage_min'][0])
		#kwh_min.append(x['kWh_useage_max'][0])




df2 = pd.DataFrame({'rate_id_alias': df['rate_id_alias'].values, 'dtou': dtou, 'etou': etou})

df2.to_sql('urdb_rates_same_min_max_2', engine, schema='diffusion_data_shared', if_exists='replace', index = False)
