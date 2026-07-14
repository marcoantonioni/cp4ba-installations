#!/bin/bash

#set -euo pipefail

_me=$(basename "$0")

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
while getopts c: flag
do
    case "${flag}" in
        c) _CFG=${OPTARG};;
    esac
done

usage () {
  echo ""
  echo -e "${_CLR_GREEN}usage: $_me
    -c full-path-to-config-file${_CLR_NC}"
}

if [[ -z "${_CFG}" ]]; then
  usage
  exit 1
fi

if [[ ! -f "${_CFG}" ]]; then
  echo "[✗] Error, configuration file not found: "${_CFG}
  exit 1
fi

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

if [[ ! -f "$_SCRIPT_DIR/../../cp4ba-config-tune/scripts/cp4ba-create-custom-xml-secrets.sh" ]]; then
  echo "Error, config-tune package not found !"
  echo "Clone it alongside with other cp4ba-..."
  echo "use the command: git clone https://github.com/marcoantonioni/cp4ba-config-tune"
  exit 1
fi


if [[ -z "${_INST_TMP_FOLDER}" ]]; then
  export _INST_TMP_FOLDER="/tmp"
fi

#_FOLDER_CONFIGS="/home/marco/cp4ba-projects/cp4ba-installations/configs26"
#_FOLDER_TEMPLATES="/home/marco/cp4ba-projects/cp4ba-installations/templates26"

_FILE_PROPS=${_CFG}
#"env1-authoring-baw.properties"

_setDefaultValuesIfNotDefined () {

  if [[ -z "${CP4BA_INST_FNCM_LICENSE_TYPE}" ]]; then
    export CP4BA_INST_FNCM_LICENSE_TYPE="production"
  fi

  if [[ -z "${CP4BA_INST_BAW_LICENSE_TYPE}" ]]; then
    export CP4BA_INST_BAW_LICENSE_TYPE="production"
  fi

  if [[ -z "${CP4BA_INST_BAI_OBJECTSTORE_CONTENT_EVENT_ENABLED}" ]]; then
    export CP4BA_INST_BAI_OBJECTSTORE_CONTENT_EVENT_ENABLED=false
  fi

}


verifyConfigurationVariables () {
  _setDefaultValuesIfNotDefined

  source ${_FILE_PROPS} 2>/dev/null
  if [[ ! -z "${CP4BA_INST_LDAP_CFG_FILE}" ]]; then
    source ${CP4BA_INST_LDAP_CFG_FILE}
    source ${_FILE_PROPS} 2>/dev/null
  fi

  _FILE_YAML="${CP4BA_INST_CR_TEMPLATE}"

  _TMP_VAR_NAMES="${_INST_TMP_FOLDER}/cp4ba-undef-vars-$USER-$RANDOM"

  _ERRORS=0
  cat ../${CP4BA_INST_CR_TEMPLATE} | grep "\${" | awk '{$1=$1};1' | sed '/^#/d' | sed 's/^.*\(\${.*\}\).*$/\1/' | sort | uniq | sed 's/\${//g' | sed 's/\}//g' > ${_TMP_VAR_NAMES}
  _LIST_VARS=$(cat ${_TMP_VAR_NAMES})
  for _VAR_NAME in ${_LIST_VARS}
  do
    _VAR_VALUE=${!_VAR_NAME}
    if [[ "$_VAR_VALUE" = "" ]]; then
      log_error "Variable '$_VAR_NAME' not set."
      _ERRORS=$((_ERRORS + 1))
    fi
  done
  echo rm ${_TMP_VAR_NAMES}
  if [[ $_ERRORS -gt 0 ]]; then
    echo "Total errors $_ERRORS, verify property file '$_FILE_PROPS' for variables defined in '$CP4BA_INST_CR_TEMPLATE'"
    exit 1
  else
    echo "Configuration is OK for file '$_FILE_PROPS' / '$CP4BA_INST_CR_TEMPLATE'"
  fi
  
}

verifyConfigurationVariables
exit 0


