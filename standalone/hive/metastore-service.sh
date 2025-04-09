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
source $HADOOP_BASE_DIR/hadoop-setup.sh
source $TEZ_BASE_DIR/tez-setup.sh
source $MR3_BASE_DIR/mr3-setup.sh
source $HIVE_BASE_DIR/hive-setup.sh

function print_usage {
    echo "Usage: metastore-service.sh [command] [options(s)]"
    echo " start                          Start Metastore on port defined in HIVE_METASTORE_PORT"
    common_setup_print_usage_common_options
    echo " --init-schema                  Initialize the database schema"
    hive_setup_print_usage_hiveconf
    echo " <Metastore option>             Add a Metastore option; may be repeated at the end"
    echo "" 
}

function warning {
    common_setup_log_warning ${FUNCNAME[1]} "$1"
}

function error {
    common_setup_log_error ${FUNCNAME[1]} "$1"
    print_usage
    exit 1
}

function metastore_service_parse_args {
    if [ $# = 0 ]; then
      print_usage
      exit 1 
    fi

    START_METASTORE=false
    INIT_SCHEMA=false

    while [ "${1+defined}" ]; do
      case "$1" in
        -h|--help)
          print_usage
          exit 1
          ;;
        start)
          START_METASTORE=true
          shift
          ;;
        --init-schema)
          INIT_SCHEMA=true
          shift
          ;;
        *)
          export HIVE_OPTS="$HIVE_OPTS $@"
          break
          ;;
      esac
    done

    if [ $START_METASTORE = false ]; then
      error "command not provided"
    fi
}

function metastore_service_init {
    hadoop_setup_init
    tez_setup_init
    mr3_setup_init
    hive_setup_init

    hive_setup_init_heapsize_mb $HIVE_METASTORE_HEAPSIZE

    echo -e "\n# Running Metastore #\n" >&2
    BASE_OUT=$HIVE_BASE_DIR/run-result/metastore
    hive_setup_init_output_dir $BASE_OUT
}

function start_metastore {
    return_code=0
    echo "Starting Metastore on port $HIVE_METASTORE_PORT..."
    if [[ $INIT_SCHEMA = true ]]; then
        schematool -initSchema -dbType $HIVE_METASTORE_DB_TYPE
    fi
    hive --service metastore -p $HIVE_METASTORE_PORT &
    return $return_code
}

function main {
    hive_setup_parse_args_common $@
    metastore_service_parse_args $REMAINING_ARGS

    if [ -e $BASE_DIR/lib/mysql-connector*.jar ]; then
      echo "A MySQL connector exists"
    else
      WGET_URL=https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-8.0.28.tar.gz
      echo "Downloading a MySQL connector: $WGET_URL"
      mkdir -p $BASE_DIR/lib/
      pushd $BASE_DIR/lib/
      wget $WGET_URL
      tar --strip-components=1 -zxf mysql-connector-java-8.0.28.tar.gz mysql-connector-java-8.0.28/mysql-connector-java-8.0.28.jar
      rm -f mysql-connector-java-8.0.28.tar.gz
      popd
    fi

    metastore_service_init

    log_dir="$OUT/hive-logs"
    out_file="$OUT/out-metastore.txt"

    hive_setup_config_hive_logs "$log_dir"
    hive_setup_init_run_configs $LOCAL_MODE 

    return_code=0

    if [ $START_METASTORE = true ]; then
        echo "Starting Metastore..." >&2
        start_metastore >> $out_file 2>&1
        [ $? != 0 ] && let return_code=1
    fi

    exit $return_code
}

main $@
