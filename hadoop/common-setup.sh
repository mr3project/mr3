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

# only for 'source'
HADOOP_BASE_DIR=$BASE_DIR/hadoop
TEZ_BASE_DIR=$BASE_DIR/tez
MR3_BASE_DIR=$BASE_DIR/mr3
HIVE_BASE_DIR=$BASE_DIR/hive
LOG_BASE_DIR=$BASE_DIR/log

function common_setup_print_usage_common_options {
    echo " -h/--help                      Print the usage."    
}

function common_setup_print_usage_conf_mode {
    echo " --local                        Run jobs with configurations in conf/local/ (default)"
    echo " --tpcds                        Run jobs with configurations in conf/tpcds/"
}

function common_setup_init {
    mkdir -p $LOG_BASE_DIR 2> /dev/null
}

# get the current time
# optionally takes a time in seconds from epoch and returns a formatted time
function common_setup_get_time {
    declare epoch_time=$1

    #[[ $epoch_time = "???" ]] && echo "???" ||
    date +"%Y-%m-%d-%H-%M-%S" ${epoch_time:+"-d @$epoch_time"}
}

function common_setup_kill_sleep {
    ps fjx | grep sleep | awk '$1==1 {print $0}' | awk '$10=="sleep" {print $0}' | awk '{print $2}' | while read pid; do kill -9 $pid; done
}

# logging/output utilities
function common_setup_output_header {
    echo -e "Job Status, Error Status, Hostname, Start Time, Runtime (seconds), Job Name, Run Number, Directory"
}

function common_setup_log {
    declare function_name=$1
    declare message=$2
    declare script_name="$(basename "$0")"

    echo -e "$script_name:$function_name() $message"
}

# prints a WARNING message 
#
# $1, calling Function (access func stack: ${FUNCNAME[0]})
# $2, Message to print
#
# Example: error "Strange stuff happened" print_usage
#
function common_setup_log_warning {
   declare function_name=$1 #${FUNCNAME[1]} for prev. function
   declare message=$2

   common_setup_log $function_name "WARNING: $message"
}

# Prints an ERROR message 
#
# $1, calling Function (access func stack: ${FUNCNAME[0]})
# $2, Message to print
#
function common_setup_log_error {
    declare function_name=$1 #${FUNCNAME[1]} for prev. function
    declare message=$2

    common_setup_log $function_name "ERROR: $message"
}

