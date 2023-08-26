#!/bin/bash

set -euo pipefail

source common.sh

INSTALL_DIR=$1

if [ $# -gt 1 ]; then
    IS_REINSTALL_PKG=$2
else
    IS_REINSTALL_PKG=0
fi

IS_LINK_AUTOCONF=1

AUTOCONF_VER=2.69
OPENSSL_VER=3
DORADO_VER="0.3.4"
DORADO_TOOL_NAME="dorado-${DORADO_VER}-osx-arm64"
DORADO_DOWNLOAD_FILE_NAME="${DORADO_TOOL_NAME}.tar.gz"
#The Clair3 model (from rerio) needs to match with the basecalling model here
DORADO_MODEL="dna_r10.4.1_e8.2_400bps_hac@v4.1.0"

#Install pre-requisities for Dorado
install_brew_pkg autoconf@${AUTOCONF_VER} $IS_REINSTALL_PKG $IS_LINK_AUTOCONF
install_brew_pkg openssl@${OPENSSL_VER} $IS_REINSTALL_PKG
install_brew_pkg zstd $IS_REINSTALL_PKG
install_brew_pkg libaec $IS_REINSTALL_PKG

IS_INSTALL_DORADO=1

if [ -d $INSTALL_DIR/$DORADO_TOOL_NAME ]; then
    if [ $IS_REINSTALL_PKG -eq 1 ]; then
        rm -rf "$INSTALL_DIR/$DORADO_TOOL_NAME"
    else
        echo "$DORADO_TOOL_NAME is already installed, skipping..."
        IS_INSTALL_DORADO=0
    fi
fi

if [ $IS_INSTALL_DORADO -eq 1 ]; then
    wget -P $INSTALL_DIR https://cdn.oxfordnanoportal.com/software/analysis/${DORADO_DOWNLOAD_FILE_NAME}

    tar -zxvf "$INSTALL_DIR/$DORADO_DOWNLOAD_FILE_NAME" -C $INSTALL_DIR
    rm "$INSTALL_DIR/$DORADO_DOWNLOAD_FILE_NAME"
fi

#Download basecalling model
DORADO_MODEL_DIR="../../models/"
mkdir -p $DORADO_MODEL_DIR

IS_DOWNLOAD_DORADO_MODEL=1

if [ -d "$DORADO_MODEL_DIR/$DORADO_MODEL" ]; then
    if [ $IS_REINSTALL_PKG -eq 1 ]; then
        rm -rf "$DORADO_MODEL_DIR/$DORADO_MODEL"
    else
        echo "Basecalling model \"$DORADO_MODEL\" already exists, skipping model download..."
        IS_DOWNLOAD_DORADO_MODEL=0
    fi
fi

if [ $IS_DOWNLOAD_DORADO_MODEL -eq 1 ]; then
    echo "Downloading basecalling model \"$DORADO_MODEL\""
    "${INSTALL_DIR}/${DORADO_TOOL_NAME}/bin/dorado" download --model $DORADO_MODEL --directory $DORADO_MODEL_DIR
fi
