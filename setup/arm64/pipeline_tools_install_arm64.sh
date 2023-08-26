#!/bin/bash

set -euo pipefail

INSTALL_SCRIPT_DIR=$(dirname $(realpath ${BASH_SOURCE}))
source $INSTALL_SCRIPT_DIR/common.sh

IS_REINSTALL_PKG=0

if [[ $# > 0 ]]; then
    if [ $1 == "--reinstall" ] || [ $1 == "-r" ]; then
        IS_REINSTALL_PKG=1
    fi
fi

#Check pre-requisites
echo "----- Pre-requisite check -----"
MAC_OS_NAME="macOS"
MIN_MAC_OS_VER=13

if [[ "$(sw_vers)" =~ ^ProductName:[[:space:]]+([[:graph:]]+)$'\n'ProductVersion:[[:space:]]+([[:digit:]]+)\.[[:digit:]]+\.[[:digit:]]+.+$ ]]; then
    if [ ${BASH_REMATCH[1]} != $MAC_OS_NAME ]; then
        echo "The operating system should be \"${MAC_OS_NAME}\""
        exit 1
    fi

    if [[ $((${BASH_REMATCH[2]})) -lt $MIN_MAC_OS_VER ]]; then
        echo "macOS version ${MIN_MAC_OS_VER} or later is required"
        exit 1
    fi
fi

#if [ $(which brew) != "/opt/homebrew/bin/brew" ]; then
if [ -z $(which brew) ]; then
    echo "Homebrew is not installed"
    exit 1
fi

#if [ $(which conda) != "/opt/miniconda3/bin/conda" ]; then
if [ -z $(which conda) ]; then
    echo "Miniconda is not installed"
    exit 1
fi

echo "All pre-requisites are met"
echo ""

INSTALL_DIR=$(realpath $INSTALL_SCRIPT_DIR/../../tools)
mkdir -p $INSTALL_DIR

#Install Dorado
echo "----- Dorado -----"
source $INSTALL_SCRIPT_DIR/dorado_install.sh $INSTALL_DIR $IS_REINSTALL_PKG
echo ""

#Install Minimap2
echo "----- Minimap2 -----"
install_brew_pkg minimap2 $IS_REINSTALL_PKG
echo ""

#Install Clair3
echo "----- Clair3 -----"
if [ $IS_REINSTALL_PKG -eq 1 ]; then
    source $INSTALL_SCRIPT_DIR/clair3_install.sh -d $INSTALL_DIR -r
else
    source $INSTALL_SCRIPT_DIR/clair3_install.sh -d $INSTALL_DIR
fi

echo ""

#Install bamstats, pod5, Sniffles2 into a Conda environment
echo "----- bamstats, pod5, Sniffles2 -----"
source $INSTALL_SCRIPT_DIR/fastcat_pod5_sniffles_install.sh $IS_REINSTALL_PKG
echo ""

echo "ONT pipeline tools installation completed"
