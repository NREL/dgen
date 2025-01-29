# Packer AMI Usage Guide

This guide provides instructions on how to use Packer to build a dgen AWS AMI with the provided configuration.

## Prerequisites

- [Packer](https://www.packer.io/downloads) installed
- AWS account with appropriate permissions to create AMIs
- AWS credentials configured (e.g., using `aws configure`)

## Building an AWS AMI with Packer

##### Packer Init

```bash
$ cd dgen/packer
$ packer init .
```

##### Customize variables and build the AWS AMI

Use Packer to build the AMI. This will create an instance, provision it, and create an AMI from it.

Override variables in example-vars.pkrvars.hcl that are specific for your environment.

```bash
$ cp example-vars.pkrvars.hcl ~/dgdo-vars.pkrvars.hcl
$ packer validate -var-file=~/dgdo-vars.pkrvars.hcl dgdo-ami.pkr.hcl
$ packer build -var-file=~/dgdo-vars.pkrvars.hcl dgdo-ami.pkr.hcl
```

## Usage

Launch an EC2 instance in AWS using the AMI built by Packer.  You can then ssh to the instance, by default you will be dropped into a dgen shell.

```bash
$ ssh -i <your_ssh_key> ubuntu@<your_server_ip>
$ (dg3n) root@0b702babc2ce:/opt/dgen_os/python# python dgen_model.py
```

##### Using a new dataset

Edit the docker-compose file `/home/ubuntu/dgen/docker-compose.yml`.  See `using a new dataset` in the [dgen Docker Usage Guide](../dgen/README.md).

One challenge you must consider when using an EC2 instnace is if the `/data/input_sheet_final.xlsm` needs to be edited, you must copy this file to a system with Excel that can edit the document, then you need to copy it back to the instance.

## Troubleshooting

If you encounter any issues, refer to the [Packer documentation](https://www.packer.io/docs) or check the error messages for guidance.

## Tests

You can run automated tests on the Packer config using the below test script.  It should be ran from the packer directory.

```bash
$ cd packer
$ ./tests/test_packer.sh
```