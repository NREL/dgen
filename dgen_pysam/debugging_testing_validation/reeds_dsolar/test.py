# -*- coding: utf-8 -*-
"""
Created on Mon Oct  5 11:26:55 2015

@author: mgleason
"""
import sys
import pandas as pd
import os
cur_path = os.path.realpath(os.curdir)
os.chdir('/Users/mgleason/NREL_Projects/github/diffusion/python') # TODO: Change this to the local directory
import dgen_model
reload(dgen_model)

year = 2014
endyr_ReEDS = 2050
reeds_path = "C:/ReEDS/OtherReEDSProject/inout"
gams_path = "C:/Gams/win64/24.1/bin"
curtailment_method = "off"

UPVCC_all = pd.read_csv(os.path.join(cur_path, 'upvcc.csv'))
annual_distPVSurplusMar = pd.read_csv(os.path.join(cur_path, 'SurplusMar.csv'))
retail_elec_price = pd.read_csv(os.path.join(cur_path, 'elecprice.csv'))
change_elec_price = pd.read_csv(os.path.join(cur_path, 'changeelecprice.csv'))

ReEDS_df = {'UPVCC_all': UPVCC_all, 'annual_distPVSurplusMar': annual_distPVSurplusMar, 
'retail_elec_price': retail_elec_price, 'change_elec_price':change_elec_price}


ReEDS_inputs = {'ReEDS_df': ReEDS_df, 'curtailment_method':curtailment_method}

df, cf_by_pca_and_ts = dgen_model.main(mode = 'ReEDS', resume_year = year, endyear = endyr_ReEDS, ReEDS_inputs = ReEDS_inputs)


