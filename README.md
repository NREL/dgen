<p align="center">
 <img src="https://github.com/NREL/dgen/blob/master/docs/figs/dGen-logo-lrg.png" />
</p>

The Distributed Generation Market Demand (dGen) Model
=====================================================

<p align="center">
 <a href="https://github.com/NREL/dgen/releases/latest">
  <img src="https://img.shields.io/github/v/release/NREL/dgen">
 </a>
 <a href="https://nrel.github.io/dgen/">
  <img src="https://img.shields.io/badge/docs-ready-blue.svg">
 </a>
</p>


## Documentation
- [Webinar and Setup Tutorial](https://youtu.be/-Te5_KKZR8o)
- [Official dGen Documentation](https://nrel.github.io/dgen/) 
- [Wiki](https://github.com/NREL/dgen/wiki)

Note, after September 30th 2021 the model will be updated to version 2.0.0 and use parquet, rather than pickle (.pkl) formatted agent files. The agent data will be unchanged and the new parquet agent files can be found in [OEDI](https://data.openei.org/submissions/1931). If you wish to continue using version 1.0.0 with the pickle formatted agent files then you can find these agent files [here](https://data.nrel.gov/submissions/169).

## Get Your Tools
Install Docker for [(Mac)](https://docs.docker.com/docker-for-mac/install/) or [(Windows)](https://docs.docker.com/docker-for-windows/install/)

- Important: In Docker, go into Docker > Preferences > Resources and up the allocation for disk size image for Docker. 16 GB is recommended for smaller (state level) databasese. 32 GB is recommended for ISO specific databases. 70+GB is required for restoring the national level database. If you get a memory issue then you'll need to up the memory allocation and or will need to prune past failed images/volumes. Running the below docker commands will clear these out and let you start fresh:
```
   $ docker system prune -a 
   $ docker volume prune -f
``` 
- Please refer to Docker’s [documentation](https://docs.docker.com/reference/) for more details.

- Install [Anaconda for Python 3.7](https://www.anaconda.com/distribution/). Users with VPNs may need to turn their VPNs off while installing or updating Anaconda.

- Install [PgAdmin](https://www.pgadmin.org/download/). Ignore all of the options for docker, python, os host, etc.

- Install Git: If you don't already have git installed, then navigate [here](https://www.atlassian.com/git/tutorials/install-git) to install it for your operating system.

Windows users: 
- We recommend using Powershell.
- If you don't have UNIX commands enabled for command prompt/powershell then you'll need to install Cygwin or QEMU to run a UNIX terminal.

## Download Code 
Users need to fork a copy of the dGen repo to their own private github account. 

Next, clone the forked repository to your local machine by running the following in a terminal/powershell/command prompt:
```$ git clone https://github.com/<github_username>/dgen.git```


# Running and Configuring dGen

### A. Create Environment
After cloning this repository and installing (and running) Docker as well as Anaconda, we'll create our environment and container:

1. Depending on directory you cloned this repo into, navigate in terminal to the python directory (/../dgen/python) and run the following command:

```$ conda env create -f dg3n.yml```

- This will create the conda environment needed to run the dgen model.
- The dgen model is optimized for Python v3 and above. Run ```$ conda list ``` to verify you have this version.

2. This command will create a container with PostgreSQL initialized.

```$ docker run --name postgis_1 -p 5432:5432 -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=postgres -d mdillon/postgis```

- Alternatively, if having issues connecting to the postgres server in pgAdmin, run:

```$ docker run --name postgis_1 -p 5432 -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=postgres -d mdillon/postgis```

- This will allow the docker container to select a different port to forward to 5432.

To setup another docker container with a different database you can run:
```$ docker run --name postgis_2 -p 7000:5432 -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=postgres -d mdillon/postgis``` where ```7000``` can be any port number not already in use. 


3. Connect to our postgresql DB. In the command line run the following:

```
   $ docker exec -it <container id> psql -U postgres
   $ postgres=# CREATE DATABASE dgen_db;
```

Notes:
- Use the alpha-numeric container id rather than the container name.
- The container id can be gotten by running ```$ docker container ls```. If this doesn't display anything try running ```$ docker container ps```.
- If you get the error ``` psql: FATAL:  the database system is starting up ``` try rerunning the docker exec command again after a minute or so because docker can take some time to initialize everything.
- ```CREATE DATABASE``` will be printed when the database is created. ```\l``` will display the databases in your server.


### B. Download data (agents and database):
Download data by navigating to https://data.openei.org/submissions/1931 and clicking the 'model inputs' tab. Make sure to unzip any zipped files once downloaded. Note, the 13.5 GB dgen_db.sql.zip file contains all of the data for national level runs. We recommend starting with the database specific to the state or ISO region you're interested in. 

For example, if you want to simulate only California then navigate to the 'ca_final_db' folder and download the dgen_db.sql file. 

You will also need to download and unzip the agent files "OS_dGen_Agents.zip", making sure the use the correct agent file corresponding to the scenario you'd like to run (e.g. commercial agents for California).

#### Windows Users

We recommend using Powershell. If you don't have UNIX commands enabled for command prompt/powershell then you'll need to install Cygwin or QEMU to run a UNIX terminal.

In Powershell run the following (replace 'path_to_where_you_saved_database_file' below with the actual path where you saved your database file):

```
   $ docker cp /path_to_where_you_saved_data/dgen_db.sql <container id>:/dgen_db.sql
   $ docker exec -i <container id> psql -U postgres -d dgen_db -f dgen_db.sql
```


#### Mac Users

In a new terminal widnow run the following (make sure to replace 'path_to_where_you_saved_database_file' below with the actual path where you saved your database file): 

```$ cat /path_to_where_you_saved_data/dgen_db.sql | docker exec -i <container id> psql -U postgres -d dgen_db```

Notes:
- Backing up state/ISO databases will likely take 5-15 minutes. The national database will likely take 45-60 minutes.
- Don't close docker at any point while running dGen.
- The container can be "paused" by running ```$ docker stop <container id>``` and "started" by running ```$ docker start <container id>```
- The container must be started/running to restore and or access the database (including during model run time).

Troublshooting Container/Database Issues:
- Make sure the disk size for Docker has been properly allocated (make sure at least 16GB has been allocated for state level databases, at least 32 GB for ISO level databases, and at least 70 GB for the national database). You'll need to restart docker after changing the disk size in Docker's system preferences and will need to make a new container/start from scratch.
- If making a new container first run ```docker system prune -a``` and ```docker volume prune -f```.
- Make sure you've specificed the right path to the .sql file and make sure the .sql file is unzipped.
- Make sure the use the container's alpha-numeric ID rather than the container name. 
- If on a VPN try turning the VPN off when making the container and restoring the database.
- Try googling errors.

### C. Create Local Server:
Once the database is restored (it will take some time), open PgAdmin and create a new server. Name this whatever you want. Input "localhost" (or 127.0.0.1) in the host/address cell and "postgres" in both the username and password cells. Upon refreshing this and opening the database dropdown, you should be able to see your database. 

### D: Activate Environment 
Activate the dg3n environment and launch spyder by opening a new terminal window and run the following command:

```
   $ conda activate dg3n
   $ (dg3n) spyder
```

- In spyder, open the ```dgen_model.py``` file. This is what we will run once everything is configured.

Notes:
- Sometimes Spyder can have issues accessing files. It may be helpful to set the working directory by right clicking the white folder icon in the upper righthand corner and navigating to ```/path_to_where_you_cloned_dgen/dgen_os```.
- Spyder's kernel can sometimes have issues/stop unexpectedly. Refreshing the kernel might help if you're encountering issues running dgen_model.py.
- Spyder isn't necessary to use. If you'd rather run dGen by launching python from the dg3n environment then by all means do so.

### E: Configure Scenario
1. Open the blank input sheet located in ```dgen_os/excel/input_sheet_v_beta.xlsm ``` (don't forget to enable macros!). This file defines most of the settings for a scenario. Configure it depending on the desired model run and save a copy in the input_scenarios folder, i.e. ```dgen_os/input_scenarios/my_scenario.xlsm```. 

See the Input Sheet [Wiki page](https://github.com/NREL/dgen/wiki) for more details on customizing scenarios. 


2. In the python folder, open ```pg_params_connect.json``` and configure it to your local database. If you didn't change your username or password settings while setting up the docker container, this file should look like the below example:

```
   {	
	"dbname": "<insert_database_name>",
 	"host": "localhost",
	"port": "5432",
	"user": "postgres",
	"password": "postgres"
   }
```

- dbname will likely just be "dgen_db" unless you changed the name of this database in postgres
- Localhost could also be set as "127.0.0.1"
- Save this file
- Make sure the role is set as "postgres" in ```settings.py``` (it is set as "postgres" already by default)

The cloned repository will have already initialized the default values for the following important parameters:

* ``` start_year = 2014 ``` ( in /../dgen/python/config.py)                    --> start year the model will begin at
* ``` pg_procs = 2 ``` ( in /../dgen/python/config.py)                              --> number of parallel processes the model will run with
* ``` cores = 2 ``` ( in /../dgen/python/config.py)                                        --> number of cores the model will run with
* ``` role = "postgres" ``` ( in /../dgen/python/config.py)                                    --> set role of the restored database


### F: Run the Model

Open ```dgen_model.py``` in the Spyder IDE and hit the large green arrow "play button" near the upper left to run the model.

Or, launch python from within the dg3n environment and run:
```$ python dgen_model.py```

Notes:
- Only one agent file can be put in the input_agents directory.
- Results from the model run will be placed in a SQL table called "agent_outputs" within a newly created schema in the connected database. 
- The database and results will be preserved in the docker container if you stop the container and or close docker. Simply start the container to access the database again.
- The database will not persist once a docker container is terminated. Results will need to be saved locally by downloading the agent_outputs table from the schema run of interest or by dumping the entire database to a .sql file (see below).

## Saving Results:
1. To backup the whole database, including the results from the completed run, please run the following command in terminal after changing the save path and database name:

```$ docker exec <container_id> pg_dumpall -U postgres > /../path_to_save_directory/dgen_db.sql```

- this .sql file can be restored in the same way as was detailed above. 

2. To export just the "agent_outputs" table, simply right click on this table and select the "Import/Export" option and configure how you want the data to be saved. Note, if a save directory isn't specified this will likely save in the home directory.


## Notes:
- The "load_path" variable in config.py from the beta release has been removed for the final release. The load data is now integrated into each database. Load data and meta data for the agents is still accessible via the OEDI data submission.
