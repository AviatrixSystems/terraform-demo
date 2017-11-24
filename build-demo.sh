#!/bin/sh
#-----------------------------------------------------------------------------
# Build Aviatrix demo environment in 2 steps. Aviatrix provider depends on the
# controller.  Terraform does not allow providers to have dependencies so we
# split this in two and pull out the IP addresses for use in step 2.
#
# Step 1:
#   - set up the services hub in AWS
#   - install controller in the services HUB
# Step 2:
#   - install the transit hub in AWS
#   - install 5 spokes in AWS
#   - install aviatrix gateways in service, transit, spoke vpcs
#   - peer spokes with service and transit
#   - create "on prem" vpc and peer transit to it
#-----------------------------------------------------------------------------

export TF_LOG= #TRACE

SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"

# check aws account is configured
secret_key=$(grep secret_key init.tf | awk '{ print $3 }')
if [ $secret_key == "ENTER VALUE" ]; then
    echo 'Set the variables in init.tf before running'
    exit 1
fi

# check that the dependencies are installed
which terraform > /dev/null 2>&1
if [ $? -ne 0 ]; then
    # install terraform
    # install terraform aws and aviatrix providers
      # install deps for aviatrix provider
    echo Please install terraform and dependencies before continuing
    exit 1
fi

# grab latest cloudformation script
mkdir -p data
pushd data
curl -O https://raw.githubusercontent.com/AviatrixSystems/AWSQuickStart/master/aviatrix-aws-quickstart.json
popd

# step 1
cd step-1-controller-service-hub/
terraform init .
terraform apply -auto-approve -no-color -parallelism=1 . | tee apply.output.log
grep "Apply complete" apply.output.log > /dev/null 2>&1
if [ $? -eq 0 ]; then
    # found lines
    appRoleARN=$(grep "iam-role-app-arn" apply.output.log | awk '{ print $3 }')
    ec2RoleARN=$(grep "iam-role-ec2-arn" apply.output.log | awk '{ print $3 }')
    privateIp=$(grep "private-ip" apply.output.log | awk '{ print $3 }')
    publicIp=$(grep "public-ip" apply.output.log | awk '{ print $3 }')
else
    echo Step 1 apply failed.  see apply.output.log
    exit 1
fi

if [ "$publicIp" == "" ]; then
    echo "Public IP not found"
    exit 1
fi

# wait for controller to be up
tries=1
success=0
while [ $tries -lt 10 -a $success -eq 0 ]; do
    echo attempt $tries ...
    output=$(curl -k "https://$publicIp/v1/api?action=login&username=admin&password=$privateIp" 2>/dev/null)
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
    echo "Failed to connect to controller"
    exit 1
fi

# step 2 - 5
STEPS="step-2-aviatrix-init step-2.25-aviatrix-init step-2.5-aviatrix-init step-3-transit-hub step-4-on-premise step-5-spokes"
for STEP in ${STEPS}; do
    cd ../${STEP}/
    terraform init .
    TF_LOG=TRACE terraform apply -auto-approve -no-color -parallelism=1 . 2>&1 | tee apply.output.log
    grep "Apply complete" apply.output.log > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo Done
    else
        echo Step ${STEP} apply failed.  see apply.output.log
        exit 1
    fi
done

echo Complete. Public IP is $publicIp (controller accessible at https://$publicIp)
