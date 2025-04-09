import * as env from '../../env';
import { strict as assert } from 'assert';

export function build(env: env.T) {
  return {
    apiVersion: "rbac.authorization.k8s.io/v1",
    kind: "ClusterRole",
    metadata: {
      name: "cluster-autoscaler",
      labels: {
        ['k8s-addon']: "cluster-autoscaler.addons.k8s.io",
        ['k8s-app']: "cluster-autoscaler"
      }
    },
    rules: [
      { apiGroups: [""],
        resources: ["events", "endpoints"],
        verbs: ["create", "patch"] },
      { apiGroups: [""],
        resources: ["pods/eviction"],
        verbs: ["create"] },
      { apiGroups: [""],
        resources: ["pods/status"],
        verbs: ["update"] },
      { apiGroups: [""],
        resources: ["endpoints"],
        resourceNames: ["cluster-autoscaler"],
        verbs: ["get", "update"] },
      { apiGroups: [""],
        resources: ["nodes"],
        verbs: ["watch", "list", "get", "update"] },
      { apiGroups: [""],
        resources: [
          "namespaces",
          "pods",
          "services",
          "replicationcontrollers",
          "persistentvolumeclaims",
          "persistentvolumes" 
        ],
        verbs: ["watch", "list", "get"] },
      { apiGroups: ["extensions"],
        resources: ["replicasets", "daemonsets"],
        verbs: ["watch", "list", "get"] },
      { apiGroups: ["policy"],
        resources: ["poddisruptionbudgets"],
        verbs: ["watch", "list"] },
      { apiGroups: ["apps"],
        resources: ["statefulsets", "replicasets", "daemonsets"],
        verbs: ["watch", "list", "get"] },
      { apiGroups: ["storage.k8s.io"],
        resources: ["storageclasses", "csinodes", "csidrivers", "csistoragecapacities"],
        verbs: ["watch", "list", "get"] },
      { apiGroups: ["batch", "extensions"],
        resources: ["jobs"],
        verbs: ["get", "list", "watch", "patch"] },
      { apiGroups: ["coordination.k8s.io"],
        resources: ["leases"],
        verbs: ["create"] },
      { apiGroups: ["coordination.k8s.io"],
        resourceNames: ["cluster-autoscaler"],
        resources: ["leases"],
        verbs: ["get", "update"] }
    ]
  };
}
