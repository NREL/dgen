FROM postgis/postgis:11-3.3

# Setup Data
RUN mkdir -p /data
RUN chmod 755 /data

# Install curl for downloading the data file
RUN apt-get update && apt-get install curl -y

# Setup Init script
COPY docker/postgis/init.sh /docker-entrypoint-initdb.d/init-dgen-pg.sh
RUN chmod +x /docker-entrypoint-initdb.d/init-dgen-pg.sh

# Expose PostgreSQL port
EXPOSE 5432

# Use the default PostgreSQL entrypoint
CMD ["postgres"]