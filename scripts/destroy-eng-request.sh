#!/bin/bash
#-----------------------------------------------------------------------------
# Removes the "engineering request"
#-----------------------------------------------------------------------------
TOP="$( cd "$(dirname "$0")/.." ; pwd -P )"

STEP=step-6-engineering
LOG=${TOP}/logs/${STEP}.destroy.output.log
VARS=${TOP}/shared/aviatrix-admin-password.tfvars
cd ${TOP}/steps/${STEP}
terraform destroy -force -no-color -parallelism=1 -var-file=${VARS} . 2>&1 | tee ${LOG}
