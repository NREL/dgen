FROM continuumio/miniconda3

# Install common CLI tools (dos2unix is required for Windows)
RUN apt-get update && \
    apt-get install -y dos2unix vim nano

# Create dgen user
RUN groupadd --gid 999 dgen && \
    useradd --uid 999 --gid dgen --create-home dgen

# Create data directory
RUN mkdir -p /data && chmod 755 /data

# Copy dgen_os directory (includes code, Excel templates, prepare script, etc.)
COPY ./dgen_os/ /opt/dgen_os/
RUN chown -R dgen: /opt/dgen_os /data

# Ensure Windows-compatible permissions
RUN find /opt/dgen_os/ -type d -exec chmod u+rwx {} \;

# Copy the states CSV lookup for full names
COPY states.csv /opt/dgen_os/python/states.csv
RUN chown dgen: /opt/dgen_os/python/states.csv

# Make the scenario prep helper executable
RUN chmod +x /opt/dgen_os/python/prepare_all_scenarios.py

# Copy and configure the init script
COPY docker/dgen/init.sh /docker-entrypoint-initdb.d/init-dgen.sh
RUN chmod 755 /docker-entrypoint-initdb.d/init-dgen.sh && \
    dos2unix /docker-entrypoint-initdb.d/init-dgen.sh

# Auto-activate the Conda env and run init script for root
RUN echo 'if [[ -z ${DGEN_DISABLE_AUTO_START} ]] || [[ ${DGEN_DISABLE_AUTO_START:-0} -eq 0 ]]; then \
    conda activate dg3n && \
    cd /opt/dgen_os/python/ && \
    /docker-entrypoint-initdb.d/init-dgen.sh; \
fi' >> ~dgen/.bashrc
RUN chown dgen: ~dgen/.bashrc

# Switch to non-root user
USER dgen

# Create the Conda environment
RUN conda env create -f /opt/dgen_os/python/dg3n.yml

# Launch an interactive shell by default (or override with your commands)
CMD ["bash", "--login"]
