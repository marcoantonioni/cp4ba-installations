#!/bin/bash

#set -euo pipefail

_me=$(basename "$0")

_CFG=""

#--------------------------------------------------------
_CLR_RED="\033[0;31m"   #'0;31' is Red's ANSI color code
_CLR_GREEN="\033[0;32m"   #'0;32' is Green's ANSI color code
_CLR_YELLOW="\033[1;33m"   #'1;32' is Yellow's ANSI color code
_CLR_BLUE="\033[0;34m"   #'0;34' is Blue's ANSI color code
_CLR_NC="\033[0m"


#--------------------------------------------------------
_INST_TMP_FOLDER="/tmp"
setTemporaryFolder () {
  _OK=0
  _ERR_MSG_FOLDER="is a folder"
  _ERR_MSG_PERMISSIONS=""
  if [[ ! -z "${CP4BA_INST_TMP_FOLDER}" ]]; then
    if [[ -d "${CP4BA_INST_TMP_FOLDER}" ]]; then
      if [[ -r "${CP4BA_INST_TMP_FOLDER}" ]] && [[ -w "${CP4BA_INST_TMP_FOLDER}" ]]; then 
        _OK=1
      else
        _ERR_MSG_PERMISSIONS=", you have not rights to read and/or write"
        _OK=-1
      fi
    else
      _ERR_MSG_FOLDER="is NOT a folder"
    fi

    if [[ $_OK -lt 1 ]]; then
      echo -e "${_CLR_RED}[✗] ERROR '${_CLR_YELLOW}${CP4BA_INST_TMP_FOLDER}${_CLR_RED}' is not a valid temporary folder, check if it is a folder or if you have write permissions !${_CLR_NC}"
      echo -e "${_CLR_RED}'${_CLR_YELLOW}${CP4BA_INST_TMP_FOLDER}${_CLR_RED}' ${_ERR_MSG_FOLDER}${_ERR_MSG_PERMISSIONS}${_CLR_NC}"
      exit 1
    fi
    export _INST_TMP_FOLDER="${CP4BA_INST_TMP_FOLDER}"
  fi
  log_info "${_CLR_GREEN}Running with temporary folder '${_CLR_YELLOW}${_INST_TMP_FOLDER}${_CLR_GREEN}'${_CLR_NC}"

}

#--------------------------------------------------------
# read command line params
while getopts c: flag
do
    case "${flag}" in
        c) _CFG=${OPTARG};;
    esac
done

if [[ -z "${_CFG}" ]]; then
  echo "usage: $_me -c path-of-config-file"
  exit 1
fi

source "${_CFG}"

#----------------------------------------------------
_SCRIPT_PATH="${BASH_SOURCE}"
while [ -L "${_SCRIPT_PATH}" ]; do
  _SCRIPT_DIR="$(cd -P "$(dirname "${_SCRIPT_PATH}")" >/dev/null 2>&1 && pwd)"
  _SCRIPT_PATH="$(readlink "${_SCRIPT_PATH}")"
  [[ ${_SCRIPT_PATH} != /* ]] && _SCRIPT_PATH="${_SCRIPT_DIR}/${_SCRIPT_PATH}"
done
_SCRIPT_PATH="$(readlink -f "${_SCRIPT_PATH}")"
_SCRIPT_DIR="$(cd -P "$(dirname -- "${_SCRIPT_PATH}")" >/dev/null 2>&1 && pwd)"

#----------------------------------------------------
if [[ ! -f "$_SCRIPT_DIR/../../cp4ba-logger/scripts/logger.sh" ]]; then
  echo "Error, log package not found !"
  echo "Clone it alongside with other cp4ba-..."
  echo "use the command: git clone https://github.com/marcoantonioni/cp4ba-logger"
  exit 1
fi
source $_SCRIPT_DIR/../../cp4ba-logger/scripts/logger.sh
if [[ -z "${CP4BA_LOGGING_ENABLED}" ]]; then 
  export CP4BA_LOGGING_ENABLED=true
fi
if [[ -z "${CP4BA_LOG_LEVEL}" ]]; then 
  export CP4BA_LOG_LEVEL="INFO"
fi
if [[ -z "${CP4BA_LOG_TO_CONSOLE}" ]]; then 
  export CP4BA_LOG_TO_CONSOLE=true
fi
if [[ -z "${CP4BA_LOG_TO_FILE}" ]]; then 
  export CP4BA_LOG_TO_FILE=false
fi
if [[ -z "${CP4BA_LOG_FILE}" ]]; then 
  export CP4BA_LOG_FILE=""
fi
if [[ -z "${CP4BA_LOG_MAX_SIZE}" ]]; then 
  export CP4BA_LOG_MAX_SIZE=$((10 * 1024 * 1024))
fi
if [[ -z "${CP4BA_LOG_BACKUP_COUNT}" ]]; then 
  export CP4BA_LOG_BACKUP_COUNT=5
fi


#-------------------------------------------------------------
# RPA MsSql Server

removeOldRPADb () {
  oc delete deployment -n ${CP4BA_INST_SUPPORT_NAMESPACE} ${CP4BA_INST_RPA_DB_DEPLOYMENT_NAME} 2> /dev/null 1> /dev/null
  oc delete pvc -n ${CP4BA_INST_SUPPORT_NAMESPACE} ${CP4BA_INST_RPA_PVC_NAME} 2> /dev/null 1> /dev/null

}

createRPASecrets () {

  if [[ -z "${CP4BA_INST_RPA_DB_SECRET_NAME}" ]]; then
    export CP4BA_INST_RPA_DB_SECRET_NAME="rpa-mssql"
    log_warning "${_CLR_GREEN}Value for CP4BA_INST_RPA_DB_SECRET_NAME is not set, default to '${CP4BA_INST_RPA_DB_SECRET_NAME}' value"
  fi
  if [[ -z "${CP4BA_INST_RPA_DB_PWD}" ]]; then
    export CP4BA_INST_RPA_DB_PWD="dem0s-dem0s"
    log_warning "${_CLR_GREEN}Value for CP4BA_INST_RPA_DB_PWD is not set, default to '${CP4BA_INST_RPA_DB_PWD}' value"
  fi

  _SECRET_NAME="${CP4BA_INST_RPA_DB_SECRET_NAME}"
  log_debug "Secret '${_CLR_YELLOW}${_SECRET_NAME}${_CLR_NC}'"
  oc delete secret -n ${CP4BA_INST_SUPPORT_NAMESPACE} ${_SECRET_NAME} 2> /dev/null 1> /dev/null
  oc create secret -n ${CP4BA_INST_SUPPORT_NAMESPACE} generic ${_SECRET_NAME} \
    --from-literal=SA_PASSWORD="${CP4BA_INST_RPA_DB_PWD}" 2> /dev/null 1> /dev/null
  if [[ $? -gt 0 ]]; then
    _ERROR=1
    log_error "${_CLR_RED}Secret ${_SECRET_NAME} NOT created (verify 'username/password' for secret) !!!${_CLR_NC}"
  fi
  oc label secret ${_SECRET_NAME} cp4ba.ibm.com/backup-type=mandatory -n ${CP4BA_INST_SUPPORT_NAMESPACE} 2> /dev/null 1> /dev/null

}

createRPAPVC () {

cat <<EOF | oc apply -f - 2> /dev/null 1> /dev/null
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: ${CP4BA_INST_RPA_PVC_NAME}
  namespace: ${CP4BA_INST_SUPPORT_NAMESPACE}
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: ${CP4BA_INST_RPA_PVC_SIZE}
  storageClassName: ${CP4BA_INST_SC_BLOCK}
EOF

}

createRPADatabase () {

cat <<EOF | oc apply -f - 2> /dev/null 1> /dev/null
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${CP4BA_INST_RPA_DB_DEPLOYMENT_NAME}
  namespace: ${CP4BA_INST_SUPPORT_NAMESPACE}
spec:
  selector:
    matchLabels:
      app: ${CP4BA_INST_RPA_DB_DEPLOYMENT_LABEL}
  replicas: 1
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: ${CP4BA_INST_RPA_DB_DEPLOYMENT_LABEL}
    spec:
      terminationGracePeriodSeconds: 10
      containers:
      - name: mssql
        image: ${CP4BA_INST_RPA_DB_IMAGE}
        ports:
        - containerPort: 1433
        env:
        - name: MSSQL_PID
          value: "Developer"
        - name: ACCEPT_EULA
          value: "Y"
        - name: SA_PASSWORD
          valueFrom:
            secretKeyRef:
              name: ${CP4BA_INST_RPA_DB_SECRET_NAME}
              key: SA_PASSWORD
        volumeMounts:
        - name: mssqldb
          mountPath: /var/opt/mssql
      serviceAccount: ${CP4BA_INST_RPA_SA}
      securityContext:
        runAsUser: 0
        runAsGroup: 0   
        fsGroup: 0
      volumes:
      - name: mssqldb
        persistentVolumeClaim:
          claimName: ${CP4BA_INST_RPA_PVC_NAME}
EOF

}

createRPADatabaseServices () {

  oc delete service -n ${CP4BA_INST_SUPPORT_NAMESPACE} ${CP4BA_INST_RPA_SERVICE_NODEPORT_NAME} 2> /dev/null 1> /dev/null
  oc delete service -n ${CP4BA_INST_SUPPORT_NAMESPACE} ${CP4BA_INST_RPA_SERVICE_NAME} 2> /dev/null 1> /dev/null

cat <<EOF | oc apply -f - 2> /dev/null 1> /dev/null
apiVersion: v1
kind: Service
metadata:
  name: ${CP4BA_INST_RPA_SERVICE_NODEPORT_NAME}
  namespace: ${CP4BA_INST_SUPPORT_NAMESPACE}
spec:
  selector:
    app: ${CP4BA_INST_RPA_DB_DEPLOYMENT_LABEL}
  ports:
    - protocol: TCP
      port: ${CP4BA_INST_RPA_NODE_PORT}
      targetPort: 1433
  type: NodePort
---
apiVersion: v1
kind: Service
metadata:
  name: ${CP4BA_INST_RPA_SERVICE_NAME}
  namespace: ${CP4BA_INST_SUPPORT_NAMESPACE}
spec:
  selector:
    app: ${CP4BA_INST_RPA_DB_DEPLOYMENT_LABEL}
  ports:
    - protocol: TCP
      port: 1433
      targetPort: 1433
EOF

}

deployRPAMsSqlServer () {
  log_info "Installing MSSQL Server for RPA capability"

  removeOldRPADb

  createRPASecrets
  createRPADatabase
  createRPAPVC
  createRPADatabaseServices  
}

if [[ "${CP4BA_INST_DB_RPA}" = "true" ]]; then
  log_msg "=============================================================="
  log_info "${_CLR_GREEN}Deploying RPA db '${_CLR_YELLOW}${CP4BA_INST_RPA_DB_DEPLOYMENT_NAME}${_CLR_GREEN}' in namespace '${_CLR_YELLOW}${CP4BA_INST_SUPPORT_NAMESPACE}${_CLR_GREEN}'${_CLR_NC}"
  deployRPAMsSqlServer
fi
exit 0

