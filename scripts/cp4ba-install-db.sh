#!/bin/bash

_me=$(basename "$0")

_CFG=""

#--------------------------------------------------------
_CLR_RED="\033[0;31m"   #'0;31' is Red's ANSI color code
_CLR_GREEN="\033[0;32m"   #'0;32' is Green's ANSI color code
_CLR_YELLOW="\033[1;32m"   #'1;32' is Yellow's ANSI color code
_CLR_BLUE="\033[0;34m"   #'0;34' is Blue's ANSI color code
_CLR_NC="\033[0m"

#--------------------------------------------------------
# read command line params
while getopts c:s: flag
do
    case "${flag}" in
        c) _CFG=${OPTARG};;
    esac
done

if [[ -z "${_CFG}" ]]; then
  echo "usage: $_me -c path-of-config-file"
  exit
fi

source ${_CFG}

deployDBCluster () {

cat <<EOF | oc create -f -
apiVersion: postgresql.k8s.enterprisedb.io/v1
kind: Cluster
metadata:
  name: ${CP4BA_INST_DB_CR_NAME}
  namespace: ${CP4BA_INST_NAMESPACE}
spec:
  logLevel: info
  startDelay: 30
  stopDelay: 30
  resources:
    limits:
      cpu: "${CP4BA_INST_DB_LIMITS_CPU}"
      memory: "${CP4BA_INST_DB_LIMITS_MEMORY}"
    requests:
      cpu: "${CP4BA_INST_DB_REQS_CPU}"
      memory: "${CP4BA_INST_DB_REQS_MEMORY}"
  imageName: >-
    icr.io/cpopen/edb/postgresql:13.10-4.14.0@sha256:0064d1e77e2f7964d562c5538f0cb3a63058d55e6ff998eb361c03e0ef7a96dd
  enableSuperuserAccess: true
  bootstrap:
    initdb:
      database: ${CP4BA_INST_DB_FAKE}
      encoding: UTF8
      localeCType: C
      localeCollate: C
      owner: ${CP4BA_INST_DB_OWNER}
  postgresql:
    parameters:
      log_truncate_on_rotation: 'false'
      archive_mode: 'on'
      log_filename: postgres
      archive_timeout: 5min
      max_replication_slots: '32'
      log_rotation_size: '0'
      work_mem: 20MB
      shared_preload_libraries: ''
      logging_collector: 'on'
      wal_receiver_timeout: 5s
      log_directory: /controller/log
      log_destination: csvlog
      wal_sender_timeout: 5s
      max_worker_processes: '32'
      max_parallel_workers: '32'
      log_rotation_age: '0'
      shared_buffers: 512MB
      max_prepared_transactions: '100'
      shared_memory_type: mmap
      dynamic_shared_memory_type: posix
      wal_keep_size: 512MB
    pg_hba:
      - host all all 0.0.0.0/0 md5
    syncReplicaElectionConstraint:
      enabled: false
  minSyncReplicas: 0
  maxSyncReplicas: 0
  postgresGID: 26
  postgresUID: 26
  primaryUpdateMethod: switchover
  switchoverDelay: 40000000
  storage:
    resizeInUseVolumes: true
    size: "${CP4BA_INST_DB_STORAGE_SIZE}"
    storageClass: ${CP4BA_INST_SC_FILE}
  primaryUpdateStrategy: unsupervised
  instances: 1
EOF

}

#==================================

echo -e "=============================================================="
echo -e "${_CLR_GREEN}Deploying DB Cluster '${_CLR_YELLOW}${CP4BA_INST_DB_CR_NAME}${_CLR_GREEN}' in '${_CLR_YELLOW}${CP4BA_INST_SUPPORT_NAMESPACE}${_CLR_GREEN}' namespace${_CLR_NC}"
deployDBCluster
# test if operator present in ns when different namespaces
if [[ "${CP4BA_INST_SUPPORT_NAMESPACE}" != "${CP4BA_INST_NAMESPACE}" ]]; then
  if [ $(oc get -n ${CP4BA_INST_SUPPORT_NAMESPACE} csv --no-headers | grep "cloud-native-postgresql.v" | wc -l) -lt 1 ]; then
    echo -e "${_CLR_GREEN}Remember to install 'EDB Postgres for Kubernetes' operator in '${_CLR_YELLOW}${CP4BA_INST_SUPPORT_NAMESPACE}${_CLR_GREEN}' namespace${_CLR_NC}"
  fi
fi
