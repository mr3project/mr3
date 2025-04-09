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

MR3_LIB=$MR3_BASE_DIR/mr3lib

JAR=$MR3_LIB/mr3-tez-[0-9].*[0-9]-assembly.jar
CLASS=com.datamonad.mr3.client.control.MasterControlYarn

export HADOOP_CLASSPATH=$MR3_LIB/*:$HADOOP_CLASSPATH

HADOOP=$HADOOP_HOME/bin/hadoop
if [[ ! -f $HADOOP ]]; then
  echo "Cannot find a Hadoop installation: \$HADOOP_HOME must be set in env.sh";
  exit 1;
fi

# Hadoop jars are included in the classpath.
# Hadoop jars may include Protobuf 2 jar files.
# Hive 4 uses Protobuf 3.
# As a result, we may see:
#   Error: tried to access field com.google.protobuf.AbstractMessage.memoizedSize from class com.datamonad.mr3.client.DAGClientHandlerProtocolRPC$GetAllDagsRequestProto
# To avoid the conflict, remove Protobuf 2 jar files (e.g., protobuf-java-2.5.0.jar) in the classpath.

exec $HADOOP jar $JAR $CLASS "$@"
