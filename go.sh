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
cd step-1-aws-setup/
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
if [ "$privateIp" == "" ]; then
    echo "Private IP not found"
    exit 1
fi
# build variables file
echo aviatrix_controller_ip = \"$publicIp\" > avtx.vars
echo aviatrix_controller_private_ip = \"$privateIp\" >> avtx.vars

# step 2
cd ../step-2-aviatrix-setup/
terraform init .
terraform apply -auto-approve -no-color -parallelism=1 -var-file=../avtx.vars . 2>&1 | tee apply.output.log
grep "Apply complete" apply.output.log > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo Done
else
    echo Step 2 apply failed.  see apply.output.log
    exit 1
fi

echo Public IP is $publicIp (controller accessible at https://$publicIp)
