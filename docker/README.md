# dGen Docker Usage Guide

By default, the dgen container uses the [Deleware residential dataset](https://oedi-data-lake.s3.amazonaws.com/dgen/de_final_db/dgen_db.sql).

You can customize the dataset, see the [Customizing the Dataset](#customizing-the-dataset) section below.

### Mac and Linux quick start

This quickstart uses docker-compose to run dgen. The default path to store dgen data files and excel configurations is ~/dgen_data/.  This path is shared with your running containers, you can change this path but you will need to edit the `docker-compose.yml` to reflect the data directory of your choice.

Prerequisites assume you are using a Mac and you already installed [Docker Desktop](https://docs.docker.com/desktop/setup/install/mac-install/)

##### Create the data directory
```bash
$ mkdir -p ~/dgen_data/
$ chmod 755 ~/dgen_data/
$ ls -l ~/dgen_data/ # Its expected to be empty, after starting dgen you will see data files in this location.
```

##### Startup the dgen containers
``` bash
$ cd dgen/docker/
$ docker-compose up --build -d
[+] Running 2/2
 ✔ Container dgen_1     Started 0.1s
 ✔ Container postgis_1  Started 0.0s
```

##### Connect to the running containers
``` bash
$ docker attach dgen_1 # Attach to dgen environment container
$ docker attach $(sudo docker ps --filter "name=dgen" --format "{{.ID}}") # If dgen_1 is not found
(dg3n) dgen@cc6e2e5f70b5:/opt/dgen_os/python$ python dgen_model.py # Run scenario
(dg3n) dgen@cc6e2e5f70b5:/opt/dgen_os/python$ exit # to exit
$ docker-compose up -d # If you exit, you have to re-up the container if you want to re-attach
```

### Troubleshooting common issues

#### psycopg2.OperationalError: connection to server

Wait 5-10 minutes for the postgres database to finish starting.

#### General errors and issues

Try clearing your `~/dgen_data` and starting over. Make sure to provide time for the datasets to fully download on the re-attempt.

```bash
$ docker-compose down
$ rm -f ~/dgen_data/*
$ docker system prune -a
$ docker volume prune -f
```

### Disabling auto-start for the dgen virtual environment

By default, logging into the `dgen` container automatically activates the `dgen` virtual environment.  For ease of use, its recommended to leave this the default.

To disable this behavior, edit the `docker-compose.yml` file in this directory and set the following environment variable:

```yaml
services:
  dgen:
    environment:
      DGEN_DISABLE_AUTO_START: 1
```

### Customizing the dataset

By default, the dgen container uses the [Deleware residential dataset](https://oedi-data-lake.s3.amazonaws.com/dgen/de_final_db/dgen_db.sql).

You can find more datasets using the links below:
- [DGen Dataset Submissions on OpenEI](https://data.openei.org/submissions/1931)
- [DGen Dataset S3 Viewer](https://data.openei.org/s3_viewer?bucket=oedi-data-lake&prefix=dgen%2F)

You can customize the dataset used by overriding the DGEN_DATAFILE_URL variable in `docker-compose.yml` and then editing `~/dgen_data/input_sheet_final.xlsm` using Excel.

Below will walk through the process of using the [Colorado residential dataset](https://oedi-data-lake.s3.amazonaws.com/dgen/co_final_db/dgen_db.sql).

Update the `docker-compose.yml` to use the co_final_db sql download and set the variable to force remove the database.  This will result in dataloss from previous runs, if this is a concern, please make backups before proceeding with the below steps.

```yaml
services:
  postgis:
    environment:
      DGEN_DATAFILE_URL: https://oedi-data-lake.s3.amazonaws.com/dgen/co_final_db/dgen_db.sql
      DGEN_AGENTFILE_URL: https://oedi-data-lake.s3.amazonaws.com/dgen/co_final_db/agent_df_base_res_co_revised.pkl
      DGEN_FORCE_DELETE_DATABASE: 1 # Clear all the data in the database to reload the Colorado dataset, Warning this will remove your existing data.
```

Edit the excel document `~/dgen_data/input_sheet_final.xlsm` using Excel (Enable macros), edit the Region to Analyize to `Colorado` and Markets to `Only Residential`, then click Save Scenario.

Restart your containers with the above options.  This will remove all your existing data and download the new Colorado dataset.

```bash
$ docker-compose down
[+] Running 3/3
 ✔ Container dgen_1  Removed  9.2s
 ✔ Container postgis_1  Removed  0.1s

 $ docker-compose up -d
 [+] Running 2/2
 ✔ Container dgen_1     Started 0.1s
 ✔ Container postgis_1  Started 0.2s
 ```

After you load the new Colorado dataset, remove the DGEN_FORCE_DELETE_DATABASE option to prevent future accidental data loss.

```yaml
services:
  postgis:
    environment:
      DGEN_FORCE_DELETE_DATABASE: 0
```

You can now attach to the dgen container and monitor the data download.  This may take 5-10 minutes depending on your internet speed, if the file size is increasing its still downloading.

```bash
$ docker attach dgen_1
(dg3n) dgen@cc6e2e5f70b5:/opt/dgen_os/python$ ls -lh /data/dgen_db.sql
-rw-r--r-- 1 dgen dgen 705M Jan 29  2025 /data/dgen_db.sql
(dg3n) dgen@cc6e2e5f70b5:/opt/dgen_os/python$ python dgen_model.py # Run scenario
(dg3n) dgen@cc6e2e5f70b5:/opt/dgen_os/python$ exit # to exit
```

### Stop running containers
```bash
$ docker ps -a
CONTAINER ID   IMAGE                           COMMAND                  CREATED          STATUS          PORTS                    NAMES
259c30e6b518   docker-postgis                  "docker-entrypoint.s…"   12 minutes ago   Up 12 minutes   0.0.0.0:5432->5432/tcp   postgis_1
a775696276eb   docker-dgen                     "bash --login"           12 minutes ago   Up 4 seconds                             dgen_1

$ docker-compose down
[+] Running 3/3
 ✔ Container dgen_1  Removed  10.1s
 ✔ Container postgis_1  Removed  0.1s
```

### Warning: This will remove old running containers and data volumes.  This may be required if you need space.

```bash
$ docker system prune -a
$ docker volume prune -f
```