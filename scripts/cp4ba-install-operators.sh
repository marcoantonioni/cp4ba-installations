#!/bin/bash

#set -euo pipefail


_me=$(basename "$0")

_CFG=""
_SCRIPTS=""

#--------------------------------------------------------
_CLR_RED="\033[0;31m"   #'0;31' is Red's ANSI color code
_CLR_GREEN="\033[0;32m"   #'0;32' is Green's ANSI color code
_CLR_YELLOW="\033[1;33m"   #'1;32' is Yellow's ANSI color code
_CLR_BLUE="\033[0;34m"   #'0;34' is Blue's ANSI color code
_CLR_NC="\033[0m"


#--------------------------------------------------------
# read command line params
while getopts c:s: flag
do
    case "${flag}" in
        c) _CFG=${OPTARG};;
        s) _SCRIPTS=${OPTARG};;
    esac
done

usage () {
  echo ""
  echo "${_CLR_GREEN}usage: $_me
    -c full-path-to-config-file
       (eg: '../configs/env1.properties')
    -s full-path-to-folder-for-case-package-manager${_CLR_NC}"
}

if [[ -z "${_CFG}" ]]; then
  echo "Configuration file name empty"
  usage
  exit 1
fi

if [[ ! -f "${_CFG}" ]]; then
  echo "Configuration file not found: "${_CFG}
  usage
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


#-------------------------------
checkPrereqTools () {
  which jq &>/dev/null
  if [[ $? -ne 0 ]]; then
    log_error "${_CLR_RED}[✗] Error, jq not installed, cannot proceed.${_CLR_NC}"
    exit 1
  fi
  which openssl &>/dev/null
  if [[ $? -ne 0 ]]; then
    log_warning "${_CLR_YELLOW}[✗] Warning, openssl not installed, some activities may fail.${_CLR_NC}"
  fi
}

#-------------------------------
storageClassExist () {
    if [ $(oc get sc $1 2>/dev/null | grep $1 | wc -l) -lt 1 ];
    then
        return 0
    fi
    return 1
}

checkPrereqVars () {
  _OK_VARS=1
  if [[ -z "${CP4BA_AUTO_CLUSTER_USER}" ]]; then
    log_error "${_CLR_RED}[✗] var CP4BA_AUTO_CLUSTER_USER not set, export it in your bash shell and rerun.${_CLR_NC}"
    _OK_VARS=0
  fi

  if [[ -z "${CP4BA_AUTO_ENTITLEMENT_KEY}" ]]; then
    log_error "${_CLR_RED}[✗] var CP4BA_AUTO_ENTITLEMENT_KEY not set, export it in your bash shell and rerun.${_CLR_NC}"
    _OK_VARS=0
  fi

  if [[ -z "${CP4BA_INST_TYPE}" ]]; then
    log_error "${_CLR_RED}[✗] var CP4BA_INST_TYPE not set, update your configuration file and rerun.${_CLR_NC}"
    _OK_VARS=0
  else
    if [[ "${CP4BA_INST_TYPE}" != "starter" ]] && [[ "${CP4BA_INST_TYPE}" != "production" ]]; then
      log_error "${_CLR_RED}[✗] var CP4BA_INST_TYPE must be 'starter' or 'production', update your configuration file and rerun.${_CLR_NC}"
      _OK_VARS=0
    fi
  fi

  if [[ -z "${CP4BA_INST_PLATFORM}" ]]; then
    log_error "${_CLR_RED}[✗] var CP4BA_INST_PLATFORM not set, update your configuration file and rerun.${_CLR_NC}"
    _OK_VARS=0
  else
    if [[ "${CP4BA_INST_PLATFORM}" != "OCP" ]] && [[ "${CP4BA_INST_PLATFORM}" != "ROKS" ]]; then
      log_error "${_CLR_RED}[✗] var CP4BA_INST_PLATFORM must be 'OCP' or 'ROKS', update your configuration file and rerun.${_CLR_NC}"
      _OK_VARS=0
    fi
  fi

  if [[ -z "${CP4BA_INST_SC_FILE}" ]]; then
    log_error "${_CLR_RED}[✗] Storage class '${CP4BA_INST_SC_FILE}' not found in your OCP cluster, update your configuration file and rerun.${_CLR_NC}"
    _OK_VARS=0
  fi

  storageClassExist ${CP4BA_INST_SC_FILE}
  if [ $? -eq 0 ]; then
    log_error "${_CLR_RED}[✗] Storage class '${CP4BA_INST_SC_FILE}' not present in your OCP cluster${_CLR_NC}"
    _OK_VARS=0
  fi

  storageClassExist ${CP4BA_INST_SC_BLOCK}
  if [ $? -eq 0 ]; then
    log_error "${_CLR_RED}[✗] Storage class '${CP4BA_INST_SC_BLOCK}' not present in your OCP cluster${_CLR_NC}"
    _OK_VARS=0
  fi


  if [ $_OK_VARS -eq 0 ]; then
    exit 1
  fi

  export CP4BA_AUTO_STORAGE_CLASS_FAST_ROKS="${CP4BA_INST_SC_FILE}"
  export CP4BA_AUTO_STORAGE_CLASS_OCP="${CP4BA_INST_SC_FILE}"
  export CP4BA_AUTO_DEPLOYMENT_TYPE="${CP4BA_INST_TYPE}"
  export CP4BA_AUTO_PLATFORM="${CP4BA_INST_PLATFORM}"
  export CP4BA_AUTO_ACCEPT_LICENSE="Yes"


}

executeClusterAdminSetup () {
  if [[ -z "${CP4BA_INST_CLUSTERADMIN_RETRIES}" ]]; then
    export CP4BA_INST_CLUSTERADMIN_RETRIES=2
  else
    _error=1
    if [[ $CP4BA_INST_CLUSTERADMIN_RETRIES =~ ^[+-]?[0-9]+\.$ ]]; then
      _error=1

    elif [[ $CP4BA_INST_CLUSTERADMIN_RETRIES =~ ^[+-]?[0-9]+$ ]]; then
      _error=0

    elif [[ $CP4BA_INST_CLUSTERADMIN_RETRIES =~ ^[+-]?[0-9]+\.?[0-9]*$ ]]; then
      _error=1
    fi
    if [[ $_error -eq 1 ]]; then
      log_error "Value of 'CP4BA_INST_CLUSTERADMIN_RETRIES' is not a number -> '$CP4BA_INST_CLUSTERADMIN_RETRIES'" 
      exit 1 
    fi  
  fi
  if [[ $CP4BA_INST_CLUSTERADMIN_RETRIES -lt 1 ]]; then
    export CP4BA_INST_CLUSTERADMIN_RETRIES=2
  fi

  log_info "${_CLR_GREEN}Running cluster admin setup with '${_CLR_YELLOW}${CP4BA_INST_CLUSTERADMIN_RETRIES}${_CLR_GREEN}' retries"

  log_info "Executing '${_CLR_YELLOW}cp4a-clusteradmin-setup.sh${_CLR_NC}' script for namespace '${_CLR_YELLOW}${CP4BA_INST_NAMESPACE}${_CLR_NC}' (this operation can take 10 minutes or more)"
  _ACT_DIR=$(pwd)

  # change folder (do not use $_SCRIPT_DIR until: cd ${_ACT_DIR})
  cd ${_SCRIPTS}
  export CP4BA_AUTO_NAMESPACE="${CP4BA_INST_NAMESPACE}"
  
  _done=0
  _counter=1
  _error=0
  while [ $_counter -le $CP4BA_INST_CLUSTERADMIN_RETRIES ]; do

    /bin/bash ./cp4a-clusteradmin-setup.sh &> ./_clusteradmin.out
    _error=$?
    _counter=$((_counter + 1))
    if [ $_error -ne 0 ]; then
      log_warning "Timeout waiting CP4BA Operators readiness in namespace '${_CLR_YELLOW}${CP4BA_INST_NAMESPACE}${_CLR_NC}, try again [$_counter/$CP4BA_INST_CLUSTERADMIN_RETRIES]...'"
      sleep 1
    else
      _done=1
    fi

  done

  if [[ -f "./_clusteradmin.out" ]]; then
    cp ./_clusteradmin.out "${_ACT_DIR}/${CP4BA_INST_OUTPUT_FOLDER}/cp4ba-${CP4BA_INST_CR_NAME}-${CP4BA_INST_ENV}-clusteradmin.out"
  fi
  if [[ $_done -eq 0 ]]; then

    log_error "${_CLR_RED}*****************************************************************${_CLR_NC}"
    log_error "ERROR, output from '${_CLR_YELLOW}cp4a-clusteradmin-setup.sh${_CLR_NC}'"
    log_error "${_CLR_RED}*****************************************************************${_CLR_NC}"

    log_error "See: '${_CLR_RED}${CP4BA_INST_OUTPUT_FOLDER}/cp4ba-${CP4BA_INST_CR_NAME}-${CP4BA_INST_ENV}-clusteradmin.out${_CLR_RED}'${_CLR_NC}"
    log_error "${_CLR_RED}*****************************************************************${_CLR_NC}"

    log_warning "If you want retry more times the operator setup task set the following variable with numeric value then rerun the installation"
    log_warning "export CP4BA_INST_CLUSTERADMIN_RETRIES=3"
    log_warning "./cp4ba-install-operators.sh -c \$CONFIG_FILE"

  fi

  # change folder back to original location
  cd ${_ACT_DIR}

  return $_done
}

installOperators () {
  _INSTOP_START_SECONDS=$SECONDS

  checkPrereqTools
  checkPrereqVars

  # verify logged in OCP
  oc whoami 2>/dev/null 1>/dev/null
  if [ $? -gt 0 ]; then
    log_error "${_CLR_RED}Not logged in to OCP cluster. Please login to an OCP cluster and rerun this command. ${_CLR_NC}" 
    exit 1
  fi

  oc new-project ${CP4BA_INST_NAMESPACE} 2>/dev/null 1>/dev/null

cat << EOF | oc create -n ${CP4BA_INST_NAMESPACE} -f - 2>/dev/null 1>/dev/null
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ibm-cp4ba-anyuid
imagePullSecrets:
- name: 'ibm-entitlement-key'
EOF

  if [[ -z "${CP4BA_INST_ANYUID}" || "${CP4BA_INST_ANYUID}" = "true" ]]; then 
    oc adm policy add-scc-to-user anyuid -z ibm-cp4ba-anyuid -n ${CP4BA_INST_NAMESPACE} 2>/dev/null 1>/dev/null
    log_info "${_CLR_GREEN}Install ${_CLR_YELLOW}with${_CLR_GREEN} SCC anyuid${_CLR_NC}"
  else
    log_info "${_CLR_GREEN}Install ${_CLR_YELLOW}without${_CLR_GREEN} SCC anyuid${_CLR_NC}"
  fi

  # 20260519 Networkpolicies
  if [[ -z "${CP4BA_INST_NP_DEPLOY}" ]]; then
    export CP4BA_INST_NP_DEPLOY="false"
  fi
  if [[ "${CP4BA_INST_NP_DEPLOY}" = "true" ]]; then
    ${_SCRIPT_DIR}/cp4ba-create-networkpolicies.sh -c ${_CFG} 
  fi

  _OK="false"
  if [[ ! -z "${_SCRIPTS}" ]]; then
    if [[ -d "${_SCRIPTS}" ]]; then
      if [[ -f "${_SCRIPTS}/cp4a-clusteradmin-setup.sh" ]]; then
        executeClusterAdminSetup
        if [ $? -eq 1 ]; then
          _OK="true"
        fi
      fi
    fi
  fi

  if [[ "${_OK}" = "false" ]]; then
    log_error ">>> ${_CLR_RED}\x1b[5m[✗] ERROR\x1b[25m${_CLR_NC} <<< ${_CLR_RED}CP4BA Operators not installed.${_CLR_NC}"
    exit 1
  fi

  STOP_SECONDS=$SECONDS
  ELAPSED_SECONDS=$(( STOP_SECONDS - _INSTOP_START_SECONDS ))
  TOT_MINUTES=$(($ELAPSED_SECONDS / 60))
  TOT_SECONDS=$(($ELAPSED_SECONDS % 60))
  _MSG="CP4BA Operators installed at ${_CLR_GREEN}"$(date)"${_CLR_NC}, total installation time "${TOT_MINUTES}" minutes and "${TOT_SECONDS}" seconds."
  log_info "${_MSG}" 

}

log_msg "=============================================================="
log_info "Install CP4BA Operators in namespace '${_CLR_YELLOW}${CP4BA_INST_NAMESPACE}${_CLR_NC}'"

installOperators

exit 0