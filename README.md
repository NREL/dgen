![dGen outputs in action](https://www.nrel.gov/analysis/dgen/assets/images/hero-hp-dgen.jpg)

## Get Your Tools
Install Docker (Mac): https://docs.docker.com/docker-for-mac/install/; (Windows): https://docs.docker.com/docker-for-windows/install/

- Important: In Docker, go into Docker > Preferences > Resources and up the allocation for disk size image for Docker. 64 GB is recommended. If a lot of this is being used up, then pruning past failed images/volumes will help free up some space. Refer to Docker’s website for more details on this.

Install Anaconda Python 3.7 Version: https://www.anaconda.com/distribution/

Install PgAdmin: https://www.pgadmin.org/download/ (ignore all of the options for docker, python, os host, etc.)

Install Git: If you don't already have git installed, then navigate here to install it for your operating system: https://www.atlassian.com/git/tutorials/install-git

## Download Code 
New users should fork a copy of dGen to their own private github account 


Next, clone the forked repository to your local machine by running the following in a terminal/powershell/command prompt:
```
   $ git clone https://github.com/<github_username>/dgen.git
```

- Create a new branch in this repository by running ```git checkout -b <branch_name_here>```
- It is generally a good practice to leave the master branch of a forked repository unchanged for easier updating in future. Hence, create new branch when developing features or performing configurations for unique runs.

# Running and Configuring dGen

### A. Create Environment
After cloning this repository and installing (and running) Docker as well as Anaconda, we'll create our environment and container:

1. Depending on directory you cloned this repo into, navigate in terminal to the python directory (/../dgen/python) and run the following command:

```
   $ conda env create -f dg3n.yml
```

- This will create the conda environment needed to run the dgen model.

2. This command will create a container with PostgreSQL initialized.
```
   $ docker run --name postgis_1 -p 5432:5432 -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=postgres -d mdillon/postgis
```
- Alternatively, if having issues connecting to the postgres server in pgAdmin, run:

```
   $ docker run --name postgis_1 -p 5432 -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=postgres -d mdillon/postgis
```
- This will allow the docker container to select a different port to forward to 5432.

3. Connect to our postgresql DB. In the command line run the following:

```
   $ docker container ls
   $ docker exec -it <container id> psql -U postgres
   $ CREATE DATABASE dgen_db;
```
- If you get the error ``` psql: FATAL:  the database system is starting up ``` try rerunning the docker exec command again after a minute or so because docker can take some time to initialize everything.

- ```CREATE DATABASE``` will be printed when the database is created. ```\l``` will display the databases in your server.

### B. Download data (agents and database):
Download data here (https://app.box.com/s/9zx58ojj0hhwr3b59xhanvmzimp06bgt) and make sure to unzip any zipped files once downloaded. Note, only download one data file at a time to avoid Box's "download size exceeded" error.

Next, run the following in the command line (replacing 'path_to_where_you_saved_database_file' below with the actual path where you saved your database file): 

```
   $ cat /path_to_where_you_saved_data/dgen_db.sql | docker exec -i <container id> psql -U postgres -d dgen_db
```

- Note, if on a Windows machine, use Powershell rather than command prompt. If linux commands still aren't working in Powershell, you can copy the data to the docker container and then load the data by running:

```
   $ docker cp /path_to_where_you_saved_data/dgen_db.sql <container id>:/dgen_db.sql
   $ docker exec -i <container id> psql -U postgres -d dgen_db -f dgen_db.sql
```

- Backing up the database will likely take 45-60 minutes. 
- Don't close docker at any point while running dGen.
- The container can be "paused" by running ```$ docker stop <container id>``` and "started" by running ```$ docker start <container id>```

### C. Create Local Server:
Once the database is restored (it will take 45-60 minutes), open PgAdmin and create a new server. Name this whatever you want. Write "localhost" (or 127.0.0.1) in the host/address cell and "postgres" in both the username and password cells. Upon refreshing this and opening the database dropdown, you should be able to see your database. 

### D: Activate Environment 
Activate the dg3n environment and launch spyder by opening a new terminal window and run the following command:

```
   $ conda activate dg3n
   $ (dg3n) spyder
```

- In spyder, open the dgen_model.py file. This is what we will run once everything is configured.

### E: Configure Scenario
1. Open the blank input sheet located in ```dgen_os/excel/input_sheet_v_beta.xlsm ``` (don't forget to enable macros!). This file defines most of the settings for a scenario. Configure it depending on the desired model run and save a copy in the input_scenarios folder, i.e. ```dgen_os/input_scenarios/my_scenario.xlsm```. 

See the Input Sheet Wiki page for more details on customizing scenarios. 


2. In the python folder, open ```pg_params_atlas.json``` and configure it to your local database. If you didn't change your username or password settings while setting up the docker container, this file should look like the below example:

```
   {	
	"dbname": "<insert_database_name>",
 	"host": "localhost",
	"port": "5432",
	"user": "postgres",
	"password": "postgres"
   }
```

- Localhost could also be set as "127.0.0.1"
- Save this file
- Make sure the role is set as "postgres" in settings.py, line 515; also change the role to "postgres" in data_functions.py (this should already be set as such)

3. Set the 'load_path' variable correctly in config.py to the exact location of the load file that corresponds to the analysis you're running.
* ``` load_path ```  = file path to where you saved your data    ( in /../dgen/python/config.py)

The cloned repository will have already initialized the default values for the following important parameters:

* ``` start_year = 2014 ``` ( in /../dgen/python/config.py)                    --> start year the model will begin at
* ``` pg_procs = 2 ``` ( in /../dgen/python/config.py)                              --> number of parallel processes the model will run with
* ``` cores = 2 ``` ( in /../dgen/python/config.py)                                        --> number of cores the model will run with

* ``` role = "postgres" ``` ( in /../dgen/python/data_functions.py)    --> same as the owner of the restored database
* ``` role = "postgres" ``` ( in /../dgen/python/settings.py)                --> same as the owner of the restored database


### F: Run the Model
Run the model in the command line:
```
   $ python dgen_model.py
```
Or, open "dgen_model.py" in the Spyder IDE and hit the large green arrow "play button" near the upper left to run the model.

Results from the model run will be placed in a SQL table called "agent_outputs" within a newly created schema in the connected database. Because the database will not persist once a docker container is terminated, these results will need to be saved locally.

## Saving Results:
1. To backup the whole database, including the results from the completed run, please run the following command in terminal after changing the save path and database name:

```
   $ docker exec <container_id> pg_dumpall -U postgres > '/../path_to_save_directory/dgen_db.sql'
```

- this .sql file can be restored in the same way as was detailed above. 

2. To export just the "agent_outputs" table, simply right click on this table and select the "Import/Export" option and configure how you want the data to be saved. Note, if a save directory isn't specified this will likely save in the home directory.
