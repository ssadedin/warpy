#!/bin/bash

INSTALL_SCRIPT_DIR=$(dirname $(realpath ${BASH_SOURCE}))
source $INSTALL_SCRIPT_DIR/common.sh

if [ $# -gt 0 ]; then
    IS_REINSTALL_PKG=$1
else
    IS_REINSTALL_PKG=0
fi

MOSDEPTH_DOCKER_IMG="quay.io/biocontainers/mosdepth"
IMG_TAG="0.3.4--hd299d5a_0"
IS_INSTALL_DOCKER_IMG=1

if is_docker_img_found $MOSDEPTH_DOCKER_IMG $IMG_TAG; then
    if  [ $IS_REINSTALL_PKG -eq 1 ] ; then
        remove_docker_containers_for_img $MOSDEPTH_DOCKER_IMG $IMG_TAG
        docker rmi $MOSDEPTH_DOCKER_IMG:$IMG_TAG
    else
        echo "Docker image \"${MOSDEPTH_DOCKER_IMG}:${IMG_TAG}\" already exists, skipping installation for Mosdepth..."
        IS_INSTALL_DOCKER_IMG=0
    fi
fi

if [ $IS_INSTALL_DOCKER_IMG -eq 1 ]; then
    docker pull $MOSDEPTH_DOCKER_IMG:$IMG_TAG
fi
