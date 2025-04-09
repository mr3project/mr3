#!/bin/bash

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

DIR="$(cd "$(dirname "$0")" && pwd)"
BASE_DIR=$(readlink -f $DIR/..)
source $BASE_DIR/env.sh
source $BASE_DIR/common-setup.sh
source $MR3_BASE_DIR/mr3-setup.sh

function upload_hdfslib_mr3_main {
    COMPILE_OUT_FILE=${COMPILE_OUT_FILE:-$LOG_BASE_DIR/upload-hdfslib-mr3.log}

    common_setup_init
    mr3_setup_init

    has_hdfs=$(which hdfs 2>> $COMPILE_OUT_FILE | wc -l)
    if [[ $has_hdfs -gt 0 ]]; then
        hdfs dfs -rm -r $MR3_HDFS_LIB_DIR >> $COMPILE_OUT_FILE 2>&1

        echo -e "\n# Uploading MR3 jar file to HDFS #"
        echo -e "Output (HDFS): $MR3_HDFS_LIB_DIR\n"
        hdfs dfs -mkdir -p $MR3_HDFS_LIB_DIR >> $COMPILE_OUT_FILE 2>&1

        hdfs dfs -put $MR3_LIB_DIR/* $MR3_HDFS_LIB_DIR >> $COMPILE_OUT_FILE 2>&1

        hdfs dfs -ls -R $MR3_HDFS_LIB_DIR 2>&1
    fi
}

upload_hdfslib_mr3_main $@
