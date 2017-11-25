#!/bin/sh

STEPS="step-6-engineering step-5-spokes step-4-on-premise step-3-transit-hub step-2.5-aviatrix-init step-2.25-aviatrix-init step-2-aviatrix-init step-1-controller-service-hub"
for STEP in ${STEPS}; do
    echo Destroying ${STEP}
    pushd ${STEP}
    terraform destroy -no-color -parallelism=1 .
    if [ $? -ne 0 ]; then
        popd
        exit 1
    fi
    popd
done
