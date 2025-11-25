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

#-------------------------------
waitForBawStatefulSetReady () {
  _SFSET_NAME="${CP4BA_INST_CR_NAME}-$1-baw-server"
  echo -e -n "${_CLR_GREEN}Wait for ${_CLR_YELLOW}${_SFSET_NAME}${_CLR_GREEN}${_CLR_NC}..."
  waitForResourceCreated ${CP4BA_INST_NAMESPACE} "statefulset" ${_SFSET_NAME} 5

  _SFS_READY=0
  while [ true ]; 
  do   
    _SFS_READY=$(oc get statefulset -n ${CP4BA_INST_NAMESPACE} ${_SFSET_NAME} -o jsonpath="{.status.readyReplicas}")
    if [[ "${_SFS_READY}" = "0" ]]; then
      sleep 1
    else
      break
    fi
  done
  echo -e "${_CLR_YELLOW}READY${_CLR_GREEN}${_CLR_NC}"
}

#--------------------------------------------------------
_createGenAiConfiguration () {

  BA_DN=$(oc get ICP4ACluster -n $1 --no-headers | awk '{print $1}')
  if [[ ! -z "${BA_DN}" ]]; then
    echo -e "${_CLR_GREEN}Patching ICP4ACluster '${_CLR_YELLOW}${BA_DN}${_CLR_GREEN}'${_CLR_NC}"

    _WX_GENAI_TMP="/tmp/cp4ba-wx-genai-$USER-$RANDOM"

    if [[ "${CP4BA_INST_TYPE}" = "starter" ]]; then

      _createWxSecret $1 ${CP4BA_INST_GENAI_WX_AUTH_SECRET}

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
      echo '        <!-- Enable WatsonX Assistant-->' >> ${_WX_GENAI_TMP}
      echo '        <server merge="mergeChildren">' >> ${_WX_GENAI_TMP}
      echo '          <portal merge="mergeChildren">' >> ${_WX_GENAI_TMP}
      echo '            <assistant-enable merge="replace">true</assistant-enable>' >> ${_WX_GENAI_TMP}
      echo '          </portal>' >> ${_WX_GENAI_TMP}
      echo '        </server>' >> ${_WX_GENAI_TMP}
      echo '      </properties>' >> ${_WX_GENAI_TMP}

      oc patch ICP4ACluster ${BA_DN} -n $1 --type=merge --patch-file=${_WX_GENAI_TMP} 2> /dev/null 1> /dev/null

      rm ${_WX_GENAI_TMP} 2> /dev/null 1> /dev/null
    else

      i=1
      _MAX_BAW=10
      while [[ $i -le $_MAX_BAW ]]
      do
        __BAW_INST="CP4BA_INST_BAW_${i}"
        __BAW_NAME="CP4BA_INST_BAW_${i}_NAME"
        __BAW_GENAI="CP4BA_INST_BAW_${i}_GENAI_ENABLED"
        __BAW_WX_URL_PROVIDER="CP4BA_INST_BAW_${i}_GENAI_WX_URL_PROVIDER"
        __BAW_WX_PRJ_ID="CP4BA_INST_BAW_${i}_GENAI_WX_PRJ_ID"
        __BAW_WX_APIKEY="CP4BA_INST_BAW_${i}_GENAI_WX_APIKEY"

        _INST="${!__BAW_INST}"
        _GENAI="${!__BAW_GENAI}"
        _NAME="${!__BAW_NAME}"
        _URL="${!__BAW_WX_URL_PROVIDER}"
        _PRJID="${!__BAW_WX_PRJ_ID}"
        _APIKEY="${!__BAW_WX_APIKEY}"
        if [[ "${_INST}" = "true" ]] && [[ "${_GENAI}" = "true" ]]; then
          waitForBawStatefulSetReady "${_NAME}"
          echo -e "${_CLR_GREEN}Patching BAW '${_CLR_YELLOW}${_NAME}${_CLR_GREEN}'${_CLR_NC}"

          _WX_GENAI_TMP="/tmp/cp4ba-wx-genai-100Custom-$USER-$RANDOM"

          echo '<?xml version="1.0" encoding="UTF-8" ?>' >> ${_WX_GENAI_TMP}
          echo '<properties>' >> ${_WX_GENAI_TMP}
          echo '	<!-- Enable GenAI -->' >> ${_WX_GENAI_TMP}
          echo '	<server>' >> ${_WX_GENAI_TMP}
          echo '		<gen-ai merge="mergeChildren">' >> ${_WX_GENAI_TMP}
          echo '			<provider-url>'${_URL}'</provider-url>' >> ${_WX_GENAI_TMP}
          echo '			<project-id>'${_PRJID}'</project-id>' >> ${_WX_GENAI_TMP}
          echo '			<auth-alias>workplace_watsonx.ai_auth_alias</auth-alias>' >> ${_WX_GENAI_TMP}
          echo '			<read-timeout merge="replace">120</read-timeout>' >> ${_WX_GENAI_TMP}
          echo '		</gen-ai>' >> ${_WX_GENAI_TMP}
          echo '	</server>' >> ${_WX_GENAI_TMP}
          echo '	<!-- Enable WatsonX Assistant-->' >> ${_WX_GENAI_TMP}
          echo '	<server merge="mergeChildren">' >> ${_WX_GENAI_TMP}
          echo '		<portal merge="mergeChildren">' >> ${_WX_GENAI_TMP}
          echo '			<assistant-enable merge="replace">true</assistant-enable>' >> ${_WX_GENAI_TMP}
          echo '		</portal>' >> ${_WX_GENAI_TMP}
          echo '	</server>' >> ${_WX_GENAI_TMP}
          echo '</properties>' >> ${_WX_GENAI_TMP}

          oc create secret -n $1 generic custom-config-workplace-assistant-${i} --from-file=sensitiveCustomConfig=${_WX_GENAI_TMP} 2> /dev/null 1> /dev/null
          rm ${_WX_GENAI_TMP} 2> /dev/null 1> /dev/null

          _WX_GENAI_TMP="/tmp/cp4ba-wx-genai-authdata-$USER-$RANDOM"

          echo '<server>' >> ${_WX_GENAI_TMP}
          echo '    <authData id="workplace_watsonx.ai_auth_alias" user="ANY_USER_ID_IS_FINE" password="${_APIKEY}" />' >> ${_WX_GENAI_TMP}
          echo '</server>' >> ${_WX_GENAI_TMP}

          oc create secret -n $1 generic custom-config-assistant-authdata-${i} --from-file=sensitiveCustomConfig=${_WX_GENAI_TMP} 2> /dev/null 1> /dev/null
          rm ${_WX_GENAI_TMP} 2> /dev/null 1> /dev/null
          
          # replace object BAW[ _NAME ] with new configuration
          _FILE_ORIG=/tmp/cp4ba-wx-genai-$USER-$RANDOM-icp4adeploy.json
          _FILE_ALL_BUT_BAW_GENAI=/tmp/cp4ba-wx-genai-$USER-$RANDOM-icp4adeploy-partial.json
          _FILE_BAW_GENAI=/tmp/cp4ba-wx-genai-$USER-$RANDOM-baw.json
          _FILE_BAW_GENAI_PATCHED=/tmp/cp4ba-wx-genai-$USER-$RANDOM-baw-patched.json
          _FILE_FINAL=/tmp/cp4ba-wx-genai-$USER-$RANDOM-icp4adeploy-final.json

          # extract CR
          oc get icp4acluster -n ${CP4BA_INST_NAMESPACE} ${CP4BA_INST_CR_NAME} -o json > ${_FILE_ORIG}

          # extract BAW object
          jq '.spec.baw_configuration[] | select(.name=="'${_NAME}'")' ${_FILE_ORIG} > ${_FILE_BAW_GENAI}

          # add workplace assistant attributes to BAW object
          cat ${_FILE_BAW_GENAI} | jq '. += {"custom_xml_secret_name": "custom-config-assistant-authdata'-${i}'", "lombardi_custom_xml_secret_name": "custom-config-workplace-assistant'-${i}'", "environment_config": {"content_security_policy_additional_script_src": ["*.watson.appdomain.cloud"],"content_security_policy_additional_connect_src": ["*.watson.appdomain.cloud"], "content_security_policy_additional_font_src": ["*.watson.appdomain.cloud"] } }' > ${_FILE_BAW_GENAI_PATCHED}

          # remove original BAW object from extracted CR
          cat ${_FILE_ORIG} | jq 'del(.spec.baw_configuration[] | select(.name=="'${_NAME}'"))' > ${_FILE_ALL_BUT_BAW_GENAI}

          # add new BAW object to CR
          jq --argjson p "$(<${_FILE_BAW_GENAI_PATCHED})" '.spec.baw_configuration += [$p]' ${_FILE_ALL_BUT_BAW_GENAI} > ${_FILE_FINAL}

          # apply modified CR
          oc apply --overwrite=true -f ${_FILE_FINAL} 2> /dev/null 1> /dev/null

          rm ${_FILE_ORIG} 2> /dev/null 1> /dev/null
          rm ${_FILE_ALL_BUT_BAW_GENAI} 2> /dev/null 1> /dev/null
          rm ${_FILE_BAW_GENAI} 2> /dev/null 1> /dev/null
          rm ${_FILE_BAW_GENAI_PATCHED} 2> /dev/null 1> /dev/null
          rm ${_FILE_FINAL} 2> /dev/null 1> /dev/null
          
          _NAME=""
        else
          if [[ ! -z "${_NAME}" ]]; then
            echo -e "${_CLR_GREEN}PFS - skipping BAW: '${_CLR_YELLOW}"${_NAME}"${_CLR_GREEN}'${_CLR_NC}"
          fi 
        fi
        ((i=i+1))
      done

    fi

    echo -e "${_CLR_GREEN}Please wait for patched BAW to restart to enable the workflow assistant${_CLR_NC}"
  else
    
    echo -e "${_CLR_RED}[✗] ERROR: _createGenAiConfiguration GenAI configuration error, ICP4ACluster object not found.${_CLR_NC}"
    exit 1
  fi
}

#--------------------------------------------------------
_verifyVars() {
  if [[ "${CP4BA_INST_TYPE}" = "starter" ]]; then
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
  else
    return 1
  fi
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
      _createGenAiConfiguration $1
    else
      echo -e "${_CLR_RED}[✗] Error, namespace '${_CLR_YELLOW}$1${_CLR_RED}' doesn't exists. ${_CLR_NC}"
      exit 1
    fi
  fi  
}

#==================================

echo -e "${_CLR_YELLOW}==============================================================${_CLR_NC}"
echo -e "${_CLR_GREEN}Configuring GenAI in namespace '${_CLR_YELLOW}${CP4BA_INST_NAMESPACE}${_CLR_GREEN}'${_CLR_NC}"

configureGenAI ${CP4BA_INST_NAMESPACE}

