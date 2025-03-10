#!/bin/bash
set -e

DB_AGENT_FILE="${DGEN_AGENTFILE:-/data/agent_df_base_revised.pkl}"
FORCE_DELETE_DATABASE=${DGEN_FORCE_DELETE_DATABASE:-0}

# Update the database connection parameters if using a different database name
if [ ! -z "${DATABASE_HOSTNAME}" ]; then
    sed -i "s/127.0.0.1/${DATABASE_HOSTNAME}/g" /opt/dgen_os/python/pg_params_connect.json
fi

# Update the database connection parameters if using a different database port
if [ ! -z "${DGEN_DB_PORT}" ]; then
    sed -i "s/5432/${DGEN_DB_PORT}/g" /opt/dgen_os/python/pg_params_connect.json
fi

# Setup Default Input Scenarios
if [[ ! -f /data/input_sheet_final.xlsm ]]; then
    cp /opt/dgen_os/excel/input_sheet_final.xlsm /data/input_sheet_final.xlsm
fi

# Setup Input Scenarios
rm -f /opt/dgen_os/input_scenarios/*
ln -s /data/input_sheet_final.xlsm /opt/dgen_os/input_scenarios/input_sheet_final.xlsm

# Setup Input Agent
rm -f /opt/dgen_os/input_agents/*
ln -s ${DB_AGENT_FILE} /opt/dgen_os/input_agents/$(basename "${DB_AGENT_FILE}")