#!/bin/bash

_me=$(basename "$0")

_CFG=""
_STATEMENTS=""
_LDAP=""
_IDP=""

#--------------------------------------------------------
_CLR_RED="\033[0;31m"   #'0;31' is Red's ANSI color code
_CLR_GREEN="\033[0;32m"   #'0;32' is Green's ANSI color code
_CLR_YELLOW="\033[1;32m"   #'1;32' is Yellow's ANSI color code
_CLR_BLUE="\033[0;34m"   #'0;34' is Blue's ANSI color code
_CLR_NC="\033[0m"

#--------------------------------------------------------
# read command line params
while getopts c:s:l:i: flag
do
    case "${flag}" in
        c) _CFG=${OPTARG};;
        s) _STATEMENTS=${OPTARG};;
        l) _LDAP=${OPTARG};;
        i) _IDP=${OPTARG};;
    esac
done

if [[ -z "${_CFG}" ]] || [[ -z "${_STATEMENTS}" ]] || [[ -z "${_LDAP}" ]] || [[ -z "${_IDP}" ]]; then
  echo "usage: $_me -c path-of-config-file -s sql-statements-file -l ldap-config-file -i idp-config-file"
  exit
fi

if [[ ! -f "${_STATEMENTS}" ]]; then
  echo "SQL Statements file not found: "${_STATEMENTS}
fi

if [[ ! -f "${_LDAP}" ]]; then
  echo "LDAP configuration file not found: "${_LDAP}
fi

if [[ ! -f "${_IDP}" ]]; then
  echo "IDP configuration file not found: "${_IDP}
fi

if [[ ! -f "${_CFG}" ]]; then
  echo "Configuration file not found: "${_CFG}
fi
source ${_LDAP}
source ${_IDP}
source ${_CFG}


#-------------------------------
deployEnvironment () {

../../cp4ba-idp-ldap/scripts/add-ldap.sh -p ${_LDAP}
./cp4ba-install-db.sh -c ${_CFG}
./cp4ba-create-secrets.sh -c ${_CFG} -s
envsubst < ../notes/cp4ba-cr-ref.yaml > ../crs/cp4ba-${CP4BA_INST_CR_NAME}-${CP4BA_INST_ENV}.yaml
./cp4ba-create-pvc.sh -c ${_CFG}
oc apply -n ${CP4BA_INST_NAMESPACE} -f ../crs/cp4ba-${CP4BA_INST_CR_NAME}-${CP4BA_INST_ENV}.yaml

./cp4ba-create-secrets.sh -c ${_CFG} -w
./cp4ba-create-databases.sh -c ${_CFG} -s ${_STATEMENTS} -w


}

echo -e "#==========================================================="
echo -e "${_CLR_GREEN}Deploying CP4BA environment '${_CLR_YELLOW}${CP4BA_INST_ENV}${_CLR_GREEN}' in namespace '${_CLR_YELLOW}${CP4BA_INST_NAMESPACE}${_CLR_GREEN}'${_CLR_NC}"
deployEnvironment

_seconds=0
while [ true ]; 
do   
  _NUM=$(oc get cm -n ${CP4BA_INST_NAMESPACE} --no-headers | grep access-info | wc -l)
  if [[ $_NUM -eq 1 ]]; then
    echo ""     
    oc get cm -n ${CP4BA_INST_NAMESPACE} --no-headers | grep access-info | awk '{print $1}' | xargs oc get cm -n ${CP4BA_INST_NAMESPACE} -o yaml
    break;   
  fi;   
  echo -e -n "${_CLR_GREEN}Wait for ICP4ACluster '${_CLR_YELLOW}${CP4BA_INST_CR_NAME}${_CLR_GREEN}' ready and config map '${_CLR_YELLOW}access-info${_CLR_GREEN}' $_seconds${_CLR_NC}\033[0K\r"
  ((_seconds=_seconds+1))
  sleep 1
done
echo ""
echo -e "${_CLR_GREEN}CP4BA environment '${_CLR_YELLOW}${CP4BA_INST_ENV}${_CLR_GREEN}' in namespace '${_CLR_YELLOW}${CP4BA_INST_NAMESPACE}${_CLR_GREEN}' is \x1b[5mREADY\x1b[25m${_CLR_NC}"

