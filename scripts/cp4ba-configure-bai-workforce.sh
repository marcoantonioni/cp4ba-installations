#!/bin/bash

_me=$(basename "$0")

_CFG=""

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
    esac
done

if [[ -z "${_CFG}" ]]; then
  echo "usage: $_me -c path-of-config-file"
  exit 1
fi

source ${_CFG}

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

    #echo "===> ibm-ban-secret: " $username " / " $password
    if [[ -z "$username" ]] || [[ -z "$password" ]]; then
      echo -e "${_CLR_RED}[✗] Error, secret ibm-ban-secret not found or username or password is empty.${_CLR_NC}"
      exit 1
    fi

    #--------------------------------
    # NEW
    # echo "wait cm access-info..."
    while [ true ]
    do
      cmName=$(oc get cm -n ${_NS} | grep access-info | awk '{print $1}')
      if [[ -z "${cmName}" ]]; then
          sleep 5
      else
        # echo "wait for "${cmName}
        _WFS_URL=$(oc get cm -n ${_NS} ${cmName} -o yaml | grep "Business Automation Workflow .* base URL" | head -1 | awk '{print $7}' | sed s'/.$//')      
        if [[ ! -z "${_WFS_URL}" ]]; then
          # echo "Workflow server url: "$_WFS_URL
          break
        fi
      fi
    done
    
    # OLD
    # _WFS_URL=$(oc get cm -n ${_NS} $(oc get cm -n ${_NS} | grep access-info | awk '{print $1}') -o yaml | grep "Business Automation Workflow .* base _WFS_URL" | head -1 | awk '{print $7}' | sed s'/.$//')
    #--------------------------
    
    iamhost="https://"$(oc get route -n ${_NS} ${_ROUTE_NAME} -o jsonpath="{.spec.host}" )
    platformauth="https://"$(oc get route -n ${_NS} cpd -o jsonpath="{.spec.host}" )

    # echo "===> iamhost: " ${iamhost}
    # echo "===> platformauth: " ${platformauth}

    if [[ ${_ROUTE_NAME} = "platform-id-provider" ]]; then
      iamaccesstoken=$(curl -sk -X POST -H "Content-Type: application/x-www-form-urlencoded;charset=UTF-8" -d "grant_type=password&username=${username}&password=${password}&scope=openid" ${platformauth}/v1/auth/identitytoken | jq -r .access_token)
    else
      iamaccesstoken=$(curl -sk -X POST -H "Content-Type: application/x-www-form-urlencoded;charset=UTF-8" -d "grant_type=password&username=${username}&password=${password}&scope=openid" ${iamhost}/idprovider/v1/auth/identitytoken | jq -r .access_token)
    fi

    # echo "===> iamaccesstoken: " ${iamaccesstoken}

    zentoken=$(curl -sk ${platformauth}/v1/preauth/validateAuth -H "username:${username}" -H "iam-token: ${iamaccesstoken}" | jq -r .accessToken)
        
    # echo "===> zentoken: " ${zentoken}

    type=$(oc get icp4acluster -n ${_NS} -o yaml | grep -E "sc_deployment_type|olm_deployment_type"| tail -1 |awk '{print $2}')
    
    # echo "===> deloyment type: " ${type}

    bpmSystemID=$(curl -sk -X GET ${_WFS_URL}/rest/bpm/wle/v1/systems -H "Accept: application/json" -H "Authorization: Bearer ${zentoken}" | jq -r .data.systems[].systemID)

    # !!! verificare nome secret PROD
    _adminSecret="bas-admin-secret"
    adminUsername=$(oc get secret -n ${_NS} $(oc get secret -n ${_NS} |grep ${_adminSecret} | awk '{print $1}') -o jsonpath='{.data.adminUser}'|base64 -d)
    adminPassword=$(oc get secret -n ${_NS} $(oc get secret -n ${_NS} |grep ${_adminSecret} | awk '{print $1}') -o jsonpath='{.data.adminPassword}'|base64 -d)

    # echo ${_WFS_URL}
    # echo "===> bpmSystemID: " $bpmSystemID
    # echo "===> adminUsername: " $adminUsername
    # echo "===> adminPassword: " $adminPassword

    secret_name=$(oc get icp4acluster -n ${_NS} $(oc get icp4acluster -n ${_NS} --no-headers | awk '{print $1}') -o jsonpath='{.spec.bai_configuration.business_performance_center.workforce_insights_secret}')
    if [[ ! -z ${secret_name} ]]; then
      oc delete secret -n ${_NS} ${secret_name} 2>/dev/null 1>/dev/null
    #else
    #  echo "INFO: workforce_insights_secret not found"
    fi

    _BAI_WKF_TMP="/tmp/cp4ba-bai-wkf-secret-$USER-$RANDOM"
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
    echo "Patching ICP4ACluster: "${BA_DN}

    _WX_BAI_WKF_TMP="/tmp/cp4ba-bai-workforce-$USER-$RANDOM"

#    if [[ "${CP4BA_INST_TYPE}" = "starter" ]]; then
#      echo 'spec:' > ${_WX_BAI_WKF_TMP}
#      echo '  bastudio_configuration:' >> ${_WX_BAI_WKF_TMP}
#      echo '    custom_secret_name: '${CP4BA_INST_GENAI_WX_AUTH_SECRET} >> ${_WX_BAI_WKF_TMP}
#      echo '    bastudio_custom_xml: |' >> ${_WX_BAI_WKF_TMP}
#      echo '      <properties>' >> ${_WX_BAI_WKF_TMP}
#      echo '        <server>' >> ${_WX_BAI_WKF_TMP}
#      echo '          <gen-ai merge="mergeChildren">' >> ${_WX_BAI_WKF_TMP} 
#      echo '            <project-id>'${CP4BA_INST_GENAI_WX_PRJ_ID}'</project-id>' >> ${_WX_BAI_WKF_TMP}
#      echo '            <provider-url>'${CP4BA_INST_GENAI_WX_URL_PROVIDER}'</provider-url>' >> ${_WX_BAI_WKF_TMP}
#      echo '            <auth-alias>watsonx.ai_auth_alias</auth-alias>' >> ${_WX_BAI_WKF_TMP}
#      echo '          </gen-ai>' >> ${_WX_BAI_WKF_TMP}
#      echo '        </server>' >> ${_WX_BAI_WKF_TMP}
#      echo '      </properties>' >> ${_WX_BAI_WKF_TMP}
#    else
#      echo -e "${_CLR_RED}[✗] ERROR: _createBAIWorkforceConfiguration GenAI not yet implemented for 'production' type deployment.${_CLR_NC}"
#    fi
#
#    oc patch ICP4ACluster ${BA_DN} -n $1 --type=merge --patch-file=${_WX_BAI_WKF_TMP}
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
}

#==================================

echo -e "=============================================================="
echo -e "${_CLR_GREEN}Configuring BAI Workforce '${_CLR_YELLOW}${CP4BA_INST_NAMESPACE}${_CLR_GREEN}' namespace${_CLR_NC}"

configureBAIWorkforce ${CP4BA_INST_NAMESPACE}

