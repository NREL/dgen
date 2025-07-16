FROM postgis/postgis:11-3.3

# Setup Data
RUN mkdir -p /data && chmod 755 /data && chown -R postgres: /data/

# Install curl for downloading the data file
RUN apt-get update && apt-get install curl dos2unix -y

# Setup Init script
COPY docker/postgis/init.sh /bin/init-dgen-pg.sh
RUN chmod +x /bin/init-dgen-pg.sh && chown postgres: /bin/init-dgen-pg.sh
RUN dos2unix /bin/init-dgen-pg.sh

# Switch to Postgres user
USER postgres

# Expose PostgreSQL port
EXPOSE 5432

# Override the PostgreSQL entrypoint for the dgen init setup
CMD ["bash", "-c", "docker-entrypoint.sh postgres & until pg_isready; do sleep 1; done && /bin/init-dgen-pg.sh && wait"]