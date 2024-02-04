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
  if [[ ! -z "${CP4BA_INST_ADS_SECRETS_MONGO_USER}" ]] && [[ ! -z "${CP4BA_INST_ADS_SECRETS_MONGO_PASS}" ]]
    oc create secret -n ${CP4BA_INST_NAMESPACE} generic ibm-dba-ads-mongo-secret \
      --from-literal=mongoUser="${CP4BA_INST_ADS_SECRETS_MONGO_USER}" \
      --from-literal=mongoPassword="${CP4BA_INST_ADS_SECRETS_MONGO_PASS}" 1> /dev/null
    if [[ $? -gt 0 ]]; then
      _ERROR=1
      echo -e "${_CLR_RED}Secret ibm-dba-ads-mongo-secret NOT created (verify 'username/password' for secret) !!!${_CLR_NC}"
    fi
  fi

  # to be investigated
  #echo -e "Secret '${_CLR_YELLOW}${CP4BA_INST_CR_NAME}-bas-admin-secret${_CLR_NC}'"
  #oc delete secret -n ${CP4BA_INST_NAMESPACE} ${CP4BA_INST_CR_NAME}-bas-admin-secret 2> /dev/null 1> /dev/null
  #oc create secret -n ${CP4BA_INST_NAMESPACE} generic ${CP4BA_INST_CR_NAME}-bas-admin-secret \
  #  --from-literal=dbUsername="${CP4BA_INST_PAKBA_ADMIN_USER}" \
  #  --from-literal=dbPassword="${CP4BA_INST_PAKBA_ADMIN_PWD}" 1> /dev/null

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