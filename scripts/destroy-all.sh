#!/bin/sh
#-----------------------------------------------------------------------------
# Cleans up all parts of the Aviatrix demo environment in multiple steps.
#-----------------------------------------------------------------------------
TOP="$( cd "$(dirname "$0")/.." ; pwd -P )"
STEPS="step-6-engineering step-5-spokes step-4-on-premise step-3-transit-hub step-2.5-aviatrix-init step-2.25-aviatrix-init step-2-aviatrix-init step-1-controller-service-hub"
for STEP in ${STEPS}; do
    echo "******************* ${STEP} *******************"
    pushd steps/${STEP}
    terraform destroy -no-color -parallelism=1 -force -var-file=${TOP}/shared/aviatrix-admin-password.tfvars .
    if [ $? -ne 0 ]; then
        echo Failed to destroy ${STEP}
        popd
        exit 1
    fi
    popd
done
