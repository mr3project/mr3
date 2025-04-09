#!/bin/bash

# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

function hadoop_setup_init {
    export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
    export YARN_CONF_DIR=$HADOOP_CONF_DIR
    export HADOOP_CLASSPATH=$HADOOP_CONF_DIR:$HADOOP_CLASSPATH
    export PATH=$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$PATH
}

function hadoop_setup_update_conf_dir {
    conf_dir=$1

    # copy the original conf files from cluster
    cp -r $HADOOP_CONF_DIR/* $conf_dir 2> /dev/null
    cp -r $YARN_CONF_DIR/* $conf_dir 2> /dev/null

    rm -f $conf_dir/*.template
    rm -f $conf_dir/*.example
    rm -f $conf_dir/*.cmd

    export HADOOP_CONF_DIR=$conf_dir
    export YARN_CONF_DIR=$HADOOP_CONF_DIR
    export HADOOP_CLASSPATH=$HADOOP_CONF_DIR:$HADOOP_CLASSPATH
}

