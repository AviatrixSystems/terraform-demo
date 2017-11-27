#!/bin/sh
#-----------------------------------------------------------------------------
# Installation script for Aviatrix re:invent demo
#-----------------------------------------------------------------------------

# terraform
which terraform > /dev/null 2>&1
if [ $? -ne 0 ]; then
    cd /tmp
    curl -O https://releases.hashicorp.com/terraform/0.11.0/terraform_0.11.0_darwin_amd64.zip
    unzip -d /usr/local/bin terraform_0.11.0_darwin_amd64.zip
fi

# brew
which brew > /dev/null 2>&1
if [ $? -ne 0 ]; then
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

export GOPATH=/usr/local/gopath
if [ ! -d ${GOPATH} ]; then
    echo "sudo'ing to chown /usr/local ..."
    # /usr/local owned by local user
    sudo chown ${USER} /usr/local
    mkdir /usr/local/gopath
fi

# install go
which go > /dev/null 2>&1
if [ $? -ne 0 ]; then
    brew install go
fi

mkdir -p $GOPATH/src/github.com/terraform-providers

# terraform aws provider
if [ ! -d $GOPATH/src/github.com/terraform-providers/terraform-provider-aws ]; then
    cd $GOPATH/src/github.com/terraform-providers
    git clone https://github.com/terraform-providers/terraform-provider-aws.git
    cd $GOPATH/src/github.com/terraform-providers/terraform-provider-aws
    make build
else
    cd $GOPATH/src/github.com/terraform-providers/terraform-provider-aws
    git pull
    make build
fi

# terraform avtx deps
if [ ! -d $GOPATH/src/github.com/ajg/form ]; then
    cd $GOPATH/src/github.com/
    mkdir ajg
    cd ajg
    git clone https://github.com/ajg/form.git
    cd form
    go install
else
    cd $GOPATH/src/github.com/ajg/form
    git pull
    go install
fi

if [ ! -d $GOPATH/src/github.com/davecgh/go-spew ]; then
    cd $GOPATH/src/github.com/
    mkdir davecgh/
    cd davecgh
    git clone https://github.com/davecgh/go-spew.git
    cd go-spew/spew
    go install
else
    cd $GOPATH/src/github.com/davecgh/go-spew/spew
    git pull
    go install
fi

if [ ! -d $GOPATH/src/github.com/AviatrixSystems/go-aviatrix ]; then
    cd $GOPATH/src/github.com/
    mkdir -p AviatrixSystems
    cd AviatrixSystems
    git clone https://github.com/mike-r-mclaughlin/go-aviatrix.git
    cd go-aviatrix/goaviatrix
    go install
else
    cd $GOPATH/src/github.com/AviatrixSystems/go-aviatrix/goaviatrix
    git pull
    go install
fi

if [ ! -d $GOPATH/src/github.com/google/go-querystring ]; then
    cd $GOPATH/src/github.com
    mkdir -p google
    cd google
    git clone https://github.com/google/go-querystring.git
    cd go-querystring/query
    go install
else
    cd $GOPATH/src/github.com/google/go-querystring/query
    git pull
    go install
fi

if [ ! -d $GOPATH/src/github.com/hashicorp/terraform ]; then
    cd $GOPATH/src/github.com
    mkdir -p hashicorp
    cd hashicorp
    git clone https://github.com/hashicorp/terraform.git
    cd terraform
    make fmt && make
else
    cd $GOPATH/src/github.com/hashicorp/terraform
    git pull
    make fmt && make
fi

# terraform aviatrix provider
if [ ! -d $GOPATH/src/github.com/terraform-providers/terraform-provider-aviatrix ]; then
    cd $GOPATH/src/github.com/terraform-providers
    git clone https://github.com/mike-r-mclaughlin/terraform-provider-aviatrix.git
    cd terraform-provider-aviatrix
    make
else
    cd $GOPATH/src/github.com/terraform-providers/terraform-provider-aviatrix
    make
fi

# accept license agreement in aws marketplace
echo Please accept the license agreement before continuing.  Press enter if complete.
echo https://aws.amazon.com/marketplace/pp?sku=zemc6exdso42eps9ki88l9za
read

# create licenses
# create aws account
# update init.tf
# create aws iam account
