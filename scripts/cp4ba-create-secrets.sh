#!/bin/bash

_me=$(basename "$0")

_CFG=""
_WAIT=false
_SILENT=false
_ERROR=0

_maxWait=60

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
  oc delete secret -n ${CP4BA_INST_NAMESPACE} ${CP4BA_INST_LDAP_SECRET} 2> /dev/null
  oc create secret -n ${CP4BA_INST_NAMESPACE} generic ${CP4BA_INST_LDAP_SECRET} \
    --from-literal=ldapUsername="cn=admin,dc=vuxprod,dc=net" \
    --from-literal=ldapPassword="passw0rd"
}

#-------------------------------
createSecretAE () {
  echo -e "Secret '${_CLR_YELLOW}${CP4BA_INST_AE_1_AD_SECRET_NAME}${_CLR_NC}'"
  if [[ ! -z "${_USER_NAME}" ]]; then
    oc delete secret -n ${CP4BA_INST_NAMESPACE} ${CP4BA_INST_AE_1_AD_SECRET_NAME} 2> /dev/null
    oc create secret -n ${CP4BA_INST_NAMESPACE} generic ${CP4BA_INST_AE_1_AD_SECRET_NAME} \
      --from-literal=AE_DATABASE_USER="${_USER_NAME}" \
      --from-literal=AE_DATABASE_PWD="${_USER_PASSWORD}"
  else
    _ERROR=1
    echo -e "${_CLR_RED}Secret ${CP4BA_INST_AE_1_AD_SECRET_NAME} NOT created (troubleshooting 'username' for secret '${_CLR_YELLOW}${CP4BA_INST_DB_CR_NAME}-app${_CLR_RED}') !!!${_CLR_NC}"
  fi
}

#-------------------------------
createSecretFNCM () {
  echo -e "Secret '${_CLR_YELLOW}ibm-fncm-secret${_CLR_NC}'"
  if [[ ! -z "${_USER_NAME}" ]]; then
    oc delete secret -n ${CP4BA_INST_NAMESPACE} ibm-fncm-secret 2> /dev/null
    oc create secret -n ${CP4BA_INST_NAMESPACE} generic ibm-fncm-secret \
      --from-literal=osDBUsername="${_USER_NAME}" \
      --from-literal=osDBPassword="${_USER_PASSWORD}" \
      --from-literal=gcdDBUsername="${_USER_NAME}" \
      --from-literal=gcdDBPassword="${_USER_PASSWORD}" \
      --from-literal=contentDBUsername="${_USER_NAME}" \
      --from-literal=contentDBPassword="${_USER_PASSWORD}" \
      --from-literal=appLoginUsername="cp4admin" \
      --from-literal=appLoginPassword="dem0s" \
      --from-literal=ltpaPassword="passw0rd" \
      --from-literal=keystorePassword="changeitchangeit"
  else
    _ERROR=1
    echo -e "${_CLR_RED}Secret ibm-fncm-secret NOT created (troubleshooting 'username' for secret '${_CLR_YELLOW}${CP4BA_INST_DB_CR_NAME}-app${_CLR_RED}') !!!${_CLR_NC}"
  fi
}

#-------------------------------
createSecretBAN () {
  echo -e "Secret '${_CLR_YELLOW}ibm-ban-secret${_CLR_NC}'"
  if [[ ! -z "${_USER_NAME}" ]]; then
    oc delete secret -n ${CP4BA_INST_NAMESPACE} ibm-ban-secret 2> /dev/null
    oc create secret -n ${CP4BA_INST_NAMESPACE} generic ibm-ban-secret \
      --from-literal=navigatorDBUsername="${_USER_NAME}" \
      --from-literal=navigatorDBPassword="${_USER_PASSWORD}" \
      --from-literal=appLoginUsername="cp4admin" \
      --from-literal=appLoginPassword="dem0s" \
      --from-literal=keystorePassword="changeit" \
      --from-literal=ltpaPassword="changeit"
  else
    _ERROR=1
    echo -e "${_CLR_RED}Secret ibm-ban-secret NOT created (troubleshooting 'username' for secret '${_CLR_YELLOW}${CP4BA_INST_DB_CR_NAME}-app${_CLR_RED}') !!!${_CLR_NC}"
  fi
}

#-------------------------------
createSecretBAW_1 () {
  # vedi rif ibm-baw-wfs-server-db-secret
  echo -e "Secret '${_CLR_YELLOW}${CP4BA_INST_BAW_1_DB_SECRET}${_CLR_NC}'"
  if [[ ! -z "${_USER_NAME}" ]]; then
    if [[ -z "${CP4BA_INST_BAW_1_DB_USER}" ]]; then
      CP4BA_INST_BAW_1_DB_USER="${_USER_NAME}"
      CP4BA_INST_BAW_1_DB_PWD="${_USER_PASSWORD}"
    fi
    oc delete secret -n ${CP4BA_INST_NAMESPACE} ${CP4BA_INST_BAW_1_DB_SECRET} 2> /dev/null
    oc create secret -n ${CP4BA_INST_NAMESPACE} generic ${CP4BA_INST_BAW_1_DB_SECRET} \
      --from-literal=dbUser="${CP4BA_INST_BAW_1_DB_USER}" \
      --from-literal=password="${CP4BA_INST_BAW_1_DB_PWD}"
  else
    _ERROR=1
    echo -e "${_CLR_RED}Secret ${CP4BA_INST_BAW_1_DB_SECRET} NOT created (troubleshooting 'username' for secret '${_CLR_YELLOW}${CP4BA_INST_DB_CR_NAME}-app${_CLR_RED}') !!!${_CLR_NC}"
  fi
}


#-------------------------------
createSecrets () {
  # no need to wait
  createSecretLDAP

  if [[ "${_WAIT}" = "true" ]]; then
    _seconds=0
    until [ $_seconds -gt $_maxWait ];
    do
      resourceExist "${CP4BA_INST_SUPPORT_NAMESPACE}" "secret" "${CP4BA_INST_DB_CR_NAME}-app"
      if [ $? -eq 0 ]; then
        echo -e -n "${_CLR_GREEN}Wait for DB credentials secret '${_CLR_YELLOW}"${CP4BA_INST_DB_CR_NAME}-app"${_CLR_GREEN}' (may take minutes) [$_seconds]${_CLR_NC}\033[0K\r"
        sleep 1
        ((_seconds=_seconds+1))
      else
        echo ""
        break
      fi
    done
  fi

  _USER_NAME=$(oc get secret -n ${CP4BA_INST_SUPPORT_NAMESPACE} ${CP4BA_INST_DB_CR_NAME}-app -o jsonpath='{.data.username}' 2> /dev/null | base64 -d)
  _USER_PASSWORD=$(oc get secret -n ${CP4BA_INST_SUPPORT_NAMESPACE} ${CP4BA_INST_DB_CR_NAME}-app -o jsonpath='{.data.password}' 2> /dev/null | base64 -d)
  echo "CP4BA_INST_DB_CR_NAME User: " $_USER_NAME / $_USER_PASSWORD

  if [[ ! -z "${_USER_NAME}" ]]; then
    createSecretAE
    createSecretFNCM
    createSecretBAN
    createSecretBAW_1
  fi
  if [[ $_ERROR = 1 ]] || [[ -z "${_USER_NAME}" ]]; then
    if [[ "${_SILENT}" = "false" ]]; then
      echo ""
      echo -e ">>> \x1b[5mWARNING\x1b[25m <<<"
      echo "Rerun this script after db '${CP4BA_INST_DB_CR_NAME}' setup."
      echo "" 
    fi
  fi

}

echo -e "#==========================================================="
echo -e "${_CLR_GREEN}Creating secrets in '${_CLR_YELLOW}${CP4BA_INST_NAMESPACE}${_CLR_GREEN}' namespace${_CLR_NC}"
createSecrets