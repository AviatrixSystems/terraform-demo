#!/bin/sh
#-----------------------------------------------------------------------------
# Removes the "engineering request"
#-----------------------------------------------------------------------------
TOP="$( cd "$(dirname "$0")/.." ; pwd -P )"

export TF_LOG= #TRACE
STEP=step-6-engineering
LOG=${TOP}/logs/${STEP}.destroy.output.log
VARS=${TOP}/shared/aviatrix-admin-password.tfvars
cd ${TOP}/steps/${STEP}
terraform destroy -force -no-color -parallelism=1 -var-file=${VARS} . 2>&1 | tee ${LOG}
grep "Destroy complete" ${LOG} > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Failed to destroy engineering VPCs"
    exit 1
fi
