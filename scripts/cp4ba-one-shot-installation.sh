#!/bin/bash

_me=$(basename "$0")

CUR_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PARENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"

_CFG=""
_SCRIPTS=""
_TEST_CFG=false
_CPAK_MGR=false
_CPAK_MGR_VER=""
_CPAK_MGR_FOLDER=""
_CPAK_MGR_FOLDER_REMOVE=false
_RELEASE_BASE=""
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
# bold: echo -e "\x1B[1m${1}${_CLR_NC}\n"

usage () {
  echo ""
  echo -e "${_CLR_GREEN}usage: $_me
    -c full-path-to-config-file
       (eg: '../configs/env1.properties')
    -t [test the configuration and exit]
    -p cp4ba-case-pkg-scripts-folder [uses a previously installed CP4BA Case Manager, mutually exclusive with -m option]
       (eg: <full-path-to>/cert-kubernetes/scripts) 
    -m(optional flag) install-case-package-manager [if set install a fresh package manager]
    -v(optional) case-package-manager-version [install latest version if not set, see 'cp4ba-casemanager-setup' repository for further options]
       (eg: '5.1.0') 
    -d(optional) full-path-to-target-folder-for-case-package-manager [mandatory if -m is set, created if not exists]
       (eg: '/tmp/my-cmgr')${_CLR_NC}"
}


#--------------------------------------------------------
# read command line params
while getopts c:p:s:v:d:mt flag
do
    case "${flag}" in
        c) _CFG=${OPTARG};;
        p) _SCRIPTS=${OPTARG};;
        m) _CPAK_MGR=true;;
        v) _CPAK_MGR_VER=${OPTARG};;
        d) _CPAK_MGR_FOLDER=${OPTARG};;
        t) _TEST_CFG=true;;
        \?) # Invalid option
            usage
            exit 1;;        
    esac
done

if [[ -z "${_CFG}" ]]; then
  usage
  exit 1
fi

if [[ ! -f "${_CFG}" ]]; then
  echo "Configuration file not found: "${_CFG}
    usage
  exit 1
fi

source ${_CFG}

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

testConfiguration () {
  echo "testConfiguration not yet implemented!"
}

if [[ "${_TEST_CFG}" = "true" ]]; then
  checkPrepreqTools
  testConfiguration
  exit 0
fi

if [[ "${_CPAK_MGR}" = "false" ]] && [[ -z "${_SCRIPTS}" ]]; then
  usage
  exit 1
fi

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
  if [[ -z "${_CPAK_MGR_FOLDER}" ]]; then
    _CPAK_MGR_FOLDER_REMOVE=true
    # _CPAK_MGR_FOLDER="/home/$USER/cp4ba-pkmgr-inst-$RANDOM"
    _CPAK_MGR_FOLDER="/tmp/cp4ba-pkmgr-inst-$USER-$RANDOM"
  fi
  if [[ "${_CPAK_MGR}" = "true" ]] && [[ ! -z "${_CPAK_MGR_FOLDER}" ]]; then
    mkdir -p ${_CPAK_MGR_FOLDER}
    _USE_VER=""
    if [[ ! -z "${_CPAK_MGR_VER}" ]]; then
      _USE_VER=" -v ${_CPAK_MGR_VER}"
    fi
    ${CP4BA_INST_CMGR_TOOLS_FOLDER}/cp4ba-casemgr-install.sh -d ${_CPAK_MGR_FOLDER} ${_USE_VER}
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
      echo -e "${_CLR_RED}Scripts folder not found: ${_SCRIPTS}${_CLR_NC}" 
      usage
      exit 1
    fi
    if [[ ! -f "${_SCRIPTS}/cp4a-clusteradmin-setup.sh" ]]; then
      echo -e "${_CLR_RED}Script 'cp4a-clusteradmin-setup.sh' not found in folder: ${_SCRIPTS}${_CLR_NC}" 
      exit 1
    fi
    _COMMON_SCRIPT="${_SCRIPTS}/helper/common.sh"
    if [[ ! -f "${_COMMON_SCRIPT}" ]]; then
      echo -e "${_CLR_RED}Script '${_COMMON_SCRIPT}' not found in folder: ${_SCRIPTS}${_CLR_NC}" 
      exit 1
    fi

    _RELEASE_BASE=$(grep "CP4BA_RELEASE_BASE=" ${_COMMON_SCRIPT} | sed 's/CP4BA_RELEASE_BASE="//g' | sed 's/"//g')
    if [[ -z "${_RELEASE_BASE}" ]]; then
      echo -e "${_CLR_RED}Error, cannot detect value of 'CP4BA_RELEASE_BASE' in file '${_COMMON_SCRIPT}'${_CLR_NC}" 
      exit 1
    fi

    if [[ -z "${CP4BA_INST_APPVER}" ]]; then
      export CP4BA_INST_APPVER=${_RELEASE_BASE}
    else
      if [[ "${_RELEASE_BASE}" != "${CP4BA_INST_APPVER}" ]]; then
        echo -e "${_CLR_RED}WARNING, CP4BA_RELEASE_BASE='${_CLR_YELLOW}${_RELEASE_BASE}${_CLR_RED}' of installation package doesn't match your configuration CP4BA_INST_APPVER='${_CLR_YELLOW}${CP4BA_INST_APPVER}${_CLR_RED}'${_CLR_NC}" 
        export CP4BA_INST_APPVER=${_RELEASE_BASE}
        echo -e "${_CLR_GREEN}Continue the installation using version '${_CLR_YELLOW}${CP4BA_INST_APPVER}${_CLR_GREEN}, update you configuration or set empty the var CP4BA_INST_APPVER=''${_CLR_NC}"
      fi
    fi

    #---------------------
    # Show CP4BA release,version,channel, etc...
    #---------------------
    _GREP_WHAT="CP4BA_PATCH_VERSION"
    _CP4BA_PATCH_VERSION=$(grep "${_GREP_WHAT}=" ${_COMMON_SCRIPT} | sed 's/'${_GREP_WHAT}'="//g' | sed 's/"//g')

    _GREP_WHAT="CP4BA_CSV_VERSION"
    _CP4BA_CSV_VERSION=$(grep "${_GREP_WHAT}=" ${_COMMON_SCRIPT} | sed 's/'${_GREP_WHAT}'="//g' | sed 's/"//g')

    _GREP_WHAT="CS_OPERATOR_VERSION"
    _CS_OPERATOR_VERSION=$(grep "${_GREP_WHAT}=" ${_COMMON_SCRIPT} | sed 's/'${_GREP_WHAT}'="//g' | sed 's/"//g')

    _GREP_WHAT="CS_CHANNEL_VERSION"
    _CS_CHANNEL_VERSION=$(grep "${_GREP_WHAT}=" ${_COMMON_SCRIPT} | sed 's/'${_GREP_WHAT}'="//g' | sed 's/"//g')

    _GREP_WHAT="CS_CATALOG_VERSION"
    _CS_CATALOG_VERSION=$(grep "${_GREP_WHAT}=" ${_COMMON_SCRIPT} | sed 's/'${_GREP_WHAT}'="//g' | sed 's/"//g')

    _GREP_WHAT="ZEN_OPERATOR_VERSION"
    _ZEN_OPERATOR_VERSION=$(grep "${_GREP_WHAT}=" ${_COMMON_SCRIPT} | sed 's/'${_GREP_WHAT}'="//g' | sed 's/"//g')

    _GREP_WHAT="REQUIREDVER_BTS"
    _REQUIREDVER_BTS=$(grep "${_GREP_WHAT}=" ${_COMMON_SCRIPT} | sed 's/'${_GREP_WHAT}'="//g' | sed 's/"//g')

    _GREP_WHAT="REQUIREDVER_POSTGRESQL"
    _REQUIREDVER_POSTGRESQL=$(grep "${_GREP_WHAT}=" ${_COMMON_SCRIPT} | sed 's/'${_GREP_WHAT}'="//g' | sed 's/"//g')

    echo -e "${_CLR_GREEN}Using CP4BA Case Manager v${_CPAK_MGR_VER} (Release/Patch version)${_CLR_NC}"
    echo -e "${_CLR_GREEN}Release base                     '${_CLR_YELLOW}${_RELEASE_BASE}${_CLR_GREEN}'${_CLR_NC}"
    echo -e "${_CLR_GREEN}CP4BA patch version              '${_CLR_YELLOW}${_CP4BA_PATCH_VERSION}${_CLR_GREEN}'${_CLR_NC}"
    echo -e "${_CLR_GREEN}CP4BA CSV version                '${_CLR_YELLOW}${_CP4BA_CSV_VERSION}${_CLR_GREEN}'${_CLR_NC}"
    echo -e "${_CLR_GREEN}Common services operator version '${_CLR_YELLOW}${_CS_OPERATOR_VERSION}${_CLR_GREEN}'${_CLR_NC}"
    echo -e "${_CLR_GREEN}Common services channel version  '${_CLR_YELLOW}${_CS_CHANNEL_VERSION}${_CLR_GREEN}'${_CLR_NC}"
    echo -e "${_CLR_GREEN}Common services catalog version  '${_CLR_YELLOW}${_CS_CATALOG_VERSION}${_CLR_GREEN}'${_CLR_NC}"
    echo -e "${_CLR_GREEN}Zen operator version             '${_CLR_YELLOW}${_ZEN_OPERATOR_VERSION}${_CLR_GREEN}'${_CLR_NC}"
    echo -e "${_CLR_GREEN}BTS required version             '${_CLR_YELLOW}${_REQUIREDVER_BTS}${_CLR_GREEN}'${_CLR_NC}"
    echo -e "${_CLR_GREEN}PostgreSQL required version      '${_CLR_YELLOW}${_REQUIREDVER_POSTGRESQL}${_CLR_GREEN}'${_CLR_NC}"

  fi
}

echo ""
echo -e "${_CLR_YELLOW}***********************************************************************"
echo -e "Install CP4BA version '${_CLR_GREEN}${CP4BA_INST_RELEASE}${_CLR_YELLOW}' complete environment in namespace '${_CLR_GREEN}${CP4BA_INST_NAMESPACE}${_CLR_YELLOW}'"
echo -e "Started at ${_CLR_GREEN}"$(date)"${_CLR_YELLOW}"
echo -e "***********************************************************************${_CLR_NC}"

checkPrepreqTools

# verify logged in OCP
oc project 2>/dev/null 1>/dev/null
if [ $? -gt 0 ]; then
  echo -e "${_CLR_RED}Not logged in to OCP cluster. Please login to an OCP cluster and rerun this command. ${_CLR_NC}" 
  exit 1
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
  # if pckgmgr dinamico rm folder
  if [[ "${_CPAK_MGR_FOLDER_REMOVE}" = "true" ]]; then
    echo -e "Removing temporary folder: '${_CLR_GREEN}${_CPAK_MGR_FOLDER}${_CLR_NC}'"
    rm -fR ${_CPAK_MGR_FOLDER}
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

  echo -e "${_CLR_YELLOW}***********************************************************************"
  echo -e "${_CLR_GREEN}[✔] Installation completed successfully for environment '${_CLR_YELLOW}${CP4BA_INST_ENV}${_CLR_GREEN}' !!!${_CLR_NC}"
  echo -e "Terminated at ${_CLR_GREEN}"$(date)"${_CLR_NC}, total installation time "${TOT_MINUTES}" minutes and "${TOT_SECONDS}" seconds."

  echo -e "${_CLR_GREEN}Verifying pod status and Case initialization logs...${_CLR_NC}"
  _CASE_INIT_ERRORS=0
  _PENDING=$(oc get pods -n ${CP4BA_INST_NAMESPACE} 2>/dev/null | grep Pending | wc -l)
  if [[ -z "${CP4BA_INST_BAW_BPM_ONLY}" ]] || [[ "${CP4BA_INST_BAW_BPM_ONLY}" = "false" ]]; then
    _CASE_INIT_ERRORS=$(oc logs -n ${CP4BA_INST_NAMESPACE} $(oc get pods -n ${CP4BA_INST_NAMESPACE} | grep case-init-job  | awk '{print $1}') 2>/dev/null | egrep "SEVERE|Exception" | wc -l)
  fi
  if [[ $_PENDING -gt 0 ]]; then
    echo -e "\x1B[1mPlease note${_CLR_NC}, some pods may be not yet ready. Check before using the system."
    oc get pods -n ${CP4BA_INST_NAMESPACE} | grep Pending
    echo ""
    echo -e "${_CLR_GREEN}For pod status run manually: ${_CLR_GREEN}oc get pods -n ${CP4BA_INST_NAMESPACE} | grep Pending${_CLR_NC}"
  fi

  if [[ -z "${CP4BA_INST_BAW_BPM_ONLY}" ]] || [[ "${CP4BA_INST_BAW_BPM_ONLY}" = "false" ]]; then
    if [[ $_CASE_INIT_ERRORS -gt 0 ]]; then
      echo -e "\x1B[1mPlease note${_CLR_NC}, some errors in Case initialization. May be a transient problem."
      echo ""
      oc logs -n ${CP4BA_INST_NAMESPACE} $(oc get pods -n ${CP4BA_INST_NAMESPACE} | grep case-init-job  | awk '{print $1}') | egrep 'SEVERE|Exception'
      echo ""
    fi

    echo -e "${_CLR_GREEN}PAY ATTENTION: The case completion job may take more time to complete${_CLR_NC}"
    echo -e "${_CLR_GREEN}To verify the completion of Case subsys. installation access Job log, the pod name is something like '...case-init-job...'${_CLR_NC}"
    echo -e "${_CLR_GREEN}For Case initialization log/status/errors run manually:${_CLR_GREEN}"
    echo -e "  logs   : ${_CLR_YELLOW}oc logs -n ${CP4BA_INST_NAMESPACE} \$(oc get pods -n ${CP4BA_INST_NAMESPACE} | grep case-init-job | awk '{print \$1}')${_CLR_GREEN}"
    echo -e "  errors : ${_CLR_YELLOW}oc logs -n ${CP4BA_INST_NAMESPACE} \$(oc get pods -n ${CP4BA_INST_NAMESPACE} | grep case-init-job | awk '{print \$1}') | egrep 'SEVERE|Exception'${_CLR_GREEN}"
    echo -e "  success: ${_CLR_YELLOW}oc logs -n ${CP4BA_INST_NAMESPACE} \$(oc get pods -n ${CP4BA_INST_NAMESPACE} | grep case-init-job | awk '{print \$1}') | grep 'INFO: Configuration Completed'${_CLR_GREEN}"
    echo -e "${_CLR_YELLOW}***********************************************************************${_CLR_NC}"

  fi

fi
