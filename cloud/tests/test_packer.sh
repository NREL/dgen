#!/bin/bash

# Get the directory of the current script
SCRIPT_DIR=$(dirname "$0")

# Run packer validate using the relative path to the Packer template
packer validate  -var-file=${SCRIPT_DIR}/../example-vars.pkrvars.hcl "${SCRIPT_DIR}/../dgdo-ami.pkr.hcl"

# Check the exit code of packer validate
if [ $? -ne 0 ]; then
  echo "Packer template validation failed."
  exit $?
else
  echo "Packer template validation succeeded."
  exit 0
fi