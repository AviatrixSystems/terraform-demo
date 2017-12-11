#!/bin/sh
#-----------------------------------------------------------------------------
# Installation script for Aviatrix demo (Mac systems)
#-----------------------------------------------------------------------------

TOP="$( cd "$(dirname "$0")/.." ; pwd -P )"

# brew
which brew > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo Installing brew ...
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

# terraform
which terraform > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo Installing terraform ...
    brew install terraform
fi

# install go
which go > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo Installing go ...
    brew install go
fi

source ${TOP}/scripts/install-prereq-go.sh

# accept license agreement in aws marketplace
echo Please accept the license agreement before continuing.  Press enter if complete.
echo https://aws.amazon.com/marketplace/pp?sku=zemc6exdso42eps9ki88l9za
