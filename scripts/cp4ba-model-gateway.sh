#!/bin/bash

# Documentation
# https://www.ibm.com/docs/en/cloud-paks/cp-biz-automation/26.0.0?topic=installing-model-gateway

#set -euo pipefail

_me=$(basename "$0")

_CFG=""
_OPERATION=""

_MODEL_GATEWAY_SECRET_NAME="model-gateway-postgres-external-secret"

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
      log_error "${_CLR_RED}[✗] ERROR '${_CLR_YELLOW}${CP4BA_INST_TMP_FOLDER}${_CLR_RED}' is not a valid temporary folder, check if it is a folder or if you have write permissions !${_CLR_NC}"
      log_error "${_CLR_RED}'${_CLR_YELLOW}${CP4BA_INST_TMP_FOLDER}${_CLR_RED}' ${_ERR_MSG_FOLDER}${_ERR_MSG_PERMISSIONS}${_CLR_NC}"
      exit 1
    fi
    export _INST_TMP_FOLDER="${CP4BA_INST_TMP_FOLDER}"
  fi
  log_info "${_CLR_GREEN}Running with temporary folder '${_CLR_YELLOW}${_INST_TMP_FOLDER}${_CLR_GREEN}'${_CLR_NC}"

}

#--------------------------------------------------------
# read command line params
while getopts c:o: flag
do
    case "${flag}" in
        c) _CFG=${OPTARG};;
        o) _OPERATION=${OPTARG};;
    esac
done

usage () {
  echo ""
  echo -e "${_CLR_GREEN}usage: $_me
    -c full-path-to-config-file
       (eg: '../configs/env1.properties')
    -o operation [install|verify|uninstall]    
    ${_CLR_NC}"
}

if [[ -z "${_CFG}" ]]; then
  usage
  exit 1
fi

if [[ ! -f "${_CFG}" ]]; then
  echo "[✗] Error, configuration file not found: ${_CFG}"
  exit 1
fi

if [[ -z "${_OPERATION}" ]]; then
  usage
  exit 1
fi

if [[ "${_OPERATION}" != "install" && "${_OPERATION}" != "verify" && "${_OPERATION}" != "uninstall" ]]; then
  echo "[✗] Error, operation not valid, use one of: install | verify | uninstall "
  exit 1
fi


source "${_CFG}" 2>/dev/null 1>/dev/null


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

#-------------------------------
checkPrereqTools () {
  which helm &>/dev/null
  if [[ $? -ne 0 ]]; then
    log_error "${_CLR_RED}[✗] Error, helm not installed, cannot proceed.${_CLR_NC}"
    exit 1
  fi
  which openssl &>/dev/null
  if [[ $? -ne 0 ]]; then
    log_warning "${_CLR_YELLOW}[✗] Warning, openssl not installed, some activities may fail.${_CLR_NC}"
  fi
}

#-------------------------------
resourceExist () {
#    echo "namespace name: $1"
#    echo "resource type: $2"
#    echo "resource name: $3"
  if [ $(oc get $2 -n $1 $3 2> /dev/null | grep $3 2>/dev/null | wc -l) -lt 1 ];
  then
      return 0
  fi
  return 1
}

extractInternalDbCertificates () {
  log_info "Exporting self signed temporary certificates in folder '${_CLR_YELLOW}${CP4BA_INST_DB_SSL_CERTIFICATE_FOLDER}${_CLR_GREEN}'"

  # secret db
  oc get secrets ${CP4BA_INST_DB_1_TLS_CERTS_SECRET_NAME} -n ${CP4BA_INST_NAMESPACE} -o jsonpath='{.data.ca\.crt}' | base64 -d > ${CP4BA_INST_DB_SSL_CERTIFICATE_FOLDER}/ca.crt
  oc get secrets ${CP4BA_INST_DB_1_TLS_CERTS_SECRET_NAME} -n ${CP4BA_INST_NAMESPACE} -o jsonpath='{.data.tls\.crt}' | base64 -d > ${CP4BA_INST_DB_SSL_CERTIFICATE_FOLDER}/client.crt
  oc get secrets ${CP4BA_INST_DB_1_TLS_CERTS_SECRET_NAME} -n ${CP4BA_INST_NAMESPACE} -o jsonpath='{.data.tls\.key}' | base64 -d > ${CP4BA_INST_DB_SSL_CERTIFICATE_FOLDER}/client.key

  return 0
}

verifyExternalDbCertificates () {
  return 0
}

createModelGatewaySecret () {

  _SECRET_NAME="${_MODEL_GATEWAY_SECRET_NAME}"
  log_debug "Secret '${_CLR_YELLOW}${_SECRET_NAME}${_CLR_NC}'"

  _parameters="verify-ca&sslrootcert=/postgres-secrets/ca.crt&sslcert=/postgres-secrets/client.crt&sslkey=/postgres-secrets/client.key"
  oc delete secret "${_SECRET_NAME}" -n ${CP4BA_INST_NAMESPACE} 2>/dev/null 1>/dev/null
  oc create secret generic "${_SECRET_NAME}" -n ${CP4BA_INST_NAMESPACE} \
    --from-literal=host="${CP4BA_INST_DB_1_SERVICE}" \
    --from-literal=port=${CP4BA_INST_DB_SERVER_PORT} \
    --from-literal=username="${CP4BA_INST_DB_MODELGATEWAY_USER}" \
    --from-literal=password="${CP4BA_INST_DB_MODELGATEWAY_PWD}" \
    --from-literal=dbname="${CP4BA_INST_ENV_FOR_DB_PREFIX}_modelgateway" \
    --from-literal=parameters="${_parameters}" \
    --from-file=ca.crt="${CP4BA_INST_DB_SSL_CERTIFICATE_FOLDER}/ca.crt" \
    --from-file=client.crt="${CP4BA_INST_DB_SSL_CERTIFICATE_FOLDER}/client.crt" \
    --from-file=client.key="${CP4BA_INST_DB_SSL_CERTIFICATE_FOLDER}/client.key" 2>/dev/null 1>/dev/null

  return 0
}

#-------------------------------------------------
installModelGateway () {
  log_info "Install model gateway...not ready"

  _DELETE_TEMP_CERTS=0

  # manage sertificates
  if [[ "${CP4BA_INST_DB}" = "true" ]]; then

    resourceExist ${CP4BA_INST_NAMESPACE} "secret" ${CP4BA_INST_DB_1_TLS_CERTS_SECRET_NAME}
    if [ $? -eq 1 ]; then
      export CP4BA_INST_DB_SSL_CERTIFICATE_FOLDER="${_INST_TMP_FOLDER}/cp4ba-pg-secrets-folder-$USER-$RANDOM"
      mkdir -p ${CP4BA_INST_DB_SSL_CERTIFICATE_FOLDER}
      _DELETE_TEMP_CERTS=1
      extractInternalDbCertificates "${CP4BA_INST_DB_SSL_CERTIFICATE_FOLDER}"

      ls -al "${CP4BA_INST_DB_SSL_CERTIFICATE_FOLDER}"
    else
      log_error "Secret '${CP4BA_INST_DB_1_TLS_CERTS_SECRET_NAME}' doesn't exists."
      exit 1
    fi
  else
    verifyExternalDbCertificates "${CP4BA_INST_DB_SSL_CERTIFICATE_FOLDER}"
  fi

  createModelGatewaySecret

  if [[ ${_DELETE_TEMP_CERTS} -eq 1 ]]; then
    log_info "Removing self signed temporary certificates"
    rm -fr ${CP4BA_INST_DB_SSL_CERTIFICATE_FOLDER} 2>/dev/null 1>/dev/null
  fi


}

verifyModelGateway () {
  echo "Verify not implemented"

}

uninstallModelGateway () {
  echo "Uninstall not implemented"

}


log_msg "=============================================================="
log_info "${_CLR_GREEN}CP4BA Model Gateway Tool${_CLR_NC}"

setTemporaryFolder

case "${_OPERATION}" in
    install) installModelGateway;;
    verify) verifyModelGateway;;
    uninstall) uninstallModelGateway;;
esac
