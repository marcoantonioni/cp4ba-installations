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

source ${_CFG}

# !!!!!!!!
export CP4BA_AUTO_CLUSTER_USER="IAM#marco_antonioni@it.ibm.com"

export CP4BA_AUTO_PLATFORM="OCP"
export CP4BA_AUTO_ALL_NAMESPACES="No"
export CP4BA_AUTO_STORAGE_CLASS_FAST_ROKS="${CP4BA_INST_SC_FILE}"
export CP4BA_AUTO_FIPS_CHECK=No
export CP4BA_AUTO_PRIVATE_CATALOG=No
export CP4BA_AUTO_DEPLOYMENT_TYPE="production"

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

echo -e "${_CLR_YELLOW}=============================================================="
echo -e "Install CP4BA Operators in namespace '${_CLR_GREEN}${CP4BA_INST_NAMESPACE}${_CLR_YELLOW}'"
echo -e "==============================================================${_CLR_NC}"

checkPrepreqTools

# verify logged in OCP
oc project 2>/dev/null 1>/dev/null
if [ $? -gt 0 ]; then
  echo -e "\x1B[1;31mNot logged in to OCP cluster. Please login to an OCP cluster and rerun this command. \x1B[0m" && exit 1
fi

oc new-project ${CP4BA_INST_NAMESPACE} 2>/dev/null 1>/dev/null

cat << EOF | oc create -n ${CP4BA_INST_NAMESPACE} -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ibm-cp4ba-anyuid
imagePullSecrets:
- name: 'ibm-entitlement-key'
EOF

oc adm policy add-scc-to-user anyuid -z ibm-cp4ba-anyuid -n ${CP4BA_INST_NAMESPACE}

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
exit 0