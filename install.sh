#!/bin/bash

if [ $# -ne 1 ]; then
    echo "Usage: $0 <URL or path to tar.gz>"
    exit 1
fi

SOURCE=$1
TEMP_FILE=""

if [[ $SOURCE == http://* || $SOURCE == https://* ]]; then
    echo "Downloading from URL: $SOURCE"
    TEMP_FILE=$(mktemp)
    if ! curl -s -L -o "$TEMP_FILE" "$SOURCE"; then
        echo "Error: Failed to download file from $SOURCE"
        rm -f "$TEMP_FILE"
        exit 1
    fi
    TAR_FILE="$TEMP_FILE"
else
    echo "Using local file: $SOURCE"
    if [ ! -f "$SOURCE" ]; then
        echo "Error: Local file $SOURCE does not exist"
        exit 1
    fi
    TAR_FILE="$SOURCE"
fi

echo "Extracting archive..."
tar -xzf "$TAR_FILE" --strip-components=1

[ -n "$TEMP_FILE" ] && rm -f "$TEMP_FILE"

echo "Installing MR3 binary files --- Completed"

mkdir -p kubernetes/key
mkdir -p kubernetes/ats-key
mkdir -p kubernetes/timeline-key

rm -f helm/hive/conf
rm -f helm/hive/key
rm -f helm/ats/conf
rm -f helm/ats/key
rm -f helm/timeline/conf
rm -f helm/timeline/key
rm -f helm/ranger/conf
rm -f helm/ranger/key

ln -s ../../kubernetes/conf helm/hive/conf
ln -s ../../kubernetes/key helm/hive/key
ln -s ../../kubernetes/ats-conf helm/ats/conf
ln -s ../../kubernetes/ats-key helm/ats/key
ln -s ../../kubernetes/timeline-conf helm/timeline/conf
ln -s ../../kubernetes/timeline-key helm/timeline/key
ln -s ../../kubernetes/ranger-conf helm/ranger/conf
ln -s ../../kubernetes/ranger-key helm/ranger/key

echo "Creating links --- Completed"

echo "Please see LICENSE-MR3.txt for the license"

