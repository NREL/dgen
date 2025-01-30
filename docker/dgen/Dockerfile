FROM continuumio/miniconda3

# Setup dgen user
RUN groupadd --gid 999 dgen && useradd --uid 999 --gid dgen --create-home dgen

# Setup Data directory
RUN mkdir -p /data && chmod 755 /data

# Copy dgen files and setup permissions
COPY ./dgen_os/ /opt/dgen_os/
RUN chown -R dgen: /opt/dgen_os /data

# Install dgen
RUN conda env create -f /opt/dgen_os/python/dg3n.yml

# Setup Init script
COPY docker/dgen/init.sh /docker-entrypoint-initdb.d/init-dgen.sh
RUN chmod +x /docker-entrypoint-initdb.d/init-dgen.sh

# Initialize Conda in the Docker environment
RUN cat <<EOF >> ~dgen/.bashrc
if [[ -z \${DGEN_DISABLE_AUTO_START} ]] || [[ ${DGEN_DISABLE_AUTO_START:-0} -eq 0 ]]; then
    conda activate dg3n
    cd /opt/dgen_os/python/
    /docker-entrypoint-initdb.d/init-dgen.sh
fi
EOF

# Change ownership of the bashrc file
RUN chown dgen: ~dgen/.bashrc

# Setup default input_sheet_final.xlsm (Deleware residential)
COPY docker/dgen/input_sheet_final.xlsm /opt/dgen_os/excel/input_sheet_final.xlsm
RUN chmod 755 /opt/dgen_os/excel/input_sheet_final.xlsm && chown dgen: /opt/dgen_os/excel/input_sheet_final.xlsm

# Switch to non-root user
USER dgen

CMD ["bash", "--login"]