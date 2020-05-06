![dGen outputs in action](https://www.nrel.gov/analysis/dgen/assets/images/hero-hp-dgen.jpg)


Install Docker (mac): https://docs.docker.com/docker-for-mac/install/

Install Docker (Windows): https://docs.docker.com/docker-for-windows/install/

Install Anaconda Python 3.7 Version: https://www.anaconda.com/distribution/

Install PgAdmin: https://www.pgadmin.org/download/ (ignore all of the options for docker, python, os host, etc.)


If you don't already have git installed, then navigate here to install it for your operating system: https://www.atlassian.com/git/tutorials/install-git

To begin, fork this repository to your own github account and clone the forked repository to your local machine.

Clone this repository by running the following command in your terminal/powershell/command prompt:

```
   $ git clone https://github.com/<github_username>/dgen.git
```

A. After cloning this repository and installing (and running) Docker as well as Anaconda, we'll create our environment and container:

1. Depending on directory you cloned this repo into, navigate in terminal to the python directory (/../dgen/python) and run the following command:

```
   $ conda env create -f dg3n.yml
```

- This will create the conda environment needed to run the dgen model.

2. This command will create a container with PostgreSQL initialized.
```
   $ docker run --name postgis_1 -p 5432:5432 -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=postgres -d mdillon/postgis
```

3. Connect to our postgresql DB. In the command line run the following:

```
   $ docker container ls
   $ docker exec -it <container id> psql -U postgres
   $ CREATE DATABASE dgen_db;
```
- Note, you may get an error like: “psql: FATAL:  the database system is starting up". Simply run the docker command again after a couple of minutes as docker can take some time to initialize everything.

- If you get the error ``` psql: FATAL:  the database system is starting up ``` try rerunning the docker exec command again after a minute or so.
- ```CREATE DATABASE``` will be printed when the database is created. ```\l``` will display the databases in your server.

B. Download data here (https://data.nrel.gov/submissions/129) and make sure to unzip any zipped files. Next, run the following in the command line (replacing 'path_to_where_you_saved_database_file' below with the actual path where you saved your database file): 

```
   $ cat /path_to_where_you_saved_data/dgen_alpha_os_db_postgres.sql | docker exec -i <container id> psql -U postgres -d dgen_db
```

- Don't close the docker container or postgresql server at any point while running dGen.

C. Once the database is restored (it could take a couple minutes), open PgAdmin and create a new server. Name this whatever you want. Write "localhost" (or 127.0.0.1) in the host/address cell and "postgres" in both the username and password cells. Upon refreshing this and opening the database dropdown, you should be able to see your database. It is time to configure and run the model:

1. Activate the dg3n environment and launch spyder by opening a new terminal window and run the following command:

```
   $ conda activate dg3n
   $ (dg3n) spyder
```

- In spyder, open the dgen_model.py file. This is what we will run once everything is configured.

2. Now open the input sheet located in dgen/python/excel (don't forget to enable macros!) and configure it depending on the model run you want to do. See the Input Sheet Wiki page for more details on this. Finally, save this in the "input_scenarios" directory (dgen/python/input_scenarios) in the dgen directory on your local machine.


3. In the python folder, open the "pg_params_atlas.json" file and configure it to your local database. If you didn't change your username or password settings while setting up the docker container, this file should look like the below example:

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
- make sure the role is set as "postgres" in settings.py, line 515; also change the role to "postgres" in data_functions.py, lines 382 and 434

4. The cloned repository will have initialized the default values for the following important parameters:

* ``` agents_per_region = 10 ``` ( in /../dgen/python/config.py)        --> number agents model will run for a given region
* ``` start_year = 2014 ``` ( in /../dgen/python/config.py)            --> start year the model will begin at
* ``` pg_procs = 2 ``` ( in /../dgen/python/config.py)                 --> number of parallel processes the model will run with
* ``` cores = 2 ``` ( in /../dgen/python/config.py)                    --> number of cores the model will run with

* ``` role = "postgres" ``` ( in /../dgen/python/data_functions.py)    --> same as the owner of the restored database
* ``` role = "postgres" ``` ( in /../dgen/python/settings.py)          --> same as the owner of the restored database

D. Open "dgen_model.py" in the Spyder IDE and hit the large green arrow "play button" near the upper left to run the model.

E. Results from the model run will be placed in a table called "agent_outputs" within a newly created schema in the connected database. Because the database will not persist once a docker container is termianted, these results will need to be saved locally. 

1. To backup the whole database, including the results from the completed run, please run the following command in terminal after changing the save path and database name:

```
   $ pg_dump dgen_db -f '/../path_to_save_directory/dgen_db.sql'
```

- this .sql file can be restored in the same way as was detailed above. 

2. To export just the "agent_outputs" table, simply right click on this table and select the "Import/Export" option and configure to how you want the data to be saved. Note, if a save directory isn't specified this will likely save in your home directory.
