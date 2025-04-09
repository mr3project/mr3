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

function tez_setup_init {
    TEZ_LIB_BASE_DIR=$TEZ_BASE_DIR/tezjar
    TEZ_LIB_DIR=$TEZ_LIB_BASE_DIR/tez-$TEZ_REV
    TEZ_CLASSPATH=$TEZ_LIB_DIR/*:$TEZ_LIB_DIR/lib/*

    TEZ_HDFS_LIB_DIR=$HDFS_LIB_DIR/tez
}

function tez_setup_update_conf_dir {
    # required by HIVE-19827 (bin/hive)
    export TEZ_CONF_DIR=$BASE_DIR/conf/$CONF_TYPE
}

function tez_setup_update_yarn_opts {
    local_mode=$1

    if [[ $local_mode = false ]]; then
        TEZ_NATIVE_LIB="-Dnative.lib=$HADOOP_NATIVE_LIB"

        export YARN_OPTS="$YARN_OPTS $TEZ_NATIVE_LIB"
    fi
}

