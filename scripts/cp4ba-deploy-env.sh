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
namespaceExist () {
# ns name: $1
  if [ $(oc get ns $1 2> /dev/null | grep $1 | wc -l) -lt 1 ];
  then
      return 0
  fi
  return 1
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
  _total_warnings=0
  _warning_interval=10
  _ROTOR="|/-\\|/-\\"
  _ROTOR_LEN=${#_ROTOR}

  START_SECONDS=$SECONDS

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
      break
    fi
    _pending_pvc_count=0
    _operator_failures=0
    _WARNING_PENDING=""
    if [ $_warning_interval -gt 10 ]; then
      _warning_interval=0
      _pending_pvc_count=$(oc get pvc -n ${CP4BA_INST_NAMESPACE} --no-headers 2>/dev/null| grep Pending | grep -Ev "ibm-zen-cs-mongo-backup|ibm-zen-objectstore-backup-pvc" | wc -l)
      _operator_failures=$(oc logs -n ${CP4BA_INST_NAMESPACE} -c operator $(oc get pods -n ${CP4BA_INST_NAMESPACE} 2>/dev/null | grep cp4a-operator- | awk '{print $1}') 2>/dev/null | grep "FAIL" | uniq | wc -l)
      ((_total_warnings=_pending_pvc_count+_operator_failures))
      #echo "pvc:"$_pending_pvc_count" fails:"$_operator_failures" tot="$_total_warnings
      if [ $_total_warnings -gt 0 ]; then
        if [ $_total_warnings -gt 99 ]; then
          _pending_pv_total_warningsc_count=99
        fi
      fi
    else
      ((_warning_interval=_warning_interval+1))
    fi
    if [ $_total_warnings -gt 0 ]; then
      _WARNING_PENDING="${_CLR_RED}\x1b[5m${_total_warnings:0:2}${_WARNING_PENDING:0:$((2 - ${#_total_warnings}))}\x1b[25m"
    fi
    _ROTOR_CHAR_OFF=$((_seconds % _ROTOR_LEN))
    _ROTOR_CHAR="${_ROTOR:_ROTOR_CHAR_OFF:1}"

    NOW_SECONDS=$SECONDS
    ELAPSED_SECONDS=$(( NOW_SECONDS - START_SECONDS ))
    TOT_MINUTES=$(($ELAPSED_SECONDS / 60))
    TOT_SECONDS=$(($ELAPSED_SECONDS % 60))
    TOT_HOURS=$(($TOT_MINUTES / 60))

    echo -e -n "${_CLR_GREEN}Wait for ICP4ACluster '${_CLR_YELLOW}${CP4BA_INST_CR_NAME}${_CLR_GREEN}' to be ready [${_ROTOR_CHAR}]${_CLR_NC} ${_CLR_BLUE}warnings${_CLR_GREEN} [${_WARNING_PENDING}]${_CLR_GREEN} elapsed time [${_CLR_YELLOW}$TOT_HOURS${_CLR_GREEN}h:${_CLR_YELLOW}$TOT_MINUTES${_CLR_GREEN}m:${_CLR_YELLOW}$TOT_SECONDS${_CLR_GREEN}s]${_CLR_NC}\033[0K\r"
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
  echo -e "${_CLR_RED}[✗] Not logged in to OCP cluster. Please login to an OCP cluster and rerun this command. ${_CLR_NC}"
  exit 1
fi

namespaceExist ${CP4BA_INST_NAMESPACE}
if [ $? -eq 1 ]; then

  if [[ "${_WAIT_ONLY}" = "false" ]]; then
    mkdir -p ../output
    deployPreEnv
    deployEnvironment
    deployPostEnv
  fi
  waitDeploymentReadiness

  echo -e "${_CLR_GREEN}CP4BA environment '${_CLR_YELLOW}${CP4BA_INST_ENV}${_CLR_GREEN}' in namespace '${_CLR_YELLOW}${CP4BA_INST_NAMESPACE}${_CLR_GREEN}' is \x1b[5mREADY\x1b[25m${_CLR_NC}"
  exit 0

else
  echo -e "${_CLR_RED}[✗] Error, namespace '${_CLR_YELLOW}${CP4BA_INST_NAMESPACE}${_CLR_RED}' doesn't exists. ${_CLR_NC}"
  exit 1
fi
