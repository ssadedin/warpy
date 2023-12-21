#!/bin/bash

set -euo pipefail

INSTALL_SCRIPT_DIR=$(dirname $(realpath ${BASH_SOURCE}))
source $INSTALL_SCRIPT_DIR/common.sh

PYPY_VER="3.9-v7.3.8-osx64"
MPMMATH_VER="1.2.1"
#The samtools/htslib version is hardcoded in Clair3 (https://github.com/HKU-BAL/Clair3/blob/181f55d7a741855597d083baffc4551949d2837e/build.py#L7)
SAMTOOLS_VER="1.15.1"
HTSLIB_VER="1.15.1"
LONGPHASE_VER="1.5"
CLAIR3_MODEL_V4_1_0="r1041_e82_400bps_hac_v410"
CLAIR3_MODEL_V4_2_0="r1041_e82_400bps_hac_v420"
CLAIR3_MODEL_V4_3_0="r1041_e82_400bps_hac_v430"

show_help_msg() {
    echo "Usage: $1 --dir|-d <Clair3 host directory path> --model|-m <Clair3 model> --reinstall|-r --help|-h"
    echo "          --dir|-d: Clone Clair3 from repository to under the directory specified"
    echo "          --model|-m: Clair3 model to download"
    echo "          --reinstall|-r: Reinstall the Homebrew packages when they are installed"
    echo "          --help|-h: Show this help message"
}

download_clair3_model() {
    local CLAIR3_MODEL=$1
    local CLAIR3_MODELS_DIR=$2
    local IS_REINSTALL_PKG=$3
    local IS_DOWNLOAD_CLAIR3_MODEL=1

    if [ -d "$CLAIR3_MODELS_DIR/$CLAIR3_MODEL" ]; then
        if [ $IS_REINSTALL_PKG -eq 1 ]; then
            rm -rf "$CLAIR3_MODELS_DIR/$CLAIR3_MODEL"
        else
            echo "Clair3 model \"$CLAIR3_MODEL\" already exists, skipping model download..."
            IS_DOWNLOAD_CLAIR3_MODEL=0
        fi
    fi

    if [ $IS_DOWNLOAD_CLAIR3_MODEL -eq 1 ]; then
        echo "Downloading Clair3 model \"$CLAIR3_MODEL\""

        mkdir -p $CLAIR3_MODELS_DIR
        download_from_web "https://cdn.oxfordnanoportal.com/software/analysis/models/clair3" $CLAIR3_MODEL $CLAIR3_MODELS_DIR
    fi
}

CLAIR3_HOST_DIR_OPT=""
CLAIR3_MODEL=""
IS_REINSTALL_PKG=0

while [[ $# > 0 ]]; do
    case $1 in
        -d | --dir )
            CLAIR3_HOST_DIR_OPT="$2"
            shift 2
            ;;
        -m | --model )
            CLAIR3_MODEL="$2"
            shift 2
            ;;
        -r | --reinstall )
            IS_REINSTALL_PKG=1
            shift
            ;;
        -h | --help )
            show_help_msg $0
            exit 0
            ;;
        *)
            echo "Unknown argument $1"
            exit 1
            ;;
    esac
done

#Check input directory path
if [ -n "$CLAIR3_HOST_DIR_OPT" ]; then
    if [ ! -d "$CLAIR3_HOST_DIR_OPT" ]; then
        echo "Directory \"$CLAIR3_HOST_DIR_OPT\" does not exist"
        exit 1
    fi

    CLAIR3_HOST_DIR=$(realpath $CLAIR3_HOST_DIR_OPT)
else
    CLAIR3_HOST_DIR=$(realpath)
fi

CLAIR3_DIR="$CLAIR3_HOST_DIR/Clair3"

#Install required packages via Homebrew
install_brew_pkg "parallel" $IS_REINSTALL_PKG
install_brew_pkg "zlib" $IS_REINSTALL_PKG
install_brew_pkg "gnu-getopt" $IS_REINSTALL_PKG
install_brew_pkg "bash" $IS_REINSTALL_PKG
install_brew_pkg "miniforge" $IS_REINSTALL_PKG

if [[ "$(cat $HOME/.bash_profile)" =~ "export PATH=\"/opt/homebrew/opt/gnu-getopt/bin:\$PATH\"" ]]; then
    echo "gnu-getopt already added to \$PATH variable in .bash_profile, no modification required"
else
    echo "Adding gnu-getopt to .bash_profile..."
    echo 'export PATH="/opt/homebrew/opt/gnu-getopt/bin:$PATH"' >> $HOME/.bash_profile
fi

#Create Clair3 Conda environment
eval "$(/opt/miniconda3/bin/conda shell.bash hook)"

conda config --set remote_read_timeout_secs 180

CLAIR3_CONDA_ENV="clair3-arm64"
IS_INSTALL_CLAIR3=1

if [ $(conda env list | grep -c "^$CLAIR3_CONDA_ENV .*") -gt 0 ]; then
    if [ $IS_REINSTALL_PKG -eq 1 ]; then
        echo "Deleting existing Conda environment \"$CLAIR3_CONDA_ENV\"..."
        conda env remove --name $CLAIR3_CONDA_ENV --yes
    else
        echo "Conda environment \"$CLAIR3_CONDA_ENV\" already exists, skipping..."
        IS_INSTALL_CLAIR3=0
    fi
fi

if [ $IS_INSTALL_CLAIR3 -eq 1 ]; then
    echo "Creating Conda environment \"$CLAIR3_CONDA_ENV\"..."

    conda create -n clair3-arm64 python=3.9 --yes
    echo "Conda environment $CLAIR3_CONDA_ENV created"
    set +e
    conda activate clair3-arm64
    set -e
    echo "Conda environment $CLAIR3_CONDA_ENV activated"

    conda install -c apple tensorflow-deps=2.8.0 --yes

    python -m pip install tensorflow-macos
    python -m pip install tensorflow-metal

    pip install cffi
    #Do not upgrade numpy to avoid breaking the numpy version requirement for tensorflow-macos
    #pip install numpy --upgrade

    if [ -d $CLAIR3_DIR ]; then
        rm -rf $CLAIR3_DIR
    fi

    cd "$CLAIR3_HOST_DIR"
    git clone https://github.com/HKU-BAL/Clair3.git

    #Install pypy and samtools/htslib under Clair3 directory
    cd "Clair3"

    echo "Installing pypy under Clair3..."

    echo pypy${PYPY_VER}.tar.bz2
    echo https://downloads.python.org/pypy/pypy${PYPY_VER}.tar.bz2

    download_from_web "https://downloads.python.org/pypy" "pypy${PYPY_VER}" "."

    "./pypy${PYPY_VER}/bin/pypy" -m ensurepip
    "./pypy${PYPY_VER}/bin/pypy" -m pip install mpmath==$MPMMATH_VER

    echo "Installing samtools under Clair3..."

    download_from_web "https://github.com/samtools/samtools/archive/refs/tags" "${SAMTOOLS_VER}" "."
    cd "samtools-${SAMTOOLS_VER}"

    download_from_web "https://github.com/samtools/htslib/releases/download/${HTSLIB_VER}" "htslib-${HTSLIB_VER}" "."

    autoheader
    autoconf -Wno-syntax
    ./configure
    make -j
    cd ..

    #Build Clair3
    echo "Building Clair3..."
    python3 build.py

    #automake may depend on the latest version (currently 2.71) of autoconf
    install_brew_pkg "autoconf" $IS_REINSTALL_PKG
    install_brew_pkg "automake" $IS_REINSTALL_PKG

    #Install longphase (under Clair3)
    echo "Installing longphase..."
    download_from_web "https://github.com/twolinin/longphase/archive/refs/tags" "v${LONGPHASE_VER}" "."
    cd "longphase-${LONGPHASE_VER}"
    autoreconf -i
    ./configure
    make -j 4

    #Install whatshap (under Clair3)
    echo "Installing whatshap..."
    pip install --user whatshap

    conda deactivate
    conda clean --all --yes

    cd ..

    echo "Clair3 installation and setup completed"
fi

#Download the Clair3 model (should match with the model used in Dorado)
CLAIR3_MODELS_DIR="$CLAIR3_HOST_DIR/../models/Clair3"

if [ -z "$CLAIR3_MODEL" ]; then
    download_clair3_model $CLAIR3_MODEL_V4_1_0 $CLAIR3_MODELS_DIR $IS_REINSTALL_PKG
    download_clair3_model $CLAIR3_MODEL_V4_2_0 $CLAIR3_MODELS_DIR $IS_REINSTALL_PKG
    download_clair3_model $CLAIR3_MODEL_V4_3_0 $CLAIR3_MODELS_DIR $IS_REINSTALL_PKG
else
    download_clair3_model $CLAIR3_MODEL $CLAIR3_MODELS_DIR $IS_REINSTALL_PKG
fi
