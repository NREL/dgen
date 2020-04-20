import pandas
import os
import glob


csv_list = [os.path.join(dirpath, f) for dirpath, dirnames, files in os.walk(os.getcwd()) for f in files if f.endswith('.csv')]

for csv in csv_list:
    name = os.path.basename(csv).split()[0]
    df = pandas.DataFrame.from_csv(csv)

    new_cols = []
    sector_cols = {}
    for col in df.columns:
        sector = col.split()[-1]
        if sector in ['res', 'com', 'ind', 'nonres']:
            col_name = "_".join(col.split()[0:-2])
            new_cols.append(col_name)
            split_cols.append(col)

        else:
            new_cols.append(col)





