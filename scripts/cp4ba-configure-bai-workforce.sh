#!/bin/bash

#set -euo pipefail

_TRACE=0

_me=$(basename "$0")

_CFG=""

#--------------------------------------------------------
_CLR_RED="\033[0;31m"   #'0;31' is Red's ANSI color code
_CLR_GREEN="\033[0;32m"   #'0;32' is Green's ANSI color code
_CLR_YELLOW="\033[1;33m"   #'1;32' is Yellow's ANSI color code
_CLR_BLUE="\033[0;34m"   #'0;34' is Blue's ANSI color code
_CLR_NC="\033[0m"


#--------------------------------------------------------
# read command line params
while getopts c:s: flag
do
    case "${flag}" in
        c) _CFG=${OPTARG};;
    esac
done

if [[ -z "${_CFG}" ]]; then
  echo "usage: $_me -c path-of-config-file"
  exit 1
fi

source "${_CFG}"

#--------------------------------------------------------
_INST_TMP_FOLDER="/tmp"
setTemporaryFolder () {
  _OK=0
  _ERR_MSG_FOLDER="is a folder"
  _ERR_MSG_PERMISSIONS=""
  if [[ ! -z "${CP4BA_INST_TMP_FOLDER}" ]]; then
    if [[ -d "${CP4BA_INST_TMP_FOLDER}" ]]; then
      if [[ -r "${CP4BA_INST_TMP_FOLDER}" ]] && [[ -w "${CP4BA_INST_TMP_FOLDER}" ]]; then 
        _OK=1
      else
        _ERR_MSG_PERMISSIONS=", you have not rights to read and/or write"
        _OK=-1
      fi
    else
      _ERR_MSG_FOLDER="is NOT a folder"
    fi

    if [[ $_OK -lt 1 ]]; then
      echo -e "${_CLR_RED}[✗] ERROR '${_CLR_YELLOW}${CP4BA_INST_TMP_FOLDER}${_CLR_RED}' is not a valid temporary folder, check if it is a folder or if you have write permissions !${_CLR_NC}"
      echo -e "${_CLR_RED}'${_CLR_YELLOW}${CP4BA_INST_TMP_FOLDER}${_CLR_RED}' ${_ERR_MSG_FOLDER}${_ERR_MSG_PERMISSIONS}${_CLR_NC}"
      exit 1
    fi
    export _INST_TMP_FOLDER="${CP4BA_INST_TMP_FOLDER}"
  fi
  echo -e "${_CLR_GREEN}Running with temporary folder '${_CLR_YELLOW}${_INST_TMP_FOLDER}${_CLR_GREEN}'${_CLR_NC}"

}



#--------------------------------------------------------
resourceExist () {
#    echo "namespace name: $1"
#    echo "resource type: $2"
#    echo "resource name: $3"
  if [ $(oc get $2 -n $1 $3 2> /dev/null | grep $3 2>/dev/null | wc -l 2>/dev/null) -lt 1 ];
  then
      return 0
  fi
  return 1
}

#-------------------------------
namespaceExist () {
# ns name: $1
  if [ $(oc get ns $1 2>/dev/null | grep $1 2>/dev/null | wc -l 2>/dev/null ) -lt 1 ];
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

  while true 
  do
      resourceExist $1 $2 $3
      if [ $? -eq 0 ]; then
          sleep $4
      else
          break
      fi
  done
}

#--------------------------------------------------------
_createBAIWorkforceSecret () {
  if [[ ! -z "$1" ]] && [[ ! -z "$2" ]]; then

    _NS=$1

    resourceExist ${CP4BA_INST_NAMESPACE} "routes" "cpd"
    if [ $? -eq 0 ]; then
      echo -e "${_CLR_GREEN}Wait for resource '${_CLR_YELLOW}cpd${_CLR_GREEN}'..."
      waitForResourceCreated ${CP4BA_INST_NAMESPACE} "routes" "cpd" 5
    fi

    _ROUTE_NAME="cp-console"
    if [ $(oc get routes -n ${_NS} $_ROUTE_NAME --no-headers 2> /dev/null | wc -l 2>/dev/null) -lt 1 ]; then
      _ROUTE_NAME="platform-id-provider"
      echo "Using console route name [${_ROUTE_NAME}]"
    fi

    resourceExist ${CP4BA_INST_NAMESPACE} "routes" ${_ROUTE_NAME}
    if [ $? -eq 0 ]; then
      echo -e "${_CLR_GREEN}Wait for resource '${_CLR_YELLOW}${_ROUTE_NAME}${_CLR_GREEN}'..."
      waitForResourceCreated ${CP4BA_INST_NAMESPACE} "routes" ${_ROUTE_NAME} 5
    fi


    resourceExist $1 secret $2
    if [ $? -eq 1 ]; then
      oc delete secret -n $1 $2 2>/dev/null 1>/dev/null
    fi

    username=$(oc get secret -n ${_NS} ibm-ban-secret -ojsonpath='{.data.appLoginUsername}'|base64 -d)
    password=$(oc get secret -n ${_NS} ibm-ban-secret -ojsonpath='{.data.appLoginPassword}'|base64 -d)

    [[ ${_TRACE} -eq 1 ]] && echo "===> ibm-ban-secret: " $username " / " $password
    if [[ -z "$username" ]] || [[ -z "$password" ]]; then
      echo -e "${_CLR_RED}[✗] Error, secret ibm-ban-secret not found or username or password is empty.${_CLR_NC}"
      exit 1
    fi

    #--------------------------------
    # NEW
    # echo "wait cm access-info..."
    while true 
    do
      cmName=$(oc get cm -n ${_NS} | grep access-info | awk '{print $1}')
      if [[ -z "${cmName}" ]]; then
          sleep 5
      else
        # echo "wait for "${cmName}
        # _WFS_URL=$(oc get cm -n ${_NS} ${cmName} -o yaml | grep "Business Automation Workflow .* base URL" | head -1 | awk '{print $7}' | sed s'/.$//')  
        _WFS_URL=$(oc get cm -n ${_NS} ${cmName} -o yaml | grep "Business Automation Workflow .* base URL:" | sed 's/.*URL://g' | sed 's/ //g')

        if [[ ! -z "${_WFS_URL}" ]]; then
          [[ ${_TRACE} -eq 1 ]] && echo "Workflow server url: "$_WFS_URL
          break
        fi
      fi
    done
    
    # OLD
    # _WFS_URL=$(oc get cm -n ${_NS} $(oc get cm -n ${_NS} | grep access-info | awk '{print $1}') -o yaml | grep "Business Automation Workflow .* base _WFS_URL" | head -1 | awk '{print $7}' | sed s'/.$//')
    #--------------------------
    
    iamhost="https://"$(oc get route -n ${_NS} ${_ROUTE_NAME} -o jsonpath="{.spec.host}" )
    platformauth="https://"$(oc get route -n ${_NS} cpd -o jsonpath="{.spec.host}" )

    [[ ${_TRACE} -eq 1 ]] && echo "===> iamhost: " ${iamhost}
    [[ ${_TRACE} -eq 1 ]] && echo "===> platformauth: " ${platformauth}

    if [[ ${_ROUTE_NAME} = "platform-id-provider" ]]; then
      iamaccesstoken=$(curl -sk -X POST -H "Content-Type: application/x-www-form-urlencoded;charset=UTF-8" -d "grant_type=password&username=${username}&password=${password}&scope=openid" ${platformauth}/v1/auth/identitytoken | jq -r .access_token)
    else
      iamaccesstoken=$(curl -sk -X POST -H "Content-Type: application/x-www-form-urlencoded;charset=UTF-8" -d "grant_type=password&username=${username}&password=${password}&scope=openid" ${iamhost}/idprovider/v1/auth/identitytoken | jq -r .access_token)
    fi

    [[ ${_TRACE} -eq 1 ]] && echo "===> iamaccesstoken: " ${iamaccesstoken}

    zentoken=$(curl -sk ${platformauth}/v1/preauth/validateAuth -H "username:${username}" -H "iam-token: ${iamaccesstoken}" | jq -r .accessToken)
        
    [[ ${_TRACE} -eq 1 ]] && echo "===> zentoken: " ${zentoken}

    type=$(oc get icp4acluster -n ${_NS} -o yaml | grep -E "sc_deployment_type|olm_deployment_type"| tail -1 |awk '{print $2}')
    
    [[ ${_TRACE} -eq 1 ]] && echo "===> deloyment type: " ${type}

    _IS_SLASH=""
    if [[ "${_WFS_URL}" != */ ]]; then
      _IS_SLASH="/"
    fi

    bpmSystemID=$(curl -sk -X GET ${_WFS_URL}${_IS_SLASH}rest/bpm/wle/v1/systems -H "Accept: application/json" -H "Authorization: Bearer ${zentoken}" | jq -r .data.systems[].systemID)

    _adminSecret="bas-admin-secret"
    _DEV_ENV=$(oc get secret --no-headers -n ${_NS} | grep "${CP4BA_INST_CR_NAME}-bas" | wc -l)
    if [[ ${_DEV_ENV} -eq 0 ]]; then
      #echo "TBD: ===>>> get baw name "
      _BAW_NAME=$(echo "${_WFS_URL}" | awk -F / -v OFS=/ '{ print $(NF-1), $NF }' | sed 's#/##g')
      _adminSecret="${CP4BA_INST_CR_NAME}-${_BAW_NAME}-admin-secret"
      [[ ${_TRACE} -eq 1 ]] && echo "===> try secret: " ${_adminSecret}
      resourceExist ${CP4BA_INST_NAMESPACE} "secret" ${_adminSecret} 
      if [[ $? -eq 0 ]]; then
        arrIN=(${_BAW_NAME//-/ })
        _BAW_NAME="${arrIN[1]}-${arrIN[0]}"
        _adminSecret="${CP4BA_INST_CR_NAME}-${_BAW_NAME}-admin-secret"
        [[ ${_TRACE} -eq 1 ]] && echo "===> try secret: " ${_adminSecret}
        resourceExist ${CP4BA_INST_NAMESPACE} "secret" ${_adminSecret} 
        if [[ $? -eq 0 ]]; then
          echo -e "${_CLR_RED}[✗] ERROR: _createBAIWorkforceSecret admin secret name not found${_CLR_NC}"
          exit 1
        fi
      fi

      [[ ${_TRACE} -eq 1 ]] && echo "admin secret name: ${_adminSecret}"
    fi

    adminUsername=$(oc get secret -n ${_NS} $(oc get secret -n ${_NS} |grep ${_adminSecret} | awk '{print $1}') -o jsonpath='{.data.adminUser}'|base64 -d)

    if [[ -z "${adminUsername}" ]]; then
      adminUsername=$(oc get secret -n ${_NS} $(oc get secret -n ${_NS} |grep ${_adminSecret} | awk '{print $1}') -o jsonpath='{.data.adminUsername}'|base64 -d)
    fi

    adminPassword=$(oc get secret -n ${_NS} $(oc get secret -n ${_NS} |grep ${_adminSecret} | awk '{print $1}') -o jsonpath='{.data.adminPassword}'|base64 -d)

    [[ ${_TRACE} -eq 1 ]] && echo ${_WFS_URL}
    [[ ${_TRACE} -eq 1 ]] && echo "===> bpmSystemID: " $bpmSystemID
    [[ ${_TRACE} -eq 1 ]] && echo "===> adminUsername: " $adminUsername
    [[ ${_TRACE} -eq 1 ]] && echo "===> adminPassword: " $adminPassword

    secret_name=$(oc get icp4acluster -n ${_NS} $(oc get icp4acluster -n ${_NS} --no-headers | awk '{print $1}') -o jsonpath='{.spec.bai_configuration.business_performance_center.workforce_insights_secret}')
    if [[ ! -z ${secret_name} ]]; then
      oc delete secret -n ${_NS} ${secret_name} 2>/dev/null 1>/dev/null
    #else
    #  echo "INFO: workforce_insights_secret not found"
    fi

    _BAI_WKF_TMP="${_INST_TMP_FOLDER}/cp4ba-bai-wkf-secret-$USER-$RANDOM"
echo "apiVersion: v1
kind: Secret
metadata:
  name: ${CP4BA_INST_BAI_BPC_WORKFORCE_SECRET}
stringData:
  workforce-insights-configuration.yml: |-
    - bpmSystemId: $bpmSystemID
      url: $_WFS_URL 
      username: $adminUsername
      password: $adminPassword
" > ${_BAI_WKF_TMP}

    # create secret for BAI Workforce
    oc create secret generic -n $1 $2 --from-file=workforce-insights-configuration.yml=${_BAI_WKF_TMP} 2>/dev/null 1>/dev/null

    rm ${_BAI_WKF_TMP} 2>/dev/null 1>/dev/null

  else
    echo -e "${_CLR_RED}[✗] ERROR: _createBAIWorkforceSecret secret name or namespace empty${_CLR_NC}"
    exit 1
  fi
}

#--------------------------------------------------------
_createBAIWorkforceConfiguration () {

  BA_DN=$(oc get ICP4ACluster -n $1 --no-headers | awk '{print $1}')

  if [[ ! -z "${BA_DN}" ]]; then
    # echo "Patching ICP4ACluster: "${BA_DN}

    _WX_BAI_WKF_TMP="${_INST_TMP_FOLDER}/cp4ba-bai-workforce-$USER-$RANDOM"
    _OK_TO_PATCH=0
    if [[ "${CP4BA_INST_TYPE}" = "starter" ]]; then
      echo 'spec:' > ${_WX_BAI_WKF_TMP}
      echo '  bastudio_configuration:' >> ${_WX_BAI_WKF_TMP}
      echo '    custom_secret_name: '${CP4BA_INST_GENAI_WX_AUTH_SECRET} >> ${_WX_BAI_WKF_TMP}
      echo '    bastudio_custom_xml: |' >> ${_WX_BAI_WKF_TMP}
      echo '      <properties>' >> ${_WX_BAI_WKF_TMP}
      echo '        <server>' >> ${_WX_BAI_WKF_TMP}
      echo '          <gen-ai merge="mergeChildren">' >> ${_WX_BAI_WKF_TMP} 
      echo '            <project-id>'${CP4BA_INST_GENAI_WX_PRJ_ID}'</project-id>' >> ${_WX_BAI_WKF_TMP}
      echo '            <provider-url>'${CP4BA_INST_GENAI_WX_URL_PROVIDER}'</provider-url>' >> ${_WX_BAI_WKF_TMP}
      echo '            <auth-alias>watsonx.ai_auth_alias</auth-alias>' >> ${_WX_BAI_WKF_TMP}
      echo '          </gen-ai>' >> ${_WX_BAI_WKF_TMP}
      echo '        </server>' >> ${_WX_BAI_WKF_TMP}
      echo '      </properties>' >> ${_WX_BAI_WKF_TMP}

      _OK_TO_PATCH=1
    else
      echo -e "${_CLR_YELLOW}[✗] WARNING: _createBAIWorkforceConfiguration GenAI not yet implemented for 'production' type deployment.${_CLR_NC}"
    fi

    if [[ ${_OK_TO_PATCH} -eq 1 ]]; then
      oc patch ICP4ACluster ${BA_DN} -n $1 --type=merge --patch-file=${_WX_BAI_WKF_TMP}
      rm "${_WX_BAI_WKF_TMP}" 2>/dev/null 1>/dev/null
    fi
  else
    echo -e "${_CLR_RED}[✗] ERROR: _createBAIWorkforceConfiguration GenAI configuration error, ICP4ACluster object not found.${_CLR_NC}"
    exit 1
  fi
}

#--------------------------------------------------------
_verifyVars() {
  if [[ -z "${CP4BA_INST_BAI_BPC_WORKFORCE_SECRET}" ]]; then
    export CP4BA_INST_BAI_BPC_WORKFORCE_SECRET="custom-bpc-workforce-secret"
  fi
  return 1
}

#--------------------------------------------------------
configureBAIWorkforce() {
  if [[ "${CP4BA_INST_BAI_ENABLE}" = "true" && "${CP4BA_INST_BAI_BPC_WORKFORCE}" = "true" ]]; then
    _verifyVars
    if [ $? -eq 1 ]; then
      namespaceExist $1
      if [ $? -eq 1 ]; then
        _createBAIWorkforceSecret $1 ${CP4BA_INST_BAI_BPC_WORKFORCE_SECRET}
        _createBAIWorkforceConfiguration $1
      else
        echo -e "${_CLR_RED}[✗] Error, namespace '${_CLR_YELLOW}$1${_CLR_RED}' doesn't exists. ${_CLR_NC}"
        exit 1
      fi
    fi
  else
    echo -e "${_CLR_YELLOW}[✗] Warning, BAI or BPC WORKFORCE not enabled in configuration file.${_CLR_NC}"
  fi
}

#==================================

echo -e "=============================================================="
echo -e "${_CLR_GREEN}Configuring BAI Workforce '${_CLR_YELLOW}${CP4BA_INST_NAMESPACE}${_CLR_GREEN}' namespace${_CLR_NC}"

setTemporaryFolder

echo -e "${_CLR_YELLOW}TBD: if runtime deployment iterate on BAWs if more than one...${_CLR_NC}"
configureBAIWorkforce ${CP4BA_INST_NAMESPACE}

