#!/bin/bash

_me=$(basename "$0")

_CFG=""
_SCRIPTS=""

#--------------------------------------------------------
_CLR_RED="\033[0;31m"   #'0;31' is Red's ANSI color code
_CLR_GREEN="\033[0;32m"   #'0;32' is Green's ANSI color code
_CLR_YELLOW="\033[1;32m"   #'1;32' is Yellow's ANSI color code
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

if [[ -z "${_CFG}" ]]; then
  echo "usage: $_me -c path-of-config-file -s cp4ba-case-pkg-scripts-folder"
  exit
fi

if [[ ! -f "${_CFG}" ]]; then
  echo "Configuration file not found: "${_CFG}
  usage
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
    echo -e "${_CLR_RED}[✗] var CP4BA_AUTO_CLUSTER_USER not set, export it in your bash shell and rerun.${_CLR_NC}"
    _OK_VARS=0
  fi

  if [[ -z "${CP4BA_AUTO_ENTITLEMENT_KEY}" ]]; then
    echo -e "${_CLR_RED}[✗] var CP4BA_AUTO_ENTITLEMENT_KEY not set, export it in your bash shell and rerun.${_CLR_NC}"
    _OK_VARS=0
  fi

  if [[ -z "${CP4BA_INST_TYPE}" ]]; then
    echo -e "${_CLR_RED}[✗] var CP4BA_INST_TYPE not set, update your configuration file and rerun.${_CLR_NC}"
    _OK_VARS=0
  else
    if [[ "${CP4BA_INST_TYPE}" != "starter" ]] && [[ "${CP4BA_INST_TYPE}" != "production" ]]; then
      echo -e "${_CLR_RED}[✗] var CP4BA_INST_TYPE must be 'starter' or 'production', update your configuration file and rerun.${_CLR_NC}"
      _OK_VARS=0
    fi
  fi

  if [[ -z "${CP4BA_INST_PLATFORM}" ]]; then
    echo -e "${_CLR_RED}[✗] var CP4BA_INST_PLATFORM not set, update your configuration file and rerun.${_CLR_NC}"
    _OK_VARS=0
  else
    if [[ "${CP4BA_INST_PLATFORM}" != "OCP" ]] && [[ "${CP4BA_INST_PLATFORM}" != "ROKS" ]]; then
      echo -e "${_CLR_RED}[✗] var CP4BA_INST_PLATFORM must be 'OCP' or 'ROKS', update your configuration file and rerun.${_CLR_NC}"
      _OK_VARS=0
    fi
  fi

  if [[ -z "${CP4BA_INST_SC_FILE}" ]]; then
    echo -e "${_CLR_RED}[✗] Storage class '${CP4BA_INST_SC_FILE}' not found in your OCP cluster, update your configuration file and rerun.${_CLR_NC}"
    _OK_VARS=0
  fi

  storageClassExist ${CP4BA_INST_SC_FILE}
  if [ $? -eq 0 ]; then
    echo -e "${_CLR_RED}[✗] Storage class '${CP4BA_INST_SC_FILE}' not present in your OCP cluster${_CLR_NC}"
    _OK_VARS=0
  fi

  storageClassExist ${CP4BA_INST_SC_BLOCK}
  if [ $? -eq 0 ]; then
    echo -e "${_CLR_RED}[✗] Storage class '${CP4BA_INST_SC_BLOCK}' not present in your OCP cluster${_CLR_NC}"
    _OK_VARS=0
  fi


  if [ $_OK_VARS -eq 0 ]; then
    exit 1
  fi

  export CP4BA_AUTO_ALL_NAMESPACES="No"
  export CP4BA_AUTO_PRIVATE_CATALOG=No
  export CP4BA_AUTO_FIPS_CHECK=No

  export CP4BA_AUTO_STORAGE_CLASS_FAST_ROKS="${CP4BA_INST_SC_FILE}"
  export CP4BA_AUTO_STORAGE_CLASS_OCP="${CP4BA_INST_SC_FILE}"
  export CP4BA_AUTO_DEPLOYMENT_TYPE="${CP4BA_INST_TYPE}"
  export CP4BA_AUTO_PLATFORM="${CP4BA_INST_PLATFORM}"

}


echo -e "${_CLR_YELLOW}=============================================================="
echo -e "Install CP4BA Operators in namespace '${_CLR_GREEN}${CP4BA_INST_NAMESPACE}${_CLR_YELLOW}'"
echo -e "==============================================================${_CLR_NC}"

START_SECONDS=$SECONDS

checkPrepreqTools
checkPrereqVars

# verify logged in OCP
oc whoami 2>/dev/null 1>/dev/null
if [ $? -gt 0 ]; then
  echo -e "${_CLR_RED}Not logged in to OCP cluster. Please login to an OCP cluster and rerun this command. ${_CLR_NC}" && exit 1
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

oc adm policy add-scc-to-user anyuid -z ibm-cp4ba-anyuid -n ${CP4BA_INST_NAMESPACE} 2>/dev/null 1>/dev/null

_OK=false
if [[ ! -z "${_SCRIPTS}" ]]; then
  if [[ -d "${_SCRIPTS}" ]]; then
    if [[ -f "${_SCRIPTS}/cp4a-clusteradmin-setup.sh" ]]; then
      echo "Executing 'cp4a-clusteradmin-setup.sh' script for namespace '${CP4BA_INST_NAMESPACE}'"
      _ACT_DIR=$(pwd)
      cd ${_SCRIPTS}
      export CP4BA_AUTO_NAMESPACE="${CP4BA_INST_NAMESPACE}"
      /bin/bash ./cp4a-clusteradmin-setup.sh &> ./_clusteradmin.out
      if [ $? -eq 0 ]; then
        rm ./_clusteradmin.out
        cd ${_ACT_DIR}
        echo "Ready to deploy ICP4ACluster CR in namespace '${CP4BA_INST_NAMESPACE}'"
        _OK=true
      else
        cat ./_clusteradmin.out
      fi
    fi
  fi
fi

if [[ "${_OK}" = "false" ]]; then
  echo -e ">>> \x1b[5mERROR\x1b[25m <<<"
  echo "CP4BA Operators not installed."
  exit 1
fi

STOP_SECONDS=$SECONDS
ELAPSED_SECONDS=$(( STOP_SECONDS - START_SECONDS ))
TOT_MINUTES=$(($ELAPSED_SECONDS / 60))
TOT_SECONDS=$(($ELAPSED_SECONDS % 60))
echo -e "CP4BA Operators installed at ${_CLR_GREEN}"$(date)"${_CLR_NC}, total installation time "${TOT_MINUTES}" minutes and "${TOT_SECONDS}" seconds."

exit 0