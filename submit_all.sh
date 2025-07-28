#!/usr/bin/env bash
set -euo pipefail

LOCATION="us-east1"

# submit the first job
gcloud batch jobs submit dgen-small-states \
  --location="${LOCATION}" \
  --config="dgen-batch-job-small-states.yaml" \
  --machine-type="c2-standard-8"

# submit the second job
gcloud batch jobs submit dgen-mid-states \
  --location="${LOCATION}" \
  --config="dgen-batch-job-mid-states.yaml" \
  --machine-type="c2d-standard-16"  

# submit the third job
gcloud batch jobs submit dgen-large-states \
  --location="${LOCATION}" \
  --config="dgen-batch-job-large-states.yaml" \
  --machine-type="c2-standard-16"  

