#!/usr/bin/env bash
set -eo pipefail

if [[ $1 != "staging" && $1 != "production" ]]; then
  'No env specified. Either use staging or production' > stderr
  exit 1
fi

ENV=$1
CREATOR="f13233"
CDKTF_DIFF_FILE=cdktf.out

echo "Running deploy for stage '${ENV}'"
cdktf deploy "$ENV" \
  --output  $CDKTF_DIFF_FILE \
  --var-file "./variables/${ENV}.tfvars" \
  --var "creator=${CREATOR}"
echo "Deploy completed"