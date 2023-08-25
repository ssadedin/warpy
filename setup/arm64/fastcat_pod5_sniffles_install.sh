#!/bin/bash

set -euo pipefail

source common.sh

if [ $# -gt 0 ]; then
    IS_REINSTALL_PKG=$1
else
    IS_REINSTALL_PKG=0
fi

CONDA_ENV="ont_tools"
PYTHON_VER=3.9
IS_INSTALL_ONT_TOOLS=1

eval "$(/opt/miniconda3/bin/conda shell.bash hook)"

conda config --set remote_read_timeout_secs 180

if is_env_found $CONDA_ENV; then
    if  [ $IS_REINSTALL_PKG -eq 1 ] ; then
        conda env remove --name $CONDA_ENV --yes
    else
        echo "Conda environment \"${CONDA_ENV}\" already exists, skipping installation for fastcat, pod5, and sniffles2..."
        IS_INSTALL_ONT_TOOLS=0
    fi
fi

if [ $IS_INSTALL_ONT_TOOLS -eq 1 ]; then
    #Create a Conda environment to host the tools
    conda create -n $CONDA_ENV -c conda-forge -c bioconda -c nanoporetech fastcat --yes
    conda activate $CONDA_ENV

    conda install python=${PYTHON_VER} --yes

    pip install pod5

    pip install sniffles

    conda deactivate
fi
