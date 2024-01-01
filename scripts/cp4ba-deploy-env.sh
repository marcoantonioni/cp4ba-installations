#!/bin/bash

_me=$(basename "$0")

_CFG=""
_LDAP=""
_WAIT_ONLY=false

#--------------------------------------------------------
_CLR_RED="\033[0;31m"   #'0;31' is Red's ANSI color code
_CLR_GREEN="\033[0;32m"   #'0;32' is Green's ANSI color code
_CLR_YELLOW="\033[1;32m"   #'1;32' is Yellow's ANSI color code
_CLR_BLUE="\033[0;34m"   #'0;34' is Blue's ANSI color code
_CLR_NC="\033[0m"

#--------------------------------------------------------
# read command line params
while getopts c:l:w flag
do
    case "${flag}" in
        c) _CFG=${OPTARG};;
        l) _LDAP=${OPTARG};;
        w) _WAIT_ONLY=true;;
    esac
done

if [[ -z "${_CFG}" ]]; then
  echo "usage: $_me -c path-of-config-file -l(optional) ldap-config-file"
  exit 1
fi

if [[ ! -z "${_LDAP}" ]]; then
  if [[ ! -f "${_LDAP}" ]]; then
    echo "[✗] Error, LDAP configuration file not found: "${_LDAP}
    exit 1
  fi
  source ${_LDAP}
fi

if [[ ! -f "${_CFG}" ]]; then
  echo "[✗] Error, configuration file not found: "${_CFG}
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
deployPreEnv () {
  if [[ "${CP4BA_INST_LDAP}" = "true" ]]; then
    if [[ ! -z "${_LDAP}" ]]; then
      ${CP4BA_INST_LDAP_TOOLS_FOLDER}/add-ldap.sh -p ${_LDAP}
      if [[ $? -ne 0 ]]; then
        echo -e "${_CLR_RED}[✗] Error, LDAP not installed.${_CLR_NC}"
        exit 1
      fi
    else
      echo -e "${_CLR_RED}[✗] Error, LDAP configuration file not set for '${_CLR_YELLOW}${_INST_ENV_FULL_PATH}${_CLR_RED}'${_CLR_NC}"
      exit 1
    fi
  fi

  ./cp4ba-install-db.sh -c ${_CFG}
  if [[ $? -ne 0 ]]; then
    echo -e "${_CLR_RED}[✗] Error, DB not installed.${_CLR_NC}"
    exit 1
  fi

  ./cp4ba-create-secrets.sh -c ${_CFG} -s -t 0
  if [[ $? -ne 0 ]]; then
    echo -e "${_CLR_RED}[✗] Error, secrets not configured.${_CLR_NC}"
    exit 1
  fi
}

#-------------------------------
deployPostEnv () {
  ./cp4ba-create-databases.sh -c ${_CFG} -w
  if [[ $? -ne 0 ]]; then
    echo -e "${_CLR_RED}[✗] Error, databases not created.${_CLR_NC}"
    exit 1
  fi
}

#-------------------------------
deployEnvironment () {
  _INST_ENV_FULL_PATH="../output/cp4ba-${CP4BA_INST_CR_NAME}-${CP4BA_INST_ENV}.yaml"
  envsubst < ../templates/${CP4BA_INST_CR_TEMPLATE} > ${_INST_ENV_FULL_PATH}
  if [[ $? -ne 0 ]]; then
    echo -e "${_CLR_RED}[✗] Error, CP4BA CR not generated.${_CLR_NC}"
    exit 1
  fi

  echo -e "=============================================================="
  echo -e "${_CLR_GREEN}Deploying ICP4ACluster '${_CLR_YELLOW}${CP4BA_INST_CR_NAME}${_CLR_GREEN}'${_CLR_NC}"

  if [[ -f "${_INST_ENV_FULL_PATH}" ]]; then
    MISSED_TRANSFORMATIONS=$(cat ${_INST_ENV_FULL_PATH} | grep "\${" | wc -l)
    if [[ MISSED_TRANSFORMATIONS -gt 0 ]]; then
      echo -e "${_CLR_RED}[✗] Error, env var missed in '${_CLR_YELLOW}${_INST_ENV_FULL_PATH}${_CLR_RED}'${_CLR_NC}"
      echo "++++++++++++++++++++++++++++++++++++++++"
      cat ${_INST_ENV_FULL_PATH} | grep "\${"
      echo "++++++++++++++++++++++++++++++++++++++++"
      exit 1
    fi
    yq ${_INST_ENV_FULL_PATH} 2>/dev/null 1>/dev/null
    YAML_ERROR=$?
    if [ $YAML_ERROR -gt 0 ]; then
      echo -e "${_CLR_RED}[✗] Error, wrong yaml format in '${_CLR_YELLOW}${_INST_ENV_FULL_PATH}${_CLR_RED}'${_CLR_NC}"
      echo "++++++++++++++++++++++++++++++++++++++++"
      yq ${_INST_ENV_FULL_PATH}
      echo "++++++++++++++++++++++++++++++++++++++++"
      exit 1
    fi
  else
    echo -e "${_CLR_GREEN}[✗] Error, file not found '${_CLR_YELLOW}${_INST_ENV_FULL_PATH}${_CLR_RED}'${_CLR_NC}"
    exit 1
  fi 

  oc apply -n ${CP4BA_INST_NAMESPACE} -f ${_INST_ENV_FULL_PATH}
  if [ $? -gt 0 ]; then
    echo -e ">>> \x1b[5mERROR\x1b[25m <<<"
    echo -e "${_CLR_RED}[✗] Cannot deploy CP4BA CR '${_CLR_YELLOW}${_INST_ENV_FULL_PATH}${_CLR_RED}', use yq to verify"
    exit 1
  fi

  echo -e "${_CLR_GREEN}CR for ICP4ACluster '${_CLR_YELLOW}${CP4BA_INST_CR_NAME}${_CLR_GREEN}' saved\nin file '${_CLR_YELLOW}${_INST_ENV_FULL_PATH}${_CLR_YELLOW}'${_CLR_NC}"

}

waitDeploymentReadiness () {
  echo "=============================================================="
  echo -e "${_CLR_GREEN}Configuration and deployment complete for '${_CLR_YELLOW}${CP4BA_INST_CR_NAME}${_CLR_GREEN}'${_CLR_NC}"
  _seconds=0
  while [ true ]; 
  do   
    _NUM=$(oc get cm -n ${CP4BA_INST_NAMESPACE} --no-headers 2>/dev/null | grep access-info | wc -l) 
    if [[ $_NUM -eq 1 ]]; then
      ACC_INFO=$(oc get cm -n ${CP4BA_INST_NAMESPACE} --no-headers | grep access-info | awk '{print $1}' | xargs oc get cm -n ${CP4BA_INST_NAMESPACE} -o jsonpath='{.data}')
      NUM_KEYS=$(echo $ACC_INFO | jq length)
      echo "" > ../output/cp4ba-${CP4BA_INST_CR_NAME}-${CP4BA_INST_ENV}-access-info.txt
      echo 
      for (( i=0; i<$NUM_KEYS; i++ ));
      do
        KEY=$(echo $ACC_INFO | jq keys[$i])
        echo -e $(echo $ACC_INFO | jq .[$KEY] | sed 's/"//g' | sed '/^$/d') >> ../output/cp4ba-${CP4BA_INST_CR_NAME}-${CP4BA_INST_ENV}-access-info.txt
      done
      echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"     
      echo "See acces info urls in file ../output/cp4ba-${CP4BA_INST_CR_NAME}-${CP4BA_INST_ENV}-access-info.txt"     
      echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"     
      break;   
    fi;   
    echo -e -n "${_CLR_GREEN}Wait for ICP4ACluster '${_CLR_YELLOW}${CP4BA_INST_CR_NAME}${_CLR_GREEN}' to be ready [$_seconds]${_CLR_NC}\033[0K\r"
    ((_seconds=_seconds+1))
    sleep 1
  done
}

echo -e "${_CLR_YELLOW}=============================================================="
echo -e "${_CLR_YELLOW}Deploying CP4BA environment '${_CLR_GREEN}${CP4BA_INST_ENV}${_CLR_YELLOW}' in namespace '${_CLR_GREEN}${CP4BA_INST_NAMESPACE}${_CLR_YELLOW}'${_CLR_NC}"
echo -e "==============================================================${_CLR_NC}"
checkPrepreqTools

# verify logged in OCP
oc project 2>/dev/null 1>/dev/null
if [ $? -gt 0 ]; then
  echo -e "\x1B[1;31m[✗] Not logged in to OCP cluster. Please login to an OCP cluster and rerun this command. \x1B[0m"
  exit 1
fi

if [[ "${_WAIT_ONLY}" = "false" ]]; then
  mkdir -p ../output
  deployPreEnv
  deployEnvironment
  deployPostEnv
fi
waitDeploymentReadiness

echo -e "${_CLR_GREEN}CP4BA environment '${_CLR_YELLOW}${CP4BA_INST_ENV}${_CLR_GREEN}' in namespace '${_CLR_YELLOW}${CP4BA_INST_NAMESPACE}${_CLR_GREEN}' is \x1b[5mREADY\x1b[25m${_CLR_NC}"
exit 0
