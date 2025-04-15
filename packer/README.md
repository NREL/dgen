# Using the dGen AWS AMI

This guide provides instructions on how to use the dGen AWS AMI as well as how to use Packer to build your own AWS AMI.

## dGen AMI Usage

#### System Requirements

- **Min CPUs**: 8 cores
- **Min Memory**: 16 GB
- **Min Disk Storage**: 80 GB

We recommend using an instance type of **c6i.4xlarge, c6i.8xlarge, c6i.12xlarge, or higher** for optimal performance. Using an instance type with too little memory will result in an error during the `conda env create -f` step, if you run into an error during the `conda env` step then try a larger instance type.

#### Getting Started

Launch an EC2 instance in AWS using the AMI built by Packer.  Once the EC2 instance has started, you can then ssh to the instance.

```bash
$ ssh -i <your_ssh_key> ubuntu@<your_server_ip>
ubuntu@ip-1-2-3-4:~/dgen/docker$ source ~ubuntu/dgen_start.sh
(dg3n) dgen@0b702cabc2ce:/opt/dgen_os/python$ python dgen_model.py
```

 The first time running `~ubuntu/dgen_start.sh`, dgen will build the Docker images and download the default dataset.  `This may take 10-15 minutes depending on your network connection.`

#### Using a new dataset

Edit the docker-compose file `/home/ubuntu/dgen/docker/docker-compose.yml`.  See `using a new dataset` in the [dgen Docker Usage Guide](../docker/README.md).

One challenge you must consider when using an EC2 instance is if the `/data/input_sheet_final.xlsm` needs to be edited, you must copy this file to a system with Excel that can edit the document, then you need to copy it back to the instance.

Below is an example of how you must copy the input_sheet_final to make edits using a Mac.

```bash
# Copy the current input sheet to your local system
$ scp -i ~/.ssh/your_ssh_key ubuntu@192.168.1.1:~/dgen_data/input_sheet_final.xlsm /tmp/input_sheet_final.xlsm

# Edit the file using Excel
$ open /tmp/input_sheet_final.xlsm

# Copy the input sheet back to the EC2 instance
$ scp -i ~/.ssh/your_ssh_key /tmp/input_sheet_final.xlsm ubuntu@192.168.1.1:~/dgen_data/input_sheet_final.xlsm
```

#### Warning: This will remove old running containers and data volumes.  This may be required if you need space.

You can completely remove all the data for a fresh start with the below script and commands. `This will result in loss in your dgen data and provide a fresh start`

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

## Troubleshooting

If you encounter any issues, refer to the [Packer documentation](https://www.packer.io/docs) or check the error messages for guidance.

## Tests

You can run automated tests on the Packer config using the below test script.  It should be ran from the packer directory.

```bash
$ cd packer
$ ./tests/test_packer.sh
```
