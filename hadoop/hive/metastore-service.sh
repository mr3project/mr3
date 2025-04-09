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
    echo " start                          Start Metastore on port defined in HIVE?_METASTORE_PORT"
    echo " stop                           Stop Metastore on port defined in HIVE?_METASTORE_PORT"
    echo " restart                        Restart Metastore on port defined in HIVE?_METASTORE_PORT" 
    common_setup_print_usage_common_options
    common_setup_print_usage_conf_mode
    echo " --init-schema                  Initialize the database schema"
    hive_setup_print_usage_hiveconf
    echo " <Metastore option>             Add a Metastore option; may be repeated at the end"
    echo "" 
    echo "Example: ./metastore-service.sh start --tpcds --init-schema"
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

function parse_args {
    if [ $# = 0 ]; then
       print_usage
       exit 1 
    fi

    START_METASTORE=false
    STOP_METASTORE=false
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
        stop)
          STOP_METASTORE=true
          shift
          ;;
        restart)
          START_METASTORE=true
          STOP_METASTORE=true
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

    if [ $START_METASTORE = false ] && [ $STOP_METASTORE = false ]; then
      error "command not provided"
    fi
}

function metastore_service_init {
    if [ $LOCAL_MODE = true ]; then
        export HADOOP_HOME=$HADOOP_HOME_LOCAL
    fi

    # set up environment variables, e.g. HIVE_HOME, PATH
    common_setup_init
    hadoop_setup_init
    tez_setup_init
    mr3_setup_init
    hive_setup_init

    hive_setup_check_hive_home || error "HIVE_HOME not a directory: $HIVE_HOME"

    # set up a configuration directory
    hive_setup_init_conf

    if [ $LOCAL_MODE = true ]; then
        export HIVE_METASTORE_PORT=$HIVE_METASTORE_LOCAL_PORT
    fi

    hive_setup_init_heapsize_mb $HIVE_METASTORE_HEAPSIZE

    BASE_OUT=$HIVE_BASE_DIR/metastore-service-result

    echo -e "\n# Running Metastore using Hive-MR3 #\n" >&2
    hive_setup_init_output_dir $LOCAL_MODE $BASE_OUT
}

function start_metastore {
    # check if the metastore port is currently used by any process
    # get the pid of the running process on metastore port    
    declare metastore_pid
    hive_setup_get_pid_by_port "$HIVE_METASTORE_PORT" metastore_pid

    # if no process running metastore, then start metastore
    declare -i return_code=0
    if [ -z "$metastore_pid" ]; then
        echo "starting hive metastore on port $HIVE_METASTORE_PORT..."
        if [[ $INIT_SCHEMA = true ]]; then
            if [[ $CONF_TYPE = local ]]; then
                schematool -initSchema -dbType derby
            else
                schematool -initSchema -dbType $HIVE_METASTORE_DB_TYPE
            fi
        fi
        hive --service metastore -p $HIVE_METASTORE_PORT & 
    else
        # given a pid, check if the process is metastore
        if [ -n "$(ps -fp $metastore_pid | grep HiveMetaStore)" ]; then
            echo "hive metastore($metastore_pid) already running on port $HIVE_METASTORE_PORT"
        elif [[ $metastore_pid == "-" ]]; then
            warning "Process unknown running on port $HIVE_METASTORE_PORT. Process owned by different user"
        else
            warning "Process($metastore_pid) running on port $HIVE_METASTORE_PORT not hive metastore"
            return_code=1
        fi
    fi

    return $return_code
}

function stop_metastore {
    # check if the metastore port is currently used by any process
    # get the pid of the running process on metastore port    
    declare metastore_pid
    hive_setup_get_pid_by_port "$HIVE_METASTORE_PORT" metastore_pid

    # given a pid, try to kill that process
    declare -i return_code=0
    if [ -n "$metastore_pid" ]; then
        if [ -n "$(ps -fp $metastore_pid | grep HiveMetaStore)" ]; then
            echo "hive metastore($metastore_pid) running on port $HIVE_METASTORE_PORT"
            echo "Attmepting to stop metastore..."
            kill $metastore_pid
            if [ $? -ne 0 ]; then
                echo "Failed to stop metastore"
                return_code=1
            else
                hive_setup_wait_for_pid_stop $metastore_pid
            fi
        elif  [[ $metastore_pid == "-" ]]; then
            warning "Process unknown running on port $HIVE_METASTORE_PORT. Process owned by different user"
        else
            warning "Process($metastore_pid) running on port $HIVE_METASTORE_PORT not hive metastore"

            return_code=1
        fi
    fi

    return $return_code
}

function main {
    hive_setup_parse_args_common $@    
    parse_args $REMAINING_ARGS

    # initialize environment vars, set up an output directory
    metastore_service_init

    declare log_dir="$OUT/hive-logs"
    declare out_file="$OUT/out-metastore.txt"

    hive_setup_config_hive_logs "$log_dir"
    hive_setup_init_run_configs $OUT $LOCAL_MODE false $LOG_LEVEL

    declare -i return_code=0

    # stop metastore for the option 'stop'
    if [ $STOP_METASTORE = true ]; then
        echo "Stopping Metastore..." >&2
        stop_metastore >> $out_file 2>&1
        #[ $? != 0 ] && let return_code=1
    fi

    # start metastore for the option 'start'
    # start metastore only if stopping successfully for the option 'restart'
    if [ $START_METASTORE = true ] && [ $return_code -eq 0 ]; then
        echo "Starting Metastore..." >&2
        start_metastore >> $out_file 2>&1
        [ $? != 0 ] && let return_code=1
    fi

    exit $return_code
}

main $@
