#!/bin/bash

set -euo pipefail

download_dorado_model() {
    local DORADO_MODELS_DIR=$1
    local DORADO_MODEL=$2
    local INSTALL_DIR=$3
    local DORADO_TOOL_NAME=$4
    local IS_REINSTALL_PKG=$5
    local IS_DOWNLOAD_DORADO_MODEL=1

    if [ -d "$DORADO_MODELS_DIR/$DORADO_MODEL" ]; then
        if [ $IS_REINSTALL_PKG -eq 1 ]; then
            rm -rf "$DORADO_MODELS_DIR/$DORADO_MODEL"
        else
            echo "Basecalling model \"$DORADO_MODEL\" already exists, skipping model download..."
            IS_DOWNLOAD_DORADO_MODEL=0
        fi
    fi

    if [ $IS_DOWNLOAD_DORADO_MODEL -eq 1 ]; then
        echo "Downloading basecalling model \"$DORADO_MODEL\""
        "${INSTALL_DIR}/${DORADO_TOOL_NAME}/bin/dorado" download --model $DORADO_MODEL --directory $DORADO_MODELS_DIR
    fi
}

INSTALL_SCRIPT_DIR=$(dirname $(realpath ${BASH_SOURCE}))
source $INSTALL_SCRIPT_DIR/common.sh

INSTALL_DIR=$1

if [ $# -gt 1 ]; then
    IS_REINSTALL_PKG=$2
else
    IS_REINSTALL_PKG=0
fi

IS_LINK_AUTOCONF=1

AUTOCONF_VER=2.69
OPENSSL_VER=3
DORADO_VER="0.5.0"
DORADO_TOOL_NAME="dorado-${DORADO_VER}-osx-arm64"
DORADO_DOWNLOAD_FILE_NAME="${DORADO_TOOL_NAME}.tar.gz"
#The Clair3 models (from rerio) needs to match with the basecalling models here
DORADO_MODEL_V4_1_0="dna_r10.4.1_e8.2_400bps_hac@v4.1.0"
DORADO_MODEL_V4_2_0="dna_r10.4.1_e8.2_400bps_hac@v4.2.0"
DORADO_MODEL_V4_3_0="dna_r10.4.1_e8.2_400bps_hac@v4.3.0"

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
    download_from_web "https://cdn.oxfordnanoportal.com/software/analysis" $DORADO_TOOL_NAME $INSTALL_DIR
fi

#Download basecalling model
DORADO_MODELS_DIR="$(realpath $INSTALL_DIR)/../models/dorado"
mkdir -p $DORADO_MODELS_DIR

download_dorado_model $DORADO_MODELS_DIR $DORADO_MODEL_V4_1_0 $INSTALL_DIR $DORADO_TOOL_NAME $IS_REINSTALL_PKG
download_dorado_model $DORADO_MODELS_DIR $DORADO_MODEL_V4_2_0 $INSTALL_DIR $DORADO_TOOL_NAME $IS_REINSTALL_PKG
download_dorado_model $DORADO_MODELS_DIR $DORADO_MODEL_V4_3_0 $INSTALL_DIR $DORADO_TOOL_NAME $IS_REINSTALL_PKG
