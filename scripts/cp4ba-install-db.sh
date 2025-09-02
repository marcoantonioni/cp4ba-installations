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
  exit 1
fi

source ${_CFG}

resourceExist () {
#    echo "namespace name: $1"
#    echo "resource type: $2"
#    echo "resource name: $3"
  if [ $(oc get $2 -n $1 $3 2> /dev/null | grep $3 | wc -l) -lt 1 ];
  then
      return 0
  fi
  return 1
}


_deployDBCluster () {

if [[ ! -z "$1" ]] && [[ ! -z "$2" ]]; then

resourceExist $2 cluster $1
if [ $? -eq 1 ]; then
  oc delete cluster -n $2 $1 2>/dev/null 1>/dev/null
fi

cat <<EOF | oc create -f -
apiVersion: postgresql.k8s.enterprisedb.io/v1
kind: Cluster
metadata:
  name: $1
  namespace: $2
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

else
  echo -e "${_CLR_RED}[✗] ERROR: _deployDBCluster name or namespace empty${_CLR_NC}"
  exit 1
fi
}

deployDBCluster() {
# $1: inst db
# $2: CR name
# $3: namespace
  if [[ "$1" = "true" ]]; then
    echo -e "${_CLR_GREEN}Deploying DB Cluster '${_CLR_YELLOW}$2${_CLR_GREEN}' in '${_CLR_YELLOW}$3${_CLR_GREEN}' namespace${_CLR_NC}"
    _deployDBCluster "$2" "$3"
  else
    echo -e "${_CLR_YELLOW}Skipping deployment of DB Cluster '${_CLR_GREEN}$1${_CLR_YELLOW}'${_CLR_NC}"
  fi
}

waitForClustersPostgresCRD () {
  echo "Wait for CR and Operator of 'clusters.postgresql.k8s.enterprisedb.io' (may take minutes)"

  if [ $(oc get crd clusters.postgresql.k8s.enterprisedb.io --no-headers 2> /dev/null | wc -l) -lt 1 ]; then
    while [ true ]
    do
      if [ $(oc get crd clusters.postgresql.k8s.enterprisedb.io --no-headers 2> /dev/null | wc -l) -lt 1 ]; then
        sleep 5
      else
        break
      fi
    done
  fi

  _READY_ITEMS=$(oc get crd clusters.postgresql.k8s.enterprisedb.io -o jsonpath='{.status.conditions}' | jq '.[] | select(.status=="True") ' | jq .status | wc -l)
  if [ $_READY_ITEMS -lt 2 ]; then
    while [ true ]
    do
      _READY_ITEMS=$(oc get crd clusters.postgresql.k8s.enterprisedb.io -o jsonpath='{.status.conditions}' | jq '.[] | select(.status=="True") ' | jq .status | wc -l)
      if [ $_READY_ITEMS -lt 2 ]; then
        sleep 5
        #echo -e -n "wait for CRD 'clusters.postgresql.k8s.enterprisedb.io' ready ... \033[0K\r"
      else
        break
      fi
    done
    #echo ""
  fi

  #echo "wait for pod postgresql-operator-controller-manager created"
  _PSQL_OCM_POD=$(oc get pod --no-headers -n ${CP4BA_INST_SUPPORT_NAMESPACE} 2>/dev/null | grep postgresql-operator-controller-manager | awk '{print $1}')
  if [[ -z "${_PSQL_OCM_POD}" ]]; then
    while [ true ]
    do
      sleep 5
      _PSQL_OCM_POD=$(oc get pod --no-headers -n ${CP4BA_INST_SUPPORT_NAMESPACE} 2>/dev/null | grep postgresql-operator-controller-manager | awk '{print $1}')
      if [[ ! -z "${_PSQL_OCM_POD}" ]]; then
        break
      fi
    done
  fi

  #echo "wait for pod postgresql-operator-controller-manager ready"
  _MAX_WAIT_READY=60000
  _RES=$(oc wait -n ${CP4BA_INST_SUPPORT_NAMESPACE} pod/${_PSQL_OCM_POD} --for condition=Ready --timeout="${_MAX_WAIT_READY}"s 2>/dev/null)
  _IS_READY=$(echo $_RES | grep "condition met" | wc -l)
  if [ $_IS_READY -eq 0 ]; then
    echo -e "${_CLR_RED}[✗] ERROR: waitForClustersPostgresCRD pod 'postgresql-operator-controller-manager' not ready in ${_MAX_WAIT_READY}, cannot deploy database${_CLR_NC}"
    exit 1
  fi
  #echo "pod 'postgresql-operator-controller-manager' is ready"
}

deployDBClusters() {
# $1: namespace

  waitForClustersPostgresCRD

  i=1
  _IDX_END=$CP4BA_INST_DB_INSTANCES
  while [[ $i -le $_IDX_END ]]
  do
    _INST_DB_CR_NAME="CP4BA_INST_DB_"$i"_CR_NAME"
    if [[ ! -z "${!_INST_DB_CR_NAME}" ]]; then
      deployDBCluster ${CP4BA_INST_DB} ${!_INST_DB_CR_NAME} $1
    else
      echo -e "${_CLR_RED}ERROR, env var '${_CLR_GREEN}${_INST_DB_CR_NAME}${_CLR_RED}' not defined, verify CP4BA_INST_DB_INSTANCES and CP4BA_INST_DB_* values.${_CLR_NC}"
    fi
    ((i = i + 1))
  done  
}

#==================================

echo -e "=============================================================="
echo -e "${_CLR_GREEN}Deploying '${_CLR_YELLOW}${CP4BA_INST_DB_INSTANCES}${_CLR_GREEN}' DB Clusters in '${_CLR_YELLOW}${CP4BA_INST_SUPPORT_NAMESPACE}${_CLR_GREEN}' namespace${_CLR_NC}"

deployDBClusters ${CP4BA_INST_SUPPORT_NAMESPACE}

# test if operator present in ns when different namespaces
if [[ "${CP4BA_INST_SUPPORT_NAMESPACE}" != "${CP4BA_INST_NAMESPACE}" ]]; then
  if [ $(oc get -n ${CP4BA_INST_SUPPORT_NAMESPACE} csv --no-headers | grep "cloud-native-postgresql.v" | wc -l) -lt 1 ]; then
    echo -e "${_CLR_GREEN}Remember to install 'EDB Postgres for Kubernetes' operator in '${_CLR_YELLOW}${CP4BA_INST_SUPPORT_NAMESPACE}${_CLR_GREEN}' namespace${_CLR_NC}"
  fi
fi
