#!/usr/bin/env bash
set -euo pipefail

gcloud batch jobs submit dgen-all \
  --location="us-east1" \
  --config="dgen-batch-job-large-states.yaml" \
  --machine-type="c2d-highcpu-16" \
  --provisioning-model="SPOT"