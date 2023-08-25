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
