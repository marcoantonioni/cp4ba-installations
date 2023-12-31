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
  if [[ "${_WAIT}" = "true" ]]; then
    echo -e "Secret '${_CLR_YELLOW}${CP4BA_INST_LDAP_SECRET}${_CLR_NC}'"
  fi
  oc delete secret -n ${CP4BA_INST_NAMESPACE} ${CP4BA_INST_LDAP_SECRET} 2> /dev/null 1> /dev/null
  oc create secret -n ${CP4BA_INST_NAMESPACE} generic ${CP4BA_INST_LDAP_SECRET} \
    --from-literal=ldapUsername="cn=admin,dc=vuxprod,dc=net" \
    --from-literal=ldapPassword="passw0rd" 1> /dev/null
}

#-------------------------------
createSecretAE () {
  if [[ ! -z "${CP4BA_INST_AE_1_AD_SECRET_NAME}" ]]; then
    echo -e "Secret '${_CLR_YELLOW}${CP4BA_INST_AE_1_AD_SECRET_NAME}${_CLR_NC}'"
    if [[ ! -z "${_USER_NAME}" ]]; then
      oc delete secret -n ${CP4BA_INST_NAMESPACE} ${CP4BA_INST_AE_1_AD_SECRET_NAME} 2> /dev/null 1> /dev/null
      oc create secret -n ${CP4BA_INST_NAMESPACE} generic ${CP4BA_INST_AE_1_AD_SECRET_NAME} \
        --from-literal=AE_DATABASE_USER="${CP4BA_INST_DB_AE_USER}" \
        --from-literal=AE_DATABASE_PWD="${CP4BA_INST_DB_AE_PWD}" 1> /dev/null
    else
      _ERROR=1
      echo -e "${_CLR_RED}Secret ${CP4BA_INST_AE_1_AD_SECRET_NAME} NOT created (troubleshooting 'username' for secret '${_CLR_YELLOW}${CP4BA_INST_DB_CR_NAME}-app${_CLR_RED}') !!!${_CLR_NC}"
    fi
  fi
}

#-------------------------------
#createSecretFNCM () {
#  echo -e "Secret '${_CLR_YELLOW}ibm-fncm-secret${_CLR_NC}'"
#  if [[ ! -z "${_USER_NAME}" ]]; then
#    oc delete secret -n ${CP4BA_INST_NAMESPACE} ibm-fncm-secret 2> /dev/null 1> /dev/null
#    oc create secret -n ${CP4BA_INST_NAMESPACE} generic ibm-fncm-secret \
#      --from-literal=osDBUsername="${CP4BA_INST_DB_OS_USER}" \
#      --from-literal=osDBPassword="${CP4BA_INST_DB_OS_PWD}" \
#      --from-literal=gcdDBUsername="${CP4BA_INST_DB_GCD_USER}" \
#      --from-literal=gcdDBPassword="${CP4BA_INST_DB_GCD_PWD}" \
#      --from-literal=contentDBUsername="${CP4BA_INST_DB_BAWDOCS_USER}" \
#      --from-literal=contentDBPassword="${CP4BA_INST_DB_BAWDOCS_PWD}" \
#      --from-literal=appLoginUsername="${CP4BA_INST_PAKBA_ADMIN_USER}" \
#      --from-literal=appLoginPassword="${CP4BA_INST_PAKBA_ADMIN_PWD}" \
#      --from-literal=ltpaPassword="passw0rd" \
#      --from-literal=keystorePassword="changeitchangeit" 1> /dev/null
#  else
#    _ERROR=1
#    echo -e "${_CLR_RED}Secret ibm-fncm-secret NOT created (troubleshooting 'username' for secret '${_CLR_YELLOW}${CP4BA_INST_DB_CR_NAME}-app${_CLR_RED}') !!!${_CLR_NC}"
#  fi
#}

#-------------------------------
createSecretFNCM () {
  echo -e "Secret '${_CLR_YELLOW}ibm-fncm-secret${_CLR_NC}'"
  if [[ ! -z "${_USER_NAME}" ]]; then
    oc delete secret -n ${CP4BA_INST_NAMESPACE} ibm-fncm-secret 2> /dev/null 1> /dev/null
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
  else
    _ERROR=1
    echo -e "${_CLR_RED}Secret ibm-fncm-secret NOT created (troubleshooting 'username' for secret '${_CLR_YELLOW}${CP4BA_INST_DB_CR_NAME}-app${_CLR_RED}') !!!${_CLR_NC}"
  fi
}

#-------------------------------
createSecretBAN () {
  echo -e "Secret '${_CLR_YELLOW}ibm-ban-secret${_CLR_NC}'"
  if [[ ! -z "${_USER_NAME}" ]]; then
    oc delete secret -n ${CP4BA_INST_NAMESPACE} ibm-ban-secret 2> /dev/null 1> /dev/null
    oc create secret -n ${CP4BA_INST_NAMESPACE} generic ibm-ban-secret \
      --from-literal=navigatorDBUsername="${CP4BA_INST_DB_ICN_USER}" \
      --from-literal=navigatorDBPassword="${CP4BA_INST_DB_ICN_PWD}" \
      --from-literal=appLoginUsername="${CP4BA_INST_PAKBA_ADMIN_USER}" \
      --from-literal=appLoginPassword="${CP4BA_INST_PAKBA_ADMIN_PWD}" \
      --from-literal=keystorePassword="changeit" \
      --from-literal=ltpaPassword="changeit" 1> /dev/null
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
    oc delete secret -n ${CP4BA_INST_NAMESPACE} ${CP4BA_INST_BAW_1_DB_SECRET} 2> /dev/null 1> /dev/null
    oc create secret -n ${CP4BA_INST_NAMESPACE} generic ${CP4BA_INST_BAW_1_DB_SECRET} \
      --from-literal=dbUser="${CP4BA_INST_BAW_1_DB_USER}" \
      --from-literal=password="${CP4BA_INST_BAW_1_DB_PWD}"  1> /dev/null
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
      _SECRET_EXIST=$?
      if [ $_SECRET_EXIST -eq 0 ]; then
        echo -e -n "${_CLR_GREEN}Wait for DB credentials secret '${_CLR_YELLOW}"${CP4BA_INST_DB_CR_NAME}-app"${_CLR_GREEN}' (may take minutes) [$_seconds]${_CLR_NC}\033[0K\r"
        sleep 1
        ((_seconds=_seconds+1))
      else
        break
      fi
    done
    if [ $_SECRET_EXIST -eq 0 ]; then
      echo ""
    fi
  fi

  _USER_NAME=$(oc get secret -n ${CP4BA_INST_SUPPORT_NAMESPACE} ${CP4BA_INST_DB_CR_NAME}-app -o jsonpath='{.data.username}' 2> /dev/null | base64 -d)
  _USER_PASSWORD=$(oc get secret -n ${CP4BA_INST_SUPPORT_NAMESPACE} ${CP4BA_INST_DB_CR_NAME}-app -o jsonpath='{.data.password}' 2> /dev/null | base64 -d)
  #echo "CP4BA_INST_DB_CR_NAME User: " $_USER_NAME / $_USER_PASSWORD

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

echo -e "=============================================================="
echo -e "${_CLR_GREEN}Creating secrets in '${_CLR_YELLOW}${CP4BA_INST_NAMESPACE}${_CLR_GREEN}' namespace${_CLR_NC}"
createSecrets