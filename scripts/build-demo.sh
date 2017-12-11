#!/bin/bash
#-----------------------------------------------------------------------------
# Build Aviatrix demo environment in multiple steps.
#
# Step 1:
#   - set up the services hub in AWS
#   - install controller in the services HUB
# Step 2:
#   - upgrade the controller
#      2.25:
#   - set the administrator email
#   - set the admin password
#      2.5:
#   - set the customer ID
#   - create the aws cloud account
# Step 3:
#   - create services hub gateway
#   - install the transit hub in AWS
#   - install aviatrix gateways in transit hub
# Step 4:
#   - create "on prem" vpc and peer transit to it
# Step 5:
#   - install 5 spokes in AWS with gateways
#   - peer spokes with service and transit
# Step 6:
#   - install 2 additional spokes ("at engineering request")
#   - peer with transit and services
#-----------------------------------------------------------------------------

export TF_LOG= #TRACE
TOP="$( cd "$(dirname "$0")/.." ; pwd -P )"

# check that the dependencies are installed
which terraform > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo Please install terraform and dependencies before continuing
    exit 1
fi

# grab the password
PASSWORD=$(grep "aviatrix_password = " ${TOP}/shared/init.tf | awk '{ print $3 }' | sed -e 's/"//g')


#-----------------------------------------------------------------------------
# function waitForControllerUp
# waits until the controller IP is accessible via a curl request (i.e., a
# successsful login request)
# Arguments:
#   $1 - publicIp - the public ip address of the controller
#   $2 - password - the password for the user "admin" to the controller
# Returns:
#   0 when successful; 1 if controller is not accessible after 10 tries
#-----------------------------------------------------------------------------
function waitForControllerUp() {
    publicIp="$1"
    password="$2"
    tries=1
    success=0
    while [ $tries -lt 10 -a $success -eq 0 ]; do
        echo "[Aviatrix Controller] Attempt $tries ..."
        output=$(curl -k "https://$publicIp/v1/api?action=login&username=admin&password=$password" 2>/dev/null)
        if [ $? -eq 0 ]; then
            echo "    output: $output"
            echo "$output" | grep "authorized successfully" > /dev/null 2>&1
            if [ $? -eq 0 ]; then
                success=1
            fi
        else
            echo "    output: $output"
            sleep 10
        fi
        tries=$((tries + 1))
    done
    if [ $success -eq 0 ]; then
        echo "Unable to connect to controller on https://$publicIp using admin:$password"
        return 2
    fi
    return 0
}

#-----------------------------------------------------------------------------
# Applies a single step.
# Arguments:
#  $1 - step - step name
#-----------------------------------------------------------------------------
function applyStep() {
    local step="$1"

    echo "******************* ${step} *******************"
    cd ${TOP}/steps/${step}/
    mkdir -p ${TOP}/logs
    LOG=${TOP}/logs/${step}.apply.output.log
    if [ "${VARS}" != "" ]; then
        ARGS="-var-file=${VARS}"
    else
        ARGS=
    fi

    terraform apply -auto-approve -no-color -parallelism=1 -var "top_dir=${TOP}" ${ARGS} . 2>&1 | tee ${LOG}
    grep "Apply complete" ${LOG} > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        if [ "${VARS}" != "" ]; then
            grep "subaction=change_password" ${TOP}/steps/${step}/*.tf > /dev/null 2>&1
            if [ $? -eq 0 ]; then # password changed in this step
                echo "aviatrix_current_password = \"$PASSWORD\"" > ${VARS}
            fi
        fi
        echo Done
        return 0
    else
        echo Step ${step} apply failed.  See ${LOG}.
        return 1
    fi
}

# init/validate all steps
cd ${TOP}
for step in $(ls -d steps/step-*); do
    cd ${TOP}/${step} && terraform init . -no-color && terraform validate . -no-color
    if [ $? -ne 0 ]; then exit 1; fi
done

# grab latest cloudformation script
mkdir -p ${TOP}/data
curl -o ${TOP}/data/aviatrix-aws-quickstart.json https://raw.githubusercontent.com/AviatrixSystems/AWSQuickStart/master/aviatrix-aws-quickstart.json 2>/dev/null

# step 1
applyStep step-1-controller-service-hub
if [ $? -eq 0 ]; then
    privateIp=$(grep "private-ip" ${LOG} | awk '{ print $3 }')
    publicIp=$(grep "public-ip" ${LOG} | awk '{ print $3 }')
else
    exit 1
fi
if [ "$publicIp" == "" ]; then
    echo "Controller public IP not found"
    exit 1
fi

# wait for the controller to be accessible
waitForControllerUp "$publicIp" "$privateIp"
rtn=$?
if [ $rtn -eq 2 ]; then
    waitForControllerUp "$publicIp" "$PASSWORD"
    rtn=$?
    current_password="$PASSWORD"
else
    current_password="$privateIp"
fi
if [ $rtn -ne 0 ]; then exit 2; fi

# create a temporary .tfvars file to store the current admin password
# (update this after step 2.25 when it is set)
VARS=${TOP}/shared/aviatrix-admin-password.tfvars
echo "aviatrix_current_password = \"$current_password\"" > ${VARS}

# step 2 - 5
STEPS="step-2-aviatrix-init step-2.25-aviatrix-init step-2.5-aviatrix-init step-3-transit-hub step-4-on-premise step-5-spokes"
for STEP in ${STEPS}; do
    applyStep ${STEP}
    if [ $? -ne 0 ]; then
        exit 1
    fi
done

current_password=$(grep "aviatrix_current_password = " ${VARS} | awk '{ print $3 }' | sed -e 's/"//g')
echo "Complete. Public IP is $publicIp.  Controller accessible at https://$publicIp.  Login as admin with password '${current_password}'."
