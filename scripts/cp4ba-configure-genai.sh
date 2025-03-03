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
  if [ $(oc get $2 -n $1 $3 2> /dev/null | grep $3 | wc -l) -lt 1 ];
  then
      return 0
  fi
  return 1
}

#--------------------------------------------------------
_createWxSecret () {

  if [[ ! -z "$1" ]] && [[ ! -z "$2" ]]; then

    resourceExist $1 secret $2
    if [ $? -eq 1 ]; then
      oc delete secret -n $1 $2 2>/dev/null 1>/dev/null
    fi

    _WX_GENAI_TMP="/tmp/cp4ba-wx-genai-$USER-$RANDOM"

    # create payload secret
    echo '<server>' > ${_WX_GENAI_TMP}
    echo '  <authData id="watsonx.ai_auth_alias" user="'${CP4BA_INST_GENAI_WX_USERID}'" password="'${CP4BA_INST_GENAI_WX_APIKEY}'"/>' >> ${_WX_GENAI_TMP}
    echo '</server>' >> ${_WX_GENAI_TMP}

    # create secret for watsonx.ai
    oc create secret generic -n $1 $2 --from-file=sensitiveCustom.xml=${_WX_GENAI_TMP} 2>/dev/null 1>/dev/null

    rm ${_WX_GENAI_TMP} 2>/dev/null 1>/dev/null

  else
    echo -e "${_CLR_RED}[✗] ERROR: _createWxSecret secret name or namespace empty${_CLR_NC}"
    exit 1
  fi
}

#--------------------------------------------------------
_createGenAiConfiguration () {

  BA_DN=$(oc get ICP4ACluster -n $1 --no-headers | awk '{print $1}')

  if [[ ! -z "${BA_DN}" ]]; then
    echo "Patching ICP4ACluster: "${BA_DN}

    _WX_GENAI_TMP="/tmp/cp4ba-wx-genai-$USER-$RANDOM"

    if [[ "${CP4BA_INST_TYPE}" = "starter" ]]; then
      echo 'spec:' > ${_WX_GENAI_TMP}
      echo '  bastudio_configuration:' >> ${_WX_GENAI_TMP}
      echo '    custom_secret_name: '${CP4BA_INST_GENAI_WX_AUTH_SECRET} >> ${_WX_GENAI_TMP}
      echo '    bastudio_custom_xml: |' >> ${_WX_GENAI_TMP}
      echo '      <properties>' >> ${_WX_GENAI_TMP}
      echo '        <server>' >> ${_WX_GENAI_TMP}
      echo '          <gen-ai merge="mergeChildren">' >> ${_WX_GENAI_TMP} 
      echo '            <project-id>'${CP4BA_INST_GENAI_WX_PRJ_ID}'</project-id>' >> ${_WX_GENAI_TMP}
      echo '            <provider-url>'${CP4BA_INST_GENAI_WX_URL_PROVIDER}'</provider-url>' >> ${_WX_GENAI_TMP}
      echo '            <auth-alias>watsonx.ai_auth_alias</auth-alias>' >> ${_WX_GENAI_TMP}
      echo '          </gen-ai>' >> ${_WX_GENAI_TMP}
      echo '        </server>' >> ${_WX_GENAI_TMP}
      echo '      </properties>' >> ${_WX_GENAI_TMP}
    else
      echo -e "${_CLR_RED}[✗] ERROR: _createGenAiConfiguration GenAI not yet implemented for 'production' type deployment.${_CLR_NC}"
    fi

    oc patch ICP4ACluster ${BA_DN} -n $1 --type=merge --patch-file=${_WX_GENAI_TMP}
  else
    echo -e "${_CLR_RED}[✗] ERROR: _createGenAiConfiguration GenAI configuration error, ICP4ACluster object not found.${_CLR_NC}"
    exit 1
  fi
}

#--------------------------------------------------------
_verifyVars() {
  _KO_CFG="false"
  _WRONG_VARS=""
  if [[ -z "${CP4BA_INST_GENAI_WX_USERID}" ]]; then
    export CP4BA_INST_GENAI_WX_USERID="${_WX_USERID}"
    if [[ -z "${CP4BA_INST_GENAI_WX_USERID}" ]]; then
      _KO_CFG="true"
      _WRONG_VARS=${_WRONG_VARS}" CP4BA_INST_GENAI_WX_USERID"
    fi
  fi
  if [[ -z "${CP4BA_INST_GENAI_WX_APIKEY}" ]]; then
    export CP4BA_INST_GENAI_WX_APIKEY="${_WX_APIKEY}"
    if [[ -z "${CP4BA_INST_GENAI_WX_APIKEY}" ]]; then
      _KO_CFG="true"
      _WRONG_VARS=${_WRONG_VARS}" CP4BA_INST_GENAI_WX_APIKEY"
    fi
  fi
  if [[ -z "${CP4BA_INST_GENAI_WX_PRJ_ID}" ]]; then
    export CP4BA_INST_GENAI_WX_PRJ_ID="${_WX_PRJ_ID}"
    if [[ -z "${CP4BA_INST_GENAI_WX_PRJ_ID}" ]]; then
      _KO_CFG="true"
      _WRONG_VARS=${_WRONG_VARS}" CP4BA_INST_GENAI_WX_PRJ_ID"
    fi
  fi
  if [[ -z "${CP4BA_INST_GENAI_WX_URL_PROVIDER}" ]]; then
    export CP4BA_INST_GENAI_WX_URL_PROVIDER="${_WX_URL_PROVIDER}"
    if [[ -z "${CP4BA_INST_GENAI_WX_URL_PROVIDER}" ]]; then
      _KO_CFG="true"
      _WRONG_VARS=${_WRONG_VARS}" CP4BA_INST_GENAI_WX_URL_PROVIDER"
    fi
  fi
  if [[ "${_KO_CFG}" = "true" ]]; then
    echo -e "${_CLR_RED}[✗] ERROR: _verifyVars GenAI configuration error, verify values for:${_CLR_YELLOW}${_WRONG_VARS}${_CLR_NC}"
    return 0
  fi
  return 1
}

#-------------------------------
namespaceExist () {
# ns name: $1
  if [ $(oc get ns $1 2>/dev/null | grep $1 2>/dev/null | wc -l) -lt 1 ];
  then
      return 0
  fi
  return 1
}


#--------------------------------------------------------
configureGenAI() {
  _verifyVars
  if [ $? -eq 1 ]; then
    namespaceExist $1
    if [ $? -eq 1 ]; then
      _createWxSecret $1 ${CP4BA_INST_GENAI_WX_AUTH_SECRET}
      _createGenAiConfiguration $1
    else
      echo -e "${_CLR_RED}[✗] Error, namespace '${_CLR_YELLOW}$1${_CLR_RED}' doesn't exists. ${_CLR_NC}"
      exit 1
    fi
  fi  
}

#==================================

echo -e "=============================================================="
echo -e "${_CLR_GREEN}Configuring GenAI '${_CLR_YELLOW}${CP4BA_INST_NAMESPACE}${_CLR_GREEN}' namespace${_CLR_NC}"

configureGenAI ${CP4BA_INST_NAMESPACE}

