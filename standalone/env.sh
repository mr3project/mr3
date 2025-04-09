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

#
# Basic settings
# 

CONF_DIR_MOUNT_DIR=$BASE_DIR/conf
KEYTAB_MOUNT_DIR=$BASE_DIR/key

#
# Step 1. JAVA_HOME and PATH
#

# Set JAVA_HOME if not set yet
#
#export JAVA_HOME=/usr/lib/java17/
#export PATH=$JAVA_HOME/bin:$PATH

#
# Step 2. Java options and heap size
#

# Cf. run-worker.sh sets JAVA_OPTS.

# HIVE_MR3_JVM_OPTION = JVM options for Metastore and HiveServer2
HIVE_MR3_JVM_OPTION="-XX:+UseG1GC -XX:+UseNUMA -Djava.net.preferIPv4Stack=true"
HIVE_MR3_JVM_OPTION="$HIVE_MR3_JVM_OPTION --add-opens java.base/java.lang=ALL-UNNAMED --add-opens java.base/java.net=ALL-UNNAMED --add-opens java.base/java.util=ALL-UNNAMED --add-opens java.base/java.time=ALL-UNNAMED --add-opens java.base/java.io=ALL-UNNAMED --add-opens java.base/java.util.concurrent=ALL-UNNAMED --add-opens java.base/java.util.concurrent.atomic=ALL-UNNAMED --add-opens java.base/java.util.regex=ALL-UNNAMED --add-opens java.base/java.util.zip=ALL-UNNAMED --add-opens java.base/java.util.stream=ALL-UNNAMED --add-opens java.base/java.util.jar=ALL-UNNAMED --add-opens java.base/java.util.function=ALL-UNNAMED --add-opens java.logging/java.util.logging=ALL-UNNAMED --add-opens java.base/java.nio=ALL-UNNAMED --add-opens java.base/java.lang.reflect=ALL-UNNAMED --add-opens java.base/java.lang.ref=ALL-UNNAMED --add-opens java.base/java.nio.charset=ALL-UNNAMED --add-opens java.base/java.text=ALL-UNNAMED --add-opens java.base/java.util.concurrent.locks=ALL-UNNAMED --add-opens java.base/sun.util.calendar=ALL-UNNAMED"

# Heap size in MB for Metastore
HIVE_METASTORE_HEAPSIZE=32768

# Heap size in MB for HiveServer2
HIVE_SERVER2_HEAPSIZE=32768

# Heap size in MB for Beeline (run-beeline.sh)
HIVE_CLIENT_HEAPSIZE=1024

# Heap size in MB for MR3 DAGAppMaster
MR3_AM_HEAPSIZE=32768

#
# Step 3. Directories for Metastore and HiveServer2
#

# Path to the Hive warehouse, e.g.,
#   s3a://hive-mr3-bucket/warehouse
#   hdfs://red0:8020/hivemr3/warehouse
HIVE_WAREHOUSE_DIR=s3a://hive-mr3-bucket/warehouse

# Path to the Hive scratch directory, e.g.,
#   s3a://hive-mr3-bucket/workdir
#   hdfs://red0:8020/hivemr3/workdir
# On HDFS, it must have directory permission 733, not 700.
# If it does not exist, HiveServer2 automatically creates a new directory. 
# Creates subdirectories:
#   /${user.name}
#   /_resultscache_
HIVE_SCRATCH_DIR=s3a://hive-mr3-bucket/workdir

# Local working directory for HiveServer2
# Creates three sub-directories:
#   /${hive.session.id}_resources
#   /scratch-dir
#   /operation_logs
HIVE_BASE_OUT_DIR=/tmp/hive

# Local working directory for FileSystem
# Fixed in core-site.xml (hadoop.tmp.dir):
#   /tmp/${user.name}
# Local working directory for MR3
# Fixed in mr3-site.xml (mr3.am.local.working-dir):
#   /tmp/${user.name}/working-dir

#
# Step 4. Metastore
#

# HIVE_METASTORE_DB_TYPE = type of Metastore database (mysql, postgresql, mssql, derby)
#                          (for running 'schematool -initSchema')
# HIVE_DATABASE_HOST = host for Metastore database
# HIVE_METASTORE_HOST = host for Metastore itself
# HIVE_METASTORE_PORT = port for Hive Metastore in non-local mode
# HIVE_DATABASE_NAME = database name in Hive Metastore
#
HIVE_METASTORE_DB_TYPE=mysql
HIVE_DATABASE_HOST=$HOSTNAME
HIVE_METASTORE_HOST=$HOSTNAME
HIVE_METASTORE_PORT=9840
HIVE_DATABASE_NAME=hivemr3

#
# Step 5. HiveServer2
#

# HIVE_SERVER2_PORT = thrift port for HiveServer2
# HIVE_SERVER2_HTTP_PORT = http port for HiveServer2
#
HIVE_SERVER2_HOST=$HOSTNAME
HIVE_SERVER2_PORT=9842
HIVE_SERVER2_HTTP_PORT=10001

#
# Step 6. Security (optional)
#

# Specifies hive.metastore.sasl.enabled 
METASTORE_SECURE_MODE=false

# For security in Metastore 
# Kerberos principal for Metastore; cf. 'hive.metastore.kerberos.principal' in hive-site.xml
HIVE_METASTORE_KERBEROS_PRINCIPAL=hive/red0@RED
# Kerberos keytab for Metastore; cf. 'hive.metastore.kerberos.keytab.file' in hive-site.xml
HIVE_METASTORE_KERBEROS_KEYTAB=$KEYTAB_MOUNT_DIR/hive-admin.keytab

# For security in HiveServer2 
# Beeline should also provide this Kerberos principal.
# Authentication option: NONE (uses plain SASL), NOSASL, KERBEROS, LDAP, PAM, and CUSTOM; cf. 'hive.server2.authentication' in hive-site.xml 
HIVE_SERVER2_AUTHENTICATION=NONE
# Kerberos principal for HiveServer2; cf. 'hive.server2.authentication.kerberos.principal' in hive-site.xml 
HIVE_SERVER2_KERBEROS_PRINCIPAL=hive/red0@RED
# Kerberos keytab for HiveServer2; cf. 'hive.server2.authentication.kerberos.keytab' in hive-site.xml 
HIVE_SERVER2_KERBEROS_KEYTAB=$KEYTAB_MOUNT_DIR/hive-admin.keytab

# Specifies whether Hive token renewal is enabled inside DAGAppMaster and ContainerWorkers
TOKEN_RENEWAL_HIVE_ENABLED=false

#
# Reading from secure HDFS
#

# 1) for renewing HDFS/Hive tokens in DAGAppMaster (mr3.keytab in mr3-site.xml)
# 2) for renewing HDFS/Hive tokens in ContainerWorker (mr3.k8s.keytab.mount.file in mr3-site.xml)

# Kerberos principal for renewing HDFS/Hive tokens (for mr3.principal)
USER_PRINCIPAL=hive@RED
# Kerberos keytab (for mr3.keytab)
USER_KEYTAB=$KEYTAB_MOUNT_DIR/hive.keytab
# for mr3.k8s.keytab.mount.file
KEYTAB_MOUNT_FILE=hive.keytab

# Specifies whether HDFS token renewal is enabled inside DAGAppMaster and ContainerWorkers
TOKEN_RENEWAL_HDFS_ENABLED=false

#
# Truststore for HiveServer2
#
HIVE_SERVER2_SSL_TRUSTSTORE=$KEYTAB_MOUNT_DIR/hivemr3-ssl-certificate.jks
HIVE_SERVER2_SSL_TRUSTSTORETYPE=jks
HIVE_SERVER2_SSL_TRUSTSTOREPASS=
export HADOOP_CREDSTORE_PASSWORD=

#
# Step 7. Logging
#

# Logging level 
LOG_LEVEL=INFO

#
# Step 8. Environment variables (directly read by MR3) for running ContainerWorkers
#

# Set to true to run ContainerWorkers in standalone mode
export PROCESS_CONTAINER_WORKER_ENABLED=true

# Required for setting up standalone mode
export PROCESS_CONTAINER_WORKER_SECRET=worker-secret
export PROCESS_CONTAINER_WORKER_SERVER_HOST=192.168.10.101

# Resources for ContainerWorker
export PROCESS_CONTAINER_WORKER_MEMORY_MB=73728
export PROCESS_CONTAINER_WORKER_CPU_CORES=12
export PROCESS_CONTAINER_WORKER_MEMORY_XMX=58982

# Local directories for ContainerWorker
export PROCESS_CONTAINER_WORKER_LOCAL_DIRS=/data1/k8s,/data2/k8s,/data3/k8s,/data4/k8s,/data5/k8s,/data6/k8s

#
# Step 9. Additional environment variables for HiveServer2 and Metastore
#
# Here the user can define additional environment variables using 'EXPORT', e.g.:
#   export FOO=bar
#

export AWS_ACCESS_KEY_ID=
export AWS_SECRET_ACCESS_KEY=
export AWS_REGION=

#
# Miscellaneous
#

# Unset because 'hive' command reads SPARK_HOME and may accidentally expand
# the classpath with HiveConf.class from Spark. 
unset SPARK_HOME

