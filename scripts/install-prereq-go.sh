#!/bin/bash
#-----------------------------------------------------------------------------
# Installs the golang prerequisites for the terraform-based demo.
# This should be sourced from one of the other install-prereq-* scripts.
#-----------------------------------------------------------------------------

export GOROOT=/usr/local/go/current
export GOPATH=/usr/local/gopath
if [ ! -d ${GOPATH} ]; then
    sudo mkdir -p /usr/local/gopath
    sudo chown ubuntu /usr/local/gopath
fi

# go - terraform
go get github.com/hashicorp/terraform

# go - terraform aws provider
go get github.com/terraform-providers/terraform-provider-aws

# go - terraform avtx deps
go get github.com/ajg/form
go get github.com/davecgh/go-spew/spew
go get github.com/AviatrixSystems/go-aviatrix/goaviatrix
go get github.com/google/go-querystring/query

# go - terraform aviatrix provider
# go get github.com/terraform-providers/terraform-provider-aviatrix
go get github.com/AviatrixSystems/terraform-provider-aviatrix
pushd $GOPATH/src/github.com/AviatrixSystems/terraform-provider-aviatrix/bin/terraform-provider-aviatrix/
sed -i -e 's/terraform-providers/AviatrixSystems/' main.go
go install
popd

# update the provider
if [ ! -f ~/.terraformrc ]; then
    cat <<EOF > ~/.terraformrc
providers {
  "aviatrix" = "/usr/local/gopath/bin/terraform-provider-aviatrix"
}
EOF
fi

sudo echo GOROOT=$GOROOT > /etc/profile.d/300-aviatrix-demo.sh
sudo echo GOPATH=$GOPATH >> /etc/profile.d/300-aviatrix-demo.sh
