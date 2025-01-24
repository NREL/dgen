# Packer AMI Build Instructions

This guide provides instructions on how to use Packer to build an AMI with the provided configuration.

## Prerequisites

- [Packer](https://www.packer.io/downloads) installed
- AWS account with appropriate permissions to create AMIs
- AWS credentials configured (e.g., using `aws configure`)

1. **Clone the repository and Packer init**

   ```bash
   git clone https://github.com/your-repo/dgen.git
   cd dgen/packer
   packer init .
   ```

2. **Customize Variables and Build the AMI**

   Use Packer to build the AMI. This will create an instance, provision it, and create an AMI from it.

   Override variables in example-vars.pkrvars.hcl that are specific for your environment.

   ```bash
   cp example-vars.pkrvars.hcl ~/dgdo-vars.pkrvars.hcl
   packer validate -var-file=~/dgdo-vars.pkrvars.hcl dgdo-ami.pkr.hcl
   packer build -var-file=~/dgdo-vars.pkrvars.hcl dgdo-ami.pkr.hcl
   ```

## Tests

You can run automated tests on the Packer config using the below test script.  It should be ran from the packer directory.

```bash
cd packer
./tests/test_packer.sh
```

## Usage

```bash
ssh -i <your_ssh_key> ubuntu@<your_server_ip>
(dg3n) root@0b702babc2ce:/opt/dgen_os/python# python dgen_model.py
```

## Troubleshooting

If you encounter any issues, refer to the Packer [documentation](https://www.packer.io/docs) or check the error messages for guidance.
