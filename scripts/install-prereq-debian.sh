#!/bin/bash
#-----------------------------------------------------------------------------
# Installation script for Aviatrix terraform based demo
# This script installs the Ubuntu/Debian packages required for this demo
# including terraform and golang.
# Arguments:
#   $1 - username - the username this is being installed on behalf of
#-----------------------------------------------------------------------------

TOP="$( cd "$(dirname "$0")/.." ; pwd -P )"

AVTX_USERNAME="$1"
if [ "${AVTX_USERNAME}" == "" ]; then
    echo "Usage: $0 [username]"
    exit 1
fi

sudo apt-get update
sudo apt --yes install python-pip
sudo pip install awscli
# for lockfile
sudo DEBIAN_FRONTEND=noninteractive apt-get -y install procmail

# terraform
which terraform > /dev/null 2>&1
if [ $? -ne 0 ]; then
    sudo apt install -y unzip wget
    if [ $? -ne 0 ]; then exit 1; fi
    wget https://releases.hashicorp.com/terraform/0.11.1/terraform_0.11.1_linux_amd64.zip
    if [ $? -ne 0 ]; then exit 1; fi
    unzip terraform_0.11.1_linux_amd64.zip
    if [ $? -ne 0 ]; then exit 1; fi
    sudo mv terraform /usr/local/bin/
    if [ $? -ne 0 ]; then exit 1; fi
    sudo ln -s /usr/local/bin/terraform /usr/bin/terraform
fi

# install go
which go > /dev/null 2>&1
if [ $? -ne 0 ]; then
    wget https://redirector.gvt1.com/edgedl/go/go1.9.2.linux-amd64.tar.gz
    tar -xvf go1.9.2.linux-amd64.tar.gz
    sudo mkdir -p /usr/local/go
    sudo mv ./go /usr/local/go/go-1.9.2
    sudo rm -f /usr/local/go/current
    sudo ln -sf /usr/local/go/go-1.9.2 /usr/local/go/current
    sudo chown -R root:root /usr/local/go/go-1.9.2
    sudo ln -sf /usr/local/go/current/bin/godoc /usr/bin/godoc
    sudo ln -sf /usr/local/go/current/bin/gofmt /usr/bin/gofmt
    sudo ln -sf /usr/local/go/current/bin/go /usr/bin/go
fi

source ${TOP}/scripts/install-prereq-go.sh

# NOTE: use tee to allow sudo access to file
#echo GOROOT=$GOROOT | sudo tee /etc/profile.d/300-aviatrix-demo.sh
echo GOPATH=$GOPATH | sudo tee /etc/profile.d/300-aviatrix-demo.sh

# ssh client timeout
grep ClientAliveInterval /etc/ssh/sshd_config > /dev/null
if [ $? -ne 0 ]; then
    echo ClientAliveInterval 120 | sudo tee -a /etc/ssh/sshd_config
    echo ClientAliveCountMax 720 | sudo tee -a /etc/ssh/sshd_config
fi

# ssh user
if [ -f ${TOP}/initialize/ssh-public-keys/${AVTX_USERNAME}.pub ]; then
    cat ${TOP}/initialize/ssh-public-keys/${AVTX_USERNAME}.pub >> ~/.ssh/authorized_keys
fi

# hostname
AVTX_HOST=demo.${AVTX_USERNAME}.aviatrix.live
if [ "$(hostname)" != "${AVTX_HOST}" ]; then
    sudo hostname ${AVTX_HOST}
    echo ${AVTX_HOST} | sudo tee /etc/hostname
    sudo sed -i -e "s/127.0.0.1 localhost/127.0.0.1 localhost ${AVTX_HOST}/g" /etc/hosts
fi

# cron job - cleanup demo environment
crontab -l > cron.txt 2> /dev/null
echo "*/10 * * * * /home/ubuntu/aviatrix-demo/scripts/cron-auto-cleanup.sh" >> cron.txt
crontab cron.txt
rm -f cron.txt

# update MOTD
sudo tee /etc/update-motd.d/10-aviatrix-demo-text > /dev/null <<"EOF"
#!/bin/bash

printf "\n"
printf "****************************** AVIATRIX DEMO **************************************\n\n"
if [ -f /home/ubuntu/aviatrix-demo/demo.running ]; then
    CONTROLLER=${HOSTNAME/demo/controller}
    printf "RUNNING -- https://${CONTROLLER}\n\n"

    printf "Add the engineering request VPCs:\n\t\tcd ~/aviatrix-demo && ./scripts/add-eng-request.sh\n"
    printf "Remove the engineering request VPCs:\n\t\tcd ~/aviatrix-demo && ./scripts/destroy-eng-request.sh\n"
    printf "Destroy entire environment:\n\t\tcd ~/aviatrix-demo && ./scripts/destroy-all.sh\n"
elif [ ! -f /home/ubuntu/aviatrix-demo/shared/init.tf ]; then
     printf "Configure your environment by creating /home/ubuntu/aviatrix-demo/shared/init.tf\n"

else
    printf "Setup your demo environment:\n\t\tcd ~/aviatrix-demo && ./scripts/build-demo.sh\n"
fi
printf "\n***********************************************************************************\n"
EOF
sudo chmod +x /etc/update-motd.d/10-aviatrix-demo-text
sudo rm -f /etc/update-motd.d/90-updates-available /etc/update-motd.d/91-release-upgrade /etc/update-motd.d/10-help-text /etc/update-motd.d/51-cloudguest

sudo ln -s /home/ubuntu/aviatrix-demo/scripts/aviatrix-demo /bin/aviatrix-demo
