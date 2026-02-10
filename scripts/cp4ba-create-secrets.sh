#!/bin/bash

_me=$(basename "$0")

_CFG=""
_WAIT=false
_SILENT=false
_ERROR=0

_maxWait=5

#--------------------------------------------------------
_CLR_RED="\033[0;31m"   #'0;31' is Red's ANSI color code
_CLR_GREEN="\033[0;32m"   #'0;32' is Green's ANSI color code
_CLR_YELLOW="\033[1;32m"   #'1;32' is Yellow's ANSI color code
_CLR_BLUE="\033[0;34m"   #'0;34' is Blue's ANSI color code
_CLR_NC="\033[0m"

#--------------------------------------------------------
# read command line params
while getopts c:t:ws flag
do
    case "${flag}" in
        c) _CFG=${OPTARG};;
        t) _maxWait=${OPTARG};;
        w) _WAIT=true;;
        s) _SILENT=true;;
    esac
done

if [[ -z "${_CFG}" ]]; then
  echo "usage: $_me -c path-of-config-file -w wait-for-db-creation -t time-to-wait-in-seconds -s silent-mode"
  exit
fi

source ${_CFG}

#-------------------------------
resourceExist () {
# namespace name: $1
# resource type: $2
# resource name: $3
  if [ $(oc get $2 -n $1 $3 2> /dev/null | grep $3 | wc -l) -lt 1 ];
  then
      return 0
  fi
  return 1
}

#-------------------------------
createSecretLDAP () {
  echo -e "Secret '${_CLR_YELLOW}${CP4BA_INST_LDAP_SECRET}${_CLR_NC}'"
  oc delete secret -n ${CP4BA_INST_NAMESPACE} ${CP4BA_INST_LDAP_SECRET} 2> /dev/null 1> /dev/null
  oc create secret -n ${CP4BA_INST_NAMESPACE} generic ${CP4BA_INST_LDAP_SECRET} \
    --from-literal=ldapUsername="cn=admin,dc=vuxprod,dc=net" \
    --from-literal=ldapPassword="passw0rd" 1> /dev/null
  if [[ $? -gt 0 ]]; then
    _ERROR=1
    echo -e "${_CLR_RED}Secret ${CP4BA_INST_LDAP_SECRET} NOT created (verify 'username/password' for secret) !!!${_CLR_NC}"
  fi
}

#-------------------------------
createSecretAE () {
  if [[ ! -z "${CP4BA_INST_AE_1_AD_SECRET_NAME}" ]]; then
    echo -e "Secret '${_CLR_YELLOW}${CP4BA_INST_AE_1_AD_SECRET_NAME}${_CLR_NC}'"

    oc delete secret -n ${CP4BA_INST_NAMESPACE} ${CP4BA_INST_AE_1_AD_SECRET_NAME} 2> /dev/null 1> /dev/null
    oc create secret -n ${CP4BA_INST_NAMESPACE} generic ${CP4BA_INST_AE_1_AD_SECRET_NAME} \
      --from-literal=AE_DATABASE_USER="${CP4BA_INST_DB_AE_USER}" \
      --from-literal=AE_DATABASE_PWD="${CP4BA_INST_DB_AE_PWD}" 1> /dev/null
    if [[ $? -gt 0 ]]; then
      _ERROR=1
      echo -e "${_CLR_RED}Secret ${CP4BA_INST_AE_1_AD_SECRET_NAME} NOT created (verify 'username/password' for secret) !!!${_CLR_NC}"
    fi
  fi
}

#-------------------------------
createSecretFNCM () {
  oc delete secret -n ${CP4BA_INST_NAMESPACE} ibm-fncm-secret 2> /dev/null 1> /dev/null
  _ERR=0  
  if [[ ! -z "${CP4BA_INST_DB_BAWDOCS_USER}" ]] && [[ ! -z "${CP4BA_INST_DB_BAWDOS_USER}" ]] && [[ ! -z "${CP4BA_INST_DB_BAWTOS_USER}" ]]; then
    echo -e "Secret '${_CLR_YELLOW}ibm-fncm-secret (FNCM+BAW objectstores users)${_CLR_NC}'"    
    oc create secret -n ${CP4BA_INST_NAMESPACE} generic ibm-fncm-secret \
      --from-literal="${CP4BA_INST_DB_OS_LBL}"DBUsername="${CP4BA_INST_DB_OS_USER}" \
      --from-literal="${CP4BA_INST_DB_OS_LBL}"DBPassword="${CP4BA_INST_DB_OS_PWD}" \
      --from-literal="${CP4BA_INST_DB_GCD_LBL}"DBUsername="${CP4BA_INST_DB_GCD_USER}" \
      --from-literal="${CP4BA_INST_DB_GCD_LBL}"DBPassword="${CP4BA_INST_DB_GCD_PWD}" \
      --from-literal="${CP4BA_INST_DB_BAWDOCS_LBL}"DBUsername="${CP4BA_INST_DB_BAWDOCS_USER}" \
      --from-literal="${CP4BA_INST_DB_BAWDOCS_LBL}"DBPassword="${CP4BA_INST_DB_BAWDOCS_PWD}" \
      --from-literal="${CP4BA_INST_DB_BAWDOS_LBL}"DBUsername="${CP4BA_INST_DB_BAWDOS_USER}" \
      --from-literal="${CP4BA_INST_DB_BAWDOS_LBL}"DBPassword="${CP4BA_INST_DB_BAWDOS_PWD}" \
      --from-literal="${CP4BA_INST_DB_BAWTOS_LBL}"DBUsername="${CP4BA_INST_DB_BAWTOS_USER}" \
      --from-literal="${CP4BA_INST_DB_BAWTOS_LBL}"DBPassword="${CP4BA_INST_DB_BAWTOS_PWD}" \
      --from-literal=appLoginUsername="${CP4BA_INST_PAKBA_ADMIN_USER}" \
      --from-literal=appLoginPassword="${CP4BA_INST_PAKBA_ADMIN_PWD}" \
      --from-literal=ltpaPassword="passw0rd" \
      --from-literal=keystorePassword="changeitchangeit" 1> /dev/null
    _ERR=$?
  else
    if [[ ! -z "${CP4BA_INST_DB_OS_USER}" ]] && [[ ! -z "${CP4BA_INST_DB_GCD_USER}" ]]; then
      echo -e "Secret '${_CLR_YELLOW}ibm-fncm-secret (FNCM objectstores users)${_CLR_NC}'"
      oc create secret -n ${CP4BA_INST_NAMESPACE} generic ibm-fncm-secret \
        --from-literal="${CP4BA_INST_DB_OS_LBL}"DBUsername="${CP4BA_INST_DB_OS_USER}" \
        --from-literal="${CP4BA_INST_DB_OS_LBL}"DBPassword="${CP4BA_INST_DB_OS_PWD}" \
        --from-literal="${CP4BA_INST_DB_GCD_LBL}"DBUsername="${CP4BA_INST_DB_GCD_USER}" \
        --from-literal="${CP4BA_INST_DB_GCD_LBL}"DBPassword="${CP4BA_INST_DB_GCD_PWD}" \
        --from-literal=appLoginUsername="${CP4BA_INST_PAKBA_ADMIN_USER}" \
        --from-literal=appLoginPassword="${CP4BA_INST_PAKBA_ADMIN_PWD}" \
        --from-literal=ltpaPassword="passw0rd" \
        --from-literal=keystorePassword="changeitchangeit" 1> /dev/null
      _ERR=$?
    else
      echo -e "Secret '${_CLR_YELLOW}ibm-fncm-secret (APP only)${_CLR_NC}'"
      oc create secret -n ${CP4BA_INST_NAMESPACE} generic ibm-fncm-secret \
        --from-literal=appLoginUsername="${CP4BA_INST_PAKBA_ADMIN_USER}" \
        --from-literal=appLoginPassword="${CP4BA_INST_PAKBA_ADMIN_PWD}" \
        --from-literal=ltpaPassword="passw0rd" \
        --from-literal=keystorePassword="changeitchangeit" 1> /dev/null
      _ERR=$?
    fi
  fi

  if [[ $_ERR -gt 0 ]]; then
    _ERROR=1
    echo -e "${_CLR_RED}Secret ibm-fncm-secret NOT created (verify 'username/password' for secret) !!!${_CLR_NC}"
  fi
}

#-------------------------------
createSecretFNCMBpmOnly () {
  echo -e "Secret '${_CLR_YELLOW}ibm-fncm-secret${_CLR_NC}'"
  oc delete secret -n ${CP4BA_INST_NAMESPACE} ibm-fncm-secret 2> /dev/null 1> /dev/null
  oc create secret -n ${CP4BA_INST_NAMESPACE} generic ibm-fncm-secret \
    --from-literal=appLoginUsername="${CP4BA_INST_PAKBA_ADMIN_USER}" \
    --from-literal=appLoginPassword="${CP4BA_INST_PAKBA_ADMIN_PWD}" \
    --from-literal=ltpaPassword="passw0rd" \
    --from-literal=keystorePassword="changeitchangeit" 1> /dev/null
  if [[ $? -gt 0 ]]; then
    _ERROR=1
    echo -e "${_CLR_RED}Secret ibm-fncm-secret NOT created (verify 'username/password' for secret) !!!${_CLR_NC}"
  fi
}

#-------------------------------
createSecretBAN () {
  echo -e "Secret '${_CLR_YELLOW}ibm-ban-secret${_CLR_NC}'"

  if [[ -z "${CP4BA_INST_DB_ICN_USER}" ]]; then
    CP4BA_INST_DB_ICN_USER="${CP4BA_INST_PAKBA_ADMIN_USER}"
    CP4BA_INST_DB_ICN_PWD="${CP4BA_INST_PAKBA_ADMIN_PWD}"
  fi

  oc delete secret -n ${CP4BA_INST_NAMESPACE} ibm-ban-secret 2> /dev/null 1> /dev/null
  oc create secret -n ${CP4BA_INST_NAMESPACE} generic ibm-ban-secret \
    --from-literal=navigatorDBUsername="${CP4BA_INST_DB_ICN_USER}" \
    --from-literal=navigatorDBPassword="${CP4BA_INST_DB_ICN_PWD}" \
    --from-literal=appLoginUsername="${CP4BA_INST_PAKBA_ADMIN_USER}" \
    --from-literal=appLoginPassword="${CP4BA_INST_PAKBA_ADMIN_PWD}" \
    --from-literal=keystorePassword="changeit" \
    --from-literal=ltpaPassword="changeit" 1> /dev/null
  if [[ $? -gt 0 ]]; then
    _ERROR=1
    echo -e "${_CLR_RED}Secret ibm-fncm-secret NOT created (verify 'username/password' for secret) !!!${_CLR_NC}"
  fi
}

#-------------------------------
createSecretBAW () {
# $1 secret name
# $2 username
# $3 password

  echo -e "Secret '${_CLR_YELLOW}$1${_CLR_NC}'"
  oc delete secret -n ${CP4BA_INST_NAMESPACE} $1 2> /dev/null 1> /dev/null
  oc create secret -n ${CP4BA_INST_NAMESPACE} generic $1 \
    --from-literal=dbUser="$2" \
    --from-literal=password="$3"  1> /dev/null
  if [[ $? -gt 0 ]]; then
    _ERROR=1
    echo -e "${_CLR_RED}Secret '${_CLR_YELLOW}$1${_CLR_RED}' NOT created (verify 'username/password' for secret) !!!${_CLR_NC}"
  fi
}

#-------------------------------
createSecretBAS () {
# $1 username
# $2 password

  echo -e "Secret '${_CLR_YELLOW}${CP4BA_INST_CR_NAME}-bas-admin-secret${_CLR_NC}'"
  oc delete secret -n ${CP4BA_INST_NAMESPACE} ${CP4BA_INST_CR_NAME}-bas-admin-secret 2> /dev/null 1> /dev/null
  oc create secret -n ${CP4BA_INST_NAMESPACE} generic ${CP4BA_INST_CR_NAME}-bas-admin-secret \
    --from-literal=dbUsername="$1" \
    --from-literal=dbPassword="$2" 1> /dev/null

  oc label secret ${CP4BA_INST_CR_NAME}-bas-admin-secret db-server=${CP4BA_INST_DB_1_SERVICE} -n ${CP4BA_INST_NAMESPACE} 1> /dev/null
  oc label secret ${CP4BA_INST_CR_NAME}-bas-admin-secret db-name=${CP4BA_INST_BAW_1_DB_NAME} -n ${CP4BA_INST_NAMESPACE} 1> /dev/null
  oc label secret ${CP4BA_INST_CR_NAME}-bas-admin-secret cp4ba.ibm.com/backup-type=mandatory -n ${CP4BA_INST_NAMESPACE} 1> /dev/null

#---------------------------------------------
_SECRET_FILE_NAME="/tmp/secret-baw-runtime-$USER-$RANDOM.xml"
cat <<EOF > ${_SECRET_FILE_NAME}
<?xml version="1.0" encoding="UTF-8"?>
<!-- BAW Runtime Liberty server properties -->
<properties>
  <server merge="mergeChildren">
    <!-- Settings related to the BAW runtime server -->

    <!-- CUSTOM DB EXAMPLE -->
    <dataSource commitOrRollbackOnCleanup="commit" id="jdbc/bawexternal" isolationLevel="TRANSACTION_READ_COMMITTED" jndiName="jdbc/bawexternal" type="javax.sql.XADataSource">
      <jdbcDriver libraryRef="PostgreSQLLib"/>
      <connectionManager maxPoolSize="50" minPoolSize="2"/>
        <properties.postgresql URL="jdbc:postgresql://${CP4BA_INST_DB_1_SERVER_NAME}:${CP4BA_INST_DB_SERVER_PORT}/bawexternal" user="bawexternal" password="dem0s"/>
    </dataSource>

    <!-- AI Features START -->
    <authData id="watsonx.ai_auth_alias" user="${CP4BA_INST_GENAI_WX_USERID}" password="${CP4BA_INST_GENAI_WX_APIKEY}" />
    <!-- AI Features END -->
  </server>
</properties>
EOF

_SECRET_NAME="my-liberty-custom-xml-secret"
echo -e "Secret '${_CLR_YELLOW}${_SECRET_NAME}${_CLR_NC}'"
oc create secret generic -n ${CP4BA_INST_NAMESPACE} ${_SECRET_NAME} --from-file=sensitiveCustomConfig=${_SECRET_FILE_NAME} 2> /dev/null 1> /dev/null
rm ${_SECRET_FILE_NAME} 2> /dev/null 1> /dev/null

#---------------------------------------------
_AGENT_FQDN_BASE=$(oc cluster-info | sed 's/.*https:\/\/api.//g' | sed 's/:.*//g' | head -n1)
_AGENT_FQDN_FULL="https://${CP4BA_INST_CPD_CONSOLE_PREFIX}.${_FQDN_BASE}"

_SECRET_FILE_NAME="/tmp/secret-100Custom-runtime-$USER-$RANDOM.xml"
cat <<EOF > ${_SECRET_FILE_NAME}
<properties>
  <server merge="mergeChildren">
    <email merge="mergeChildren">
      <!-- SMTP server that mail should be sent to -->
      <smtp-server merge="replace">mail.cp4ba-collateral.svc.cluster.local</smtp-server>
        <mail-template>
          <process>externalmailprocesslink_{0}.html</process>
          <no-process>externalmailnoprocess_{0}.html</no-process> 
        </mail-template> 
      <valid-from-required merge="replace">true</valid-from-required>
      <default-from-address merge="replace">system@cp.internal</default-from-address>
      <send-external-email merge="replace">true</send-external-email>
      <send-email-notifications-to-list merge="replace">false</send-email-notifications-to-list>
      <send-email-notifications-async merge="replace">false</send-email-notifications-async>
      <send-on-reassignment merge="replace">true</send-on-reassignment>
    </email>
    <!-- mime type white list which specifies mime types accepted for -->
    <!-- upload to document list or document attachment -->
    <document-attachment-accepted-mime-types merge="mergeChildren">
    <!-- specifies whether to allow a null mime type for upload-->
        <allow-null-mime-type>false</allow-null-mime-type>
        <!-- lists the mime types allowed for upload -->
        <mime-type>text/plain</mime-type>
        <mime-type>application/xml</mime-type>
        <mime-type>image/png</mime-type>
        <mime-type>image/jpg</mime-type>
        <mime-type>application/pdf</mime-type>
        <mime-type>application/vnd.ms-excel</mime-type>
        <mime-type>application/vnd.openxmlformats-officedocument.spreadsheetml.sheet</mime-type>
        <mime-type>application/msword</mime-type>
        <mime-type>application/vnd.openxmlformats-officedocument.wordprocessingml.document</mime-type>
        <mime-type>application/vnd.ms-powerpoint</mime-type>
        <mime-type>application/vnd.openxmlformats-officedocument.presentationml.presentation</mime-type>
        <mime-type>audio/mpeg</mime-type>
        <mime-type>video/mp4</mime-type>
        <mime-type>text/csv</mime-type>
        <mime-type>text/html</mime-type>
        <mime-type>application/json</mime-type>
        <mime-type>text/markdown</mime-type>
        <mime-type>application/vnd.oasis.opendocument.presentation</mime-type>
        <mime-type>application/vnd.oasis.opendocument.spreadsheet</mime-type>
        <mime-type>application/vnd.oasis.opendocument.text</mime-type>
        <mime-type>audio/wav</mime-type>
        <mime-type>application/zip</mime-type>
        <mime-type>message/rfc822</mime-type>
    </document-attachment-accepted-mime-types>
    <!-- extension white list which specifies extensions accepted for -->
    <!-- upload to document list or document attachment -->
    <document-attachment-accepted-extensions merge="mergeChildren">
        <!-- specifies whether to allow a document with no extension for upload -->
        <allow-null-extension>true</allow-null-extension>
        <!-- lists the extensions allowed for upload -->
        <extension>txt</extension>
        <extension>xml</extension>
        <extension>png</extension>
        <extension>jpg</extension>
        <extension>jpeg</extension>
        <extension>pdf</extension>
        <extension>xls</extension>
        <extension>xlsx</extension>
        <extension>doc</extension>
        <extension>docx</extension>
        <extension>ppt</extension>
        <extension>pptx</extension>
        <extension>mp3</extension>
        <extension>mp4</extension>
        <extension>m4a</extension>
        <extension>csv</extension>
        <extension>htm</extension>
        <extension>html</extension>
        <extension>json</extension>
        <extension>md</extension>
        <extension>odp</extension>
        <extension>ods</extension>
        <extension>odt</extension>
        <extension>wav</extension>
        <extension>zip</extension>
        <extension>eml</extension>
    </document-attachment-accepted-extensions>
    <document-attachment-max-file-size-upload merge="replace">5000048576</document-attachment-max-file-size-upload>
    <case-instance-migration-enabled>true</case-instance-migration-enabled>
    <gen-ai merge="mergeChildren"> 
      <project-id>project_id</project-id> 
      <provider-url>${CP4BA_INST_BAS_GENAI_WX_URL_PROVIDER}</provider-url> 
      <auth-alias>watsonx.ai_auth_alias</auth-alias> 
      <read-timeout>120</read-timeout>
      <default-foundation-model>meta-llama/llama-3-3-70b-instruct</default-foundation-model>
    </gen-ai>
    <portal merge="mergeChildren">
      <agent-enable merge="replace">true</agent-enable>
      <agent-endpoint merge="replace">${_AGENT_FQDN_FULL}/agent/runtimeChat</agent-endpoint>
    </portal>
    <wxo merge="mergeChildren">
      <token-url>${CP4BA_INST_WXO_TOKEN_URL}</token-url> 
      <discovery>
        <service-instance-url>${CP4BA_INST_WXO_SERVICE_INSTANCE_URL}</service-instance-url> 
      </discovery>
    </wxo>
  </server>
</properties>
EOF

_SECRET_NAME="my-lombardi-custom-xml-secret"
echo -e "Secret '${_CLR_YELLOW}${_SECRET_NAME}${_CLR_NC}'"
oc create secret generic -n ${CP4BA_INST_NAMESPACE} ${_SECRET_NAME} --from-file=sensitiveCustomConfig=${_SECRET_FILE_NAME} 2> /dev/null 1> /dev/null
rm ${_SECRET_FILE_NAME} 2> /dev/null 1> /dev/null


#---------------------------------------------
_WX_APIKEY=$(echo ${CP4BA_INST_BAS_GENAI_WX_APIKEY} | base64)
_WX_PRJID=$(echo ${CP4BA_INST_BAS_GENAI_WX_PRJ_ID} | base64)
_WX_URL=$(echo ${CP4BA_INST_BAS_GENAI_WX_URL_PROVIDER} | base64)

_SECRET_FILE_NAME="/tmp/secret-wf-assistant-$USER-$RANDOM.xml"
cat <<EOF > ${_SECRET_FILE_NAME}
kind: Secret
apiVersion: v1
metadata:
  name: ibm-workflow-assistant-secrets
  namespace: ${CP4BA_INST_NAMESPACE}
data:
  WATSONX_API_KEY: "${_WX_APIKEY}"
  WATSONX_PASSWORD: ''
  WATSONX_PROJECT_ID: "${_WX_PRJID}"
  WATSONX_TOKEN: ''
  WATSONX_URL: "${_WX_URL}"
type: Opaque

EOF

_SECRET_NAME="ibm-workflow-assistant-secrets"
echo -e "Secret '${_CLR_YELLOW}${_SECRET_NAME}${_CLR_NC}'"
oc apply -f ${_SECRET_FILE_NAME} 2> /dev/null 1> /dev/null
rm ${_SECRET_FILE_NAME} 2> /dev/null 1> /dev/null

}

#-------------------------------
createSecretADS () {
  echo -e "Secret '${_CLR_YELLOW}ibm-dba-ads-runtime-secret${_CLR_NC}'"
  oc delete secret -n ${CP4BA_INST_NAMESPACE} ibm-dba-ads-runtime-secret 2> /dev/null 1> /dev/null
  oc create secret -n ${CP4BA_INST_NAMESPACE} generic ibm-dba-ads-runtime-secret \
    --from-literal=asraManagerUsername="${CP4BA_INST_ADS_SECRETS_ASRA_MGR_USER}" \
    --from-literal=asraManagerPassword="${CP4BA_INST_ADS_SECRETS_ASRA_MGR_PASS}" \
    --from-literal=decisionServiceUsername="${CP4BA_INST_ADS_SECRETS_DRS_USER}" \
    --from-literal=decisionServicePassword="${CP4BA_INST_ADS_SECRETS_DRS_PASS}" \
    --from-literal=decisionServiceManagerUsername="${CP4BA_INST_ADS_SECRETS_DRS_MGR_USER}" \
    --from-literal=decisionServiceManagerPassword="${CP4BA_INST_ADS_SECRETS_DRS_MGR_PASS}" \
    --from-literal=decisionRuntimeMonitorUsername="${CP4BA_INST_ADS_SECRETS_DRS_MON_USER}" \
    --from-literal=decisionRuntimeMonitorPassword="${CP4BA_INST_ADS_SECRETS_DRS_MON_PASS}" \
    --from-literal=deploymentSpaceManagerUsername="${CP4BA_INST_ADS_SECRETS_DEPL_MGR_USER}" \
    --from-literal=deploymentSpaceManagerPassword="${CP4BA_INST_ADS_SECRETS_DEPL_MGR_PASS}" \
    --from-literal=encryptionKeys="{\"activeKey\":\"key1\",\"secretKeyList\":[{\"secretKeyId\":\"key1\",\"value\":\"123344566745435\"},{\"secretKeyId\":\"key2\",\"value\":\"987766544365675\"}]}" \
    --from-literal=sslKeystorePassword="averymuchlongpasswordtobecompliantwithfips" 1> /dev/null
  if [[ $? -gt 0 ]]; then
    _ERROR=1
    echo -e "${_CLR_RED}Secret ibm-dba-ads-runtime-secret NOT created (verify 'username/password' for secret) !!!${_CLR_NC}"
  fi

  echo -e "Secret '${_CLR_YELLOW}ibm-dba-ads-mongo-secret${_CLR_NC}'"
  oc delete secret -n ${CP4BA_INST_NAMESPACE} ibm-dba-ads-mongo-secret 2> /dev/null 1> /dev/null
  if [[ ! -z "${CP4BA_INST_ADS_SECRETS_MONGO_USER}" ]] && [[ ! -z "${CP4BA_INST_ADS_SECRETS_MONGO_PASS}" ]]; then
    oc create secret -n ${CP4BA_INST_NAMESPACE} generic ibm-dba-ads-mongo-secret \
      --from-literal=mongoUser="${CP4BA_INST_ADS_SECRETS_MONGO_USER}" \
      --from-literal=mongoPassword="${CP4BA_INST_ADS_SECRETS_MONGO_PASS}" 1> /dev/null
    if [[ $? -gt 0 ]]; then
      _ERROR=1
      echo -e "${_CLR_RED}Secret ibm-dba-ads-mongo-secret NOT created (verify 'username/password' for secret) !!!${_CLR_NC}"
    fi
  fi

}

#--------------------------------------------------------------
# get certificate from remote url
# $1: url:port
# $2: cert name
# $3: output file
getCertificate () {

  echo "Getting certificate from: "$1  
  _FILE_TMP="/tmp/cp4ba-ads-cert-$USER-$RANDOM"
  openssl s_client -showcerts -connect $1 < /dev/null 2>/dev/null | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > ${_FILE_TMP}
  
  echo "  $2: |" >> $3
  while IFS= read -r line
  do
    echo "    $line" >> $3
  done < "${_FILE_TMP}"

  rm ${_FILE_TMP}
}

#--------------------------------------------------------------
grabCertificates () {

  _CFGMAP_FILE_TMP="/tmp/cp4ba-ads-cfgmap-$USER-$RANDOM"

echo "
apiVersion: v1
kind: ConfigMap
metadata:
  name: ${CP4BA_INST_ADS_TLS_CERTS_CFGMAP_NAME}
  namespace: ${CP4BA_INST_NAMESPACE}
  labels:
    ads-trusted-certs: runtime
data:
" > ${_CFGMAP_FILE_TMP}

  for i in {1..10}
  do
    __URL="CP4BA_INST_ADS_HOST_PORT_TRUSTED_EP_$i"
    __CRT="CP4BA_INST_ADS_CERT_NAME_TRUSTED_EP_$i"
    _URL=${!__URL}
    _CRT=${!__CRT}
    if [[ ! -z "${_URL}" ]]; then
      getCertificate ${_URL} ${_CRT} ${_CFGMAP_FILE_TMP}
    fi
  done

  _ALREADY_SET=$(oc get cm --no-headers ${CP4BA_INST_ADS_TLS_CERTS_CFGMAP_NAME} -n ${CP4BA_INST_NAMESPACE} 2>/dev/null | wc -l)
  if [[ "${_ALREADY_SET}" == "1" ]]; then
    oc delete cm ${CP4BA_INST_ADS_TLS_CERTS_CFGMAP_NAME} -n ${CP4BA_INST_NAMESPACE} 2>/dev/null
  fi
  oc create -f ${_CFGMAP_FILE_TMP} 2>/dev/null 1>/dev/null
  rm ${_CFGMAP_FILE_TMP}
}

#-------------------------------
createConfigMapADS() {
  echo -e "ConfigMap '${_CLR_YELLOW}${CP4BA_INST_ADS_TLS_CERTS_CFGMAP_NAME}${_CLR_NC}'"
  grabCertificates
}

createConfigMapBtsImZenForExternalDBs() {

echo "createConfigMapBtsImZenForExternalDBs: config maps not created, used only for external db ..."

# echo -e "ConfigMap '${_CLR_YELLOW}ibm-bts-config-extension${_CLR_NC}'"
# 
# cat <<EOF | oc apply -f - 2>/dev/null 1>/dev/null
# apiVersion: v1
# kind: ConfigMap
# metadata:
#   name: ibm-bts-config-extension
#   namespace: "${CP4BA_INST_NAMESPACE}"
#   labels:
#     cp4ba.ibm.com/backup-type: mandatory
# data:
#   serverName: "${CP4BA_INST_DB_1_SERVICE}"
#   portNumber: "5432"
#   databaseName: bts
#   ssl: "false"
#   sslMode: verify-ca
#   sslSecretName: bts-datastore-edb-secret
#   customPropertyName1: sslKey
#   customPropertyValue1: "/opt/ibm/wlp/usr/shared/resources/security/db/tls.key"
#   customPropertyName2: user
#   customPropertyValue2: "bts_user"
# EOF

# echo -e "ConfigMap '${_CLR_YELLOW}im-datastore-edb-cm${_CLR_NC}'"

# cat <<EOF | oc apply -f - 2>/dev/null 1>/dev/null
# apiVersion: v1
# kind: ConfigMap
# metadata:
#   name: im-datastore-edb-cm
#   namespace: "${CP4BA_INST_NAMESPACE}"
#   labels:
#     cp4ba.ibm.com/backup-type: mandatory
# data:
#   IS_EMBEDDED: "false"
#   DATABASE_PORT: "5432"
#   DATABASE_R_ENDPOINT: "${CP4BA_INST_DB_1_SERVICE}"
#   DATABASE_RW_ENDPOINT: "${CP4BA_INST_DB_1_SERVICE}"
#   DATABASE_USER: im_user
#   DATABASE_NAME: im
#   DATABASE_CA_CERT: ca.crt
#   DATABASE_CLIENT_CERT: tls.crt
#   DATABASE_CLIENT_KEY: tls.key
# EOF

# echo -e "ConfigMap '${_CLR_YELLOW}ibm-zen-metastore-edb-cm${_CLR_NC}'"

# cat <<EOF | oc apply -f - 2>/dev/null 1>/dev/null
# apiVersion: v1
# kind: ConfigMap
# metadata:
#   name: ibm-zen-metastore-edb-cm
#   namespace: "${CP4BA_INST_NAMESPACE}"
#   labels:
#     cp4ba.ibm.com/backup-type: mandatory
# data:
#   IS_EMBEDDED: "false"
#   DATABASE_CA_CERT: ca.crt
#   DATABASE_CLIENT_CERT: tls.crt
#   DATABASE_CLIENT_KEY: tls.key
#   DATABASE_MONITORING_SCHEMA: watchdog
#   DATABASE_NAME: zen
#   DATABASE_PORT: "5432"
#   DATABASE_R_ENDPOINT: "${CP4BA_INST_DB_1_SERVICE}"
#   DATABASE_RW_ENDPOINT: "${CP4BA_INST_DB_1_SERVICE}"
#   DATABASE_SCHEMA: public
#   DATABASE_USER: zen_user
#   DATABASE_ENABLE_SSL: "false"
#   #DATABASE_SSL_MODE: require 
# EOF

}

#-------------------------------
createSecrets () {
  if [[ "${CP4BA_INST_LDAP}" = "true" ]]; then
    createSecretLDAP
  fi
  createSecretBAN

  if [[ $CP4BA_INST_DB_INSTANCES -eq 0 ]]; then
    createSecretFNCMBpmOnly
  else
    if [[ -z "${CP4BA_INST_BAW_BPM_ONLY}" ]] || [[ "${CP4BA_INST_BAW_BPM_ONLY}" = "false" ]]; then
      createSecretFNCM
    else
      createSecretFNCMBpmOnly
    fi
  fi

  # ADS
  if [[ "${CP4BA_INST_ADS_SECRETS_CREATE}" = "true" ]]; then
    createSecretADS
    createConfigMapADS
  fi

  i=1
  _IDX_END=$CP4BA_INST_DB_INSTANCES
  while [[ $i -le $_IDX_END ]]
  do
    _INST_BAW="CP4BA_INST_BAW_$i"
    _INST="${!_INST_BAW}"
    if [[ "${_INST}" = "true" ]]; then
      _DB_SECRET="CP4BA_INST_BAW_"$i"_DB_SECRET"
      #_DB_USER="CP4BA_INST_BAW_"$i"_DB_USER"
      #_DB_PWD="CP4BA_INST_BAW_"$i"_DB_PWD"
      if [[ ! -z "${!_DB_SECRET}" ]]; then
        createSecretBAW ${!_DB_SECRET} ${CP4BA_INST_DB_BAW_USER} ${CP4BA_INST_DB_BAW_PWD} # ${!_DB_USER} ${!_DB_PWD}
      else
        echo -e "${_CLR_RED}ERROR, env var '${_CLR_GREEN}${_DB_SECRET}${_CLR_RED}' not defined, verify CP4BA_INST_DB_INSTANCES and CP4BA_INST_BAW_* values.${_CLR_NC}"
      fi
    fi
    ((i = i + 1))
  done  

  createSecretBAS ${CP4BA_INST_DB_BAW_USER} ${CP4BA_INST_DB_BAW_PWD}

  # TBD for external DBs createConfigMapBtsImZenForExternalDBs

  # createSecretAE

  if [[ $_ERROR = 1 ]]; then
    if [[ "${_SILENT}" = "false" ]]; then
      echo ""
      echo -e ">>> \x1b[5mWARNING\x1b[25m <<<"
      echo "Rerun this script after db setup."
      echo "" 
    fi
  fi

}

echo -e "=============================================================="
echo -e "${_CLR_GREEN}Creating secrets in '${_CLR_YELLOW}${CP4BA_INST_NAMESPACE}${_CLR_GREEN}' namespace${_CLR_NC}"
createSecrets