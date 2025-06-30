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

function run_worker {
    hadoop_setup_init
    tez_setup_init
    mr3_setup_init
    hive_setup_init

    echo -e "\n# Running ContainerWorker: $@ #\n" >&2
    BASE_OUT=$HIVE_BASE_DIR/worker-result
    hive_setup_init_output_dir $BASE_OUT
    declare out_file="$OUT/out-worker.txt"

    # To change logging configuration:
    #  1. create a new configuration file (e.g., worker-container-log4j2.properties)
    #  2. extend CLASSPATH to include the file
    #  3. change -Dlog4j.configurationFile in JAVA_OPTS

    export HADOOP_HOME=$HADOOP_BASE_DIR/apache-hadoop

    export CLASSPATH=$HIVE_CONF_DIR:$MR3_CLASSPATH:$TEZ_CLASSPATH:$HIVE_JARS/*
    export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$HADOOP_HOME/lib/native:$BASE_DIR/lib/native

    echo -e "CLASSPATH=$CLASSPATH" >> $out_file
    echo -e "LD_LIBRARY_PATH=$LD_LIBRARY_PATH" >> $out_file

    JAVA=$JAVA_HOME/bin/java

    PROCESS_CONTAINER_WORKER_MEMORY_XMS=$PROCESS_CONTAINER_WORKER_MEMORY_XMX

    JAVA_OPTS="-XX:+AlwaysPreTouch -Xss512k -XX:+UseG1GC -XX:+UseNUMA -XX:InitiatingHeapOccupancyPercent=40 -XX:G1ReservePercent=20 -XX:MaxGCPauseMillis=200 -XX:MetaspaceSize=1024m -Djava.net.preferIPv4Stack=true"

    JAVA_OPTS="$JAVA_OPTS --add-opens java.base/java.lang=ALL-UNNAMED --add-opens java.base/java.net=ALL-UNNAMED --add-opens java.base/java.util=ALL-UNNAMED --add-opens java.base/java.time=ALL-UNNAMED --add-opens java.base/java.io=ALL-UNNAMED --add-opens java.base/java.util.concurrent=ALL-UNNAMED --add-opens java.base/java.util.concurrent.atomic=ALL-UNNAMED --add-opens java.base/java.util.regex=ALL-UNNAMED --add-opens java.base/java.util.zip=ALL-UNNAMED --add-opens java.base/java.util.stream=ALL-UNNAMED --add-opens java.base/java.util.jar=ALL-UNNAMED --add-opens java.base/java.util.function=ALL-UNNAMED --add-opens java.logging/java.util.logging=ALL-UNNAMED --add-opens java.base/java.nio=ALL-UNNAMED --add-opens java.base/java.lang.reflect=ALL-UNNAMED --add-opens java.base/java.lang.ref=ALL-UNNAMED --add-opens java.base/java.nio.charset=ALL-UNNAMED --add-opens java.base/java.text=ALL-UNNAMED --add-opens java.base/java.util.concurrent.locks=ALL-UNNAMED --add-opens java.base/sun.util.calendar=ALL-UNNAMED"

    JAVA_OPTS="\
-Xmx${PROCESS_CONTAINER_WORKER_MEMORY_XMX}m \
-Xms${PROCESS_CONTAINER_WORKER_MEMORY_XMS}m \
-Dlog4j.configurationFile=mr3-container-log4j2.properties \
-Dyarn.app.container.log.dir=$OUT \
$JAVA_OPTS"

    JAVA_OPTS="-Djavax.security.auth.useSubjectCredsOnly=false \
-Djava.security.auth.login.config=$CONF_DIR_MOUNT_DIR/jgss.conf \
-Djava.security.krb5.conf=$CONF_DIR_MOUNT_DIR/krb5.conf \
-Dsun.security.jgss.debug=true $JAVA_OPTS"

    JAVA_OPTS="-Dmr3.root.logger=$LOG_LEVEL $JAVA_OPTS"

    common_setup_cleanup 

    export JVM_PID="$$"
    exec "$JAVA" $JAVA_OPTS com.datamonad.mr3.worker.ContainerWorker _ 0 _ _ 0 false >> $out_file 2>&1

    exit_code=$?
    exit $exit_code
}

run_worker $@
