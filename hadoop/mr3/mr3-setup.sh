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

function mr3_setup_print_usage_amprocess {
    echo " --amprocess                    Run the MR3 DAGAppMaster in LocalProcess mode"
}

function mr3_setup_init {
    MR3_LIB_DIR=$MR3_BASE_DIR/mr3lib
    MR3_CLASSPATH=$MR3_LIB_DIR/*

    MR3_HDFS_LIB_DIR=$HDFS_LIB_DIR/mr3

    MR3_CORE_JAR=mr3-core-$MR3_REV.jar
    MR3_TEZ_JAR=mr3-tez-$MR3_REV.jar
    MR3_TEZ_ASSEMBLY_JAR=mr3-tez-$MR3_REV-assembly.jar

    # okay to use even when using LOG4J version 1 because it uses -Dlog4j.configuration, not -Dlog4j.configurationFile
    export YARN_CLIENT_OPTS="$YARN_CLIENT_OPTS -Dlog4j.configurationFile=mr3-container-log4j2.properties"
}

function mr3_setup_update_yarn_opts {
    local_mode=$1
    log_dir=$2
    am_mode=$3

    if [[ $local_mode = false ]]; then
        MR3_LIBURIS_OPTS="-Dliburis=$TEZ_HDFS_LIB_DIR/tar/tez-$TEZ_REV.tar.gz"
        MR3_AUXURIS_OPTS="-Dauxuris=$MR3_HDFS_LIB_DIR/$MR3_TEZ_ASSEMBLY_JAR"
        MR3_ADD_CLASSPATH_JAVA_HOME_OPTS="-Djavahome=$MR3_JAVA_HOME"

        export YARN_OPTS="$YARN_OPTS $MR3_LIBURIS_OPTS $MR3_AUXURIS_OPTS $MR3_ADD_CLASSPATH_JAVA_HOME_OPTS"

        # TEZ_USE_MINIMAL
        # Specifies whether classes are imported from YarnConfiguration.YARN_APPLICATION_CLASSPATH
        # If set to true, the user should ensure the compatibility between Tez-MR3 and classes imported from
        # YarnConfiguration.YARN_APPLICATION_CLASSPATH.
        #
        # Set to false on vanilla Hadoop clusters and HDP
        # Set to true on CDH and Amazon EMR
        #
        TEZ_USE_MINIMAL=false
        export YARN_OPTS="$YARN_OPTS -Dtez.use.minimal=$TEZ_USE_MINIMAL"

        # token renewal
        if [[ $TOKEN_RENEWAL_HDFS_ENABLED = "true" ]]; then
            MR3_TOKEN_OPTS="-Dmr3.principal=$USER_PRINCIPAL -Dmr3.keytab=$USER_KEYTAB -Dmr3.token.renewal.hdfs.enabled=true"
            if [[ $TOKEN_RENEWAL_HIVE_ENABLED = "true" ]]; then
                MR3_TOKEN_OPTS="$MR3_TOKEN_OPTS -Dmr3.token.renewal.hive.enabled=true"
            fi
        fi
        export YARN_OPTS="$YARN_OPTS $MR3_TOKEN_OPTS"
    fi

    export YARN_OPTS="$YARN_OPTS -Dmr3.am.heapsize=$MR3_AM_HEAPSIZE"

    # -Dmr3.XXX=YYY directly adds (mr3.XXX -> YYY) to MR3Conf
    MR3_LOG_OPTS="-Dmr3.am.local.log-dir=$log_dir -Dyarn.app.container.log.dir=$log_dir -Dmr3.am.log.level=$LOG_LEVEL -Dmr3.container.log.level=$LOG_LEVEL"
    export YARN_OPTS="$YARN_OPTS $MR3_LOG_OPTS"

    # AMProcesss mode
    if [[ $am_mode = "local-process" ]]; then
        MR3_AM_MODE_CLASSPATH="-Dmr3.master.mode=local-process -Damprocess.classpath=$MR3_LIB_DIR/$MR3_TEZ_ASSEMBLY_JAR:$TEZ_LIB_DIR/*:$TEZ_LIB_DIR/lib/*"
    else
        MR3_AM_MODE_CLASSPATH="-Damprocess.classpath="
    fi
    export YARN_OPTS="$YARN_OPTS $MR3_AM_MODE_CLASSPATH"
}

