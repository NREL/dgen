#!/bin/bash
set -e

# Update the database connection parameters if using a different database name
if [ ! -z "${DATABASE_HOSTNAME}" ]; then
    sed -i "s/127.0.0.1/${DATABASE_HOSTNAME}/g" /opt/dgen_os/python/pg_params_connect.json
fi

# Setup Input Scenarios
rm -f /opt/dgen_os/input_scenarios/*
cp /opt/dgen_os/excel/input_sheet_final.xlsm /data/input_sheet_final.xlsm
ln -s /data/input_sheet_final.xlsm /opt/dgen_os/input_scenarios/input_sheet_final.xlsm

# Setup Input Agent
#rm -f /opt/dgen_os/input_agents/*
#ln -s /data/agent_df_base_res_de_revised.pkl /opt/dgen_os/input_agents/agent_df_base_res_de_revised.pkl