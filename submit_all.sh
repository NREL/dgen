#!/usr/bin/env bash
set -euo pipefail

LOCATION="us-east1"
JOB_TS=$(date -u +"%Y%m%d-%H%M%S")

# Define job name with timestamp
JOB_NAME="dgen-small-states-${JOB_TS}"

# submit the first job
gcloud batch jobs submit "${JOB_NAME}" \
  --location="${LOCATION}" \
  --config="dgen-batch-job-small-states.yaml" \
  --machine-type="c2-standard-8" \
  --provisioning-model="SPOT"

# Define job name with timestamp
JOB_NAME="dgen-mid-states-${JOB_TS}"

# submit the second job
gcloud batch jobs submit "${JOB_NAME}" \
  --location="${LOCATION}" \
  --config="dgen-batch-job-mid-states.yaml" \
  --machine-type="c2d-standard-16"  \
  --provisioning-model="SPOT"

# Define job name with timestamp
JOB_NAME="dgen-large-states-${JOB_TS}"

# submit the third job
gcloud batch jobs submit "${JOB_NAME}" \
  --location="${LOCATION}" \
  --config="dgen-batch-job-large-states.yaml" \
  --machine-type="c2-standard-16"  \
  --provisioning-model="SPOT"

