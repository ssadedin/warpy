install_brew_pkg() {
    TARGET_PKG=$1

    if [ $# -gt 1 ]; then
        IS_REINSTALL_PKG=$2
    else
        IS_REINSTALL_PKG=0
    fi

    if [ $# -gt 2 ]; then
        IS_LINK_PKG=$3
    else
        IS_LINK_PKG=0
    fi

    IS_PKG_INSTALLED=0
    if [[ $(brew list) =~ ^([[:graph:]]+[[:space:]]+)*${TARGET_PKG}([[:space:]]+[[:graph:]]+)*$ ]]; then
        IS_PKG_INSTALLED=1
    fi

    if [ $IS_PKG_INSTALLED -eq 1 ] && [ $IS_REINSTALL_PKG -eq 0 ]; then
        IS_LINK_PKG=0
    fi

    if [ $IS_PKG_INSTALLED -eq 1 ]; then
        if [ $IS_REINSTALL_PKG -eq 1 ]; then
            if [ $IS_LINK_PKG -eq 1 ]; then
                if [ $(echo "$(brew unlink $TARGET_PKG --dry-run)" | wc -l) -gt 1 ]; then
                    echo "Unlinking $TARGET_PKG..."
                    brew unlink $TARGET_PKG
                else
                    IS_LINK_PKG=0
                fi
            fi

            echo "Re-installing $TARGET_PKG..."
            brew reinstall $TARGET_PKG
        else
            echo "$TARGET_PKG is already installed, skipping..."
        fi
    else
        echo "Installing $TARGET_PKG..."
        brew install $TARGET_PKG
    fi

    if [ $IS_LINK_PKG -eq 1 ]; then
        echo "Linking $TARGET_PKG..."
        brew link $TARGET_PKG
    fi
}

is_env_found() {
    [ $(conda env list | grep -c "^${1} .*") -gt 0 ]
}

is_docker_img_found() {
    [ $(docker images -f reference="$1:$2" | grep -c "${1} *${2}") -gt 0 ]
}

remove_docker_containers_for_img() {
    for CONTAINER_ID in $(docker container ls -aq --filter ancestor="$1:$2"); do
        docker rm $CONTAINER_ID
    done
}

is_target_url_exist() {
    if curl -L -o /dev/null -s -I -f "$1"; then
        echo 1
    else
        echo 0
    fi
}

download_from_web() {
    URL_PREFIX=$1
    TARGET_NAME=$2
    INSTALL_DIR=$3

    ARCHIVE_EXTS=("tar.gz" "tar.bz2" "zip")
    DECOMPRESS_CMDS=("tar -zxvf target_file_path -C ${INSTALL_DIR}"
        "tar -zxvf target_file_path -C ${INSTALL_DIR}"
        "unzip -d ${INSTALL_DIR} target_file_path")

    for ((i=0; i<${#ARCHIVE_EXTS[@]}; i++)); do
        TARGET_FILE_NAME="${TARGET_NAME}.${ARCHIVE_EXTS[i]}"
        TARGET_URL="${URL_PREFIX}/${TARGET_FILE_NAME}"

        if [ $(is_target_url_exist $TARGET_URL) -eq 1 ]; then
            TARGET_FILE_PATH="${INSTALL_DIR}/${TARGET_FILE_NAME}"
            curl -L -o $TARGET_FILE_PATH $TARGET_URL
            CMD="${DECOMPRESS_CMDS[i]/target_file_path/${TARGET_FILE_PATH}}"
            eval "$CMD"
            rm $TARGET_FILE_PATH
            return 0
        fi
    done

    echo "Warning: Unable to download $TARGET_NAME from $URL_PREFIX"
}
