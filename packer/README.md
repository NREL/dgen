# Packer AMI Build Instructions

This guide provides instructions on how to use Packer to build an AMI with the provided configuration.

## Prerequisites

- [Packer](https://www.packer.io/downloads) installed
- AWS account with appropriate permissions to create AMIs
- AWS credentials configured (e.g., using `aws configure`)

1. **Clone the repository and Packer init**

   ```sh
   git clone https://github.com/your-repo/dgen.git
   cd dgen/packer
   packer init .
   ```

2. **Validate the Packer template**

   ```sh
   packer validate dgdo-ami.pkr.hcl
   ```

3. **Build the AMI**

   Use Packer to build the AMI. This will create an instance, provision it, and create an AMI from it.

   ```sh
   packer build -var-file=example-vars.pkrvars.hcl dgdo-ami.pkr.hcl
   ```

## Configuration

The Packer template is configured to use the latest Ubuntu AMI and install Apache2. You can modify the template as needed.

- **Region**: The AWS region where the AMI will be created. Default is `us-west-2`.
- **Instance Type**: The instance type used for building the AMI. Default is `t3.micro`.

## Troubleshooting

If you encounter any issues, refer to the Packer [documentation](https://www.packer.io/docs) or check the error messages for guidance.
