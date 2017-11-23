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

# /usr/local owned by local user
sudo chown ${USER} /usr/local

# install go
brew install go
export GOPATH=/usr/local/gopath

# terraform aws provider
mkdir -p $GOPATH/src/github.com/terraform-providers
cd $GOPATH/src/github.com/terraform-providers
git clone https://github.com/terraform-providers/terraform-provider-aws.git
cd $GOPATH/src/github.com/terraform-providers/terraform-provider-aws
make build

# terraform avtx deps
cd $GOPATH/src/github.com/
mkdir ajg
cd ajg
git clone https://github.com/ajg/form.git
cd form
go install

cd $GOPATH/src/github.com/
mkdir davecgh/
cd davecgh
git clone https://github.com/davecgh/go-spew.git
cd go-spew/spew
go install

cd $GOPATH/src/github.com/
mkdir -p AviatrixSystems
cd AviatrixSystems
git clone https://github.com/AviatrixSystems/go-aviatrix.git
cd go-aviatrix/goaviatrix
go install

# terraform aviatrix provider
cd $GOPATH/src/github.com/terraform-providers
git clone https://github.com/AviatrixSystems/terraform-provider-aviatrix.git
cd terraform-provider-aviatrix
make 

# accept license agreement in aws marketplace
echo Please accept the license agreement before continuing.  Press enter if complete.
echo https://aws.amazon.com/marketplace/pp?sku=zemc6exdso42eps9ki88l9za
read

# create licenses
# create aws account
# update init.tf
# create aws iam account
