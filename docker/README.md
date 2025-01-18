# Download dataset
https://data.openei.org/submissions/1931
https://data.openei.org/s3_viewer?bucket=oedi-data-lake&prefix=dgen%2F

It defaults to using the Deleware Residential: https://oedi-data-lake.s3.amazonaws.com/dgen/de_final_db/dgen_db.sql

Warning:  This will remove old running containers and data, this may be required to free up space and getting started.

```bash
docker system prune -a
docker volume prune -f
```

Use docker-compose to run dgen.

~/dgen_data/ is the path to your home directory.  This path is shared with your running containers.

```bash
mkdir ~/dgen_data/ && chmod 755 ~/dgen_data/
```

``` bash
docker-compose up --build -d
```

``` bash
docker attach dgen_1
(dg3n) root@62bf0bdd2aff:/opt/dgen_os/python# python dgen_model.py
```