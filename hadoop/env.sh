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
# Local directories should be located on the machine where Hive on MR3 is installed.
#

#
# Step 1. JAVA_HOME and PATH
#

# Set JAVA_HOME if not set yet
#
#export JAVA_HOME=/usr/lib/java17/
#export PATH=$JAVA_HOME/bin:$PATH

# In order to start Metastore and HiveServer2 with Java 17,
# update JAVA_HOME in hadoop-env.sh (such as /etc/hadoop/conf/hadoop-env.sh)

# JAVA_HOME for executing MR3 DAGAppMaster and ContainerWorkers
# Used to update mr3.am.launch.env and mr3.container.launch.env in mr3-site.xml
MR3_JAVA_HOME=/usr/lib/java17/

#
# Step 2. Local directories for Hadoop
#

# Hadoop home directory in non-local mode
export HADOOP_HOME=${HADOOP_HOME:-/usr/lib/hadoop}
# Hadoop native library paths in non-local mode
HADOOP_NATIVE_LIB=$HADOOP_HOME/lib/native

# Hadoop home directory used for running Hive on MR3 in local mode 
STANDALONE_BASE_DIR=$BASE_DIR/../standalone
HADOOP_HOME_LOCAL=$STANDALONE_BASE_DIR/hadoop/apache-hadoop

# Do not set HADOOP_COMMON_HOME, HADOOP_HDFS_HOME, HADOOP_MAPRED_HOME, HADOOP_YARN_HOME

# fs.defaultFS is determined by HADOOP_HOME or HADOOP_LOCAL_HOME.
# Hence setting fs.defaultFS in hive-site.xml/tez-site.xml/mr3-site.xml has no effect.

# To prevent apache-hive-*-bin/bin/hive from including paths for HBase,
#  - do not set HBASE_BIN
#  - do not include hbase in the path

#
# Step 3. Java options and heap size
#

# HIVE_MR3_JVM_OPTION = JVM options for Metastore and HiveServer2
HIVE_MR3_JVM_OPTION="-XX:+UseG1GC -XX:+UseNUMA -Djava.net.preferIPv4Stack=true"
HIVE_MR3_JVM_OPTION="$HIVE_MR3_JVM_OPTION --add-opens java.base/java.lang=ALL-UNNAMED --add-opens java.base/java.net=ALL-UNNAMED --add-opens java.base/java.util=ALL-UNNAMED --add-opens java.base/java.time=ALL-UNNAMED --add-opens java.base/java.io=ALL-UNNAMED --add-opens java.base/java.util.concurrent=ALL-UNNAMED --add-opens java.base/java.util.concurrent.atomic=ALL-UNNAMED --add-opens java.base/java.util.regex=ALL-UNNAMED --add-opens java.base/java.util.zip=ALL-UNNAMED --add-opens java.base/java.util.stream=ALL-UNNAMED --add-opens java.base/java.util.jar=ALL-UNNAMED --add-opens java.base/java.util.function=ALL-UNNAMED --add-opens java.logging/java.util.logging=ALL-UNNAMED --add-opens java.base/java.nio=ALL-UNNAMED --add-opens java.base/java.lang.reflect=ALL-UNNAMED --add-opens java.base/java.lang.ref=ALL-UNNAMED --add-opens java.base/java.nio.charset=ALL-UNNAMED --add-opens java.base/java.text=ALL-UNNAMED --add-opens java.base/java.util.concurrent.locks=ALL-UNNAMED --add-opens java.base/sun.util.calendar=ALL-UNNAMED"

# Heap size in MB for Metastore
HIVE_METASTORE_HEAPSIZE=32768

# Heap size in MB for HiveServer2
HIVE_SERVER2_HEAPSIZE=32768

# Heap size in MB for Beeline (run-beeline.sh) and HiveCLI (run-hive-cli.sh)
HIVE_CLIENT_HEAPSIZE=1024

# Heap size in MB for MR3 DAGAppMaster
# For non-local mode only
# Should be smaller than HIVE_SERVER2_HEAPSIZE in local-thread mode, i.e.,
#   when mr3.master.mode is set to local-thread in mr3-site.xml
# For local mode, see mr3.am.resource.memory.mb in conf/local/mr3-site.xml
MR3_AM_HEAPSIZE=32768

#
# Step 4. Directories for Metastore and HiveServer2
#

# HDFS directory where all MR3 jar files are copied
# For non-local mode only
HDFS_LIB_DIR=/user/$USER/lib

# HDFS directory for the Hive warehouse
# For non-local mode only
HIVE_WAREHOUSE_DIR=/user/hive/warehouse

# Scratch directory for HiveServer2
#  - local directory in local mode
#  - HDFS directory in non-local mode
# If the scratch directory already exists, it must have directory permission 733, not 700.
# If it does not exist, HiveServer2 automatically creates a new directory. 
# Creates a subdirectory:
#   /_resultscache_
HIVE_SCRATCH_DIR=/tmp/hive

# Local working directory for HiveServer2
# Creates three sub-directories:
#   /${hive.session.id}_resources
#   /scratch-dir
#   /operation_logs
HIVE_BASE_OUT_DIR=/tmp/hive

# Local working directory for MR3
# Used only for local-thread and local-process mode of MR3 DAGAppMaster
# Fixed in mr3-site.xml (mr3.am.local.working-dir):
#   /tmp/${user.name}/working-dir

#
# Step 5. Metastore
#

# HIVE_METASTORE_DB_TYPE = type of Metastore database (mysql, postgresql, mssql, derby)
#                          in non-local mode (for running 'schematool -initSchema')
# HIVE_DATABASE_HOST = host for Metastore database
# HIVE_METASTORE_HOST = host for Metastore itself
# HIVE_METASTORE_PORT = port for Hive Metastore in non-local mode
# HIVE_METASTORE_LOCAL_PORT= port for Hive Metastore in local mode
# HIVE_DATABASE_NAME = database name in Hive Metastore
#
HIVE_METASTORE_DB_TYPE=mysql
HIVE_DATABASE_HOST=$HOSTNAME
HIVE_METASTORE_HOST=$HOSTNAME
HIVE_METASTORE_PORT=9840
HIVE_METASTORE_LOCAL_PORT=9841
HIVE_DATABASE_NAME=hivemr3

# MySQL/PostgreSQL connector jar file when --tpcds is used in scripts
HIVE_MYSQL_DRIVER=/usr/share/java/mysql-connector-java.jar

#
# Step 6. HiveServer2
#

# HIVE_SERVER2_PORT = port for HiveServer2 (for both non-local mode and local mode)
#
HIVE_SERVER2_HOST=$HOSTNAME
HIVE_SERVER2_PORT=9842

# JDBC options for Beeline when connecting to HiveServer2
HIVE_SERVER2_JDBC_OPTS="ssl=false"

#
# Step 7. Security (optional)
#

# Specifies whether the cluster is secure with Kerberos or not 
SECURE_MODE=false

# For running MR3 and Hive-MR3 with SECURE_MODE=true
 
# For security in Metastore 
# Kerberos principal for Metastore; cf. 'hive.metastore.kerberos.principal' in hive-site.xml
HIVE_METASTORE_KERBEROS_PRINCIPAL=hive/_HOST@HADOOP
# Kerberos keytab for Metastore; cf. 'hive.metastore.kerberos.keytab.file' in hive-site.xml
HIVE_METASTORE_KERBEROS_KEYTAB=/etc/security/keytabs/hive.service.keytab

# For security in HiveServer2 
# Authentication option: NONE (uses plain SASL), NOSASL, KERBEROS, LDAP, PAM, and CUSTOM; cf. 'hive.server2.authentication' in hive-site.xml 
HIVE_SERVER2_AUTHENTICATION=NONE
# Kerberos principal for HiveServer2; cf. 'hive.server2.authentication.kerberos.principal' in hive-site.xml 
HIVE_SERVER2_KERBEROS_PRINCIPAL=hive/_HOST@HADOOP
# Kerberos keytab for HiveServer2; cf. 'hive.server2.authentication.kerberos.keytab' in hive-site.xml
HIVE_SERVER2_KERBEROS_KEYTAB=/home/hive/hive.keytab

# Specifies whether Hive token renewal is enabled inside DAGAppMaster and ContainerWorkers
TOKEN_RENEWAL_HIVE_ENABLED=false

#
# Reading from secure HDFS
#

# Kerberos principal for renewing HDFS/Hive tokens
USER_PRINCIPAL=hive@HADOOP
# Kerberos keytab
USER_KEYTAB=/home/hive/hive.keytab

# Specifies whether HDFS token renewal is enabled inside DAGAppMaster and ContainerWorkers
TOKEN_RENEWAL_HDFS_ENABLED=false

#
# Step 8. Logging
#

# Logging level 
LOG_LEVEL=INFO

#
# Step 9. MR3 version
#

# MR3 revision number
MR3_REV=2.0

# Tez-MR3 revision number
TEZ_REV=0.9.1.mr3.${MR3_REV}

# Hive-MR3 revision number
HIVE_REV=4.0.0

#
# Step 10. High availability (optional)
#

# In order to enable high availability, the user should export environment variable MR3_SHARED_SESSION_ID
# before executing hive/hiveserver2-service.sh. Then MR3_SHARED_SESSION_ID is shared by all HiveServer2
# instances. If MR3_SHARED_SESSION_ID is not set, each HiveServer2 instance creates its own MR3 session ID,
# thus never sharing a common MR3 session directory. (Still all HiveServer2 instances share a common MR3
# DAGAppMaster.)

#export MR3_SHARED_SESSION_ID=d7b52f74-7349-405c-88a2-d0d1cbb5a918

#
# Miscellaneous
#

# Unset because 'hive' command reads SPARK_HOME and may accidentally expand
# the classpath with HiveConf.class from Spark. 
unset SPARK_HOME

