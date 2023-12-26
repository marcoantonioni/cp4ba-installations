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

#-------------------------------
_MAX_CHECKS=10
_checks=0
checkSecrets () {
  _FOUND=$(oc get secret --no-headers -n ${CP4BA_INST_NAMESPACE} ${CP4BA_INST_BAW_1_DB_SECRET} 2>/dev/null | wc -l)
  if [[ "${_FOUND}" = "0" ]] && [[ $_checks -lt $_MAX_CHECKS ]]; then
    ((_checks=_checks+1))
    ./cp4ba-create-secrets.sh -c ${_CFG} -s -w -t 60
    checkSecrets
  fi
}

#-------------------------------
deployEnvironment () {

../../cp4ba-idp-ldap/scripts/add-ldap.sh -p ${_LDAP}
./cp4ba-install-db.sh -c ${_CFG}
./cp4ba-create-secrets.sh -c ${_CFG} -s
envsubst < ../notes/cp4ba-cr-ref.yaml > ../crs/cp4ba-${CP4BA_INST_CR_NAME}-${CP4BA_INST_ENV}.yaml
./cp4ba-create-pvc.sh -c ${_CFG}

echo -e "#==========================================================="
echo -e "${_CLR_GREEN}Deploying ICP4ACluster '${_CLR_YELLOW}${CP4BA_INST_CR_NAME}${_CLR_GREEN}'${_CLR_NC}"
oc apply -n ${CP4BA_INST_NAMESPACE} -f ../crs/cp4ba-${CP4BA_INST_CR_NAME}-${CP4BA_INST_ENV}.yaml

./cp4ba-create-secrets.sh -c ${_CFG} -s -w -t 60
./cp4ba-create-databases.sh -c ${_CFG} -s ${_STATEMENTS} -w

checkSecrets

}

waitDeploymentReadiness () {
  _seconds=0
  while [ true ]; 
  do   
    _NUM=$(oc get cm -n ${CP4BA_INST_NAMESPACE} --no-headers 2>/dev/null | grep access-info | wc -l) 
    if [[ $_NUM -eq 1 ]]; then
      ACC_INFO=$(oc get cm -n ${CP4BA_INST_NAMESPACE} --no-headers | grep access-info | awk '{print $1}' | xargs oc get cm -n ${CP4BA_INST_NAMESPACE} -o jsonpath='{.data}')
      NUM_KEYS=$(echo $ACC_INFO | jq length)
      echo "" > ../crs/cp4ba-${CP4BA_INST_CR_NAME}-${CP4BA_INST_ENV}-access-info.txt
      echo 
      for (( i=0; i<$NUM_KEYS; i++ ));
      do
        KEY=$(echo $ACC_INFO | jq keys[$i])
        echo -e $(echo $ACC_INFO | jq .[$KEY] | sed 's/"//g' | sed '/^$/d') >> ../crs/cp4ba-${CP4BA_INST_CR_NAME}-${CP4BA_INST_ENV}-access-info.txt
      done
      echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"     
      echo "See acces info urls in file ../crs/cp4ba-${CP4BA_INST_CR_NAME}-${CP4BA_INST_ENV}-access-info.txt"     
      echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"     
      break;   
    fi;   
    echo -e -n "${_CLR_GREEN}Wait for ICP4ACluster '${_CLR_YELLOW}${CP4BA_INST_CR_NAME}${_CLR_GREEN}' to be ready [$_seconds]${_CLR_NC}\033[0K\r"
    ((_seconds=_seconds+1))
    sleep 1
  done
}

echo ""
echo "#=========================================================================="
echo -e "${_CLR_GREEN}Deploying CP4BA environment '${_CLR_YELLOW}${CP4BA_INST_ENV}${_CLR_GREEN}' in namespace '${_CLR_YELLOW}${CP4BA_INST_NAMESPACE}${_CLR_GREEN}'${_CLR_NC}"
echo "#=========================================================================="
echo ""
checkPrepreqTools

# verify logged in OCP
oc project 2>/dev/null 1>/dev/null
if [ $? -gt 0 ]; then
  echo -e "\x1B[1;31mNot logged in to OCP cluster. Please login to an OCP cluster and rerun this command. \x1B[0m" && exit 1
fi
deployEnvironment
waitDeploymentReadiness
echo ""
echo -e "${_CLR_GREEN}CP4BA environment '${_CLR_YELLOW}${CP4BA_INST_ENV}${_CLR_GREEN}' in namespace '${_CLR_YELLOW}${CP4BA_INST_NAMESPACE}${_CLR_GREEN}' is \x1b[5mREADY\x1b[25m${_CLR_NC}"
exit 0
