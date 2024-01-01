#!/bin/bash

_me=$(basename "$0")

CUR_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PARENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"

_CFG=""
_SCRIPTS=""
_CPAK_MGR=false
_CPAK_MGR_VER=""
_CPAK_MGR_FOLDER=""

_OK=0
_ERR_PKG_MGR=0

#--------------------------------------------------------
_CLR_RED="\033[0;31m"   #'0;31' is Red's ANSI color code
_CLR_GREEN="\033[0;32m"   #'0;32' is Green's ANSI color code
_CLR_YELLOW="\033[1;32m"   #'1;32' is Yellow's ANSI color code
_CLR_BLUE="\033[0;34m"   #'0;34' is Blue's ANSI color code
_CLR_NC="\033[0m"

# "\33[32m[✔] ${1}\33[0m"
# "\33[33m[✗] ${1}\33[0m"
# bold: echo -e "\x1B[1m${1}\x1B[0m\n"

#--------------------------------------------------------
# read command line params
while getopts c:p:s:v:d:m flag
do
    case "${flag}" in
        c) _CFG=${OPTARG};;
        p) _SCRIPTS=${OPTARG};;
        m) _CPAK_MGR=true;;
        v) _CPAK_MGR_VER=${OPTARG};;
        d) _CPAK_MGR_FOLDER=${OPTARG};;
    esac
done

usage () {
  echo ""
  echo -e "${_CLR_GREEN}usage: $_me
    -c full-path-to-config-file
       (eg: '../configs/env1.properties')
    -p cp4ba-case-pkg-scripts-folder [uses a previously installed CP4BA Case Manager, mutually exclusive with -m option]
       (eg: <full-path-to>/cert-kubernetes/scripts) 
    -m(optional flag) install-case-package-manager [if set install a fresh package manager]
    -v(optional) case-package-manager-version [install latest version if not set, see 'cp4ba-casemanager-setup' repository for further options]
       (eg: '5.1.0') 
    -d(optional) full-path-to-target-folder-for-case-package-manager [mandatory if -m is set, created if not exists]
       (eg: '~/tmp-cmgr')${_CLR_NC}"
}

if [[ -z "${_CFG}" ]]; then
  usage
  exit 1
fi

if [[ "${_CPAK_MGR}" = "false" ]] && [[ -z "${_SCRIPTS}" ]]; then
  usage
  exit 1
fi

if [[ ! -f "${_CFG}" ]]; then
  echo "Configuration file not found: "${_CFG}
    usage
  exit 1
fi

source ${_CFG}

if [[ "${CP4BA_INST_LDAP}" = "true" ]]; then
  if [[ ! -z "${CP4BA_INST_LDAP_CFG_FILE}" ]]; then
    if [[ ! -f "${CP4BA_INST_LDAP_CFG_FILE}" ]]; then
      echo "LDAP configuration file not found: "${CP4BA_INST_LDAP_CFG_FILE}
      usage
      exit 1
    fi
    source ${CP4BA_INST_LDAP_CFG_FILE}
  fi
fi

if [[ "${CP4BA_INST_IAM}" = "true" ]]; then
  if [[ ! -z "${CP4BA_INST_IDP_CFG_FILE}" ]]; then
    if [[ ! -f "${CP4BA_INST_IDP_CFG_FILE}" ]]; then
      echo "IDP configuration file not found: "${CP4BA_INST_IDP_CFG_FILE}
      usage
      exit 1
    fi
    source ${CP4BA_INST_IDP_CFG_FILE}
  fi
fi

#-------------------------------
checkPrepreqTools () {
  which jq &>/dev/null
  if [[ $? -ne 0 ]]; then
    echo -e "${_CLR_RED}[✗] Error, jq not installed, cannot proceed.${_CLR_NC}"
    exit 1
  fi
  which openssl &>/dev/null
  if [[ $? -ne 0 ]]; then
    echo -e "${_CLR_YELLOW}[✗] Warning, openssl not installed, some activities may fail.${_CLR_NC}"
  fi
}

onboardUsers () {

  if [[ "${CP4BA_INST_LDAP}" = "true" ]]; then
    if [[ -z "${CP4BA_INST_LDAP_CFG_FILE}" ]]; then
      echo -e "${_CLR_RED}Error, LDAP configuration file value not set for '${_CLR_YELLOW}${_INST_ENV_FULL_PATH}${_CLR_RED}'${_CLR_NC}"
      exit 1
    fi
    if [[ ! -f "${CP4BA_INST_LDAP_CFG_FILE}" ]]; then
      echo -e "${_CLR_RED}Error, LDAP configuration file not not found for '${_CLR_YELLOW}${_INST_ENV_FULL_PATH}${_CLR_RED}'${_CLR_NC}"
      exit 1
    fi

    if [[ -z "${CP4BA_INST_IDP_CFG_FILE}" ]]; then
      echo -e "${_CLR_RED}Error, IDP configuration file value not set for '${_CLR_YELLOW}${_INST_ENV_FULL_PATH}${_CLR_RED}'${_CLR_NC}"
      exit 1
    fi
    if [[ ! -f "${CP4BA_INST_IDP_CFG_FILE}" ]]; then
      echo -e "${_CLR_RED}Error, LDAP configuration file not not found for '${_CLR_YELLOW}${_INST_ENV_FULL_PATH}${_CLR_RED}'${_CLR_NC}"
      exit 1
    fi
  fi

  source ${CP4BA_INST_LDAP_CFG_FILE}
  source ${CP4BA_INST_IDP_CFG_FILE} 
  echo -e "=============================================================="
  echo -e "${_CLR_GREEN}CP4BA Onboarding users${_CLR_NC}"

  # !!! cp4admin perde ruoli Automation Administrator, Automation Developer se remove-and-add
  ${CP4BA_INST_LDAP_TOOLS_FOLDER}/onboard-users.sh -p ${CP4BA_INST_IDP_CFG_FILE} -l ${CP4BA_INST_LDAP_CFG_FILE} -n ${CP4BA_INST_SUPPORT_NAMESPACE} -s -o add
}

installAndVerifyCasePkgMgr () {
  if [[ "${_CPAK_MGR}" = "true" ]] && [[ ! -z "${_CPAK_MGR_FOLDER}" ]]; then
    mkdir -p ${_CPAK_MGR_FOLDER}
    _USE_VER=""
    if [[ ! -z "${_CPAK_MGR_VER}" ]]; then
      _USE_VER=" -v ${_CPAK_MGR_VER}"
    fi
    ${CP4BA_INST_CMGR_TOOLS_FOLDER}/cp4ba-casemgr-install.sh -r -d ${_CPAK_MGR_FOLDER} ${_USE_VER}
    if [[ $? -gt 0 ]]; then
      _ERR_PKG_MGR=1
    else
      if [[ -z "${_CPAK_MGR_VER}" ]]; then
        _CPAK_MGR_VER=$(find ${_CPAK_MGR_FOLDER} -maxdepth 1 -type d | sort -r | head -n 1 | sed 's/.*\/ibm-cp-automation-//g')
      fi
      _SCRIPTS=${_CPAK_MGR_FOLDER}"/ibm-cp-automation-${_CPAK_MGR_VER}/ibm-cp-automation/inventory/cp4aOperatorSdk/files/deploy/crs/cert-kubernetes/scripts"
    fi
  fi
  if [[ $_ERR_PKG_MGR -eq 0 ]]; then
    if [[ ! -d "${_SCRIPTS}" ]]; then
      echo "Scripts folder not found: "${_SCRIPTS}
      usage
      exit 1
    fi
    if [[ ! -f "${_SCRIPTS}/cp4a-clusteradmin-setup.sh" ]]; then
      echo "Script 'cp4a-clusteradmin-setup.sh' not found in folder: "${_SCRIPTS}
      usage
      exit 1
    fi
  fi
}

echo ""
echo -e "${_CLR_YELLOW}***********************************************************************"
echo -e "Install CP4BA complete environment in namespace '${_CLR_GREEN}${CP4BA_INST_NAMESPACE}${_CLR_YELLOW}'"
echo -e "  started at ${_CLR_GREEN}"$(date)"${_CLR_YELLOW}"
echo -e "***********************************************************************${_CLR_NC}"

checkPrepreqTools

# verify logged in OCP
oc project 2>/dev/null 1>/dev/null
if [ $? -gt 0 ]; then
  echo -e "\x1B[1;31mNot logged in to OCP cluster. Please login to an OCP cluster and rerun this command. \x1B[0m" && exit 1
fi

START_SECONDS=$SECONDS

installAndVerifyCasePkgMgr
if [[ $_ERR_PKG_MGR -eq 0 ]]; then
  ./cp4ba-install-operators.sh -c ${_CFG} -s ${_SCRIPTS}
  if [[ $? -eq 0 ]]; then
    ./cp4ba-deploy-env.sh -c ${_CFG} -l ${CP4BA_INST_LDAP_CFG_FILE}
    if [[ $? -eq 0 ]]; then
      if [[ "${CP4BA_INST_IAM}" = "true" ]]; then
        onboardUsers
      fi
      _OK=1
    fi
  fi
fi

STOP_SECONDS=$SECONDS

if [[ "${_OK}" = "0" ]]; then
  echo ""
  echo -e "${_CLR_RED}[✗] Installation error, environment '${_CLR_YELLOW}${CP4BA_INST_ENV}${_CLR_RED}' not installed !!!${_CLR_NC}"
  echo "Verify the configuration and/or run parameters."
  echo "If the installation was started and subsequently interrupted it is recommended to remove the entire namespace"
  echo "using the 'remove-cp4ba' tool."
  echo "See link https://github.com/marcoantonioni/cp4ba-utilities"
else
  ELAPSED_SECONDS=$(( STOP_SECONDS - START_SECONDS ))
  TOT_MINUTES=$(($ELAPSED_SECONDS / 60))
  TOT_SECONDS=$(($ELAPSED_SECONDS % 60))

  _CASE_INIT_ERRORS=0
  _PENDING=$(oc get pods -n ${CP4BA_INST_NAMESPACE} 2>/dev/null | grep Pending | wc -l)
  if [[ -z "${CP4BA_INST_BAW_BPM_ONLY}" ]] || [[ "${CP4BA_INST_BAW_BPM_ONLY}" = "false" ]]; then
    _CASE_INIT_ERRORS=$(oc logs -n ${CP4BA_INST_NAMESPACE} $(oc get pods -n ${CP4BA_INST_NAMESPACE} | grep case-init-job  | awk '{print $1}') | egrep "SEVERE|Exception" | wc -l)
  fi
  echo -e "${_CLR_YELLOW}***********************************************************************"
  echo -e "${_CLR_GREEN}[✔] Installation completed successfully for environment '${_CLR_YELLOW}${CP4BA_INST_ENV}${_CLR_GREEN}' !!!${_CLR_NC}"
  echo -e "  terminated at ${_CLR_GREEN}"$(date)"${_CLR_NC}, total installation time "${TOT_MINUTES}" minutes and "${TOT_SECONDS}" seconds."
  if [[ $_PENDING -gt 0 ]]; then
    echo -e "\x1B[1mPlease note\x1B[0m, some pods may be not yet ready. Check before using the system."
    oc get pods -n ${CP4BA_INST_NAMESPACE} | grep Pending
    echo "For pod status run manually: oc get pods -n ${CP4BA_INST_NAMESPACE} | grep Pending"
  fi
  if [[ -z "${CP4BA_INST_BAW_BPM_ONLY}" ]] || [[ "${CP4BA_INST_BAW_BPM_ONLY}" = "false" ]]; then
    if [[ $_CASE_INIT_ERRORS -gt 0 ]]; then
      echo -e "\x1B[1mPlease note\x1B[0m, some errors in Case initialization. May be a transient problem."
      echo ""
      oc logs -n ${CP4BA_INST_NAMESPACE} $(oc get pods -n ${CP4BA_INST_NAMESPACE} | grep case-init-job  | awk '{print $1}') | egrep "SEVERE|Exception"
      echo ""
    if [[ -z "${CP4BA_INST_BAW_BPM_ONLY}" ]] || [[ "${CP4BA_INST_BAW_BPM_ONLY}" = "false" ]]; then
      echo "For Case initialization log/status/errors run manually:"
      echo "  logs   : oc logs -n \${CP4BA_INST_NAMESPACE} \$(oc get pods -n \${CP4BA_INST_NAMESPACE} | grep case-init-job  | awk '{print \$1}')"
      echo "  errors : oc logs -n \${CP4BA_INST_NAMESPACE} \$(oc get pods -n \${CP4BA_INST_NAMESPACE} | grep case-init-job  | awk '{print \$1}') | egrep \"SEVERE|Exception\""
      echo "  success: oc logs -n \${CP4BA_INST_NAMESPACE} \$(oc get pods -n \${CP4BA_INST_NAMESPACE} | grep case-init-job  | awk '{print \$1}') | grep \"INFO: Configuration Completed\""
      echo -e "${_CLR_YELLOW}***********************************************************************${_CLR_NC}"
    fi
  fi

fi
