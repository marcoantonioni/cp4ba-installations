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
# RPA 

deployMsSqlToolsPod() {
  log_info "${_CLR_GREEN}Deploying '${_CLR_YELLOW}MsSql Tools${_CLR_GREEN}' in namespace '${_CLR_YELLOW}${CP4BA_INST_NAMESPACE}${_CLR_GREEN}'${_CLR_NC}"  
  
  oc delete pod -n ${CP4BA_INST_SUPPORT_NAMESPACE} ${CP4BA_INST_DB_RPA_SQLTOOLS_POD_NAME} 2>/dev/null 1>/dev/null

cat <<EOF | oc create -f - 2>/dev/null 1>/dev/null
kind: Pod
apiVersion: v1
metadata:
  name: ${CP4BA_INST_DB_RPA_SQLTOOLS_POD_NAME}
  namespace: ${CP4BA_INST_SUPPORT_NAMESPACE}
  labels:
    app: mssql-tools
spec:
  containers:
    - name: mssql-tools
      image: 'mcr.microsoft.com/mssql-tools'
      command: [ "/bin/bash", "-c", "sleep infinity" ]
EOF

  while [ true ]
  do
      PHASE=$(oc get pod -n ${CP4BA_INST_SUPPORT_NAMESPACE} ${CP4BA_INST_DB_RPA_SQLTOOLS_POD_NAME} -o jsonpath='{.status.phase}')
      if [ "${PHASE}" = "Running" ]; then
          break
      else
          sleep 1
      fi
  done

}

createRpaDatabases() {
  
  log_info "${_CLR_GREEN}Execute SQL statements for RPA databases '${_CLR_YELLOW}automation, knowledge, wordnet, address, audit${_CLR_GREEN}'${_CLR_NC}"  

  # execute sql statements
  _KO=0
  _retry=0
  while [[ $_retry -le 10 ]]
  do
    _sqlResult=0

    oc rsh -n ${CP4BA_INST_SUPPORT_NAMESPACE} ${CP4BA_INST_DB_RPA_SQLTOOLS_POD_NAME} "${CP4BA_INST_DB_RPA_SQLTOOLS_FULL_PATH}" -C -S ${CP4BA_INST_RPA_SERVICE_NAME}.${CP4BA_INST_SUPPORT_NAMESPACE}.svc.cluster.local -U sa -P ${CP4BA_INST_RPA_DB_PWD} -Q "create database [automation]; create database [knowledge]; create database [wordnet]; create database [address]; create database [audit];" 2>/dev/null 1>/dev/null

    _sqlResult=$?
      
    if [ $_sqlResult -gt 0 ]; then
      _KO=1
      log_warning "${_CLR_GREEN}Cannot execute SQL statements for RPA databases, retry...${_CLR_NC}" 
      sleep 5
    else
      _KO=0
      log_info "${_CLR_GREEN}The SQL statements for RPA databases were executed successfully.${_CLR_NC}" 
      break  
    fi
    ((_retry = _retry + 1))
  done        

  if [[ $_KO -eq 1 ]]; then
    log_msg ""
    log_error "${_CLR_RED}[✗] RPA DBs NOT configured, check status of deployment '${_CLR_YELLOW}${CP4BA_INST_RPA_DB_DEPLOYMENT_NAME}${_CLR_RED}'${_CLR_NC}"
    log_error ">>> ${_CLR_RED}\x1b[5mERROR\x1b[25m${_CLR_NC} <<< RPA DB configuration terminated in error."
    log_msg ""
    exit 1
  fi

}

createMQCatalogAndSubscription () {

oc delete CatalogSource -n ${CP4BA_INST_NAMESPACE} ibmmq-operator-catalogsource 2>/dev/null 1>/dev/null
oc delete subs -n ${CP4BA_INST_NAMESPACE} ibm-mq 2>/dev/null 1>/dev/null

cat <<EOF | oc create -f - 2>/dev/null 1>/dev/null
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: ibmmq-operator-catalogsource
  namespace: ${CP4BA_INST_NAMESPACE}
spec:
  displayName: IBM MQ
  image: ${CP4BA_INST_RPA_MQ_OPERATOR_IMAGE}
  publisher: IBM
  sourceType: grpc
  updateStrategy:
    registryPoll:
      interval: 45m
EOF
      
cat <<EOF | oc create -f - 2>/dev/null 1>/dev/null
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: ibm-mq
  namespace: ${CP4BA_INST_NAMESPACE}
spec:
  channel: ${CP4BA_INST_RPA_MQ_CHANNEL}
  installPlanApproval: Automatic
  name: ibm-mq 
  source: ibmmq-operator-catalogsource
  sourceNamespace: ${CP4BA_INST_NAMESPACE}
EOF

}


createRpaCatalogAndSubscription () {

oc delete CatalogSource -n ${CP4BA_INST_NAMESPACE} ibm-robotic-process-automation-catalog 2>/dev/null 1>/dev/null
oc delete subs -n ${CP4BA_INST_NAMESPACE} rpa-subscription 2>/dev/null 1>/dev/null

cat <<EOF | oc create -f - 2>/dev/null 1>/dev/null
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: ibm-robotic-process-automation-catalog
  namespace: ${CP4BA_INST_NAMESPACE}
spec:
  displayName: IBM Robotic Process Automation Catalog
  publisher: IBM
  sourceType: grpc
  image: ${CP4BA_INST_RPA_OPERATOR_IMAGE}
  updateStrategy:
    registryPoll:
      interval: 45m
EOF

cat <<EOF | oc create -f - 2>/dev/null 1>/dev/null
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: rpa-subscription
  namespace: ${CP4BA_INST_NAMESPACE}
  labels:
    operators.coreos.com/ibm-automation-rpa.cp4ba: ''
spec:
  name: ibm-automation-rpa
  channel: ${CP4BA_INST_RPA_CHANNEL_VER}
  startingCSV: ${CP4BA_INST_RPA_STARTING_CSV}
  sourceNamespace: ${CP4BA_INST_NAMESPACE}
  installPlanApproval: Automatic
  source: ibm-robotic-process-automation-catalog
EOF

}

createRpaSecrets() {

  # db secret
  oc create secret generic rpa-db -n ${CP4BA_INST_NAMESPACE} \
    --from-literal=AddressContext="${CP4BA_INST_RPA_DB_CONN_PARAMS_ADDRESS}" \
    --from-literal=AutomationContext="${CP4BA_INST_RPA_DB_CONN_PARAMS_AUTOMATION}" \
    --from-literal=KnowledgeBase="${CP4BA_INST_RPA_DB_CONN_PARAMS_KNOWLEDGE}" \
    --from-literal=WordnetContext="${CP4BA_INST_RPA_DB_CONN_PARAMS_WORDNET}" \
    --from-literal=AuditContext="${CP4BA_INST_RPA_DB_CONN_PARAMS_AUDIT}" 2>/dev/null 1>/dev/null

  # tenant owner
  oc create secret generic rpa-first-tenant-owner -n ${CP4BA_INST_NAMESPACE} \
    --from-literal=name=${CP4BA_INST_RPA_TENANT_OWNER_NAME} \
    --from-literal=email=${CP4BA_INST_RPA_TENANT_OWNER_EMAIL} 2>/dev/null 1>/dev/null

  # smtp secret
  oc create secret generic rpa-smtp -n ${CP4BA_INST_NAMESPACE} \
    --from-literal=username=${CP4BA_INST_RPA_SMTP_USER} \
    --from-literal=password=${CP4BA_INST_RPA_SMTP_PASSWORD} 2>/dev/null 1>/dev/null

  # redis secret https://www.ibm.com/docs/en/rpa/30.0.x?topic=platform-creating-rpa-secrets#creating-a-redis-password-secret
  oc create secret generic rpa-redis-rpa -n ${CP4BA_INST_NAMESPACE} \
    --from-literal=default_password=${CP4BA_INST_PAKBA_ADMIN_PWD} 2>/dev/null 1>/dev/null

  oc label secret rpa-redis-rpa app.kubernetes.io/component=rpa -n ${CP4BA_INST_NAMESPACE} 2> /dev/null 1> /dev/null
  oc label secret rpa-redis-rpa app.kubernetes.io/instance=rpa -n ${CP4BA_INST_NAMESPACE} 2> /dev/null 1> /dev/null
  oc label secret rpa-redis-rpa app.kubernetes.io/managed-by=ibm-rpa-operator -n ${CP4BA_INST_NAMESPACE} 2> /dev/null 1> /dev/null
  oc label secret rpa-redis-rpa app.kubernetes.io/name=redis -n ${CP4BA_INST_NAMESPACE} 2> /dev/null 1> /dev/null
  oc label secret rpa-redis-rpa rpa.automation.ibm.com/cr-name=rpa -n ${CP4BA_INST_NAMESPACE} 2> /dev/null 1> /dev/null

# apiVersion: v1
# kind: Secret
# metadata:
#   name: <RPA-INSTANCE-NAME>-redis-rpa
#   namespace: <NAMESPACE>
#   labels:
#     app.kubernetes.io/component: rpa
#     app.kubernetes.io/instance: <RPA-INSTANCE-NAME>
#     app.kubernetes.io/managed-by: ibm-rpa-operator
#     app.kubernetes.io/name: redis
#     rpa.automation.ibm.com/cr-name: <RPA-INSTANCE-NAME>
# data:
#   default_password: <PASSWORD>
# type: Opaque   
}

createRpaCR () {

  log_info "${_CLR_GREEN}Create RPA CR '${_CLR_YELLOW}${CP4BA_INST_RPA_INSTANCE_NAME}' in namespace '${_CLR_YELLOW}${CP4BA_INST_NAMESPACE}${_CLR_GREEN}'${_CLR_NC}"  

cat <<EOF | oc create -f - 2>/dev/null 1>/dev/null
apiVersion: rpa.automation.ibm.com/v1
kind: RoboticProcessAutomation
metadata:
  name: ${CP4BA_INST_RPA_INSTANCE_NAME}
  namespace: ${CP4BA_INST_NAMESPACE}
spec:
  license:
    accept: true
    includeSWCUpload: true
  createRoutes: true
  webDriverUpdates:
    enabled: true
  systemQueueProvider:
    highAvailability: false
  ui:
    replicas: 1
  hotStorageCleanup:
    enabled: true
  version: ${CP4BA_INST_RPA_VERSION}
  iam:
    route: cpd

  zen:
    managed: false

  fileStorageClass: ${CP4BA_INST_SC_FILE}
  blockStorageClass: ${CP4BA_INST_SC_BLOCK}

  sizeMapping:
    watson-nlp:
      replicas: 1

  api:
    replicas: 1

    databaseConnectionSecretName: rpa-db

    firstTenant:
      name: ${CP4BA_INST_RPA_TENANT_NAME}
      ownerSecretName: rpa-first-tenant-owner
    smtp:
      port: 587
      server: mail.cp4ba-collateral.svc.cluster.local
      userSecretName: rpa-smtp

  antivirus:
    replicas: 1
  tls: {}
  audit:
    forwardingEnabled: true
  ocr:
    replicas: 1
EOF

}

deployRPAResources () {
  _DELAY=600

  createMQCatalogAndSubscription
  createRpaCatalogAndSubscription

  sleep $_DELAY

  createRpaSecrets
  deployMsSqlToolsPod
  createRpaDatabases

  sleep $_DELAY

  createRpaCR
}

if [[ "${CP4BA_INST_DB_RPA}" = "true" ]]; then
  ${_SCRIPT_DIR}/cp4ba-install-rpa-db.sh -c ${_CFG}
  if [[ $? -ne 0 ]]; then
    log_error "${_CLR_RED}[✗] Error, RPA DB not installed.${_CLR_NC}"
    exit 1
  fi

  log_msg "=============================================================="
  log_info "${_CLR_GREEN}Deploying RPA resources (version:${_CLR_YELLOW}${CP4BA_INST_RPA_VERSION}${_CLR_GREEN}, channel:${_CLR_YELLOW}${CP4BA_INST_RPA_CHANNEL_VER}${_CLR_GREEN}, csv:${_CLR_YELLOW}${CP4BA_INST_RPA_STARTING_CSV}${_CLR_GREEN}), wait..."

  deployRPAResources

fi
exit 0

