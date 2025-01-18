FROM continuumio/miniconda3

# Setup Data
RUN mkdir -p /data
RUN chmod 755 /data

# Copy dgen files
COPY ./dgen_os/ /opt/dgen_os/

# Install dgen
RUN conda env create -f /opt/dgen_os/python/dg3n.yml

# Setup Init script
COPY docker/dgen/init.sh /docker-entrypoint-initdb.d/init-dgen.sh
RUN chmod +x /docker-entrypoint-initdb.d/init-dgen.sh

# Initialize Conda in the Docker environment
RUN echo "conda activate dg3n" >> ~/.bashrc
RUN echo "cd /opt/dgen_os/python/" >> ~/.bashrc
RUN echo "/docker-entrypoint-initdb.d/init-dgen.sh" >> ~/.bashrc

CMD ["bash", "--login"]