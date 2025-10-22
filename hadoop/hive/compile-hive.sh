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
BASE_DIR="$(readlink -f $DIR/..)"
source $BASE_DIR/env.sh
source $BASE_DIR/common-setup.sh
source $TEZ_BASE_DIR/tez-setup.sh
source $MR3_BASE_DIR/mr3-setup.sh
source $HIVE_BASE_DIR/hive-setup.sh

function compile_hive_print_usage {
    echo "Usage: compile-hive.sh [options(s)]"
    echo " -h/--help                              Print the usage."
    echo " -p <package name>                      Specify a package to compile."
    echo " --run-tests                            Run unit tests."
    echo " <mvn option>                           Add a Maven option; may be repeated at the end."
    echo ""
    echo "Example: ./compile-hive.sh -pl ql -pl common"
    echo ""
}

function compile_hive_parse_args {
    CLEAN=true
    RUN_TESTS=false

    while [ -n "$1" ]; do
      case "$1" in
        -h|--help)
            compile_hive_print_usage
            exit 0
            ;;
        -p)
            CLEAN=false
            BUILD_PACKAGES="$BUILD_PACKAGES $2"
            shift 2
            ;;
        --run-tests)
            RUN_TESTS=true
            shift
            ;;
        *)
            HIVE_MVN_OPTS=$@
            break
            ;;
      esac
    done
}

function compile_hive_main {
    compile_hive_parse_args $@

    # setup environment variables, e.g. HIVE_HOME, PATH
    common_setup_init
    tez_setup_init
    mr3_setup_init
    hive_setup_init

    echo -e "\n# Compiling Hive-MR3 ($(basename $HIVE_SRC), $HIVE_REV) #" >&2

    COMPILE_OUT_FILE=$LOG_BASE_DIR/compile-hive.log
    rm -rf $COMPILE_OUT_FILE

    # use mvn to install mr3 core/tez jars to mvn local repo
    mr3_core_mvn_install
    mr3_tez_mvn_install

    pushd $HIVE_SRC/storage-api
    mvn clean install -DskipTests >> $COMPILE_OUT_FILE
    if [ $? -ne 0 ]; then echo "Failed to compile hive/storage-api, $COMPILE_OUT_FILE"; exit 1; fi
    popd > /dev/null

    # add 'clean' for mvn
    pushd $HIVE_SRC > /dev/null
    if [[ $CLEAN = true ]]; then
        cmd="mvn clean"
    else
        cmd="mvn"
    fi
    # default options for mvn
    cmd="$cmd install -Dmaven.javadoc.skip=true -Pdist -Dtez.version=$TEZ_REV"
    # add package options for mvn
    if [[ ! -z $BUILD_PACKAGES ]]; then
        for package in $BUILD_PACKAGES; do
            cmd="$cmd -pl $package"
        done
    fi
    # skip testing while compiling
    if [[ $RUN_TESTS = false ]]; then
        cmd="$cmd -DskipTests"
    fi

    # execute the command
    eval "$cmd" 2>&1 | tee -a $COMPILE_OUT_FILE
    echo -e "\nCommand: $cmd \n"
    popd > /dev/null

    if [[ $(grep -c "BUILD FAILURE" $COMPILE_OUT_FILE) -gt 0 ]]; then
        cat $COMPILE_OUT_FILE >&2
        echo -e "\nCompilation failed" >&2
        exit 1
    fi

    pushd $HIVE_SRC/itests
    mvn clean install -DskipTests=true -DskipSparkTests=true >> $COMPILE_OUT_FILE
    if [ $? -ne 0 ]; then echo "Failed to compile hive/itests, $COMPILE_OUT_FILE"; exit 1; fi
    popd > /dev/null

    if [ -n "$HIVE_SRC" ] && [ "${BUILD_PACKAGES+defined}" ]; then
        for package in $BUILD_PACKAGES; do
            # In order to support speed up the overhead from build -> test,
            # we put the hive-exec.jar into the hive dist jar folder
            declare built_jars=$HIVE_SRC/$package/target/hive-*.jar
            declare list_glob=($built_jars)
            echo "Copy $built_jars to $HIVE_JARS:"
            rsync -a $built_jars $HIVE_JARS
        done
    fi

    rm -rf $HIVE_HOME
    mkdir -p $HIVE_HOME
    cp -r $HIVE_SRC/packaging/target/apache-hive-$HIVE_REV-bin/apache-hive-$HIVE_REV-bin/* $HIVE_HOME

    if [[ $HIVE_REV == 4* ]]; then
      if ls $HIVE_HOME/lib/calcite* 1> /dev/null 2>&1; then
        echo "WARNING: for Hive 4, Calcite jars should not be produced -- retry with a different version of mvn (ex. 3.6.0)"
        ls $HIVE_HOME/lib/calcite*
      fi
    fi

    echo -e "\nCompilation succeeded" >&2
}

compile_hive_main $@
