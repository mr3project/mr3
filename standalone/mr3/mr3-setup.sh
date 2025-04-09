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

function mr3_setup_init {
    MR3_LIB_DIR=$MR3_BASE_DIR/mr3lib
    MR3_CLASSPATH=$MR3_LIB_DIR/*
}

function mr3_setup_update_hadoop_opts {
    local_mode=$1

    export HADOOP_OPTS="$HADOOP_OPTS -Dmr3.master.mode=$local_mode"

    # include mr3lib first because of some classes overriden in Tez (e.g., TezCounters)
    MR3_ADD_CLASSPATH_OPTS="-Dmr3.cluster.additional.classpath=$MR3_LIB_DIR/*:$HIVE_JARS/*:$TEZ_CLASSPATH"
    export HADOOP_OPTS="$HADOOP_OPTS $MR3_ADD_CLASSPATH_OPTS" 

    if [[ $TOKEN_RENEWAL_HDFS_ENABLED = "true" ]] || [[ $TOKEN_RENEWAL_HIVE_ENABLED = "true" ]]; then
        export HADOOP_OPTS="$HADOOP_OPTS -Dmr3.principal=$USER_PRINCIPAL -Dmr3.keytab=$USER_KEYTAB"
    fi
    if [[ $TOKEN_RENEWAL_HDFS_ENABLED = "true" ]]; then
        export HADOOP_OPTS="$HADOOP_OPTS -Dmr3.token.renewal.hdfs.enabled=true"
    fi
    if [[ $TOKEN_RENEWAL_HIVE_ENABLED = "true" ]]; then
        export HADOOP_OPTS="$HADOOP_OPTS -Dmr3.token.renewal.hive.enabled=true"
    fi

    export HADOOP_OPTS="$HADOOP_OPTS -Dmr3.am.heapsize=$MR3_AM_HEAPSIZE"

    # -Dmr3.XXX=YYY directly adds (mr3.XXX -> YYY) to MR3Conf
    # Thus, mr3-setup.sh always sets mr3.am.log.level and mr3.container.log.level 
    MR3_LOG_OPTS="-Dmr3.am.log.level=$LOG_LEVEL -Dmr3.container.log.level=$LOG_LEVEL"
    export HADOOP_OPTS="$HADOOP_OPTS $MR3_LOG_OPTS"

    export HADOOP_OPTS="$HADOOP_OPTS \
-Dbase.conf.dir=$CONF_DIR_MOUNT_DIR \
-Dbase.key.dir=$KEYTAB_MOUNT_DIR \
-Dbase.out.dir=$BASE_OUT"
}

