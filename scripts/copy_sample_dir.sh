#!/bin/bash

show_help_msg() {
    echo "Usage: $1 --src|-s <source FAST5 data directory path> --dest|-d <destination sample directory path> --help|-h"
    echo "          --src|-s: Source FAST5 files directory"
    echo "          --dest|-d: Pipeline sample directory to be created"
    echo "          --help|-h: Show this help message"
}

SRC_FAST5_DIR=""

while [[ $# > 0 ]]; do
    case $1 in
        -s | --src )
            SRC_FAST5_DIR="$2"
            shift 2
            ;;
        -d | --dest )
            USER_SAMPLE_DIR_NAME=$(basename $2)
            shift 2
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

if [ -z $SRC_FAST5_DIR ]; then
    echo "Source FAST5 file directory required."
    exit 1
fi

if [ ! -d $SRC_FAST5_DIR ]; then
    echo "\"$SRC_FAST5_DIR\" does not exist."
    exit 1
fi

BASE=$(dirname $(dirname $(realpath ${BASH_SOURCE})))
BATCHES_DIR="$BASE/batches"
DEFAULT_SAMPLE_DIR_NAME="test_sample_"$(date +%Y-%m-%d_%H-%M-%S)
DEST_SAMPLE_DIR_NAME=${USER_SAMPLE_DIR_NAME:-$DEFAULT_SAMPLE_DIR_NAME}
DEST_SAMPLE_DATA_DIR="$BATCHES_DIR/$DEST_SAMPLE_DIR_NAME/data"

mkdir -p $DEST_SAMPLE_DATA_DIR

SRC_FAST5_FILES="$SRC_FAST5_DIR/*.fast5"
for FAST5_FILE_PATH in $SRC_FAST5_FILES
do
    if [ -f $FAST5_FILE_PATH ]; then
        ln -fs "$FAST5_FILE_PATH" "$DEST_SAMPLE_DATA_DIR/$(basename $FAST5_FILE_PATH)"
    fi
done
