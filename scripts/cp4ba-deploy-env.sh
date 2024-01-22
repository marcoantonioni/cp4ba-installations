#!/bin/bash

_me=$(basename "$0")

_CFG=""
_LDAP=""
_WAIT_ONLY=false
_GENERATE_ONLY=false

#--------------------------------------------------------
_CLR_RED="\033[0;31m"   #'0;31' is Red's ANSI color code
_CLR_GREEN="\033[0;32m"   #'0;32' is Green's ANSI color code
_CLR_YELLOW="\033[1;32m"   #'1;32' is Yellow's ANSI color code
_CLR_BLUE="\033[0;34m"   #'0;34' is Blue's ANSI color code
_CLR_NC="\033[0m"

#--------------------------------------------------------
# read command line params
while getopts c:l:wg flag
do
    case "${flag}" in
        c) _CFG=${OPTARG};;
        l) _LDAP=${OPTARG};;
        w) _WAIT_ONLY=true;;
        g) _GENERATE_ONLY=true;;
    esac
done

usage () {
  echo ""
  echo -e "${_CLR_GREEN}usage: $_me
    -c full-path-to-config-file
       (eg: '../configs/env1.properties')
    -l(optional) ldap-config-file
       (eg: '../configs/_cfg-production-ldap-domain.properties')
    -w(optional) wait only, skip deployment
    -g(optional) generate yaml only, skip deployment${_CLR_NC}"
}

if [[ -z "${_CFG}" ]]; then
  usage
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
storageClassExist () {
    if [ $(oc get sc $1 2>/dev/null | grep $1 | wc -l) -lt 1 ];
    then
        return 0
    fi
    return 1
}

#-------------------------------
resourceExist () {
#    echo "namespace name: $1"
#    echo "resource type: $2"
#    echo "resource name: $3"
  if [ $(oc get $2 -n $1 $3 2> /dev/null | grep $3 | wc -l) -lt 1 ];
  then
      return 0
  fi
  return 1
}

#-------------------------------
waitForResourceCreated () {
#    echo "namespace name: $1"
#    echo "resource type: $2"
#    echo "resource name: $3"
#    echo "time to wait: $4"

  while [ true ]
  do
      resourceExist $1 $2 $3
      if [ $? -eq 0 ]; then
          sleep $4
      else
          break
      fi
  done
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
    CP4BA_INST_TYPE=$(echo "${CP4BA_INST_TYPE}" | tr '[:upper:]' '[:lower:]')
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

  if [[ "${CP4BA_INST_LDAP}" = "true" ]]; then
    if [[ -z "${CP4BA_INST_LDAP_SECRET}" ]]; then
      echo -e "${_CLR_RED}[✗] var CP4BA_INST_LDAP_SECRET not set, must be set when CP4BA_INST_LDAP=true, update your configuration file and rerun.${_CLR_NC}"
    fi
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

  if [[ "${CP4BA_INST_DB}" = "true" ]]; then
    ./cp4ba-install-db.sh -c ${_CFG}
    if [[ $? -ne 0 ]]; then
      echo -e "${_CLR_RED}[✗] Error, DB not installed.${_CLR_NC}"
      exit 1
    fi
  fi

  if [[ "${CP4BA_INST_TYPE}" != "starter" ]]; then
    ./cp4ba-create-secrets.sh -c ${_CFG} -s -t 0
    if [[ $? -ne 0 ]]; then
      echo -e "${_CLR_RED}[✗] Error, secrets not configured.${_CLR_NC}"
      exit 1
    fi
  fi
}

#-------------------------------
deployPostEnv () {
  if [[ "${CP4BA_INST_DB}" = "true" ]]; then
    ./cp4ba-create-databases.sh -c ${_CFG} -w
    if [[ $? -ne 0 ]]; then
      echo -e "${_CLR_RED}[✗] Error, databases not created.${_CLR_NC}"
      exit 1
    fi
  fi
}

#-------------------------------
deployPFS () {
  if [[ "${CP4BA_INST_PFS}" = "true" ]]; then
    _PFS_SCRIPT="${CP4BA_INST_PFS_TOOLS_FOLDER}/scripts/pfs-deploy.sh"

    if [[ -f "${_PFS_SCRIPT}" ]]; then

      _PFS_PRAMS_FILE="/tmp/cp4ba-pfs-params-$USER-$RANDOM"

      echo "CP4BA_INST_PFS_NAME=\"${CP4BA_INST_PFS_NAME}\"" > ${_PFS_PRAMS_FILE}
      echo "CP4BA_INST_PFS_NAMESPACE=\"${CP4BA_INST_PFS_NAMESPACE}\"" >> ${_PFS_PRAMS_FILE}
      echo "CP4BA_INST_PFS_STORAGE_CLASS=\"${CP4BA_INST_PFS_STORAGE_CLASS}\"" >> ${_PFS_PRAMS_FILE}
      echo "CP4BA_INST_PFS_APP_VER=\"${CP4BA_INST_PFS_APP_VER}\"" >> ${_PFS_PRAMS_FILE}
      echo "CP4BA_INST_PFS_ADMINUSER=\"${CP4BA_INST_PFS_ADMINUSER}\"" >> ${_PFS_PRAMS_FILE}

      echo -e "${_CLR_GREEN}Wait for PFS deployment '${_CLR_YELLOW}${CP4BA_INST_PFS_NAME}${_CLR_GREEN}' to complete${_CLR_NC}"
      # launch in embedded mode, no wait
      /bin/bash ${_PFS_SCRIPT} -c ${_PFS_PRAMS_FILE} -e 1>/dev/null
      echo -e "${_CLR_GREEN}PFS '${_CLR_YELLOW}${CP4BA_INST_PFS_NAME}${_CLR_GREEN}' deployment complete${_CLR_NC}"

      rm ${_PFS_PRAMS_FILE}
    else
      echo -e "${_CLR_RED}[✗] Error, PFS tool script not found (check var CP4BA_INST_PFS_TOOLS_FOLDER), PFS CR not generated.${_CLR_NC}"
      exit 1
    fi
  fi

}

#-------------------------------
generateCR () {
  _INST_ENV_FULL_PATH="${CP4BA_INST_OUTPUT_FOLDER}/cp4ba-${CP4BA_INST_CR_NAME}-${CP4BA_INST_ENV}.yaml"
  envsubst < ../templates/${CP4BA_INST_CR_TEMPLATE} > ${_INST_ENV_FULL_PATH}
  if [[ $? -ne 0 ]]; then
    echo -e "${_CLR_RED}[✗] Error, CP4BA CR not generated.${_CLR_NC}"
    exit 1
  fi

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
  echo -e "${_CLR_GREEN}CR for ICP4ACluster '${_CLR_YELLOW}${CP4BA_INST_CR_NAME}${_CLR_GREEN}' saved\nin file '${_CLR_YELLOW}${_INST_ENV_FULL_PATH}${_CLR_YELLOW}'${_CLR_NC}"
}

#-------------------------------
deployEnvironment () {
  generateCR

  echo -e "=============================================================="
  echo -e "${_CLR_GREEN}Deploying ICP4ACluster '${_CLR_YELLOW}${CP4BA_INST_CR_NAME}${_CLR_GREEN}'${_CLR_NC}"

  _INST_ENV_FULL_PATH="${CP4BA_INST_OUTPUT_FOLDER}/cp4ba-${CP4BA_INST_CR_NAME}-${CP4BA_INST_ENV}.yaml"
  oc apply -n ${CP4BA_INST_NAMESPACE} -f ${_INST_ENV_FULL_PATH}
  if [ $? -gt 0 ]; then
    echo -e ">>> \x1b[5mERROR\x1b[25m <<<"
    echo -e "${_CLR_RED}[✗] Cannot deploy CP4BA CR '${_CLR_YELLOW}${_INST_ENV_FULL_PATH}${_CLR_RED}', use yq to verify"
    exit 1
  fi

}

#-------------------------------
waitForPfsReady () {
#    echo "namespace name: $1"
#    echo "resource name: $2"
#    echo "time to wait: $3"

    while [ true ]
    do
      _PFS_COMPONENTS=$(oc get pfs -n $1 $2 -o jsonpath='{.status.components.pfs}')
      _pfsDeployment=$(echo $_PFS_COMPONENTS | jq .pfsDeployment | sed 's/"//g' )
      _pfsService=$(echo $_PFS_COMPONENTS | jq .pfsService | sed 's/"//g' )
      _pfsZenIntegration=$(echo $_PFS_COMPONENTS | jq .pfsZenIntegration | sed 's/"//g' )
      if [[ "${_pfsDeployment}" = "Ready" ]] && [[ "${_pfsService}" = "Ready" ]] && [[ "${_pfsZenIntegration}" = "Ready" ]]; then
          return 1
      else
          sleep $3
      fi
    done
    return 0
}

#-------------------------------
federateBaw () {
  _BAW_NAME=$1
  _HOST_FED_PORTAL=$2

  if [[ -z "${_BAW_NAME}" ]]; then
    echo -e ">>> \x1b[5mERROR\x1b[25m <<<"
    echo -e "${_CLR_RED}[✗] Cannot federate BAW '${_CLR_YELLOW}${_BAW_NAME}${_CLR_RED}', name not found in configuration.${_CLR_NC}"
    exit 1
  fi
  echo -e "${_CLR_GREEN}PFS - Federating BAW: '${_CLR_YELLOW}"${_BAW_NAME}"${_CLR_GREEN}'${_CLR_NC}"

  _PFS_CR_NAME=""
  if [[ "${CP4BA_INST_PFS}" = "true" ]]; then
    _PFS_CR_NAME=${CP4BA_INST_PFS_NAME}
  else
    _PFS_CR_NAME=$(oc get pfs --no-headers | awk '{print $1}')
  fi

  waitForResourceCreated ${CP4BA_INST_NAMESPACE} "pfs" ${_PFS_CR_NAME} 5

  if [[ ! -z "${_PFS_CR_NAME}" ]]; then
    waitForPfsReady ${CP4BA_INST_NAMESPACE} ${_PFS_CR_NAME} 5

    _RND_PART=$RANDOM
    _FILE_ORIG="/tmp/icp4-${_PFS_CR_NAME}-${_RND_PART}.json.orig"
    _FILE_BAW_FEDERATED="/tmp/icp4-baw-federated-${_RND_PART}.json"
    _FILE_ALL_BUT_BAW_FEDERATED="/tmp/icp4-all-but-baw-federated-${_RND_PART}.json"
    _FILE_FINAL="/tmp/icp4-${_PFS_CR_NAME}-final-${_RND_PART}.json"

    _PFS_FULL_URL=$(oc get pfs -n ${CP4BA_INST_NAMESPACE} ${_PFS_CR_NAME} -o jsonpath='{.status.endpoints}' | jq '.[] | select(.scope == "External")' | jq .uri | sed 's/"//g' | sed 's/https:\/\///g')

    _PFS_CTX="/"$(echo ${_PFS_FULL_URL} | sed 's/.*\///g')
    _PFS_HOST=$(echo ${_PFS_FULL_URL} | sed 's/\/.*//g')

    if [[ -z "${_PFS_HOST}" ]] || [[ -z "${_PFS_CTX}" ]]; then
        echo -e ">>> \x1b[5mERROR\x1b[25m <<<"
        echo -e "${_CLR_RED}[✗] Cannot federate BAW '${_CLR_YELLOW}${_BAW_NAME}${_CLR_RED}', PFS host/ctx not found in endpoints.${_CLR_NC}"
        exit 1
    fi

    _patched=0
    _tryPatch=0
    _maxTryPatch=10
    _patchInterval=3
    while [[ $_tryPatch -le $_maxTryPatch ]]
    do
      oc get icp4acluster -n ${CP4BA_INST_NAMESPACE} ${CP4BA_INST_CR_NAME} -o json > ${_FILE_ORIG}
      # extract and update baw section 
      jq '.spec.baw_configuration[] | select(.name=="'${_BAW_NAME}'") | .host_federated_portal='${_HOST_FED_PORTAL}' | .process_federation_server.hostname="'${_PFS_HOST}'" | .process_federation_server.context_root_prefix="'${_PFS_CTX}'"' ${_FILE_ORIG} > ${_FILE_BAW_FEDERATED}
      # remove old baw section from CR
      jq '. | del(.spec.baw_configuration[] | select(.name=="'${_BAW_NAME}'"))' ${_FILE_ORIG} > ${_FILE_ALL_BUT_BAW_FEDERATED}
      # add new baw section in CR
      jq --argjson p "$(<${_FILE_BAW_FEDERATED})" '.spec.baw_configuration += [$p]' ${_FILE_ALL_BUT_BAW_FEDERATED} > ${_FILE_FINAL}
      # update CR
      oc apply -f ${_FILE_FINAL} 1>/dev/null
      _ERR=$?
      if [[ $_ERR -gt 0 ]]; then
        ((_tryPatch = _tryPatch + 1))
        sleep ${_patchInterval}
      else
        _patched=1
        break
      fi
    done
    rm ${_FILE_ORIG} 2>/dev/null
    rm ${_FILE_BAW_FEDERATED} 2>/dev/null
    rm ${_FILE_ALL_BUT_BAW_FEDERATED} 2>/dev/null
    rm ${_FILE_FINAL} 2>/dev/null

    if [[ $_patched -eq 0 ]]; then
      echo -e ">>> \x1b[5mERROR\x1b[25m <<<"
      echo -e "${_CLR_RED}[✗] Unable to patch CR '${_CLR_YELLOW}${CP4BA_INST_CR_NAME}${_CLR_RED}${_CLR_NC}'"
      exit 1
    fi
  else
    echo -e "${_CLR_YELLOW}WARNING: PFS instance not found, federation ignored for BAWs in'${_CLR_GREEN}${CP4BA_INST_CR_NAME}${_CLR_YELLOW}'${_CLR_NC}"
  fi
}

waitForPfsReady () {
  _PFS_COMPONENTS=$(oc get pfs -n ${CP4BA_INST_PFS_NAMESPACE} ${CP4BA_INST_PFS_NAME} -o jsonpath='{.status.components.pfs}')
  _pfsDeployment=$(echo $_PFS_COMPONENTS | jq .pfsDeployment 2>/dev/null | sed 's/"//g' )
  _pfsService=$(echo $_PFS_COMPONENTS | jq .pfsService 2>/dev/null | sed 's/"//g' )
  _pfsZenIntegration=$(echo $_PFS_COMPONENTS | jq .pfsZenIntegration 2>/dev/null | sed 's/"//g' )
  if [[ "${_pfsDeployment}" = "Ready" ]] && [[ "${_pfsService}" = "Ready" ]] && [[ "${_pfsZenIntegration}" = "Ready" ]]; then
      return 1
  fi
  return 0
}

federateBawsInDeployment () {

  i=1
  _MAX_BAW=10
  while [[ $i -le $_MAX_BAW ]]
  do
    __BAW_INST="CP4BA_INST_BAW_${i}"
    __BAW_NAME="CP4BA_INST_BAW_${i}_NAME"
    __BAW_FEDERATE="CP4BA_INST_BAW_${i}_FEDERATED"
    __BAW_HOST_FED_PORTAL="CP4BA_INST_BAW_${i}_HOST_FEDERATED_PORTAL"

    _INST="${!__BAW_INST}"
    _FEDERATE="${!__BAW_FEDERATE}"
    _NAME="${!__BAW_NAME}"
    _HFP="${!__BAW_HOST_FED_PORTAL}"
    if [[ "${_INST}" = "true" ]] && [[ "${_FEDERATE}" = "true" ]]; then
      federateBaw "${_NAME}" "${_HFP}"
      _NAME=""
    else
      if [[ ! -z "${_NAME}" ]]; then
        echo -e "${_CLR_GREEN}PFS - skipping BAW: '${_CLR_YELLOW}"${_BAW_NAME}"${_CLR_GREEN}'${_CLR_NC}"
      fi 
    fi
    ((i=i+1))
  done
}

waitDeploymentReadiness () {
  echo -e "${_CLR_GREEN}Configuration and deployment complete for '${_CLR_YELLOW}${CP4BA_INST_CR_NAME}${_CLR_GREEN}'${_CLR_NC}"

  _seconds=0
  _total_warnings=0
  _warning_interval=10
  _ROTOR="|/-\\|/-\\"
  _ROTOR_LEN=${#_ROTOR}

  START_SECONDS=$SECONDS

  _PFS_READY=1
  while [ true ]; 
  do   
    if [[ "${CP4BA_INST_PFS}" = "true" ]]; then
      waitForPfsReady
      _PFS_READY=$?
    fi
    _CR_READY=$(oc get ICP4ACluster -n ${CP4BA_INST_NAMESPACE} ${CP4BA_INST_CR_NAME} -o jsonpath='{.status.conditions}' 2>/dev/null | jq '.[] | select(.type == "Ready")' | jq .status | sed 's/"//g')
    if [[ "${_CR_READY}" = "True" ]] && [[ ${_PFS_READY} -eq 1 ]]; then

      if [[ "${_WAIT_ONLY}" = "false" ]]; then
        resourceExist ${CP4BA_INST_NAMESPACE} "pfs" ${CP4BA_INST_PFS_NAME}
        if [ $? -eq 1 ]; then
          federateBawsInDeployment
        fi
      fi
      
      echo -e "${_CLR_GREEN}ICP4ACluster '${_CLR_YELLOW}${CP4BA_INST_CR_NAME}${_CLR_GREEN}' is ready.${_CLR_NC}"
      ACC_INFO=$(oc get cm -n ${CP4BA_INST_NAMESPACE} --no-headers | grep access-info | awk '{print $1}' | xargs oc get cm -n ${CP4BA_INST_NAMESPACE} -o jsonpath='{.data}')
      NUM_KEYS=$(echo $ACC_INFO | jq length)
      echo "" > ${CP4BA_INST_OUTPUT_FOLDER}/cp4ba-${CP4BA_INST_CR_NAME}-${CP4BA_INST_ENV}-access-info.txt
      echo 
      for (( i=0; i<$NUM_KEYS; i++ ));
      do
        KEY=$(echo $ACC_INFO | jq keys[$i])
        echo -e $(echo $ACC_INFO | jq .[$KEY] | sed 's/"//g' | sed '/^$/d') >> ${CP4BA_INST_OUTPUT_FOLDER}/cp4ba-${CP4BA_INST_CR_NAME}-${CP4BA_INST_ENV}-access-info.txt
      done
      echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"     
      echo "See acces info urls in file ${CP4BA_INST_OUTPUT_FOLDER}/cp4ba-${CP4BA_INST_CR_NAME}-${CP4BA_INST_ENV}-access-info.txt"     
      echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"     
      break
    fi
    _pending_pvc_count=0
    _operator_failures=0
    _WARNING_PENDING=""
    if [ $_warning_interval -gt 10 ]; then
      # check for failures and pending pvc (for pending items there are no immediate errors from operators)
      _warning_interval=0
      _pending_pvc_count=$(oc get pvc -n ${CP4BA_INST_NAMESPACE} --no-headers 2>/dev/null| grep Pending | grep -Ev "ibm-zen-cs-mongo-backup|ibm-zen-objectstore-backup-pvc" | wc -l)
      _operator_failures=$(oc logs -n ${CP4BA_INST_NAMESPACE} -c operator $(oc get pods -n ${CP4BA_INST_NAMESPACE} 2>/dev/null | grep cp4a-operator- | awk '{print $1}') 2>/dev/null | grep "FAIL" | uniq | wc -l)
      ((_total_warnings=_pending_pvc_count+_operator_failures))
      if [ $_total_warnings -gt 0 ]; then
        if [ $_total_warnings -gt 99 ]; then
          # limit the output to double digit
          _pending_pv_total_warningsc_count=99
        fi
      fi
    else
      ((_warning_interval=_warning_interval+1))
    fi
    if [ $_total_warnings -gt 0 ]; then
      # format the output
      _WARNING_PENDING="${_total_warnings:0:2}${_WARNING_PENDING:0:$((2 - ${#_total_warnings}))}"
    fi
    _ROTOR_CHAR_OFF=$((_seconds % _ROTOR_LEN))
    _ROTOR_CHAR="${_ROTOR:_ROTOR_CHAR_OFF:1}"

    NOW_SECONDS=$SECONDS
    ELAPSED_SECONDS=$(( $NOW_SECONDS - $START_SECONDS ))
    TOT_SECONDS=$(($ELAPSED_SECONDS % 60))
    TOT_MINUTES=$(( $(($ELAPSED_SECONDS / 60)) % 60))
    TOT_HOURS=$(( $(($ELAPSED_SECONDS / 3600)) % 24))

    echo -e -n "${_CLR_GREEN}Wait for ICP4ACluster '${_CLR_YELLOW}${CP4BA_INST_CR_NAME}${_CLR_GREEN}' to be ready (${_CLR_YELLOW} ${_ROTOR_CHAR} ${_CLR_GREEN}) warnings [${_CLR_RED}${_WARNING_PENDING}${_CLR_GREEN}] elapsed time [${_CLR_YELLOW}$TOT_HOURS${_CLR_GREEN}h:${_CLR_YELLOW}$TOT_MINUTES${_CLR_GREEN}m:${_CLR_YELLOW}$TOT_SECONDS${_CLR_GREEN}s]${_CLR_NC}\033[0K\r"
    ((_seconds=_seconds+1))
    sleep 1
  done
}


echo -e "${_CLR_YELLOW}=============================================================="
echo -e "${_CLR_YELLOW}Deploying CP4BA environment '${_CLR_GREEN}${CP4BA_INST_ENV}${_CLR_YELLOW}' in namespace '${_CLR_GREEN}${CP4BA_INST_NAMESPACE}${_CLR_YELLOW}'${_CLR_NC}"
echo -e "${_CLR_GREEN}Tag '${_CLR_YELLOW}appVersion${_CLR_GREEN}' is '${_CLR_YELLOW}${CP4BA_INST_APPVER}${_CLR_GREEN}'${_CLR_NC}"
echo -e "${_CLR_YELLOW}==============================================================${_CLR_NC}"
checkPrepreqTools
checkPrereqVars

if [[ "${_GENERATE_ONLY}" = "true" ]]; then
  generateCR
  ./cp4ba-create-databases.sh -c ${_CFG} -g
  if [[ -z "${_LDAP}" ]] && [[ "${CP4BA_INST_TYPE}" = "production" ]]; then
    echo ""
    echo -e "${_CLR_YELLOW}WARNING${_CLR_GREEN}: no LDAP data has been configured, update manually the generated CR.${_CLR_NC}" 
  fi
  echo -e "${_CLR_GREEN}If you intend to manually deploy the generated CR, remember to create/configure all the prerequisites (LDAP, DBs, secrets, etc...)${_CLR_NC}"
  exit 0
fi

# verify logged in OCP
oc whoami 2>/dev/null 1>/dev/null
if [ $? -gt 0 ]; then
  echo -e "${_CLR_RED}[✗] Not logged in to OCP cluster. Please login to an OCP cluster and rerun this command. ${_CLR_NC}"
  exit 1
fi

namespaceExist ${CP4BA_INST_NAMESPACE}
if [ $? -eq 1 ]; then

  if [[ -z "${CP4BA_INST_APPVER}" ]]; then
    echo -e "${_CLR_RED}[✗] Error, var '${_CLR_YELLOW}CP4BA_INST_APPVER${_CLR_RED}' not set, cannot continue. ${_CLR_NC}"
    exit 1
  fi
  
  if [[ "${_WAIT_ONLY}" = "false" ]]; then
    mkdir -p ${CP4BA_INST_OUTPUT_FOLDER}
    deployPreEnv
    deployEnvironment
    deployPostEnv
    deployPFS
  fi
  waitDeploymentReadiness

  echo -e "${_CLR_GREEN}CP4BA environment '${_CLR_YELLOW}${CP4BA_INST_ENV}${_CLR_GREEN}' in namespace '${_CLR_YELLOW}${CP4BA_INST_NAMESPACE}${_CLR_GREEN}' is \x1b[5mREADY\x1b[25m${_CLR_NC}"
  exit 0

else
  echo -e "${_CLR_RED}[✗] Error, namespace '${_CLR_YELLOW}${CP4BA_INST_NAMESPACE}${_CLR_RED}' doesn't exists. ${_CLR_NC}"
  exit 1
fi
