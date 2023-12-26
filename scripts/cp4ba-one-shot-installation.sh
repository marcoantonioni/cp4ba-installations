#!/bin/bash

_me=$(basename "$0")

_CFG=""
_SCRIPTS=""
_STATEMENTS=""
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
        s) _STATEMENTS=${OPTARG};;
        l) _LDAP=${OPTARG};;
        i) _IDP=${OPTARG};;
    esac
done

if [[ -z "${_CFG}" ]] || [[ -z "${_SCRIPTS}" ]] || [[ -z "${_STATEMENTS}" ]] || [[ -z "${_LDAP}" ]] || [[ -z "${_IDP}" ]]; then
  echo "usage: $_me -c path-of-config-file -s sql-statements-file -l ldap-config-file -i idp-config-file -p cp4ba-case-pkg-scripts-folder"
  exit 1
fi

if [[ ! -f "${_STATEMENTS}" ]]; then
  echo "SQL Statements file not found: "${_STATEMENTS}
  exit 1
fi

if [[ ! -f "${_LDAP}" ]]; then
  echo "LDAP configuration file not found: "${_LDAP}
  exit 1
fi

if [[ ! -f "${_IDP}" ]]; then
  echo "IDP configuration file not found: "${_IDP}
  exit 1
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

source ${_LDAP}
source ${_IDP}
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
  echo -e "#==========================================================="
  echo -e "${_CLR_GREEN}Onboarding users from domain '${_CLR_YELLOW}${CP4BA_INST_LDAP_BASE_DOMAIN}${_CLR_GREEN}'${_CLR_NC}"
  ../../cp4ba-idp-ldap/scripts/onboard-users.sh -p ${_IDP} -l ${_LDAP} -n ${CP4BA_INST_SUPPORT_NAMESPACE} -o add -s
}

echo ""
echo -e "${_CLR_YELLOW}***********************************************************************"
echo -e "Install CP4BA complete environment in namespace '${_CLR_GREEN}${CP4BA_INST_NAMESPACE}${_CLR_YELLOW}' at "$(date)
echo -e "***********************************************************************${_CLR_NC}"
echo ""

checkPrepreqTools

# verify logged in OCP
oc project 2>/dev/null 1>/dev/null
if [ $? -gt 0 ]; then
  echo -e "\x1B[1;31mNot logged in to OCP cluster. Please login to an OCP cluster and rerun this command. \x1B[0m" && exit 1
fi

_OK=0
./cp4ba-install-operators.sh -c ${_CFG} -s ${_SCRIPTS}
if [[ $? -eq 0 ]]; then
  ./cp4ba-deploy-env.sh -c ${_CFG} -s ${_STATEMENTS} -l ${_LDAP} -i ${_IDP}
  if [[ $? -eq 0 ]]; then
    onboardUsers
    _OK=1
  fi
fi
if [[ "${_OK}" = "0" ]]; then
  echo ""
  echo -e "${_CLR_RED}[✗] Installation error, environment '${_CLR_YELLOW}${CP4BA_INST_ENV}${_CLR_RED}' not installed !!!${_CLR_NC}"
  echo "Verify the configuration and/or run parameters."
  echo "If the installation was started and subsequently interrupted it is recommended to remove the entire namespace"
  echo "using the 'remove-cp4ba' tool."
  echo "See link https://github.com/marcoantonioni/cp4ba-utilities"
else
  echo ""
  echo -e "${_CLR_GREEN}[✔] Installation completed successfully for environment '${_CLR_YELLOW}${CP4BA_INST_ENV}${_CLR_GREEN}' !!!${_CLR_NC} at "$(date)
  echo -e "\x1B[1mPlease note\x1B[0m, some pods may still be in the not ready state. Check before using the system."
fi
