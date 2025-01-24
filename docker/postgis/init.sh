#!/bin/bash
set -e

DB_USER="${DGEN_DB_USER:-postgres}"
DB_NAME="${DGEN_DB_NAME:-dgen_db}"
DB_SQL_FILE="${DGEN_DATAFILE:-/data/dgen_db.sql}"
DB_SQL_FILE_URL="${DGEN_DATAFILE_URL:-https://oedi-data-lake.s3.amazonaws.com/dgen/de_final_db/dgen_db.sql}"
DB_AGENT_FILE="${DGEN_AGENTFILE:-/data/agent_df_base_revised.pkl}"
DB_AGENT_FILE_URL="${DGEN_AGENTFILE_URL:-https://oedi-data-lake.s3.amazonaws.com/dgen/de_final_db/agent_df_base_res_de_revised.pkl}"
FORCE_DELETE_DATABASE=${DGEN_FORCE_DELETE_DATABASE:-0}

# Clear database if FORCE_DELETE_DATABASE is enabled
if [[ ${FORCE_DELETE_DATABASE} -eq 1 ]]; then
    echo "DGEN_FORCE_DELETE_DATABASE is set to 1. Dropping database '${DB_NAME}' if it exists..."
    psql -U "${DB_USER}" -tc "SELECT 1 FROM pg_database WHERE datname = '${DB_NAME}';" | grep -q 1 && \
    psql -U "${DB_USER}" -c "DROP DATABASE ${DB_NAME};"
    echo "Database '${DB_NAME}' dropped."
    rm -f ${DB_SQL_FILE}
    echo "Datafile '${DB_SQL_FILE}' removed."
    rm -f ${DB_AGENT_FILE}
    echo "Datafile '${DB_AGENT_FILE}' removed."
fi

# Check if the data file already exists, download if not
if [[ ! -f ${DB_AGENT_FILE} ]]; then
    echo "Downloading data file..."
    curl -o ${DB_AGENT_FILE} ${DB_AGENT_FILE_URL}
fi

# Check if the data file already exists, download if not
if [[ ! -f ${DB_SQL_FILE} ]]; then
    echo "Downloading data file..."
    curl -o ${DB_SQL_FILE} ${DB_SQL_FILE_URL}
fi

# Check if the database already exists
if psql -U "${DB_USER}" -tc "SELECT 1 FROM pg_database WHERE datname = '${DB_NAME}';" | grep -q 1; then
    echo "Database '${DB_NAME}' already exists, skipping initialization..."
else
    # Create the database
    echo "Creating database ${DB_NAME}..."
    psql -U ${DB_USER} -c "CREATE DATABASE ${DB_NAME};"

    # Load the dataset into the database
    echo "Loading data into ${DB_NAME}..."
    psql -U ${DB_USER} -d ${DB_NAME} -f ${DB_SQL_FILE}
    echo "Database initialization complete!"
fi