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
    echo "Usage: hiveserver2-service.sh [command] [option(s)]"
    echo " start                          Start HiveServer2 on port defined in HIVE?_SERVER2_PORT"
    echo " stop                           Stop HiveServer2 on port defined in HIVE?_SERVER2_PORT"
    echo " restart                        Restart HiveServer2 on port defined in HIVE?_SERVER2_PORT" 
    common_setup_print_usage_common_options
    common_setup_print_usage_conf_mode
    mr3_setup_print_usage_amprocess
    hive_setup_print_usage_hiveconf
    echo " <HiveServer2 option>           Add a HiveServer2 option; may be repeated at the end"
    echo ""
    echo "Example: ./hiveserver2-service.sh start --tpcds --hiveconf hive.server2.mr3.share.session=true"
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

    START_HIVE_SERVER2=false
    STOP_HIVE_SERVER2=false
    AM_PROCESS=false
    while [ "${1+defined}" ]; do
      case "$1" in
        -h|--help)
          print_usage
          exit 1
          ;;
        start)
          START_HIVE_SERVER2=true
          shift
          ;;
        stop)
          STOP_HIVE_SERVER2=true
          shift
          ;;
        restart)
          START_HIVE_SERVER2=true
          STOP_HIVE_SERVER2=true
          shift
          ;;
        --amprocess)
          AM_PROCESS=true
          shift
          ;;
        *)
          export HIVE_OPTS="$HIVE_OPTS $@"
          break
          ;;
      esac
    done

    if [ $START_HIVE_SERVER2 = false ] && [ $STOP_HIVE_SERVER2 = false ]; then
      error "command not provided"
    fi
}

function hiveserver2_service_init {
    if [ $LOCAL_MODE = true ]; then
        export HADOOP_HOME=$HADOOP_HOME_LOCAL
    fi

    # setup environment variables, e.g. HIVE_HOME, PATH
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
    
    hive_setup_init_heapsize_mb $HIVE_SERVER2_HEAPSIZE

    BASE_OUT=$HIVE_BASE_DIR/hiveserver2-service-result

    echo -e "\n# Running HiveServer2 using Hive-MR3 #\n" >&2
    hive_setup_init_output_dir $LOCAL_MODE $BASE_OUT
}

function start_hiveserver2 {
    # check if the hiveserver2 port is currently used by any process
    # get the pid of the running process on hiveserver2 port
    declare hiveserver2_pid
    hive_setup_get_pid_by_port "$HIVE_SERVER2_PORT" hiveserver2_pid

    # if no process running hiveserver2, then start hiveserver2 
    declare -i return_code=0
    if [ -z "$hiveserver2_pid" ]; then
        echo "starting HiveServer2 on port $HIVE_SERVER2_PORT..."
        hive --service hiveserver2 &
    else
        # given a pid, check if the process is hiveserver2
        if [ -n "$(ps -fp $hiveserver2_pid | grep HiveServer2)" ]; then
            echo "HiveServer2($hiveserver2_pid) already running on port $HIVE_SERVER2_PORT"
        elif [[ $hiveserver2_pid == "-" ]]; then
            warning "Process unknown running on port $HIVE_SERVER2_PORT. Process owned by different user"
        else
            warning "Process($hiveserver2_pid) running on port $HIVE_SERVER2_PORT not HiveServer2"
            return_code=1
        fi
    fi

    return $return_code
}

function stop_hiveserver2 {
    # check if the hiveserver2 port is currently used by any process
    # get the pid of the running process on hiveserver2 port
    declare hiveserver2_pid
    hive_setup_get_pid_by_port "$HIVE_SERVER2_PORT" hiveserver2_pid

    # given a pid, try to kill that process
    declare -i return_code=0
    if [ -n "$hiveserver2_pid" ]; then
        # skip checking if the process is HiveServer2 because the output of ps may be truncated 
        echo "HiveServer2($hiveserver2_pid) running on port $HIVE_SERVER2_PORT"
        echo "Attmepting to stop HiveServer2..."
        kill $hiveserver2_pid
        if [ $? -ne 0 ]; then
            echo "Failed to stop HiveServer2"
            return_code=1
        else
            hive_setup_wait_for_pid_stop $hiveserver2_pid
        fi
        if  [[ $hiveserver2_pid == "-" ]]; then
            warning "Unknown process running on port $HIVE_SERVER2_PORT"
        fi
    fi

    return $return_code
}

function main {
    hive_setup_parse_args_common $@
    parse_args $REMAINING_ARGS

    # initialize environment vars, setup output directory
    hiveserver2_service_init

    declare log_dir="$OUT/hive-logs"
    declare out_file="$log_dir/out-hiveserver2.txt"

    # update log path
    hive_setup_config_hive_logs "$log_dir"
    # update HADOOP_OPTS and HADOOP_CLASSPATH
    hive_setup_server2_update_hadoop_opts $HIVE_SERVER2_PORT $LOCAL_MODE
    hive_setup_init_run_configs $OUT $LOCAL_MODE $AM_PROCESS $LOG_LEVEL

    declare -i return_code=0

    # stop hiveserver2 for the option 'stop'
    if [ $STOP_HIVE_SERVER2 = true ]; then
        echo "Stopping HiveServer2..." >&2
        stop_hiveserver2 >> $out_file 2>&1
        #[ $? != 0 ] && let return_code=1
    fi

    # start hiveserver2 for the option 'start'
    # start hiveserver2 only if stopping successfully for the option 'restart'
    if [ $START_HIVE_SERVER2 = true ] && [ $return_code -eq 0 ]; then
        echo "Starting HiveServer2..." >&2
        start_hiveserver2 >> $out_file 2>&1
        [ $? != 0 ] && let return_code=1
    fi

    env >> $OUT/env
    exit $return_code
}

main $@
