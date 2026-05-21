#!/bin/bash

#set -euo pipefail


_me=$(basename "$0")

_CFG=""

unset _NP_NAMES

#--------------------------------------------------------
_CLR_RED="\033[0;31m"   #'0;31' is Red's ANSI color code
_CLR_GREEN="\033[0;32m"   #'0;32' is Green's ANSI color code
_CLR_YELLOW="\033[1;33m"   #'1;32' is Yellow's ANSI color code
_CLR_BLUE="\033[0;34m"   #'0;34' is Blue's ANSI color code
_CLR_NC="\033[0m"


#--------------------------------------------------------
# read command line params
while getopts c:wgvf flag
do
    case "${flag}" in
        c) _CFG=${OPTARG};;
    esac
done

if [[ -z "${_CFG}" ]]; then
  echo "usage: $_me -c path-of-config-file"
  exit
fi

if [[ ! -f "${_CFG}" ]]; then
  echo "Configuration file not found: ${_CFG}"
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

_createNPNamesFromFolder () {

  if [[ -d "${CP4BA_INST_NP_FOLDER}" ]]; then
    for _FILE_PATH in "${CP4BA_INST_NP_FOLDER}"/*.y*ml; do
      _BASE_NAME=$(basename "${_FILE_PATH}")
      _DEST_FILE="${CP4BA_INST_OUTPUT_FOLDER}/${_BASE_NAME}"

      envsubst < ${_FILE_PATH} > ${_DEST_FILE}
      if [[ $? -ne 0 ]]; then
        log_warning "[✗] Error, Network policy CR '${_BASE_NAME}' not generated.${_CLR_NC}"
      fi
      _NP_NAMES+=("${_DEST_FILE}")
    done
  else
    log_warning "Folder '${CP4BA_INST_NP_FOLDER}' not found"
  fi
}

_createNPNamesFromVars () {
  _DB_CR_NAME_SUFFIX="1"

  i=1
  _IDX_END=${CP4BA_INST_DB_INSTANCES}
  while [[ true ]]
  do
    _INST_NP_TEMPLATE="CP4BA_INST_NP_TEMPLATE_$i"

    _NP_CR_NAME="${!_INST_NP_TEMPLATE}"

    if [[ -z "${_NP_CR_NAME}" ]]; then
      break
    fi

    if [[ -f "${_NP_CR_NAME}" ]]; then
      log_debug "Adding policy file '${_CLR_YELLOW}${_NP_CR_NAME}${_CLR_NC}' "

      _BASE_NAME=$(basename ${_NP_CR_NAME})
      _DEST_FILE="${CP4BA_INST_OUTPUT_FOLDER}/${CP4BA_INST_ENV}-$USER-$RANDOM-${_BASE_NAME}"

      envsubst < ${_NP_CR_NAME} > ${_DEST_FILE}
      if [[ $? -ne 0 ]]; then
        log_warning "${_CLR_RED}[✗] Error, Network policy CR '${_NP_CR_NAME}' not generated.${_CLR_NC}"
      fi
    else
      log_warning "Network policy template file not found: ${_NP_CR_NAME}"
    fi
    
    _NP_NAMES+=("${_DEST_FILE}")
 
    ((i = i + 1))
  done  
}

_createPolicy () {
  _POLICY_NAME="$1"
  log_info "${_CLR_GREEN}Creating policy '${_CLR_YELLOW}${_POLICY_NAME}${_CLR_GREEN}'"
  oc apply -f ${_POLICY_NAME} 2>/dev/null 1>/dev/null
  if [[ $? -ne 0 ]]; then
    log_warning "Error creating network policy '${_POLICY_NAME}'"
  fi
}

createPolicies () {
  if [[ "${CP4BA_INST_NP_SCAN_FOLDER}" = "true" ]]; then
    # crea array file in folder con estensione .yaml e .yml
    log_debug "Creating network policies from folder contents"
    _createNPNamesFromFolder
  else
    # crea array file da CP4BA_INST_NP_TEMPLATE_n
    log_debug "Creating network policies from environment variables"
    _createNPNamesFromVars
  fi

  for i in "${_NP_NAMES[@]}"; do
    _createPolicy "$i"
  done    
}

log_msg "==============================================================${_CLR_NC}"
# 20260519 Networkpolicies
if [[ -z "${CP4BA_INST_NP_DEPLOY}" ]]; then
  export CP4BA_INST_NP_DEPLOY="false"
fi
if [[ "${CP4BA_INST_NP_DEPLOY}" = "true" ]]; then
  log_info "${_CLR_GREEN}Creating network policies${_CLR_NC}"
  createPolicies 
else
  log_info "${_CLR_GREEN}Skipping creation of network policies${_CLR_NC}"
fi
