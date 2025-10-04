MR3
===

MR3 is a new execution engine for Hadoop and Kubernetes. Similar in spirit to
MapReduce and Tez, it is a new execution engine with simpler design, better
performance, and more features. MR3 serves as a framework for running jobs on
Hadoop and Kubernetes. MR3 also supports standalone mode which does not require
a resource manager such as Hadoop or Kubernetes.

The main application of MR3 is Hive on MR3. With MR3 as the execution engine,
the user can run Apache Hive not only on Hadoop but also directly on Kubernetes.
By exploiting standalone mode supported by MR3, the user can run Apache Hive
virtually in any type of cluster regardless of the availability of Hadoop or
Kubernetes and the version of Java installed in the system.

MR3 is implemented in Scala.

For the full documentation on MR3, please visit:

  https://mr3docs.datamonad.com/

* [MR3 Slack](https://join.slack.com/t/mr3-help/shared_invite/zt-1wpqztk35-AN8JRDznTkvxFIjtvhmiNg)
* [MR3 Google Group](https://groups.google.com/g/hive-mr3)

MR3 release
===========

This is the git repository for the MR3 release.

Installing binary files
=======================
In order to install binary files of Hive on MR3, execute install.sh, e.g.:

  ./install.sh https://github.com/mr3project/mr3/releases/download/v2.1/hive4-mr3-2.1.tar.gz

Please see LICENSE-MR3.txt for the license of the binary files.

Local mode
==========
Scripts for running Hive on MR3 in local mode

  /hadoop - Executable scripts (with --local option)

For instructions, visit:

  https://mr3docs.datamonad.com/docs/quick/local/

On Hadoop
=========
Scripts for running Hive on MR3 on Hadoop

  /hadoop - Executable scripts (with --tpcds option)

For instructions, visit:

  https://mr3docs.datamonad.com/docs/quick/hadoop/

Standalone mode
===============
Scripts for running Hive on MR3 in standalone mode

  /standalone - Executable scripts

For instructions, visit:

  https://mr3docs.datamonad.com/docs/quick/standalone/

On Kubernetes - Shell Scripts
=============================
Shell scripts for running Hive on MR3 on Kubernetes

  /kubernetes - Executable scripts with YAML files

For instructions, visit:

  https://mr3docs.datamonad.com/docs/quick/k8s/

On Kubernetes - Helm
====================
Helm charts for running Hive on MR3 on Kubernetes

  /helm - Helm charts

For instructions, visit:

  https://mr3docs.datamonad.com/docs/quick/k8s/

On Amazon EKS with Autoscaling
==============================
Additional steps for running Hive on MR3 on Amazon EKS

  /eks

For instructions, visit:

  https://mr3docs.datamonad.com/docs/quick/aws-eks

