#!/bin/bash
#-----------------------------------------------------------------------------
# Cleans up all parts of the Aviatrix demo environment
#-----------------------------------------------------------------------------
TOP="$( cd "$(dirname $(readlink -f $0))/.." ; pwd -P )"
source ${TOP}/scripts/common.sh
cd ${TOP}

# only one instance of this script should run at a time
LOCKFILE=${TOP}/.destroy-all.lock
lockfile -r 0 ${LOCKFILE} || exit 5

STEPS="step-6-engineering step-5-spokes step-4-on-premise step-3-transit-hub step-2.5-aviatrix-init step-2.25-aviatrix-init step-2-aviatrix-init step-1-controller-service-hub"
VARS=${TOP}/shared/aviatrix-admin-password.tfvars
for STEP in ${STEPS}; do
    echo "******************* ${STEP} *******************"
    pushd ${TOP}/steps/${STEP}
    terraform init -no-color . && \
        terraform destroy -no-color -parallelism=1 -force -var-file=${VARS} .
    if [ $? -ne 0 ]; then
        echo Failed to destroy ${STEP}
        popd
        rm -f ${LOCKFILE}
        exit 1
    fi
    popd
done
rm -f ${LOCKFILE} ${DEMORUNNINGFILE}
send_demo_destroyed_email

exit 0
