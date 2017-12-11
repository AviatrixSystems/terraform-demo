#!/bin/bash
#-----------------------------------------------------------------------------
# Installation script for Aviatrix terraform based demo
# This script installs the Ubuntu/Debian packages required for this demo
# including terraform and golang.
#-----------------------------------------------------------------------------

TOP="$( cd "$(dirname "$0")/.." ; pwd -P )"

sudo apt-get update

# terraform
which terraform > /dev/null 2>&1
if [ $? -ne 0 ]; then
    sudo apt install -y unzip wget
    if [ $? -ne 0 ]; then; exit 1; fi
    wget https://releases.hashicorp.com/terraform/0.11.1/terraform_0.11.1_linux_amd64.zip
    if [ $? -ne 0 ]; then; exit 1; fi
    unzip terraform_0.11.1_linux_amd64.zip
    if [ $? -ne 0 ]; then; exit 1; fi
    sudo mv terraform /usr/local/bin/
    if [ $? -ne 0 ]; then; exit 1; fi
    sudo ln -s /usr/local/bin/terraform /usr/bin/terraform
fi

# install go
which go > /dev/null 2>&1
if [ $? -ne 0 ]; then
    wget https://redirector.gvt1.com/edgedl/go/go1.9.2.linux-amd64.tar.gz
    tar -xvf go1.9.2.linux-amd64.tar.gz
    sudo mkdir -p /usr/local/go
    sudo mv ./go /usr/local/go/go-1.9.2
    sudo rm /usr/local/go/current
    sudo ln -sf /usr/local/go/go-1.9.2 /usr/local/go/current
    sudo chown -R root:root /usr/local/go/go-1.9.2
    sudo ln -sf /usr/local/go/current/bin/godoc /usr/bin/godoc
    sudo ln -sf /usr/local/go/current/bin/gofmt /usr/bin/gofmt
    sudo ln -sf /usr/local/go/current/bin/go /usr/bin/go
fi

source ${TOP}/scripts/install-prereq-go.sh

# accept license agreement in aws marketplace
echo Please accept the license agreement before continuing.  Press enter if complete.
echo https://aws.amazon.com/marketplace/pp?sku=zemc6exdso42eps9ki88l9za

