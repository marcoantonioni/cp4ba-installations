#!/bin/bash

#set -euo pipefail

_me=$(basename "$0")

_CFG=""
_WAIT="false"
_SILENT="false"
_ERROR=0

_maxWait=5

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
      echo -e "${_CLR_RED} '${_CLR_YELLOW}${CP4BA_INST_TMP_FOLDER}${_CLR_RED}' ${_ERR_MSG_FOLDER}${_ERR_MSG_PERMISSIONS}${_CLR_NC}"
      exit 1
    fi
    export _INST_TMP_FOLDER="${CP4BA_INST_TMP_FOLDER}"
  fi
  log_info "${_CLR_GREEN}Running with temporary folder '${_CLR_YELLOW}${_INST_TMP_FOLDER}${_CLR_GREEN}'${_CLR_NC}"

}

#--------------------------------------------------------
# read command line params
while getopts c:t:ws flag
do
    case "${flag}" in
        c) _CFG=${OPTARG};;
        t) _maxWait=${OPTARG};;
        w) _WAIT="true";;
        s) _SILENT="true";;
    esac
done

if [[ -z "${_CFG}" ]]; then
  echo "usage: $_me -c path-of-config-file -w wait-for-db-creation -t time-to-wait-in-seconds -s silent-mode"
  exit
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

#-------------------------------
createSecretLDAP () {
  log_debug "Secret '${_CLR_YELLOW}${CP4BA_INST_LDAP_SECRET}${_CLR_NC}'"
  oc delete secret -n ${CP4BA_INST_NAMESPACE} ${CP4BA_INST_LDAP_SECRET} 2> /dev/null 1> /dev/null
  oc create secret -n ${CP4BA_INST_NAMESPACE} generic ${CP4BA_INST_LDAP_SECRET} \
    --from-literal=ldapUsername="cn=admin,dc=vuxprod,dc=net" \
    --from-literal=ldapPassword="passw0rd" 2> /dev/null 1> /dev/null
  if [[ $? -gt 0 ]]; then
    _ERROR=1
    log_error "${_CLR_RED}Secret ${CP4BA_INST_LDAP_SECRET} NOT created (verify 'username/password' for secret) !!!${_CLR_NC}"
  fi
}


#-------------------------------
createSecretFNCM () {
  oc delete secret -n ${CP4BA_INST_NAMESPACE} ibm-fncm-secret 2> /dev/null 1> /dev/null
  _ERR=0  
  if [[ ! -z "${CP4BA_INST_DB_BAWDOCS_USER}" ]] && [[ ! -z "${CP4BA_INST_DB_BAWDOS_USER}" ]] && [[ ! -z "${CP4BA_INST_DB_BAWTOS_USER}" ]]; then
    log_debug "Secret '${_CLR_YELLOW}ibm-fncm-secret (FNCM+BAW objectstores users)${_CLR_NC}'"    
    oc delete secret -n ${CP4BA_INST_NAMESPACE} ibm-fncm-secret 2> /dev/null 1> /dev/null
    oc create secret -n ${CP4BA_INST_NAMESPACE} generic ibm-fncm-secret \
      --from-literal="${CP4BA_INST_DB_GCD_LBL}"DBUsername="${CP4BA_INST_DB_GCD_USER}" \
      --from-literal="${CP4BA_INST_DB_GCD_LBL}"DBPassword="${CP4BA_INST_DB_GCD_PWD}" \
      --from-literal="${CP4BA_INST_DB_BAWDOCS_LBL}"DBUsername="${CP4BA_INST_DB_BAWDOCS_USER}" \
      --from-literal="${CP4BA_INST_DB_BAWDOCS_LBL}"DBPassword="${CP4BA_INST_DB_BAWDOCS_PWD}" \
      --from-literal="${CP4BA_INST_DB_BAWDOS_LBL}"DBUsername="${CP4BA_INST_DB_BAWDOS_USER}" \
      --from-literal="${CP4BA_INST_DB_BAWDOS_LBL}"DBPassword="${CP4BA_INST_DB_BAWDOS_PWD}" \
      --from-literal="${CP4BA_INST_DB_BAWTOS_LBL}"DBUsername="${CP4BA_INST_DB_BAWTOS_USER}" \
      --from-literal="${CP4BA_INST_DB_BAWTOS_LBL}"DBPassword="${CP4BA_INST_DB_BAWTOS_PWD}" \
      --from-literal="${CP4BA_INST_DB_OS_LBL}"DBUsername="${CP4BA_INST_DB_OS_USER}" \
      --from-literal="${CP4BA_INST_DB_OS_LBL}"DBPassword="${CP4BA_INST_DB_OS_PWD}" \
      --from-literal="${CP4BA_INST_DB_CONTENT_LBL}"DBUsername="${CP4BA_INST_DB_CONTENT_USER}" \
      --from-literal="${CP4BA_INST_DB_CONTENT_LBL}"DBPassword="${CP4BA_INST_DB_CONTENT_PWD}" \
      --from-literal="${CP4BA_INST_DB_CHOS_LBL}"DBUsername="${CP4BA_INST_DB_CHOS_USER}" \
      --from-literal="${CP4BA_INST_DB_CHOS_LBL}"DBPassword="${CP4BA_INST_DB_CHOS_PWD}" \
      --from-literal="${CP4BA_INST_DB_AE_LBL}"DBUsername="${CP4BA_INST_DB_AE_USER}" \
      --from-literal="${CP4BA_INST_DB_AE_LBL}"DBPassword="${CP4BA_INST_DB_AE_PWD}" \
      --from-literal="${CP4BA_INST_DB_PBK_LBL}"DBUsername="${CP4BA_INST_DB_PBK_USER}" \
      --from-literal="${CP4BA_INST_DB_PBK_LBL}"DBPassword="${CP4BA_INST_DB_PBK_PWD}" \
      --from-literal="${CP4BA_INST_DB_APP_LBL}"DBUsername="${CP4BA_INST_DB_APP_USER}" \
      --from-literal="${CP4BA_INST_DB_APP_LBL}"DBPassword="${CP4BA_INST_DB_APP_PWD}" \
      --from-literal="${CP4BA_INST_DB_AWS_LBL}"DBUsername="${CP4BA_INST_DB_AWS_USER}" \
      --from-literal="${CP4BA_INST_DB_AWS_LBL}"DBPassword="${CP4BA_INST_DB_AWS_PWD}" \
      --from-literal=appLoginUsername="${CP4BA_INST_PAKBA_ADMIN_USER}" \
      --from-literal=appLoginPassword="${CP4BA_INST_PAKBA_ADMIN_PWD}" \
      --from-literal=ltpaPassword="${CP4BA_INST_PAKBA_PASSW_LTPA}" \
      --from-literal=keystorePassword="${CP4BA_INST_PAKBA_PASSW_KEYSTORE}" 2> /dev/null 1> /dev/null
    _ERR=$?
  else
    if [[ ! -z "${CP4BA_INST_DB_OS_USER}" ]] && [[ ! -z "${CP4BA_INST_DB_GCD_USER}" ]]; then
      log_debug "Secret '${_CLR_YELLOW}ibm-fncm-secret (FNCM objectstores users)${_CLR_NC}'"
      oc delete secret -n ${CP4BA_INST_NAMESPACE} ibm-fncm-secret 2> /dev/null 1> /dev/null
      oc create secret -n ${CP4BA_INST_NAMESPACE} generic ibm-fncm-secret \
        --from-literal="${CP4BA_INST_DB_OS_LBL}"DBUsername="${CP4BA_INST_DB_OS_USER}" \
        --from-literal="${CP4BA_INST_DB_OS_LBL}"DBPassword="${CP4BA_INST_DB_OS_PWD}" \
        --from-literal="${CP4BA_INST_DB_GCD_LBL}"DBUsername="${CP4BA_INST_DB_GCD_USER}" \
        --from-literal="${CP4BA_INST_DB_GCD_LBL}"DBPassword="${CP4BA_INST_DB_GCD_PWD}" \
        --from-literal=appLoginUsername="${CP4BA_INST_PAKBA_ADMIN_USER}" \
        --from-literal=appLoginPassword="${CP4BA_INST_PAKBA_ADMIN_PWD}" \
        --from-literal=ltpaPassword="${CP4BA_INST_PAKBA_PASSW_LTPA}" \
        --from-literal=keystorePassword="${CP4BA_INST_PAKBA_PASSW_KEYSTORE}" 2> /dev/null 1> /dev/null
      _ERR=$?
    else
      log_debug "Secret '${_CLR_YELLOW}ibm-fncm-secret (APP only)${_CLR_NC}'"
      oc delete secret -n ${CP4BA_INST_NAMESPACE} ibm-fncm-secret 2> /dev/null 1> /dev/null
      oc create secret -n ${CP4BA_INST_NAMESPACE} generic ibm-fncm-secret \
        --from-literal=appLoginUsername="${CP4BA_INST_PAKBA_ADMIN_USER}" \
        --from-literal=appLoginPassword="${CP4BA_INST_PAKBA_ADMIN_PWD}" \
        --from-literal=ltpaPassword="${CP4BA_INST_PAKBA_PASSW_LTPA}" \
        --from-literal=keystorePassword="${CP4BA_INST_PAKBA_PASSW_KEYSTORE}" 2> /dev/null 1> /dev/null
      _ERR=$?
    fi
  fi

  if [[ $_ERR -gt 0 ]]; then
    _ERROR=1
    log_error "${_CLR_RED}Secret ibm-fncm-secret NOT created (verify 'username/password' for secret) !!!${_CLR_NC}"
  fi
}

#-------------------------------
createSecretFNCMBpmOnly () {
  log_debug "Secret '${_CLR_YELLOW}ibm-fncm-secret${_CLR_NC}'"
  oc delete secret -n ${CP4BA_INST_NAMESPACE} ibm-fncm-secret 2> /dev/null 1> /dev/null
  oc create secret -n ${CP4BA_INST_NAMESPACE} generic ibm-fncm-secret \
    --from-literal=appLoginUsername="${CP4BA_INST_PAKBA_ADMIN_USER}" \
    --from-literal=appLoginPassword="${CP4BA_INST_PAKBA_ADMIN_PWD}" \
    --from-literal=ltpaPassword="${CP4BA_INST_PAKBA_PASSW_LTPA}" \
    --from-literal=keystorePassword="${CP4BA_INST_PAKBA_PASSW_KEYSTORE}" 2> /dev/null 1> /dev/null
  if [[ $? -gt 0 ]]; then
    _ERROR=1
    log_error "${_CLR_RED}Secret ibm-fncm-secret NOT created (verify 'username/password' for secret) !!!${_CLR_NC}"
  fi
}

#-------------------------------
createSecretBAN () {
  log_debug "Secret '${_CLR_YELLOW}ibm-ban-secret${_CLR_NC}'"

  if [[ -z "${CP4BA_INST_DB_ICN_USER}" ]]; then
    CP4BA_INST_DB_ICN_USER="${CP4BA_INST_PAKBA_ADMIN_USER}"
    CP4BA_INST_DB_ICN_PWD="${CP4BA_INST_PAKBA_ADMIN_PWD}"
  fi

  oc delete secret -n ${CP4BA_INST_NAMESPACE} ibm-ban-secret 2> /dev/null 1> /dev/null
  oc create secret -n ${CP4BA_INST_NAMESPACE} generic ibm-ban-secret \
    --from-literal=navigatorDBUsername="${CP4BA_INST_DB_ICN_USER}" \
    --from-literal=navigatorDBPassword="${CP4BA_INST_DB_ICN_PWD}" \
    --from-literal=appLoginUsername="${CP4BA_INST_PAKBA_ADMIN_USER}" \
    --from-literal=appLoginPassword="${CP4BA_INST_PAKBA_ADMIN_PWD}" \
    --from-literal=ltpaPassword="${CP4BA_INST_PAKBA_PASSW_LTPA}" \
    --from-literal=keystorePassword="${CP4BA_INST_PAKBA_PASSW_KEYSTORE}" 2> /dev/null 1> /dev/null
  if [[ $? -gt 0 ]]; then
    _ERROR=1
    log_error "${_CLR_RED}Secret ibm-ban-secret NOT created (verify 'username/password' for secret) !!!${_CLR_NC}"
  fi
}

#-------------------------------
createSecretBAW () {
# $1 secret name
# $2 username
# $3 password

  log_debug "Secret '${_CLR_YELLOW}$1${_CLR_NC}'"
  oc delete secret -n ${CP4BA_INST_NAMESPACE} $1 2> /dev/null 1> /dev/null
  oc create secret -n ${CP4BA_INST_NAMESPACE} generic $1 \
    --from-literal=dbUser="$2" \
    --from-literal=password="$3"  2> /dev/null 1> /dev/null
  if [[ $? -gt 0 ]]; then
    _ERROR=1
    log_error "${_CLR_RED}Secret '${_CLR_YELLOW}$1${_CLR_RED}' NOT created (verify 'username/password' for secret) !!!${_CLR_NC}"
  fi
}

createSecretWFAssistantBAW () {
# $1=APIKEY
# $2=PRJID
# $3=URL

  _SECRET_NAME="ibm-workflow-assistant-secrets"
  log_debug "Secret '${_CLR_YELLOW}${_SECRET_NAME}${_CLR_NC}'"
  oc delete secret -n ${CP4BA_INST_NAMESPACE} ${_SECRET_NAME} 2> /dev/null 1> /dev/null
  oc create secret -n ${CP4BA_INST_NAMESPACE} generic ${_SECRET_NAME} \
    --from-literal=WATSONX_API_KEY="$1" \
    --from-literal=WATSONX_PROJECT_ID="$2" \
    --from-literal=WATSONX_URL="$3" 2> /dev/null 1> /dev/null
  if [[ $? -gt 0 ]]; then
    _ERROR=1
    log_error "${_CLR_RED}Secret '${_CLR_YELLOW}${_SECRET_NAME}${_CLR_RED}' NOT created (verify 'watsonx api key / proj id / url' for secret) !!!${_CLR_NC}"
  fi

}


#-------------------------------
#createSecretAE () {
#  if [[ ! -z "${CP4BA_INST_AE_1_AD_SECRET_NAME}" ]]; then
#    log_debug "Secret '${_CLR_YELLOW}${CP4BA_INST_AE_1_AD_SECRET_NAME}${_CLR_NC}'"
#
#    oc delete secret -n ${CP4BA_INST_NAMESPACE} ${CP4BA_INST_AE_1_AD_SECRET_NAME} 2> /dev/null 1> /dev/null
#    oc create secret -n ${CP4BA_INST_NAMESPACE} generic ${CP4BA_INST_AE_1_AD_SECRET_NAME} \
#      --from-literal=AE_DATABASE_USER="${CP4BA_INST_DB_AE_USER}" \
#      --from-literal=AE_DATABASE_PWD="${CP4BA_INST_DB_AE_PWD}" 1> /dev/null
#    if [[ $? -gt 0 ]]; then
#      _ERROR=1
#      log_error "${_CLR_RED}Secret ${CP4BA_INST_AE_1_AD_SECRET_NAME} NOT created (verify 'username/password' for secret) !!!${_CLR_NC}"
#    fi
#  fi
#}

# ??? modificare come sopra
createSecretAE () {

_AE_DB_USER=$(echo ${CP4BA_INST_DB_AE_USER} | base64)
_AE_DB_PWD=$(echo ${CP4BA_INST_DB_AE_PWD} | base64)

#---------------------------

  _SECRET_NAME="${CP4BA_INST_CR_NAME}-workspace-app-engine-admin-secret"
  log_debug "Secret '${_CLR_YELLOW}${_SECRET_NAME}${_CLR_NC}'"
  oc delete secret -n ${CP4BA_INST_NAMESPACE} ${_SECRET_NAME} 2> /dev/null 1> /dev/null
  oc create secret -n ${CP4BA_INST_NAMESPACE} generic ${_SECRET_NAME} \
    --from-literal=AE_DATABASE_USER="${CP4BA_INST_DB_AE_USER}" \
    --from-literal=AE_DATABASE_PWD="${CP4BA_INST_DB_AE_PWD}" 2> /dev/null 1> /dev/null

#---------------------------

  _SECRET_NAME="${CP4BA_INST_CR_NAME}-pbk-app-engine-admin-secret"
  log_debug "Secret '${_CLR_YELLOW}${_SECRET_NAME}${_CLR_NC}'"
  oc delete secret -n ${CP4BA_INST_NAMESPACE} ${_SECRET_NAME} 2> /dev/null 1> /dev/null
  oc create secret -n ${CP4BA_INST_NAMESPACE} generic ${_SECRET_NAME} \
    --from-literal=AE_DATABASE_USER="${CP4BA_INST_DB_AE_USER}" \
    --from-literal=AE_DATABASE_PWD="${CP4BA_INST_DB_AE_PWD}" 2> /dev/null 1> /dev/null

#---------------------------

  _SECRET_NAME="${CP4BA_INST_CR_NAME}-workspace-aae-app-engine-admin-secret"
  log_debug "Secret '${_CLR_YELLOW}${_SECRET_NAME}${_CLR_NC}'"
  oc delete secret -n ${CP4BA_INST_NAMESPACE} ${_SECRET_NAME} 2> /dev/null 1> /dev/null
  oc create secret -n ${CP4BA_INST_NAMESPACE} generic ${_SECRET_NAME} \
    --from-literal=AE_DATABASE_USER="${CP4BA_INST_DB_AE_USER}" \
    --from-literal=AE_DATABASE_PWD="${CP4BA_INST_DB_AE_PWD}" 2> /dev/null 1> /dev/null

}

#-------------------------------
createSecretBAS () {
# $1 username
# $2 password

if [[ ${CP4BA_INST_OPT_COMPONENTS} == *"baw_authoring"* ]] || [[ ${CP4BA_INST_OPT_COMPONENTS} == *"wfps_authoring"* ]]; then
  log_debug "Secret '${_CLR_YELLOW}${CP4BA_INST_CR_NAME}-bas-admin-secret${_CLR_NC}'"
  oc delete secret -n ${CP4BA_INST_NAMESPACE} ${CP4BA_INST_CR_NAME}-bas-admin-secret 2> /dev/null 1> /dev/null
  oc create secret -n ${CP4BA_INST_NAMESPACE} generic ${CP4BA_INST_CR_NAME}-bas-admin-secret \
    --from-literal=dbUsername="$1" \
    --from-literal=dbPassword="$2" 2> /dev/null 1> /dev/null
  if [[ $? -gt 0 ]]; then
    _ERROR=1
    log_error "${_CLR_RED}Secret '${_CLR_YELLOW}${CP4BA_INST_CR_NAME}-bas-admin-secret${_CLR_RED}' NOT created (verify 'username/password' for secret) !!!${_CLR_NC}"
  fi

  oc label secret ${CP4BA_INST_CR_NAME}-bas-admin-secret db-server=${CP4BA_INST_DB_1_SERVICE} -n ${CP4BA_INST_NAMESPACE} 2> /dev/null 1> /dev/null
  oc label secret ${CP4BA_INST_CR_NAME}-bas-admin-secret db-name=${CP4BA_INST_BAW_1_DB_NAME} -n ${CP4BA_INST_NAMESPACE} 2> /dev/null 1> /dev/null
  oc label secret ${CP4BA_INST_CR_NAME}-bas-admin-secret cp4ba.ibm.com/backup-type=mandatory -n ${CP4BA_INST_NAMESPACE} 2> /dev/null 1> /dev/null

fi

#---------------------------------------------
# BAS WF Assistant

#---------------------------------------------
  _SECRET_NAME="ibm-workflow-assistant-secrets"
  log_debug "Secret '${_CLR_YELLOW}${_SECRET_NAME}${_CLR_NC}'"
  oc delete secret -n ${CP4BA_INST_NAMESPACE} ${_SECRET_NAME} 2> /dev/null 1> /dev/null
  oc create secret -n ${CP4BA_INST_NAMESPACE} generic ${_SECRET_NAME} \
    --from-literal=WATSONX_API_KEY="${CP4BA_INST_BAS_GENAI_WX_APIKEY}" \
    --from-literal=WATSONX_PROJECT_ID="${CP4BA_INST_BAS_GENAI_WX_PRJ_ID}" \
    --from-literal=WATSONX_URL="${CP4BA_INST_BAS_GENAI_WX_URL_PROVIDER}" 2> /dev/null 1> /dev/null
  if [[ $? -gt 0 ]]; then
    _ERROR=1
    log_error "${_CLR_RED}Secret '${_CLR_YELLOW}${_SECRET_NAME}${_CLR_RED}' NOT created (verify 'watsonx api key / proj id / url' for secret) !!!${_CLR_NC}"
  fi

}

#-------------------------------
createSecretADS () {
  log_debug "Secret '${_CLR_YELLOW}ibm-dba-ads-runtime-secret${_CLR_NC}'"
  oc delete secret -n ${CP4BA_INST_NAMESPACE} ibm-dba-ads-runtime-secret 2> /dev/null 1> /dev/null
  oc create secret -n ${CP4BA_INST_NAMESPACE} generic ibm-dba-ads-runtime-secret \
    --from-literal=asraManagerUsername="${CP4BA_INST_ADS_SECRETS_ASRA_MGR_USER}" \
    --from-literal=asraManagerPassword="${CP4BA_INST_ADS_SECRETS_ASRA_MGR_PASS}" \
    --from-literal=decisionServiceUsername="${CP4BA_INST_ADS_SECRETS_DRS_USER}" \
    --from-literal=decisionServicePassword="${CP4BA_INST_ADS_SECRETS_DRS_PASS}" \
    --from-literal=decisionServiceManagerUsername="${CP4BA_INST_ADS_SECRETS_DRS_MGR_USER}" \
    --from-literal=decisionServiceManagerPassword="${CP4BA_INST_ADS_SECRETS_DRS_MGR_PASS}" \
    --from-literal=decisionRuntimeMonitorUsername="${CP4BA_INST_ADS_SECRETS_DRS_MON_USER}" \
    --from-literal=decisionRuntimeMonitorPassword="${CP4BA_INST_ADS_SECRETS_DRS_MON_PASS}" \
    --from-literal=deploymentSpaceManagerUsername="${CP4BA_INST_ADS_SECRETS_DEPL_MGR_USER}" \
    --from-literal=deploymentSpaceManagerPassword="${CP4BA_INST_ADS_SECRETS_DEPL_MGR_PASS}" \
    --from-literal=encryptionKeys="{\"activeKey\":\"key1\",\"secretKeyList\":[{\"secretKeyId\":\"key1\",\"value\":\"123344566745435\"},{\"secretKeyId\":\"key2\",\"value\":\"987766544365675\"}]}" \
    --from-literal=sslKeystorePassword="averymuchlongpasswordtobecompliantwithfips" 2> /dev/null 1> /dev/null
  if [[ $? -gt 0 ]]; then
    _ERROR=1
    log_error "${_CLR_RED}Secret ibm-dba-ads-runtime-secret NOT created (verify 'username/password' for secret) !!!${_CLR_NC}"
  fi

  log_debug "Secret '${_CLR_YELLOW}ibm-dba-ads-mongo-secret${_CLR_NC}'"
  oc delete secret -n ${CP4BA_INST_NAMESPACE} ibm-dba-ads-mongo-secret 2> /dev/null 1> /dev/null
  if [[ ! -z "${CP4BA_INST_ADS_SECRETS_MONGO_USER}" ]] && [[ ! -z "${CP4BA_INST_ADS_SECRETS_MONGO_PASS}" ]]; then
    oc delete secret -n ${CP4BA_INST_NAMESPACE} ibm-dba-ads-mongo-secret 2> /dev/null 1> /dev/null
    oc create secret -n ${CP4BA_INST_NAMESPACE} generic ibm-dba-ads-mongo-secret \
      --from-literal=mongoUser="${CP4BA_INST_ADS_SECRETS_MONGO_USER}" \
      --from-literal=mongoPassword="${CP4BA_INST_ADS_SECRETS_MONGO_PASS}" 2> /dev/null 1> /dev/null
    if [[ $? -gt 0 ]]; then
      _ERROR=1
      log_error "${_CLR_RED}Secret ibm-dba-ads-mongo-secret NOT created (verify 'username/password' for secret) !!!${_CLR_NC}"
    fi
  fi

}

#--------------------------------------------------------------
# get certificate from remote url
# $1: url:port
# $2: cert name
# $3: output file
getCertificate () {

  log_info "${_CLR_GREEN}Getting certificate from: $1"  
  _FILE_TMP="${_INST_TMP_FOLDER}/cp4ba-ads-cert-$USER-$RANDOM"
  openssl s_client -showcerts -connect $1 < /dev/null 2>/dev/null | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > ${_FILE_TMP}
  
  echo "  $2: |" >> $3
  while IFS= read -r line
  do
    echo "    $line" >> $3
  done < "${_FILE_TMP}"

  rm ${_FILE_TMP}
}

#--------------------------------------------------------------
grabCertificates () {

  _CFGMAP_FILE_TMP="${_INST_TMP_FOLDER}/cp4ba-ads-cfgmap-$USER-$RANDOM"

echo "
apiVersion: v1
kind: ConfigMap
metadata:
  name: ${CP4BA_INST_ADS_TLS_CERTS_CFGMAP_NAME}
  namespace: ${CP4BA_INST_NAMESPACE}
  labels:
    ads-trusted-certs: runtime
data:
" > ${_CFGMAP_FILE_TMP}

  for i in {1..10}
  do
    __URL="CP4BA_INST_ADS_HOST_PORT_TRUSTED_EP_$i"
    __CRT="CP4BA_INST_ADS_CERT_NAME_TRUSTED_EP_$i"
    _URL=${!__URL}
    _CRT=${!__CRT}
    if [[ ! -z "${_URL}" ]]; then
      getCertificate ${_URL} ${_CRT} ${_CFGMAP_FILE_TMP}
    fi
  done

  _ALREADY_SET=$(oc get cm --no-headers ${CP4BA_INST_ADS_TLS_CERTS_CFGMAP_NAME} -n ${CP4BA_INST_NAMESPACE} 2>/dev/null | wc -l)
  if [[ "${_ALREADY_SET}" == "1" ]]; then
    oc delete cm ${CP4BA_INST_ADS_TLS_CERTS_CFGMAP_NAME} -n ${CP4BA_INST_NAMESPACE} 2>/dev/null
  fi
  oc create -f ${_CFGMAP_FILE_TMP} 2>/dev/null 1>/dev/null
  rm ${_CFGMAP_FILE_TMP}
}

#-------------------------------
createConfigMapADS() {
  log_debug "ConfigMap '${_CLR_YELLOW}${CP4BA_INST_ADS_TLS_CERTS_CFGMAP_NAME}${_CLR_NC}'"
  grabCertificates
}

_createConfigMapBts() {

_CM_NAME="ibm-bts-config-extension"
log_debug "ConfigMap '${_CLR_YELLOW}${_CM_NAME}${_CLR_NC}'"
oc delete cm -n ${CP4BA_INST_NAMESPACE} ${_CM_NAME} 2>/dev/null 1>/dev/null

cat <<EOF | oc apply -f - 2>/dev/null 1>/dev/null
apiVersion: v1
kind: ConfigMap
metadata:
  name: "${_CM_NAME}"
  namespace: "${CP4BA_INST_NAMESPACE}"
  labels:
    cp4ba.ibm.com/backup-type: mandatory
data:
  serverName: "${CP4BA_INST_DB_1_SERVER_NAME_SSL}"
  portNumber: "${CP4BA_INST_DB_SERVER_PORT}"
  databaseName: bts
  ssl: "true"
  sslMode: verify-ca
  sslSecretName: bts-datastore-edb-secret
  customPropertyName1: sslKey
  customPropertyValue1: "/opt/ibm/wlp/usr/shared/resources/security/db/tls.key"
  customPropertyName2: user
  customPropertyValue2: "${CP4BA_INST_DB_BTS_USER}"
EOF

}

_createConfigMapIm() {

_CM_NAME="im-datastore-edb-cm"
log_debug "ConfigMap '${_CLR_YELLOW}${_CM_NAME}${_CLR_NC}'"
oc delete cm -n ${CP4BA_INST_NAMESPACE} ${_CM_NAME} 2>/dev/null 1>/dev/null

cat <<EOF | oc apply -f - 2>/dev/null 1>/dev/null
apiVersion: v1
kind: ConfigMap
metadata:
  name: "${_CM_NAME}"
  namespace: "${CP4BA_INST_NAMESPACE}"
  labels:
    cp4ba.ibm.com/backup-type: mandatory
data:
  IS_EMBEDDED: "false"
  DATABASE_USER: "${CP4BA_INST_DB_IM_USER}"
  DATABASE_NAME: im
  DATABASE_PORT: "${CP4BA_INST_DB_SERVER_PORT}"
  DATABASE_R_ENDPOINT: "${CP4BA_INST_DB_1_SERVER_NAME_SSL}"
  DATABASE_RW_ENDPOINT: "${CP4BA_INST_DB_1_SERVER_NAME_SSL}"
  DATABASE_ENABLE_SSL: "true"
  DATABASE_CA_CERT: ca.crt
  DATABASE_CLIENT_CERT: tls.crt
  DATABASE_CLIENT_KEY: tls.key
EOF

# ??????????
#apiVersion: operator.ibm.com/v1alpha1
#kind: OperandRequest
#metadata:
#  name: common-service
#  namespace: $<your-foundational-services-namespace>
#spec:
#  requests:
#    - operands:
#        - name: ibm-im-operator
#        - name: ibm-events-operator
#        - name: ibm-platformui-operator
#        - name: cloud-native-postgresql
#      registry: common-service
#      registryNamespace: $<your-foundational-services-namespace>
 
}

_createConfigMapZen() {

_CM_NAME="ibm-zen-metastore-edb-cm"
log_debug "ConfigMap '${_CLR_YELLOW}${_CM_NAME}${_CLR_NC}'"
oc delete cm -n ${CP4BA_INST_NAMESPACE} ${_CM_NAME} 2>/dev/null 1>/dev/null

cat <<EOF | oc apply -f - 2>/dev/null 1>/dev/null
apiVersion: v1
kind: ConfigMap
metadata:
  name: "${_CM_NAME}"
  namespace: "${CP4BA_INST_NAMESPACE}"
  labels:
    cp4ba.ibm.com/backup-type: mandatory
data:
  IS_EMBEDDED: "false"
  DATABASE_USER: "${CP4BA_INST_DB_ZEN_USER}"
  DATABASE_NAME: zen
  DATABASE_PORT: "${CP4BA_INST_DB_SERVER_PORT}"
  DATABASE_R_ENDPOINT: "${CP4BA_INST_DB_1_SERVER_NAME_SSL}"
  DATABASE_RW_ENDPOINT: "${CP4BA_INST_DB_1_SERVER_NAME_SSL}"
  DATABASE_SCHEMA: public
  DATABASE_MONITORING_SCHEMA: watchdog
  DATABASE_ENABLE_SSL: "true"
  DATABASE_CA_CERT: ca.crt
  DATABASE_CLIENT_CERT: tls.crt
  DATABASE_CLIENT_KEY: tls.key
  DATABASE_SSL_MODE: require 
EOF
}

createConfigMapBtsImZenForExternalDBs() {
  # https://www.ibm.com/docs/en/cloud-paks/foundational-services/4.x_cd?topic=management-configuring-external-postgresql-database-im

  if [[ "${CP4BA_INST_DB_USE_EDB}" = "false" ]]; then
    log_info "${_CLR_GREEN}Creating config maps for BTS, IM, ZEN external Postgres database${_CLR_NC}"

    _createConfigMapBts
    _createConfigMapIm
    _createConfigMapZen

  fi
}

createSecretBAML () {

#---------------------------------------------

  _SECRET_NAME="${CP4BA_INST_CR_NAME}-ibm-mls-itp-admin-secret"
  log_debug "Secret '${_CLR_YELLOW}${_SECRET_NAME}${_CLR_NC}'"
  oc delete secret -n ${CP4BA_INST_NAMESPACE} ${_SECRET_NAME} 2> /dev/null 1> /dev/null
  oc create secret -n ${CP4BA_INST_NAMESPACE} generic ${_SECRET_NAME} \
    --from-literal=adminUsername="${CP4BA_INST_PAKBA_ADMIN_USER}" \
    --from-literal=adminPassword="${CP4BA_INST_PAKBA_ADMIN_PWD}" 2> /dev/null 1> /dev/null
  if [[ $_ERR -gt 0 ]]; then
    _ERROR=1
    log_error "${_CLR_RED}Secret ${_SECRET_NAME} NOT created (verify 'username/password' for secret) !!!${_CLR_NC}"
  fi

#---------------------------------------------

  _SECRET_NAME="${CP4BA_INST_CR_NAME}-ibm-mls-wfi-admin-secret"
  log_debug "Secret '${_CLR_YELLOW}${_SECRET_NAME}${_CLR_NC}'"
  oc delete secret -n ${CP4BA_INST_NAMESPACE} ${_SECRET_NAME} 2> /dev/null 1> /dev/null
  oc create secret -n ${CP4BA_INST_NAMESPACE} generic ${_SECRET_NAME} \
    --from-literal=adminUsername="${CP4BA_INST_PAKBA_ADMIN_USER}" \
    --from-literal=adminPassword="${CP4BA_INST_PAKBA_ADMIN_PWD}" 2> /dev/null 1> /dev/null
  if [[ $_ERR -gt 0 ]]; then
    _ERROR=1
    log_error "${_CLR_RED}Secret ${_SECRET_NAME} NOT created (verify 'username/password' for secret) !!!${_CLR_NC}"
  fi

#---------------------------------------------
# empty values, to let the 'insights' installation progress
##  _SECRET_NAME="${CP4BA_INST_BAI_BPC_WORKFORCE_SECRET}"
##  log_debug "Secret '${_CLR_YELLOW}${_SECRET_NAME}${_CLR_NC}'"
##  oc delete secret -n ${CP4BA_INST_NAMESPACE} ${_SECRET_NAME} 2> /dev/null 1> /dev/null
##  oc create secret -n ${CP4BA_INST_NAMESPACE} generic ${_SECRET_NAME} \
##    --from-literal=bpmSystemId="to-be-defined" \
##    --from-literal=url="https://to-be-defined" \
##    --from-literal=adminUsername="to-be-defined" \
##    --from-literal=adminPassword="to-be-defined" 2> /dev/null 1> /dev/null
##  if [[ $_ERR -gt 0 ]]; then
##    _ERROR=1
##    log_error "${_CLR_RED}Secret ${_SECRET_NAME} NOT created (verify 'username/password' for secret) !!!${_CLR_NC}"
##  fi

  # this secret contains fake server address not known at this time, will be updated later by cp4ba-configure-bai-workforce.sh 
  oc delete secret -n ${CP4BA_INST_NAMESPACE} ${_SECRET_NAME} 2> /dev/null 1> /dev/null
  _BAI_WKF_TMP="${_INST_TMP_FOLDER}/cp4ba-bai-wkf-secret-$USER-$RANDOM"
echo "apiVersion: v1
kind: Secret
metadata:
  name: ${CP4BA_INST_BAI_BPC_WORKFORCE_SECRET}
  namespace: ${CP4BA_INST_NAMESPACE}
stringData:
  workforce-insights-configuration.yml: |-
    - bpmSystemId: 0
      url: 'https://127.0.0.1'
      username: ${CP4BA_INST_PAKBA_ADMIN_USER}
      password: ${CP4BA_INST_PAKBA_ADMIN_PWD}
" > ${_BAI_WKF_TMP}
    log_debug "Secret '${_CLR_YELLOW}${CP4BA_INST_BAI_BPC_WORKFORCE_SECRET}${_CLR_NC}'"
  oc create secret generic -n ${CP4BA_INST_NAMESPACE} ${CP4BA_INST_BAI_BPC_WORKFORCE_SECRET} --from-file=workforce-insights-configuration.yml=${_BAI_WKF_TMP} 2>/dev/null 1>/dev/null
  if [[ $_ERR -gt 0 ]]; then
    _ERROR=1
    log_error "${_CLR_RED}Secret ${_SECRET_NAME} NOT created !!!${_CLR_NC}"
  fi
  rm ${_BAI_WKF_TMP} 2>/dev/null 1>/dev/null

} 

createSecretAdminRegistry () {

  if [[ ! -z "${CP4BA_AUTO_ENTITLEMENT_KEY}" ]]; then
    _SECRET_NAME="admin.registrykey"
    log_debug "Secret '${_CLR_YELLOW}${_SECRET_NAME}${_CLR_NC}'"
    oc delete secret -n ${CP4BA_INST_NAMESPACE} ${_SECRET_NAME} 2> /dev/null 1> /dev/null
    oc create secret -n ${CP4BA_INST_NAMESPACE} docker-registry ${_SECRET_NAME} \
      --docker-server=cp.icr.io \
      --docker-username=cp \
      --docker-password="${CP4BA_AUTO_ENTITLEMENT_KEY}" 2> /dev/null 1> /dev/null
    if [[ $_ERR -gt 0 ]]; then
      log_error "${_CLR_RED}Secret ${_SECRET_NAME} NOT created (verify 'cp.icr.io/cp/password' for secret) !!!${_CLR_NC}"
    fi
  else
    log_error "${_CLR_RED}Secret ${_SECRET_NAME} NOT created (verify 'CP4BA_AUTO_ENTITLEMENT_KEY' variable) !!!${_CLR_NC}"
  fi

}


#-------------------------------
createSecrets () {
  createSecretAdminRegistry

  if [[ "${CP4BA_INST_LDAP}" = "true" ]]; then
    createSecretLDAP
  fi
  createSecretBAN

  if [[ $CP4BA_INST_DB_INSTANCES -eq 0 ]]; then
    createSecretFNCMBpmOnly
  else
    if [[ -z "${CP4BA_INST_BAW_BPM_ONLY}" ]] || [[ "${CP4BA_INST_BAW_BPM_ONLY}" = "false" ]]; then
      createSecretFNCM
    else
      createSecretFNCMBpmOnly
    fi
  fi

  # ADS
  if [[ "${CP4BA_INST_ADS_SECRETS_CREATE}" = "true" ]]; then
    createSecretADS
    createConfigMapADS
  fi

  i=1
  _IDX_END=$CP4BA_INST_DB_INSTANCES
  while [[ $i -le $_IDX_END ]]
  do
    _INST_BAW="CP4BA_INST_BAW_$i"
    _INST="${!_INST_BAW}"
    if [[ "${_INST}" = "true" ]]; then
      _DB_SECRET="CP4BA_INST_BAW_"$i"_DB_SECRET"
      #_DB_USER="CP4BA_INST_BAW_"$i"_DB_USER"
      #_DB_PWD="CP4BA_INST_BAW_"$i"_DB_PWD"
      if [[ ! -z "${!_DB_SECRET}" ]]; then
        createSecretBAW ${!_DB_SECRET} ${CP4BA_INST_DB_BAW_USER} ${CP4BA_INST_DB_BAW_PWD} # ${!_DB_USER} ${!_DB_PWD}
      else
        log_error "${_CLR_RED}ERROR, env var '${_CLR_GREEN}${_DB_SECRET}${_CLR_RED}' not defined, verify CP4BA_INST_DB_INSTANCES and CP4BA_INST_BAW_* values.${_CLR_NC}"
      fi

      # WF Assistant
      _APIKEY="CP4BA_INST_BAW_"$i"_GENAI_WX_APIKEY"
      _PRJID="CP4BA_INST_BAW_"$i"_GENAI_WX_PRJ_ID"
      _URLPRVD="CP4BA_INST_BAW_"$i"_GENAI_WX_URL_PROVIDER"
      _WX_APIKEY=$(echo "${!_APIKEY}" | base64)
      _WX_PRJID=$(echo "${!_PRJID}" | base64)
      _WX_URL=$(echo "${!_URLPRVD}" | base64)

      createSecretWFAssistantBAW "${_WX_APIKEY}" "${_WX_PRJID}" "${_WX_URL}" 

    fi
    ((i = i + 1))
  done  

  createSecretBAS ${CP4BA_INST_DB_BAW_USER} ${CP4BA_INST_DB_BAW_PWD}

  createSecretAE

  createSecretBAML

  # External Postgres DBs 
  createConfigMapBtsImZenForExternalDBs

  if [[ $_ERROR = 1 ]]; then
    if [[ "${_SILENT}" = "false" ]]; then
      echo ""
      echo -e ">>> \x1b[5mWARNING\x1b[25m <<<"
      echo "Rerun this script after db setup."
      echo "" 
    fi
  fi

}

log_msg "=============================================================="
log_info "${_CLR_GREEN}Creating secrets in '${_CLR_YELLOW}${CP4BA_INST_NAMESPACE}${_CLR_GREEN}' namespace${_CLR_NC}"

setTemporaryFolder

createSecrets
