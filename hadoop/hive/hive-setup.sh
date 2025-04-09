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

# Check if file already been sourced
# Alternatively we could check return status of 'declare -F function_name' defined in script
if [ "${HIVE_SETUP_DEFINED:+defined}" ]; then
    exit 0;
fi
readonly HIVE_SETUP_DEFINED=true

function hive_setup_print_usage_hiveconf {
    echo " --hiveconf <key>=<value>       Add a configuration key/value; may be repeated at the end"
}

function hive_setup_parse_args_common {
    LOCAL_MODE=true
    CONF_TYPE=local

    while [[ -n $1 ]]; do
        case "$1" in
            --local)
                LOCAL_MODE=true
                CONF_TYPE=local
                shift
                ;;
            --tpcds)
                LOCAL_MODE=false
                CONF_TYPE=tpcds
                shift
                ;;
            --conf|--hiveconf)
                export HIVE_OPTS="$HIVE_OPTS ${@//--conf/--hiveconf}"
                shift 2
                ;;
            *)
                REMAINING_ARGS="$REMAINING_ARGS $1"
                shift
                ;;
        esac
    done

    if ! [[ $RUN_BEELINE = true ]] ; then
      export HIVE_OPTS="--hiveconf mr3.runtime=tez $HIVE_OPTS"
    fi
}

function hive_setup_init {
    export HIVE_HOME=$HIVE_BASE_DIR/hivejar/apache-hive-$HIVE_REV-bin

    HIVE_LOCAL_DATA=$HIVE_BASE_DIR/hive-local-data

    export MR3_CLASSPATH=$MR3_LIB_DIR/$MR3_TEZ_ASSEMBLY_JAR

    # HIVE uses $HIVE_LIB
    export HIVE_CONF_DIR=$HIVE_HOME/conf

    HIVE_JARS=$HIVE_HOME/lib
    HCATALOG_DIR=$HIVE_HOME/hcatalog
    HCATALOG_CONF_DIR=$HCATALOG_DIR/etc/hcatalog
    HCATALOG_JARS=$HCATALOG_DIR/share/hcatalog
    export HIVE_CLASSPATH=$HIVE_MYSQL_DRIVER:$HIVE_CONF_DIR:$HCATALOG_CONF_DIR:$HIVE_JARS/*:$HCATALOG_JARS/*

    HIVE_BIN=$HIVE_HOME/bin
    export PATH=$HIVE_BIN:$PATH
}

function hive_setup_init_conf {
    HIVE_MR3_CONF_DIR=$BASE_DIR/conf/$CONF_TYPE

    if ! [ -d "$HIVE_MR3_CONF_DIR" ]; then
      echo "ERROR: Not a directory, HIVE_MR3_CONF_DIR=$HIVE_MR3_CONF_DIR"
      exit 1;
    fi
}

function hive_setup_init_heapsize_mb {
    declare heapsize=$1

    export HADOOP_CLIENT_OPTS="-Xmx${heapsize}m $HIVE_MR3_JVM_OPTION $HADOOP_CLIENT_OPTS"
}

function hive_setup_check_hive_home {
    declare -i return_code=0

    # validate env.sh env vars
    if ! [ -d "$HIVE_HOME" ]; then
      return_code=1
    fi

    return $return_code
}

# Usage:
# get_pid_by_port $port var_for_pid
# var_for_pid should be uninitialized and can be any name, (pid), $ is left off
#
function hive_setup_get_pid_by_port {
    declare port=$1

    which ss > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "ss is not available. Please manually stop the process using port $port"
    else
        declare found_pid="$(ss -anpt | grep -E "LISTEN.*:$port" | awk '{ print $6 }' | cut -d',' -f2 | cut -d'=' -f2)"

        if [ -n "$found_pid" ]; then
            # use bash passed arg as reference
            eval "$2=$found_pid"
            echo "Found process $2 listening on port $port"
        else
            echo "No process listening on port $port"
        fi
    fi
}

function hive_setup_wait_for_pid_stop {
    declare pid=$1
    echo "Waiting for Process($pid) to stop..."
    while ps -p $pid; do sleep 1;done;
    echo "Process($pid) stopped."
}

function hive_setup_server2_update_hadoop_opts {
   declare hiveserver2_port=$1
   declare local_mode=$2

   export HADOOP_OPTS="$HADOOP_OPTS \
-Dhive.server2.host=$HIVE_SERVER2_HOST \
-Dhive.server2.port=$hiveserver2_port \
-Dhive.server2.authentication.mode=$HIVE_SERVER2_AUTHENTICATION \
-Dhive.server2.keytab.file=$HIVE_SERVER2_KERBEROS_KEYTAB \
-Dhive.server2.principal=$HIVE_SERVER2_KERBEROS_PRINCIPAL"
}

function hive_setup_config_hive_logs {
    declare output_dir=$1
    declare log_filename=${2:-hive.log}

    mkdir -p $output_dir
    export HIVE_OPTS="--hiveconf hive.querylog.location=$output_dir $HIVE_OPTS"

    # Cf. HIVE-19886
    # YARN_OPTS should be updated because some LOG objects may be initialized before HiveServer2.main() calls 
    # LogUtils.initHiveLog4j(), e.g., conf.HiveConf.LOG. Without updating YARN_OPTS, these LOG objects send their output
    # to hive.log in a default directory, e.g., /tmp/gitlab-runner/hive.log, and we end up with two hive.log files.
    export YARN_OPTS="-Dhive.log.dir=$output_dir -Dhive.log.file=$log_filename"
}

function hive_setup_update_conf_dir {
    declare conf_dir=$1

    cp -r $HIVE_CONF_DIR/* $conf_dir
    cp -r $HCATALOG_CONF_DIR/* $conf_dir
    cp -r $HIVE_MR3_CONF_DIR/* $conf_dir

    rm -f $conf_dir/*.template

    export HIVE_CONF_DIR=$conf_dir
    export HIVE_CLASSPATH=$HIVE_CONF_DIR:$HIVE_CLASSPATH
}

##
# Initialize the output directory
##
function hive_setup_init_output_dir {
    declare local_mode=$1
    declare output_dir=$2

    mkdir -p $output_dir > /dev/null 2>&1

    #create $OUT env var
    hive_setup_create_output_dir $output_dir

    OUT_CONF=$OUT/conf
    mkdir -p $OUT_CONF > /dev/null 2>&1

    cp $BASE_DIR/env.sh $OUT_CONF
    hadoop_setup_update_conf_dir $OUT_CONF
    tez_setup_update_conf_dir
    hive_setup_update_conf_dir $OUT_CONF
}

##
# Return Variables
# OUT  Directory script will output run files
# SCRIPT_START_TIME
##
function hive_setup_create_output_dir {
    declare base_dir=$1

    SCRIPT_START_TIME=$(date +%s)
    declare time_stamp="$(common_setup_get_time $SCRIPT_START_TIME)"
    export OUT=$base_dir/hive-$time_stamp-$(uuidgen | awk -F- '{print $1}')
    mkdir -p $OUT > /dev/null 2>&1
    echo -e "Output Directory: \n$OUT\n"
}

function hive_setup_init_run_configs {
    declare out_dir=$1
    declare local_mode=$2
    declare am_process=$3
    declare log_level=$4

    hive_setup_update_hadoop_opts $out_dir $local_mode $am_process

    YARN_OPTS=""  # YARN_OPTS already consumed in hive_setup_update_hadoop_opts
    hive_setup_metastore_update_hadoop_opts

    # do not include HIVE_CLASSPATH which is added to HADOOP_CLASSPATH by hive command
    export HADOOP_CLASSPATH=$MR3_CLASSPATH:$HIVE_MR3_CONF_DIR:$TEZ_CLASSPATH:$HADOOP_CLASSPATH
}

##
# executes a given command, and stores output in given
# execute_cmd(cmd, outputFile, boolean silent(default: true))
# Returns exit code from eval statement
#
# Result variables
#  EXEC_EXIT_CODE
#  EXEC_TIMED_RUN_START
#  EXEC_TIMED_RUN_STOP
#  EXEC_TIMED_RUN_TIME
##
function hive_setup_exec_cmd {
    declare cmd=$1
    declare out_file=$2
    declare silent=$3
    declare combine=${4:-true}

    declare silent_opts=">> $out_file 2>&1"
    declare combined_out_file="$(dirname $out_file)/out-all.txt"
    declare combine_out_opts="2>&1 | tee -a $combined_out_file"

    EXEC_EXIT_CODE=0

    echo "Output file: $out_file" >> $out_file

    if [ $combine = true ]; then
      cmd+=" $combine_out_opts"
    fi 

    [ $silent = true ] && cmd+=" $silent_opts" || cmd+=""

    cmd="set -o pipefail; $cmd"

    echo "$cmd" >> $out_file

    EXEC_TIMED_RUN_TIME=0
    EXEC_TIMED_RUN_START=$(date -u +%s%3N)
    eval "$cmd"
    EXEC_EXIT_CODE=$?
    EXEC_TIMED_RUN_STOP=$(date -u +%s%3N)
    elapsed_raw=$((EXEC_TIMED_RUN_STOP-$EXEC_TIMED_RUN_START))
    EXEC_TIMED_RUN_TIME="$((elapsed_raw / 1000)).$((elapsed_raw % 1000))"

    return $EXEC_EXIT_CODE
}

##
# Times a given command, calls hive_setup_exec_cmd
# execute_cmd_timed(cmd, outputFile, boolean silent(default: true))
# Returns exit code EXEC_EXIT_CODE from hive_setup_exec_cmd
#
# Result variables
#  EXEC_EXIT_CODE
#  EXEC_TIMED_RUN_START
#  EXEC_TIMED_RUN_STOP
#  EXEC_TIMED_RUN_TIME
##
function hive_setup_exec_cmd_timed {
    declare cmd=$1
    declare out_file=$2
    declare silent=$3
    declare combine=${4:-true}

    hive_setup_exec_cmd "$cmd" $out_file $silent $combine
    
    return $EXEC_EXIT_CODE
}

#
# Local functions
#

function hive_setup_update_hadoop_opts {
    declare log_dir=$1
    declare local_mode=$2
    declare am_process=$3

    tez_setup_update_yarn_opts $local_mode

    if [[ $local_mode = true ]]; then
        if [[ $am_process = true ]]; then
            am_mode="local-process"
        else
            am_mode="local-thread"
            export HADOOP_OPTS="$HADOOP_OPTS -Dmr3.root.logger=INFO,file,console"
        fi
    else
        if [[ $am_process = true ]]; then
            am_mode="local-process"
        else
            am_mode="yarn"
        fi
    fi

    mr3_setup_update_yarn_opts $local_mode $log_dir $am_mode

    #Hive does not use $YARN_OPTS, we need $HADOOP_OPTS instead
    export HADOOP_OPTS="$HADOOP_OPTS $YARN_OPTS"
}

function hive_setup_metastore_update_hadoop_opts {
   export HADOOP_OPTS="$HADOOP_OPTS \
-Dhive.database.host=$HIVE_DATABASE_HOST \
-Dhive.metastore.host=$HIVE_METASTORE_HOST \
-Dhive.metastore.port=$HIVE_METASTORE_PORT \
-Dhive.database.name=$HIVE_DATABASE_NAME \
-Dhive.local.data=$HIVE_LOCAL_DATA \
-Dhive.warehouse.dir=$HIVE_WAREHOUSE_DIR \
-Dhive.scratch.dir=$HIVE_SCRATCH_DIR \
-Dhive.base.out.dir=$HIVE_BASE_OUT_DIR \
-Dhive.secure.mode=$SECURE_MODE \
-Dhive.metastore.keytab.file=$HIVE_METASTORE_KERBEROS_KEYTAB \
-Dhive.metastore.principal=$HIVE_METASTORE_KERBEROS_PRINCIPAL \
$YARN_OPTS"

    if [[ $SECURE_MODE = true ]]; then
        export HADOOP_OPTS="$HADOOP_OPTS -Dhadoop.login=hybrid"
    fi
}

