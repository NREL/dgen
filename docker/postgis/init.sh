#!/bin/bash
set -e

DB_USER="postgres"
DB_NAME="dgen_db"
DB_SQL_FILE="/data/dgen_db.sql"
DB_SQL_FILE_URL="https://oedi-data-lake.s3.amazonaws.com/dgen/de_final_db/dgen_db.sql"

# Check if the data file already exists
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