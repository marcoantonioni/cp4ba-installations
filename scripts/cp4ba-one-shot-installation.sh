#!/bin/bash

_me=$(basename "$0")

CUR_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PARENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"

_CFG=""
_SCRIPTS=""
_LDAP=""
_IDP=""

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
while getopts c:p:s:l:i: flag
do
    case "${flag}" in
        c) _CFG=${OPTARG};;
        p) _SCRIPTS=${OPTARG};;
        l) _LDAP=${OPTARG};;
        i) _IDP=${OPTARG};;
    esac
done

if [[ -z "${_CFG}" ]] || [[ -z "${_SCRIPTS}" ]] || [[ -z "${_LDAP}" ]] || [[ -z "${_IDP}" ]]; then
  echo "usage: $_me -c path-of-config-file -p cp4ba-case-pkg-scripts-folder -l(optional) ldap-config-file -i(optional) idp-config-file"
  exit 1
fi

if [[ ! -z "${_LDAP}" ]]; then
  if [[ ! -f "${_LDAP}" ]]; then
    echo "LDAP configuration file not found: "${_LDAP}
    exit 1
  fi
  source ${_LDAP}
fi

if [[ ! -z "${_IDP}" ]]; then
  if [[ ! -f "${_IDP}" ]]; then
    echo "IDP configuration file not found: "${_IDP}
    exit 1
  fi
  source ${_IDP}
fi

if [[ ! -f "${_CFG}" ]]; then
  echo "Configuration file not found: "${_CFG}
  exit 1
fi

if [[ ! -d "${_SCRIPTS}" ]]; then
  echo "Scripts folder not found: "${_SCRIPTS}
  exit 1
fi
if [[ ! -f "${_SCRIPTS}/cp4a-clusteradmin-setup.sh" ]]; then
  echo "Script 'cp4a-clusteradmin-setup.sh' not found in folder: "${_SCRIPTS}
  exit 1
fi

source ${_CFG}

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
  echo -e "=============================================================="
  echo -e "${_CLR_GREEN}Onboarding users from domain '${_CLR_YELLOW}${CP4BA_INST_LDAP_BASE_DOMAIN}${_CLR_GREEN}'${_CLR_NC}"

  # !!! cp4admin perde ruoli Automation Administrator, Automation Developer se remove-and-add
  ../../cp4ba-idp-ldap/scripts/onboard-users.sh -p ${_IDP} -l ${_LDAP} -n ${CP4BA_INST_SUPPORT_NAMESPACE} -s -o add
}

echo ""
echo -e "${_CLR_YELLOW}***********************************************************************"
echo -e "Install CP4BA complete environment in namespace '${_CLR_GREEN}${CP4BA_INST_NAMESPACE}${_CLR_YELLOW}'"
echo -e "  started at ${_CLR_GREEN}"$(date)"${_CLR_YELLOW}"
echo -e "***********************************************************************${_CLR_NC}"
echo ""

checkPrepreqTools

# verify logged in OCP
oc project 2>/dev/null 1>/dev/null
if [ $? -gt 0 ]; then
  echo -e "\x1B[1;31mNot logged in to OCP cluster. Please login to an OCP cluster and rerun this command. \x1B[0m" && exit 1
fi

_OK=0

START_SECONDS=$SECONDS

./cp4ba-install-operators.sh -c ${_CFG} -s ${_SCRIPTS}
if [[ $? -eq 0 ]]; then
  ./cp4ba-deploy-env.sh -c ${_CFG} -s ${CP4BA_INST_DB_TEMPLATE} -l ${_LDAP}
  if [[ $? -eq 0 ]]; then
    if [[ ! -z "${_IDP}" ]]; then
      onboardUsers
    fi
    _OK=1
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
  echo -e "  terminated at ${_CLR_GREEN}"$(date)"${_CLR_NC}, total installation time "${TOT_MINUTES}" minutes and "${TOT_SECONDS}" seconds."
  echo -e "\x1B[1mPlease note\x1B[0m, some pods may still be in the not ready state. Check before using the system."
  echo -e "${_CLR_YELLOW}***********************************************************************${_CLR_NC}"
fi
