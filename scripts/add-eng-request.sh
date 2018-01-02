#!/bin/bash
#-----------------------------------------------------------------------------
# Adds the "engineering request"
#-----------------------------------------------------------------------------
TOP="$( cd "$(dirname $(readlink -f $0))/.." ; pwd -P )"

STEP=step-6-engineering
LOG=${TOP}/logs/${STEP}.apply.output.log
VARS=${TOP}/shared/aviatrix-admin-password.tfvars
cd ${TOP}/steps/${STEP}
terraform apply -auto-approve -no-color -parallelism=1 -var-file=${VARS} . 2>&1 | tee ${LOG}
