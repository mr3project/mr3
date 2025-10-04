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
BASE_DIR=$(readlink -f $DIR)
YAML_DIR=$BASE_DIR/yaml

source $BASE_DIR/config-run.sh
source $BASE_DIR/env.sh

run_kubernetes_parse_args $@

# run as the user who has set up ~/.kube/config

# Namespace
kubectl create namespace $MR3_NAMESPACE

# env-secret and ConfigMaps
kubectl create -n $MR3_NAMESPACE secret generic env-secret --from-file=$BASE_DIR/env.sh
kubectl create -n $MR3_NAMESPACE configmap hivemr3-timeline-conf-configmap --from-file=$BASE_DIR/timeline-conf/

kubectl create -n $MR3_NAMESPACE configmap client-timeline-config

kubectl create -f $YAML_DIR/timeline.yaml
kubectl create -f $YAML_DIR/timeline-service.yaml
