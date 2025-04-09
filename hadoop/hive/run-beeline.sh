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

function run_beeline_error {
    common_setup_log_error ${FUNCNAME[1]} "$1"
    print_usage
    exit 1
}

function print_usage {
    echo "Usage: run-beeline.sh [option(s)]"
    common_setup_print_usage_common_options
    common_setup_print_usage_conf_mode
    hive_setup_print_usage_hiveconf
    echo " <Beeline option>               Add a Beeline option; may be repeated at the end"
    echo "" 
}

function run_beeline_parse_args {
    while [ "${1+defined}" ]; do
        case "$1" in
            -h|--help)
                print_usage
                exit 1
                ;;
            *)
                export HIVE_OPTS="$HIVE_OPTS $@"
                break
                ;;
        esac
    done
}

function run_beeline_init {
    if [ $LOCAL_MODE == true ]; then
        export HADOOP_HOME=$HADOOP_HOME_LOCAL
    fi

    # setup environment variables, e.g. HIVE_HOME, PATH
    common_setup_init
    hadoop_setup_init
    tez_setup_init
    hive_setup_init

    hive_setup_check_hive_home || run_beeline_error "HIVE_HOME not a directory: $HIVE_HOME"

    # setup configuration directory
    hive_setup_init_conf

    hive_setup_init_heapsize_mb $HIVE_CLIENT_HEAPSIZE

    # Define script output Dir
    BASE_OUT=$HIVE_BASE_DIR/run-beeline-result
}

function run_beeline_start {
    declare -i return_code=0

    declare run_dir=$OUT
    declare output_file=$run_dir/out.txt
    declare hive_log_dir=$run_dir/hive-logs
    mkdir -p $run_dir

    hiveserver2_host=${HIVE_SERVER2_HOST_CUSTOM:-$HIVE_SERVER2_HOST}
    hiveserver2_port=${HIVE_SERVER2_PORT_CUSTOM:-$HIVE_SERVER2_PORT}
    if [[ $HIVE_SERVER2_AUTHENTICATION = KERBEROS ]]; then
        principal_name="principal=${HIVE_SERVER2_KERBEROS_PRINCIPAL_CUSTOM:-$HIVE_SERVER2_KERBEROS_PRINCIPAL}"
    else
        principal_name=""
    fi
    jdbc_options=$HIVE_SERVER2_JDBC_OPTS

    declare cmd="beeline -u \"jdbc:hive2://$hiveserver2_host:$hiveserver2_port/;${principal_name};${jdbc_options}\" -n $USER -p $USER \
--hiveconf hive.querylog.location=$hive_log_dir"

    # set javax.security.auth.useSubjectCredsOnly to false so as to be able to pass Kerberos tickets
    # if set to true, the user may get:
    #   Caused by: org.ietf.jgss.GSSException: No valid credentials provided (Mechanism level: Failed to find any Kerberos tgt)
    export HADOOP_OPTS="$HADOOP_OPTS -Djavax.security.auth.useSubjectCredsOnly=false"
    echo $cmd

    hive_setup_exec_cmd_timed "$cmd" $output_file false false
    return $?
}

function run_beeline_main {
    RUN_BEELINE=true
    hive_setup_parse_args_common $@
    run_beeline_parse_args $REMAINING_ARGS

    # initialize environment vars, setup output directory
    run_beeline_init

    hive_setup_init_output_dir $LOCAL_MODE $BASE_OUT

    # TEZ_CLASSPATH contains hadoop-common-*.jar which is required by Beeline
    export HADOOP_CLASSPATH=$TEZ_CLASSPATH:$HADOOP_CLASSPATH

    pushd $BASE_DIR > /dev/null
    echo -e "\n# Running Beeline using Hive-MR3 ($HIVE_REV) #\n" >&2

    run_beeline_start
    exit_code=$?
    popd > /dev/null

    exit $exit_code
}

run_beeline_main $@
