# Packer AMI Usage Guide

This guide provides instructions on how to use the dGen AWS AMI as well as how to use Packer to build your own AWS AMI.

## Usage

Launch an EC2 instance in AWS using the AMI built by Packer.  You can then ssh to the instance, by default you will be dropped into a dgen shell.

```bash
$ ssh -i <your_ssh_key> ubuntu@<your_server_ip>
ubuntu@ip-1-2-3-4:~/dgen/docker$ source ~ubuntu/dgen_start.sh
(dg3n) dgen@0b702cabc2ce:/opt/dgen_os/python$ python dgen_model.py
```

 The first time running `~ubuntu/dgen_start.sh`, dgen will build the Docker images and download the default dataset.  `This may take 10-15 minutes depending on your network connection.`

You can completely remove all the data for a fresh start with the below script and commands.

```bash
$ ~/dgen_prune_all_data.sh
```

## Building an AWS AMI with Packer

#### Prerequisites

- [Packer](https://www.packer.io/downloads) installed
- AWS account with appropriate permissions to create AMIs
- AWS credentials configured (e.g., using `aws configure`)

#### Packer Init

```bash
$ cd dgen/packer
$ packer init .
```

#### Customize variables and build the AWS AMI

Use Packer to build the AMI. This will create an instance, provision it, and create an AMI from it.

Override variables in example-vars.pkrvars.hcl that are specific for your environment.

```bash
$ cp example-vars.pkrvars.hcl /tmp/dgdo-vars.pkrvars.hcl
$ packer validate -var-file=/tmp/dgdo-vars.pkrvars.hcl dgdo-ami.pkr.hcl
$ packer build -var-file=/tmp/dgdo-vars.pkrvars.hcl dgdo-ami.pkr.hcl
```

#### Using a new dataset

Edit the docker-compose file `/home/ubuntu/dgen/docker/docker-compose.yml`.  See `using a new dataset` in the [dgen Docker Usage Guide](../dgen/README.md).

One challenge you must consider when using an EC2 instance is if the `/data/input_sheet_final.xlsm` needs to be edited, you must copy this file to a system with Excel that can edit the document, then you need to copy it back to the instance.

#### Disable auto start of dgen at login

To diable auto start of dgen at login, comment out the `dgen_start.sh` script in `~ubuntu/.bashrc`.

```bash
$ nano ~ubuntu/.bashrc
# source ~ubuntu/dgen_start.sh
```

## Troubleshooting

If you encounter any issues, refer to the [Packer documentation](https://www.packer.io/docs) or check the error messages for guidance.

## Tests

You can run automated tests on the Packer config using the below test script.  It should be ran from the packer directory.

```bash
$ cd packer
$ ./tests/test_packer.sh
```